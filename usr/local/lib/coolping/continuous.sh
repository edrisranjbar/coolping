#!/bin/bash

# Continuous monitoring dashboard for coolping

# Frame height (top + 21 content rows + bottom) used for in-place redraw
CONT_FRAME_LINES=23

# Print one aligned box row directly to stdout (no subshells).
# $1 = content (may contain literal \033[..m sequences)
# $2 = optional extra width correction for double-width glyphs (emoji)
cont_row() {
  local content="$1" extra="${2:-0}"
  local stripped="${content//\\033\[*([0-9;])m/}"
  local pad=$((BOX_WIDTH - ${#stripped} - extra))
  (( pad < 0 )) && pad=0
  printf '│%b%*s│\033[K\n' "$content" "$pad" ''
}

run_continuous() {
  local interval=1
  local total=0 success=0 failed=0
  local min_h=-1 max_h=0 sum_h=0   # RTT stored in hundredths of ms
  local state="" last_state=""
  local status_line="" last_rtt="" last_rtt_plain=""
  local stats avg_rtt recent_avg jitter loss_percent quality min_disp max_disp spark_idx
  local sparkline="" bar="" uptime_formatted
  local frame_started=false
  local start_sec=$SECONDS
  local tick_start=${EPOCHREALTIME:-$SECONDS}
  local ping_output="" rtt="" h i idx

  declare -a recent_rtts=()
  local RECENT_WINDOW=10
  local re_time='time[=<]([0-9.]+)'
  local BLOCK_ALL='████████████████████'

  trap 'echo -e "\n${YELLOW}${INFO} Monitoring stopped. Final stats above.${NC}"; exit 0' INT

  echo -e "${YELLOW}${INFO} Continuous monitoring of $HOST (Press Ctrl+C to stop)${NC}"
  echo

  while true; do
    (( total += 1 ))

    rtt=""
    if ping_output=$(ping -c 1 -W 1 "$HOST" 2>&1); then
      if [[ $ping_output =~ $re_time ]]; then
        rtt="${BASH_REMATCH[1]}"
      fi
    fi

    if [[ -n "$rtt" ]]; then
      (( success += 1 ))
      h=$(awk -v r="$rtt" 'BEGIN { printf "%d", r * 100 + 0.5 }')
      (( sum_h += h ))
      if (( min_h < 0 || h < min_h )); then min_h=$h; fi
      if (( h > max_h )); then max_h=$h; fi

      recent_rtts+=("$rtt")
      if (( ${#recent_rtts[@]} > RECENT_WINDOW )); then
        recent_rtts=("${recent_rtts[@]:1}")
      fi

      status_line="${GREEN}${TICK} UP${NC}"
      last_rtt_plain="${rtt}ms"
      last_rtt="${GREEN}${last_rtt_plain}${NC}"
      state="up"
    else
      (( failed += 1 ))
      status_line="${RED}${CROSS} DOWN${NC}"
      last_rtt_plain="timeout"
      last_rtt="${RED}timeout${NC}"
      state="down"
    fi

    # Single awk pass computes all statistics from recent samples
    if (( ${#recent_rtts[@]} > 0 )); then
      stats=$(printf '%s\n' "${recent_rtts[@]}" | awk \
        -v succ="$success" -v fail="$failed" -v tot="$total" \
        -v sumh="$sum_h" -v minh="$min_h" -v maxh="$max_h" '
        function abs(x) { return x < 0 ? -x : x }
        { v[NR] = $1 }
        END {
          n = NR
          loss = tot > 0 ? fail * 100 / tot : 0
          avg = succ > 0 ? sumh / succ / 100 : -1
          ravg = 0; jit = 0; s = 0
          for (k = 1; k <= n; k++) s += v[k]
          if (n > 0) ravg = s / n
          if (n > 1) {
            d = 0
            for (k = 2; k <= n; k++) d += abs(v[k] - v[k - 1])
            jit = d / (n - 1)
          }
          q = 0
          if (avg >= 0) {
            if (loss < 1 && avg < 50) q = 5
            else if (loss < 5 && avg < 100) q = 4
            else if (loss < 10 && avg < 200) q = 3
            else if (loss < 25) q = 2
            else q = 1
          }
          mn = 1e18; mx = -1e18
          for (k = 1; k <= n; k++) {
            if (v[k] < mn) mn = v[k]
            if (v[k] > mx) mx = v[k]
          }
          rng = mx - mn; if (rng <= 0) rng = 1
          idxs = ""
          for (k = 1; k <= n; k++) idxs = idxs int((v[k] - mn) / rng * 7.999) " "
          printf "%.2f %.2f %.2f %.1f %d %.2f %.2f %s\n", avg, ravg, jit, loss, q, minh / 100, maxh / 100, idxs
        }')
    else
      stats="-1.00 N/A N/A 0.0 0 N/A N/A"
    fi

    read -r avg_rtt recent_avg jitter loss_percent quality min_disp max_disp spark_idx <<< "$stats"

    case "$quality" in
      5) quality="${GREEN}Excellent ★★★★★${NC}" ;;
      4) quality="${GREEN}Good ★★★★☆${NC}" ;;
      3) quality="${YELLOW}Fair ★★★☆☆${NC}" ;;
      2) quality="${YELLOW}Poor ★★☆☆☆${NC}" ;;
      1) quality="${RED}Bad ★☆☆☆☆${NC}" ;;
      *) quality="N/A" ;;
    esac

    sparkline=""
    for idx in $spark_idx; do
      case "$idx" in
        0) sparkline+='▁' ;;
        1) sparkline+='▂' ;;
        2) sparkline+='▃' ;;
        3) sparkline+='▄' ;;
        4) sparkline+='▅' ;;
        5) sparkline+='▆' ;;
        6) sparkline+='▇' ;;
        *) sparkline+='█' ;;
      esac
    done

    local loss_blocks=${loss_percent%.*}
    (( loss_blocks /= 5 ))
    (( loss_blocks > 20 )) && loss_blocks=20
    local success_blocks=$((20 - loss_blocks))
    bar="${GREEN}${BLOCK_ALL:0:success_blocks}${RED}${BLOCK_ALL:0:loss_blocks}${NC}"

    if [[ "$avg_rtt" == "-1.00" ]]; then
      avg_rtt="N/A"
      recent_avg="N/A"
      jitter="N/A"
      min_disp="N/A"
      max_disp="N/A"
    else
      min_disp="${min_disp}ms"
      max_disp="${max_disp}ms"
      avg_rtt="${avg_rtt}ms"
      recent_avg="${recent_avg}ms"
      jitter="${jitter}ms"
    fi

    uptime_seconds=$((SECONDS - start_sec))
    uptime_formatted=$(printf '%02d:%02d:%02d' \
      $((uptime_seconds / 3600)) $((uptime_seconds % 3600 / 60)) $((uptime_seconds % 60)))

    # Logging: record state changes plus a periodic heartbeat
    if [[ "$LOG_ENABLED" == true ]]; then
      if [[ "$state" != "$last_state" ]] || (( total % 30 == 0 )); then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - coolping $HOST seq=$total ${state} rtt=${rtt:-timeout}" >> "$HOME/coolping.log"
      fi
    fi
    last_state="$state"

    # Redraw in place: move cursor up over the previous frame instead of clearing
    if [[ -t 1 ]]; then
      if [[ "$frame_started" == true ]]; then
        printf '\033[%dA\r' "$CONT_FRAME_LINES"
      fi
      printf '%s\033[K\n' "$BOX_TOP"
      cont_row "  ${BLUE}🌐 Host:${NC} $HOST" 1
      cont_row "  ${BLUE}Status:${NC} $status_line    ${BLUE}Last RTT:${NC} $last_rtt" 1
      printf '%s\033[K\n' "$BOX_SEP"
      cont_row "  ${YELLOW}📊 Statistics${NC}" 1
      cont_row "    Total Pings:    $total"
      cont_row "    Successful:     ${GREEN}$success${NC}"
      cont_row "    Failed:         ${RED}$failed${NC}"
      cont_row "    Packet Loss:    ${RED}${loss_percent}%${NC}"
      cont_row "    Loss Graph:     $bar"
      cont_row "    Sparkline:      ${sparkline} (${RECENT_WINDOW}-ping trend)"
      printf '%s\033[K\n' "$BOX_SEP"
      cont_row "  ${YELLOW}⚡ Latency (ms)${NC}" 1
      cont_row "    Current:        $last_rtt"
      cont_row "    Average:        ${avg_rtt}"
      cont_row "    Recent (10):    ${recent_avg}"
      cont_row "    Jitter:         ${jitter}"
      cont_row "    Min:            ${GREEN}${min_disp}${NC}"
      cont_row "    Max:            ${RED}${max_disp}${NC}"
      printf '%s\033[K\n' "$BOX_SEP"
      cont_row "  ${YELLOW}🏆 Quality:${NC} $quality" 1
      cont_row "  ${YELLOW}⏱️  Uptime:${NC}  $uptime_formatted" 1
      printf '%s\033[K\n' "$BOX_BOT"
      frame_started=true
    else
      # Non-tty: print frames sequentially without cursor tricks
      echo "$BOX_TOP"
      cont_row "  ${BLUE}🌐 Host:${NC} $HOST" 1
      cont_row "  ${BLUE}Status:${NC} $status_line    ${BLUE}Last RTT:${NC} $last_rtt" 1
      echo "$BOX_SEP"
      cont_row "  ${YELLOW}📊 Statistics${NC}" 1
      cont_row "    Total Pings:    $total"
      cont_row "    Successful:     ${GREEN}$success${NC}"
      cont_row "    Failed:         ${RED}$failed${NC}"
      cont_row "    Packet Loss:    ${RED}${loss_percent}%${NC}"
      cont_row "    Loss Graph:     $bar"
      cont_row "    Sparkline:      ${sparkline} (${RECENT_WINDOW}-ping trend)"
      echo "$BOX_SEP"
      cont_row "  ${YELLOW}⚡ Latency (ms)${NC}" 1
      cont_row "    Current:        $last_rtt"
      cont_row "    Average:        ${avg_rtt}"
      cont_row "    Recent (10):    ${recent_avg}"
      cont_row "    Jitter:         ${jitter}"
      cont_row "    Min:            ${GREEN}${min_disp}${NC}"
      cont_row "    Max:            ${RED}${max_disp}${NC}"
      echo "$BOX_SEP"
      cont_row "  ${YELLOW}🏆 Quality:${NC} $quality" 1
      cont_row "  ${YELLOW}⏱️  Uptime:${NC}  $uptime_formatted" 1
      echo "$BOX_BOT"
      echo
    fi

    sleep_interval "$tick_start" "$interval"
    tick_start=${EPOCHREALTIME:-$SECONDS}
  done
}

#!/bin/bash

# Single-shot ping logic and summary for coolping

# Map an RTT value to a color tag: G (< good), Y (< ok), R otherwise
rtt_tag() {
  awk -v r="$1" -v g="$RTT_GOOD" -v o="$RTT_OK" 'BEGIN {
    if (r < g) print "G"
    else if (r < o) print "Y"
    else print "R"
  }'
}

# Sleep so that the next iteration starts at (start + interval), drift-free
sleep_interval() {
  local start="$1" interval="$2" remaining

  if [[ -n "${EPOCHREALTIME:-}" ]]; then
    remaining=$(awk -v n="${EPOCHREALTIME}" -v s="$start" -v i="$interval" \
      'BEGIN { r = i - (n - s); printf "%.3f", (r > 0 ? r : 0) }')
  else
    (( remaining = SECONDS - start ))
    (( remaining = interval - remaining ))
    (( remaining < 0 )) && remaining=0
  fi

  sleep "$remaining"
}

run_ping() {
  local interval=1
  local success_count=0
  local loss_percent=100
  local sum_rtt="0"
  local avg_rtt="N/A"
  local resolved_host=""
  local ping_output=""
  local reply_from=""
  local reply_ip=""
  local rtt=""
  local ttl=""
  local status=""
  local log_status=""
  local iter_start=${EPOCHREALTIME:-$SECONDS}
  local i tag

  local -a reply_hosts=()
  local -a reply_times=()
  local -a reply_ttls=()
  local -a reply_statuses=()
  local -a reply_tags=()

  local re_from='from[[:space:]]([^[:space:]()]+)'
  local re_ip='\(([^)]+)\)'
  local re_time='time[=<]([0-9.]+)'
  local re_ttl='ttl[=:[:space:]]([0-9]+)'
  local re_ping='PING[[:space:]]([^[:space:]]+)[[:space:]]+\(([^)]+)\)'

  for ((i=1; i<=PING_COUNT; i++)); do
    if ping_output=$(ping -c 1 -W 1 "$HOST" 2>&1); then
      if [[ "$VERBOSE" == true ]]; then
        echo "$ping_output"
      fi

      reply_from=""
      reply_ip=""
      rtt=""
      ttl=""

      if [[ $ping_output =~ $re_from ]]; then
        reply_from="${BASH_REMATCH[1]}"
        reply_from="${reply_from%:}"
      fi
      if [[ $ping_output =~ $re_ip ]]; then
        reply_ip="${BASH_REMATCH[1]}"
      fi
      if [[ $ping_output =~ $re_time ]]; then
        rtt="${BASH_REMATCH[1]}"
      fi
      if [[ $ping_output =~ $re_ttl ]]; then
        ttl="${BASH_REMATCH[1]}"
      fi

      if [[ -z "$resolved_host" ]]; then
        if [[ $ping_output =~ $re_ping ]]; then
          resolved_host="${BASH_REMATCH[2]}"
        fi
        resolved_host="${resolved_host:-$reply_ip}"
      fi

      reply_hosts+=("${reply_from:-$HOST}")
      reply_times+=("${rtt:-N/A}")
      reply_ttls+=("${ttl:-N/A}")
      reply_statuses+=("$TICK")
      if [[ -n "$rtt" ]]; then
        tag=$(rtt_tag "$rtt")
        sum_rtt=$(awk -v total="$sum_rtt" -v value="$rtt" 'BEGIN { printf "%.3f", total + value }')
      else
        tag="N"
      fi
      reply_tags+=("$tag")
      (( success_count += 1 ))
    else
      if [[ "$VERBOSE" == true ]]; then
        echo "$ping_output"
      fi

      reply_hosts+=("-")
      reply_times+=("timeout")
      reply_ttls+=("-")
      reply_statuses+=("$CROSS")
      reply_tags+=("")
    fi

    if (( i < PING_COUNT )); then
      sleep_interval "$iter_start" "$interval"
      iter_start=${EPOCHREALTIME:-$SECONDS}
    fi
  done

  if (( PING_COUNT > 0 )); then
    (( loss_percent = (PING_COUNT - success_count) * 100 / PING_COUNT ))
  fi

  if (( success_count > 0 )); then
    avg_rtt=$(awk -v total="$sum_rtt" -v count="$success_count" \
      'BEGIN { printf "%.1f", total / count }')
  fi

  echo -e "${DIM}${HOST}${resolved_host:+ ($resolved_host)}${NC}"
  echo
  echo -e "${GREEN}${TICK}${NC} ${success_count} received    ${RED}${CROSS}${NC} ${loss_percent}% packet loss    ${BLUE}◴${NC} ${avg_rtt} ms avg"
  echo
  printf "%-6s %-24s %-14s %-8s %s\n" "Seq" "Reply from" "Time" "TTL" "Status"

  for ((i=0; i<PING_COUNT; i++)); do
    if [[ "${reply_times[$i]}" == "timeout" ]]; then
      status="${RED}${reply_statuses[$i]}${NC}"
      printf "%-6s %-24s ${RED}%-14s${NC} %-8s %b\n" \
        "$((i + 1))" "${reply_hosts[$i]}" "${reply_times[$i]}" "${reply_ttls[$i]}" "$status"
    else
      case "${reply_tags[$i]}" in
        G) tag="$GREEN" ;;
        Y) tag="$YELLOW" ;;
        R) tag="$RED" ;;
        *) tag="" ;;
      esac
      status="${GREEN}${reply_statuses[$i]}${NC}"
      printf "%-6s %-24s %b%-14s${NC} %-8s %b\n" \
        "$((i + 1))" "${reply_hosts[$i]}" "${tag}" "${reply_times[$i]} ms" "${reply_ttls[$i]}" "$status"
    fi
  done

  if [[ $success_count -eq 0 ]]; then
    egg="$(maybe_easter_egg)"
    if [[ -n "$egg" ]]; then
      echo -e "\n${RED}$egg${NC}"
    else
      echo -e "\n${RED}$(random_fail_quote)${NC}"
    fi
    echo -e "\n${YELLOW}🛠️  How to fix this mess?${NC}"
    echo "  1. Check your Wi-Fi or network cable."
    echo "  2. Restart your router (the classic 'turn it off and on again')."
    echo "  3. Verify your DNS settings (try 8.8.8.8 or 1.1.1.1)."
    echo "  4. Use 'traceroute $HOST' or 'mtr $HOST' to see where the connection drops."
  elif [[ $success_count -eq $PING_COUNT ]]; then
    egg="$(maybe_easter_egg)"
    if [[ -n "$egg" ]]; then
      echo -e "\n${GREEN}$egg${NC}"
    else
      echo -e "\n${GREEN}$(random_success_quote)${NC}"
    fi
  fi

  if [[ "$LOG_ENABLED" == true ]]; then
    log_status="partially successful"
    if (( success_count == PING_COUNT )); then
      log_status="successful"
    elif (( success_count == 0 )); then
      log_status="failed"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - coolping $HOST --count $PING_COUNT - ${log_status}" >> "$HOME/coolping.log"
    echo
    echo -e "${BLUE}Logging to: ~/coolping.log${NC}"
  fi

  echo
}

#!/bin/bash

# Single-shot ping logic and summary for coolping
run_ping() {
  local success_count=0
  local loss_percent=100
  local sum_rtt="0"
  local avg_rtt="N/A"
  local resolved_host=""
  local ping_output=""
  local reply_from=""
  local rtt=""
  local ttl=""
  local status=""
  local log_status=""
  local i

  local -a reply_hosts=()
  local -a reply_times=()
  local -a reply_ttls=()
  local -a reply_statuses=()

  for ((i=1; i<=PING_COUNT; i++)); do
    if ping_output=$(ping -c 1 -W 1 "$HOST" 2>&1); then
      if [[ "$VERBOSE" == true ]]; then
        echo "$ping_output"
      fi

      reply_from=$(echo "$ping_output" | sed -nE \
        -e 's/.*[Ff]rom [^( ]+ \(([^)]+)\).*/\1/p' \
        -e 's/.*[Ff]rom ([^ :]+).*/\1/p' | head -n 1)
      rtt=$(echo "$ping_output" | sed -nE 's/.*time[=<]([0-9.]+).*/\1/p' | head -n 1)
      ttl=$(echo "$ping_output" | sed -nE 's/.*ttl[= ]([0-9]+).*/\1/p' | head -n 1)

      if [[ -z "$resolved_host" ]]; then
        resolved_host=$(echo "$ping_output" | sed -nE \
          's/^PING [^( ]+ \(([^)]+)\).*/\1/p' | head -n 1)
        resolved_host="${resolved_host:-$reply_from}"
      fi

      reply_hosts+=("${reply_from:-$HOST}")
      reply_times+=("${rtt:-N/A}")
      reply_ttls+=("${ttl:-N/A}")
      reply_statuses+=("$TICK")
      ((success_count++))

      if [[ -n "$rtt" ]]; then
        sum_rtt=$(awk -v total="$sum_rtt" -v value="$rtt" 'BEGIN { printf "%.3f", total + value }')
      fi
    else
      if [[ "$VERBOSE" == true ]]; then
        echo "$ping_output"
      fi

      reply_hosts+=("-")
      reply_times+=("timeout")
      reply_ttls+=("-")
      reply_statuses+=("$CROSS")
    fi

    if (( i < PING_COUNT )); then
      sleep 0.2
    fi
  done

  if (( PING_COUNT > 0 )); then
    loss_percent=$(( (PING_COUNT - success_count) * 100 / PING_COUNT ))
  fi

  if (( success_count > 0 )); then
    avg_rtt=$(awk -v total="$sum_rtt" -v count="$success_count" \
      'BEGIN { printf "%.1f", total / count }')
  fi

  if [[ -z "$resolved_host" ]]; then
    resolved_host=$(echo "$ping_output" | sed -nE \
      's/^PING [^( ]+ \(([^)]+)\).*/\1/p' | head -n 1)
  fi

  echo -e "${NC}${HOST}${resolved_host:+ (${resolved_host})}"
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
      status="${GREEN}${reply_statuses[$i]}${NC}"
      printf "%-6s %-24s ${GREEN}%-14s${NC} %-8s %b\n" \
        "$((i + 1))" "${reply_hosts[$i]}" "${reply_times[$i]} ms" "${reply_ttls[$i]}" "$status"
    fi
  done

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

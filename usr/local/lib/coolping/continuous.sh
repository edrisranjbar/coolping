#!/bin/bash

# Continuous monitoring loop for coolping
run_continuous() {
  echo -e "${YELLOW}${INFO} Continuous monitoring of $HOST (Press Ctrl+C to stop)${NC}\n"

  total_pings=0
  successful_pings=0
  failed_pings=0
  min_rtt=999999
  max_rtt=0
  sum_rtt=0
  start_time=$(date +%s)

  declare -a recent_rtts
  RECENT_WINDOW=10

  trap 'echo -e "\n\n${YELLOW}${INFO} Monitoring stopped. Final stats above.${NC}"; exit 0' INT

  tput sc

  while true; do
    ((total_pings++))

    if ping_output=$(ping -c 1 -W 1 "$HOST" 2>&1); then
      rtt=$(echo "$ping_output" | grep -o 'time=[0-9.]*' | cut -d'=' -f2)

      if [[ -n "$rtt" ]]; then
        ((successful_pings++))

        if (( $(echo "$rtt < $min_rtt" | bc -l) )); then
          min_rtt=$rtt
        fi
        if (( $(echo "$rtt > $max_rtt" | bc -l) )); then
          max_rtt=$rtt
        fi
        sum_rtt=$(echo "$sum_rtt + $rtt" | bc -l)

        recent_rtts+=("$rtt")
        if [[ ${#recent_rtts[@]} -gt $RECENT_WINDOW ]]; then
          recent_rtts=("${recent_rtts[@]:1}")
        fi

        status="${GREEN}${TICK} UP${NC}"
        last_rtt="${GREEN}${rtt}ms${NC}"
      fi
    else
      ((failed_pings++))
      status="${RED}${CROSS} DOWN${NC}"
      last_rtt="${RED}timeout${NC}"
    fi

    if [[ $successful_pings -gt 0 ]]; then
      avg_rtt=$(printf "%.2f" $(echo "scale=2; $sum_rtt / $successful_pings" | bc -l))

      recent_sum=0
      for r in "${recent_rtts[@]}"; do
        recent_sum=$(echo "$recent_sum + $r" | bc -l)
      done
      if [[ ${#recent_rtts[@]} -gt 0 ]]; then
        recent_avg=$(printf "%.2f" $(echo "scale=2; $recent_sum / ${#recent_rtts[@]}" | bc -l))
      else
        recent_avg="0.00"
      fi
    else
      avg_rtt="N/A"
      recent_avg="N/A"
      min_rtt_display="N/A"
      max_rtt_display="N/A"
    fi

    if [[ $successful_pings -gt 0 ]]; then
      min_rtt_display="${min_rtt}ms"
      max_rtt_display="${max_rtt}ms"
    fi

    if [[ $total_pings -gt 0 ]]; then
      loss_percent=$(echo "scale=1; ($failed_pings * 100) / $total_pings" | bc -l)
    else
      loss_percent="0.0"
    fi

    current_time=$(date +%s)
    uptime_seconds=$((current_time - start_time))
    uptime_formatted=$(printf '%02d:%02d:%02d' $((uptime_seconds/3600)) $((uptime_seconds%3600/60)) $((uptime_seconds%60)))

    quality="N/A"
    if [[ $successful_pings -gt 0 ]]; then
      if (( $(echo "$loss_percent < 1 && $avg_rtt < 50" | bc -l) )); then
        quality="${GREEN}Excellent ★★★★★${NC}"
      elif (( $(echo "$loss_percent < 5 && $avg_rtt < 100" | bc -l) )); then
        quality="${GREEN}Good ★★★★☆${NC}"
      elif (( $(echo "$loss_percent < 10 && $avg_rtt < 200" | bc -l) )); then
        quality="${YELLOW}Fair ★★★☆☆${NC}"
      elif (( $(echo "$loss_percent < 25" | bc -l) )); then
        quality="${YELLOW}Poor ★★☆☆☆${NC}"
      else
        quality="${RED}Bad ★☆☆☆☆${NC}"
      fi
    fi

    loss_bar=""
    loss_blocks=$((${loss_percent%.*} / 5))
    if [[ $loss_blocks -gt 20 ]]; then loss_blocks=20; fi
    success_blocks=$((20 - loss_blocks))
    for ((i=0; i<success_blocks; i++)); do loss_bar+="${GREEN}█${NC}"; done
    for ((i=0; i<loss_blocks; i++)); do loss_bar+="${RED}█${NC}"; done

    tput rc
    tput ed

    echo -e "╭─────────────────────────────────────────────────────────────╮"
    echo -e "│  ${BLUE}🌐 Host:${NC} $HOST                                          "
    echo -e "│  ${BLUE}Status:${NC} $status    ${BLUE}Last RTT:${NC} $last_rtt                     "
    echo -e "├─────────────────────────────────────────────────────────────┤"
    echo -e "│  ${YELLOW}📊 Statistics${NC}                                            "
    echo -e "│    Total Pings:    $total_pings                                      "
    echo -e "│    Successful:     ${GREEN}$successful_pings${NC}                               "
    echo -e "│    Failed:         ${RED}$failed_pings${NC}                                  "
    echo -e "│    Packet Loss:    ${RED}${loss_percent}%${NC}                              "
    echo -e "│    Loss Graph:     $loss_bar                     "
    echo -e "├─────────────────────────────────────────────────────────────┤"
    echo -e "│  ${YELLOW}⚡ Latency (ms)${NC}                                          "
    echo -e "│    Current:        $last_rtt                                "
    echo -e "│    Average:        ${avg_rtt}ms                                   "
    echo -e "│    Recent (10):    ${recent_avg}ms                              "
    echo -e "│    Min:            ${GREEN}${min_rtt_display}${NC}                              "
    echo -e "│    Max:            ${RED}${max_rtt_display}${NC}                              "
    echo -e "├─────────────────────────────────────────────────────────────┤"
    echo -e "│  ${YELLOW}🏆 Quality:${NC} $quality                                "
    echo -e "│  ${YELLOW}⏱️  Uptime:${NC}  $uptime_formatted                                    "
    echo -e "╰─────────────────────────────────────────────────────────────╯"

    sleep 1
  done
}

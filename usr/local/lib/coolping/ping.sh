#!/bin/bash

# Single-shot ping logic and summary for coolping
run_ping() {
  echo -e "${YELLOW}${INFO} Pinging $HOST with $PING_COUNT packets...${NC}"
  
  success_count=0
  
  for ((i=1; i<=PING_COUNT; i++)); do
    if ping_output=$(ping -c 1 -W 1 "$HOST" 2>&1); then
      if [[ "$VERBOSE" == true ]]; then
        echo "$ping_output"
      fi
      rtt=$(echo "$ping_output" | grep -o 'time=[0-9.]*' | cut -d'=' -f2)
      echo -e "${GREEN}${TICK} Reply from $HOST: seq=$i time=${rtt} ms${NC}"
      ((success_count++))
    else
      if [[ "$VERBOSE" == true ]]; then
        echo "$ping_output"
      fi
      echo -e "${RED}${CROSS} No reply from $HOST: seq=$i timeout${NC}"
    fi
    sleep 0.2
  done

  if [[ $success_count -eq 0 ]]; then
    egg="$(maybe_easter_egg)"
    if [[ -n "$egg" ]]; then
      echo -e "\n${RED}$egg${NC}\n"
    else
      echo -e "\n${RED}$(random_fail_quote)${NC}\n"
    fi
    echo -e "${YELLOW}🛠️  How to fix this mess?${NC}"
    echo "  1. Check your Wi-Fi or network cable."
    echo "  2. Restart your router (the classic 'turn it off and on again')."
    echo "  3. Verify your DNS settings (try 8.8.8.8 or 1.1.1.1)."
    echo "  4. Use 'traceroute $HOST' or 'mtr $HOST' to see where the connection drops."
    echo
  elif [[ $success_count -eq $PING_COUNT ]]; then
    egg="$(maybe_easter_egg)"
    if [[ -n "$egg" ]]; then
      echo -e "\n${GREEN}$egg${NC}\n"
    else
      echo -e "\n${GREEN}$(random_success_quote)${NC}\n"
    fi
  fi

  if [[ "$LOG_ENABLED" = true ]]; then
    log_status="partially successful"
    if [[ $success_count -eq $PING_COUNT ]]; then
      log_status="successful"
    elif [[ $success_count -eq 0 ]]; then
      log_status="failed"
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - coolping $HOST --count $PING_COUNT - ${log_status}" >> ~/coolping.log
    echo -e "${BLUE}${INFO} Logged to ~/coolping.log${NC}"
  fi
}

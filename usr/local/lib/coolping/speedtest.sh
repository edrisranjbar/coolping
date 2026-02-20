#!/bin/bash

# Download & upload speed test function for coolping
run_speedtest() {
  echo -e "${YELLOW}${INFO} Running speed test...${NC}\n"
  
  local test_urls=(
    "https://speed.hetzner.de/10MB.bin"
    "http://speedtest.tele2.net/10MB.zip"
    "https://proof.ovh.net/files/10Mb.dat"
    "http://ipv4.download.thinkbroadband.com/10MB.zip"
  )
  
  local test_url=""
  for url in "${test_urls[@]}"; do
    if curl -s -I "$url" --connect-timeout 5 >/dev/null 2>&1; then
      test_url="$url"
      break
    fi
  done
  
  if [[ -z "$test_url" ]]; then
    echo -e "${RED}${CROSS} Could not connect to speed test servers${NC}"
    echo -e "${YELLOW}Trying alternative method...${NC}\n"
    test_url="${test_urls[0]}"
  fi
  
  echo -e "╭─────────────────────────────────────────────────────────────╮"
  echo -e "│  ${BLUE}📥 Testing Download Speed${NC}                                 "
  echo -e "╰─────────────────────────────────────────────────────────────╯"
  
  local temp_file="/tmp/coolping_speedtest_$$"
  
  echo -ne "${YELLOW}Downloading test file (10MB)...${NC}\n"
  
  local curl_output=$(curl -o "$temp_file" -# "$test_url" --max-time 30 -w "\n%{time_total}|%{size_download}" 2>&1)
  local curl_exit=$?
  
  if [[ $curl_exit -eq 0 ]] && [[ -f "$temp_file" ]]; then
    local time_and_size=$(echo "$curl_output" | tail -1)
    local time_total=$(echo "$time_and_size" | cut -d'|' -f1)
    local size_download=$(echo "$time_and_size" | cut -d'|' -f2)
    
    if [[ -z "$size_download" ]] || [[ "$size_download" == "0" ]]; then
      size_download=$(stat -f%z "$temp_file" 2>/dev/null || stat -c%s "$temp_file" 2>/dev/null || echo "0")
    fi
    
    if [[ -z "$time_total" ]] || [[ "$time_total" == "0" ]]; then
      time_total="0.001"
    fi
    
    if [[ "$size_download" -gt 10000 ]]; then
      local bytes_per_sec=$(echo "scale=2; $size_download / $time_total" | bc -l)
      local mbps=$(echo "scale=2; ($bytes_per_sec * 8) / 1000000" | bc -l)
      local mbps_formatted=$(printf "%.2f" "$mbps")
      local mbytes_per_sec=$(echo "scale=2; $size_download / $time_total / 1000000" | bc -l)
      local mbytes_formatted=$(printf "%.2f" "$mbytes_per_sec")
      
      local speed_emoji="${GREEN}🚀${NC}"
      local speed_rating="${GREEN}★★★★★${NC}"
      if (( $(echo "$mbps < 10" | bc -l) )); then
        speed_emoji="${RED}🐌${NC}"
        speed_rating="${RED}★☆☆☆☆${NC}"
      elif (( $(echo "$mbps < 50" | bc -l) )); then
        speed_emoji="${YELLOW}🚶${NC}"
        speed_rating="${YELLOW}★★★☆☆${NC}"
      elif (( $(echo "$mbps < 100" | bc -l) )); then
        speed_emoji="${GREEN}🏃${NC}"
        speed_rating="${GREEN}★★★★☆${NC}"
      fi
      
      echo -e "${GREEN}${TICK} Download Speed: ${speed_emoji} ${GREEN}${mbps_formatted} Mbps${NC} (${mbytes_formatted} MB/s) $speed_rating"
    else
      echo -e "${RED}${CROSS} Download test failed (file too small: ${size_download} bytes)${NC}"
    fi
    
    rm -f "$temp_file"
  else
    echo -e "${RED}${CROSS} Download test failed (connection error)${NC}"
    rm -f "$temp_file"
  fi
  
  echo ""
  
  echo -e "╭─────────────────────────────────────────────────────────────╮"
  echo -e "│  ${BLUE}📤 Testing Upload Speed${NC}                                   "
  echo -e "╰─────────────────────────────────────────────────────────────╯"
  
  local upload_size=$((2 * 1024 * 1024))
  local upload_file="/tmp/coolping_upload_$$"
  
  echo -ne "${YELLOW}Generating test data (2MB)...${NC} "
  dd if=/dev/zero of="$upload_file" bs=1M count=2 2>/dev/null
  echo -e "${GREEN}Done${NC}"
  
  echo -ne "${YELLOW}Uploading test data...${NC}\n"
  
  local upload_url="https://httpbin.org/post"
  local start_time=$(date +%s%N)
  
  if curl -X POST -F "file=@$upload_file" "$upload_url" -o /dev/null -# --max-time 60 2>&1; then
    local end_time=$(date +%s%N)
    local duration_ns=$((end_time - start_time))
    local duration=$(echo "scale=3; $duration_ns / 1000000000" | bc -l)
    
    if [[ -z "$duration" ]] || [[ "$duration" == "0" ]]; then
      duration="0.001"
    fi
    
    if (( $(echo "$duration > 0.05" | bc -l) )); then
      local bytes_per_sec=$(echo "scale=2; $upload_size / $duration" | bc -l)
      local mbps=$(echo "scale=2; ($bytes_per_sec * 8) / 1000000" | bc -l)
      local mbps_formatted=$(printf "%.2f" "$mbps")
      local mbytes_per_sec=$(echo "scale=2; $upload_size / $duration / 1000000" | bc -l)
      local mbytes_formatted=$(printf "%.2f" "$mbytes_per_sec")
      
      local speed_emoji="${GREEN}🚀${NC}"
      local speed_rating="${GREEN}★★★★★${NC}"
      if (( $(echo "$mbps < 5" | bc -l) )); then
        speed_emoji="${RED}🐌${NC}"
        speed_rating="${RED}★☆☆☆☆${NC}"
      elif (( $(echo "$mbps < 20" | bc -l) )); then
        speed_emoji="${YELLOW}🚶${NC}"
        speed_rating="${YELLOW}★★★☆☆${NC}"
      elif (( $(echo "$mbps < 50" | bc -l) )); then
        speed_emoji="${GREEN}🏃${NC}"
        speed_rating="${GREEN}★★★★☆${NC}"
      fi
      
      echo -e "${GREEN}${TICK} Upload Speed:   ${speed_emoji} ${GREEN}${mbps_formatted} Mbps${NC} (${mbytes_formatted} MB/s) $speed_rating"
    else
      echo -e "${YELLOW}${WARN} Upload test completed too quickly to measure accurately${NC}"
    fi
  else
    echo -e "${YELLOW}${WARN} Upload test unavailable (connection error or timeout)${NC}"
  fi
  
  rm -f "$upload_file"
  
  echo ""
  echo -e "${GREEN}Speed test complete!${NC}"
  
  local speed_quotes=(
    "Gotta go fast! 💨"
    "Your internet is ${GREEN}zooming${NC}! 🏎️"
    "Speed test complete. Time to download ALL the things! 📦"
    "That's what I call bandwidth! 🎉"
    "Your ISP would be proud... or surprised! 😄"
  )
  local random_quote="${speed_quotes[$RANDOM % ${#speed_quotes[@]}]}"
  echo -e "\n${BLUE}${random_quote}${NC}\n"
}

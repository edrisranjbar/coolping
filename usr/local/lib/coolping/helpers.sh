#!/bin/bash

# Common helpers, colors, emojis, box drawing, and fun messages for coolping

shopt -s extglob

# Defaults
PING_COUNT=4
LOG_ENABLED=false
USE_EMOJI=true
USE_COLOR=true
VERBOSE=false
CONTINUOUS=false
HOST=""

# Emoji-safe fallback
TICK="✅"
CROSS="❌"
INFO="ℹ️"
WARN="⚠️"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m'

# RTT color thresholds (ms)
RTT_GOOD=50
RTT_OK=150

# Box drawing (inner width)
BOX_WIDTH=61
_box_dash() {
  local d=''
  local i
  for ((i = 0; i < BOX_WIDTH; i++)); do d+='─'; done
  printf '%s' "$d"
}
BOX_DASH=$(_box_dash)
BOX_TOP="╭${BOX_DASH}╮"
BOX_SEP="├${BOX_DASH}┤"
BOX_BOT="╰${BOX_DASH}╯"

validate_count() {
  local v="$1"
  case "$v" in
    ''|*[!0-9]*) return 1 ;;
  esac
  (( v > 0 ))
}

show_help() {
  echo -e "${BLUE}CoolPing - A stylish ping command with emoji feedback 🌐${NC}"
  echo ""
  echo "Usage:"
  echo "  coolping [options] <host>"
  echo "  coolping --help"
  echo ""
  echo "Options:"
  echo "  --count N       Number of packets to send (default: 4)"
  echo "  --continuous,-c Run indefinitely with live updating stats"
  echo "  --log           Enable logging to ~/coolping.log"
  echo "  --no-emoji      Disable emojis"
  echo "  --color WHEN    Colorize output: never, always, auto (default)"
  echo "  --verbose,-v    Show verbose output"
  echo "  --help,-h       Show this help message"
  echo ""
  echo "Environment:"
  echo "  NO_COLOR        Disables color output when set"
}

# Fun message arrays
FAIL_QUOTES=(
  "Oops! Did the internet ghost us again? 👻"
  "Nope, nada, zilch. Where did those packets go? 📦"
  "Still waiting... Still nothing... Typical. 😑"
  "Imagine paying for internet and this happens. 🙄"
  "Is your Wi-Fi just a suggestion, not a fact? 📶"
)

SUCCESS_QUOTES=(
  "All packets home safe and sound! 🚀"
  "Ping complete. Internet still loves you. ❤️"
  "Boom! Host answered like a champ. 🏆"
  "Solid connection! Your router approves. ✅"
  "The tubes of the internet are unclogged. 🪠"
)

EASTER_EGGS=(
  "It's not a bug, it's a feature! 🐞"
  "Have you tried turning it off and on again? 🔄"
  "99 little bugs in the code, 99 bugs in the code... 🐛"
  "To err is human, to debug divine. 👨‍💻"
  "There is no cloud, just someone else's computer. ☁️"
  "Works on my machine! 🤷"
  "I see dead packets... 👻"
  "It's always DNS. Always. 🧙"
  "Segmentation fault (core dumped) 💥"
)

random_fail_quote() {
  echo "${FAIL_QUOTES[RANDOM % ${#FAIL_QUOTES[@]}]}"
}

random_success_quote() {
  echo "${SUCCESS_QUOTES[RANDOM % ${#SUCCESS_QUOTES[@]}]}"
}

random_easter_egg() {
  echo "${EASTER_EGGS[RANDOM % ${#EASTER_EGGS[@]}]}"
}

maybe_easter_egg() {
  if (( RANDOM % 10 == 0 )); then
    random_easter_egg
  else
    echo ""
  fi
}

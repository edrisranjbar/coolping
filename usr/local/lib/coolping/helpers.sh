#!/bin/bash

# Common helpers, colors, emojis, and fun messages for coolping

# Defaults
PING_COUNT=4
LOG_ENABLED=false
USE_EMOJI=true
USE_COLOR=true
VERBOSE=false
CONTINUOUS=false

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
NC='\033[0m' # No Color

show_help() {
  echo -e "${BLUE}CoolPing - A stylish ping command with emoji feedback 🌐${NC}"
  echo ""
  echo "Usage:"
  echo "  coolping <host> [options]"
  echo ""
  echo "Options:"
  echo "  --count N       Number of packets to send (default: 4)"
  echo "  --continuous    Run indefinitely with live updating stats"
  echo "  --log           Enable logging to ~/coolping.log"
  echo "  --no-emoji      Disable emojis"
  echo "  --color never   Disable colored output"
  echo "  --help          Show this help message"
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
  "Boom! $HOST answered like a champ. 🏆"
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
  "rm -rf / --no-preserve-root (just kidding, don't!) 💣"
  "I see dead packets... 👻"
  "It's always DNS. Always. 🧙"
  "Segmentation fault (core dumped) 💥"
)

random_fail_quote() {
  echo "${FAIL_QUOTES[$RANDOM % ${#FAIL_QUOTES[@]}]}"
}

random_success_quote() {
  echo "${SUCCESS_QUOTES[$RANDOM % ${#SUCCESS_QUOTES[@]}]}"
}

random_easter_egg() {
  echo "${EASTER_EGGS[$RANDOM % ${#EASTER_EGGS[@]}]}"
}

maybe_easter_egg() {
  if (( RANDOM % 10 == 0 )); then
    random_easter_egg
  else
    echo ""
  fi
}

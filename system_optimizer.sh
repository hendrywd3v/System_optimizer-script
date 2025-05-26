#!/bin/bash

# ================================
# Update and Cleanup Script
# With Interactive Menu + Disk Graph + Kernel Cleanup + Optional Reboot
# ================================

set -euo pipefail

# ====== Colors ======
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
MAGENTA='\e[35m'
BOLD='\e[1m'
NC='\e[0m' # Reset color

# ====== Spinner ======
spinner() {
    local pid=$!
    local delay=0.15
    local spinstr='|/-\'
    while ps a | awk '{print $1}' | grep -q "$pid"; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ====== Check root ======
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}${BOLD}⚠️  Please run as root or with sudo.${NC}"
  exit 1
fi

# ====== Check internet connection ======
check_internet() {
  echo -e "${CYAN}🌐 Checking internet connection...${NC}"
  (ping -q -c 1 8.8.8.8 &>/dev/null) & spinner
  if ! ping -q -c 1 8.8.8.8 &>/dev/null; then
    echo -e "${RED}❌ No internet connection. Please check your network.${NC}"
    exit 1
  fi
}

# ====== Reboot prompt ======
reboot_prompt() {
  echo ""
  read -p "🔁 Do you want to reboot the system now? (y/n): " resp
  if [[ "$resp" =~ ^[yY]$ ]]; then
    echo -e "${GREEN}🔄 Rebooting...${NC}"
    reboot
  else
    echo -e "${YELLOW}👍 OK, no reboot.${NC}"
  fi
}

# ====== Package Repair ======
fix_errors() {
  echo -e "${CYAN}🩹 Checking and fixing broken packages...${NC}"
  (dpkg --configure -a &>/dev/null) & spinner
  (apt --fix-broken install -y &>/dev/null) & spinner
}

# ====== Disk space graph ======
show_disk_usage() {
  local label=$1
  local used=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
  local total_bar=20
  local filled=$((used * total_bar / 100))
  local empty=$((total_bar - filled))
  
  bar=$(printf "%0.s█" $(seq 1 $filled))
  space=$(printf "%0.s░" $(seq 1 $empty))

  echo -e "${label} [${bar}${space}] ${used}% used"
}

# ====== Update ======
update() {
  check_internet
  echo -e "${YELLOW}==========================================${NC}"
  echo -e "${BOLD}${BLUE}🔄  Updating the system...${NC}"
  echo -e "${YELLOW}==========================================${NC}"

  echo -e "${CYAN}🔍 Updating package list...${NC}"
  (apt update -y &>/dev/null) & spinner

  echo -e "${MAGENTA}📦 Upgradable packages:${NC}"
  apt list --upgradable

  echo -e "${CYAN}🚀 Installing updates...${NC}"
  (apt upgrade -y &>/dev/null) & spinner
  (apt full-upgrade -y &>/dev/null) & spinner

  fix_errors

  echo -e "${GREEN}✅ Update completed successfully!${NC}"
}

# ====== Cleanup ======
cleanup() {
  echo -e "${YELLOW}==========================================${NC}"
  echo -e "${BOLD}${BLUE}🧹 Starting system cleanup...${NC}"
  echo -e "${YELLOW}==========================================${NC}"

  BEFORE_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
  echo -e "${CYAN}💾 Disk space before:${NC}"
  show_disk_usage "   Before"

  echo -e "${CYAN}🗑️  Removing unnecessary packages...${NC}"
  (apt autoremove -y &>/dev/null) & spinner
  (apt autoclean -y &>/dev/null) & spinner
  (apt clean -y &>/dev/null) & spinner

  echo -e "${CYAN}🧽 Cleaning caches and temporary files...${NC}"
  (rm -rf ~/.cache/* /tmp/* /root/.cache/* &>/dev/null || true) & spinner

  echo -e "${CYAN}📜 Cleaning old logs...${NC}"
  (journalctl --vacuum-time=1s &>/dev/null || true) & spinner
  (find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; &>/dev/null) & spinner
  (find /var/log -type f -name "*.gz" -delete &>/dev/null) & spinner

  echo -e "${CYAN}♻️  Emptying trash...${NC}"
  (rm -rf ~/.local/share/Trash/* &>/dev/null || true) & spinner

  echo -e "${CYAN}🧹 Cleaning Snap cache (if exists)...${NC}"
  (rm -rf /var/cache/snapd &>/dev/null || true) & spinner

  AFTER_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
  echo -e "${CYAN}💾 Disk space after:${NC}"
  show_disk_usage "   After"

  SAVED=$((BEFORE_USAGE - AFTER_USAGE))

  if (( SAVED > 0 )); then
    echo -e "${GREEN}🚀 You freed approximately ${SAVED}% of space!${NC}"
  else
    echo -e "${YELLOW}ℹ️ No significant difference in disk usage.${NC}"
  fi

  echo -e "${GREEN}✅ Cleanup completed!${NC}"
}

# ====== Old Kernel Cleanup ======
cleanup_kernels() {
  echo -e "${YELLOW}==========================================${NC}"
  echo -e "${BOLD}${BLUE}🧹🧠 Cleaning old kernels...${NC}"
  echo -e "${YELLOW}==========================================${NC}"

  CURRENT_KERNEL=$(uname -r | sed 's/-generic//')
  echo -e "${CYAN}🔍 Current kernel: ${GREEN}${CURRENT_KERNEL}${NC}"

  INSTALLED_KERNELS=$(dpkg --list | grep linux-image | grep -v "${CURRENT_KERNEL}" | awk '{print $2}' | grep -E 'linux-image-[0-9]')

  if [[ -z "$INSTALLED_KERNELS" ]]; then
    echo -e "${GREEN}✅ No old kernels found.${NC}"
  else
    echo -e "${MAGENTA}🗑️  Old kernels found:${NC}"
    echo "${INSTALLED_KERNELS}"
    echo ""

    read -p "❗ Do you want to remove these old kernels? (y/n): " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
      apt remove --purge -y $INSTALLED_KERNELS
      apt autoremove -y
      echo -e "${GREEN}✅ Old kernels removed successfully.${NC}"
    else
      echo -e "${YELLOW}⚠️  Operation canceled by user.${NC}"
    fi
  fi
}

# ====== Menu ======
while true; do
  clear
  echo -e "${BOLD}${CYAN}"
  echo "╔══════════════════════════════════════════╗"
  echo "║                                          ║"
  echo "║     🛠️  SYSTEM MAINTENANCE MENU           ║"
  echo "║                                          ║"
  echo "╚══════════════════════════════════════════╝"
  echo -e "${NC}"

  echo -e "${BOLD}${YELLOW}Choose an option:${NC}"
  echo -e "${BLUE}  [1]${NC} 🔄 Update the system"
  echo -e "${BLUE}  [2]${NC} 🧹 Clean the system"
  echo -e "${BLUE}  [3]${NC} 🧹🧠 Clean old kernels"
  echo -e "${BLUE}  [4]${NC} 🔄🧹 Update and Clean"
  echo -e "${BLUE}  [0]${NC} ❌ Exit"
  echo ""
  read -p "👉 Enter your option [0-4]: " option

  case $option in
    1) 
      update 
      reboot_prompt
      read -p "🔙 Press ENTER to return to menu..."
      ;;
    2) 
      cleanup 
      reboot_prompt
      read -p "🔙 Press ENTER to return to menu..."
      ;;
    3) 
      cleanup_kernels
      read -p "🔙 Press ENTER to return to menu..."
      ;;
    4) 
      update
      cleanup 
      reboot_prompt
      read -p "🔙 Press ENTER to return to menu..."
      ;;
    0) 
      echo -e "${GREEN}👋 Exiting... See you later!${NC}"
      exit 0
      ;;
    *) 
      echo -e "${RED}❌ Invalid option. Try again.${NC}"
      sleep 2
      ;;
  esac
done

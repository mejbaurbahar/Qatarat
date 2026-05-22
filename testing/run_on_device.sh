#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#   Qatarat — USB Device Test Runner
#   Connect your Android phone via USB and run any test suite.
#   No emulator, no setup knowledge needed.
# ═══════════════════════════════════════════════════════════════════

set -e

# ── Colours ─────────────────────────────────────────────────────────
BOLD='\033[1m';    RESET='\033[0m'
GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m';   CYAN='\033[0;36m'
BLUE='\033[0;34m';  DIM='\033[2m'

log()     { echo -e "${GREEN}${BOLD}[✓]${RESET} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $1"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $1"; }
step()    { echo -e "\n${CYAN}${BOLD}▶  $1${RESET}"; }
info()    { echo -e "${DIM}    $1${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_PATH="$SCRIPT_DIR/../Qatarat (Lambda-Stage).apk"

# ── PATH setup ──────────────────────────────────────────────────────
# Resolve JAVA_HOME — prefer user env, then Homebrew Apple Silicon, then Intel
if [ -z "$JAVA_HOME" ]; then
  if   [ -d "/opt/homebrew/opt/openjdk@17" ]; then JAVA_HOME="/opt/homebrew/opt/openjdk@17"
  elif [ -d "/usr/local/opt/openjdk@17" ];    then JAVA_HOME="/usr/local/opt/openjdk@17"
  elif command -v java &>/dev/null;            then JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
  fi
fi
# Resolve ANDROID_HOME — prefer user env, then standard locations
if [ -z "$ANDROID_HOME" ]; then
  if   [ -d "$HOME/Library/Android/sdk" ];   then ANDROID_HOME="$HOME/Library/Android/sdk"
  elif [ -d "$HOME/Android/sdk" ];            then ANDROID_HOME="$HOME/Android/sdk"
  fi
fi
export JAVA_HOME ANDROID_HOME
export PATH="${JAVA_HOME:+$JAVA_HOME/bin:}$HOME/.maestro/bin:${ANDROID_HOME:+$ANDROID_HOME/platform-tools:}$PATH"

# ── Banner ──────────────────────────────────────────────────────────
clear
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ██████╗  █████╗ ████████╗ █████╗ ██████╗  █████╗ ████████╗"
echo "  ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝"
echo "  ██║  ██║███████║   ██║   ███████║██████╔╝███████║   ██║   "
echo "  ██║  ██║██╔══██║   ██║   ██╔══██║██╔══██╗██╔══██║   ██║   "
echo "  ██████╔╝██║  ██║   ██║   ██║  ██║██║  ██║██║  ██║   ██║   "
echo "  ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   "
echo -e "${RESET}"
echo -e "  ${BOLD}Qatarat (قطرات) — Mobile Test Runner${RESET}"
echo -e "  ${DIM}Android USB Device Edition${RESET}"
echo ""
echo "  ─────────────────────────────────────────────────────────"
echo ""

# ── Prerequisites check ─────────────────────────────────────────────
step "Checking tools..."

MISSING=()
command -v java    &>/dev/null || MISSING+=("Java 17  →  run: cd testing && ./install.sh")
command -v adb     &>/dev/null || MISSING+=("ADB      →  run: cd testing && ./install.sh")
command -v maestro &>/dev/null || MISSING+=("Maestro  →  run: cd testing && ./install.sh")

if [ ${#MISSING[@]} -gt 0 ]; then
  error "Missing tools:"
  for m in "${MISSING[@]}"; do echo -e "    ${RED}•${RESET} $m"; done
  echo ""
  read -p "  Run install.sh now? (y/n): " DO_INSTALL
  if [[ "$DO_INSTALL" =~ ^[Yy]$ ]]; then
    "$SCRIPT_DIR/install.sh"
    source ~/.zshrc 2>/dev/null || true
    export PATH="$JAVA_HOME/bin:$HOME/.maestro/bin:$ANDROID_HOME/platform-tools:$PATH"
  else
    exit 1
  fi
fi
log "All tools found"

# ── APK check ───────────────────────────────────────────────────────
if [ ! -f "$APK_PATH" ]; then
  error "APK not found at: $APK_PATH"
  echo ""
  echo "  Put 'Qatarat (Lambda-Stage).apk' in the project root folder."
  exit 1
fi
APK_SIZE=$(du -sh "$APK_PATH" | cut -f1)
log "APK found ($APK_SIZE)"

# ── USB device detection ────────────────────────────────────────────
step "Looking for a connected Android device..."
echo ""
echo -e "  ${YELLOW}How to enable USB Debugging:${RESET}"
echo -e "  ${DIM}1. Settings → About Phone → tap 'Build Number' 7 times${RESET}"
echo -e "  ${DIM}2. Settings → Developer Options → enable 'USB Debugging'${RESET}"
echo -e "  ${DIM}3. Connect phone via USB cable (use data cable, not charge-only)${RESET}"
echo -e "  ${DIM}4. Unlock phone and tap 'Allow' on the USB Debugging dialog${RESET}"
echo ""

# Kill & restart ADB server — clears stale state that hides real devices
printf "  Resetting ADB server..."
adb kill-server 2>/dev/null; adb start-server 2>/dev/null
echo -e " ${DIM}done${RESET}"
echo ""

# Wait up to 90 seconds, showing live adb devices output so user can see 'unauthorized'
MAX_WAIT=90
WAIT=0
DEVICE_ID=""
LAST_STATE=""

while [ $WAIT -lt $MAX_WAIT ]; do
  # Get raw adb devices lines (skip header and blank)
  RAW=$(adb devices 2>/dev/null | tail -n +2 | grep -v "^$" || true)

  # Check for fully authorised device
  DEVICE_LINE=$(echo "$RAW" | grep "device$" | head -1)
  if [ -n "$DEVICE_LINE" ]; then
    DEVICE_ID=$(echo "$DEVICE_LINE" | awk '{print $1}')
    break
  fi

  # Check for device seen but not yet authorized
  UNAUTH=$(echo "$RAW" | grep "unauthorized" | head -1)
  if [ -n "$UNAUTH" ]; then
    UNAUTH_ID=$(echo "$UNAUTH" | awk '{print $1}')
    if [ "$LAST_STATE" != "unauthorized:$UNAUTH_ID" ]; then
      echo ""
      echo -e "  ${YELLOW}${BOLD}[!]${RESET} Phone detected (${UNAUTH_ID}) but USB Debugging not authorized yet."
      echo -e "  ${BOLD}    → Unlock your phone and tap 'Allow' on the USB Debugging dialog.${RESET}"
      echo -e "  ${DIM}    Waiting for authorization...${RESET}"
      LAST_STATE="unauthorized:$UNAUTH_ID"
    fi
  else
    # No device at all
    if [ "$LAST_STATE" != "nodevice" ]; then
      LAST_STATE="nodevice"
    fi
    printf "\r  ${YELLOW}Waiting for device...${RESET} ${DIM}${WAIT}s / ${MAX_WAIT}s${RESET}   "
  fi

  sleep 2
  WAIT=$((WAIT + 2))
done
echo ""

if [ -z "$DEVICE_ID" ]; then
  echo ""
  error "No device found after ${MAX_WAIT} seconds."
  echo ""
  echo -e "  ${BOLD}Diagnostics:${RESET}"
  echo -e "  ${DIM}Run this to see what ADB sees:${RESET}"
  echo ""
  echo -e "    ${CYAN}adb devices${RESET}"
  echo ""
  echo -e "  ${BOLD}Common fixes:${RESET}"
  echo -e "  ${CYAN}•${RESET} ${BOLD}Swap the USB cable${RESET} — charge-only cables have no data pins"
  echo -e "  ${CYAN}•${RESET} Try a different USB port on your Mac"
  echo -e "  ${CYAN}•${RESET} Unlock the phone and check for the 'Allow USB Debugging' popup"
  echo -e "  ${CYAN}•${RESET} Revoke & re-grant USB debugging: Developer Options → Revoke USB debugging authorizations"
  echo -e "  ${CYAN}•${RESET} On Samsung: enable both 'USB Debugging' AND 'Install via USB'"
  echo -e "  ${CYAN}•${RESET} Try: ${CYAN}adb kill-server && adb start-server && adb devices${RESET}"
  echo ""
  exit 1
fi

echo ""
echo ""
# Get device info
DEVICE_MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
DEVICE_ANDROID=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
DEVICE_NAME=$(adb -s "$DEVICE_ID" shell getprop ro.product.brand 2>/dev/null | tr -d '\r')

log "Device connected!"
echo ""
echo -e "  ${BOLD}Device:${RESET}  $DEVICE_NAME $DEVICE_MODEL"
echo -e "  ${BOLD}Android:${RESET} $DEVICE_ANDROID"
echo -e "  ${BOLD}ID:${RESET}      $DEVICE_ID"
echo ""

# ── Install APK ─────────────────────────────────────────────────────
step "Installing Qatarat app on device..."
adb -s "$DEVICE_ID" install -r "$APK_PATH" 2>&1 | grep -E "Success|Failure|error" || true
log "App installed"

# ── Test menu ───────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────────────"
echo -e "  ${BOLD}  What do you want to test?${RESET}"
echo "  ─────────────────────────────────────────────────────────"
echo ""
echo -e "  ${CYAN}${BOLD}  MAESTRO (quick UI flows)${RESET}"
echo -e "  ${BOLD}  1)${RESET} Smoke Suite        ${DIM}~5 min  — login, cart, checkout${RESET}"
echo -e "  ${BOLD}  2)${RESET} Full Regression     ${DIM}~20 min — all 11 flows${RESET}"
echo ""
echo -e "  ${CYAN}${BOLD}  SINGLE FLOWS${RESET}"
echo -e "  ${BOLD}  3)${RESET} Login / OTP"
echo -e "  ${BOLD}  4)${RESET} Cart + Add Items"
echo -e "  ${BOLD}  5)${RESET} Checkout + Payment selection"
echo -e "  ${BOLD}  6)${RESET} Gift Card"
echo -e "  ${BOLD}  7)${RESET} My Orders + Rating"
echo -e "  ${BOLD}  8)${RESET} Subscription"
echo -e "  ${BOLD}  9)${RESET} Multi-language"
echo ""
echo -e "  ${CYAN}${BOLD}  APPIUM (deep tests — needs Appium running)${RESET}"
echo -e "  ${BOLD}  a)${RESET} Payment Tests      ${DIM}card, Tabby, bank transfer${RESET}"
echo -e "  ${BOLD}  b)${RESET} Gift Card Tests"
echo -e "  ${BOLD}  c)${RESET} Subscription Tests"
echo -e "  ${BOLD}  d)${RESET} All Appium Tests    ${DIM}~45 min${RESET}"
echo ""
echo "  ─────────────────────────────────────────────────────────"
echo ""
read -p "  Enter choice [1-9, a-d]: " CHOICE
echo ""

# ── Run selection ───────────────────────────────────────────────────
run_maestro() {
  local FLOW="$1"
  local LABEL="$2"
  step "Running: $LABEL"
  maestro \
    --device "$DEVICE_ID" \
    test "$FLOW" \
    --format junit \
    --output "$SCRIPT_DIR/maestro/reports/device-run-$(date +%Y%m%d-%H%M%S).xml"
}

run_appium() {
  local MARKER="$1"
  local LABEL="$2"
  step "Running: $LABEL"

  # Start Appium if not running
  if ! curl -s http://127.0.0.1:4723/status &>/dev/null; then
    warn "Starting Appium server..."
    appium --port 4723 --log /tmp/appium-device.log &
    sleep 4
  fi

  DEVICE_MODE=device \
  ANDROID_UDID="$DEVICE_ID" \
    "$SCRIPT_DIR/appium/.venv/bin/python" -m pytest \
      "$SCRIPT_DIR/appium/tests/" \
      -m "$MARKER" -v \
      --html="$SCRIPT_DIR/appium/reports/device-run-$(date +%Y%m%d-%H%M%S).html" \
      --self-contained-html \
      --tb=short
}

mkdir -p "$SCRIPT_DIR/maestro/reports" "$SCRIPT_DIR/appium/reports/screenshots"

case "$CHOICE" in
  1) run_maestro "$SCRIPT_DIR/maestro/flows/suites/smoke.yaml"      "Smoke Suite" ;;
  2) run_maestro "$SCRIPT_DIR/maestro/flows/suites/regression.yaml" "Full Regression" ;;
  3) run_maestro "$SCRIPT_DIR/maestro/flows/02_login_otp.yaml"      "Login / OTP" ;;
  4) run_maestro "$SCRIPT_DIR/maestro/flows/05_cart_add_items.yaml" "Cart + Add Items" ;;
  5) run_maestro "$SCRIPT_DIR/maestro/flows/06_checkout_payment_select.yaml" "Checkout" ;;
  6) run_maestro "$SCRIPT_DIR/maestro/flows/07_gift_card.yaml"      "Gift Card" ;;
  7) run_maestro "$SCRIPT_DIR/maestro/flows/08_my_orders.yaml"      "My Orders + Rating" ;;
  8) run_maestro "$SCRIPT_DIR/maestro/flows/09_subscription.yaml"   "Subscription" ;;
  9) run_maestro "$SCRIPT_DIR/maestro/flows/10_multilanguage.yaml"  "Multi-language" ;;
  a|A) run_appium "payment"      "Payment Tests (card, Tabby, bank)" ;;
  b|B) run_appium "gift"         "Gift Card Tests" ;;
  c|C) run_appium "subscription" "Subscription Tests" ;;
  d|D) run_appium ""             "All Appium Tests" ;;
  *)
    warn "Invalid choice: $CHOICE"
    exit 1
    ;;
esac

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────────────"
log "Run complete!"
echo ""
echo -e "  ${BOLD}Reports saved to:${RESET}"
echo -e "  ${DIM}  Maestro: testing/maestro/reports/${RESET}"
echo -e "  ${DIM}  Appium:  testing/appium/reports/${RESET}"
echo ""
echo -e "  ${DIM}Run again anytime:  cd testing && ./run_on_device.sh${RESET}"
echo ""

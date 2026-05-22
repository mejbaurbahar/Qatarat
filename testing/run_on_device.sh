#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#   Qatarat — Wireless Device Test Runner
#   Run all 25 Maestro flows on a REAL device — no USB, no emulator.
#   WiFi only.  Tests run in the background; terminal stays free.
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colours ─────────────────────────────────────────────────────────
BOLD='\033[1m';    RESET='\033[0m'
GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m';   CYAN='\033[0;36m'
BLUE='\033[0;34m';  DIM='\033[2m'
MAGENTA='\033[0;35m'

log()     { echo -e "${GREEN}${BOLD}[✓]${RESET} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $1"; }
error()   { echo -e "${RED}${BOLD}[✗]${RESET} $1" >&2; }
step()    { echo -e "\n${CYAN}${BOLD}▶  $1${RESET}"; }
info()    { echo -e "  ${DIM}$1${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLOWS_DIR="$SCRIPT_DIR/maestro/flows"
REPORTS_DIR="$SCRIPT_DIR/reports/maestro"
APK_PATH="$SCRIPT_DIR/../Qatarat (Lambda-Stage).apk"
REPORT_TS=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$REPORTS_DIR/run_${REPORT_TS}.log"

# ── PATH setup ──────────────────────────────────────────────────────
for _java in /opt/homebrew/opt/openjdk@17 /usr/local/opt/openjdk@17; do
  [ -d "$_java" ] && { export JAVA_HOME="$_java"; break; }
done
for _sdk in "$HOME/Library/Android/sdk" "$HOME/Android/sdk" "$HOME/.qatarat-android-sdk"; do
  [ -d "$_sdk" ] && { export ANDROID_HOME="$_sdk"; break; }
done
export PATH="${JAVA_HOME:+$JAVA_HOME/bin:}$HOME/.maestro/bin:${ANDROID_HOME:+$ANDROID_HOME/platform-tools:}/opt/homebrew/bin:/usr/local/bin:$PATH"

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
echo -e "  ${BOLD}Qatarat (قطرات) — Wireless Test Runner${RESET}"
echo -e "  ${DIM}Real device · No USB · No emulator · Runs in background${RESET}"
echo ""
echo "  ─────────────────────────────────────────────────────────"
echo ""

# ── Prerequisites ───────────────────────────────────────────────────
step "Checking tools..."
MISSING=()
command -v adb     &>/dev/null || MISSING+=(adb)
command -v maestro &>/dev/null || MISSING+=(maestro)

if [ ${#MISSING[@]} -gt 0 ]; then
  error "Missing: ${MISSING[*]}"
  echo ""
  echo -e "  Install with:  ${CYAN}cd testing && bash install.sh${RESET}"
  exit 1
fi
log "adb + maestro found"

# ── Platform selection ───────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Which device platform?${RESET}"
echo ""
echo -e "  ${BOLD}  1)${RESET} Android"
echo -e "  ${BOLD}  2)${RESET} iPhone (iOS)"
echo ""
read -rp "  Enter choice [1 or 2, default=1]: " PLATFORM_CHOICE
PLATFORM_CHOICE="${PLATFORM_CHOICE:-1}"
case "$PLATFORM_CHOICE" in
  2) PLATFORM="ios" ;;
  *) PLATFORM="android" ;;
esac

# ═══════════════════════════════════════════════════════════════════
#   ANDROID — WiFi connection
# ═══════════════════════════════════════════════════════════════════
if [ "$PLATFORM" = "android" ]; then

  echo ""
  echo "  ─────────────────────────────────────────────────────────"
  echo -e "  ${BOLD}How do you want to connect?${RESET}  (no USB required)"
  echo "  ─────────────────────────────────────────────────────────"
  echo ""
  echo -e "  ${BOLD}  1)${RESET} ${GREEN}WiFi — Android 11+ Wireless Debugging${RESET}"
  echo -e "     ${DIM}Settings → Developer Options → Wireless debugging${RESET}"
  echo -e "     ${DIM}Tap 'Pair device with pairing code' → enter IP:port + code${RESET}"
  echo ""
  echo -e "  ${BOLD}  2)${RESET} ${CYAN}WiFi — Enter device IP directly${RESET}"
  echo -e "     ${DIM}Developer Options → enable 'ADB over network' or 'Wireless debugging'${RESET}"
  echo -e "     ${DIM}Then just enter the IP shown on that screen${RESET}"
  echo ""
  echo -e "  ${BOLD}  3)${RESET} USB cable"
  echo ""
  read -rp "  Enter choice [1/2/3, default=1]: " CONN_CHOICE
  CONN_CHOICE="${CONN_CHOICE:-1}"
  echo ""

  case "$CONN_CHOICE" in

    # ── Wireless Debugging — Android 11+ ──────────────────────────
    1)
      echo -e "  ${YELLOW}${BOLD}Steps on your Android phone:${RESET}"
      echo ""
      echo -e "  ${CYAN}1.${RESET} Settings  →  About phone  →  tap 'Build number' 7 times"
      echo -e "  ${CYAN}2.${RESET} Settings  →  Developer options  →  Wireless debugging  →  toggle ON"
      echo -e "  ${CYAN}3.${RESET} Tap ${BOLD}'Pair device with pairing code'${RESET}"
      echo -e "     It shows a popup with:  ${BOLD}IP address & Port${RESET}  and a  ${BOLD}6-digit code${RESET}"
      echo ""
      read -rp "  Enter IP:port from popup (e.g. 192.168.1.5:39753): " PAIR_ADDR
      read -rp "  Enter 6-digit pairing code: " PAIR_CODE
      echo ""
      step "Pairing device..."
      if adb pair "$PAIR_ADDR" "$PAIR_CODE"; then
        log "Paired successfully"
      else
        error "Pairing failed — make sure IP:port and code match exactly"
        exit 1
      fi
      echo ""
      echo -e "  ${DIM}Now go back to the 'Wireless debugging' main screen.${RESET}"
      echo -e "  ${DIM}It shows a second  IP:port  (the one used for connecting — often port 5555).${RESET}"
      echo ""
      WIFI_IP="${PAIR_ADDR%%:*}"
      read -rp "  Enter the IP:port from the Wireless debugging main screen (e.g. 192.168.1.5:5555): " CONN_ADDR
      CONN_ADDR="${CONN_ADDR:-$WIFI_IP:5555}"
      step "Connecting to $CONN_ADDR..."
      if adb connect "$CONN_ADDR"; then
        log "Connected to $CONN_ADDR"
        DEVICE_TARGET="$CONN_ADDR"
      else
        error "Connection failed — check that Wireless debugging is still ON on the device"
        exit 1
      fi
      ;;

    # ── Enter IP directly ─────────────────────────────────────────
    2)
      echo -e "  ${YELLOW}${BOLD}Enable on your phone first:${RESET}"
      echo -e "  ${DIM}  Option A: Settings → Developer options → 'ADB over network' → toggle ON${RESET}"
      echo -e "  ${DIM}  Option B: Settings → Developer options → Wireless debugging → toggle ON${RESET}"
      echo -e "  ${DIM}  The IP address is shown on that page.${RESET}"
      echo ""
      read -rp "  Enter device IP address (e.g. 192.168.1.42): " WIFI_IP
      read -rp "  Port [default 5555]: " WIFI_PORT
      WIFI_PORT="${WIFI_PORT:-5555}"
      CONN_ADDR="$WIFI_IP:$WIFI_PORT"
      step "Connecting to $CONN_ADDR..."
      if adb connect "$CONN_ADDR"; then
        log "Connected to $CONN_ADDR"
        DEVICE_TARGET="$CONN_ADDR"
      else
        error "Cannot reach $CONN_ADDR — is the device on the same WiFi network?"
        echo ""
        echo -e "  ${DIM}Tip: device must be on the same LAN as this computer.${RESET}"
        echo -e "  ${DIM}Check: ping $WIFI_IP${RESET}"
        exit 1
      fi
      ;;

    # ── USB ───────────────────────────────────────────────────────
    3)
      step "Waiting for USB device..."
      echo ""
      echo -e "  ${DIM}Settings → About phone → tap 'Build number' 7 times${RESET}"
      echo -e "  ${DIM}Settings → Developer options → enable 'USB debugging'${RESET}"
      echo -e "  ${DIM}Connect USB cable → tap 'Allow' on the phone${RESET}"
      echo ""
      adb kill-server 2>/dev/null; adb start-server 2>/dev/null
      MAX_WAIT=90; WAIT=0; DEVICE_TARGET=""; LAST_STATE=""
      while [ $WAIT -lt $MAX_WAIT ]; do
        RAW=$(adb devices 2>/dev/null | tail -n +2 | grep -v "^$" || true)
        DEVICE_LINE=$(echo "$RAW" | grep "device$" | head -1)
        if [ -n "$DEVICE_LINE" ]; then
          DEVICE_TARGET=$(echo "$DEVICE_LINE" | awk '{print $1}')
          break
        fi
        UNAUTH=$(echo "$RAW" | grep "unauthorized" | head -1)
        if [ -n "$UNAUTH" ] && [ "$LAST_STATE" != "unauth" ]; then
          echo -e "  ${YELLOW}${BOLD}[!]${RESET} Phone detected but not authorized — tap 'Allow' on the USB Debugging dialog"
          LAST_STATE="unauth"
        else
          printf "\r  Waiting for device... %ds / %ds   " "$WAIT" "$MAX_WAIT"
          LAST_STATE="none"
        fi
        sleep 2; WAIT=$((WAIT + 2))
      done
      echo ""
      [ -z "$DEVICE_TARGET" ] && { error "No device found after ${MAX_WAIT}s."; exit 1; }
      log "USB device found: $DEVICE_TARGET"
      ;;

    *)
      error "Invalid choice"; exit 1 ;;
  esac

  # ── Pick if multiple devices ─────────────────────────────────────
  # (may have USB + WiFi both connected)
  DEVICE_LIST=$(adb devices 2>/dev/null | tail -n +2 | grep "device$" || true)
  DEVICE_COUNT=$(echo "$DEVICE_LIST" | grep -c "device$" || true)
  if [ "$DEVICE_COUNT" -gt 1 ]; then
    echo ""
    warn "Multiple devices detected — please choose one:"
    echo ""
    i=1
    declare -a SERIALS
    while IFS= read -r line; do
      SER=$(echo "$line" | awk '{print $1}')
      MOD=$(adb -s "$SER" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "?")
      SERIALS+=("$SER")
      echo -e "  ${BOLD}  $i)${RESET} $SER  ${DIM}($MOD)${RESET}"
      ((i++))
    done <<< "$DEVICE_LIST"
    echo ""
    read -rp "  Choose device [1-$((i-1))]: " SEL
    DEVICE_TARGET="${SERIALS[$((SEL-1))]}"
  fi

  # ── Device info ──────────────────────────────────────────────────
  DEVICE_MODEL=$(adb -s "$DEVICE_TARGET" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "?")
  DEVICE_VER=$(  adb -s "$DEVICE_TARGET" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || echo "?")
  DEVICE_BRAND=$(adb -s "$DEVICE_TARGET" shell getprop ro.product.brand 2>/dev/null | tr -d '\r' || echo "?")
  echo ""
  echo "  ─────────────────────────────────────────────────────────"
  log "Device ready"
  echo ""
  echo -e "  ${BOLD}Device:${RESET}  $DEVICE_BRAND $DEVICE_MODEL"
  echo -e "  ${BOLD}Android:${RESET} $DEVICE_VER"
  echo -e "  ${BOLD}Serial:${RESET}  $DEVICE_TARGET"
  echo ""

  # ── Install APK ──────────────────────────────────────────────────
  if [ -f "$APK_PATH" ]; then
    step "Installing Qatarat app..."
    if adb -s "$DEVICE_TARGET" install -r "$APK_PATH" 2>&1 | grep -q "Success"; then
      log "App installed"
    else
      warn "Install had warnings — app may already be up to date, continuing..."
    fi
  else
    warn "APK not found at project root — assuming app is already installed on device"
  fi

# ═══════════════════════════════════════════════════════════════════
#   iOS PATH
# ═══════════════════════════════════════════════════════════════════
else

  # iOS needs idb-companion
  if ! command -v idb_companion &>/dev/null; then
    warn "idb-companion not found — required for Maestro on iOS"
    if command -v brew &>/dev/null; then
      step "Installing idb-companion..."
      brew install facebook/fb/idb-companion 2>/dev/null || \
        { error "Install failed: brew install facebook/fb/idb-companion"; exit 1; }
    else
      error "Install idb-companion: brew install facebook/fb/idb-companion"; exit 1
    fi
  fi

  step "Looking for a connected iPhone..."
  echo ""
  echo -e "  ${DIM}1. Connect iPhone via USB (required for initial trust) or use Wi-Fi sync${RESET}"
  echo -e "  ${DIM}2. Unlock iPhone → tap 'Trust' → enter passcode${RESET}"
  echo -e "  ${DIM}Note: app must already be installed via Xcode or TestFlight${RESET}"
  echo ""

  MAX_WAIT=90; WAIT=0; DEVICE_TARGET=""
  while [ $WAIT -lt $MAX_WAIT ]; do
    DEVICES_RAW=$(xcrun xctrace list devices 2>/dev/null | grep -E "iPhone|iPad" | grep -v "Simulator" | grep -v "^==" || true)
    if [ -n "$DEVICES_RAW" ]; then
      FIRST_LINE=$(echo "$DEVICES_RAW" | head -1)
      UDID=$(echo "$FIRST_LINE" | grep -oE '\([A-F0-9a-f-]{36,}\)' | tr -d '()' | head -1)
      if [ -n "$UDID" ]; then
        DEVICE_TARGET="$UDID"
        DEVICE_MODEL=$(echo "$FIRST_LINE" | sed 's/ ([^)]*) ([^)]*)//')
        break
      fi
    fi
    printf "\r  Waiting for iPhone... %ds / %ds   " "$WAIT" "$MAX_WAIT"
    sleep 2; WAIT=$((WAIT + 2))
  done
  echo ""
  [ -z "$DEVICE_TARGET" ] && { error "No iPhone found. Check connection and trust dialog."; exit 1; }
  log "iPhone connected!"
  echo -e "  ${BOLD}Device:${RESET} $DEVICE_MODEL"
  echo -e "  ${BOLD}UDID:${RESET}   $DEVICE_TARGET"
  echo ""

fi  # end platform branch

# ── Test suite menu ──────────────────────────────────────────────────
echo "  ─────────────────────────────────────────────────────────"
echo -e "  ${BOLD}  Which flows to run?${RESET}"
echo "  ─────────────────────────────────────────────────────────"
echo ""
echo -e "  ${BOLD}  1)${RESET} ${GREEN}All 25 flows${RESET}  ${DIM}~40 min  — complete regression${RESET}"
echo -e "  ${BOLD}  2)${RESET} Smoke only    ${DIM}~10 min  — flows 01-05 (login, onboard, browse, cart)${RESET}"
echo -e "  ${BOLD}  3)${RESET} Single flow   ${DIM}enter flow number (e.g. 12)${RESET}"
echo ""
read -rp "  Enter choice [1/2/3, default=1]: " SUITE_CHOICE
SUITE_CHOICE="${SUITE_CHOICE:-1}"
echo ""

# Build the list of flow files to run
FLOW_FILES=()
case "$SUITE_CHOICE" in
  1)
    while IFS= read -r -d '' f; do
      FLOW_FILES+=("$f")
    done < <(find "$FLOWS_DIR" -maxdepth 1 -name '[0-9][0-9]_*.yaml' -print0 | sort -z)
    SUITE_LABEL="All 25 flows"
    ;;
  2)
    while IFS= read -r -d '' f; do
      FLOW_FILES+=("$f")
    done < <(find "$FLOWS_DIR" -maxdepth 1 -name '0[1-5]_*.yaml' -print0 | sort -z)
    SUITE_LABEL="Smoke (flows 01-05)"
    ;;
  3)
    read -rp "  Enter flow number (e.g. 12): " FLOW_NUM
    MATCH=$(find "$FLOWS_DIR" -maxdepth 1 -name "${FLOW_NUM}_*.yaml" | head -1)
    if [ -z "$MATCH" ]; then
      error "No flow found matching: ${FLOW_NUM}_*.yaml"
      exit 1
    fi
    FLOW_FILES+=("$MATCH")
    SUITE_LABEL="Flow ${FLOW_NUM}"
    ;;
  *)
    error "Invalid choice"; exit 1 ;;
esac

if [ ${#FLOW_FILES[@]} -eq 0 ]; then
  error "No flow YAML files found in $FLOWS_DIR"
  exit 1
fi

# ── Prepare background run script ───────────────────────────────────
mkdir -p "$REPORTS_DIR"

# Write a sub-script that runs all flows sequentially and logs results
RUN_SCRIPT="/tmp/qatarat_run_${REPORT_TS}.sh"
cat > "$RUN_SCRIPT" <<RUNNER_EOF
#!/usr/bin/env bash
export PATH="$HOME/.maestro/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"
PASS=0; FAIL=0; TOTAL=${#FLOW_FILES[@]}
echo "════════════════════════════════════════════════════════"
echo "  Qatarat Maestro — \$TOTAL flows on $DEVICE_TARGET"
echo "  Suite : $SUITE_LABEL"
echo "  Start : \$(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════"
echo ""
RUNNER_EOF

for flow_yaml in "${FLOW_FILES[@]}"; do
  flow_name="$(basename "$flow_yaml" .yaml)"
  cat >> "$RUN_SCRIPT" <<STEP_EOF
echo "──────────────────────────────────────────────────────"
echo "  [RUN]  $flow_name"
echo "──────────────────────────────────────────────────────"
if maestro --device "$DEVICE_TARGET" test \\
    --format junit \\
    --output "$REPORTS_DIR/${flow_name}-results.xml" \\
    "$flow_yaml" ; then
  echo "  [PASS] $flow_name"
  PASS=\$((PASS+1))
else
  echo "  [FAIL] $flow_name"
  FAIL=\$((FAIL+1))
fi
echo ""
STEP_EOF
done

cat >> "$RUN_SCRIPT" <<FOOTER_EOF
echo "════════════════════════════════════════════════════════"
echo "  DONE  — \$(date '+%Y-%m-%d %H:%M:%S')"
echo "  PASS: \$PASS   FAIL: \$FAIL   TOTAL: \$TOTAL"
echo "  Reports: $REPORTS_DIR"
echo "════════════════════════════════════════════════════════"
[ \$FAIL -eq 0 ] && exit 0 || exit 1
FOOTER_EOF
chmod +x "$RUN_SCRIPT"

# ── Launch in background ─────────────────────────────────────────────
echo -e "  ${BOLD}Starting ${#FLOW_FILES[@]} flows on${RESET} ${GREEN}$DEVICE_TARGET${RESET} ${BOLD}in background...${RESET}"
echo ""

nohup bash "$RUN_SCRIPT" > "$LOG_FILE" 2>&1 &
TEST_PID=$!

echo -e "  ${GREEN}${BOLD}Tests are running in the background!${RESET}"
echo ""
echo -e "  ${BOLD}PID:${RESET}      $TEST_PID"
echo -e "  ${BOLD}Log:${RESET}      $LOG_FILE"
echo -e "  ${BOLD}Reports:${RESET}  $REPORTS_DIR"
echo ""
echo "  ─────────────────────────────────────────────────────────"
echo -e "  ${DIM}Live output below.  Press ${BOLD}Ctrl+C${RESET}${DIM} to detach — tests keep running.${RESET}"
echo -e "  ${DIM}Rejoin anytime:  tail -f $LOG_FILE${RESET}"
echo -e "  ${DIM}Check status:    kill -0 $TEST_PID 2>/dev/null && echo running || echo done${RESET}"
echo "  ─────────────────────────────────────────────────────────"
echo ""

# ── Detachable live tail ─────────────────────────────────────────────
detach_message() {
  echo ""
  echo -e "  ${YELLOW}${BOLD}Detached from log.${RESET}  Tests are still running on the device."
  echo ""
  echo -e "  ${BOLD}Rejoin log:${RESET}   tail -f $LOG_FILE"
  echo -e "  ${BOLD}Check done:${RESET}   kill -0 $TEST_PID 2>/dev/null && echo running || echo finished"
  echo -e "  ${BOLD}See results:${RESET}  ls $REPORTS_DIR"
  echo ""
  exit 0
}
trap 'detach_message' INT TERM

# Follow log until process finishes, then show final lines
tail -f "$LOG_FILE" &
TAIL_PID=$!

# Wait for background test process
set +e
wait "$TEST_PID"
EXIT_CODE=$?
set -e
sleep 1
kill "$TAIL_PID" 2>/dev/null || true

# ── Final summary ─────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────────────"
if [ "$EXIT_CODE" -eq 0 ]; then
  log "${GREEN}All flows passed!${RESET}"
else
  error "Some flows failed — check logs in $REPORTS_DIR"
fi
echo ""
echo -e "  ${BOLD}Full log:${RESET}     $LOG_FILE"
echo -e "  ${BOLD}JUnit XML:${RESET}    $REPORTS_DIR/*-results.xml"
echo -e "  ${BOLD}Run again:${RESET}    cd testing && bash run_on_device.sh"
echo ""

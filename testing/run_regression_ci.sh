#!/usr/bin/env bash
# Regression CI runner — called from reactivecircus/android-emulator-runner script:
# Pass a flow number prefix (e.g. "07") as $1 to run a single flow; omit for all 16.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLOWS_DIR="$SCRIPT_DIR/maestro/flows"
REPORTS_DIR="$SCRIPT_DIR/maestro/reports"
SOLO_FLOW="${1:-}"
mkdir -p "$REPORTS_DIR"

FAIL=0
if [ -n "$SOLO_FLOW" ]; then
  FLOW_FILE="$(ls "$FLOWS_DIR/${SOLO_FLOW}"*.yaml 2>/dev/null | head -1)"
  if [ -z "$FLOW_FILE" ]; then
    echo "ERROR: no flow file found for prefix '$SOLO_FLOW'"
    exit 1
  fi
  name="$(basename "$FLOW_FILE" .yaml)"
  echo "▶  Running single flow: $name"
  maestro test --format junit \
    --output "$REPORTS_DIR/${name}-results.xml" \
    "$FLOW_FILE" \
    && echo "   ✓ $name" \
    || { echo "   ✗ $name FAILED"; FAIL=1; }
else
  for flow_file in "$FLOWS_DIR"/[0-9][0-9]_*.yaml; do
    name="$(basename "$flow_file" .yaml)"
    echo "▶  Running flow: $name"
    maestro test --format junit \
      --output "$REPORTS_DIR/${name}-results.xml" \
      "$flow_file" \
      && echo "   ✓ $name" \
      || { echo "   ✗ $name FAILED"; FAIL=$((FAIL + 1)); }
  done
fi

echo ""
echo "Regression complete: $FAIL flow(s) failed."
exit $FAIL

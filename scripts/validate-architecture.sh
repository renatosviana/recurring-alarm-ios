#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
spec="$root/SPEC.md"
architecture="$root/ARCHITECTURE.md"

require() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Fq -- "$pattern" "$file"; then
    echo "FAIL: $description" >&2
    exit 1
  fi
}

require "$spec" "sound alert or silent notification" "current alert modes are documented"
require "$spec" "it does not guarantee vibration" "silent notifications do not promise haptics"
require "$spec" "Vibration-only while locked" "vibration-only remains a deferred requirement"
require "$spec" "weekly on one or more weekdays" "weekly recurrence remains in scope"
require "$spec" "monthly on one or more dates from 1 to 31" "monthly recurrence remains in scope"
require "$spec" "Monthly on the 31st skips February and April" "invalid monthly-date policy remains documented"
require "$architecture" "one repeating request per selected weekday" "weekly scheduling strategy is documented"
require "$architecture" "This is finite recurrence" "monthly scheduling is bounded"
require "$architecture" "partial" "partial scheduling failures are documented"
require "$architecture" "Request notification authorization" "permission handling is documented"
require "$architecture" "must not be used as a substitute for vibration-only" "deferred vibration-only is not exposed as current behavior"

echo "PASS: current scope and architecture contracts are present"

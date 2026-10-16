#!/usr/bin/env bash
# Compile-check LVGL draw units on Zephyr. Builds only the LVGL library target, one board per draw unit.
#
# Usage: scripts/zephyr.sh [-v] [name...]   (default: all entries)
#        scripts/zephyr.sh --list           print the entry names
#   -v   also print the build output (it always goes to the log)
# Logs: <workspace>/build-check/<name>.log
#
# Status:
#   OK      the LVGL library built
#   OK*     LVGL sources were compiled without errors, but the build failed elsewhere
#           (e.g. Zephyr's lvgl.c on a board without a display)
#   FAIL    an error in lvgl/src, or the build failed before compiling any LVGL source (setup problem)
# "warnings" counts unique warnings in lvgl/src; compare with the baseline in the README.
set -uo pipefail
ws=$(cd "$(dirname "$0")/../.." && pwd)
conf="$ws/sandbox/conf"
cd "$ws"

# name | board | extra cmake args
MATRIX=(
  "pxp|mimxrt1170_evk/mimxrt1176/cm7|-DSHIELD=rk055hdmipi4ma0"
  "dma2d|stm32h7b3i_dk|"
  "dave2d|ek_ra8d1|-DSHIELD=rtkmipilcdb00000be"
  "nemagfx|stm32u5g9j_dk2|"
  "epic|sf32lb52_devkit_lcd|-DEXTRA_CFLAGS=-I$ws/modules/hal/sifli/hal/include"
  "ppa|esp32p4_function_ev_board/esp32p4/hpcore|"
  "eve|native_sim/native/64|"
  "layer_debug|native_sim/native/64|"
  "sw_simple|native_sim/native/64|"
)

if [ "${1:-}" = "--list" ]; then
  for e in "${MATRIX[@]}"; do echo "${e%%|*}"; done
  exit 0
fi

verbose=0
if [ "${1:-}" = "-v" ]; then verbose=1; shift; fi

mkdir -p build-check
want=" $* "
failed=0
for e in "${MATRIX[@]}"; do
  IFS='|' read -r name board extra <<< "$e"
  [ $# -gt 0 ] && [[ "$want" != *" $name "* ]] && continue
  log=build-check/$name.log
  cmd=(west build -p always -b "$board" zephyr/samples/subsys/display/lvgl -d "build-check/$name"
       -t libmodules__lvgl.a -- -DEXTRA_CONF_FILE="$conf/$name.conf" $extra)
  if [ $verbose -eq 1 ]; then "${cmd[@]}" 2>&1 | tee "$log"; else "${cmd[@]}" > "$log" 2>&1; fi
  rc=$?
  errs=$(grep -E "modules/lib/gui/lvgl/src/.*error:" "$log" | sort -u | wc -l)
  warns=$(grep -E "modules/lib/gui/lvgl/src/.*warning:" "$log" | sort -u | wc -l)
  compiled=$(grep -cE "Building C object .*/lvgl/src/" "$log")
  if [ $rc -eq 0 ]; then status=OK
  elif [ "$errs" -eq 0 ] && [ "$compiled" -gt 0 ]; then status="OK*"
  else status=FAIL; failed=1
  fi
  printf '%-12s %-42s %-5s warnings: %s\n' "$name" "$board" "$status" "$warns"
done
exit $failed

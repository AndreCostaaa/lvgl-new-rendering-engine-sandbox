#!/usr/bin/env bash
# Optional: compile-check the G2D draw unit. G2D is used on i.MX Linux, not Zephyr, so this cross-compiles the LVGL
# library with an i.MX Yocto SDK (it provides g2d.h and libg2d).
#
# Usage: scripts/g2d.sh <sdk-environment-setup-script> [lvgl-dir]
#   scripts/g2d.sh /opt/fsl-imx-wayland/6.12-styhead/environment-setup-armv8a-poky-linux
# lvgl-dir defaults to the workspace's modules/lib/gui/lvgl (the branch selected with use-lvgl.sh).
# Log: <workspace>/build-check/g2d.log
set -uo pipefail
[ $# -ge 1 ] || { sed -n '2,8p' "$0"; exit 2; }
ws=$(cd "$(dirname "$0")/../.." && pwd)
env_script=$1
lvgl=${2:-$ws/modules/lib/gui/lvgl}
out=$ws/build-check/g2d
mkdir -p "$ws/build-check"
log=$ws/build-check/g2d.log

# shellcheck disable=SC1090
source "$env_script" || exit 1
cmake -S "$lvgl" -B "$out" -G Ninja -DLV_BUILD_USE_KCONFIG=ON -DLV_BUILD_KCONFIG_ROOT="$lvgl/Kconfig" \
  -DLV_BUILD_DEFCONFIG_PATH="$ws/sandbox/conf/g2d.defconfig" > "$log" 2>&1 &&
ninja -C "$out" >> "$log" 2>&1
rc=$?
errs=$(grep -E "lvgl/src/.*error:" "$log" | sort -u | wc -l)
warns=$(grep -E "lvgl/src/.*warning:" "$log" | sort -u | wc -l)
printf '%-12s %-42s %-5s warnings: %s\n' g2d "i.MX SDK (Linux)" "$([ $rc -eq 0 ] && echo OK || echo FAIL)" "$warns"
[ $rc -eq 0 ] && [ "$errs" -eq 0 ]

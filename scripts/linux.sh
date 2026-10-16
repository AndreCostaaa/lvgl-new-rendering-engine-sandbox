#!/usr/bin/env bash
# Compile-check the draw units that build natively on Linux: VG-Lite (ThorVG simulator), NanoVG, OpenGL ES, SDL.
# Builds the LVGL library with CMake and the host compiler.
#
# Usage: scripts/linux.sh [-v] [name...]   (names: vg_lite nanovg opengles sdl; default: all)
#        scripts/linux.sh --list           print the entry names
#   -v   also print the build output (it always goes to the log)
# Needs CMake, Ninja, a C/C++ compiler and the SDL2, EGL, GLESv2 and GLFW3 development headers.
#
# Environment:
#   LVGL_DIR    LVGL source tree (default: <workspace>/modules/lib/gui/lvgl, the branch chosen with use-lvgl.sh)
#   BUILD_DIR   where builds and logs go (default: <workspace>/build-check)
set -uo pipefail
sandbox=$(cd "$(dirname "$0")/.." && pwd)
ws=$(cd "$sandbox/.." && pwd)
lvgl=${LVGL_DIR:-$ws/modules/lib/gui/lvgl}
out=${BUILD_DIR:-$ws/build-check}

all=(vg_lite nanovg opengles sdl)
if [ "${1:-}" = "--list" ]; then printf '%s\n' "${all[@]}"; exit 0; fi

verbose=0
if [ "${1:-}" = "-v" ]; then verbose=1; shift; fi
names=("$@")
[ ${#names[@]} -eq 0 ] && names=("${all[@]}")

mkdir -p "$out"
failed=0
for name in "${names[@]}"; do
  defconfig=$sandbox/conf/linux/$name.defconfig
  [ -f "$defconfig" ] || { echo "unknown entry: $name" >&2; failed=1; continue; }
  log=$out/linux-$name.log
  bdir=$out/linux-$name
  rm -rf "$bdir"
  build() {
    cmake -S "$lvgl" -B "$bdir" -G Ninja -DLV_BUILD_USE_KCONFIG=ON -DLV_BUILD_KCONFIG_ROOT="$lvgl/Kconfig" \
      -DLV_BUILD_DEFCONFIG_PATH="$defconfig" && ninja -C "$bdir"
  }
  if [ $verbose -eq 1 ]; then build 2>&1 | tee "$log"; else build > "$log" 2>&1; fi
  rc=$?
  warns=$(grep -E "lvgl/src/.*warning:" "$log" | sort -u | wc -l)
  [ $rc -eq 0 ] && status=OK || { status=FAIL; failed=1; }
  printf '%-12s %-42s %-5s warnings: %s\n' "$name" "Linux host" "$status" "$warns"
done
exit $failed

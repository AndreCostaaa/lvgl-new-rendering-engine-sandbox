#!/usr/bin/env bash
# Build every configuration: Zephyr (zephyr.sh) and Linux (linux.sh).
#
# Usage: scripts/check.sh [-v] [name...]   (default: all; names from either script, e.g. pxp sdl)
set -uo pipefail
dir=$(cd "$(dirname "$0")" && pwd)

v=()
if [ "${1:-}" = "-v" ]; then v=(-v); shift; fi

zephyr=(); linux=()
if [ $# -eq 0 ]; then
  mapfile -t zephyr < <("$dir/zephyr.sh" --list)
  mapfile -t linux < <("$dir/linux.sh" --list)
else
  for n in "$@"; do
    if "$dir/zephyr.sh" --list | grep -qx "$n"; then zephyr+=("$n")
    elif "$dir/linux.sh" --list | grep -qx "$n"; then linux+=("$n")
    else echo "unknown entry: $n" >&2; exit 2
    fi
  done
fi

rc=0
[ ${#zephyr[@]} -gt 0 ] && { "$dir/zephyr.sh" "${v[@]}" "${zephyr[@]}" || rc=1; }
[ ${#linux[@]} -gt 0 ] && { "$dir/linux.sh" "${v[@]}" "${linux[@]}" || rc=1; }
exit $rc

#!/usr/bin/env bash
# Put an LVGL branch (e.g. a PR) under the Zephyr glue commits in modules/lib/gui/lvgl.
#
# Usage: scripts/use-lvgl.sh <git-url-or-local-path> <branch>
#   scripts/use-lvgl.sh https://github.com/AndreCostaaa/lvgl.git remove-draw-task
#
# Zephyr pins LVGL to a zephyrproject-rtos/lvgl revision that carries Zephyr-specific glue on top of an LVGL
# release. Those glue commits (GLUE below) are cherry-picked onto the requested branch into a local branch called
# `sandbox`. Missing glue commits (e.g. after a shallow `west update`) are fetched from zephyrproject-rtos/lvgl.
# Update GLUE when the Zephyr revision in west.yml is bumped.
set -euo pipefail
GLUE="43f6dc613749c1b06537a084a413046b39ee2331 c9ffd4692de246eb911c7ba49b78a331b2c63c74"
GLUE_REMOTE=https://github.com/zephyrproject-rtos/lvgl

[ $# -eq 2 ] || { sed -n '2,10p' "$0"; exit 2; }
url=$1; branch=$2
ws=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ws/modules/lib/gui/lvgl"

last=${GLUE##* }
for c in $GLUE; do
  if ! git cat-file -e "$c^{commit}" 2>/dev/null || ! git cat-file -e "$c^^{commit}" 2>/dev/null; then
    git fetch -q --depth=4 "$GLUE_REMOTE" "$last"
    break
  fi
done

git fetch -q --depth=1 "$url" "$branch"
git checkout -q -B sandbox FETCH_HEAD
git -c user.name=sandbox -c user.email=sandbox@localhost cherry-pick $GLUE >/dev/null
echo "modules/lib/gui/lvgl: $branch from $url + Zephyr glue"
git log --oneline -3

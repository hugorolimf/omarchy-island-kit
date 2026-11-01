#!/bin/bash
# Compare installed plugins with their GitHub repositories, without changing them.
# Usage: check-updates.sh <plugin id>...
# Prints one line per plugin: id<TAB>behind<TAB>ahead<TAB>dirty<TAB>version
# A plugin whose repository can't be reached prints: id<TAB>error
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -oBatchMode=yes}"
export LC_ALL=C

plugins_dir="${OMARCHY_PLUGINS_DIR:-$HOME/.config/omarchy/plugins}"

check_one() {
  local id="$1" dir="$plugins_dir/$1" behind ahead dirty=0 version
  [[ $id =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $id != *..* ]] || return 0
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  if ! timeout 20 git -C "$dir" fetch --quiet origin HEAD 2>/dev/null; then
    printf '%s\terror\n' "$id"
    return 0
  fi
  behind=$(git -C "$dir" rev-list --count HEAD..FETCH_HEAD) || return 0
  ahead=$(git -C "$dir" rev-list --count FETCH_HEAD..HEAD) || return 0
  [[ -z $(git -C "$dir" status --porcelain) ]] || dirty=1
  version=$(git -C "$dir" show FETCH_HEAD:manifest.json 2>/dev/null | jq -r '.version // ""' 2>/dev/null | tr -d '\t\r\n')
  # A new commit without a new version has no version to announce.
  [[ $version != "$(jq -r '.version // ""' "$dir/manifest.json" 2>/dev/null)" ]] || version=""
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$behind" "$ahead" "$dirty" "$version"
}

for id in "$@"; do
  check_one "$id" &
done
wait

#!/bin/sh
set -o errexit

which_tool() {
  tool="$(for t in "$@"; do which "$t" || :; done | head -n1)"
  [ -n "$tool" ] || { >&2 echo "ERROR: None of the tools found: $(echo "$@" | sed 's/ /, /g')"; return 1; }
  echo "$tool"
}

runt() {
  path="$1"
  [ "${path##*/}" = "$2" ] || return 0
  shift 2; $path "$@"
}

# Install tools
if [ "${1:-}" = "--os-install" ]; then
  shift; tool="$(which_tool apk apt)"
  runt "$tool" apk add "$@"
  runt "$tool" apt update
  runt "$tool" apt install -y add "$@"
fi
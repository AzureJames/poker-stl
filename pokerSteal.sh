#!/bin/sh
printf '\033c\033]0;%s\a' pokerSteal
base_path="$(dirname "$(realpath "$0")")"
"$base_path/pokerSteal.x86_64" "$@"

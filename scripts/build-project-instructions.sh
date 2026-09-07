#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
output_file="${1:-$repo_root/PROJECT-INSTRUCTIONS.md}"
general_file="$repo_root/GENERAL-5.md"
bootstrap_file="$repo_root/ACTIVATION-BOOTSTRAP.md"

general_version="$(sed -n 's/^Статус: .*General \([0-9][0-9.]*\).*/\1/p' "$general_file" | head -n 1)"
bootstrap_version="$(sed -n 's/^# Activation Bootstrap \([0-9][0-9.]*\)$/\1/p' "$bootstrap_file" | head -n 1)"

if [[ -z "$general_version" || -z "$bootstrap_version" ]]; then
  printf 'Could not determine General or Bootstrap version.\n' >&2
  exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

{
  printf '# General 5 — Project Adapter\n\n'
  printf 'General %s + Activation Bootstrap %s.\n\n' "$general_version" "$bootstrap_version"
  printf '## Ядро General %s\n\n' "$general_version"
  sed -e '${/^$/d;}' "$general_file"
  printf '\n\n## Автоматическая активация\n\n'
  sed -e '${/^$/d;}' "$bootstrap_file"
} > "$tmp_file"

mkdir -p "$(dirname "$output_file")"
mv "$tmp_file" "$output_file"
trap - EXIT

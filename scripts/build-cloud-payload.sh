#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
output_file="${1:-$repo_root/CLOUD-PAYLOAD.md}"
git_file="$repo_root/ACTIVATION-GIT.md"

git_version="$(sed -n 's/^# Activation Git \([0-9][0-9.]*\)$/\1/p' "$git_file" | head -n 1)"

if [[ -z "$git_version" ]]; then
  printf 'Could not determine Activation Git version.\n' >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

"$script_dir/build-project-instructions.sh" "$tmp_dir/base.md"

{
  cat "$tmp_dir/base.md"
  printf '\n\n## Работа с репозиторием\n\n'
  sed -e '${/^$/d;}' "$git_file"
} > "$tmp_dir/payload.md"

mkdir -p "$(dirname "$output_file")"
mv "$tmp_dir/payload.md" "$output_file"
trap - EXIT
rm -rf "$tmp_dir"

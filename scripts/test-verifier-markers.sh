#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/repo"
cp -R "$repo_root/scripts" "$tmp_dir/repo/scripts"
cp "$repo_root/GENERAL-5.md" "$repo_root/ACTIVATION-BOOTSTRAP.md" \
  "$repo_root/PROJECT-INSTRUCTIONS.md" "$repo_root/AGENTS.md" \
  "$repo_root/CLAUDE-CODE-SETUP.sh" "$repo_root/ACTIVATION.md" "$tmp_dir/repo/"

printf '\n<!-- GENERAL-5:BEGIN version=5.0.2 bootstrap=1.2.5 -->\n' >> "$tmp_dir/repo/AGENTS.md"
if bash "$tmp_dir/repo/scripts/verify-artifacts.sh" >/dev/null 2>&1; then
  printf 'Verifier accepted ambiguous General markers.\n' >&2
  exit 1
fi

printf 'Ambiguous General marker rejection passed.\n'

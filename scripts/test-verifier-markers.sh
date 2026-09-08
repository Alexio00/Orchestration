#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/repo"
cp -R "$repo_root/scripts" "$tmp_dir/repo/scripts"
cp -R "$repo_root/.github" "$tmp_dir/repo/.github"
cp "$repo_root/GENERAL-5.md" "$repo_root/ACTIVATION-BOOTSTRAP.md" "$repo_root/ACTIVATION-GIT.md" \
  "$repo_root/PROJECT-INSTRUCTIONS.md" "$repo_root/AGENTS.md" "$repo_root/OPS-DELEGATION.md" \
  "$repo_root/CLAUDE-CODE-SETUP.sh" "$repo_root/ACTIVATION.md" \
  "$repo_root/PROJECT-STATE.md" "$repo_root/.gitignore" "$tmp_dir/repo/"

if ! bash "$tmp_dir/repo/scripts/verify-artifacts.sh" >/dev/null 2>&1; then
  printf 'Fixture is unsound: verifier rejects the untouched copy.\n' >&2
  exit 1
fi

existing_marker="$(grep -m1 -F 'GENERAL-5:BEGIN' "$repo_root/AGENTS.md")"
printf '\n%s\n' "$existing_marker" >> "$tmp_dir/repo/AGENTS.md"
if bash "$tmp_dir/repo/scripts/verify-artifacts.sh" >/dev/null 2>&1; then
  printf 'Verifier accepted ambiguous General markers.\n' >&2
  exit 1
fi

printf 'Ambiguous General marker rejection passed.\n'

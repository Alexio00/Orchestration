#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

source_copy="$tmp_dir/source"
target_copy="$tmp_dir/pages"
mkdir -p "$source_copy/scripts" "$target_copy"
cp "$repo_root/GENERAL-5.md" "$source_copy/GENERAL-5.md"
cp "$repo_root/ACTIVATION-BOOTSTRAP.md" "$source_copy/ACTIVATION-BOOTSTRAP.md"
cp "$repo_root/ACTIVATION-GIT.md" "$source_copy/ACTIVATION-GIT.md"
cp "$repo_root/OPS-DELEGATION.md" "$source_copy/OPS-DELEGATION.md"
cp "$repo_root/PROJECT-INSTRUCTIONS.md" "$source_copy/PROJECT-INSTRUCTIONS.md"
cp "$repo_root/CLAUDE-CODE-SETUP.sh" "$source_copy/CLAUDE-CODE-SETUP.sh"
cp "$repo_root/scripts/publish-pages.sh" "$source_copy/scripts/publish-pages.sh"

general_version="$(sed -n 's/^Статус: \*\*\(candidate\|выпущено\) — General \([0-9][0-9.]*\)\*\*$/\2/p' "$source_copy/GENERAL-5.md" | head -n 1)"
bootstrap_version="$(sed -n 's/^# Activation Bootstrap \([0-9][0-9.]*\)$/\1/p' "$source_copy/ACTIVATION-BOOTSTRAP.md" | head -n 1)"
git_version="$(sed -n 's/^# Activation Git \([0-9][0-9.]*\)$/\1/p' "$source_copy/ACTIVATION-GIT.md" | head -n 1)"
adapter_version="$(sed -n "s/^adapter_version='\([0-9][0-9.]*\)'$/\1/p" "$source_copy/CLAUDE-CODE-SETUP.sh" | head -n 1)"

git -C "$source_copy" init -q
git -C "$source_copy" config user.name test
git -C "$source_copy" config user.email test@example.invalid

sed -i "s/Статус: \*\*выпущено — General $general_version\*\*/Статус: **candidate — General $general_version**/" "$source_copy/GENERAL-5.md"
sed -i "s/Статус: \*\*выпущено — Activation Bootstrap $bootstrap_version\*\*/Статус: **candidate — Activation Bootstrap $bootstrap_version**/" "$source_copy/ACTIVATION-BOOTSTRAP.md"
sed -i "s/Статус: \*\*выпущено — Activation Git $git_version\*\*/Статус: **candidate — Activation Git $git_version**/" "$source_copy/ACTIVATION-GIT.md"
sed -i "s/# Статус: выпущено — Claude Code Cloud Adapter $adapter_version/# Статус: candidate — Claude Code Cloud Adapter $adapter_version/" "$source_copy/CLAUDE-CODE-SETUP.sh"

expect_rejection() {
  local expected="$1"
  local output
  if output="$(bash "$source_copy/scripts/publish-pages.sh" "$source_copy" "$target_copy" "v$general_version" HEAD 2>&1)"; then
    printf 'Publication unexpectedly succeeded.\n' >&2
    exit 1
  fi
  grep -Fq "$expected" <<< "$output"
}

expect_rejection 'without released status'

sed -i "s/Статус: \*\*candidate — General $general_version\*\*/Статус: **выпущено — General $general_version**/" "$source_copy/GENERAL-5.md"
expect_rejection "Activation Bootstrap $bootstrap_version without released status"

sed -i "s/Статус: \*\*candidate — Activation Bootstrap $bootstrap_version\*\*/Статус: **выпущено — Activation Bootstrap $bootstrap_version**/" "$source_copy/ACTIVATION-BOOTSTRAP.md"
expect_rejection "Activation Git $git_version without released status"

sed -i "s/Статус: \*\*candidate — Activation Git $git_version\*\*/Статус: **выпущено — Activation Git $git_version**/" "$source_copy/ACTIVATION-GIT.md"
expect_rejection "Cloud Adapter $adapter_version without released status"

printf 'Publication lifecycle rejection scenarios passed.\n'

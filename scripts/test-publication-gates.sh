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
cp "$repo_root/PROJECT-INSTRUCTIONS.md" "$source_copy/PROJECT-INSTRUCTIONS.md"
cp "$repo_root/CLAUDE-CODE-SETUP.sh" "$source_copy/CLAUDE-CODE-SETUP.sh"
cp "$repo_root/scripts/publish-pages.sh" "$source_copy/scripts/publish-pages.sh"

git -C "$source_copy" init -q
git -C "$source_copy" config user.name test
git -C "$source_copy" config user.email test@example.invalid

sed -i 's/Статус: \*\*выпущено — General 5.0.2\*\*/Статус: **candidate — General 5.0.2**/' "$source_copy/GENERAL-5.md"
sed -i 's/Статус: \*\*выпущено — Activation Bootstrap 1.2.5\*\*/Статус: **candidate — Activation Bootstrap 1.2.5**/' "$source_copy/ACTIVATION-BOOTSTRAP.md"
sed -i 's/# Статус: выпущено — Claude Code Cloud Adapter 1.2.5/# Статус: candidate — Claude Code Cloud Adapter 1.2.5/' "$source_copy/CLAUDE-CODE-SETUP.sh"

expect_rejection() {
  local expected="$1"
  local output
  if output="$(bash "$source_copy/scripts/publish-pages.sh" "$source_copy" "$target_copy" v5.0.2 HEAD 2>&1)"; then
    printf 'Publication unexpectedly succeeded.\n' >&2
    exit 1
  fi
  grep -Fq "$expected" <<< "$output"
}

expect_rejection 'without released status'

sed -i 's/Статус: \*\*candidate — General 5.0.2\*\*/Статус: **выпущено — General 5.0.2**/' "$source_copy/GENERAL-5.md"
expect_rejection 'Activation Bootstrap 1.2.5 without released status'

sed -i 's/Статус: \*\*candidate — Activation Bootstrap 1.2.5\*\*/Статус: **выпущено — Activation Bootstrap 1.2.5**/' "$source_copy/ACTIVATION-BOOTSTRAP.md"
expect_rejection 'Cloud Adapter 1.2.5 without released status'

printf 'Publication lifecycle rejection scenarios passed.\n'

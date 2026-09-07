#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

general_file="$repo_root/GENERAL-5.md"
bootstrap_file="$repo_root/ACTIVATION-BOOTSTRAP.md"
project_file="$repo_root/PROJECT-INSTRUCTIONS.md"
agents_file="$repo_root/AGENTS.md"
setup_file="$repo_root/CLAUDE-CODE-SETUP.sh"

general_version="$(sed -n 's/^Статус: .*General \([0-9][0-9.]*\).*/\1/p' "$general_file" | head -n 1)"
bootstrap_version="$(sed -n 's/^# Activation Bootstrap \([0-9][0-9.]*\)$/\1/p' "$bootstrap_file" | head -n 1)"
adapter_version="$(sed -n 's/^# - Claude Code Cloud Adapter \([0-9][0-9.]*\)$/\1/p' "$setup_file" | head -n 1)"

if [[ -z "$general_version" || -z "$bootstrap_version" || -z "$adapter_version" ]]; then
  printf 'Could not determine component versions.\n' >&2
  exit 1
fi

if grep -Fq 'Статус: **выпущено — General ' "$general_file"; then
  general_tag="v$general_version"
  if ! git -C "$repo_root" rev-parse --verify "refs/tags/$general_tag^{commit}" >/dev/null 2>&1; then
    printf 'Released General tag is missing: %s.\n' "$general_tag" >&2
    exit 1
  fi
  git -C "$repo_root" show "$general_tag:GENERAL-5.md" > "$tmp_dir/tagged-general.md"
  diff -u "$tmp_dir/tagged-general.md" "$general_file"
fi

"$script_dir/build-project-instructions.sh" "$tmp_dir/PROJECT-INSTRUCTIONS.md"
diff -u "$project_file" "$tmp_dir/PROJECT-INSTRUCTIONS.md"
project_characters="$(wc -m < "$project_file")"
if (( project_characters > 8000 )); then
  printf 'PROJECT-INSTRUCTIONS.md exceeds 8000 characters: %s.\n' "$project_characters" >&2
  exit 1
fi

awk '
  $0 == "## Ядро General 5.0.0" { found = 1; next }
  found && !started && $0 == "" { next }
  found && $0 == "<!-- GENERAL-5:END -->" { exit }
  found { started = 1; print }
' "$agents_file" > "$tmp_dir/agents-core.md"
diff -u "$general_file" "$tmp_dir/agents-core.md"

awk '
  $0 == "cat >> \"$tmp_policy\" <<\047GENERAL5_PROJECT_INSTRUCTIONS\047" { extracting = 1; next }
  extracting && $0 == "GENERAL5_PROJECT_INSTRUCTIONS" { exit }
  extracting { print }
' "$setup_file" > "$tmp_dir/setup-payload.md"
diff -u "$project_file" "$tmp_dir/setup-payload.md"

grep -Fxq "<!-- GENERAL-5:BEGIN version=$general_version bootstrap=$bootstrap_version -->" "$agents_file"
grep -Fxq "Activation Bootstrap: $bootstrap_version." "$agents_file"
grep -Fxq "# - Activation Bootstrap $bootstrap_version" "$setup_file"
grep -Fxq "# - Claude Code Cloud Adapter $adapter_version" "$setup_file"
grep -Fxq "begin_marker=\"<!-- GENERAL-5-CLOUD-ADAPTER:BEGIN version=\$adapter_version -->\"" "$setup_file"
grep -Fq "Activation Bootstrap $bootstrap_version и Claude Code Cloud Adapter $adapter_version" "$repo_root/ACTIVATION.md"

bash -n "$setup_file"
bash -n "$script_dir/build-project-instructions.sh"
bash -n "$script_dir/sync-setup-payload.sh"
bash -n "$script_dir/publish-pages.sh"

printf 'Verified General %s, Bootstrap %s and Cloud Adapter %s artifacts.\n' \
  "$general_version" "$bootstrap_version" "$adapter_version"

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

general_file="$repo_root/GENERAL-5.md"
delegation_file="$repo_root/OPS-DELEGATION.md"
state_file="$repo_root/PROJECT-STATE.md"
bootstrap_file="$repo_root/ACTIVATION-BOOTSTRAP.md"
git_file="$repo_root/ACTIVATION-GIT.md"
project_file="$repo_root/PROJECT-INSTRUCTIONS.md"
agents_file="$repo_root/AGENTS.md"
setup_file="$repo_root/CLAUDE-CODE-SETUP.sh"

general_version="$(sed -n 's/^Статус: .*General \([0-9][0-9.]*\).*/\1/p' "$general_file" | head -n 1)"
bootstrap_version="$(sed -n 's/^# Activation Bootstrap \([0-9][0-9.]*\)$/\1/p' "$bootstrap_file" | head -n 1)"
git_version="$(sed -n 's/^# Activation Git \([0-9][0-9.]*\)$/\1/p' "$git_file" | head -n 1)"
adapter_version="$(sed -n 's/^# - Claude Code Cloud Adapter \([0-9][0-9.]*\)$/\1/p' "$setup_file" | head -n 1)"
general_status="$(sed -n 's/^Статус: \*\*\(candidate\|выпущено\) — General .*$/\1/p' "$general_file" | head -n 1)"
bootstrap_status="$(sed -n 's/^Статус: \*\*\(candidate\|выпущено\) — Activation Bootstrap .*$/\1/p' "$bootstrap_file" | head -n 1)"
git_status="$(sed -n 's/^Статус: \*\*\(candidate\|выпущено\) — Activation Git .*$/\1/p' "$git_file" | head -n 1)"
adapter_status="$(sed -n 's/^# Статус: \(candidate\|выпущено\) — Claude Code Cloud Adapter .*$/\1/p' "$setup_file" | head -n 1)"

if [[ -z "$general_version" || -z "$bootstrap_version" || -z "$git_version" || -z "$adapter_version" ]]; then
  printf 'Could not determine component versions.\n' >&2
  exit 1
fi
if [[ -z "$general_status" || "$general_status" != "$bootstrap_status" \
   || "$general_status" != "$git_status" || "$general_status" != "$adapter_status" ]]; then
  printf 'Component lifecycle statuses are missing or inconsistent.\n' >&2
  exit 1
fi
activation_status='candidate'
[[ "$general_status" == 'выпущено' ]] && activation_status='released'
grep -Fq "Статус: $activation_status;" "$repo_root/ACTIVATION.md"

if grep -Fq 'Статус: **выпущено — General ' "$general_file"; then
  general_tag="v$general_version"
  if ! git -C "$repo_root" rev-parse --verify "refs/tags/$general_tag^{commit}" >/dev/null 2>&1; then
    if [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" && "${GITHUB_HEAD_REF:-}" == release/* ]]; then
      printf 'Release tag %s is pending until the verified release PR is merged.\n' "$general_tag"
    else
      printf 'Released General tag is missing: %s.\n' "$general_tag" >&2
      exit 1
    fi
  else
    git -C "$repo_root" show "$general_tag:GENERAL-5.md" > "$tmp_dir/tagged-general.md"
    diff -u "$tmp_dir/tagged-general.md" "$general_file"
  fi
fi

"$script_dir/build-project-instructions.sh" "$tmp_dir/PROJECT-INSTRUCTIONS.md"
diff -u "$project_file" "$tmp_dir/PROJECT-INSTRUCTIONS.md"
"$script_dir/build-cloud-payload.sh" "$tmp_dir/CLOUD-PAYLOAD.md"
project_characters="$(wc -m < "$project_file")"
if (( project_characters > 8000 )); then
  printf 'PROJECT-INSTRUCTIONS.md exceeds 8000 characters: %s.\n' "$project_characters" >&2
  exit 1
fi

general_characters="$(wc -m < "$general_file")"
if (( general_characters > 3000 )); then
  printf 'GENERAL-5.md exceeds the 3000 character budget: %s.\n' "$general_characters" >&2
  exit 1
fi

agents_characters="$(wc -m < "$agents_file")"
if (( agents_characters > 4500 )); then
  printf 'AGENTS.md exceeds the 4500 character budget: %s.\n' "$agents_characters" >&2
  exit 1
fi

state_characters="$(wc -m < "$state_file")"
if (( state_characters > 5500 )); then
  printf 'PROJECT-STATE.md exceeds the 5500 character budget: %s. Снимок не журнал — сократи закрытое.\n' "$state_characters" >&2
  exit 1
fi

if [[ ! -f "$delegation_file" ]]; then
  printf 'OPS-DELEGATION.md is missing.\n' >&2
  exit 1
fi
grep -Fq 'Приложение к General '"$general_version" "$delegation_file"
grep -Fq '`OPS-DELEGATION.md`' "$agents_file"
if grep -qF 'OPS-DELEGATION' "$project_file"; then
  printf 'PROJECT-INSTRUCTIONS.md must not depend on repository-only appendices.\n' >&2
  exit 1
fi

if grep -qF 'GENERAL-5-ACTIVATION repository=' "$project_file"; then
  printf 'PROJECT-INSTRUCTIONS.md must not carry repository-only activation rules.\n' >&2
  exit 1
fi
grep -Fq 'Activation Git' "$tmp_dir/CLOUD-PAYLOAD.md" || {
  printf 'Cloud payload is missing the Activation Git supplement.\n' >&2
  exit 1
}

awk '
  $0 == "## Ядро General " version { found = 1; next }
  found && !started && $0 == "" { next }
  found && $0 == "<!-- GENERAL-5:END -->" { exit }
  found { started = 1; print }
' version="$general_version" "$agents_file" > "$tmp_dir/agents-core.md"
diff -u "$general_file" "$tmp_dir/agents-core.md"

awk '
  $0 == "cat >> \"$tmp_policy\" <<\047GENERAL5_PROJECT_INSTRUCTIONS\047" { extracting = 1; next }
  extracting && $0 == "GENERAL5_PROJECT_INSTRUCTIONS" { exit }
  extracting { print }
' "$setup_file" > "$tmp_dir/setup-payload.md"
diff -u "$tmp_dir/CLOUD-PAYLOAD.md" "$tmp_dir/setup-payload.md"

grep -Fxq "<!-- GENERAL-5:BEGIN version=$general_version bootstrap=$bootstrap_version -->" "$agents_file"
[[ "$(grep -cF 'GENERAL-5:BEGIN' "$agents_file" || true)" == 1 ]]
[[ "$(grep -cF 'GENERAL-5:END' "$agents_file" || true)" == 1 ]]
grep -Fxq "Activation Bootstrap: $bootstrap_version." "$agents_file"
grep -Fxq "# - Activation Bootstrap $bootstrap_version" "$setup_file"
grep -Fxq "# - Activation Git $git_version" "$setup_file"
grep -Fxq "# - Claude Code Cloud Adapter $adapter_version" "$setup_file"
grep -Fxq "begin_marker=\"<!-- GENERAL-5-CLOUD-ADAPTER:BEGIN version=\$adapter_version -->\"" "$setup_file"
grep -Fq "Activation Bootstrap $bootstrap_version, Activation Git $git_version и Claude Code Cloud Adapter $adapter_version" "$repo_root/ACTIVATION.md"

bash -n "$setup_file"
bash -n "$script_dir/build-project-instructions.sh"
bash -n "$script_dir/build-cloud-payload.sh"
bash -n "$script_dir/sync-setup-payload.sh"
bash -n "$script_dir/publish-pages.sh"
grep -Fq "ref: \${{ github.event_name == 'workflow_dispatch' && 'main' || github.event.release.tag_name }}" "$repo_root/.github/workflows/publish-pages.yml"
grep -Fq "if: github.event_name == 'workflow_dispatch' && github.ref != 'refs/heads/main'" "$repo_root/.github/workflows/publish-pages.yml"
grep -Fq 'expected_release_status="Статус: **выпущено — General $general_version**"' "$script_dir/publish-pages.sh"
grep -Fq 'grep -Fxq "$expected_release_status" "$general_file"' "$script_dir/publish-pages.sh"
grep -Fq 'grep -Fxq "$expected_bootstrap_status" "$bootstrap_file"' "$script_dir/publish-pages.sh"
grep -Fq 'cp "$delegation_file" "$snapshot_tmp/ops-delegation.md"' "$script_dir/publish-pages.sh"
grep -Fq 'grep -Fxq "$expected_git_status" "$git_file"' "$script_dir/publish-pages.sh"
grep -Fq 'grep -Fxq "$expected_adapter_status" "$setup_file"' "$script_dir/publish-pages.sh"

printf 'Verified General %s, Bootstrap %s, Activation Git %s and Cloud Adapter %s artifacts.\n' \
  "$general_version" "$bootstrap_version" "$git_version" "$adapter_version"

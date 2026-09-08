#!/usr/bin/env bash
set -euo pipefail

source_root="${1:?source repository root is required}"
target_root="${2:?pages repository root is required}"
release_tag="${3:-v5.0.3}"
source_revision="${4:-unknown}"

general_file="$source_root/GENERAL-5.md"
bootstrap_file="$source_root/ACTIVATION-BOOTSTRAP.md"
git_file="$source_root/ACTIVATION-GIT.md"
delegation_file="$source_root/OPS-DELEGATION.md"
roles_file="$source_root/OPS-ROLES.md"
project_file="$source_root/PROJECT-INSTRUCTIONS.md"
setup_file="$source_root/CLAUDE-CODE-SETUP.sh"

for required in "$general_file" "$bootstrap_file" "$git_file" "$delegation_file" "$roles_file" "$project_file" "$setup_file"; do
  if [[ ! -f "$required" ]]; then
    printf 'Required public artifact is missing: %s\n' "$required" >&2
    exit 1
  fi
done

general_version="$(sed -n 's/^Статус: .*General \([0-9][0-9.]*\).*/\1/p' "$general_file" | head -n 1)"
bootstrap_version="$(sed -n 's/^General [0-9][0-9.]* + Activation Bootstrap \([0-9][0-9.]*\)\.$/\1/p' "$project_file" | head -n 1)"
git_version="$(sed -n 's/^# Activation Git \([0-9][0-9.]*\)$/\1/p' "$git_file" | head -n 1)"
adapter_version="$(sed -n 's/^# - Claude Code Cloud Adapter \([0-9][0-9.]*\)$/\1/p' "$setup_file" | head -n 1)"

if [[ -z "$general_version" || -z "$bootstrap_version" || -z "$git_version" || -z "$adapter_version" ]]; then
  printf 'Could not determine published component versions.\n' >&2
  exit 1
fi

expected_release_status="Статус: **выпущено — General $general_version**"
if ! grep -Fxq "$expected_release_status" "$general_file"; then
  printf 'Refusing to publish General %s without released status.\n' "$general_version" >&2
  exit 1
fi

expected_bootstrap_status="Статус: **выпущено — Activation Bootstrap $bootstrap_version**"
if ! grep -Fxq "$expected_bootstrap_status" "$bootstrap_file"; then
  printf 'Refusing to publish Activation Bootstrap %s without released status.\n' "$bootstrap_version" >&2
  exit 1
fi
expected_git_status="Статус: **выпущено — Activation Git $git_version**"
if ! grep -Fxq "$expected_git_status" "$git_file"; then
  printf 'Refusing to publish Activation Git %s without released status.\n' "$git_version" >&2
  exit 1
fi
expected_adapter_status="# Статус: выпущено — Claude Code Cloud Adapter $adapter_version"
if ! grep -Fxq "$expected_adapter_status" "$setup_file"; then
  printf 'Refusing to publish Claude Code Cloud Adapter %s without released status.\n' "$adapter_version" >&2
  exit 1
fi

if [[ ! "$release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Invalid General release tag: %s\n' "$release_tag" >&2
  exit 1
fi
if [[ "$release_tag" != "v$general_version" ]]; then
  printf 'General release tag %s does not match General %s.\n' "$release_tag" "$general_version" >&2
  exit 1
fi
snapshot_id="$release_tag-bootstrap-$bootstrap_version-git-$git_version-cloud-$adapter_version"
version_dir="$target_root/content/releases/$snapshot_id"
latest_dir="$target_root/content/latest"
snapshot_tmp="$(mktemp -d)"
trap 'rm -rf "$snapshot_tmp"' EXIT

if ! git -C "$source_root" rev-parse --verify "refs/tags/$release_tag^{commit}" >/dev/null 2>&1; then
  printf 'General release tag is missing: %s.\n' "$release_tag" >&2
  exit 1
fi
git -C "$source_root" show "$release_tag:GENERAL-5.md" > "$snapshot_tmp/tagged-general.md"
if ! diff -u "$snapshot_tmp/tagged-general.md" "$general_file"; then
  printf 'GENERAL-5.md differs from release tag %s.\n' "$release_tag" >&2
  exit 1
fi
rm -f "$snapshot_tmp/tagged-general.md"

cp "$general_file" "$snapshot_tmp/general.md"
cp "$delegation_file" "$snapshot_tmp/ops-delegation.md"
cp "$roles_file" "$snapshot_tmp/ops-roles.md"
cp "$project_file" "$snapshot_tmp/project-instructions.md"
cp "$setup_file" "$snapshot_tmp/claude-code-setup.sh"

{
  printf 'Активируй General %s в этом чате. Следующие инструкции действуют до конца текущего чата. Выполни автоматический preflight перед первой содержательной задачей.\n\n' "$general_version"
  cat "$project_file"
} > "$snapshot_tmp/chat-prompt.txt"

release_url="https://github.com/Alexio00/Orchestration/releases/tag/$release_tag"
commit_time="$(git -C "$source_root" show -s --format=%cI "$source_revision" 2>/dev/null || true)"
if [[ -n "$commit_time" ]]; then
  published_at="$(date -u -d "$commit_time" +%Y-%m-%dT%H:%M:%SZ)"
else
  published_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

cat > "$snapshot_tmp/manifest.json" <<JSON
{
  "generalVersion": "$general_version",
  "generalTag": "$release_tag",
  "snapshotId": "$snapshot_id",
  "bootstrapVersion": "$bootstrap_version",
  "activationGitVersion": "$git_version",
  "cloudAdapterVersion": "$adapter_version",
  "sourceRevision": "$source_revision",
  "publishedAt": "$published_at",
  "releaseUrl": "$release_url"
}
JSON

if [[ -e "$version_dir" ]]; then
  if ! diff -qr "$snapshot_tmp" "$version_dir" >/dev/null; then
    printf 'Refusing to rewrite immutable public snapshot: %s\n' "$snapshot_id" >&2
    exit 1
  fi
else
  mkdir -p "$(dirname "$version_dir")"
  cp -R "$snapshot_tmp" "$version_dir"
fi

mkdir -p "$latest_dir"
cp "$version_dir/general.md" "$latest_dir/general.md"
cp "$version_dir/ops-delegation.md" "$latest_dir/ops-delegation.md"
cp "$version_dir/ops-roles.md" "$latest_dir/ops-roles.md"
cp "$version_dir/project-instructions.md" "$latest_dir/project-instructions.md"
cp "$version_dir/claude-code-setup.sh" "$latest_dir/claude-code-setup.sh"
cp "$version_dir/chat-prompt.txt" "$latest_dir/chat-prompt.txt"
cp "$version_dir/manifest.json" "$latest_dir/manifest.json"

printf 'Prepared public artifacts for General %s, Bootstrap %s, Activation Git %s, Cloud Adapter %s.\n' \
  "$general_version" "$bootstrap_version" "$git_version" "$adapter_version"

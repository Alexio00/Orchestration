#!/usr/bin/env bash
set -euo pipefail

source_root="${1:?source repository root is required}"
target_root="${2:?pages repository root is required}"
release_tag="${3:-v5.0.0}"
source_revision="${4:-unknown}"

general_file="$source_root/GENERAL-5.md"
project_file="$source_root/PROJECT-INSTRUCTIONS.md"
setup_file="$source_root/CLAUDE-CODE-SETUP.sh"

for required in "$general_file" "$project_file" "$setup_file"; do
  if [[ ! -f "$required" ]]; then
    printf 'Required public artifact is missing: %s\n' "$required" >&2
    exit 1
  fi
done

general_version="$(sed -n 's/^Статус: .*General \([0-9][0-9.]*\).*/\1/p' "$general_file" | head -n 1)"
bootstrap_version="$(sed -n 's/^General [0-9][0-9.]* + Activation Bootstrap \([0-9][0-9.]*\)\.$/\1/p' "$project_file" | head -n 1)"
adapter_version="$(sed -n 's/^# - Claude Code Cloud Adapter \([0-9][0-9.]*\)$/\1/p' "$setup_file" | head -n 1)"

if [[ -z "$general_version" || -z "$bootstrap_version" || -z "$adapter_version" ]]; then
  printf 'Could not determine published component versions.\n' >&2
  exit 1
fi

snapshot_id="$release_tag-bootstrap-$bootstrap_version-cloud-$adapter_version"
version_dir="$target_root/content/releases/$snapshot_id"
latest_dir="$target_root/content/latest"
snapshot_tmp="$(mktemp -d)"
trap 'rm -rf "$snapshot_tmp"' EXIT

cp "$general_file" "$snapshot_tmp/general.md"
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
cp "$version_dir/project-instructions.md" "$latest_dir/project-instructions.md"
cp "$version_dir/claude-code-setup.sh" "$latest_dir/claude-code-setup.sh"
cp "$version_dir/chat-prompt.txt" "$latest_dir/chat-prompt.txt"
cp "$version_dir/manifest.json" "$latest_dir/manifest.json"

printf 'Prepared public artifacts for General %s, Bootstrap %s, Cloud Adapter %s.\n' \
  "$general_version" "$bootstrap_version" "$adapter_version"

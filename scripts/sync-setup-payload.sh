#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
setup_file="$repo_root/CLAUDE-CODE-SETUP.sh"
payload_dir="$(mktemp -d)"
payload_file="$payload_dir/CLOUD-PAYLOAD.md"
"$script_dir/build-cloud-payload.sh" "$payload_file"
start_line="cat >> \"\$tmp_policy\" <<'GENERAL5_PROJECT_INSTRUCTIONS'"
end_line='GENERAL5_PROJECT_INSTRUCTIONS'
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"; rm -rf "$payload_dir"' EXIT

start_count="$(grep -cFx "$start_line" "$setup_file" || true)"
end_count="$(grep -cFx "$end_line" "$setup_file" || true)"
if [[ "$start_count" != 1 || "$end_count" != 1 ]]; then
  printf 'Setup payload markers are missing or ambiguous.\n' >&2
  exit 1
fi

awk -v start="$start_line" -v finish="$end_line" -v payload="$payload_file" '
  $0 == start {
    print
    while ((getline line < payload) > 0) print line
    close(payload)
    replacing = 1
    next
  }
  replacing && $0 == finish {
    replacing = 0
    print
    next
  }
  !replacing { print }
' "$setup_file" > "$tmp_file"

chmod --reference="$setup_file" "$tmp_file"
mv "$tmp_file" "$setup_file"
trap - EXIT

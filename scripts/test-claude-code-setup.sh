#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
setup_file="$repo_root/CLAUDE-CODE-SETUP.sh"
adapter_version="$(sed -n "s/^adapter_version='\([0-9][0-9.]*\)'$/\1/p" "$setup_file" | head -n 1)"
begin_marker="<!-- GENERAL-5-CLOUD-ADAPTER:BEGIN version=$adapter_version -->"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_setup() {
  local root="$1"
  GENERAL5_SETUP_ROOT="$root" bash "$setup_file" >/dev/null
}

expect_failure() {
  local root="$1"
  if GENERAL5_SETUP_ROOT="$root" bash "$setup_file" >/dev/null 2>&1; then
    printf 'Expected setup failure for %s.\n' "$root" >&2
    exit 1
  fi
}

fresh_root="$tmp_dir/fresh"
run_setup "$fresh_root"
fresh_policy="$fresh_root/etc/claude-code/CLAUDE.md"
grep -Fxq "$begin_marker" "$fresh_policy"

printf '\nCUSTOM-SUFFIX\n' >> "$fresh_policy"
run_setup "$fresh_root"
[[ "$(grep -c '^<!-- GENERAL-5-CLOUD-ADAPTER:BEGIN' "$fresh_policy")" == 1 ]]
[[ "$(grep -c '^<!-- GENERAL-5-CLOUD-ADAPTER:END -->$' "$fresh_policy")" == 1 ]]
[[ "$(grep -c '^CUSTOM-SUFFIX$' "$fresh_policy")" == 1 ]]
fresh_end_line="$(grep -nFx '<!-- GENERAL-5-CLOUD-ADAPTER:END -->' "$fresh_policy" | cut -d: -f1)"
fresh_suffix_line="$(grep -nFx 'CUSTOM-SUFFIX' "$fresh_policy" | cut -d: -f1)"
(( fresh_end_line < fresh_suffix_line ))

older_root="$tmp_dir/older"
mkdir -p "$older_root/etc/claude-code"
older_policy="$older_root/etc/claude-code/CLAUDE.md"
printf '%s\n' \
  'CUSTOM-PREFIX' \
  '<!-- GENERAL-5-CLOUD-ADAPTER:BEGIN version=1.2.0 -->' \
  'old payload' \
  '<!-- GENERAL-5-CLOUD-ADAPTER:END -->' \
  'CUSTOM-SUFFIX' > "$older_policy"
run_setup "$older_root"
grep -Fxq 'CUSTOM-PREFIX' "$older_policy"
grep -Fxq 'CUSTOM-SUFFIX' "$older_policy"
grep -Fxq "$begin_marker" "$older_policy"
older_prefix_line="$(grep -nFx 'CUSTOM-PREFIX' "$older_policy" | cut -d: -f1)"
older_begin_line="$(grep -nFx "$begin_marker" "$older_policy" | cut -d: -f1)"
older_end_line="$(grep -nFx '<!-- GENERAL-5-CLOUD-ADAPTER:END -->' "$older_policy" | cut -d: -f1)"
older_suffix_line="$(grep -nFx 'CUSTOM-SUFFIX' "$older_policy" | cut -d: -f1)"
(( older_prefix_line < older_begin_line ))
(( older_begin_line < older_end_line ))
(( older_end_line < older_suffix_line ))
printf '%s\n' 'CUSTOM-PREFIX' 'CUSTOM-SUFFIX' > "$tmp_dir/older-expected-outside"
awk '
  /^<!-- GENERAL-5-CLOUD-ADAPTER:BEGIN/ { managed = 1; next }
  managed && /^<!-- GENERAL-5-CLOUD-ADAPTER:END -->$/ { managed = 0; next }
  !managed { print }
' "$older_policy" > "$tmp_dir/older-actual-outside"
cmp "$tmp_dir/older-expected-outside" "$tmp_dir/older-actual-outside"

newer_root="$tmp_dir/newer"
mkdir -p "$newer_root/etc/claude-code"
newer_policy="$newer_root/etc/claude-code/CLAUDE.md"
printf '%s\n' \
  'CUSTOM-PREFIX' \
  '<!-- GENERAL-5-CLOUD-ADAPTER:BEGIN version=9.0.0 -->' \
  'future payload' \
  '<!-- GENERAL-5-CLOUD-ADAPTER:END -->' \
  'CUSTOM-SUFFIX' > "$newer_policy"
cp "$newer_policy" "$tmp_dir/newer-before"
expect_failure "$newer_root"
cmp "$tmp_dir/newer-before" "$newer_policy"

broken_root="$tmp_dir/broken"
mkdir -p "$broken_root/etc/claude-code"
broken_policy="$broken_root/etc/claude-code/CLAUDE.md"
printf '%s\n' \
  'CUSTOM-PREFIX' \
  '<!-- GENERAL-5-CLOUD-ADAPTER:BEGIN version=1.1.1 -->' \
  'must survive' > "$broken_policy"
cp "$broken_policy" "$tmp_dir/broken-before"
expect_failure "$broken_root"
cmp "$tmp_dir/broken-before" "$broken_policy"

ambiguous_root="$tmp_dir/ambiguous"
mkdir -p "$ambiguous_root/etc/claude-code"
ambiguous_policy="$ambiguous_root/etc/claude-code/CLAUDE.md"
printf '%s\n' 'CUSTOM-PREFIX' ' <!-- GENERAL-5-CLOUD-ADAPTER:BEGIN version=1.1.1 -->' 'CUSTOM-SUFFIX' > "$ambiguous_policy"
cp "$ambiguous_policy" "$tmp_dir/ambiguous-before"
expect_failure "$ambiguous_root"
cmp "$tmp_dir/ambiguous-before" "$ambiguous_policy"

printf 'Claude Code setup safety scenarios passed.\n'

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
fixture="$tmp_dir/repo"
mkdir -p "$fixture"
cp -R "$repo_root/scripts" "$fixture/scripts"
cp -R "$repo_root/.github" "$fixture/.github"
cp "$repo_root/GENERAL-5.md" "$repo_root/ACTIVATION-BOOTSTRAP.md" "$repo_root/ACTIVATION-GIT.md" \
  "$repo_root/PROJECT-INSTRUCTIONS.md" "$repo_root/AGENTS.md" "$repo_root/OPS-DELEGATION.md" "$repo_root/OPS-ROLES.md" \
  "$repo_root/CLAUDE-CODE-SETUP.sh" "$repo_root/ACTIVATION.md" "$repo_root/PROJECT-STATE.md" \
  "$repo_root/.gitignore" "$fixture/"

version="$(sed -n 's/^Статус: .*General \\([0-9][0-9.]*\\).*/\\1/p' "$fixture/GENERAL-5.md" | head -n 1)"
git -C "$fixture" init -q
git -C "$fixture" config user.name test
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" add -A
git -C "$fixture" commit -qm fixture
if grep -Fq 'Статус: **выпущено — General ' "$fixture/GENERAL-5.md"; then
  git -C "$fixture" tag "v$version"
fi

verify() {
  bash "$fixture/scripts/verify-artifacts.sh" >/dev/null 2>&1
}
if ! verify; then
  printf 'Unmodified fixture unexpectedly fails verification.\n' >&2
  exit 1
fi

expect_rejection() {
  local label="$1" path="$2" before="$3" after="$4"
  cp "$repo_root/$path" "$fixture/$path"
  BEFORE="$before" AFTER="$after" FILE="$fixture/$path" python3 - <<'PY'
import os
from pathlib import Path
p = Path(os.environ["FILE"])
content = p.read_text()
old, new = os.environ["BEFORE"], os.environ["AFTER"]
if content.count(old) != 1:
    raise SystemExit("Fixture mutation anchor is missing or ambiguous")
p.write_text(content.replace(old, new))
PY
  if verify; then
    printf 'Verifier accepted regression: %s.\n' "$label" >&2
    exit 1
  fi
  cp "$repo_root/$path" "$fixture/$path"
  if ! verify; then
    printf 'Fixture did not recover after %s.\n' "$label" >&2
    exit 1
  fi
}

expect_rejection 'git activation begin marker' ACTIVATION-GIT.md \
  "GENERAL-5:BEGIN version=$version bootstrap=1.3.1" \
  "GENERAL-5:BEGIN version=5.0.3 bootstrap=1.3.1"
expect_rejection 'git activation PR marker' ACTIVATION-GIT.md \
  "general=$version bootstrap=1.3.1" \
  "general=5.0.3 bootstrap=1.3.1"
expect_rejection 'candidate declares unissued release tag' AGENTS.md \
  'Канонический текст кандидата:' \
  'Канонический выпущенный текст:'
expect_rejection 'bootstrap claims premature activation' ACTIVATION-BOOTSTRAP.md \
  "Статус: дистрибутив General $version; подключение и активация подтверждаются отдельно." \
  "Статус: активный репозиторный дистрибутив General $version."
expect_rejection 'logs unavailable replaces known process status' OPS-ROLES.md \
  'при недоступных логах (пометка `logs unavailable`)' \
  'при недоступных логах (пометка `unknown`)'
expect_rejection 'docs misrepresent missing logs' ACTIVATION.md \
  'при подтверждённом `running` и отсутствии логов — `running; logs unavailable`' \
  'при подтверждённом `running` и отсутствии логов — `unknown`'

printf 'Activation and process-status regression scenarios passed.\n'

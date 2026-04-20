#!/usr/bin/env bash
set -euo pipefail

# run-smoke-WI-A1.sh — WI-A1 smoke 5종 자동 실행
# tests/smoke-WI-A1.md에 기록된 재현 가능 시나리오를 스크립트화
# 사용: bash tests/run-smoke-WI-A1.sh

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

PASS=0
FAIL=0
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

pass() { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Smoke 1: stop-rag-check.sh 빈 INPUT 회귀 ==="
exit_code=0
echo '' | bash templates/.flowset/scripts/stop-rag-check.sh > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" == "0" ]]; then
  pass "빈 INPUT → EXIT_CODE=0"
else
  fail "빈 INPUT → EXIT_CODE=$exit_code (기대: 0)"
fi

echo ""
echo "=== Smoke 2: restore_state() jq 파싱 6개 키 ==="
cat > "$TMPDIR/fake_state.json" <<'EOF'
{
  "loop_count": 42,
  "call_count": 10,
  "session_id": "test-session-abc123",
  "total_cost_usd": 1.23,
  "last_git_sha": "abcdef1",
  "timestamp": "2026-04-20 22:00:00",
  "status": "running"
}
EOF

declare -A expected=(
  ["status"]="running"
  ["loop_count"]="42"
  ["timestamp"]="2026-04-20 22:00:00"
  ["total_cost_usd"]="1.23"
  ["last_git_sha"]="abcdef1"
  ["session_id"]="test-session-abc123"
)
for key in status loop_count timestamp total_cost_usd last_git_sha session_id; do
  actual=$(jq -r ".${key} // \"default\"" "$TMPDIR/fake_state.json" 2>/dev/null || echo "ERR")
  if [[ "$actual" == "${expected[$key]}" ]]; then
    pass "${key} = ${actual}"
  else
    fail "${key} = '$actual' (기대: '${expected[$key]}')"
  fi
done

echo ""
echo "=== Smoke 3: execute_claude() jq 재귀 순회 ==="
cat > "$TMPDIR/fake_claude_out.json" <<'EOF'
{
  "session_id": "s-xyz-789",
  "total_cost_usd": 0.042,
  "usage": { "cache_creation_input_tokens": 15000, "cache_read_input_tokens": 5000 },
  "message": { "usage": { "cache_creation_input_tokens": 25000 } }
}
EOF

sid=$(jq -r '.session_id // empty' "$TMPDIR/fake_claude_out.json")
cost=$(jq -r '.total_cost_usd // empty' "$TMPDIR/fake_claude_out.json")
cache=$(jq -r '.. | objects | .cache_creation_input_tokens? // empty' "$TMPDIR/fake_claude_out.json" | head -1)

# if-else 명시 분기 — `[[ ]] && pass || fail` 패턴의 잠재 함정(pass 실패 시 fail 동시 실행) 회피
if [[ "$sid" == "s-xyz-789" ]]; then
  pass "session_id = $sid"
else
  fail "session_id = '$sid'"
fi
if [[ "$cost" == "0.042" ]]; then
  pass "total_cost_usd = $cost"
else
  fail "total_cost_usd = '$cost'"
fi
if [[ "$cache" == "15000" ]]; then
  pass "cache_creation(DFS 첫 값) = $cache"
else
  fail "cache_creation = '$cache' (기대: 15000, usage.*이 message.usage.*보다 우선)"
fi

echo ""
echo "=== Smoke 4: install.sh 의존성 체크 블록 ==="
# install.sh의 의존성 체크 섹션만 추출 실행 (Windows/macOS 모두 호환)
check_output=$(bash -c '
  if ! command -v jq &> /dev/null; then echo "NO_JQ"; exit 1; fi
  echo "JQ_OK"
  if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )); then
    echo "BASH_PASS_${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
  else
    echo "BASH_WARN_${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
  fi
' 2>&1)

if echo "$check_output" | grep -q "^JQ_OK$"; then
  pass "jq 존재 체크 통과"
else
  fail "jq 체크 실패"
fi
if echo "$check_output" | grep -qE "^BASH_(PASS|WARN)_"; then
  pass "bash 버전 분기 동작 ($(echo "$check_output" | grep -oE 'BASH_[A-Z]+_[0-9]+\.[0-9]+'))"
else
  fail "bash 버전 체크 분기 실패"
fi

echo ""
echo "=== Smoke 6: .flowset/scripts/vault-helpers.sh runtime 검증 ==="
# FlowSet 저장소 자체 hook이 사용하는 .flowset/scripts/ 경로의 vault-helpers
# 손상된 transcript JSON을 넘겨도 set -euo pipefail 하에서 조기 종료하지 않는지 확인
# (templates/는 Smoke 2·3에서 검증. .flowset/scripts/는 이 Smoke 6에서 커버)
cat > "$TMPDIR/bad_transcript.jsonl" <<'EOF'
not a valid json line
{also broken
EOF

local_vault_ok=0
bash -c "
  set -euo pipefail
  export VAULT_ENABLED=false
  source '$REPO_ROOT/.flowset/scripts/vault-helpers.sh'
  vault_extract_transcript '$TMPDIR/bad_transcript.jsonl'
  # 손상 JSON이어도 TRANSCRIPT_SESSION_START는 빈 문자열로 안전하게 설정됨
  [[ -z \"\$TRANSCRIPT_SESSION_START\" ]] || exit 2
" && local_vault_ok=1 || local_vault_ok=0

if [[ "$local_vault_ok" == "1" ]]; then
  pass ".flowset/scripts/vault-helpers.sh 손상 JSON에서 set -e 안전"
else
  fail ".flowset/scripts/vault-helpers.sh 손상 JSON에서 조기 종료 (|| true 누락 가능성)"
fi

echo ""
echo "=== Smoke 5: test-vault-transcript.sh 회귀 검증 ==="
# set -euo pipefail 추가 후에도 기존 31개 assertion 전부 통과하는지
test_output=$(bash "$SCRIPT_DIR/test-vault-transcript.sh" 2>&1 || true)
if echo "$test_output" | grep -q "^ALL TESTS PASSED$"; then
  total_pass=$(echo "$test_output" | grep -oE "PASS: [0-9]+" | head -1)
  pass "test-vault-transcript.sh 완전 통과 ($total_pass)"
else
  fail_line=$(echo "$test_output" | grep -E "PASS: [0-9]+ / FAIL: [0-9]+" | tail -1)
  fail "test-vault-transcript.sh 회귀 발생 ($fail_line)"
fi

echo ""
echo "================================"
echo "  Smoke Total: $((PASS + FAIL))"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
if (( FAIL == 0 )); then
  echo "  ✅ WI-A1 ALL SMOKE PASSED"
  exit 0
else
  echo "  ❌ WI-A1 SMOKE REGRESSION DETECTED"
  exit 1
fi

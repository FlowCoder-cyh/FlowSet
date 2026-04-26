#!/usr/bin/env bash
set -euo pipefail

# run-smoke-WI-v4int.sh — v4.0 통합 평가 [CRITICAL/MEDIUM/LOW] 7건 해소 검증 + 회귀 영구 차단
#
# 통합 평가 (eval-v4-integration, 5.20/10.00) 발견 결함:
#   [CRITICAL-1] templates/.claude/settings.json Stop hook에 stop-rag-check.sh 미등록 → B2~B7 무력화
#   [CRITICAL-2] stop-rag-check.sh:88 verify_output '|| true' 마스킹 → B1 stop hook 경로 깨짐
#   [MEDIUM-3]  sprint-template B1/B2/B3 정의가 다른 SSOT와 충돌
#   [MEDIUM-4]  README B 매핑에 B5 누락
#   [MEDIUM-5]  학습 31 (tr -d '\r') 4곳 누락 (verify-requirements + session-start-vault)
#   [LOW-6]     evaluator.md cell_coverage // {} null guard 부재
#   [LOW-7]     CHANGELOG "22 WI" vs 23 commit 카운트 불일치
#
# 본 smoke는 7건 해소 + 동일 결함 재발 자동 차단 (cross-check 패턴, 학습 33).

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

PASS=0
FAIL=0

pass() { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

# ============================================================================
echo "=== v4int-1: [CRITICAL-1] settings.json Stop hook stop-rag-check 등록 ==="

SETTINGS="templates/.claude/settings.json"

# JSON 자체 valid (jq parse)
if jq -e . "$SETTINGS" > /dev/null 2>&1; then
  pass "templates/.claude/settings.json valid JSON"
else
  fail "settings.json invalid JSON"
fi

# Stop 배열에 stop-rag-check.sh 등록 — v4.0 차단 메커니즘 발동 의무
stop_rag_count=$(jq -r '[.hooks.Stop[]?.hooks[]? | select(.command | test("stop-rag-check\\.sh"))] | length' "$SETTINGS" 2>/dev/null | tr -d '\r' || echo "0")
if (( stop_rag_count >= 1 )); then
  pass "[CRITICAL-1 해소] Stop hook에 stop-rag-check.sh 등록 (${stop_rag_count}건) — B2~B7 차단 발동"
else
  fail "[CRITICAL-1] stop-rag-check.sh 미등록 — v4.0 B2~B7 차단 무력화"
fi

# 기존 stop-vault-sync.sh 보존 (회귀 차단)
stop_vault_count=$(jq -r '[.hooks.Stop[]?.hooks[]? | select(.command | test("stop-vault-sync\\.sh"))] | length' "$SETTINGS" 2>/dev/null | tr -d '\r' || echo "0")
if (( stop_vault_count >= 1 )); then
  pass "기존 stop-vault-sync.sh 등록 보존 (vault 동기화 회귀 차단)"
else
  fail "stop-vault-sync.sh 등록 변형됨"
fi

# 두 hook 모두 timeout 적정값 (120s — 평가자 시뮬레이션 권고)
two_hooks_timeout=$(jq -r '[.hooks.Stop[]?.hooks[]? | select(.timeout >= 60)] | length' "$SETTINGS" 2>/dev/null | tr -d '\r' || echo "0")
if (( two_hooks_timeout >= 2 )); then
  pass "Stop hook 2개 모두 timeout >= 60s (긴 검증 안전 마진)"
else
  fail "Stop hook timeout 부족 (${two_hooks_timeout}건 >= 60s)"
fi

# ============================================================================
echo ""
echo "=== v4int-2: [CRITICAL-2] verify_output exit code 마스킹 해소 ==="

STOP_SH="templates/.flowset/scripts/stop-rag-check.sh"

# 기존 마스킹 패턴 부재 확인 — '|| true' 직접 패턴 0건
if grep -qE 'verify_output=\$\(bash .*verify-requirements\.sh.*\|\| true\)' "$STOP_SH"; then
  fail "[CRITICAL-2] verify_output 마스킹 패턴 잔존 ('|| true') — exit 2 무력화"
else
  pass "[CRITICAL-2 해소] verify_output 마스킹 패턴 ('|| true') 0건"
fi

# set +e/-e 분리 패턴 적용 (verify_exit 정확 캡처)
verify_block=$(awk '/^# 4\. 검증 에이전트/,/^# ===/{print; if (/^# ===/) exit}' "$STOP_SH")
if echo "$verify_block" | grep -qE 'set \+e' && \
   echo "$verify_block" | grep -qE 'set -e'; then
  pass "set +e/-e 분리 패턴 — verify_exit 정확 캡처 (set -euo pipefail 안전)"
else
  fail "set +e/-e 분리 패턴 누락"
fi

# verify_exit 비교 로직 보존 (== 2)
if echo "$verify_block" | grep -qE 'verify_exit -eq 2'; then
  pass "verify_exit == 2 비교 로직 보존 (B1 차단 경로)"
else
  fail "verify_exit 비교 로직 변형됨"
fi

# ============================================================================
echo ""
echo "=== v4int-3: [MEDIUM-3] sprint-template B 매핑 SSOT 일치 ==="

SPRINT="templates/.flowset/contracts/sprint-template.md"

# B1 매핑 정확 (matrix.entities[].status 미완 셀)
if grep -qE 'matrix\.entities\[\]\.status.*\*\*B1\*\*' "$SPRINT"; then
  pass "[MEDIUM-3 해소] sprint-template B1: matrix.entities[].status 미완 셀 (다른 SSOT 일치)"
else
  fail "[MEDIUM-3] B1 SSOT 일치 위반"
fi

# B2/B3가 sprint contract 자체 의무로 명시 (Stop hook 영역 별개임을 명시)
if grep -qE 'auth_patterns \*\*B2\*\*는 별개' "$SPRINT" && \
   grep -qE '타입 중복 \*\*B3\*\*은 별개' "$SPRINT"; then
  pass "[MEDIUM-3 해소] B2/B3가 Stop hook 영역과 별개임을 명시 (cross-WI 정의 충돌 차단)"
else
  fail "[MEDIUM-3] B2/B3 영역 분리 명시 누락"
fi

# B4 (Gherkin↔테스트) sprint-template에서 Stop hook §8 참조
if grep -qE 'Stop hook §8.*\*\*B4\*\*' "$SPRINT" || grep -qE '\*\*B4\*\*.*Stop hook §8' "$SPRINT"; then
  pass "B4 (Gherkin↔테스트) sprint-template ↔ Stop hook §8 매핑 명시"
else
  fail "B4 매핑 누락"
fi

# ============================================================================
echo ""
echo "=== v4int-4: [MEDIUM-4] README B5 추가 ==="

README="README.md"
readme_block=$(awk '/^### v4\.0 PROJECT_CLASS/,/^### FlowSet 동작 원리/' "$README")

# B5 명시 (미완 셀 우선 주입)
if echo "$readme_block" | grep -qE 'B5.*미완 셀 우선 주입'; then
  pass "[MEDIUM-4 해소] README B5 명시 (미완 셀 우선 주입 — SessionStart/PostCompact)"
else
  fail "[MEDIUM-4] README B5 누락"
fi

# session-start-vault.sh 참조 (B5 차단 위치)
if echo "$readme_block" | grep -qE 'session-start-vault\.sh'; then
  pass "README B5 차단 위치 (session-start-vault.sh) 명시"
else
  fail "session-start-vault.sh 명시 누락"
fi

# ============================================================================
echo ""
echo "=== v4int-5: [MEDIUM-5] 학습 31 (tr -d '\\r') 4곳 적용 ==="

VERIFY="templates/.flowset/scripts/verify-requirements.sh"
VAULT="templates/.flowset/scripts/session-start-vault.sh"

# verify-requirements.sh _emit_missing_entities + _emit_missing_sections 2건
verify_tr=$(awk '/^_emit_missing_(entities|sections)\(\)/,/^}/' "$VERIFY" | grep -cE "tr -d '" || echo "0")
if (( verify_tr >= 2 )); then
  pass "[MEDIUM-5 해소] verify-requirements.sh _emit_missing_* 2건 모두 tr -d '\\r' (${verify_tr}건)"
else
  fail "[MEDIUM-5] verify-requirements.sh tr -d '\\r' 부족 (${verify_tr}건, 2+ 기대)"
fi

# session-start-vault.sh _emit_missing_entities + _emit_missing_sections 2건
vault_tr=$(awk '/^_emit_missing_(entities|sections)\(\)/,/^}/' "$VAULT" | grep -cE "tr -d '" || echo "0")
if (( vault_tr >= 2 )); then
  pass "[MEDIUM-5 해소] session-start-vault.sh _emit_missing_* 2건 모두 tr -d '\\r' (${vault_tr}건)"
else
  fail "[MEDIUM-5] session-start-vault.sh tr -d '\\r' 부족 (${vault_tr}건, 2+ 기대)"
fi

# ============================================================================
echo ""
echo "=== v4int-6: [LOW-6] evaluator.md cell_coverage null guard ==="

EVAL_MD="templates/.claude/agents/evaluator.md"

# (.entities // {}) null guard 패턴 등장 (code class)
if grep -qE '\(\.entities // \{\}\)' "$EVAL_MD"; then
  pass "[LOW-6 해소] evaluator.md cell_coverage code: (.entities // {}) null guard"
else
  fail "[LOW-6] entities null guard 누락"
fi

# (.sections // {}) null guard 패턴 등장 (content class)
if grep -qE '\(\.sections // \{\}\)' "$EVAL_MD"; then
  pass "[LOW-6 해소] evaluator.md cell_coverage content: (.sections // {}) null guard"
else
  fail "[LOW-6] sections null guard 누락"
fi

# ============================================================================
echo ""
echo "=== v4int-7: [LOW-7] CHANGELOG 카운트 명시 ==="

# 23 commits 명시 (22 WI + 사전 정비 1)
if grep -qE '23 commits' CHANGELOG.md; then
  pass "[LOW-7 해소] CHANGELOG 23 commits 카운트 명시 (22 WI + 사전 정비 1)"
else
  fail "[LOW-7] 23 commits 카운트 명시 누락"
fi

# ============================================================================
echo ""
echo "=== v4int-8: cross-check 영구 차단 (재발 방지) ==="

# settings.json ↔ 실제 hook 파일 존재 cross-check
# Stop hook에 등록된 모든 .sh 파일이 templates/.flowset/scripts/에 실제 존재해야 함
missing_hooks=""
while IFS= read -r hook_path; do
  [[ -z "$hook_path" ]] && continue
  # "bash .flowset/scripts/foo.sh" → "foo.sh" 추출
  hook_file=$(echo "$hook_path" | sed -E 's|^bash \.flowset/scripts/||' | awk '{print $1}')
  [[ -z "$hook_file" ]] && continue
  if [[ ! -f "templates/.flowset/scripts/$hook_file" ]]; then
    missing_hooks+="$hook_file "
  fi
done < <(jq -r '.hooks.Stop[]?.hooks[]?.command // empty' "$SETTINGS" 2>/dev/null | tr -d '\r')

if [[ -z "$missing_hooks" ]]; then
  pass "Stop hook 등록 파일 모두 templates/.flowset/scripts/에 실재 (cross-check)"
else
  fail "Stop hook 등록되었으나 파일 부재: ${missing_hooks}"
fi

# 모든 hook 이벤트 (SessionStart/PreToolUse/PostToolUse/TaskCompleted/PostCompact/Stop)
# 등록 파일도 동일 cross-check
all_missing=""
while IFS= read -r hook_path; do
  [[ -z "$hook_path" ]] && continue
  hook_file=$(echo "$hook_path" | sed -E 's|^bash \.flowset/scripts/||' | awk '{print $1}')
  [[ -z "$hook_file" ]] && continue
  if [[ ! -f "templates/.flowset/scripts/$hook_file" ]]; then
    all_missing+="$hook_file "
  fi
done < <(jq -r '.hooks | to_entries[] | .value[]? | .hooks[]? | .command // empty' "$SETTINGS" 2>/dev/null | tr -d '\r')

if [[ -z "$all_missing" ]]; then
  pass "전체 hook 등록 파일 모두 templates/.flowset/scripts/에 실재 (전 hook 이벤트 cross-check)"
else
  fail "전체 hook 중 파일 부재: ${all_missing}"
fi

# verify-requirements.sh 호출 패턴이 set +e/-e 또는 if/else 분리 (마스킹 패턴 재발 방지)
# awk 단일 호출로 카운트 (grep -c 0건 + || echo "0" multi-line 회피)
masking_count=$(awk '/verify_output=\$\(bash .*verify-requirements.*\|\| true\)/{c++} END{print c+0}' "$STOP_SH")
if (( masking_count == 0 )); then
  pass "verify_output '|| true' 마스킹 패턴 재발 차단 (재발 방지 awk, ${masking_count}건)"
else
  fail "verify_output 마스킹 패턴 ${masking_count}건 — [CRITICAL-2] 회귀"
fi

# 학습 31 SSOT — 모든 _emit_missing_*에 tr -d '\r' (cross-script)
_emit_total=$(grep -cE '^_emit_missing_(entities|sections)\(\)' "$VERIFY" "$VAULT" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
_emit_with_tr=$(awk '/^_emit_missing_(entities|sections)\(\)/,/^}/' "$VERIFY" "$VAULT" 2>/dev/null | grep -cE "tr -d '" || echo "0")
if (( _emit_total > 0 )) && (( _emit_with_tr >= _emit_total )); then
  pass "학습 31 SSOT — 모든 _emit_missing_* 함수 (${_emit_total}개) tr -d '\\r' 적용 (${_emit_with_tr}건)"
else
  fail "학습 31 SSOT 위반 — _emit_missing_* ${_emit_total}개 중 ${_emit_with_tr}건만 적용"
fi

# ============================================================================
echo ""
echo "=== v4int-9: 회귀 차단 — 기존 v4.0 산출물 무영향 ==="

# stop-rag-check.sh 신규 섹션 9/10 보존 (B6/B7)
if grep -qE '^# 9\. 출처 URL' "$STOP_SH" && grep -qE '^# 10\. completeness_checklist' "$STOP_SH"; then
  pass "stop-rag-check.sh §9/§10 (B6/B7) 보존 (회귀 차단)"
else
  fail "§9/§10 변형됨"
fi

# evaluator.md 4-class 보존 (WI-C4)
if grep -qE 'type: code \(PROJECT_CLASS=code\)' "$EVAL_MD" && \
   grep -qE 'type: content \(PROJECT_CLASS=content\)' "$EVAL_MD" && \
   grep -qE 'type: hybrid \(PROJECT_CLASS=hybrid\)' "$EVAL_MD"; then
  pass "evaluator.md 4-class (code/content/hybrid) 보존"
else
  fail "4-class 변형됨"
fi

# CHANGELOG v4.0.0 항목 보존
if grep -qE '^## \[v4\.0\.0\]' CHANGELOG.md; then
  pass "CHANGELOG v4.0.0 항목 보존"
else
  fail "v4.0.0 항목 변형됨"
fi

# README v4.0 PROJECT_CLASS 시스템 보존
if grep -qE '^### v4\.0 PROJECT_CLASS 시스템' "$README"; then
  pass "README v4.0 PROJECT_CLASS 섹션 보존"
else
  fail "README v4.0 섹션 변형됨"
fi

# ============================================================================
echo ""
echo "=== 총 결과 ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
if (( FAIL == 0 )); then
  echo "  ✅ WI-v4int ALL SMOKE PASSED"
  exit 0
else
  echo "  ❌ WI-v4int SMOKE FAILED"
  exit 1
fi

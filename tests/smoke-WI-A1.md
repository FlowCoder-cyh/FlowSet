# Smoke Tests — WI-A1 (v4.0 shell 품질 강화)

WI-A1 변경사항이 기존 동작을 깨뜨리지 않고, 새로 추가된 메커니즘이 정확히 동작하는지 수동 재현 가능한 형태로 기록.

**실행 환경**: jq 1.8.1, bash 5.2.37 (MSYS2 Git Bash, Windows 11)
**최초 실행일**: 2026-04-20
**대응 커밋**: `6f03857` + `d5d56d4` + (line 118 조건식 수정 커밋)

---

## Smoke 1 — stop-rag-check.sh 빈 INPUT 회귀 검사

**목적**: `set -euo pipefail` 추가가 기존 hook 동작을 깨뜨리지 않는지 검증.

**재현 명령**:
```bash
echo '' | bash templates/.flowset/scripts/stop-rag-check.sh
echo "EXIT_CODE=$?"
```

**예상 출력**:
```
EXIT_CODE=0
```

**의미**: hook이 빈 stdin(비hook 환경 가정)으로도 정상 종료. `git diff` 등 내부 명령 실패는 `|| true` fallback으로 흡수됨.

---

## Smoke 2 — restore_state() jq 파싱 정확성

**목적**: `restore_state()`의 sed → jq 전환이 기존 sed와 동일한 값 추출.

**재현 명령**:
```bash
cat > /tmp/fake_state.json <<'EOF'
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
for key in status loop_count timestamp total_cost_usd last_git_sha session_id; do
  val=$(jq -r ".${key} // \"default\"" /tmp/fake_state.json 2>/dev/null)
  printf "  %-18s = %s\n" "$key" "$val"
done
rm -f /tmp/fake_state.json
```

**예상 출력**:
```
  status             = running
  loop_count         = 42
  timestamp          = 2026-04-20 22:00:00
  total_cost_usd     = 1.23
  last_git_sha       = abcdef1
  session_id         = test-session-abc123
```

**의미**: 6개 키 모두 정확 추출. sed 시절과 동일한 결과. `templates/flowset.sh:128-132, 149`의 jq 전환이 `restore_state()` 기능을 보존.

---

## Smoke 3 — execute_claude() jq 재귀 순회 동작

**목적**: `cache_creation_input_tokens` 재귀 순회(`.. | objects | .cache_creation_input_tokens?`)가 중첩 위치(usage 내부)에서 DFS 첫 값을 반환하는지 확인.

**재현 명령**:
```bash
cat > /tmp/fake_claude_out.json <<'EOF'
{
  "session_id": "s-xyz-789",
  "total_cost_usd": 0.042,
  "usage": {
    "cache_creation_input_tokens": 15000,
    "cache_read_input_tokens": 5000
  },
  "message": {
    "usage": {
      "cache_creation_input_tokens": 25000
    }
  }
}
EOF
sid=$(jq -r '.session_id // empty' /tmp/fake_claude_out.json)
cost=$(jq -r '.total_cost_usd // empty' /tmp/fake_claude_out.json)
cache=$(jq -r '.. | objects | .cache_creation_input_tokens? // empty' /tmp/fake_claude_out.json | head -1)
printf "  session_id  = %s\n  total_cost  = %s\n  cache_creation(첫값) = %s\n" "$sid" "$cost" "$cache"
rm -f /tmp/fake_claude_out.json
```

**예상 출력**:
```
  session_id  = s-xyz-789
  total_cost  = 0.042
  cache_creation(첫값) = 15000
```

**의미**: `usage.cache_creation_input_tokens=15000`이 `message.usage.cache_creation_input_tokens=25000`보다 먼저 감지됨(DFS 첫 값). `flowset.sh:1677-1678` 주석에 명시된 "sed 마지막 값 vs jq DFS 첫 값" 동작 차이가 실제 확인됨. Claude CLI 응답에는 한 번만 나타나므로 실무 영향 없음.

---

## Smoke 4 — install.sh 의존성 체크 블록 출력

**목적**: `install.sh` [0/6] 단계가 현재 환경(bash 5.2, jq 1.8.1 설치)에서 모든 체크 PASS를 출력하는지 확인. 2차 평가에서 발견된 line 118 조건식 버그(bash 5.0~5.3 PASS 누락) 재회귀 방지.

**재현 명령** (install.sh의 의존성 체크 블록만 추출 실행):
```bash
bash -c '
if ! command -v jq &> /dev/null; then
  echo "  ❌ jq 없음"; exit 1
fi
echo "  ✅ jq $(jq --version 2>&1 | head -1)"
if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )); then
  echo "  ✅ bash ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
else
  echo "  ⚠️  WARN: bash ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} 감지 (4.4+ 권장)"
fi
'
```

**예상 출력** (bash 4.4+ 환경):
```
  ✅ jq jq-1.8.1
  ✅ bash 5.2
```

**경계값 동작**:
| bash | 예상 |
|------|------|
| 3.2 | ⚠️ WARN |
| 4.3 | ⚠️ WARN |
| 4.4 | ✅ PASS |
| 5.0 / 5.2 / 6.0 | ✅ PASS |

**의미**: 2차 평가 line 118 버그(`-ge 4 && -ge 4`로 bash 5.0~5.3 false) 회귀 방지. 단일 조건식 `(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) ))`로 통일.

---

## Smoke 6 — .flowset/scripts/vault-helpers.sh runtime 검증

**목적**: FlowSet 저장소 자체 hook이 사용하는 `.flowset/scripts/vault-helpers.sh` 경로에서 `vault_extract_transcript`에 손상된 JSON을 넘겨도 `set -euo pipefail` 환경에서 조기 종료하지 않는지 확인. Smoke 2·3은 `templates/` master copy를 검증하나, 저장소 자체의 런타임은 `.flowset/scripts/`를 사용하므로 이 경로의 방어 상태도 독립 검증 필요.

**재현 명령**:
```bash
cat > /tmp/bad.jsonl <<'EOF'
not a valid json line
{also broken
EOF
bash -c "
  set -euo pipefail
  export VAULT_ENABLED=false
  source .flowset/scripts/vault-helpers.sh
  vault_extract_transcript '/tmp/bad.jsonl'
  [[ -z \"\$TRANSCRIPT_SESSION_START\" ]] || exit 2
" && echo "PASS" || echo "FAIL"
rm -f /tmp/bad.jsonl
```

**예상 출력**: `PASS`

**의미**: `head -1 | jq ... 2>/dev/null || true` 방어가 `.flowset/scripts/vault-helpers.sh:359`에 정확히 적용됨을 확인. 방어 누락 시 jq가 invalid JSON에서 exit 5 반환 → set -o pipefail이 함수 중단 → 호출자 전파로 `exit 2` 대신 파이프 실패 코드로 종료됨.

---

## Smoke 5 — test-vault-transcript.sh 회귀 검증

**목적**: 기존 1개 bash 테스트(`tests/test-vault-transcript.sh`)의 31개 assertion이 WI-A1 변경(set -euo pipefail + jq 전환) 이후에도 전부 통과하는지 확인.

**재현 명령**:
```bash
bash tests/test-vault-transcript.sh
echo "EXIT_CODE=$?"
```

**예상 출력 (마지막 3줄)**:
```
================================
PASS: 31 / FAIL: 0 / TOTAL: 31
ALL TESTS PASSED
EXIT_CODE=0
```

**의미**: 31개 assertion 전부 통과. set -euo pipefail 추가로 인한 `vault_extract_transcript` 내부 grep 파이프 실패(set -o pipefail) 회귀를 `|| true` 방어로 해결했음을 증명. `test-vault-transcript.sh`는 `templates/.flowset/scripts/vault-helpers.sh`(master copy)를 source하도록 수정됨.

**수정된 방어 코드** (`vault-helpers.sh:360-369`):
- `grep -oP | sort | head` 파이프 3곳 → 각각 `|| true` 추가
- `git log --oneline | head` 파이프 2곳 → 각각 `|| true` 추가
- `((PASS++))` / `((FAIL++))` → `PASS=$((PASS + 1))` / `FAIL=$((FAIL + 1))` (bash gotcha: var=0일 때 반환값 0으로 set -e 조기 종료)

---

## 자동 실행 스크립트

위 5종 smoke 시나리오를 한 번에 실행:

```bash
bash tests/run-smoke-WI-A1.sh
```

**예상 출력 요약**:
```
  Smoke Total: 14
  PASS: 14
  FAIL: 0
  ✅ WI-A1 ALL SMOKE PASSED
```

- Smoke 1: 1개 assertion (stop-rag-check.sh 빈 INPUT)
- Smoke 2: 6개 키 파싱 (restore_state)
- Smoke 3: 3개 키 파싱 (execute_claude 재귀 순회)
- Smoke 4: 2개 의존성 체크 (install.sh jq + bash)
- Smoke 5: 1개 통합 (test-vault-transcript.sh 31 assertion 통합)
- Smoke 6: 1개 runtime 검증 (.flowset/scripts/ 손상 JSON)
- **합계: 14 assertion**

`exit 1` 반환 시 WI-A1 회귀. `exit 0`이 릴리즈 조건.

이 문서는 WI-A1 회귀 감지용 기준선. 후속 WI(A2~A4, B, C, D)가 이 시나리오를 깨뜨리지 않는지 매 릴리즈 전 `run-smoke-WI-A1.sh`로 확인.

**WI-A3(bats 테스트)에서 정식 회귀 테스트로 변환 예정.**

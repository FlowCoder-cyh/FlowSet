# Smoke Tests — WI-A4 (v4.0 FlowSet 자체 CI)

WI-A4 변경이 기존 smoke(159 assertion)를 깨뜨리지 않고, `.github/workflows/flowset-ci.yml`이 설계 §5 CI 정의와 WI-A3 submodule 전략 양쪽을 만족하는지 검증.

**실행 환경**: jq 1.8.1, bash 5.2.37, Bats 1.13.0, Python 3.12 + pyyaml (MSYS2 Git Bash, Windows 11)
**최초 실행일**: 2026-04-21
**대응 커밋**: WI-A4 브랜치 (`refactor/WI-A4-flowset-ci`)

---

## 변경 범위

1. **`.github/workflows/flowset-ci.yml` 신설** — 4개 job 병렬:
   - **shellcheck**: `find . -name "*.sh" -not -path "./.git/*" -not -path "./tests/bats/*"` 대상 `--severity=warning`
   - **bats**: `bash tests/bats/bin/bats tests/bats_tests/core.bats` (submodule 경로)
   - **smoke**: test-vault + WI-A1~A3 7개 smoke 전수 순차 실행 (실패 시 전체 실패)
   - **commit-check**: PR에서만 `WI-NNN-[type] 한글` 커밋 메시지 검증 (rules/wi-global.md §1)
2. **트리거**: `push` (main + refactor/feature/fix/docs/chore) + `pull_request` (main 대상)
3. **모든 checkout에 `submodules: recursive`** (commit-check 제외 — git log만 검증)

## 설계 §5 :255-267 원본과의 차이점

| 항목 | 설계 §5 원본 | WI-A4 구현 | 근거 |
|------|------------|-----------|------|
| shellcheck find | `-not -path "./.git/*"` | + `-not -path "./tests/bats/*"` | tests/bats/는 submodule 상류 관리 (WI-A3 도입) |
| bats 설치 | `sudo npm install -g bats` | `bash tests/bats/bin/bats` | WI-A3에서 submodule 채택 — npm 전략 폐기 |
| checkout | `uses: actions/checkout@v4` | + `with: submodules: recursive` | tests/bats/ 없으면 bats 실행 불가 |
| bats 대상 | `bats tests/` | `bats tests/bats_tests/core.bats` | 실제 테스트 위치 명시 |

**evaluator WI-A3 2차 평가에서 선제 지적된 3건 반영**.

---

## Smoke 1~11 시나리오

`tests/run-smoke-WI-A4.sh`에 전체 실행 스크립트. 수동 재현:

### A4-1 — CI yml 존재 + YAML 문법 (2 assertion)
```bash
test -f .github/workflows/flowset-ci.yml
python -c "import yaml; yaml.safe_load(open('.github/workflows/flowset-ci.yml', encoding='utf-8'))"
```
Python 3.12 + pyyaml 필요. cp949 회피 위해 `encoding='utf-8'` 필수 (wi-utf8.md).

### A4-2 — 4개 job 정의 (1 assertion)
```bash
for job in shellcheck bats smoke commit-check; do
  grep -qE "^  ${job}:" .github/workflows/flowset-ci.yml
done
```

### A4-3 — [evaluator R1] submodules: recursive ≥3회 (1 assertion)
```bash
grep -c 'submodules: recursive' .github/workflows/flowset-ci.yml
# 기대: ≥3 (shellcheck/bats/smoke job 커버, commit-check 제외)
```
**evaluator WI-A3 2차 지적**: 누락 시 tests/bats/ 미존재로 bats 실행 불가.

### A4-4 — [evaluator R2] shellcheck에서 tests/bats/* 제외 (1 assertion)
```bash
grep -q 'not -path "./tests/bats/\*"' .github/workflows/flowset-ci.yml
```
**evaluator WI-A3 2차 지적**: 설계 §5 :260 원본은 .git만 제외 → submodule 내부 7개 .sh까지 검사되어 경고 발생.

### A4-5 — [evaluator R3] bats submodule 경로 사용 (2 assertion)
```bash
grep -qE 'bash tests/bats/bin/bats' .github/workflows/flowset-ci.yml
# + npm install -g bats 0건 (설계 §5 :265 원본 폐기)
! grep -qE 'npm install.*bats' .github/workflows/flowset-ci.yml
```

### A4-6 — smoke job이 7개 smoke 전수 호출 (1 assertion)
```bash
for s in test-vault-transcript.sh run-smoke-WI-A1.sh run-smoke-WI-A2a.sh \
         run-smoke-WI-A2b.sh run-smoke-WI-A2c.sh run-smoke-WI-A2d.sh \
         run-smoke-WI-A2e.sh run-smoke-WI-A3.sh; do
  grep -qE "bash tests/${s}" .github/workflows/flowset-ci.yml
done
```

### A4-7 — commit-check 정규식 + pull_request 조건 (2 assertion)
```bash
# WI-NNN-[type] 정규식 존재
grep -q 'WI-\[0-9A-Za-z\]\+-(feat|fix|docs|style|refactor|test|chore|perf|ci|revert)' .github/workflows/flowset-ci.yml
# PR에만 적용
grep -qE "if: github.event_name == 'pull_request'" .github/workflows/flowset-ci.yml
```

### A4-8 — trigger push + pull_request (1 assertion)

### A4-9 — bash -n 전체 shell (1 assertion)

### A4-10 — 학습 전이 보존 (1 assertion)
CI yml 내 sed JSON / `((var++))` / `${arr[@]/pattern}` 0건

### A4-11 — WI-A1~A3 기준선 전수 비회귀 (8 assertion)

---

## 자동 실행 스크립트

```bash
bash tests/run-smoke-WI-A4.sh
```

**예상 출력 요약**:
```
  Smoke Total: 21
  PASS: 21
  FAIL: 0
  ✅ WI-A4 ALL SMOKE PASSED
```

assertion 계수:
- A4-1: 2 (존재 + YAML)
- A4-2: 1 (4 jobs)
- A4-3: 1 (submodules recursive)
- A4-4: 1 (shellcheck 제외)
- A4-5: 2 (submodule 경로 + npm 0건)
- A4-6: 1 (7 smoke 호출)
- A4-7: 2 (commit-check 정규식 + PR 조건)
- A4-8: 1 (트리거)
- A4-9: 1 (bash -n)
- A4-10: 1 (학습 전이)
- A4-11: 8 (비회귀 × 8개 smoke)
- **합계: 21 assertion**

**전체 누적**: 기존 159 + WI-A4 smoke 21 = **180 assertion**

---

## CI 실제 동작 검증 (push 후)

smoke는 **CI yml의 정적 구조 검증**만 수행. 실제 GitHub Actions 실행 결과는 push 후 확인:

1. `git push -u origin refactor/WI-A4-flowset-ci`
2. GitHub Actions 페이지에서 4개 job 병렬 실행 관찰
3. 모두 녹색 ✅ 확인 후 PR 생성
4. PR에서 commit-check job 추가 실행 확인
5. 실패 시 로그 분석 → 수정 → 재push

**실측 확인 전 머지 금지**. smoke 21/21 PASS는 "구조 정확"만 증명하지 "실행 성공"은 증명하지 않음.

---

## 이 smoke의 역할 (후속 WI에서 깨뜨리지 말아야 할 것)

| 검증 대상 | 회귀 시 차단 시점 |
|----------|-----------------|
| .github/workflows/flowset-ci.yml 구조 | YAML 깨짐 / job 삭제 시 A4-1, A4-2 실패 |
| submodules: recursive 누락 | checkout 수정 시 A4-3 실패 |
| shellcheck tests/bats/ 제외 | find 명령 단순화 시 A4-4 실패 |
| bats submodule 경로 | npm 전략 회귀 시 A4-5 실패 |
| 누적 smoke 전수 호출 | 새 WI 추가 후 A4 smoke에 신규 smoke 누락 시 갱신 필요 |

---

## Group α 완료 선언

WI-A4 머지 시점에 FlowSet v4.0 **Group α 7/7 완료**:
- WI-A1: shell 품질 (set -euo + jq)
- WI-A2a~e: lib/*.sh 5개 모듈 분리 + 이중 기록 제거
- WI-A3: bats 테스트 인프라
- **WI-A4: FlowSet 자체 CI** ← 최종

**후속 진입**:
- WI-001 (PROJECT_CLASS 게이트웨이) — Group β/γ/δ의 선행 조건
- Group β (class 분기: WI-B1/B2/B3)
- Group γ (매트릭스: WI-C1~C6)
- Group δ (문서: WI-D1/D2)

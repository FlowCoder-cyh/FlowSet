#!/usr/bin/env bash
set -euo pipefail

# run-smoke-WI-B3.sh — WI-B3 (contracts class별 템플릿 신설) 전용 smoke
# 설계 §5 :221-222 + §7 :304 Group β 3/3 이행:
#   1. templates/.flowset/contracts/style-guide.md 신설 (content class용)
#   2. templates/.flowset/contracts/review-rubric.md 신설 (content class용)
#   3. /wi:init Step 3 조건부 cp 추가 (content/hybrid 시에만 복사)
# 사용: bash tests/run-smoke-WI-B3.sh
#
# 누적 기준선 SSOT: `.github/workflows/flowset-ci.yml` smoke job name 참조
#   CI 호출분(A4 미포함): test-vault 31 + A1 14 + A2a-e 81 + A3 17 + 001 40 + B1 27 + B2 36 + B3 35 = 281 assertion
#   로컬 regression (A4 21 포함): 281 + 21 = 302 assertion
#   bats core.bats: 16 @test (class 무관)

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

PASS=0
FAIL=0

pass() { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

STYLE_MD="templates/.flowset/contracts/style-guide.md"
RUBRIC_MD="templates/.flowset/contracts/review-rubric.md"
INIT_MD="skills/wi/init.md"

echo "=== WI-B3-1: style-guide.md 신설 및 핵심 섹션 확인 ==="
# 1. 파일 존재 + 비어있지 않음
if [[ -s "$STYLE_MD" ]]; then
  pass "style-guide.md 파일 존재 및 비어있지 않음 ($(wc -l < "$STYLE_MD")줄)"
else
  fail "style-guide.md 누락 또는 빈 파일"
  echo "=== 총: PASS=$PASS FAIL=$FAIL ==="
  exit 1
fi

# 2. 적용 대상 명시 (content + hybrid)
if grep -qE 'PROJECT_CLASS=content' "$STYLE_MD" && grep -qE 'PROJECT_CLASS=hybrid' "$STYLE_MD"; then
  pass "style-guide: 적용 대상 명시 (content + hybrid)"
else
  fail "style-guide: 적용 대상 명시 누락"
fi

# 3. 10개 섹션 모두 존재 (문체/heading/코드블록/용어/링크/리스트/파일/매트릭스/검증/변경)
sec_count=$(grep -cE '^## [0-9]+\.' "$STYLE_MD" || true)
if (( sec_count >= 10 )); then
  pass "style-guide: 10개 이상 주요 섹션 존재 ($sec_count개)"
else
  fail "style-guide: 주요 섹션 부족 ($sec_count개)"
fi

# 4. heading H5/H6 금지 규칙 존재
if grep -qE 'H5/H6' "$STYLE_MD" && grep -qE '사용 금지' "$STYLE_MD"; then
  pass "style-guide: H5/H6 사용 금지 규칙"
else
  fail "style-guide: H5/H6 규칙 누락"
fi

# 5. 코드블록 언어 필수 규칙
if grep -qE '코드블록.*언어.*명시 필수' "$STYLE_MD"; then
  pass "style-guide: 코드블록 언어 명시 필수 규칙"
else
  fail "style-guide: 코드블록 언어 규칙 누락"
fi

# 6. 출처 URL 섹션당 최소 1개 필수
if grep -qE '출처 URL' "$STYLE_MD" && grep -qE '섹션당 최소 1개' "$STYLE_MD"; then
  pass "style-guide: 섹션당 출처 URL 최소 1개 필수 규칙"
else
  fail "style-guide: 출처 URL 기준선 규칙 누락"
fi

# 7. 검증 지점 섹션 — stop-rag-check.sh content 분기 연계 명시
if grep -qE 'stop-rag-check\.sh.*content' "$STYLE_MD"; then
  pass "style-guide: stop-rag-check.sh content 분기 연계 명시 (WI-C3-content 예약)"
else
  fail "style-guide: Group γ 예약성 누락"
fi

echo ""
echo "=== WI-B3-2: review-rubric.md 신설 및 5축 채점표 확인 ==="
# 1. 파일 존재
if [[ -s "$RUBRIC_MD" ]]; then
  pass "review-rubric.md 파일 존재 ($(wc -l < "$RUBRIC_MD")줄)"
else
  fail "review-rubric.md 누락 또는 빈 파일"
  echo "=== 총: PASS=$PASS FAIL=$FAIL ==="
  exit 1
fi

# 2. 5축 각각 존재 (사실성/완결성/명료성/일관성/출처)
axes_hit=0
for axis in "사실성.*Accuracy" "완결성.*Completeness" "명료성.*Clarity" "일관성.*Consistency" "출처.*Source"; do
  if grep -qE "$axis" "$RUBRIC_MD"; then
    axes_hit=$((axes_hit + 1))
  fi
done
if (( axes_hit == 5 )); then
  pass "review-rubric: 5축 전수 존재 (사실성/완결성/명료성/일관성/출처)"
else
  fail "review-rubric: 5축 부족 (${axes_hit}/5)"
fi

# 3. 각 축별 섹션 제목 존재 (축 1 ~ 축 5)
axis_sections=$(grep -cE '^## 축 [1-5]\.' "$RUBRIC_MD" || true)
if (( axis_sections == 5 )); then
  pass "review-rubric: 축별 섹션 5개 (`## 축 N.` 제목)"
else
  fail "review-rubric: 축별 섹션 부족 ($axis_sections/5)"
fi

# 4. 가중치 합 = 100 검증 (table에서 25+25+20+15+15 = 100)
if grep -qE '가중치 합.*100' "$RUBRIC_MD"; then
  pass "review-rubric: 가중치 합 100% 명시"
else
  fail "review-rubric: 가중치 합 명시 누락"
fi

# 5. 통과 기준: 각 축 임계값 + 가중 총점 ≥ 7.5
if grep -qE '통과 기준' "$RUBRIC_MD" && grep -qE '7\.5' "$RUBRIC_MD"; then
  pass "review-rubric: 통과 기준 명시 (임계값 + 가중 총점 ≥ 7.5)"
else
  fail "review-rubric: 통과 기준 누락"
fi

# 5b. 반올림 규칙 명시 (소수 셋째 자리)
if grep -qE '반올림 규칙' "$RUBRIC_MD" && grep -qE '셋째 자리' "$RUBRIC_MD"; then
  pass "review-rubric: 반올림 규칙 명시 (소수 셋째 자리)"
else
  fail "review-rubric: 반올림 규칙 누락"
fi

# 5c. 이중 AND 게이트 의도 명시 (반례 3건으로 작동 증명)
if grep -qE '이중 AND 게이트' "$RUBRIC_MD" && grep -qE '반례' "$RUBRIC_MD"; then
  pass "review-rubric: 이중 AND 게이트 의도 + 반례 명시"
else
  fail "review-rubric: 이중 게이트 의도 누락"
fi

# 5d. 가중 총점 예시 산술 정확성 (증적 양식 예시): 9.375 표기
if grep -qE '= \*\*9\.375\*\*' "$RUBRIC_MD"; then
  pass "review-rubric: 증적 양식 가중 총점 산술 정확 (9.375)"
else
  fail "review-rubric: 증적 양식 산술 오류 (9.375 미표기)"
fi

# 5e. 반례 1/2/3 수치 산술 정확성 (이중 AND 게이트 섹션)
# 반례 1: 총점 7.65 (최소 통과 경계), 반례 3: 총점 6.65 (이중 게이트 동시 작동)
if grep -qE '= \*\*7\.65\*\* → PASS' "$RUBRIC_MD"; then
  pass "review-rubric: 반례 1 총점 산술 정확 (7.65 PASS)"
else
  fail "review-rubric: 반례 1 총점 표기 오류"
fi
if grep -qE '= \*\*6\.65\*\*' "$RUBRIC_MD"; then
  pass "review-rubric: 반례 3 총점 산술 정확 (6.65 REVISE)"
else
  fail "review-rubric: 반례 3 총점 표기 오류 (6.65 미표기)"
fi
# 반례 2는 총점 이전 탈락이므로 "축 임계값" 키워드만 검증
if grep -qE '축 3 임계값\(7\.0\) 미달' "$RUBRIC_MD"; then
  pass "review-rubric: 반례 2 축 임계 탈락 명시 (총점 이전)"
else
  fail "review-rubric: 반례 2 탈락 경로 누락"
fi

# 6. 증적 파일 양식 2종 (reviews/ + approvals/)
if grep -qE '\.flowset/reviews/\{section\}-\{reviewer\}\.md' "$RUBRIC_MD" && \
   grep -qE '\.flowset/approvals/\{section\}-\{approver\}\.md' "$RUBRIC_MD"; then
  pass "review-rubric: 증적 파일 양식 2종 (reviews + approvals)"
else
  fail "review-rubric: 증적 파일 양식 누락"
fi

# 7. 익명 리뷰 금지 규칙 (파일명에 reviewer 실명 필수)
if grep -qE '익명 리뷰 금지' "$RUBRIC_MD"; then
  pass "review-rubric: 익명 리뷰 금지 규칙 (§3 :145 계승)"
else
  fail "review-rubric: 익명 리뷰 금지 규칙 누락"
fi

# 8. 후속 WI 연계 (C1/C3-content/C4/D1)
hits=0
for wi in "WI-C1" "WI-C3-content" "WI-C4"; do
  grep -qE "$wi" "$RUBRIC_MD" && hits=$((hits + 1))
done
if (( hits >= 3 )); then
  pass "review-rubric: 후속 WI 연계 명시 (WI-C1/C3-content/C4)"
else
  fail "review-rubric: 후속 WI 연계 부족 ($hits/3)"
fi

echo ""
echo "=== WI-B3-3: init.md Step 3 조건부 cp 추가 확인 ==="
# 1. 조건부 if 블록 존재 (PROJECT_CLASS content 또는 hybrid)
if grep -qE 'if \[\[ "\$\{PROJECT_CLASS:-code\}" == "content" \|\| "\$\{PROJECT_CLASS:-code\}" == "hybrid" \]\]; then' "$INIT_MD"; then
  pass "init.md: content/hybrid 조건부 cp if 블록"
else
  fail "init.md: 조건부 cp if 블록 누락"
fi

# 2. style-guide.md cp 명령 (따옴표/공백 허용)
if grep -qE 'cp .*contracts/style-guide\.md.*\.flowset/contracts/style-guide\.md' "$INIT_MD"; then
  pass "init.md: style-guide.md cp 명령"
else
  fail "init.md: style-guide.md cp 누락"
fi

# 3. review-rubric.md cp 명령
if grep -qE 'cp .*contracts/review-rubric\.md.*\.flowset/contracts/review-rubric\.md' "$INIT_MD"; then
  pass "init.md: review-rubric.md cp 명령"
else
  fail "init.md: review-rubric.md cp 누락"
fi

# 4. code 단일 class에서는 불필요 명시 (주석 검증)
if grep -qE 'code 단일 class는 두 파일 불필요' "$INIT_MD"; then
  pass "init.md: code 단일 class 불필요 주석 (하위 호환 근거)"
else
  fail "init.md: 하위 호환 주석 누락"
fi

# 5. 설계 §5 :221-222, §7 :304 참조
if grep -qE '§5 :221-222' "$INIT_MD" && grep -qE '§7 :304' "$INIT_MD"; then
  pass "init.md: 설계 섹션 참조 명시 (§5 :221-222, §7 :304)"
else
  fail "init.md: 설계 참조 누락"
fi

echo ""
echo "=== WI-B3-4: 학습 전이 회귀 방지 (패턴 2/3/4/19) ==="
# 각 신규 파일에 대해 패턴 회귀 검사 (백틱 주석 제거 후)
for file in "$STYLE_MD" "$RUBRIC_MD"; do
  fname=$(basename "$file")
  stripped=$(sed 's/`[^`]*`//g' "$file" | sed -E 's/[[:space:]]+#.*$//')

  # 패턴 2: ((var++))
  cnt=$(echo "$stripped" | grep -cE '\(\([[:alnum:]_]+\+\+\)\)' || true)
  if (( cnt == 0 )); then
    pass "$fname: 패턴 2 ((var++)) 사용 0건"
  else
    fail "$fname: 패턴 2 사용 ${cnt}건"
  fi

  # 패턴 3: "${arr[@]/pattern}"
  if sed 's/`[^`]*`//g' "$file" | grep -nE '\$\{[[:alnum:]_]+\[@\]/[^}]+\}' | grep -vE ':\s*#' > /dev/null; then
    fail "$fname: 패턴 3 \${arr[@]/pattern} 사용 발견"
  else
    pass "$fname: 패턴 3 사용 0건"
  fi
done

echo ""
echo "=== WI-B3-5: init.md Step 3 블록 추출 + 실측 (condition cp 실행 검증) ==="
TMP_DIR="${TMPDIR:-/tmp}/wi-b3-smoke-$$"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

# 가짜 템플릿 소스 디렉토리 (2개 파일만 제공)
FAKE_TPL="$TMP_DIR/fake-template"
mkdir -p "$FAKE_TPL/.flowset/contracts" "$FAKE_TPL/.flowset/scripts"
# 3개 공통 파일 + 2개 content 전용 파일 모두 생성
for f in api-standard data-flow sprint-template style-guide review-rubric; do
  echo "# stub $f" > "$FAKE_TPL/.flowset/contracts/$f.md"
done
echo "# stub script" > "$FAKE_TPL/.flowset/scripts/task-completed-eval.sh"

# 조건부 cp 블록만 추출 (init.md에서 해당 if 블록)
# 실측용 미니 bash 스크립트 작성
TESTER="$TMP_DIR/tester.sh"
cat > "$TESTER" <<'EOF'
#!/usr/bin/env bash
set -u
TEMPLATE_DIR="$1"
PROJECT_CLASS="${2:-code}"

mkdir -p ./.flowset/contracts ./.flowset/scripts

# init.md Step 3의 3개 공통 cp
cp "$TEMPLATE_DIR/.flowset/contracts/api-standard.md" ./.flowset/contracts/api-standard.md
cp "$TEMPLATE_DIR/.flowset/contracts/data-flow.md" ./.flowset/contracts/data-flow.md
cp "$TEMPLATE_DIR/.flowset/contracts/sprint-template.md" ./.flowset/contracts/sprint-template.md

# WI-B3 조건부 cp
if [[ "${PROJECT_CLASS:-code}" == "content" || "${PROJECT_CLASS:-code}" == "hybrid" ]]; then
  cp "$TEMPLATE_DIR/.flowset/contracts/style-guide.md"  ./.flowset/contracts/style-guide.md
  cp "$TEMPLATE_DIR/.flowset/contracts/review-rubric.md" ./.flowset/contracts/review-rubric.md
fi

ls ./.flowset/contracts/
EOF
chmod +x "$TESTER"

# 시나리오 1: class=code — 공통 3개만 복사, style-guide/review-rubric 미복사
WORK="$TMP_DIR/work-code"
mkdir -p "$WORK"
pushd "$WORK" > /dev/null
out=$(bash "$TESTER" "$FAKE_TPL" code 2>&1)
if echo "$out" | grep -qE '^api-standard\.md$' && \
   echo "$out" | grep -qE '^data-flow\.md$' && \
   echo "$out" | grep -qE '^sprint-template\.md$' && \
   ! echo "$out" | grep -qE '^style-guide\.md$' && \
   ! echo "$out" | grep -qE '^review-rubric\.md$'; then
  pass "실측 1: class=code → 공통 3개만 복사 (style-guide/review-rubric 미복사)"
else
  fail "실측 1: code 복사 결과 이상"
  echo "$out" | sed 's/^/    /'
fi
popd > /dev/null

# 시나리오 2: class=content — 5개 모두 복사
WORK="$TMP_DIR/work-content"
mkdir -p "$WORK"
pushd "$WORK" > /dev/null
out=$(bash "$TESTER" "$FAKE_TPL" content 2>&1)
if echo "$out" | grep -qE '^style-guide\.md$' && \
   echo "$out" | grep -qE '^review-rubric\.md$' && \
   echo "$out" | grep -qE '^api-standard\.md$'; then
  pass "실측 2: class=content → style-guide + review-rubric + 공통 3개 복사 (5개)"
else
  fail "실측 2: content 복사 결과 이상"
fi
popd > /dev/null

# 시나리오 3: class=hybrid — 5개 모두 복사
WORK="$TMP_DIR/work-hybrid"
mkdir -p "$WORK"
pushd "$WORK" > /dev/null
out=$(bash "$TESTER" "$FAKE_TPL" hybrid 2>&1)
if echo "$out" | grep -qE '^style-guide\.md$' && \
   echo "$out" | grep -qE '^review-rubric\.md$'; then
  pass "실측 3: class=hybrid → style-guide + review-rubric 복사"
else
  fail "실측 3: hybrid 복사 결과 이상"
fi
popd > /dev/null

# 시나리오 4: PROJECT_CLASS 미설정 (빈 값) → ${PROJECT_CLASS:-code} 기본값 → code 경로 (하위 호환)
WORK="$TMP_DIR/work-unset"
mkdir -p "$WORK"
pushd "$WORK" > /dev/null
out=$(bash "$TESTER" "$FAKE_TPL" "" 2>&1)
if ! echo "$out" | grep -qE '^style-guide\.md$' && \
   ! echo "$out" | grep -qE '^review-rubric\.md$'; then
  pass "실측 4: PROJECT_CLASS 빈 값 → code 기본 (하위 호환, content 계약 미복사)"
else
  fail "실측 4: 빈 값에서 content 계약 복사됨 (하위 호환 위반)"
fi
popd > /dev/null

# 시나리오 5: 실제 template 디렉토리로 실행 — 2개 파일이 실제 존재하는지 확인
WORK="$TMP_DIR/work-real"
mkdir -p "$WORK"
pushd "$WORK" > /dev/null
out=$(bash "$TESTER" "$REPO_ROOT/templates" content 2>&1)
if echo "$out" | grep -qE '^style-guide\.md$' && \
   echo "$out" | grep -qE '^review-rubric\.md$'; then
  pass "실측 5: 실제 templates/.flowset/contracts/에서 2개 파일 복사 성공"
else
  fail "실측 5: 실제 template 복사 실패"
fi
popd > /dev/null

echo ""
echo "=== 총 결과 ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
if (( FAIL == 0 )); then
  echo "  ✅ WI-B3 ALL SMOKE PASSED"
  exit 0
else
  echo "  ❌ WI-B3 SMOKE FAILED"
  exit 1
fi

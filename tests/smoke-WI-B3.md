# Smoke Tests — WI-B3 (contracts class별 템플릿 신설)

WI-B3 변경이 기존 누적 smoke(SSOT = `.github/workflows/flowset-ci.yml` smoke job name)를 깨뜨리지 않고, `templates/.flowset/contracts/` 하위에 content class 전용 2개 계약 파일을 신설하며 `/wi:init` Step 3의 조건부 복사를 실측 검증.

**실행 환경**: jq 1.8.1, bash 5.2.37 (MSYS2 Git Bash, Windows 11)
**최초 실행일**: 2026-04-25
**대응 브랜치**: `feature/WI-B3-feat-contracts-class-templates`

---

## 변경 범위

1. **`templates/.flowset/contracts/style-guide.md` 신설** (126줄) — content class 스타일 가이드
   - 10개 섹션: 문체·톤 / heading / 코드블록·인용 / 용어 / 링크·이미지·출처 / 리스트·테이블 / 파일·경로 / content 매트릭스 연동 / 검증 지점 / 변경 규칙
   - 코드블록 언어 명시 필수 + H5/H6 금지 + 섹션당 출처 URL ≥ 1건
2. **`templates/.flowset/contracts/review-rubric.md` 신설** (222줄) — content class 5축 채점표
   - 5축: 사실성(25%) · 완결성(25%) · 명료성(20%) · 일관성(15%) · 출처(15%)
   - 가중치 합 100%, 통과 기준: 각 축 임계값 + 가중 총점 ≥ 7.5
   - 증적 파일 양식 2종 (reviews / approvals), 익명 리뷰 금지
   - 후속 WI 연계(WI-C1/C3-content/C4/D1) 명시
3. **`skills/wi/init.md` Step 3** — `PROJECT_CLASS` 조건부 cp 2줄 추가
   - `content` 또는 `hybrid` → style-guide + review-rubric 복사
   - `code` → 복사 생략 (하위 호환)
4. **`.github/workflows/flowset-ci.yml`** smoke job에 `run-smoke-WI-B3.sh` 추가
5. **`tests/run-smoke-WI-B3.sh`** 신규 (29 assertion, 5 실측 시나리오 + 24 정적)

---

## 하위 호환

- `PROJECT_CLASS=code` (기본) → 기존 3개 계약만 복사 (api-standard, data-flow, sprint-template). 두 신규 파일 미복사 → v3.x 동작 완전 동일
- `PROJECT_CLASS` 미설정 시 `${PROJECT_CLASS:-code}` 기본값 → `code` 경로
- 신규 2개 파일은 `templates/.flowset/contracts/` 디렉토리에만 추가 — 기존 3개 파일 변경 없음
- content/hybrid 프로젝트에서만 신규 계약이 프로젝트 디렉토리로 배포됨

---

## Smoke 1~5 블록별 요약

| 블록 | 주제 | Assertion |
|------|------|-----------|
| WI-B3-1 | style-guide.md 핵심 섹션 (파일 존재 / 적용 대상 / 10섹션 / H5-H6 / 코드블록 / 출처 / stop-rag 연계) | 7 |
| WI-B3-2 | review-rubric.md 5축 채점표 (파일 / 5축 키워드 / 축별 섹션 / 가중치 100% / 통과기준 7.5 / 반올림 규칙 / 이중 AND 게이트 / 예시 산술 9.375 / 증적 2종 / 익명금지 / 후속 WI) | 11 |
| WI-B3-3 | init.md Step 3 조건부 cp (if 블록 / style cp / rubric cp / code 불필요 주석 / 설계 참조) | 5 |
| WI-B3-4 | 학습 전이 회귀 방지 (패턴 2 + 패턴 3, 2개 파일 × 2패턴) | 4 |
| WI-B3-5 | init.md Step 3 실측 (가짜 template + 실제 template, 5 시나리오) | 5 |
| **합계** | | **32** |

### 실측 시나리오 (WI-B3-5)

- **1 — class=code**: 공통 3개(api/data-flow/sprint)만 복사. style-guide/review-rubric 미복사 (하위 호환)
- **2 — class=content**: 공통 3개 + 신규 2개 = 5개 전수 복사
- **3 — class=hybrid**: 공통 3개 + 신규 2개 = 5개 전수 복사
- **4 — PROJECT_CLASS 빈 값**: `${PROJECT_CLASS:-code}` → code 기본 → 신규 2개 미복사 (하위 호환 증명)
- **5 — 실제 templates/ 디렉토리**: 가짜 template이 아닌 실제 `templates/.flowset/contracts/` 경로에서 2개 파일 실존 확인 + 복사 성공

### 블록 추출 방식

init.md의 Step 3 조건부 cp 블록을 외부 tester 스크립트로 재구성 (핵심 로직 2줄 + 공통 3줄만 포함). 가짜 template 디렉토리를 `/tmp/wi-b3-smoke-$$/fake-template`에 구성하여 `PROJECT_CLASS` 값만 바꿔가며 격리 실행. 실측 5에서는 실제 저장소 `templates/` 경로로 실행하여 파일 실존 증명.

---

## 자동 실행 스크립트

```bash
bash tests/run-smoke-WI-B3.sh
```

**예상 출력 요약**:
```
  PASS: 32
  FAIL: 0
  ✅ WI-B3 ALL SMOKE PASSED
```

**전체 누적 (SSOT = `.github/workflows/flowset-ci.yml` smoke job name)**:
- **CI SSOT**: test-vault 31 + A1 14 + A2a-e 81 (13+13+15+16+24) + A3 17 + 001 40 + B1 27 + B2 36 + **B3 32** = **278 assertion** (A4는 CI 미호출, 순수 meta-smoke)
- **로컬 regression (A4 포함)**: 278 + 21 = **299 assertion**
- **bats core.bats**: 16 @test (class 무관)

---

## 이 smoke의 역할 (후속 WI에서 깨뜨리지 말아야 할 것)

| 검증 대상 | 회귀 시 차단 시점 |
|----------|-----------------|
| style-guide.md 10섹션 구조 | 섹션 누락 시 WI-B3-1 실패 |
| review-rubric.md 5축 + 가중치 100% | 축 누락/가중치 변경 시 WI-B3-2 실패 |
| init.md 조건부 cp 블록 | content/hybrid 분기 손상 시 WI-B3-3 실패 |
| code 하위 호환 (신규 2개 미복사) | 무조건 복사로 바뀌면 실측 1/4 실패 |
| 실제 template 파일 실존 | 파일 삭제/이동 시 실측 5 실패 |
| stop-rag-check.sh content 분기 연계 명시 | Group γ 예약성 손상 시 WI-B3-1 실패 |
| 후속 WI(C1/C3-content/C4) 연계 | Group γ 진입 경로 손상 시 WI-B3-2 실패 |

---

## Group β 진행 상황 (완결)

- ✅ WI-B1 — `/wi:init` content/hybrid 분기
- ✅ WI-B2 — `/wi:start` 3모드 분기 (Phase 6 재구성)
- ✅ **WI-B3** — contracts class별 템플릿 신설 (본 smoke)

Group β 3/3 완결. 다음은 Group γ (매트릭스) 진입 — WI-C1 선행 → {C2, C5, C6} 병렬 → C3-code ∥ C3-content → C4.

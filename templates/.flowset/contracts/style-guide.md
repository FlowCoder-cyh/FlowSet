# Style Guide Contract (content class)

**적용 대상**: `PROJECT_CLASS=content` 또는 `PROJECT_CLASS=hybrid`의 content 경로(docs/**, wireframes/**, research/** 등)
**목적**: 콘텐츠 산출물의 톤·문체·포맷·용어 일관성 강제. `/wi:init` Step 3에서 자동 복사.

이 파일은 설계 §3 content 매트릭스(Section × Role × Action) 및 §5 :230 templates/CLAUDE.md content class 핵심 규칙 7개 중 **"포맷 일관성(heading 레벨·코드블록 언어)"**을 운영 수준에서 구체화.

---

## 1. 문체·톤

| 항목 | 규칙 |
|------|------|
| 서술 시제 | 현재형 평서문 기본 (예: "계정을 생성한다" — "생성됩니다" 금지) |
| 경어체 | 사용자 대상 문서는 경어(습니다/입니다), 내부 문서는 평서문 |
| 1인칭/2인칭 | 기본 금지. 절차 안내 예외("다음 단계를 수행하세요") |
| 추측·의견 | 금지. "아마도", "~일 것 같다" 등 불확정 표현 금지 |
| 감정/수사 | 금지. 객관적 사실만 기술 |

**프로젝트별 override**: 본 파일을 각 프로젝트 `.flowset/contracts/style-guide.md`에서 덮어쓸 수 있음. override 시 이 섹션 전체를 다른 규칙으로 교체.

---

## 2. Heading 레벨 규칙

| 규칙 | 적용 |
|------|------|
| H1(`#`) | 파일당 1개만. 파일 제목 |
| H2(`##`) | 최상위 섹션 |
| H3(`###`) | H2 하위 서브섹션 |
| H4(`####`) | H3 하위 (최대 4단계까지만 허용) |
| H5/H6 | **사용 금지** — 구조 설계 재검토 신호 |

**heading 일관성 검증**: `stop-rag-check.sh` content 분기(WI-C3-content 이후)가 각 섹션의 heading 레벨 깊이를 자동 grep.

---

## 3. 코드블록·인용 규칙

| 항목 | 규칙 |
|------|------|
| 코드블록 언어 | **모든 코드블록에 언어 명시 필수**. ` ```bash`, ` ```json`, ` ```markdown` 등. 언어 없는 ` ``` `는 `stop-rag-check.sh`가 검출하여 block |
| 예시 언어 | `bash`, `sh`, `json`, `yaml`, `markdown`, `typescript`, `python`, `text`(비코드 예시) |
| 인라인 코드 | 백틱 1개 (` `` `). 여러 단어 인용 시 전체를 감쌈 |
| 인용 블록 | `> ` 1단계 기본. 다중 인용(`> >`) 금지 |

---

## 4. 용어 통일 (Terminology)

| 선호 용어 | 금지 표현 | 이유 |
|----------|---------|------|
| 작업 항목 (WI) | 태스크, 할 일, TODO | FlowSet 표준 용어 |
| 사용자 | 유저, 사용자분 | 1음절 선호 |
| 저장 | 저장하기, 저장해주세요 | 명사/동사 원형 |
| 삭제 | 지움, 제거 | 명사형 |
| 승인 | OK, 컨펌 | 한글 표준 |

**프로젝트별 용어집**: 필요 시 `docs/terminology.md`를 추가하고 본 파일에서 참조. 충돌 시 프로젝트별 용어집 우선.

---

## 5. 링크·이미지·출처 규칙

| 항목 | 규칙 |
|------|------|
| 외부 링크 | 절대 URL + 참조 날짜 명시 권장. 예: `[출처](https://example.com) (조회: 2026-04-24)` |
| 내부 링크 | 상대 경로. 예: `[계약](../contracts/api-standard.md)` |
| 이미지 | `wireframes/`, `assets/`, `docs/images/` 등 지정 디렉토리 아래만 허용 |
| 이미지 alt 텍스트 | 필수. 접근성(a11y) 고려 |
| 출처 URL | **섹션당 최소 1개 필수** (설계 §3 :132-134 + §5 :230 content 핵심 규칙 #1). `stop-rag-check.sh` content 분기가 자동 감지 |

---

## 6. 리스트·테이블 규칙

| 항목 | 규칙 |
|------|------|
| 순서 없는 리스트 | `-` 하이픈 통일 (`*`, `+` 금지) |
| 순서 있는 리스트 | `1.` 시작, 실제 순서를 `1. 2. 3.`로 명시 (모두 `1.`로 쓰지 않음) |
| 중첩 레벨 | 최대 3단계 |
| 테이블 헤더 | 필수. 빈 테이블 금지 |
| 테이블 정렬 | 텍스트 열은 좌정렬 기본, 숫자 열은 우정렬 |

---

## 7. 파일·경로 규칙

| 항목 | 규칙 |
|------|------|
| 파일명 | `kebab-case.md` (소문자 + 하이픈). 한글/공백/대문자 금지 |
| 한글 제목이 필요한 경우 | 파일 본문 H1에 한글, 파일명은 kebab 영문 |
| 디렉토리 | 역할별 분리 (`docs/drafts/`, `docs/reviews/`, `docs/approved/` — ownership.json content class 매핑 기준) |
| 파일 크기 | 단일 섹션당 상한 가이드: 500줄 초과 시 분리 검토 |

---

## 8. content 매트릭스 연동 (§3)

각 산출물은 `.flowset/spec/matrix.json.sections[X]`의 한 섹션에 대응해야 합니다 (Group γ WI-C1에서 도입).
- `section` 이름은 H2(`##`) 제목과 매칭
- `roles` 각 역할의 draft/review/approve 상태를 문서 프론트매터 또는 별도 증적 파일로 기록
- `sources[]`에 등록된 출처 URL이 본문에 최소 1개 이상 인용되어야 함

본 규칙은 `review-rubric.md` 축 3(사실성)·축 5(출처) 채점의 기반.

---

## 9. 검증 지점 (hook·evaluator 자동 강제)

| 규칙 위반 | 감지 주체 | 차단 시점 |
|----------|---------|---------|
| 코드블록 언어 미명시 | `stop-rag-check.sh` content 분기 (WI-C3-content) | Stop hook |
| heading H5/H6 사용 | `stop-rag-check.sh` content 분기 | Stop hook |
| 출처 URL 0건인 섹션 | `stop-rag-check.sh` content 분기 | Stop hook |
| reviewer 증적 파일 부재 | evaluator `type: content` (WI-C4) | TaskCompleted hook |
| 본 파일 규칙과 산출물 불일치 | evaluator `type: content` 채점 축 4(일관성) | 평가 점수 감점 |

---

## 10. 변경 규칙

- 본 파일 수정 시 writer/reviewer/approver 전원 확인 필수 (sprint 계약으로 명시)
- 기존 규칙 변경은 전체 docs/** 전수 점검 후 일괄 적용 (deprecation 1 sprint)
- 프로젝트별 override는 `.flowset/contracts/style-guide.md` 직접 수정 (template 원본 수정 금지)
- 본 템플릿 원본은 FlowSet 저장소의 WI-B3 범위 내에서만 수정

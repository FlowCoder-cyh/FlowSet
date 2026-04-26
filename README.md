# FlowSet

**AI가 알아서 개발해주는 자동화 시스템**

> Autonomous AI development loop for Claude Code — describe what you want, and AI builds it automatically with full Git workflow (branch, implement, test, PR, merge).

FlowSet은 [Claude Code](https://claude.com/claude-code)를 활용하여 프로젝트를 자동으로 개발하는 시스템입니다.
요구사항(PRD)만 작성하면, AI가 코드 작성부터 테스트, PR 생성, 머지까지 전부 처리합니다.

**v4.0 (현재)**: 매트릭스 기반 검증 게이트웨이 + 3-class 시스템 (`PROJECT_CLASS=code|content|hybrid`) + Stop hook B1~B7 자동 차단. 코드 프로젝트(SaaS·앱)뿐 아니라 **content 프로젝트(문서·연구·기획)** 도 동일 워크플로우로 자동화.

**Keywords**: Claude Code automation, AI coding agent, autonomous development, AI pair programming, automated PR workflow, Claude API, Anthropic, AI software engineer, vibe coding, matrix-based validation, code-content hybrid

---

## 이런 분들에게 추천합니다

- 아이디어는 있는데 개발이 어려운 분
- 반복적인 개발 작업을 자동화하고 싶은 분
- Claude Code를 더 체계적으로 활용하고 싶은 개발자
- 문서·연구·기획 작업도 매트릭스로 검증하고 싶은 분 (v4.0 content class)

## 어떻게 동작하나요?

```
1. 만들고 싶은 것을 설명합니다 (PRD 작성)
2. AI가 도메인 + 역할(role) + 매트릭스 셀(entities × CRUD 또는 sections × draft·review·approve)을 도출합니다
3. AI가 와이어프레임을 만들어 확인받습니다 (code class)
4. AI가 작업 목록을 만듭니다 (WI: Work Item, 매트릭스 셀이 곧 수용 기준)
5. FlowSet이 자동으로 돌면서:
   브랜치 생성 → Gherkin 시나리오 → 테스트(RED) → 구현(GREEN) → Stop hook B1~B7 검증 → PR → 머지 → 다음 WI
   이 과정을 모든 매트릭스 셀이 done 상태가 될 때까지 반복합니다
```

사람이 할 일은 **"무엇을 만들지 설명하는 것"** 뿐입니다.

**class별 흐름 차이**:
- `code`: 위 흐름 그대로 (loop 모드, 자동 반복)
- `content`: 매트릭스 cells × draft/review/approve 추적, 출처(sources) 무결성 + completeness_checklist 본문 등장 검증 (interactive 모드)
- `hybrid`: code 영역 + content 영역 동시 변경 시 양쪽 검증 모두 통과 필수 (team 모드)

---

## 설치

### 사전 준비

| 필수 | 설치 방법 |
|------|-----------|
| [Claude Code](https://claude.com/claude-code) | `npm install -g @anthropic-ai/claude-code` |
| [GitHub CLI](https://cli.github.com/) | `winget install GitHub.cli` (Windows) / `brew install gh` (Mac) |
| [Git](https://git-scm.com/) | 대부분 이미 설치되어 있음 |
| Git Bash | Windows: Git 설치 시 포함 / Mac·Linux: 터미널 그대로 사용 |
| [jq](https://jqlang.github.io/jq/) (v4.0부터 필수) | `winget install jqlang.jq` (Windows) / `brew install jq` (Mac) / `apt install jq` (Linux) |
| bash 4.4+ (권장) | macOS는 `brew install bash`. Windows Git Bash는 기본 4.4+ |

`install.sh`가 의존성 자동 검증 — jq 미설치 시 즉시 종료, bash 4.4 미만은 경고.

### 설치 방법

1. 저장소를 다운로드합니다
```bash
git clone https://github.com/FlowCoder-cyh/FlowSet.git
```

2. Claude Code를 열고 클론받은 폴더로 이동합니다
```
"install.sh 실행해줘"
```

이것만 하면 설치 끝입니다.

> **터미널에서 직접 설치하려면** (참고용):
> ```bash
> cd FlowSet
> bash install.sh
> ```

### 제거

```bash
bash uninstall.sh
```

---

## 사용법

Claude Code를 열고 아래 명령어를 순서대로 입력하면 됩니다. AI가 알아서 필요한 것들을 물어봅니다.

### 1단계: 프로젝트 만들기

```
/wi:init
```

프로젝트 이름, 유형(typescript/python/rust/go/java), GitHub 계정, **PROJECT_CLASS(code/content/hybrid)** 를 AI가 물어봅니다.
- `code` (기본): 코드 프로젝트 (SaaS, 앱, API)
- `content`: 문서·연구·기획 프로젝트 — `.flowset/reviews/`, `.flowset/approvals/` 자동 생성
- `hybrid`: 코드+문서 혼합 — `ownership.json.teams[].class`로 경로별 class 태깅, 팀명 중복 시 재입력 루프

> 조직 계정을 사용하면 **Merge Queue**가 활성화되어 PR이 자동으로 순차 머지됩니다.

### 2단계: 만들고 싶은 것 설명하기

```
/wi:prd
```

AI가 "어떤 걸 만들고 싶으세요?"라고 물어보고, 대화를 통해 PRD를 작성합니다.
- **Role 추출** (v4.0): PRD 본문에서 admin/manager/employee/user/writer/reviewer/approver 등 역할 자동 감지
- **매트릭스 SSOT 동적 생성**: PROJECT_CLASS에 따라 `.flowset/spec/matrix.json` 자동 생성
  - code: `entities × CRUD × status`
  - content: `sections × (draft/review/approve) × status` + `sources[]` + `completeness_checklist[]`
  - hybrid: 양쪽 모두
- **와이어프레임 자동 생성** (code class): 브라우저에서 UI 미리 확인

> 어떻게 설명해야 할지 모르겠다면 `/wi:guide`를 먼저 실행해보세요.

### 3단계: 인프라 환경 구성

```
/wi:env
```

> 현재는 **code class 위주** (Supabase MCP, Vercel CLI, GitHub Secrets, DB 연결 mock 금지). content class 프로젝트는 보통 인프라 셋업이 거의 불필요하므로 이 단계를 건너뛰고 4단계로 진행할 수 있습니다.

AI가 PRD를 분석해서 필요한 인프라(DB, 배포, 인증 등)를 파악하고, 단계별로 안내하며 설정합니다.
- Supabase MCP로 DB 자동 생성
- Vercel CLI로 배포 연결
- GitHub Secrets 자동 등록
- DB 연결 확인 시 mock 금지 자동 적용

### 4단계: 개발 시작

```
/wi:start
```

Phase 5.95에서 **3모드 중 하나를 선택**합니다 (PROJECT_CLASS 기본값 자동 매핑):

| 모드 | 동작 | PROJECT_CLASS 기본 |
|------|------|--------------------|
| `loop` | `flowset.sh` 새 터미널 자동 반복 | code |
| `interactive` | 이 세션에서 WI 1개씩 수동 승인 | content |
| `team` | `lead-workflow` agent spawn, 6단계 (TeamCreate→Agent Teams→evaluator→정리) | hybrid |

이후 AI가 자동으로:
- 아키텍처 계약 생성 (`api-standard.md` + `data-flow.md` + `style-guide.md` + `review-rubric.md`)
- RAG 체계 초기화
- 작업 목록 생성 (도메인 분리 분석 → 병렬/순차 자동 권장)
- Smoke 테스트 생성
- 모드별 진입점 실행

### 진행 상황 확인

```
/wi:status
```

---

## 명령어 요약

| 명령어 | 설명 | v4.0 변경 |
|--------|------|----------|
| `/wi:init` | 프로젝트 환경 셋업 (Git, CI/CD, 템플릿, hooks) | `--class code\|content\|hybrid` 플래그 + 대화형 선택 |
| `/wi:prd` | 요구사항(PRD) + 와이어프레임 + 매트릭스 SSOT 작성 | Role 추출 + `matrix.json` 동적 생성 + `prd-state.json` v2 |
| `/wi:env` | 인프라 환경 구성 (DB, 배포, Secrets) | code class 중심 |
| `/wi:start` | 개발 시작 (계약, RAG, smoke, 3모드 선택) | `loop\|interactive\|team` 분기 |
| `/wi:status` | 진행 상황 확인 | 매트릭스 셀 진척도 표시 |
| `/wi:guide` | PRD 작성 가이드 | — |
| `/wi:note` | 결정사항 기록 | — |

---

## 개발자 가이드

### 시스템 구조

```
FlowSet/
├── install.sh             # 설치 스크립트 (jq + bash 4.4+ 의존성 검증)
├── uninstall.sh           # 제거 스크립트
├── CHANGELOG.md           # 릴리즈 노트 (v4.0.0 항목 신설)
├── rules/                 # Claude Code 글로벌 규칙
│   ├── wi-global.md       # 커밋/브랜치/PR/코드 규칙 (canonical source)
│   ├── wi-flowset.md      # FlowSet 실행 규칙
│   └── wi-utf8.md         # UTF-8 인코딩 규칙
├── skills/wi/             # Claude Code 스킬 (명령어)
│   ├── init.md            # /wi:init (PROJECT_CLASS 선택 + ownership 동적 생성)
│   ├── prd.md             # /wi:prd (Role 추출 + 매트릭스 SSOT 동적 생성)
│   ├── env.md             # /wi:env (code class 위주)
│   ├── start.md           # /wi:start (loop/interactive/team 3모드 + 계약 + RAG)
│   ├── status.md          # /wi:status
│   ├── guide.md           # /wi:guide
│   └── note.md            # /wi:note
└── templates/             # 프로젝트 템플릿 (다운스트림 프로젝트에 복사)
    ├── flowset.sh         # FlowSet 엔진 (v4.0)
    ├── lib/               # v4.0 모듈 분리 (WI-A2)
    │   ├── state.sh       # save/restore_state, completed_wis 관리
    │   ├── preflight.sh   # 사전 검증 (Git, gh, jq)
    │   ├── worker.sh      # execute_claude() + 워커 컨텍스트
    │   ├── merge.sh       # wait_for_merge / wait_for_batch_merge / inject_regression_wis
    │   └── vault.sh       # vault-helpers 통합 (transcript 추출, state.md 빌드)
    ├── CLAUDE.md          # 프로젝트 규칙 (4-class 분화: code 9개 / content 7개 / hybrid 16개)
    ├── .flowset/
    │   ├── PROMPT.md      # AI 지시서 (TDD, 머지 대기, 와이어프레임 참조)
    │   ├── AGENT.md       # 빌드 명령 + 인프라 + 와이어프레임 + 계약
    │   ├── spec/
    │   │   └── matrix.json    # v4.0 매트릭스 SSOT (entities × CRUD / sections × draft·review·approve)
    │   ├── contracts/     # 팀 간 계약 (5개)
    │   │   ├── api-standard.md    # API 응답 형식 계약 (code class)
    │   │   ├── data-flow.md       # SSOT 데이터 흐름 계약 (code class)
    │   │   ├── sprint-template.md # 스프린트 계약 템플릿 (수용 기준 + Gherkin 강제)
    │   │   ├── review-rubric.md   # content class 리뷰 채점 기준 (WI-B3)
    │   │   └── style-guide.md     # content class 형식 일관성 (WI-B3)
    │   ├── reviews/       # content class 리뷰 증적 ({section}-{reviewer}.md, /wi:init 자동 생성)
    │   ├── approvals/     # content class 승인 증적 ({section}-{approver}.md, /wi:init 자동 생성)
    │   ├── guides/
    │   │   ├── team-worker-guide.md          # Agent Teams 팀원 초기화 가이드
    │   │   └── flowset-operations-guide.md   # FlowSet 운영 상세 가이드 (E2E 품질 기준 등)
    │   ├── ownership.json # 팀별 소유 디렉토리 매핑 (teams[].class로 경로별 분류)
    │   ├── tech-debt.md   # 기술부채 등록 (P0/P1/P2)
    │   ├── hooks/         # Git hooks (commit-msg + pre-push)
    │   └── scripts/       # 운영 스크립트 (14개)
    │                      #   세션:    session-start-vault, stop-vault-sync, vault-helpers
    │                      #   검증:    stop-rag-check (B1~B7), verify-requirements, parse-gherkin
    │                      #   소유권: check-ownership, check-cross-team-impact, notify-contract-change
    │                      #   실행:    launch-loop, enqueue-pr, rollback, resolve-team, task-completed-eval
    ├── .claude/
    │   ├── settings.json  # SessionStart + PostCompact + PreToolUse + PostToolUse + TaskCompleted + Stop hook (6종)
    │   ├── agents/
    │   │   ├── lead-workflow.md  # 리드 6단계 (TeamCreate→Agent Teams→evaluator→정리)
    │   │   └── evaluator.md      # 평가자 v4.0 (type=code/content/hybrid + cell_coverage/scenario_coverage 채점, visual legacy 보존)
    │   └── rules/
    │       ├── flowset-operations.md  # 핵심 운영 규칙 (경량화)
    │       ├── project.md             # 프로젝트 규칙 ({PROJECT_NAME}으로 채워짐)
    │       └── team-roles.md          # 팀 역할 매핑
    ├── .github/
    │   └── workflows/     # ci.yml, commit-check.yml, e2e.yml
    └── .flowsetrc         # 루프 + class + 모드 + vault 설정
```

### v4.0 PROJECT_CLASS 시스템

`/wi:init` Step 1에서 `PROJECT_CLASS`를 선택 (기본값: `code`).

| PROJECT_CLASS | 매트릭스 영역 | Stop hook 차단 (B1~B7) | evaluator type |
|---------------|--------------|------------------------|---------------|
| `code` | `matrix.entities[]` (CRUD × status) | B1 미완 셀 / B2 auth / B3 타입중복 / B4 Gherkin↔테스트 | code (cell+scenario coverage) |
| `content` | `matrix.sections[]` (draft/review/approve × status) | B1 미완 / B6 sources / B7 completeness_checklist | content (출처/리뷰/형식) |
| `hybrid` | 양쪽 모두 (`ownership.json.teams[].class` 경로별) | B1~B7 전체 | hybrid (weighted/strict) |

> evaluator의 `type: visual` 채점 모드(legacy)는 v3.x 호환을 위해 보존되지만, `PROJECT_CLASS`의 정식 값은 `code|content|hybrid` 3종입니다.

**매트릭스 SSOT**: `.flowset/spec/matrix.json` — `/wi:prd` Step 4가 PROJECT_CLASS에 따라 동적 생성.

**자동 차단 메커니즘** (Stop hook `stop-rag-check.sh`, v4.0 §6/7/8/9/10 + SessionStart):
- **B1** (미완 셀): `matrix.status: "missing"` → evaluator FAIL + `verify-requirements.sh exit 2`
- **B2** (auth_patterns): `src/api/**` 변경 시 등록 패턴 grep, 매칭 실패 → block
- **B3** (타입 중복): 같은 interface/type 다른 파일 2개+ → block
- **B4** (Gherkin↔테스트): 시나리오 수 + 이름 부분 매칭 검증, 실패 → block
- **B5** (미완 셀 우선 주입): SessionStart/PostCompact 시점 `session-start-vault.sh`가 미완 셀을 컨텍스트에 자동 주입
- **B6** (sources): `matrix.sections[].sources[]` 파일 존재 + URL 형식 검증
- **B7** (completeness): `completeness_checklist` 항목이 본문(매핑된 paths)에 등장 검증

**hybrid 동시 변경**: 변경 파일을 class별로 분리 → 각 영역 검증 모두 실행 → 모든 issue 수집 후 한 번에 block.

### FlowSet 동작 원리 (v4.0)

```
bash flowset.sh                              ← entry point
    │
    ├─ source lib/state.sh                   ← save/restore_state, completed_wis
    ├─ source lib/preflight.sh               ← Git/gh/jq 사전 검증
    ├─ source lib/worker.sh                  ← execute_claude()
    ├─ source lib/merge.sh                   ← wait_for_merge / wait_for_batch_merge
    ├─ source lib/vault.sh                   ← transcript 추출, state.md 빌드
    │
    ├─ safe_sync_main                        (origin/main과 동기화)
    ├─ recover_completed_from_history        (crash 복구)
    ├─ cleanup_stale_completed               (충돌 close된 WI 재실행)
    ├─ resolve_conflicting_prs               (충돌 PR 자동 rebase)
    ├─ inject_regression_wis                 (lib/merge.sh — regression issue → fix WI 추가)
    │
    ├─ 다음 미완료 WI 선택 (completed_wis.txt 필터)
    ├─ execute_claude (lib/worker.sh) — TDD: 매트릭스 셀 ↔ Gherkin → 테스트(RED) → 구현(GREEN)
    │   ├─ 브랜치 생성 (worktree)
    │   ├─ wireframes/ + contracts/ + spec/matrix.json 참조
    │   ├─ RED → GREEN → lint → build → test
    │   ├─ Stop hook B1~B7 검증 (stop-rag-check.sh)
    │   ├─ 커밋 → push → PR → enqueue
    │   └─ 즉시 종료 (CI 폴링 없음)
    │
    ├─ validate_post_iteration               (scope/TODO/API/RAG/requirements 검증)
    ├─ verify-requirements.sh                (매트릭스 대조 — git diff ↔ matrix.json 셀)
    ├─ wait_for_merge (lib/merge.sh)         (머지 완료 대기)
    ├─ safe_sync_main → mark_wi_done
    ├─ log_trace                             (trace.jsonl 기록)
    └─ 다음 WI로 반복

    루프 종료 시:
    └─ reconcile_fix_plan                    (fix_plan.md 일괄 동기화 → 단일 PR)
```

### 핵심 설계 원칙 (v4.0)

- **매트릭스 SSOT** (v4.0 신설): `.flowset/spec/matrix.json`이 "무엇을 만들었는가"의 단일 진실. PRD ↔ 코드 ↔ 테스트 모든 검증의 근거.
- **B1~B7 자동 차단** (v4.0 신설): Stop hook이 7개 차단 메커니즘으로 미완 셀, auth 패턴 누락, 타입 중복, Gherkin 매핑 실패, 출처 깨짐, completeness 본문 미등장을 자동 block.
- **3-class 분기** (v4.0 신설): `PROJECT_CLASS=code|content|hybrid`로 init/prd/start/CI/PR/hook/evaluator를 한 게이트웨이로 분기. content 프로젝트도 동일 워크플로우.
- **증거 기반 완료 보고** (v4.0 신설): `matrix.entities[].status` 미완 셀 0 + Gherkin 시나리오 대응 테스트 존재 + auth 패턴 grep 통과 전까지 "완료" 보고 금지.
- **요구사항 보호**: `requirements.md`에 사용자 원본 고정, 에이전트 수정 금지.
- **생성자-평가자 분리**: 구현(team-worker)과 평가(evaluator)를 별도 에이전트로 분리. evaluator는 `type=code/content/hybrid` 분기 채점 (visual legacy 보존).
- **스프린트 계약**: WI별 수용 기준(매트릭스 셀) + Gherkin 시나리오를 사전 합의. 자유 텍스트 금지.
- **Agent Teams 상주 팀원**: TeamCreate → Agent(team_name)로 생성. 기존 팀원 재사용 필수, 중복 생성 금지.
- **소유권 hook 강제**: 팀별 디렉토리 제한 (PreToolUse), 계약/스키마 변경 차단 (cross-team).
- **vault 세션 연속성**: Obsidian vault에 state + 일별 세션 로그 + 팀 상태 자동 기록. SessionStart/PostCompact 시 미완 매트릭스 셀을 컨텍스트에 우선 주입 (B5).
- **머지 대기**: PR 머지 완료까지 대기 후 다음 WI (stale base 방지).
- **TDD 강제**: 테스트 먼저 작성 → 구현. Gherkin 시나리오와 1:1 매핑.
- **Stop hook §1-5 RAG + §6-10 차단**: §1-5는 RAG 자동 업데이트 강제, §6-10은 B2/B3/B4/B6/B7 차단 (별도 책임).
- **fix_plan.md 읽기 전용**: `completed_wis.txt`가 SSOT.
- **regression 자동화**: e2e 실패 → issue → WI-NNN-1-fix → 자동 재실행.

### 커스터마이징

**`.flowsetrc` 주요 변수** (v4.0 기준):

```bash
# === 프로젝트 정보 (v4.0 게이트웨이) ===
PROJECT_NAME=""
PROJECT_TYPE=""              # typescript, python, rust, go, java
PROJECT_CLASS="code"         # code | content | hybrid (v4.0 게이트웨이)
EXECUTION_MODE=""            # loop | interactive | team (v4.0, 빈 값이면 PROJECT_CLASS에서 자동 매핑)

# === 루프 제어 ===
MAX_ITERATIONS=50            # 최대 반복 횟수 (미설정 시 WI 수 × 1.2 자동 계산)
RATE_LIMIT_PER_HOUR=80       # 시간당 API 호출 제한
COOLDOWN_SEC=5               # 반복 간 대기
ERROR_COOLDOWN_SEC=30        # 에러 후 추가 대기
NO_PROGRESS_LIMIT=3          # 진행 없는 연속 반복 허용 횟수

# === 워커 토큰 제어 ===
MAX_TURNS=40                 # 워커당 최대 턴 (0=무제한)

# === 파일 경로 ===
PROMPT_FILE=".flowset/PROMPT.md"
FIX_PLAN=".flowset/fix_plan.md"

# === 병렬 실행 ===
PARALLEL_COUNT=1             # 1=순차, 2+=병렬 worktree

# === 브랜치/커밋 규칙 ===
BRANCH_PREFIX="feature"      # feature, fix, chore
COMMIT_PREFIX="WI"           # WI-NNN-[type] 한글 작업명

# === GitHub ===
GITHUB_ACCOUNT_TYPE=""       # "org" 또는 "personal"
GITHUB_ORG=""

# === Obsidian Vault 연동 (v3.0+) ===
VAULT_ENABLED=true
VAULT_URL="https://localhost:27124"
VAULT_API_KEY=""
VAULT_PROJECT_NAME=""        # PROJECT_NAME과 동일하게 설정
```

> `CONTEXT_THRESHOLD`(세션 리셋 토큰 임계치)는 `flowset.sh`의 환경변수 기본값(150000)으로 동작. `.flowsetrc`에 추가하면 override 가능.

---

## 지원 환경

| OS | 상태 | 비고 |
|----|------|------|
| Windows (Git Bash) | 지원 | jq.exe stdout CRLF 자동 처리 (학습 31) |
| macOS | 지원 | tmux 권장 (`brew install tmux`), bash 4.4+는 `brew install bash` |
| Linux | 지원 | |
| WSL | 지원 | Windows 경로 자동 감지 |

---

## 버전 히스토리

릴리즈 노트는 [CHANGELOG.md](./CHANGELOG.md) 참조 — v4.0.0 (2026-04-27): 23 WI + 사전 정비 1 + 통합 fix 1 = 25 PR.

---

## 라이선스

MIT License

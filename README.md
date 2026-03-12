# RalphLoop

**AI가 알아서 개발해주는 자동화 시스템**

RalphLoop은 [Claude Code](https://claude.com/claude-code)를 활용하여 프로젝트를 자동으로 개발하는 시스템입니다.
요구사항(PRD)만 작성하면, AI가 코드 작성부터 테스트, PR 생성, 머지까지 전부 처리합니다.

---

## 이런 분들에게 추천합니다

- 아이디어는 있는데 개발이 어려운 분
- 반복적인 개발 작업을 자동화하고 싶은 분
- Claude Code를 더 체계적으로 활용하고 싶은 개발자

## 어떻게 동작하나요?

```
1. 만들고 싶은 것을 설명합니다 (PRD 작성)
2. AI가 작업 목록을 만듭니다 (WI: Work Item)
3. Ralph Loop이 자동으로 돌면서:
   브랜치 생성 → 코드 구현 → 테스트 → PR → CI 통과 → 머지
   이 과정을 작업이 끝날 때까지 반복합니다
```

사람이 할 일은 **"무엇을 만들지 설명하는 것"** 뿐입니다.

---

## 설치

### 사전 준비

| 필수 | 설치 방법 |
|------|-----------|
| [Claude Code](https://claude.com/claude-code) | `npm install -g @anthropic-ai/claude-code` |
| [GitHub CLI](https://cli.github.com/) | `winget install GitHub.cli` (Windows) / `brew install gh` (Mac) |
| [Git](https://git-scm.com/) | 대부분 이미 설치되어 있음 |
| Git Bash | Windows: Git 설치 시 포함 / Mac·Linux: 터미널 그대로 사용 |

### 설치 방법

1. 저장소를 다운로드합니다
```bash
git clone https://github.com/FlowCoder-cyh/RalphLoop.git
```

2. Claude Code를 열고 클론받은 폴더로 이동합니다
```
"install.sh 실행해줘"
```

이것만 하면 설치 끝입니다.

> **터미널에서 직접 설치하려면** (참고용):
> ```bash
> cd RalphLoop
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

프로젝트 이름, 유형, GitHub 조직 등을 AI가 물어봅니다. 답변만 하면 환경이 자동으로 셋업됩니다.

### 2단계: 만들고 싶은 것 설명하기

```
/wi:prd
```

AI가 "어떤 걸 만들고 싶으세요?"라고 물어봅니다. 편하게 설명하면 AI가 정리해서 문서(PRD)로 만들어줍니다.

> 어떻게 설명해야 할지 모르겠다면 `/wi:guide`를 먼저 실행해보세요.

### 3단계: 개발 시작

```
/wi:start
```

이것만 치면 AI가 알아서:
- 작업 목록을 만들고
- 필요한 도구를 설치하고
- 별도 터미널에서 자동 개발을 시작합니다

이후 Ralph Loop이 작업이 끝날 때까지 자동으로 돌아갑니다.

### 진행 상황 확인

```
/wi:status
```

터미널에서도 실시간으로 볼 수 있습니다:
```
--- Iteration 5/94 ---
WI #8/78: WI-008-feat People DB 스키마
진행률: 7/78 (8%)
  ⠹ 2m 30s | feature/WI-008-feat-people-db-schema | 파일: 5개
```

### 중간에 결정사항 메모

```
/wi:note 인증은 NextAuth 대신 Supabase Auth를 사용하기로 결정
```

---

## 명령어 요약

| 명령어 | 설명 |
|--------|------|
| `/wi:init` | 프로젝트 환경 셋업 |
| `/wi:prd` | 요구사항(PRD) 작성 |
| `/wi:start` | 개발 시작 (Ralph Loop 가동) |
| `/wi:status` | 진행 상황 확인 |
| `/wi:guide` | PRD 작성 가이드 |
| `/wi:note` | 결정사항 기록 |

---

## 개발자 가이드

### 시스템 구조

```
RalphLoop/
├── install.sh          # 설치 스크립트
├── uninstall.sh        # 제거 스크립트
├── rules/              # Claude Code 글로벌 규칙
│   ├── wi-global.md    # 커밋/브랜치/PR/코드 규칙
│   ├── wi-ralph-loop.md # Ralph Loop 실행 규칙
│   └── wi-utf8.md      # UTF-8 인코딩 규칙
├── skills/wi/          # Claude Code 스킬 (명령어)
│   ├── init.md         # /wi:init
│   ├── start.md        # /wi:start
│   ├── prd.md          # /wi:prd
│   ├── status.md       # /wi:status
│   ├── guide.md        # /wi:guide
│   └── note.md         # /wi:note
└── templates/          # 프로젝트 템플릿
    ├── ralph.sh        # Ralph Loop 엔진
    ├── .ralph/         # 상태 관리 파일
    │   ├── PROMPT.md   # AI에게 전달되는 지시서
    │   ├── AGENT.md    # 빌드/테스트 명령 정의
    │   ├── fix_plan.md # 작업 목록 (WI)
    │   ├── guardrails.md # 실패 방지 규칙
    │   └── hooks/      # Git hooks
    ├── .github/        # CI/CD + PR 템플릿
    ├── .ralphrc        # 루프 설정
    └── CLAUDE.md       # 프로젝트 정보
```

### Ralph Loop 동작 원리

```
bash ralph.sh
    │
    ├─ fix_plan.md에서 다음 미완료 WI 선택
    ├─ claude -p 호출 (1개 WI만 처리)
    │   ├─ 브랜치 생성
    │   ├─ 코드 구현
    │   ├─ lint → build → test 검증
    │   ├─ 커밋 → push → PR 생성
    │   ├─ CI 통과 → 자동 머지
    │   └─ RALPH_STATUS 출력 후 종료
    ├─ 세션 ID 및 토큰 사용량 파싱
    ├─ 컨텍스트 임계치 체크 (150k tokens)
    ├─ fix_plan.md 진행률 확인
    └─ 다음 WI로 반복
```

### 핵심 설계 원칙

- **1 iteration = 1 WI**: `claude -p` 한 번 호출에 하나의 작업만 처리
- **세션 재활용**: `--resume`으로 이전 컨텍스트 재사용, 토큰 절약
- **컨텍스트 모니터링**: 150k tokens 초과 시 자동으로 새 세션
- **크래시 복구**: `loop_state.json`에 상태 저장, 비정상 종료 후 자동 재개
- **에러 전략**: 명확한 에러(빌드/타입)는 근본 분석 + 재시도, 모호한 에러는 기록 후 스킵
- **circuit breaker**: 3회 연속 진행 없으면 자동 중지

### WI 커밋 규칙

```
형식: WI-NNN-[type] 한글 작업명

타입: feat, fix, docs, style, refactor, test, chore, perf, ci, revert
번호: fix_plan.md 기준 3자리 순번 (001, 002, ...)
예시: WI-001-feat 사용자 인증 추가
      WI-015-fix 로그인 토큰 만료 처리

시스템 커밋 (번호 없음): WI-chore, WI-docs
```

### 브랜치 규칙

```
feat:     feature/WI-NNN-feat-작업명-kebab
fix:      fix/WI-NNN-fix-작업명-kebab
chore:    chore/WI-NNN-chore-작업명-kebab
docs:     docs/WI-NNN-docs-작업명-kebab
refactor: refactor/WI-NNN-refactor-작업명-kebab
```

### 커스터마이징

**루프 설정** (`.ralphrc`):
```bash
MAX_ITERATIONS=50       # 최대 반복 횟수 (미설정 시 WI 수 × 1.2 자동 계산)
RATE_LIMIT_PER_HOUR=80  # 시간당 API 호출 제한
COOLDOWN_SEC=5          # 반복 간 대기 시간
NO_PROGRESS_LIMIT=3     # 진행 없는 연속 반복 허용 횟수
CONTEXT_THRESHOLD=150000 # 세션 리셋 토큰 임계치
```

**빌드/테스트 명령** (`.ralph/AGENT.md`):
프로젝트 유형에 따라 lint, build, test 명령을 정의합니다.

**실패 방지 규칙** (`.ralph/guardrails.md`):
루프 실행 중 발견된 실패 패턴이 자동으로 누적됩니다. 다음 WI에서 이를 참고하여 동일 실패를 방지합니다.

---

## 지원 환경

| OS | 상태 |
|----|------|
| Windows (Git Bash) | 지원 |
| macOS | 지원 |
| Linux | 지원 |
| WSL | 지원 (Windows 경로 자동 감지) |

---

## 라이선스

MIT License

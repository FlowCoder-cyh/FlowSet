# {PROJECT_NAME}

## 프로젝트 정보
- **이름**: {PROJECT_NAME}
- **타입**: {PROJECT_TYPE}
- **설명**: {PROJECT_DESCRIPTION}

## 빌드/테스트
```bash
# /wi:init에서 프로젝트 타입에 따라 자동 채워짐
```

## 구조
```
src/                    → 소스 코드
wireframes/             → 와이어프레임 HTML (PRD 확정 시 생성)
docs/                   → 문서 계층구조 (L0~L4)
.ralph/                 → Ralph Loop 설정
.ralph/requirements.md  → 사용자 원본 요구사항 (수정 금지)
.ralph/contracts/       → API 표준 + 데이터 흐름 계약
.github/                → CI/CD 워크플로우
.claude/rules/          → 프로젝트 규칙 (자동 로드)
.claude/memory/rag/     → RAG 참조 문서
```

## 핵심 규칙 (5개 — 나머지는 hook/validate가 자동 강제)
1. **requirements.md 수정 금지**: 사용자 원본 요구사항. 범위 축소 시 사용자 승인 필수.
2. **머지 확인 후 다음**: PR 머지 완료 → `git pull` → 다음 브랜치. 이전 PR 머지 전 다음 작업 금지.
3. **요구사항 충실 이행**: "나중에", "Phase 2로", "일단 빼고" 금지. 어려우면 확인을 구할 것.
4. **검증 후 커밋**: lint → build → test 통과 + contracts/ 준수 확인 후에만.
5. **코드 숙지 먼저**: 수정 전 관련 파일 전문 읽기. 추측으로 구현 금지.

## 자동 강제 (hook/validate — 규칙으로 쓸 필요 없음)
- scope creep (10파일 초과) → validate 경고
- TODO/placeholder → validate 경고
- .env/package-lock 수정 → validate 경고
- API 형식 미준수 → validate 경고
- RAG 미업데이트 → Stop hook 경고
- E2E API shortcut → Stop hook 경고
- requirements.md 수정 → validate 차단 + Stop hook 경고
- TDD 미수행 (TESTS_ADDED=0) → validate 경고

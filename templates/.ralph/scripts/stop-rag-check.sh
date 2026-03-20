#!/usr/bin/env bash
# Stop hook: RAG 업데이트 필요 여부 검출
# .claude/settings.json의 Stop hook으로 등록됨
# 대화형 세션에서 파일 변경 시 RAG 업데이트 알림

# RAG 디렉토리가 없으면 스킵
[[ -d ".claude/memory/rag" ]] || exit 0

# 최근 변경 파일 확인 (staged + unstaged + last commit)
changed_files=""
changed_files+=$(git diff --name-only HEAD 2>/dev/null || true)
changed_files+=$'\n'
changed_files+=$(git diff --cached --name-only 2>/dev/null || true)
changed_files+=$'\n'
changed_files+=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)

rag_needed=false
reasons=""

echo "$changed_files" | grep -qE '^(src/)?app/api/' 2>/dev/null && { rag_needed=true; reasons+="API 변경, "; }
echo "$changed_files" | grep -qE 'page\.tsx$' 2>/dev/null && { rag_needed=true; reasons+="페이지 변경, "; }
echo "$changed_files" | grep -qE '^prisma/' 2>/dev/null && { rag_needed=true; reasons+="스키마 변경, "; }

if [[ "$rag_needed" == true ]]; then
  rag_updated=false
  echo "$changed_files" | grep -qE '^\.claude/memory/rag/' 2>/dev/null && rag_updated=true

  if [[ "$rag_updated" == false ]]; then
    echo ""
    echo "⚠️  RAG 업데이트 필요: ${reasons%, }"
    echo "   .claude/memory/rag/ 파일을 업데이트하세요."
    echo ""
  fi
fi

# E2E 테스트 품질 검사 (API shortcut 감지)
e2e_files=$(echo "$changed_files" | grep -E '\.(spec|test)\.(ts|js)$' 2>/dev/null || true)
if [[ -z "$e2e_files" ]]; then
  e2e_files=$(echo "$changed_files" | grep -E '^e2e/' 2>/dev/null || true)
fi

if [[ -n "$e2e_files" ]]; then
  for ef in $e2e_files; do
    [[ ! -f "$ef" ]] && continue
    # request.get/post (API shortcut) 감지 — seed/setup 외
    if grep -E 'request\.(get|post|put|delete|patch)\(' "$ef" 2>/dev/null | grep -vq 'beforeAll\|beforeEach\|seed\|setup' 2>/dev/null; then
      echo ""
      echo "⚠️  E2E에 API shortcut 감지: $ef"
      echo "   request.get/post는 seed에서만 허용. 본문은 page.goto/click/fill 사용."
      echo ""
      break
    fi
    # page.goto 없으면 브라우저 테스트 아님
    if ! grep -q 'page\.goto\|page\.click\|page\.fill' "$ef" 2>/dev/null; then
      echo ""
      echo "⚠️  E2E에 UI 인터랙션 없음: $ef"
      echo "   wireframes/의 data-testid로 실제 UI를 조작하세요."
      echo ""
      break
    fi
  done
fi

# 사용자 원본 요구사항 수정 감지
if [[ -f ".ralph/requirements.md" ]]; then
  req_modified=false
  echo "$changed_files" | grep -qF '.ralph/requirements.md' 2>/dev/null && req_modified=true
  if [[ "$req_modified" == true ]]; then
    echo ""
    echo "🚫 .ralph/requirements.md 수정 감지!"
    echo "   이 파일은 사용자 원본 요구사항이며 에이전트가 수정할 수 없습니다."
    echo "   변경을 되돌리세요: git checkout -- .ralph/requirements.md"
    echo ""
  fi
fi

exit 0

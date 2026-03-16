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

exit 0

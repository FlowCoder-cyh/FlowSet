#!/usr/bin/env bash
# resolve-team.sh — TEAM_NAME 해소 유틸리티
# hook에서 source하여 사용
# 1순위: TEAM_NAME 환경변수 (Agent Teams 세션에서 직접 설정 시)
# 2순위: .flowset/teams/{session_id}.team 파일 (서브에이전트 파일 기반 등록)
# 둘 다 없으면 빈 문자열 (solo 모드)

# $1: stdin INPUT (hook JSON)
# 결과: RESOLVED_TEAM_NAME 변수에 설정
resolve_team_name() {
  local input="${1:-}"

  # 1순위: 환경변수
  if [[ -n "${TEAM_NAME:-}" ]]; then
    RESOLVED_TEAM_NAME="$TEAM_NAME"
    return 0
  fi

  # 2순위: 세션별 팀 파일
  local session_id
  session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
  if [[ -n "$session_id" && -f ".flowset/teams/${session_id}.team" ]]; then
    RESOLVED_TEAM_NAME=$(cat ".flowset/teams/${session_id}.team" 2>/dev/null | tr -d '[:space:]')
    return 0
  fi

  # 미설정 → solo 모드
  RESOLVED_TEAM_NAME=""
  return 0
}

# 팀 등록 (서브에이전트 초기화 시 호출)
# $1: 팀명, $2: session_id
register_team() {
  local team="${1:?register_team: team required}"
  local session_id="${2:?register_team: session_id required}"
  mkdir -p .flowset/teams
  echo "$team" > ".flowset/teams/${session_id}.team"
}

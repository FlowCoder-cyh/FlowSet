#!/usr/bin/env bash
set -euo pipefail

# resolve-team.sh — TEAM_NAME 해소 유틸리티
# hook에서 source하여 사용

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 1순위: TEAM_NAME 환경변수 (Agent Teams 세션에서 직접 설정 시)
# 2순위: .flowset/teams/{이름}.team 파일 (팀명 기반 등록)
# 둘 다 없으면 빈 문자열 (solo 모드)

# $1: stdin INPUT (hook JSON) — 하위 호환용, 현재 미사용 (향후 JSON 파싱 확장 슬롯)
# 결과: RESOLVED_TEAM_NAME 변수에 설정 (외부 caller가 소비)
resolve_team_name() {
  # input은 하위 호환 placeholder (JSON 파싱 미구현)
  # shellcheck disable=SC2034
  local input="${1:-}"

  # 1순위: 환경변수
  if [[ -n "${TEAM_NAME:-}" ]]; then
    # RESOLVED_TEAM_NAME은 외부 caller가 소비
    # shellcheck disable=SC2034
    RESOLVED_TEAM_NAME="$TEAM_NAME"
    return 0
  fi

  # 2순위: .flowset/teams/ 내 이름 기반 .team 파일 스캔
  # PID 파일(숫자만)은 무시하고, 이름 기반 파일을 우선 사용
  # 여러 개면 가장 최근 수정된 파일 사용
  if [[ -d ".flowset/teams" ]]; then
    local latest_file=""
    local latest_mtime=0
    for f in .flowset/teams/*.team; do
      [[ -f "$f" ]] || continue
      local basename_f
      basename_f=$(basename "$f" .team)
      # PID 파일(숫자만) 건너뛰기
      if [[ "$basename_f" =~ ^[0-9]+$ ]]; then
        continue
      fi
      # 빈 파일 건너뛰기
      local file_content
      file_content=$(cat "$f" 2>/dev/null | tr -d '[:space:]')
      if [[ -z "$file_content" ]]; then
        continue
      fi
      # 수정 시간 비교 (가장 최근 파일 선택)
      local mtime
      if stat --version &>/dev/null; then
        mtime=$(stat -c %Y "$f" 2>/dev/null || echo 0)
      else
        mtime=$(stat -f %m "$f" 2>/dev/null || echo 0)
      fi
      if [[ "$mtime" -gt "$latest_mtime" ]]; then
        latest_mtime="$mtime"
        latest_file="$f"
      fi
    done
    if [[ -n "$latest_file" ]]; then
      local content
      content=$(cat "$latest_file" 2>/dev/null | tr -d '[:space:]')
      if [[ -n "$content" ]]; then
        RESOLVED_TEAM_NAME="$content"
        return 0
      fi
    fi
  fi

  # 미설정 → solo 모드
  # RESOLVED_TEAM_NAME은 외부 caller가 소비
  # shellcheck disable=SC2034
  RESOLVED_TEAM_NAME=""
  return 0
}

# 팀 등록 (서브에이전트 초기화 시 호출)
# $1: 팀명
register_team() {
  local team="${1:?register_team: team required}"
  mkdir -p .flowset/teams
  echo "$team" > ".flowset/teams/${team}.team"
}

#!/usr/bin/env bash

autom8_now() {
  date "+%Y-%m-%d %H:%M:%S"
}

autom8_log_file_for() {
  local type="${1:-actions}"
  echo "$AUTOM8_LOG_DIR/${type}.log"
}

autom8_log() {
  local type="${1:-actions}"
  local level="${2:-INFO}"
  local message="${3:-}"
  local file
  file="$(autom8_log_file_for "$type")"
  printf '[%s] [%s] %s\n' "$(autom8_now)" "$level" "$message" >> "$file"
}

autom8_log_info() {
  autom8_log "${1:-actions}" "INFO" "${2:-}"
}

autom8_log_warn() {
  autom8_log "${1:-actions}" "WARN" "${2:-}"
}

autom8_log_error() {
  autom8_log "${1:-errors}" "ERROR" "${2:-}"
}

autom8_rotate_logs() {
  local days="${AUTOM8_LOG_RETENTION_DAYS:-30}"

  if [[ -d "$AUTOM8_LOG_DIR" ]]; then
    find "$AUTOM8_LOG_DIR" -type f -name "*.log" -mtime +"$days" -print -delete 2>/dev/null || true
  fi
}

autom8_log_start() {
  autom8_rotate_logs
  autom8_log_info "actions" "Starting AutoM8 ${AUTOM8_VERSION}"
}

autom8_log_end() {
  autom8_log_info "actions" "Finished AutoM8 execution"
}

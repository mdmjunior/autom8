#!/usr/bin/env bash

AUTOM8_NAME="AutoM8 - Linux Management Suite"
AUTOM8_DEFAULT_ROOT="/opt/autom8"

if [[ -z "${AUTOM8_ROOT:-}" ]]; then
  AUTOM8_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

AUTOM8_VERSION_FILE="$AUTOM8_ROOT/VERSION"
AUTOM8_CONFIG_FILE="$AUTOM8_ROOT/config/autom8.conf"
AUTOM8_CONFIG_EXAMPLE="$AUTOM8_ROOT/config/autom8.conf.example"

AUTOM8_LOG_DIR="$AUTOM8_ROOT/logs"
AUTOM8_BACKUP_DIR="$AUTOM8_ROOT/backups"
AUTOM8_REPORT_DIR="$AUTOM8_ROOT/reports"
AUTOM8_TMP_DIR="$AUTOM8_ROOT/tmp"

AUTOM8_VERSION="dev"
if [[ -f "$AUTOM8_VERSION_FILE" ]]; then
  AUTOM8_VERSION="$(tr -d '[:space:]' < "$AUTOM8_VERSION_FILE")"
fi

mkdir -p "$AUTOM8_LOG_DIR" "$AUTOM8_BACKUP_DIR" "$AUTOM8_REPORT_DIR" "$AUTOM8_TMP_DIR"

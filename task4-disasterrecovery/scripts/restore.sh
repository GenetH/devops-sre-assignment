#!/usr/bin/env bash
# restore.sh – verifies checksum, optional decrypt, restore to dir or Postgres
set -euo pipefail

usage(){ cat <<EOF
Usage:
  BACKUP_SRC=<s3://bucket/prefix | /mnt/backup> ./restore.sh --list
  BACKUP_SRC=<...> ./restore.sh -f <artifact> [--to /restore] [--postgres] [--dry-run]
Options:
  --postgres  restore SQL payload to PG (set PG_* + PGPASSWORD)
  ENCRYPTION=none|age|openssl (and AGE_IDENTITY / OPENSSL_PASSWORD when used)
EOF
}

LIST=false; FILE=""; TO="/restore"; DRYRUN=false; POSTGRES=false
while (( $# )); do case "$1" in
  --list) LIST=true;;
  -f|--file) FILE="${2:-}"; shift;;
  --to) TO="${2:-}"; shift;;
  --postgres) POSTGRES=true;;
  --dry-run) DRYRUN=true;;
  -h|--help) usage; exit 0;;
  *) echo "Unknown: $1"; usage; exit 2;;
esac; shift || true; done

: "${BACKUP_SRC:?Set BACKUP_SRC}"
: "${ENCRYPTION:=none}"
: "${AGE_IDENTITY:=}"        # for age decrypt
: "${OPENSSL_PASSWORD:=}"    # for openssl decrypt

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
log(){ echo "[$(date -u +%FT%TZ)] $*"; }

list() {
  if [[ "$BACKUP_SRC" == s3://* ]]; then
    aws s3 ls "$BACKUP_SRC/" | awk '{print $4}' | grep -E 'backup_.*\.(tar\.gz|tar\.gz\.age|tar\.gz\.enc)$' || true
  else
    ls -1 "$BACKUP_SRC"/backup_*.tar.gz* 2>/dev/null | xargs -n1 basename || true
  fi
}

$LIST && { list; exit 0; }
[[ -n "$FILE" ]] || { echo "Use --file"; exit 2; }

sha="${FILE%.tar.gz*}.sha256"
if [[ "$BACKUP_SRC" == s3://* ]]; then
  aws s3 cp "${BACKUP_SRC}/${FILE}" "$tmp/"
  aws s3 cp "${BACKUP_SRC}/${sha}" "$tmp/" || { echo "Missing sha256" >&2; exit 3; }
else
  cp -f "${BACKUP_SRC}/${FILE}" "$tmp/"
  cp -f "${BACKUP_SRC}/${sha}" "$tmp/" || { echo "Missing sha256" >&2; exit 3; }
fi

artifact="$tmp/${FILE}"
case "$ENCRYPTION" in
  age) : "${AGE_IDENTITY:?Set AGE_IDENTITY}"; age -d -i "$AGE_IDENTITY" -o "${artifact%.age}" "$artifact"; artifact="${artifact%.age}";;
  openssl) : "${OPENSSL_PASSWORD:?Set OPENSSL_PASSWORD}"; openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$OPENSSL_PASSWORD" -in "$artifact" -out "${artifact%.enc}"; artifact="${artifact%.enc}";;
  none) ;;
  *) echo "Unknown ENCRYPTION=$ENCRYPTION"; exit 2;;
endcase

log "Verifying checksum"
if command -v sha256sum >/dev/null 2>&1; then
  ( cd "$tmp" && sha256sum -c "$(basename "$sha")" )
else
  ( cd "$tmp" && shasum -a 256 -c "$(basename "$sha")" )
fi

$DRYRUN && { log "Dry-run OK: $(basename "$artifact")"; exit 0; }

if $POSTGRES; then
  : "${PGPASSWORD:?Set PGPASSWORD}"; : "${PG_HOST:?Set PG_HOST}"; : "${PG_PORT:?Set PG_PORT}"; : "${PG_USER:?Set PG_USER}"; : "${PG_DATABASE:?Set PG_DATABASE}"
  tar -xzf "$artifact" -C "$tmp"
  sql="$(find "$tmp" -maxdepth 1 -name '*.sql' | head -n1)"
  [[ -n "$sql" ]] || { echo "SQL not found in archive" >&2; exit 4; }
  psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE" -f "$sql"
  log "Postgres restore complete"
else
  mkdir -p "$TO"
  tar -xzf "$artifact" -C "$TO"
  log "File restore complete to $TO"
fi

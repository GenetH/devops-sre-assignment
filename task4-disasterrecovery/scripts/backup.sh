#!/usr/bin/env bash
# backup.sh – production backup with rotation, KMS/SSE, optional client-side encryption, and sha256 integrity
# Supports: BACKUP_SOURCE_TYPE=files|postgres
set -euo pipefail

: "${BACKUP_SOURCE_TYPE:=files}"        # files|postgres
: "${FILES_SRC_DIR:=/srv/app-data}"     # when files
: "${PG_HOST:=localhost}"               # when postgres
: "${PG_PORT:=5432}"
: "${PG_USER:=postgres}"
: "${PG_DATABASE:=postgres}"            # or "all"
: "${PG_EXTRA_OPTS:=}"
: "${BACKUP_DEST:?Set BACKUP_DEST (s3://bucket/prefix or /mnt/backup)}"
: "${RETENTION_DAYS:=14}"
: "${ENCRYPTION:=none}"                 # none|age|openssl
: "${AGE_RECIPIENT:=}"                  # if ENCRYPTION=age
: "${OPENSSL_PASSWORD:=}"               # if ENCRYPTION=openssl
: "${TAG:=prod}"
: "${COMPRESS_LEVEL:=6}"                # 1..9
: "${S3_SSE:=aws:kms}"                  # aws:kms or AES256
: "${S3_SSE_KMS_KEY_ID:=}"             # required if aws:kms
: "${S3_STORAGE_CLASS:=STANDARD_IA}"

ts() { date -u +'%Y%m%dT%H%M%SZ'; }
log(){ echo "[$(ts)] $*"; }

workdir="$(mktemp -d)"; trap 'rm -rf "$workdir"' EXIT
tsv="$(ts)"
base="backup_${TAG}_${tsv}"
archive="$workdir/${base}.tar.gz"

# 1) Build payload (portable tar → gzip)
if [[ "$BACKUP_SOURCE_TYPE" == "files" ]]; then
  [[ -d "$FILES_SRC_DIR" ]] || { echo "FILES_SRC_DIR not found: $FILES_SRC_DIR" >&2; exit 2; }
  log "Archiving $FILES_SRC_DIR"
  ( cd "$(dirname "$FILES_SRC_DIR")" && tar -cf - "$(basename "$FILES_SRC_DIR")" | gzip -${COMPRESS_LEVEL} > "$archive" )
elif [[ "$BACKUP_SOURCE_TYPE" == "postgres" ]]; then
  : "${PGPASSWORD:?Set PGPASSWORD}"
  export PGPASSWORD
  dump="$workdir/${base}.sql"
  if [[ "$PG_DATABASE" == "all" ]]; then
    log "pg_dumpall ${PG_USER}@${PG_HOST}:${PG_PORT}"
    pg_dumpall -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" $PG_EXTRA_OPTS > "$dump"
  else
    log "pg_dump ${PG_DATABASE} ${PG_USER}@${PG_HOST}:${PG_PORT}"
    pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" $PG_EXTRA_OPTS "$PG_DATABASE" > "$dump"
  fi
  ( cd "$workdir" && tar -cf - "$(basename "$dump")" | gzip -${COMPRESS_LEVEL} > "$archive" )
else
  echo "Unsupported BACKUP_SOURCE_TYPE=$BACKUP_SOURCE_TYPE" >&2; exit 2
fi

# 2) Integrity hash (portable)
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$archive" > "${archive}.sha256"
else
  shasum -a 256 "$archive" > "${archive}.sha256"
fi

# 3) Optional client-side encryption
artifact="$archive"
case "$ENCRYPTION" in
  none) ;;
  age)
    : "${AGE_RECIPIENT:?Set AGE_RECIPIENT}"
    log "Encrypting with age"
    age -r "$AGE_RECIPIENT" -o "${archive}.age" "$archive"
    artifact="${archive}.age"
    ;;
  openssl)
    : "${OPENSSL_PASSWORD:?Set OPENSSL_PASSWORD}"
    log "Encrypting with OpenSSL AES-256-CBC"
    openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:"$OPENSSL_PASSWORD" -in "$archive" -out "${archive}.enc"
    artifact="${archive}.enc"
    ;;
  *) echo "Unknown ENCRYPTION=$ENCRYPTION" >&2; exit 2 ;;
esac

# 4) Ship + retention
if [[ "$BACKUP_DEST" == s3://* ]]; then
  log "Uploading to $BACKUP_DEST (SSE=$S3_SSE)"
  aws s3 cp "$artifact" "${BACKUP_DEST}/" --sse "$S3_SSE" ${S3_SSE_KMS_KEY_ID:+--sse-kms-key-id "$S3_SSE_KMS_KEY_ID"} --storage-class "$S3_STORAGE_CLASS"
  aws s3 cp "${archive}.sha256" "${BACKUP_DEST}/" --sse "$S3_SSE" ${S3_SSE_KMS_KEY_ID:+--sse-kms-key-id "$S3_SSE_KMS_KEY_ID"} --storage-class "$S3_STORAGE_CLASS"

  cutoff=$(date -u -d "-${RETENTION_DAYS} days" +%s)
  aws s3 ls "$BACKUP_DEST/" | awk '{print $1" "$2" "$4}' | while read -r d t f; do
    [[ -z "$f" ]] && continue
    tsf=$(date -u -d "$d $t" +%s)
    if (( tsf < cutoff )); then aws s3 rm "${BACKUP_DEST}/${f}" || true; fi
  done
else
  mkdir -p "$BACKUP_DEST"
  cp -f "$artifact" "${BACKUP_DEST}/"
  cp -f "${archive}.sha256" "${BACKUP_DEST}/"
  find "$BACKUP_DEST" -type f -mtime +"$RETENTION_DAYS" -name 'backup_*.tar.gz*' -delete -o -name 'backup_*.sha256' -delete 2>/dev/null || true
fi

log "DONE: $(basename "$artifact")"

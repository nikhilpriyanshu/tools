#!/bin/bash

primary="/run/media/dev/Image-2"
secondary="/run/media/dev/Image-1"

LOG_DIR="$HOME/logs/rsync"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/rsync-$(date +%F-%H%M%S).log"

filepath="$1"

function validate_filepath() {
  ls "$1" &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "[valid] file-path: $1"
  else
    echo "ERROR: invalid file-path"
    exit -1
  fi
}

function validate_input_filepath() {
  ls "$primary/$filepath" &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "[valid] file-path: ${filepath}"
  else
    echo "ERROR: invalid file-path"
    exit -1
  fi
}

function show_details() {
  echo "primary:   ${primary}"
  echo "secondary: ${secondary}"
}

get_fullpath() {
  printf '%s/%s\n' "$1" "$2"
}

function differentiate_rsync_output() {
  echo
}

function set_primary_and_secondary_path() {
  PRIMARY_PATH="$(get_fullpath $primary $filepath)"
  echo "Validating primary path..."; validate_filepath ${PRIMARY_PATH}
  
  SECONDARY_PATH="$(get_fullpath $secondary $filepath)"
  echo "Validating secondary path..."; validate_filepath ${SECONDARY_PATH}
}

function rsync_now() {
  differentiate_rsync_output
  rsync -avh \
    --checksum \
    --delete-delay \
    --backup \
    --backup-dir="${SECONDARY_PATH}/.rsync-backup-$(date +%F)" \
    --exclude='.rsync-backup-*' \
    --itemize-changes \
    --info=progress2 \
    --partial \
    --stats \
    --one-file-system \
    --numeric-ids \
    --log-file="${LOG_FILE}" \
    "${PRIMARY_PATH}/" "${SECONDARY_PATH}/"
}

function confirm_proceed() {
  echo "Files in ${PRIMARY_PATH} and ${SECONDARY_PATH} will be synced. This operation cannot be reversed"
  read -rp "Do you want to proceed? [y/N]: " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "Proceeding..."
  else
    echo "Cancelled."
    exit 1
  fi
}

function main() {
  validate_input_filepath "${filepath}"
  show_details
  set_primary_and_secondary_path
  confirm_proceed

  rsync_now
}

main

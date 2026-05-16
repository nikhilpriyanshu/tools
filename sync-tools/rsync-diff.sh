#!/bin/bash

primary="/run/media/dev/Image-2"
secondary="/run/media/dev/Image-1"
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

function rsync_diff() {
  PRIMARY_PATH="$(get_fullpath $primary $filepath)"
  echo "Validating primary path..."; validate_filepath ${PRIMARY_PATH}
  
  SECONDARY_PATH="$(get_fullpath $secondary $filepath)"
  echo "Validating secondary path..."; validate_filepath ${SECONDARY_PATH}

  differentiate_rsync_output

  rsync -avhnc --checksum --delete --itemize-changes ${PRIMARY_PATH} ${SECONDARY_PATH}
}

function main() {
  validate_input_filepath "${filepath}"
  
  show_details

  rsync_diff
}

main

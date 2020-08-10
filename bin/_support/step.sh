#!/usr/bin/env bash

source "bin/_support/cecho.sh"

step_header() {
  cecho --green "\n▸" --cyan "${1}:" --yellow "${2}" --orange "${3:-}"
}

step() {
  description=$1
  command=$2

  step_header "${description}" "${command}"
  eval "${command}"

  if [ $? -eq 0 ]; then
    cecho --green "OK"
  else
    cecho --red "FAILED"
    exit
  fi
}

section() {
  title=$1
  cecho --yellow "\n${title}"
}

xstep() {
  description=$1
  command=$2

  step_header "${description}" "${command}" "[SKIPPED]"

  return 0
}

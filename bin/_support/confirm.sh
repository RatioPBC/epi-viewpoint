#!/usr/bin/env bash

source "bin/_support/cecho.sh"

confirm() {
  description=$1

  cecho -n --green "\n▸" --bold-bright-red "${description}?" --yellow "[y/N]"
  read CONFIRMATION
  CONFIRMATION=$(echo "${CONFIRMATION}" | tr '[:upper:]' '[:lower:]')

  if [[ ! "${CONFIRMATION}" =~ "y" ]]; then
    echo
    cecho --yellow "Exiting due to confirmation"
    exit 0
  fi
}

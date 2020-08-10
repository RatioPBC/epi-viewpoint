#!/usr/bin/env bash

source "bin/_support/cecho.sh"
source "bin/_support/check.sh"
source "bin/_support/os.sh"

chromedriver_path=$(command -v chromedriver)

if darwin; then
  chrome_path="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
  chrome_path="$(command -v google-chrome)"
fi

chromedriver_version=$("${chromedriver_path}" --version)
chrome_version=$("${chrome_path}" --version)

chromedriver_major_version=$("${chromedriver_path}" --version | cut -f 2 -d " " | cut -f 1 -d ".")
chrome_major_version=$("${chrome_path}" --version | cut -f 3 -d " " | cut -f 1 -d ".")

if [ "${chromedriver_major_version}" == "${chrome_major_version}" ]; then
  exit 0
else
  cecho --red "Wallaby often fails with 'invalid session id' if Chromedriver and Chrome have different versions."
  cecho "Chromedriver version:" --bold-bright-yellow "${chromedriver_version}" --white "(${chromedriver_path})"
  cecho "Chrome version      :" --bold-bright-yellow "${chrome_version}" --white "(${chrome_path})"
  exit 1
fi

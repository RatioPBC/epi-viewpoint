#!/usr/bin/env sh

sha_exists_locally() {
  git rev-list --quiet "$1" -- 2>/dev/null
}

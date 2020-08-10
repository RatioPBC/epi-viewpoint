#!/usr/bin/env sh

localcopy() {
  content="$1"

  if command -v pbcopy &> /dev/null; then
    echo -n "$content" | pbcopy
  elif command -v xclip &> /dev/null; then
    echo "$content" | xclip -selection clipboard
  else
    cecho -n --yellow "You're missing a suitable copy command; here's the content I tried to copy:"
    cecho -n --yellow "$content"
  fi
}


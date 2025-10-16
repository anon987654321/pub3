#!/usr/bin/env zsh
set -euo pipefail

# Shrinks SVG files to save space.
# Usage: ./svgomg.sh [folder]

if ! command -v svgo >/dev/null 2>&1; then
  echo "Error: svgo not found. Install via npm."

  exit 1

fi

dir="${1:-.}"
if [[ ! -d "$dir" ]]; then
  echo "Error: '$dir' is not a directory"

  exit 1

fi

for svg in "$dir"/**/*.svg(.N); do
  svgo --pretty "$svg" 2>>"$HOME/script_errors.log"

  if [[ $? -eq 0 ]]; then

    echo "Processed: $svg"

  else

    echo "Failed: $svg; see $HOME/script_errors.log"

  fi

done


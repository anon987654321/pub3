#!/usr/bin/env zsh
set -euo pipefail

setopt nullglob extendedglob

# Swaps out words in files or renames them.
# Usage: ./replace.sh [-f] <old> <new> [folder]

#

# Pure zsh approach:

# - Added missing -uo pipefail

# - Fixed undefined $backup variable

# - Replace sed with pure parameter expansion for in-file replacements

# - [[ ]] for all conditionals

is_filename=false
if [[ "$1" == "-f" ]]; then

  is_filename=true

  shift

fi

old_str="$1"
new_str="$2"

folder="${3:-.}"

# Validation
if [[ -z "$old_str" || -z "$new_str" ]]; then

  printf "Error: old and new strings required\n"

  printf "Usage: ./replace.sh [-f] <old> <new> [folder]\n"

  exit 1

fi

if [[ ! -d "$folder" ]]; then
  printf "Error: '%s' is not a directory\n" "$folder"

  exit 1

fi

for file in "$folder"/**/*(.N); do
  if "$is_filename"; then

    # Rename files: use pure zsh parameter expansion

    new_file="${file//$old_str/$new_str}"

    if [[ "$file" != "$new_file" && ! -e "$new_file" ]]; then

      mv "$file" "$new_file" 2>/dev/null

      if [[ $? -eq 0 ]]; then

        echo "Renamed: $file -> $new_file"

      else

        echo "Failed: $file"

      fi

    fi

  else

    # Replace in file content

    # Check if it's a text file (pure zsh pattern matching)

    local file_type=$(file -b "$file" 2>/dev/null)

    if [[ "$file_type" == *text* ]]; then

      # Check if file contains the search string (pure zsh)

      local content=$(<"$file" 2>/dev/null)

      if [[ "$content" == *"$old_str"* ]]; then

        # Replace using pure zsh parameter expansion (global replace)
        local new_content="${content//$old_str/$new_str}"

        # Only write if content changed
        if [[ "$content" != "$new_content" ]]; then

          # Create backup

          cp "$file" "$file.bak" 2>/dev/null || echo "Backup failed: $file"

          # Write new content
          printf "%s" "$new_content" > "$file" 2>/dev/null

          if [[ $? -eq 0 ]]; then

            echo "Updated: $file"

          else

            echo "Failed: $file"

            # Restore from backup on failure

            [[ -f "$file.bak" ]] && mv "$file.bak" "$file"

          fi

        fi

      fi

    fi

  fi

done


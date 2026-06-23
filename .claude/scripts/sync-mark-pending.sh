#!/usr/bin/env bash
# PostToolUse-хук: если правился файл внутри travel-репозитория,
# поднимает флаг .sync-pending. Сам ничего не синхронизирует.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

REPO="/Users/sirmax/work/home/travel"
FLAG="$REPO/.claude/.sync-pending"

input="$(cat)"

# Путь отредактированного файла (Edit/Write/MultiEdit/NotebookEdit)
fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)"
if [ -z "$fp" ]; then
  fp="$(printf '%s' "$input" | sed -n 's/.*"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p' | head -1)"
fi

case "$fp" in
  "$REPO"/.git/*|"$REPO"/.claude/*) : ;;            # служебные — игнор
  "$REPO"/*) mkdir -p "$REPO/.claude"; : > "$FLAG" ;; # правка внутри travel — отметить
esac

exit 0

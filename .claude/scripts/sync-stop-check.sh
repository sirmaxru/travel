#!/usr/bin/env bash
# Stop-хук: если в этом ответе правились travel-файлы (есть .sync-pending) —
# один раз просит Claude спросить пользователя про синхронизацию в iCloud.
# Флаг снимается сразу, поэтому вопрос не повторяется и не зацикливается.
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

REPO="/Users/sirmax/work/home/travel"
FLAG="$REPO/.claude/.sync-pending"

input="$(cat)"

# Уже внутри stop-hook-продолжения — не блокировать повторно
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)"
[ "$active" = "true" ] && exit 0

# Нет несинхронизированных правок — дать остановиться
[ -f "$FLAG" ] || exit 0

# Есть правки: спрашиваем один раз и сразу снимаем флаг
rm -f "$FLAG"

cat <<'JSON'
{"decision":"block","reason":"⚠️ В travel-репозитории есть несинхронизированные изменения. Задай пользователю ОДИН вопрос через AskUserQuestion (варианты «Да, синхронизировать в iCloud» и «Нет, позже»): нужно ли скопировать папку travel в офлайн-копию iCloud. Если «Да» — выполни: bash /Users/sirmax/work/home/travel/.claude/scripts/sync-to-icloud.sh и кратко покажи результат. Если «Нет» — ничего не синхронизируй. Это разовое напоминание, не повторяй его в этом ответе."}
JSON
exit 0

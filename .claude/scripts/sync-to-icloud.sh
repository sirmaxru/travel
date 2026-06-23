#!/usr/bin/env bash
# Зеркалирует папку travel в офлайн-копию iCloud (FSNotes).
# Используется скиллом /sync-travel и при ответе «Да» на авто-вопрос (Stop-хук).
set -uo pipefail

# UTF-8, иначе macOS sed/awk спотыкаются о кириллицу/вьетнамские имена
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

REPO="/Users/sirmax/work/home/travel"
DEST="/Users/sirmax/Library/Mobile Documents/iCloud~co~fluder~fsnotes/Documents/travel"

# iCloud-контейнер должен быть смонтирован
if [ ! -d "$(dirname "$DEST")" ]; then
  echo "❌ iCloud-папка недоступна: $(dirname "$DEST")" >&2
  echo "   Проверь, что iCloud Drive / FSNotes включён и синхронизирован." >&2
  exit 1
fi

mkdir -p "$DEST"

# Зеркало: -a (архив) + --delete (удалить в копии то, чего нет в репо).
out="$(rsync -av --delete --delete-excluded \
  --exclude='.git/' \
  --exclude='.claude/' \
  --exclude='.gitignore' \
  --exclude='.DS_Store' \
  --exclude='*.swp' \
  "$REPO/" "$DEST/" 2>&1)"
rc=$?

# Снять флаг «есть несинхронизированные правки»
rm -f "$REPO/.claude/.sync-pending"

if [ $rc -ne 0 ]; then
  echo "❌ rsync завершился с ошибкой ($rc):" >&2
  printf '%s\n' "$out" >&2
  exit $rc
fi

echo "✅ Синхронизировано: travel → iCloud"
echo "   источник: $REPO"
echo "   копия:    $DEST"
echo ""
echo "Изменения rsync (-av --delete):"
# Байт-безопасный отступ (без sed/awk — не падает на UTF-8 именах)
while IFS= read -r line; do
  [ -n "$line" ] && printf '   %s\n' "$line"
done <<EOF
$out
EOF

exit 0

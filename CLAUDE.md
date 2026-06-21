# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal family travel-planning repository. It holds detailed itineraries, day schedules,
and practical information for trips to various countries. Each trip lives in its own folder
and may have its own country-specific `CLAUDE.md`.

## Folder Structure

- Trips are organized as `YYYY/NN-country/` — e.g. `2025/11-morocco/`, `2026/01-china/`, `2026/06-vietnam/`.
- Each trip folder has its own `CLAUDE.md` with **country-specific** guidance (currency, maps,
  apps, weather, local rules, visa notes). **Read it before planning that trip** — it overrides
  generic assumptions here.
- Inside a trip folder:
  - `dayline.md` — master overview: all days, hotels, flights/transfers, booking status, links to day files
  - `YYYY-MM-DD.md` — detailed day plans
  - `template-day.md` — reusable day-plan template (copy it to start a new day)
- Itineraries are written in **Russian**.

## Travelers (Информация о путешествующих)

Двое взрослых и 2 девочки 8 и 11 лет.

## File Conventions

- UTF-8 encoding for all markdown files (required for Cyrillic text)
- **Always add a newline at the end of every file** (yaml, j2, md, …)
- GPS coordinates format: `34.0661, -4.9710`
- Times in 24-hour format: `7:00-8:15`
- Currency: use the **local currency of the trip** (see the trip's `CLAUDE.md`); add a rough
  conversion to rubles where helpful

## Common Sections in Day Plans

1. Концепция дня
2. Маршрут дня (схема перемещений)
3. Расписание по времени (с эмодзи активностей)
4. Места с GPS-координатами
5. Еда / рестораны
6. Погода и закаты
7. 💰 Бюджет на день
8. 📝 Что взять с собой
9. 📍 Координаты (таблица)
10. ⚠️ Важные напоминания
11. Краткий план

## Emoji Usage

- ✈️ перелёты · 🚕 такси · 🚇 метро · 🚄 поезд · 🚶 пешком · 🚐 трансфер
- 🏨 отели · 🍽️ еда · 🛒 шопинг
- 📍 координаты · 💰 бюджет · ⚠️ важное · 🌤️ погода · 🌅 закат/рассвет

## Правила планирования для города или места

1. найти список популярных достопримечательностей
2. найти список достопримечательностей, которые не очень известны, но заслуживают внимания
2-1. уточнить координаты через Google Maps с помощью haiku — ты иногда указываешь совсем не те
3. уточнить временные рамки в городе
4. понять, сколько надо времени на посещение достопримечательностей
5. уточнить, можем ли мы посмотреть всё в заданное время
6. если не можем — предложить оптимальный вариант
7. не забывать закладывать время просто погулять
8. когда планируешь вечернее фото, учитывай не только реальное время заката, но и горы вокруг,
   из-за которых закат может быть раньше расчётного

## Editing Guidelines

- Maintain consistent emoji usage for activity types
- Keep time allocations realistic for family travel with two children (7 and 10)
- Include practical details (costs, coordinates, phone numbers, opening hours)
- Preserve the conversational, helpful tone of the content
- Include child-friendly activities and educational moments

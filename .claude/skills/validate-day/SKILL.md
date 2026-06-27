---
name: validate-day
description: Validate a single travel day's plan — cross-check weather, verify all coordinates/hours/closures, estimate crowds per location, flag risks, and (if useful) provide the country's taxi-app deeplink. Fans the heavy lookups out to cheap Haiku subagents. Use when the user says /validate-day, asks to "validate / check / проверь / валидируй" the plan for a specific day or "tomorrow / завтра", verify locations & coordinates, check weather, or check crowds for a day.
argument-hint: "[YYYY-MM-DD | today | tomorrow | завтра]  (default: tomorrow)"
allowed-tools: Read, Edit, Bash, Agent, Task, WebSearch, WebFetch, TaskCreate, TaskUpdate, AskUserQuestion
---

# Validate a travel day

Validate ONE day's plan in this travel repo at the lowest possible cost: the expensive
main-loop model does only light orchestration + final synthesis + the file edit, while all
the heavy web lookups are delegated to **cheap Haiku subagents** running in parallel.

What it produces:
1. Weather cross-check for that day's city/date (does it threaten the plan?).
2. Verification of every location's coordinates, opening hours, and weekly closures.
3. Crowd estimate per location for that specific weekday/season + the top mitigation.
4. A risk list (schedule conflicts, jet-lag, heat, sell-outs, timing).
5. Concrete corrections applied to the day file.
6. (Conditional) the country's ride-hailing deeplink/flow — only if relevant (see §6).

---

## ⚙️ Cost & model strategy (READ FIRST — this is the point of the skill)

**Do the minimum in the expensive main loop; push each lookup down to the cheapest model that
can do it.** Tier the work by how much judgment it needs:

| Layer | Model | Tasks |
|-------|-------|-------|
| Cheap lookup | **`haiku`** | weather (fetch + extract), simple coordinate / hours / closure checks |
| Research w/ judgment | **`sonnet`** | crowds per location, ride-hailing / transport research, "live vs stale" nuance |
| Synthesis + edits | **main loop** (Opus, or Sonnet on routine days) | risk reasoning, schedule conflicts, deciding + applying the file edits |

Pass `model` **explicitly** on every Agent call — never rely on inheritance. Spawn all research
agents **in a single message** (multiple Agent calls together) so they run concurrently.

### ⚠️ The 1M-context subagent gotcha + STOP rule (verified)
If the main session runs **Opus with the 1M-context variant** (`claude-opus-4-8[1m]`):
- `model: "haiku"` → **works** (Haiku has no 1M variant, so the inherited 1M flag can't apply).
- `model: "sonnet"` → **FAILS** with *"Usage credits required for 1M context"* (Sonnet *has* a
  1M variant, so the parent's 1M flag leaks in and demands 1M credits).
- omitting `model` → inherits `opus[1m]` (works, but the most expensive option).

This skill is cheapest with **1M context OFF** — then the Haiku/Sonnet tiering above just works
and nothing leaks. For these travel tasks 1M is unnecessary (files are tiny; context never
approaches 200k).

**STOP rule — do this, don't work around it.** If you spawn a subagent and it **fails to launch**
(e.g. the *"Usage credits required for 1M context"* error on a `sonnet` agent), **halt the skill
immediately**: do NOT silently downgrade to Haiku, do NOT continue with partial results. Tell
the user, verbatim, and then stop and wait:

> ⚠️ Отключи 1M-контекст (`/model` → Opus или Sonnet в стандартном контексте) и перезапусти меня.

Once 1M is off, re-running uses the full Haiku → Sonnet → main-loop tiering with no failures.

---

## 1. Locate the day and load context (main loop, cheap)

1. Resolve the **target date** from the user's argument (`$ARGUMENTS`):
   - Accept `YYYY-MM-DD`, or relative words `today`/`сегодня`, `tomorrow`/`завтра`.
   - If absent → default to **tomorrow** relative to the current date (today's date is in the
     session context / `date +%F`).
   - If still ambiguous → ask the user with **one** AskUserQuestion.
2. Find the day file: `*/NN-*/<YYYY-MM-DD>.md` (e.g. `2026/06-vietnam/2026-06-28.md`).
   Use Glob/Bash `find`. If none exists, tell the user and stop.
3. Read **only**: the day file, the trip folder's `CLAUDE.md` (country specifics — currency,
   maps app, taxi app, weather notes, time zone), and skim `dayline.md` only if the day file
   lacks context. The trip `CLAUDE.md` tells you the **country/city**, which drives weather
   source, map app (AMap+Apple in China / Google in Vietnam), and the ride-hailing app.
4. Extract from the day file: the **city**, the **list of locations** (name + file
   coordinates + any Chinese/local name), and the **weekday** of the date.

---

## 2. Fan out the research (parallel subagents — see tiering)

Spawn these in ONE message, each `subagent_type: "general-purpose"`, with `model` set per the
tiering table (**A & B → `haiku`**, **C & D → `sonnet`**). Each agent must **return a compact
markdown summary** (table/bullets) with source URLs — its text is the return value, not a
message to a human. If any spawn fails to launch, apply the **STOP rule** above.

### Agent A — Weather  (model: `haiku`)
> Near-term weather forecast for **{CITY}, {COUNTRY}** on **{DATE} ({weekday})**. Report:
> high/low temp; **rain probability split by morning / afternoon / evening** (call out any
> outdoor blocks in the plan: {OUTDOOR_BLOCKS}); thunderstorm risk; humidity; UV; AQI; sunrise
> & sunset times. Cross-check ≥2 sources (e.g. weather25, weather-forecast.com, CMA/中国天气 for
> China, accuweather, timeanddate, sunrise-sunset.org). End with **implications**: are the
> plan's outdoor blocks dry? umbrella needed? heat concern for kids (8 & 11)? Cite URLs.

### Agent B — Coordinates, hours & closures  (model: `haiku`)
> For these locations in **{CITY}** verify GPS coordinates, opening hours, **weekly closure
> days**, and any **booking/entry rule** that matters on **{DATE} ({weekday})**:
> {LOCATIONS_WITH_COORDS_AND_LOCAL_NAMES}.
> For each: is the file coordinate correct (flag only errors > ~300 m / wrong place — ignore
> sub-100 m GCJ-02 vs WGS-84 shifts in China), confirmed hours, closure days (does anything
> close on {weekday}?), nearest metro/station, and any advance-booking caveat. Return a
> per-location verdict table (OK / corrected lat,lon). Cite official sites + recent reports.

### Agent C — Crowds per location  (model: `sonnet`)
> Expected **crowd level** (low/medium/high/very high) and the single best mitigation for each
> location on **{DATE}** — a **{weekday}** in **{SEASON}** — for a family with kids 8 & 11:
> {LOCATIONS}. Use recent (last ~2 yrs) traveler reports + official notices. Call out
> sell-out/daily-cap/advance-booking risks, best arrival time, and any "fills up by X o'clock"
> facts. Return a table: location | crowd level | #1 tip. Cite sources.

### Agent D — Ride-hailing deeplink (CONDITIONAL — see §6)  (model: `sonnet`)
Only spawn if the trip uses taxis (no rental car, or taxi beats driving). See §6 for the
country-specific prompt and the per-app reality.

> Skip Agent D entirely if the trip's `CLAUDE.md` indicates a rental car is the primary mode
> for this leg.

---

## 3. Synthesize & validate (main loop)

Combine the agent outputs against the day file and check:
- **Timing realism**: travel times between points, total day length, buffers, jet-lag day,
  kid stamina. Flag any block scheduled at its worst crowd window (e.g. a teahouse at weekend
  midday that "fills by 10:00").
- **Weather vs plan**: do outdoor blocks fall in the dry window? Is the stated sunset time
  right? Update Plan-B if the real forecast differs from the file's generic note.
- **Coordinates/hours**: list every correction (wrong metro line, mislabeled gate, missing
  local-language drop-off string, closure that lands on this weekday).
- **Booking/sell-out risks**: caps, real-name rules, kids needing their own tickets, lead time.

---

## 4. Apply corrections to the day file (main loop)

Use Edit to fix the **load-bearing factual errors** in `<YYYY-MM-DD>.md`, preserving the file's
style (emoji, tables, Russian text, sections per repo `CLAUDE.md`). Typical fixes:
- wrong transit line/station, mislabeled entrance, add local-language taxi drop-off string;
- replace a generic weather note with the dated forecast (temps, rain timing, UV, sunrise/sunset);
- add crowd/sell-out warnings + the recommended arrival time / re-ordering;
- add the ride-hailing how-to (§6) if relevant.
Keep edits surgical; don't rewrite whole sections. **Every text file must end with a newline**
(repo rule). Do not touch `dayline.md` unless a coordinate there is also wrong.

---

## 5. Report to the user

Short, skimmable, in the user's language (itineraries are Russian, so usually Russian):
- ✅ verdict (plan OK / needs changes), then
- 🌤️ weather check, 📍 coordinate/hours fixes, 👥 crowds table, ⚠️ **risks** (the important
  part), 🚕 taxi note (if any), 📝 what was changed in the file.
Don't sync to iCloud here — a stop-hook already prompts for that.

---

## 6. Ride-hailing deeplink (conditional)

**When:** only if traveling **without a rental car**, or where **taxi is more convenient** than
driving (city days). Skip for self-drive legs. (See the saved memory
`travel-taxi-deeplinks-skill` for the standing rule + per-app reality.)

Pick the app from the trip `CLAUDE.md`:
- **China** → DiDi via **Alipay** (foreigners). Reality: **no reliable tappable deeplink** —
  DiDi's mini-program was removed from Alipay/WeChat in 2021 and ride-hailing now routes through
  Amap (高德打车). Don't hand the user a stale `alipays://...appId=20000778` link as if it works.
  Put the **manual flow** in the file: Alipay → search «滴滴»/«DiDi» or the **出行** tab → enter
  destination (English or 汉字) → 快车 (economy); pays via linked foreign card, no Chinese number.
- **Vietnam / SE-Asia** → **Grab**. Reality: **no public destination deeplink** (its scheme is
  OAuth-only). Provide "open Grab + manual" + a maps coordinate link.
- **Elsewhere with Uber** → Uber has a real HTTPS universal deeplink:
  `https://m.uber.com/ul/?action=setPickup&dropoff[latitude]=<LAT>&dropoff[longitude]=<LNG>&dropoff[nickname]=<NAME>`
  (nickname/address is mandatory; URL-encode values). This is the **only** major app with a
  reliable destination-prefill link.

Agent D prompt (Haiku) when you do need fresh verification:
> Research, honestly, whether {APP} (used in {COUNTRY}) supports a **tappable destination
> deeplink** a tourist can put in a notes file, and the current best manual flow for a foreigner
> (payment, phone-number requirement, English UI). Distinguish what actually works today from
> stale/ theoretical schemes. Give exact strings if any, else the manual steps. Cite sources.

**General rule for the skill:** prefer **HTTPS universal links** over custom `xxx://` schemes
(schemes only fire on a tap on a device that has the app). Always keep manual steps + an
Apple/Google Maps coordinate link as the fallback.

---

## Notes / gotchas
- Keep the main-loop reads minimal — that's where the expensive tokens are.
- Send all research agents in one message (parallel). 3–4 agents is well under the concurrency cap.
- Agent text **is** the return value; tell agents to return raw structured data, not prose.
- If any subagent fails to launch (e.g. the 1M-credit error on `sonnet`), apply the **STOP rule**
  in the cost section: halt and tell the user to turn off 1M and restart — never silently
  downgrade or continue with partial results.
- China coordinates: don't chase sub-100 m GCJ-02/WGS-84 differences; only fix genuinely wrong pins.

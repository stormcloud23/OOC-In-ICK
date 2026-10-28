# OOC-In-ICK

An experimental **World of Warcraft: Forever** addon for players on RP rulesets who want a private, human-reviewed queue of potentially out-of-character character names.

It observes available nearby player unit tokens (nameplates, target, mouseover, focus) and optionally local chat senders, compares **full first-name + surname** combinations to conservative naming-policy heuristics, and saves potential matches. The player can inspect, ignore, or try to open Blizzard's native report dialog for each entry.

**No reports are automatically submitted.** A suggestion is not a finding of a policy violation. The addon is not affiliated with Blizzard.

## Install

1. Download the repo as a ZIP and open its OOCInICK directory.
2. Copy that entire directory to the Forever client's Interface/AddOns folder so the path reads: AddOns/OOCInICK/OOCInICK_Camelot.toc
3. Enable OOC-In-ICK in the AddOns screen, then log in.
4. Type /ooc to open the review queue.

Forever 1.60.1 uses interface number 16001 and the Camelot TOC flavor. This code has not yet been tested inside the live game client; API behavior may change before/after the November 2026 launch.

## How it works

- Passive observation: NAME_PLATE_UNIT_ADDED, UNIT_NAME_UPDATE, focus/target/mouseover changes, and exposed nameplates; event-driven, no continuous polling.
- Nearby chat: say/yell/emote senders (on by default).
- Optional zone chat: CHAT_MSG_CHANNEL senders (off by default). This is not a census of the zone.
- Detection: Blizzard naming-policy examples; a curated list of pop-culture names, modern brands, internet slang and joke phrases; specific sentence prefixes; decorative X wrappers (e.g. `xXSephirothXx`); and low-confidence repeated-character patterns. Only complete first-and-surname identities are automatically queued.
- Processing: non-matches are cached in a bounded 256-name table, repeated candidate sightings are coalesced into 60-second intervals, and chat events do not allocate an argument table.
- Name identity: "First Surname" and "First-Surname" normalize to the same key, while "FirstSurname" remains distinct; heuristics may still inspect the joined spelling. Older saved entries are migrated on load.
- Review queue: timestamp, zone, source, sightings (at least 60 seconds apart), reason, name, and optional player GUID are held in SavedVariables.
- Report: a user-initiated attempt to open Blizzard's native InWorld report UI with the inappropriate-name category and optional suggested notes. A fresh target/nameplate/GUID-based PlayerLocation is required. If the native frame is missing or restricted, the addon offers manual details and instructs you to use the built-in right-click report function.
- Ignore: excludes that exact normalized full name locally. There is no network communication or shared blocklist.

**Important limitations:** The Lua addon API does not provide arbitrary nearby/whole-zone player rosters, cannot guarantee names on unloaded nameplates, and does not allow addon-triggered C_ReportSystem.SendReport. Opening the Blizzard reporting window and preselecting a category are best-effort and require testing on Forever's current build. There is no background scanning of the entire zone or automated mass reporting.

## Expanded name detection (v0.1.2)

The local rule dictionary now includes references such as Sephiroth, Naruto, Fortnite, TikTok, and Discord; internet slang such as LMAO, Gitgud, Skillissue, and Skibidi; and joke/sentence-like names such as Deez Nuts, Your Mom, Sendhelp, and Whereismyloot.

Names with decorative **double X** at either end of a component are suggested for review: \`xXSephirothXx Blackwick\`, \`xxGrumdin Redbeard\`, and \`Grumdinxx Stone\`. A **single X** at the start or end is only considered when the underlying component is a recognized modern reference (\`xSephiroth\`, \`Sephirothx\`). This deliberately avoids flagging normal fantasy names like \`Xavier\`, \`Xanthus\`, \`Nyx\`, and \`Felix\`.

The \`/ooc test NAME\` command can test an isolated first name, but automatic observation continues to require a **first name and surname** so partial identities are not entered into the reporting queue. All matches require human judgment before reporting. No substring-wide detection or recurring scanning was added.

## Expanded anachronism dictionary (v0.1.3)

The dictionary adds **modern technology and computing** (WiFi, Bluetooth, smartphone, laptop, software, ChatGPT, machine learning, cryptocurrency), **contemporary institutions and products** (tax return, student loan, credit card, insurance, air fryer, social media), **online slang and memes** (Poggers, Copium, Ragequit, Gitgud, AltF4), and **sentence/joke names** (Not A Bot, Error 404, Free Gold, Like And Subscribe, Dontbanme).

Terms are matched as an **entire first-name or surname component**, or across an entire joined full name (such as `Tax Return`). There is no blanket substring matching: `WiFi Stone` is a candidate, while `Wifindor Stone` is not. The new streamer-tag suffix checks recognize names such as `GrumdinTTV` and `RedbeardYT`.

Every match is only a **suggestion for human review**. Warcraft includes technology, steam engineering, machines, commerce, and modern-sounding humor, so generic words such as `engineer`, `steam`, `tank`, `raid`, `bank`, `sigma`, and `chad` are intentionally not blacklisted. Players can remove false positives through Ignore. As before, only complete first-and-surname observations enter the queue automatically.

## Modern professions, organizations and streamer handles (v0.1.4)

Distinctive modern occupations are matched as complete components or combined
full names: Tax Accountant, Software Developer, Data Scientist, FBI Agent,
NASA Astronaut, Real Estate Agent, and Social Media Manager. Generic fantasy-
plausible occupations like Engineer, Merchant and Accountant remain unflagged.

Modern organization references include FBI, CIA, IRS, NASA, NATO, Interpol,
United Nations, SpaceX, Airbnb, and PayPal. Exact matching prevents nearby
fantasy-sounding words from being flagged by substring.

A curated list of WoW streaming handles includes Asmongold, Zackrawrr,
Sodapoppin, EsfandTV, Pikabooirl, Towelliee, Bajheera, JokerdTV,
Ziqoftw, and other recognizable channel handles. Short/fantasy-plausible
aliases Asmon, Esfand, Xaryu, Payo, Guzu, Savix, and Kungen are
flagged **low confidence** to reduce false positives. No legal names
are used. Names matching streamer handles are not proof of a policy violation,
impersonation, or intent to reference the streamer.

Research (October 2026):
- https://www.twitchmetrics.net/channels/viewership?game=World+of+Warcraft
- https://streamscout.org/categories/world-of-warcraft
- https://www.followercharts.com/games/twitch/world-of-warcraft

## Embedded streamer handles and streamer guilds (v0.1.5)

A **short curated list** of unmistakable streamer handles can now match
*inside* a longer name: \`Asmongolden\`, \`Myasmongoldfan\`,
\`Zackrawrrswarrior\`, \`Sodapoppinfan\`, etc. This applies only to
distinctive handles; short or fantasy-plausible aliases such as \`Asmon\`,
\`Esfand\`, \`Payo\`, and \`Guzu\` still require a whole component.

Guild and community handles are also recognized inside longer character
names: \`OnlyFangs\`, \`Fangsly\`, \`RoachCouncil\`, \`OTKNetwork\`,
\`TeamLiquid\`, \`EchoEsports\`, \`ComplexityLimit\`, and \`BigDumbGaming\`.

Asmongold's **Olympus** family of guilds deserves additional context:
names such as \`OlympusGuild\`, \`OlympusArmy\`, \`OlympusRecruiter\`,
\`OlympusFan\` and \`OlympusMute\` are medium-confidence suggestions;
\`Olympus\` by itself and \`LordOlympus\` are **low confidence**, since
Olympus is also a Greek mythological name. \`Olympian\` and \`Olympia\`
alone are not automatically flagged. \`OTK\` alone is low confidence.

These checks apply **only to character names**, not the actual guild tag
or membership. Being in an Olympus/OnlyFangs guild by itself should not
cause a report. All suggestions require human review.

Background sources:
- https://www.asmongold.org/olympus
- https://www.invenglobal.com/articles/9155/to-a-captive-in-game-audience-asmongold-crafts-realm-first-sulfuras-hand-of-ragnaros
- https://raider.io/events/onlyfangs-season-2-hardcore/info
- https://us.forums.blizzard.com/en/wow/t/can-anyone-explain-what-onlyfangs-fangsly-are/2011280/1
- https://news.blizzard.com/en-gb/article/23700347/the-race-to-world-first-in-the-sanctum-of-domination-has-begun

## Chat commands

| Command | Action |
| --- | --- |
| /ooc | Open/close review queue |
| /ooc scan | Rescan exposed unit tokens |
| /ooc test First Surname | Preview a classification without logging |
| /ooc add First Surname | Manually add a name to review |
| /ooc watch First Surname | Always flag a full name |
| /ooc unwatch First Surname | Remove custom flag |
| /ooc ignore First Surname | Ignore name and remove queued entry |
| /ooc unignore First Surname | Remove from ignore list |
| /ooc on or /ooc off | Toggle observation |
| /ooc chat | Toggle local chat monitoring |
| /ooc zonechat | Toggle channel sender monitoring |
| /ooc notify | Toggle chat notifications for new candidates |
| /ooc clear | Clear queued candidates, retaining ignores |
| /ooc status | Display current options and queue count |

## Naming-policy basis

Blizzard's RP realm policy gives non-fantasy names, pop-culture/brand references, and multiword phrases as examples of disruptive character names. The Rules.lua heuristics deliberately avoid blanket dictionary rules; fantasy names can contain ordinary English words, and context matters.

References:
- https://us.support.blizzard.com/en/help/article/135764
- https://news.blizzard.com/en-us/article/24304161/create-a-name-of-your-own-in-wow-forever
- https://github.com/ATTWoWAddon/AllTheThings/issues/2630 (Forever's surname API behavior)
- https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes (Forever interface/security differences)
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ReportFrameShared/ReportFrameShared.lua (modern report-frame integration)

## Testing priorities

1. Confirm full names from GetUnitName and the formatting of CHAT_MSG sender names on the RP ruleset.
2. Confirm Blizzard_ReportFrame can be loaded and opened using ReportInfo:CreateReportInfoFromType(Enum.ReportType.InWorld).
3. Confirm the clicked candidate corresponds to a reportable PlayerLocation; verify old/out-of-range GUID behavior.
4. Ensure the native report's Inappropriate Name category and comment prefill do not taint protected submission. If they do, disable that prefill and retain manual Details copy.
5. Confirm SavedVariables persist between client sessions; beta builds have reportedly exhibited persistence problems.

All candidate reports require independent, deliberate user review.

## Regression testing

The GitHub Actions workflow runs Lua 5.1 syntax checks, naming-heuristic tests, and a headless event/SavedVariables test with mocked WoW APIs. You can run them locally with `lua5.1 tests/rules.lua` and `lua5.1 tests/core.lua` from the repository root. A successful run cannot verify the live client or protected Blizzard reporting flow.

Historical v0.1.0 ignored/watchlist keys were compacted without separators; these remain recognized for backwards compatibility. New entries use separator-aware keys. To remove an old watch or ignore, use `/ooc unwatch First Surname` or `/ooc unignore First Surname`.

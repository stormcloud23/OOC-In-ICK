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
- Detection: examples from Blizzard's RP naming policy, a short list of obvious modern references, suspicious sentence-like prefixes, and low-confidence repeated-character patterns. Only complete first-and-surname identities are automatically queued.
- Processing: non-matches are cached in a bounded 256-name table, repeated candidate sightings are coalesced into 60-second intervals, and chat events do not allocate an argument table.
- Name identity: "First Surname" and "First-Surname" normalize to the same key, while "FirstSurname" remains distinct; heuristics may still inspect the joined spelling. Older saved entries are migrated on load.
- Review queue: timestamp, zone, source, sightings (at least 60 seconds apart), reason, name, and optional player GUID are held in SavedVariables.
- Report: a user-initiated attempt to open Blizzard's native InWorld report UI with the inappropriate-name category and optional suggested notes. A fresh target/nameplate/GUID-based PlayerLocation is required. If the native frame is missing or restricted, the addon offers manual details and instructs you to use the built-in right-click report function.
- Ignore: excludes that exact normalized full name locally. There is no network communication or shared blocklist.

**Important limitations:** The Lua addon API does not provide arbitrary nearby/whole-zone player rosters, cannot guarantee names on unloaded nameplates, and does not allow addon-triggered C_ReportSystem.SendReport. Opening the Blizzard reporting window and preselecting a category are best-effort and require testing on Forever's current build. There is no background scanning of the entire zone or automated mass reporting.

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

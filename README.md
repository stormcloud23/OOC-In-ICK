# OOC-In-ICK

A lightweight **World of Warcraft: Forever** addon that spots potentially out-of-character names on RP realms and keeps a private queue for review.

It observes names available through nearby nameplates, target, mouseover, focus, and chat. You can inspect a match, ignore it, or attempt to open Blizzard's reporting window. **Nothing is reported automatically.** A match is only a suggestion, not proof of a naming-policy violation.

## Installation

1. [Download the repository](https://github.com/stormcloud23/OOC-In-ICK/archive/refs/heads/main.zip).
2. Copy the `OOCInICK` folder into your Forever client's `Interface/AddOns/` directory.
3. Enable the addon, enter the game, and type **`/ooc`** to open the review queue.

The installed file should be at `Interface/AddOns/OOCInICK/OOCInICK_Camelot.toc`.

## Name detection

The addon applies explainable, configurable heuristics rather than AI:

- **Modern references:** brands, technology, websites, contemporary jobs and organizations (e.g. `WiFi`, `ChatGPT`, `FBI Agent`).
- **Out-of-character language:** internet slang, memes, joke phrases, and sentence-like names (e.g. `Deez Nuts`, `Skillissue`, `Mynameis...`).
- **Streamer and community references:** distinctive WoW streamer handles and derivatives (e.g. `Asmongolden`), plus recognizable guild/community references (e.g. `OnlyFangs`, `OlympusGuild`).
- **Gamer-tag styling:** decorative X prefixes/suffixes (`xXSephirothXx`), `TTV`/`YT` endings, and extreme letter repetition.

Most dictionary rules match complete name components or phrases; **distinctive streamer handles** and selected community identifiers can also match within longer names. Ambiguous matches (such as `Esfand` or `Olympus`) are lower confidence. Ordinary fantasy names and terms like `Engineer` are not automatically treated as violations.

Automatic logging requires an observed **first name and surname**. Results include the reason, confidence, location, and sightings. Detection is event-driven, with a small cache and no continuous scanning.

## Commands

| Command | Purpose |
| --- | --- |
| `/ooc` | Open/close the review queue |
| `/ooc scan` | Recheck currently exposed player units |
| `/ooc test NAME` | Test a name without logging it |
| `/ooc add NAME` | Manually queue a full name |
| `/ooc watch NAME` / `unwatch NAME` | Add/remove a full-name watchlist entry |
| `/ooc ignore NAME` / `unignore NAME` | Ignore/unignore a full name |
| `/ooc chat` / `zonechat` | Toggle local chat / channel-sender monitoring |
| `/ooc notify` / `on` / `off` | Toggle notifications or detection |
| `/ooc clear` / `status` | Clear the queue or show settings |

Local chat monitoring is enabled by default; channel-sender monitoring is off by default. Use complete first-and-surname values for watchlists and manual additions.

## Reporting and limitations

The **Report** button attempts to hand off to Blizzard's native report interface, with a suggested category and notes where the client allows it. If that interface is unavailable or protected, use the game's normal right-click **Report** action. You must review and submit every report yourself.

- WoW does **not** expose a complete list of players in a zone; only names actually available to the client can be checked.
- The addon examines **character names**, not guild membership. A streamer or guild name resemblance may be coincidental.
- The native reporting flow and surname APIs still need validation in the Forever client; automated Lua tests cannot guarantee in-game behavior.
- No data is shared externally, and there is no automatic reporting or mass-reporting feature.

## Development

Rules live in [`OOCInICK/Rules.lua`](OOCInICK/Rules.lua). GitHub Actions checks Lua 5.1 syntax and runs name-detection and mocked event tests. To run locally from the repo root:

```sh
lua5.1 tests/rules.lua
lua5.1 tests/core.lua
```

OOC-In-ICK is an independent community addon and is not affiliated with Blizzard.

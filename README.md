# Kjellman ESO Helper (KEH)

Kjellman ESO Helper is a quality-of-life addon for **The Elder Scrolls Online (PC)**. It combines pricing, inventory management, build planning, item finding, quest focus and an in-game notepad in one addon.

Current version: **2.7.2**

## Features

- TTC suggested prices in inventory, stores and guild traders.
- Guild-trader deal percentages with clear red/green comparison colors.
- Smart inventory and bank filters, Armory protection and useful item badges.
- Notifications for valuable items and planned build drops.
- Build Planner with sets, armor weight, weapon type, traits and owned-item matching.
- Build import/export using the `KEHBUILD` text format.
- Item Finder with acquisition hints and zone names for overland, dungeon, monster and special sets.
- Mythic Helper with name search, owned/active/missing lead status, zones and detailed drop hints through LibLeadDrop.
- Floating Notepad with General, Farming, Shopping and Build tabs.
- Checklists, missing-build lists and `KEHNOTE` import/export.
- Automatic focus for newly accepted quests.
- Goldmaker Production with target stock, material requirements and TTC-based profit estimates.
- Goldmaker Farming with valuable-material rankings, acquisition guidance and an Active Farm List.
- Configurable fishing bite sound and large `REEL IN!` indicator.

## Requirements

- The Elder Scrolls Online for PC.
- [Tamriel Trade Centre](https://www.tamrieltradecentre.com/) is optional but required for TTC market-price features.
- LibAddonMenu-2.0 is optional and enables the settings panel.
- Master Merchant is **not required**.

## Installation

1. Download the latest release zip.
2. Extract the `KjellmanESOHelper` folder into:
   `Documents/Elder Scrolls Online/live/AddOns/`
3. Enable **Kjellman ESO Helper** from ESO's Add-Ons menu.
4. Run `/reloadui` after updating.

## Main controls

- Floating `KEH Build` button: open Build Planner.
- `FIND`: open Item Finder.
- `INV`: open KEH Inventory Manager.
- `NOTES`: open KEH Notepad.
- `GOLD`: open Goldmaker Production and Farming.
- `MYTHIC`: open Mythic Helper.
- Build slot left click: choose a set.
- Build slot right click: cycle armor weight or weapon type.
- Build slot Shift + right click: cycle trait.
- Blue `+` on an inventory row: add the item to Notepad.

## Slash commands

- `/kehbuild` — open Build Planner.
- `/kehimport` — open Build Import.
- `/kehnotes` — open Notepad.
- `/kehgold` — open Goldmaker.
- `/kehmythic <name>` — search for and open a Mythic item.
- `/kehfishalert` — test the configured fishing bite notifications.
- `/kehprice` — show TTC price for the selected guild-store item.

## Updating and releases

GitHub releases contain an install-ready `KjellmanESOHelper` folder. Release archives are generated automatically when a version tag such as `v2.0.3` is pushed.

### KEH Updater for Windows

For the easiest installation, download `KEH-Updater.exe` from the latest release and run it while ESO is closed. The updater:

- finds the standard ESO `live/AddOns` folder automatically;
- compares the installed KEH version with the latest GitHub release;
- downloads and validates the official release archive;
- creates a timestamped backup before replacing the addon;
- can restore the latest backup;
- never modifies ESO `SavedVariables`, builds or Notepad data.

Windows may show a SmartScreen warning because this personal utility is not code-signed. The updater source is available in the [`Updater`](Updater) directory.

## License

Licensed under the MIT License. See [LICENSE](LICENSE).

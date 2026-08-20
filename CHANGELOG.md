# Changelog

## Unreleased

- Rebuilt Set Tracker ownership around a shared LibSets-canonical model. Worn,
  backpack, bank and migrated character snapshots now feed the same data used
  by the tracker list, details and Build Planner. Owned sets are discovered
  automatically, the list is scrollable and REFRESH SETS performs a manual
  rescan; automatic rescans are scheduled through LibAsync.
- Added live name filtering and a shown/total counter to MY SETS, plus detail
  filters for light, medium and heavy armor, weapons and jewelry.
- Added LibSets as a required standalone dependency and use its public API for
  canonical set-name lookup and complete item-piece definitions when ESO's
  Collections API returns aliases or no pieces.
- Added a shared internal SetData module for canonical set IDs, normalized set
  identity, collection paths, piece keys, crafted definitions and drop rules.
  Item Finder, Set Tracker and Build Planner now use the same programmatic data.
- Standardized all player-facing addon text, settings, tooltips, notifications
  and chat messages in English for public distribution.
- Fixed KEHBUILD imports treating a jewelry trait such as Infused as an armor
  weight, which prevented neck and ring slots from importing.
- Made acquired leads clickable in Mythic Helper to start their ESO scrying session directly.
- Fixed Item Finder resolving the overworld zone for dungeon categories that
  cover multiple instances, such as Fungal Grotto I and II in Stonefalls.
- Added Set Tracker with a starter watch list, red/orange/green collection
  status, set bonuses, piece sources, bank locations, character snapshots and
  stickerbook/transmute availability. Item Finder results can add sets directly.
- Replaced the long KEH launcher with a compact icon bar and hover tooltips,
  including direct access to the new Set Tracker.
- Added physical five-piece completion and name-based matching for crafted sets
  such as Hunding's Rage, which do not have stickerbook entries.
- Fixed Item Finder losing mouse/edit focus after opening and closing Set Tracker.
- List missing armor, jewelry and weapon types for crafted sets instead of
  showing only cached physical pieces.

## 2.7.2

- Added built-in drop hints for Shattered Paths Signet because LibLeadDrop 1.0.0 does not yet contain its five leads.

## 2.7.1

- Added Details and All Mythics tabs with collection status and click-through navigation.
- Increased the Mythic Helper height.
- Added red, orange and green status for missing, active/partial and completed Mythics.
- Added native ESO item tooltips when hovering Mythics in the full list.
- Improved fishing bite detection and made `/kehfishalert` use a more noticeable alert sound reliably.

## 2.7.0

- Added Mythic Helper with search for all five-fragment Mythic antiquity sets.
- Shows recovered fragments, active leads, missing leads, excavation zones and drop hints.
- Added the `MYTHIC` launcher button and `/kehmythic <name>` command.
- Added optional LibLeadDrop integration for maintained, detailed lead sources.

## 2.6.3

- Added Goldmaker with separate Production and Farming workflows.
- Added production plans, target stock, live material counts and Farming Notes export.
- Added TTC-based Profitable Crafts ranking using material cost, net profit, sales signals and competition.
- Added Best to Farm ranking, acquisition guidance and a manually managed Active Farm List.
- Added tri-state inventory and bank filters with movable filter window and improved Armory-item handling.
- Improved Build Planner ownership matching and armor/weapon selection behavior.
- Added configurable fishing bite sound and large `REEL IN!` indicator.
- Added `/kehgold` and `/kehfishalert` commands.

## 2.1.0

- Added zone names to Item Finder results.
- Dungeon and subzone results resolve to their parent story zone when ESO provides that relationship.
- Added an overland fallback when ESO's zone API does not return a direct match.

## 2.0.3

- Added the floating KEH Notepad with four saved tabs.
- Added checklists, missing-build export and KEHNOTE import/export.
- Added a safe inventory-row button for sending items to Notepad.
- Added Build Planner armor-weight and weapon-type cycling.
- Improved ownership matching for armor weight and traits.
- Added build import/export, saved build navigation and item acquisition hints.
- Added smart inventory/bank filters, Armory protection and valuable-item notifications.
- Added TTC pricing and guild-trader deal comparisons.

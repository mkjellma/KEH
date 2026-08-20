local KPH = KjellmanESOHelper

local function AddCount(target, key, amount)
    target[key] = (target[key] or 0) + (amount or 1)
end

local function ContainsId(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

function KPH:GetCanonicalSetFromItemLink(itemLink)
    if not itemLink or itemLink == "" then return nil end
    if self:IsLibSetsReady() and type(LibSets.IsSetByItemLink) == "function" then
        local hasSet, setName, setId = LibSets.IsSetByItemLink(itemLink)
        if hasSet and setId and setId > 0 then
            return setId,
                zo_strformat("<<C:1>>", setName or GetItemSetName(setId))
        end
    end
    local hasSet, setName, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
    if not hasSet or not setId or setId <= 0 then return nil end
    return self:CanonicalizeSetId(setId, setName),
        zo_strformat("<<C:1>>", setName or GetItemSetName(setId))
end

function KPH:BuildOwnedSetItem(itemLink, location, characterName)
    local setId, setName = self:GetCanonicalSetFromItemLink(itemLink)
    if not setId then return nil end
    return {
        setId = setId,
        setName = setName,
        itemId = GetItemLinkItemId(itemLink),
        pieceKey = self:GetSetPieceTypeKey(itemLink),
        equipType = GetItemLinkEquipType(itemLink),
        weaponType = GetItemLinkWeaponType(itemLink),
        armorType = GetItemLinkArmorType(itemLink),
        traitType = GetItemLinkTraitInfo(itemLink),
        link = itemLink,
        location = location,
        character = characterName,
    }
end

function KPH:ScanSetOwnershipBag(bagId, location, characterName, output)
    for slotIndex = 0, (GetBagSize(bagId) or 0) - 1 do
        local link = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
        local item = self:BuildOwnedSetItem(link, location, characterName)
        if item then table.insert(output, item) end
    end
end

function KPH:SnapshotCurrentSetOwnership()
    self.savedVariables.setOwnershipCharacters =
        self.savedVariables.setOwnershipCharacters or {}
    local characterId = tostring(GetCurrentCharacterId())
    local characterName = zo_strformat("<<C:1>>", GetUnitName("player"))
    local items = {}
    self:ScanSetOwnershipBag(BAG_WORN, "equipped", characterName, items)
    self:ScanSetOwnershipBag(BAG_BACKPACK, "backpack", characterName, items)
    self.savedVariables.setOwnershipCharacters[characterId] = {
        name = characterName,
        updated = GetTimeStamp(),
        items = items,
    }
end

function KPH:MigrateLegacySetOwnershipSnapshots()
    if self.savedVariables.setOwnershipMigrated then return end
    self.savedVariables.setOwnershipCharacters =
        self.savedVariables.setOwnershipCharacters or {}
    for characterId, legacy in pairs(
        self.savedVariables.setTrackerCharacters or {}) do
        if not self.savedVariables.setOwnershipCharacters[characterId] then
            local items = {}
            for _, counts in pairs(legacy.pieces or {}) do
                if counts.link and counts.link ~= "" then
                    for _ = 1, counts.worn or 0 do
                        local item = self:BuildOwnedSetItem(counts.link,
                            "equipped", legacy.name)
                        if item then table.insert(items, item) end
                    end
                    for _ = 1, counts.backpack or 0 do
                        local item = self:BuildOwnedSetItem(counts.link,
                            "backpack", legacy.name)
                        if item then table.insert(items, item) end
                    end
                end
            end
            self.savedVariables.setOwnershipCharacters[characterId] = {
                name = legacy.name, updated = 0, items = items,
            }
        end
    end
    self.savedVariables.setOwnershipMigrated = true
end

function KPH:RefreshSetOwnership(autoTrack)
    if not self.savedVariables then return end
    self:MigrateLegacySetOwnershipSnapshots()
    self:SnapshotCurrentSetOwnership()
    local model = { sets = {}, allItems = {} }
    local function AddItem(item)
        if not item or not item.setId then return end
        local set = model.sets[item.setId]
        if not set then
            set = { id = item.setId, name = item.setName, pieces = {}, items = {} }
            model.sets[item.setId] = set
        end
        table.insert(set.items, item)
        table.insert(model.allItems, item)
        local piece = set.pieces[item.pieceKey]
        if not piece then
            piece = { key = item.pieceKey, link = item.link, bank = 0,
                characters = {}, count = 0 }
            set.pieces[item.pieceKey] = piece
        end
        piece.count = piece.count + 1
        piece.link = piece.link or item.link
        if item.location == "bank" then
            piece.bank = piece.bank + 1
        else
            local ownerKey = item.character or "Unknown character"
            local owner = piece.characters[ownerKey]
            if not owner then
                owner = { name = ownerKey, backpack = 0, worn = 0 }
                piece.characters[ownerKey] = owner
            end
            if item.location == "equipped" then owner.worn = owner.worn + 1
            else owner.backpack = owner.backpack + 1 end
        end
    end
    for _, snapshot in pairs(self.savedVariables.setOwnershipCharacters or {}) do
        for _, item in ipairs(snapshot.items or {}) do AddItem(item) end
    end
    local bankItems = {}
    self:ScanSetOwnershipBag(BAG_BANK, "bank", nil, bankItems)
    self:ScanSetOwnershipBag(BAG_SUBSCRIBER_BANK, "bank", nil, bankItems)
    for _, item in ipairs(bankItems) do AddItem(item) end
    for _, set in pairs(model.sets) do
        for key, ownerMap in pairs(set.pieces) do
            local characters = {}
            for _, owner in pairs(ownerMap.characters) do
                table.insert(characters, owner)
            end
            table.sort(characters, function(a, b) return a.name < b.name end)
            ownerMap.characters = characters
        end
    end
    self.setOwnership = model
    if autoTrack then
        local tracked = self.savedVariables.trackedSetIds or {}
        self.savedVariables.trackedSetIds = tracked
        for setId in pairs(model.sets) do
            if not ContainsId(tracked, setId) then table.insert(tracked, setId) end
        end
        table.sort(tracked, function(a, b)
            return zo_strlower(GetItemSetName(a) or tostring(a)) <
                zo_strlower(GetItemSetName(b) or tostring(b))
        end)
    end
end

function KPH:GetSetOwnership(setId)
    setId = self:CanonicalizeSetId(setId)
    return self.setOwnership and self.setOwnership.sets[setId]
end

function KPH:GetSetTrackerPhysicalLocations(setId)
    local set = self:GetSetOwnership(setId)
    return set and set.pieces or {}
end

function KPH:GetOwnedSetItemLinks()
    local links = {}
    for _, item in ipairs(self.setOwnership and self.setOwnership.allItems or {}) do
        table.insert(links, { setId = item.setId, link = item.link,
            location = item.location, character = item.character })
    end
    return links
end

function KPH:GetSetTrackerViewModel(setId)
    setId = self:CanonicalizeSetId(setId)
    local ownedSet = self:GetSetOwnership(setId)
    local physical = ownedSet and ownedSet.pieces or {}
    local definitions, hasCollection = self:GetSetDataPieceDefinitions(setId)
    local rows, physicalTypes, collected, owned = {}, 0, 0, 0
    for _ in pairs(physical) do physicalTypes = physicalTypes + 1 end
    for _, definition in ipairs(definitions) do
        local location = physical[definition.key]
        local stickerbook = hasCollection and definition.collectionSlot and
            IsItemSetCollectionSlotUnlocked(setId, definition.collectionSlot) or false
        if stickerbook then collected = collected + 1 end
        if location or stickerbook then owned = owned + 1 end
        table.insert(rows, { definition = definition, location = location,
            stickerbook = stickerbook })
    end
    local total = #definitions
    if not hasCollection and GetItemSetType(setId) == ITEM_SET_TYPE_CRAFTED then
        total = 5
        owned = math.min(physicalTypes, total)
    end
    return { id = setId, name = GetItemSetName(setId), rows = rows,
        total = total, owned = owned, physical = physicalTypes,
        collected = collected, hasCollection = hasCollection }
end

function KPH:GetSetTrackerStats(setId)
    local view = self:GetSetTrackerViewModel(setId)
    return { total = view.total, owned = view.owned,
        physical = view.physical, collected = view.collected }
end

function KPH:SetTrackerStatus(setId)
    local stats = self:GetSetTrackerStats(setId)
    if stats.total > 0 and stats.owned >= stats.total then
        return "66CC66", "COMPLETE", stats
    elseif stats.owned > 0 then return "E89B35", "PARTIAL", stats end
    return "E05A5A", "NOT FOUND", stats
end

function KPH:RefreshSetPlanner()
    if not self.savedVariables or self.setTrackerRefreshing then return end
    self.setTrackerRefreshing = true
    self:RefreshSetOwnership(true)
    local normalized, seen = {}, {}
    for _, storedId in ipairs(self.savedVariables.trackedSetIds or {}) do
        local resolvedId = self:CanonicalizeSetId(storedId)
        if resolvedId and resolvedId > 0 and not seen[resolvedId] then
            table.insert(normalized, resolvedId)
            seen[resolvedId] = true
        end
    end
    self.savedVariables.trackedSetIds = normalized
    if self.savedVariables.plannedSetId then
        self.savedVariables.plannedSetId = self:CanonicalizeSetId(
            self.savedVariables.plannedSetId)
    end
    if self.selectedTrackedSetId then
        self.selectedTrackedSetId = self:CanonicalizeSetId(
            self.selectedTrackedSetId)
    end
    self:RefreshSetTrackerList()
    if self.setPlannerText then
        self.setPlannerText:SetText(self:BuildSetTrackerDetails(
            self.selectedTrackedSetId))
        self.setPlannerDetailsChild:SetHeight(math.max(620,
            self.setPlannerText:GetTextHeight() + 20))
    end
    self.setTrackerRefreshing = false
end

function KPH:QueueSetOwnershipRefresh(autoTrack, refreshUI)
    if self.setOwnershipRefreshQueued then return end
    self.setOwnershipRefreshQueued = true
    local function RunRefresh()
        self:RefreshSetOwnership(autoTrack ~= false)
    end
    local function FinishRefresh()
        self.setOwnershipRefreshQueued = false
        if refreshUI and self.setPlannerWindow and
           not self.setPlannerWindow:IsHidden() then self:RefreshSetPlanner() end
        if self.buildPlannerWindow and not self.buildPlannerWindow:IsHidden() then
            self:RefreshBuildPlanner()
        end
    end
    if LibAsync and type(LibAsync.Create) == "function" then
        LibAsync:Create(self.name .. "SetOwnershipRefresh")
            :Call(RunRefresh):Finally(FinishRefresh)
    else
        zo_callLater(function()
            RunRefresh()
            FinishRefresh()
        end, 100)
    end
end

function KPH:InitializeSetPlanner()
    self:SeedSetTracker()
    local function ShowOrAdd(text)
        text = zo_strtrim(text or "")
        if text == "" then
            self:CreateSetPlannerWindow()
            self:RefreshSetPlanner()
            self.setPlannerWindow:SetHidden(false)
            SCENE_MANAGER:SetInUIMode(true)
        elseif not self:SelectPlannedSet(text) then
            self:FindPlannedSetByName(text)
        end
    end
    SLASH_COMMANDS["/kehsets"] = ShowOrAdd
    SLASH_COMMANDS["/kehplanner"] = ShowOrAdd
    EVENT_MANAGER:RegisterForEvent(self.name .. "SetOwnershipCollection",
        EVENT_ITEM_SET_COLLECTION_UPDATED,
        function() self:QueueSetOwnershipRefresh(true, true) end)
    EVENT_MANAGER:RegisterForEvent(self.name .. "SetOwnershipInventory",
        EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
        function(_, bagId, slotIndex, isNewItem, _, _, stackCountChange)
            self:CheckPlannerInventoryItem(
                bagId, slotIndex, isNewItem, stackCountChange)
            if bagId == BAG_BACKPACK or bagId == BAG_WORN or
               bagId == BAG_BANK or bagId == BAG_SUBSCRIBER_BANK then
                self:QueueSetOwnershipRefresh(true, true)
            end
        end)
    EVENT_MANAGER:RegisterForEvent(self.name .. "SetOwnershipActivated",
        EVENT_PLAYER_ACTIVATED,
        function() self:QueueSetOwnershipRefresh(true, true) end)
end

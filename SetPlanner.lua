local KPH = KjellmanESOHelper

local function GetPieceKey(itemLink)
    local equipType = GetItemLinkEquipType(itemLink)
    local weaponType = GetItemLinkWeaponType(itemLink)
    if weaponType and weaponType ~= WEAPONTYPE_NONE then
        return string.format("w:%d", weaponType)
    end
    return string.format("e:%d", equipType or 0)
end

local function GetCollectionLocation(itemSetId)
    local names = {}
    local categoryId = GetItemSetCollectionCategoryId(itemSetId)
    local safety = 0
    while categoryId and categoryId > 0 and safety < 6 do
        local name = GetItemSetCollectionCategoryName(categoryId)
        if name and name ~= "" then table.insert(names, 1, name) end
        categoryId = GetItemSetCollectionCategoryParentId(categoryId)
        safety = safety + 1
    end
    return #names > 0 and table.concat(names, " > ") or "Okänd plats"
end

local function GetSource(itemSetType, itemLink)
    local equipType = GetItemLinkEquipType(itemLink)
    local weaponType = GetItemLinkWeaponType(itemLink)
    local isWeapon = weaponType and weaponType ~= WEAPONTYPE_NONE

    if itemSetType == ITEM_SET_TYPE_WORLD then
        if equipType == EQUIP_TYPE_WAIST or equipType == EQUIP_TYPE_FEET then
            return "Delve-boss"
        elseif equipType == EQUIP_TYPE_HEAD or equipType == EQUIP_TYPE_CHEST or
               equipType == EQUIP_TYPE_LEGS then
            return "World boss"
        elseif equipType == EQUIP_TYPE_SHOULDERS or equipType == EQUIP_TYPE_HAND then
            return "Public dungeon-boss"
        elseif equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK then
            return "Dark Anchor / world event"
        elseif isWeapon then
            return "World boss / public dungeon-boss"
        end
        return "Zonaktivitet / treasure chest"
    elseif itemSetType == ITEM_SET_TYPE_DUNGEON then
        if isWeapon or equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK then
            return "Dungeonens slutboss"
        elseif equipType == EQUIP_TYPE_WAIST or equipType == EQUIP_TYPE_HAND or
               equipType == EQUIP_TYPE_FEET then
            return "Dungeonens minibossar"
        end
        return "Dungeonbossar"
    elseif itemSetType == ITEM_SET_TYPE_MONSTER then
        if equipType == EQUIP_TYPE_HEAD then return "Veteran-dungeonens slutboss" end
        return "Undaunted-kista"
    elseif itemSetType == ITEM_SET_TYPE_CRAFTED then
        return "Crafting station"
    elseif itemSetType == ITEM_SET_TYPE_WEAPON then
        return "Arena / specialaktivitet"
    end
    return "Setets aktivitet"
end

function KPH:GetPhysicalSetPieces(itemSetId)
    local owned = {}
    local bags = { BAG_BACKPACK, BAG_WORN, BAG_BANK, BAG_SUBSCRIBER_BANK }
    for _, bagId in ipairs(bags) do
        for slotIndex = 0, GetBagSize(bagId) - 1 do
            local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
            if itemLink and itemLink ~= "" then
                local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
                if hasSet and setId == itemSetId then
                    owned[GetPieceKey(itemLink)] = true
                end
            end
        end
    end
    return owned
end

function KPH:RefreshPlannerOwnedCache()
    local itemSetId = self.savedVariables and self.savedVariables.plannedSetId
    self.plannerOwnedKeys = itemSetId and itemSetId > 0 and
        self:GetPhysicalSetPieces(itemSetId) or {}
end

function KPH:ShowPlannerPieceFound(itemLink)
    local itemName = zo_strformat("<<C:1>>", GetItemLinkName(itemLink))
    local setName = select(2, GetItemLinkSetInfo(itemLink, false))
    local message = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(
        CSA_CATEGORY_SMALL_TEXT, SOUNDS.QUEST_OBJECTIVE_INCREMENT)
    message:SetSound(SOUNDS.QUEST_OBJECTIVE_INCREMENT)
    message:SetText(string.format("KEH Planner: %s hittad!", itemName))
    message:MarkSuppressIconFrame()
    message:MarkShowImmediately()
    CENTER_SCREEN_ANNOUNCE:QueueMessage(message)
    d(string.format("[KEH] Planner: %s från %s hittad.", itemName,
        zo_strformat("<<C:1>>", setName)))
end

function KPH:CheckPlannerInventoryItem(bagId, slotIndex, isNewItem,
                                       stackCountChange)
    if not self.savedVariables or not self.savedVariables.plannerNotifications then
        return
    end
    if bagId ~= BAG_BACKPACK or (not isNewItem and (stackCountChange or 0) <= 0) then
        return
    end
    local plannedSetId = self.savedVariables.plannedSetId
    if not plannedSetId or plannedSetId <= 0 then return end
    local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
    if not itemLink or itemLink == "" then return end
    local hasSet, _, _, _, _, itemSetId = GetItemLinkSetInfo(itemLink, false)
    if not hasSet or itemSetId ~= plannedSetId then return end

    self.plannerOwnedKeys = self.plannerOwnedKeys or {}
    local key = GetPieceKey(itemLink)
    if self.plannerOwnedKeys[key] then return end
    self.plannerOwnedKeys[key] = true
    self:ShowPlannerPieceFound(itemLink)
    self:RefreshSetPlanner()
end

function KPH:BuildSetPlannerText()
    local itemSetId = self.savedVariables and self.savedVariables.plannedSetId
    if not itemSetId or itemSetId <= 0 then
        return "|cE89B35Inget set valt.|r\n\nSkriv |cFFFFFF/kehplan|r följt av en länkad set-del i chatten."
    end

    local setName = GetItemSetName(itemSetId)
    if not setName or setName == "" then
        return "Det sparade setet kunde inte hittas. Välj setet igen med /kehplan."
    end

    local itemSetType = GetItemSetType(itemSetId)
    local physical = self:GetPhysicalSetPieces(itemSetId)
    local groups, groupOrder = {}, {}
    local physicalCount, collectedCount, missingCount = 0, 0, 0
    local numPieces = GetNumItemSetCollectionPieces(itemSetId)

    for index = 1, numPieces do
        local pieceId, slot = GetItemSetCollectionPieceInfo(itemSetId, index)
        local itemLink = GetItemSetCollectionPieceItemLink(pieceId,
            LINK_STYLE_DEFAULT, ITEM_TRAIT_TYPE_NONE, ITEM_FUNCTIONAL_QUALITY_MAGIC)
        if itemLink and itemLink ~= "" then
            local source = GetSource(itemSetType, itemLink)
            if not groups[source] then
                groups[source] = {}
                table.insert(groupOrder, source)
            end
            local key = GetPieceKey(itemLink)
            local marker
            if physical[key] then
                marker = "|c66CC66✓|r"
                physicalCount = physicalCount + 1
            elseif IsItemSetCollectionSlotUnlocked(itemSetId, slot) then
                marker = "|cE89B35●|r"
                collectedCount = collectedCount + 1
            else
                marker = "|cE05A5A✗|r"
                missingCount = missingCount + 1
            end
            local pieceName = zo_strformat("<<C:1>>", GetItemLinkName(itemLink))
            table.insert(groups[source], string.format("%s %s", marker, pieceName))
        end
    end

    local lines = {
        string.format("|cFFFFFF%s|r", zo_strformat("<<C:1>>", setName)),
        string.format("|cAAAAAA%s|r", GetCollectionLocation(itemSetId)),
        "",
        string.format("|c66CC66✓ Fysisk: %d|r   |cE89B35● Collections: %d|r   |cE05A5A✗ Saknas: %d|r",
            physicalCount, collectedCount, missingCount),
        "",
    }
    for _, source in ipairs(groupOrder) do
        table.insert(lines, string.format("|cD6B35A%s|r", source))
        table.insert(lines, table.concat(groups[source], "   "))
        table.insert(lines, "")
    end
    table.insert(lines, "|c888888Treasure chests och vissa quests kan ge andra delar än huvudregeln.|r")
    return table.concat(lines, "\n")
end

function KPH:RefreshSetPlanner()
    if self.setPlannerText then
        self.setPlannerText:SetText(self:BuildSetPlannerText())
    end
end

function KPH:CreateSetPlannerWindow()
    if self.setPlannerWindow then return end
    local window = WINDOW_MANAGER:CreateTopLevelWindow(self.name .. "SetPlanner")
    window:SetDimensions(760, 620)
    window:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    window:SetClampedToScreen(true)
    window:SetMouseEnabled(true)
    window:SetMovable(true)
    window:SetHidden(true)

    local backdrop = WINDOW_MANAGER:CreateControlFromVirtual(nil, window,
        "ZO_DefaultBackdrop")
    backdrop:SetAnchorFill(window)

    local title = WINDOW_MANAGER:CreateControl(nil, window, CT_LABEL)
    title:SetAnchor(TOPLEFT, window, TOPLEFT, 24, 18)
    title:SetFont("ZoFontWinH1")
    title:SetText("KEH Set Planner")

    local close = WINDOW_MANAGER:CreateControlFromVirtual(nil, window,
        "ZO_CloseButton")
    close:SetAnchor(TOPRIGHT, window, TOPRIGHT, -8, 8)
    close:SetHandler("OnClicked", function() window:SetHidden(true) end)

    local textControl = WINDOW_MANAGER:CreateControl(nil, window, CT_LABEL)
    textControl:SetAnchor(TOPLEFT, window, TOPLEFT, 24, 62)
    textControl:SetAnchor(BOTTOMRIGHT, window, BOTTOMRIGHT, -24, -22)
    textControl:SetFont("ZoFontGame")
    textControl:SetVerticalAlignment(TEXT_ALIGN_TOP)
    textControl:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    self.setPlannerWindow = window
    self.setPlannerText = textControl
end

function KPH:SelectPlannedSetId(itemSetId)
    if not itemSetId or itemSetId <= 0 then return false end
    local setName = GetItemSetName(itemSetId)
    if not setName or setName == "" then return false end
    self.savedVariables.plannedSetId = itemSetId
    self:RefreshPlannerOwnedCache()
    d(string.format("[KEH] Planner valt: %s", zo_strformat("<<C:1>>", setName)))
    self:CreateSetPlannerWindow()
    self:RefreshSetPlanner()
    self.setPlannerWindow:SetHidden(false)
    return true
end

function KPH:SelectPlannedSet(itemLink)
    if type(itemLink) ~= "string" or not string.find(itemLink, "|H", 1, true) then
        return false
    end
    local hasSet, _, _, _, _, itemSetId = GetItemLinkSetInfo(itemLink, false)
    if not hasSet then return false end
    return self:SelectPlannedSetId(itemSetId)
end

function KPH:FindPlannedSetByName(searchText)
    local needle = zo_strlower(zo_strtrim(searchText or ""))
    if needle == "" then return false end
    local matches, exactMatch = {}, nil
    local itemSetId = GetNextItemSetCollectionId(nil)
    while itemSetId do
        local setName = GetItemSetName(itemSetId)
        local loweredName = zo_strlower(setName or "")
        if loweredName == needle then
            exactMatch = itemSetId
            break
        elseif string.find(loweredName, needle, 1, true) then
            table.insert(matches, { id = itemSetId, name = setName })
        end
        itemSetId = GetNextItemSetCollectionId(itemSetId)
    end

    if exactMatch then return self:SelectPlannedSetId(exactMatch) end
    if #matches == 1 then return self:SelectPlannedSetId(matches[1].id) end
    if #matches > 1 then
        d(string.format("[KEH] Flera set matchar '%s':", searchText))
        for index = 1, math.min(10, #matches) do
            d(string.format("  %s", zo_strformat("<<C:1>>", matches[index].name)))
        end
        d("[KEH] Skriv ett mer exakt setnamn.")
        return false
    end
    d(string.format("[KEH] Inget Collections-set matchar '%s'.", searchText))
    return false
end

function KPH:InitializeSetPlanner()
    SLASH_COMMANDS["/kehplan"] = function(text)
        text = zo_strtrim(text or "")
        if text == "" then
            d("[KEH] Använd: /kehplan Setnamn eller /kehplan [länkad set-del]")
            return
        end
        if not self:SelectPlannedSet(text) then
            self:FindPlannedSetByName(text)
        end
    end
    SLASH_COMMANDS["/kehplanner"] = function()
        self:CreateSetPlannerWindow()
        self:RefreshSetPlanner()
        self.setPlannerWindow:SetHidden(not self.setPlannerWindow:IsHidden())
    end
    EVENT_MANAGER:RegisterForEvent(self.name .. "PlannerCollection",
        EVENT_ITEM_SET_COLLECTION_UPDATED, function()
            if self.setPlannerWindow and not self.setPlannerWindow:IsHidden() then
                self:RefreshSetPlanner()
            end
        end)
    EVENT_MANAGER:RegisterForEvent(self.name .. "PlannerInventory",
        EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
        function(_, bagId, slotIndex, isNewItem, _, _, stackCountChange)
            zo_callLater(function()
                self:CheckPlannerInventoryItem(bagId, slotIndex, isNewItem,
                    stackCountChange)
            end, 1)
        end)
    EVENT_MANAGER:RegisterForEvent(self.name .. "PlannerActivated",
        EVENT_PLAYER_ACTIVATED, function()
            EVENT_MANAGER:UnregisterForEvent(self.name .. "PlannerActivated",
                EVENT_PLAYER_ACTIVATED)
            self:RefreshPlannerOwnedCache()
        end)
end

local KPH = KjellmanESOHelper

local STARTER_SETS = {
    "Briarheart", "Sergeant's Mail", "Mother's Sorrow",
    "Pillar of Nirn", "Burning Spellweave", "Hunding's Rage",
    "Order's Wrath",
}

local function ContainsId(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local function AddLocationText(places, location)
    if not location then return end
    if location.bank and location.bank > 0 then
        table.insert(places, string.format("Bank x%d", location.bank))
    end
    for _, character in ipairs(location.characters or {}) do
        local details = {}
        if character.worn > 0 then table.insert(details, "equipped") end
        if character.backpack > 0 then
            table.insert(details, string.format("bag x%d", character.backpack))
        end
        table.insert(places, string.format("%s (%s)", character.name,
            table.concat(details, ", ")))
    end
end

local DETAIL_FILTERS = {
    { key="all", label="ALL", width=70 },
    { key="light", label="LIGHT ARMOR", width=140 },
    { key="medium", label="MEDIUM ARMOR", width=155 },
    { key="heavy", label="HEAVY ARMOR", width=145 },
    { key="weapons", label="WEAPONS", width=125 },
    { key="jewelry", label="JEWELRY", width=120 },
}

local function GetDetailFilterLabel(filterKey)
    for _, filter in ipairs(DETAIL_FILTERS) do
        if filter.key == filterKey then return filter.label end
    end
    return "ALL"
end

local function GetDetailPieceCategory(piece)
    local link = piece and piece.link
    if link and link ~= "" then
        local weaponType = GetItemLinkWeaponType(link)
        if weaponType and weaponType ~= WEAPONTYPE_NONE then return "weapons" end
        local equipType = GetItemLinkEquipType(link)
        if equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK then
            return "jewelry"
        end
        local armorType = GetItemLinkArmorType(link)
        if armorType == ARMORTYPE_LIGHT then return "light" end
        if armorType == ARMORTYPE_MEDIUM then return "medium" end
        if armorType == ARMORTYPE_HEAVY then return "heavy" end
    end
    local key = piece and piece.key or ""
    if key:match("^w:") then return "weapons" end
    local equipType = tonumber(key:match("^e:(%d+)"))
    if equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK then
        return "jewelry"
    end
    local armorType = tonumber(key:match(":a:(%d+)$"))
    if armorType == ARMORTYPE_LIGHT then return "light" end
    if armorType == ARMORTYPE_MEDIUM then return "medium" end
    if armorType == ARMORTYPE_HEAVY then return "heavy" end
    return "other"
end

function KPH:SeedSetTracker()
    local saved = self.savedVariables
    saved.trackedSetIds = saved.trackedSetIds or {}
    if (saved.setTrackerSeedVersion or 0) >= 1 then return end
    if saved.plannedSetId and saved.plannedSetId > 0 and
       not ContainsId(saved.trackedSetIds, saved.plannedSetId) then
        table.insert(saved.trackedSetIds, saved.plannedSetId)
    end
    for _, setName in ipairs(STARTER_SETS) do
        for _, match in ipairs(self:GetBuildSetMatches(setName)) do
            if zo_strlower(match.name) == zo_strlower(setName) and
               not ContainsId(saved.trackedSetIds, match.id) then
                table.insert(saved.trackedSetIds, match.id)
                break
            end
        end
    end
    saved.setTrackerSeeded = true
    saved.setTrackerSeedVersion = 1
end

function KPH:AddSetTrackerSet(setId, openDetails)
    setId = self:CanonicalizeSetId(setId)
    if not setId or setId <= 0 or not GetItemSetName(setId) then return false end
    local tracked = self.savedVariables.trackedSetIds
    if not ContainsId(tracked, setId) then
        table.insert(tracked, setId)
    end
    self.savedVariables.plannedSetId = setId
    self.selectedTrackedSetId = setId
    if self.itemFinderWindow and not self.itemFinderWindow:IsHidden() then
        self.setTrackerReturnToItemFinder = true
        if self.itemFinderEdit then self.itemFinderEdit:LoseFocus() end
        self.itemFinderWindow:SetHidden(true)
    end
    self:CreateSetPlannerWindow()
    self:RefreshSetPlanner()
    self.setPlannerWindow:SetHidden(false)
    SCENE_MANAGER:SetInUIMode(true)
    if openDetails ~= false then self:SelectSetTrackerTab("details") end
    d(string.format("[KEH] Set Tracker: %s added.",
        zo_strformat("<<C:1>>", GetItemSetName(setId))))
    return true
end

function KPH:RemoveSelectedTrackedSet()
    local setId = self.selectedTrackedSetId
    if not setId then return end
    for index, value in ipairs(self.savedVariables.trackedSetIds or {}) do
        if value == setId then table.remove(self.savedVariables.trackedSetIds, index) break end
    end
    self.selectedTrackedSetId = nil
    self:SelectSetTrackerTab("list")
end

function KPH:BuildSetTrackerDetails(setId)
    if not setId then return "|cE89B35Select a set from MY SETS.|r" end
    setId = self:CanonicalizeSetId(setId)
    self.selectedTrackedSetId = setId
    local view = self:GetSetTrackerViewModel(setId)
    local setName = zo_strformat("<<C:1>>", view.name or "Unknown set")
    local lines = {
        string.format("|cFFFFFF%s|r", setName),
        string.format("|cAAAAAA%s|r", self:GetSetCollectionLocation(setId)),
        string.format("|c66CC66Physical: %d|r   |cE89B35Stickerbook: %d|r   |cAAAAAATotal types: %d|r",
            view.physical, view.collected, view.total), "",
    }
    local representative = view.rows[1] and
        (view.rows[1].definition.link or
            (view.rows[1].location and view.rows[1].location.link))
    if representative and representative ~= "" and
       type(GetItemLinkSetBonusInfo) == "function" then
        local _, _, numBonuses = GetItemLinkSetInfo(representative, false)
        table.insert(lines, "|cD6B35ASET BONUSES|r")
        for bonusIndex = 1, numBonuses or 0 do
            local required, description = GetItemLinkSetBonusInfo(
                representative, false, bonusIndex)
            if description and description ~= "" then
                table.insert(lines, string.format("|cAAAAAA%d items:|r %s",
                    required or 0, zo_strformat("<<C:1>>", description)))
            end
        end
        table.insert(lines, "")
    end
    local activeFilter = self.setTrackerDetailFilter or "all"
    local filterLabel = GetDetailFilterLabel(activeFilter)
    table.insert(lines, string.format("|cD6B35APIECES AND LOCATIONS — %s|r",
        filterLabel))
    local visibleRows = 0
    for rowIndex = 1, math.max(view.total or 0, #(view.rows or {})) do
        local row = view.rows and view.rows[rowIndex]
        local category = row and row.definition and
            GetDetailPieceCategory(row.definition) or "other"
        if row and row.definition and
           (activeFilter == "all" or category == activeFilter) then
            visibleRows = visibleRows + 1
            local piece, location = row.definition, row.location
            local places = {}
            AddLocationText(places, location)
            if row.stickerbook then
                table.insert(places, "Stickerbook / transmute")
            end
            local isOwned = #places > 0
            local status = isOwned and "|c66CC66[OWNED]|r" or
                "|cE05A5A[MISSING]|r"
            local pieceName = piece.name or
                (piece.link and zo_strformat("<<C:1>>", GetItemLinkName(piece.link))) or
                string.format("Piece %d", rowIndex)
            local placeText = isOwned and table.concat(places, "; ") or
                (piece.link and self:GetSetPieceSource(setId, piece.link) or
                    "Missing — craft at the set's crafting station")
            table.insert(lines, string.format(
                "%s |cFFFFFF%s|r  |cAAAAAA— %s|r", status, pieceName, placeText))
        elseif not row and activeFilter == "all" then
            visibleRows = visibleRows + 1
            table.insert(lines, string.format(
                "|cE05A5A[MISSING]|r |cFFFFFFPiece %d|r  |cAAAAAA— Piece data unavailable|r",
                rowIndex))
        end
    end
    if visibleRows == 0 then
        table.insert(lines, "|cAAAAAANo pieces in this category.|r")
    end
    table.insert(lines, "")
    table.insert(lines,
        "|c777777Alt locations are cached after each character logs in with this version.|r")
    return table.concat(lines, "\n")
end

function KPH:SelectSetTrackerDetailFilter(filterKey)
    self.setTrackerDetailFilter = filterKey or "all"
    for key, button in pairs(self.setPlannerDetailFilterButtons or {}) do
        local active = key == self.setTrackerDetailFilter
        button:SetNormalFontColor(active and 1 or 0.65,
            active and 0.85 or 0.65, active and 0.35 or 0.65, 1)
    end
    if self.setPlannerText then
        self.setPlannerText:SetText(self:BuildSetTrackerDetails(
            self.selectedTrackedSetId))
        self.setPlannerDetailsChild:SetHeight(math.max(620,
            self.setPlannerText:GetTextHeight() + 20))
    end
end

function KPH:RefreshSetTrackerList()
    if not self.setPlannerListButtons then return end
    local query = self.setPlannerSearchEdit and
        zo_strlower(zo_strtrim(self.setPlannerSearchEdit:GetText() or "")) or ""
    local visible = {}
    for _, setId in ipairs(self.savedVariables.trackedSetIds or {}) do
        local name = zo_strformat("<<C:1>>", GetItemSetName(setId) or "")
        if query == "" or string.find(zo_strlower(name), query, 1, true) then
            table.insert(visible, { id=setId, name=name })
        end
    end
    self:EnsureSetTrackerListButtons(#visible)
    for index, button in ipairs(self.setPlannerListButtons) do
        local entry = visible[index]
        if entry then
            local color, status, stats = self:SetTrackerStatus(entry.id)
            button.kehSetId = entry.id
            button:SetText(string.format("|c%s%s|r  |cAAAAAA%s — %d/%d parts|r",
                color, entry.name, status, stats.owned, stats.total))
            button:SetHidden(false)
        else
            button.kehSetId = nil
            button:SetHidden(true)
        end
    end
    self.setPlannerListChild:SetHeight(math.max(#visible, 1) * 42)
    if self.setPlannerListCounter then
        self.setPlannerListCounter:SetText(string.format("SHOWING %d / %d SETS",
            #visible, #(self.savedVariables.trackedSetIds or {})))
    end
end

function KPH:SelectSetTrackerTab(tab)
    self.setTrackerTab = tab
    if not self.setPlannerListPanel then return end
    self.setPlannerListPanel:SetHidden(tab ~= "list")
    self.setPlannerDetailsPanel:SetHidden(tab ~= "details")
    self.setPlannerListTab:SetNormalFontColor(tab == "list" and 1 or 0.7,
        tab == "list" and 0.85 or 0.7, tab == "list" and 0.35 or 0.7, 1)
    self.setPlannerDetailsTab:SetNormalFontColor(tab == "details" and 1 or 0.7,
        tab == "details" and 0.85 or 0.7, tab == "details" and 0.35 or 0.7, 1)
    self:RefreshSetPlanner()
end

function KPH:CreateSetPlannerWindow()
    if self.setPlannerWindow then return end
    local window = WINDOW_MANAGER:CreateTopLevelWindow(self.name .. "SetPlanner")
    window:SetDimensions(math.min(1040, GuiRoot:GetWidth() - 40),
        math.min(780, GuiRoot:GetHeight() - 40))
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
    title:SetText("KEH Set Tracker")
    local close = WINDOW_MANAGER:CreateControlFromVirtual(nil, window, "ZO_CloseButton")
    close:SetAnchor(TOPRIGHT, window, TOPRIGHT, -8, 8)
    close:SetHandler("OnClicked", function()
        window:SetHidden(true)
        if self.setTrackerReturnToItemFinder then
            self.setTrackerReturnToItemFinder = false
            self:ShowItemFinder()
        else
            SCENE_MANAGER:SetInUIMode(false)
        end
    end)
    local refresh = WINDOW_MANAGER:CreateControl(nil, window, CT_BUTTON)
    refresh:SetDimensions(190, 34)
    refresh:SetAnchor(TOPRIGHT, window, TOPRIGHT, -54, 18)
    refresh:SetFont("ZoFontGameBold")
    refresh:SetText("REFRESH SETS")
    refresh:SetNormalFontColor(0.45, 0.85, 1, 1)
    refresh:SetMouseOverFontColor(1, 1, 1, 1)
    refresh:SetHandler("OnClicked", function()
        self:RefreshSetPlanner()
        d("[KEH] Set ownership refreshed.")
    end)
    local listTab = WINDOW_MANAGER:CreateControl(nil, window, CT_BUTTON)
    listTab:SetDimensions(170, 36)
    listTab:SetAnchor(TOPLEFT, window, TOPLEFT, 50, 58)
    listTab:SetFont("ZoFontGameBold")
    listTab:SetText("MY SETS")
    local detailsTab = WINDOW_MANAGER:CreateControl(nil, window, CT_BUTTON)
    detailsTab:SetDimensions(170, 36)
    detailsTab:SetAnchor(LEFT, listTab, RIGHT, 16, 0)
    detailsTab:SetFont("ZoFontGameBold")
    detailsTab:SetText("DETAILS")

    local listPanel = WINDOW_MANAGER:CreateControl(nil, window, CT_CONTROL)
    listPanel:SetAnchor(TOPLEFT, window, TOPLEFT, 24, 104)
    listPanel:SetAnchor(BOTTOMRIGHT, window, BOTTOMRIGHT, -24, -24)
    local help = WINDOW_MANAGER:CreateControl(nil, listPanel, CT_LABEL)
    help:SetAnchor(TOPLEFT, listPanel, TOPLEFT, 8, 0)
    help:SetFont("ZoFontGame")
    help:SetText("Filter tracked sets by name:")
    local searchBG = WINDOW_MANAGER:CreateControl(nil, listPanel, CT_BACKDROP)
    searchBG:SetDimensions(520, 38)
    searchBG:SetAnchor(TOPLEFT, listPanel, TOPLEFT, 8, 34)
    searchBG:SetCenterColor(0, 0, 0, 0.9)
    searchBG:SetEdgeColor(0.7, 0.65, 0.45, 1)
    local searchEdit = WINDOW_MANAGER:CreateControl(
        self.name .. "SetTrackerSearch", searchBG, CT_EDITBOX)
    searchEdit:SetAnchor(TOPLEFT, searchBG, TOPLEFT, 10, 4)
    searchEdit:SetDimensions(500, 30)
    searchEdit:SetFont("ZoFontGame")
    searchEdit:SetColor(1, 1, 1, 1)
    searchEdit:SetMaxInputChars(100)
    searchEdit:SetMouseEnabled(true)
    searchEdit:SetEditEnabled(true)
    searchEdit:SetHandler("OnMouseDown", function(control) control:TakeFocus() end)
    searchEdit:SetHandler("OnTextChanged", function()
        self:RefreshSetTrackerList()
    end)
    local counter = WINDOW_MANAGER:CreateControl(nil, listPanel, CT_LABEL)
    counter:SetDimensions(370, 30)
    counter:SetAnchor(TOPRIGHT, listPanel, TOPRIGHT, -8, 40)
    counter:SetFont("ZoFontGameBold")
    counter:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    counter:SetColor(0.75, 0.75, 0.75, 1)
    local listScroll = WINDOW_MANAGER:CreateControlFromVirtual(
        self.name .. "SetTrackerListScroll", listPanel, "ZO_ScrollContainer")
    listScroll:SetAnchor(TOPLEFT, listPanel, TOPLEFT, 8, 82)
    listScroll:SetAnchor(BOTTOMRIGHT, listPanel, BOTTOMRIGHT, -8, -8)
    local listChild = GetControl(listScroll, "ScrollChild")
    listChild:SetWidth(940)
    local listButtons = {}
    for index = 1, 80 do
        local button = WINDOW_MANAGER:CreateControl(
            self.name .. "TrackedSet" .. index, listChild, CT_BUTTON)
        button:SetDimensions(940, 40)
        button:SetAnchor(TOPLEFT, listChild, TOPLEFT, 0, (index - 1) * 42)
        button:SetFont("ZoFontGame")
        button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        button:SetHandler("OnClicked", function(control)
            self.selectedTrackedSetId = control.kehSetId
            self.savedVariables.plannedSetId = control.kehSetId
            self:SelectSetTrackerTab("details")
        end)
        button:SetHidden(true)
        listButtons[index] = button
    end
    listChild:SetHeight(80 * 42)
    local detailsPanel = WINDOW_MANAGER:CreateControl(nil, window, CT_CONTROL)
    detailsPanel:SetAnchor(TOPLEFT, window, TOPLEFT, 24, 104)
    detailsPanel:SetAnchor(BOTTOMRIGHT, window, BOTTOMRIGHT, -24, -24)
    local remove = WINDOW_MANAGER:CreateControl(nil, detailsPanel, CT_BUTTON)
    remove:SetDimensions(180, 34)
    remove:SetAnchor(TOPRIGHT, detailsPanel, TOPRIGHT, -8, 0)
    remove:SetFont("ZoFontGameBold")
    remove:SetText("REMOVE FROM LIST")
    remove:SetNormalFontColor(0.9, 0.35, 0.35, 1)
    remove:SetHandler("OnClicked", function() self:RemoveSelectedTrackedSet() end)
    local detailFilterButtons = {}
    local detailFilterX = 8
    for index, filter in ipairs(DETAIL_FILTERS) do
        local filterKey = filter.key
        local button = WINDOW_MANAGER:CreateControl(
            self.name .. "SetDetailFilter" .. index, detailsPanel, CT_BUTTON)
        button:SetDimensions(filter.width, 32)
        button:SetAnchor(TOPLEFT, detailsPanel, TOPLEFT, detailFilterX, 40)
        button:SetFont("ZoFontGameBold")
        button:SetText(filter.label)
        button:SetHandler("OnClicked", function()
            self:SelectSetTrackerDetailFilter(filterKey)
        end)
        detailFilterButtons[filterKey] = button
        detailFilterX = detailFilterX + filter.width + 8
    end
    local scroll = WINDOW_MANAGER:CreateControlFromVirtual(
        self.name .. "SetTrackerScroll", detailsPanel, "ZO_ScrollContainer")
    scroll:SetAnchor(TOPLEFT, detailsPanel, TOPLEFT, 8, 80)
    scroll:SetAnchor(BOTTOMRIGHT, detailsPanel, BOTTOMRIGHT, -8, -8)
    local child = GetControl(scroll, "ScrollChild")
    local text = WINDOW_MANAGER:CreateControl(nil, child, CT_LABEL)
    text:SetAnchor(TOPLEFT, child, TOPLEFT, 0, 0)
    text:SetWidth(920)
    text:SetFont("ZoFontGameSmall")
    text:SetVerticalAlignment(TEXT_ALIGN_TOP)
    text:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    listTab:SetHandler("OnClicked", function() self:SelectSetTrackerTab("list") end)
    detailsTab:SetHandler("OnClicked", function() self:SelectSetTrackerTab("details") end)
    self.setPlannerWindow, self.setPlannerListPanel = window, listPanel
    self.setPlannerDetailsPanel = detailsPanel
    self.setPlannerListTab, self.setPlannerDetailsTab = listTab, detailsTab
    self.setPlannerListButtons, self.setPlannerDetailsChild = listButtons, child
    self.setPlannerListChild = listChild
    self.setPlannerSearchEdit = searchEdit
    self.setPlannerListCounter = counter
    self.setPlannerText = text
    self.setPlannerRefreshButton = refresh
    self.setPlannerDetailFilterButtons = detailFilterButtons
    self.setTrackerDetailFilter = self.setTrackerDetailFilter or "all"
    self:SelectSetTrackerDetailFilter(self.setTrackerDetailFilter)
    self:SelectSetTrackerTab("list")
end

function KPH:EnsureSetTrackerListButtons(count)
    local buttons = self.setPlannerListButtons
    local child = self.setPlannerListChild
    if not buttons or not child then return end
    for index = #buttons + 1, count do
        local button = WINDOW_MANAGER:CreateControl(
            self.name .. "TrackedSet" .. index, child, CT_BUTTON)
        button:SetDimensions(940, 40)
        button:SetAnchor(TOPLEFT, child, TOPLEFT, 0, (index - 1) * 42)
        button:SetFont("ZoFontGame")
        button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        button:SetHandler("OnClicked", function(control)
            self.selectedTrackedSetId = control.kehSetId
            self.savedVariables.plannedSetId = control.kehSetId
            self:SelectSetTrackerTab("details")
        end)
        button:SetHidden(true)
        buttons[index] = button
    end
    child:SetHeight(math.max(count, 1) * 42)
end

function KPH:SelectPlannedSetId(setId)
    return self:AddSetTrackerSet(setId, true)
end

function KPH:SelectPlannedSet(itemLink)
    if type(itemLink) ~= "string" or not string.find(itemLink, "|H", 1, true) then
        return false
    end
    local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(itemLink, false)
    return hasSet and self:SelectPlannedSetId(setId) or false
end

function KPH:FindPlannedSetByName(searchText)
    local matches = self:GetBuildSetMatches(searchText)
    if matches[1] and (matches[1].exact or #matches == 1) then
        return self:SelectPlannedSetId(matches[1].id)
    end
    d(#matches > 1 and "[KEH] Multiple sets match. Use a more exact name." or
        "[KEH] No matching set found.")
    return false
end

function KPH:ShowPlannerPieceFound(itemLink)
    local message = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(
        CSA_CATEGORY_SMALL_TEXT, SOUNDS.QUEST_OBJECTIVE_INCREMENT)
    message:SetText(string.format("KEH Set Tracker: %s found!",
        zo_strformat("<<C:1>>", GetItemLinkName(itemLink))))
    message:MarkSuppressIconFrame()
    message:MarkShowImmediately()
    CENTER_SCREEN_ANNOUNCE:QueueMessage(message)
end

function KPH:CheckPlannerInventoryItem(bagId, slotIndex, isNewItem, stackCountChange)
    if not self.savedVariables or not self.savedVariables.plannerNotifications or
       bagId ~= BAG_BACKPACK or (not isNewItem and (stackCountChange or 0) <= 0) then
        return
    end
    local link = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
    if not link or link == "" then return end
    local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(link, false)
    setId = self:CanonicalizeSetId(setId)
    if hasSet and ContainsId(self.savedVariables.trackedSetIds, setId) then
        self:ShowPlannerPieceFound(link)
    end
end

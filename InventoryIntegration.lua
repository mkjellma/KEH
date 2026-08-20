local KPH = KjellmanESOHelper

local ARMORY_FILTER_ALL = 1
local ARMORY_FILTER_ONLY = 2
local ARMORY_FILTER_EXCLUDE = 3

local ARMORY_FILTER_LABELS = {
    [ARMORY_FILTER_ALL] = "All",
    [ARMORY_FILTER_ONLY] = "Armory",
    [ARMORY_FILTER_EXCLUDE] = "Not Armory",
}

local LOCK_FILTER_ALL = 1
local LOCK_FILTER_ONLY = 2
local LOCK_FILTER_EXCLUDE = 3

local LOCK_FILTER_LABELS = {
    [LOCK_FILTER_ALL] = "All",
    [LOCK_FILTER_ONLY] = "Locked",
    [LOCK_FILTER_EXCLUDE] = "Unlocked",
}

function KPH:IsArmoryItem(slotData)
    if not slotData then return false end
    if slotData.isInArmory ~= nil then return slotData.isInArmory end
    if slotData.bagId == nil or slotData.slotIndex == nil then return false end
    return IsItemInArmory(slotData.bagId, slotData.slotIndex)
end

function KPH:DoesSlotPassArmoryFilter(inventory, slotData)
    if not PLAYER_INVENTORY then
        return true
    end
    local backpack=PLAYER_INVENTORY.inventories[INVENTORY_BACKPACK]
    local bank=PLAYER_INVENTORY.inventories[INVENTORY_BANK]
    if inventory~=backpack and inventory~=bank then return true end
    local mode = self.armoryFilterMode or ARMORY_FILTER_ALL
    if mode ~= ARMORY_FILTER_ALL then
        local isArmoryItem = self:IsArmoryItem(slotData)
        if mode == ARMORY_FILTER_ONLY and not isArmoryItem then return false end
        if mode == ARMORY_FILTER_EXCLUDE and isArmoryItem then return false end
    end

    local lockMode = self.lockFilterMode or LOCK_FILTER_ALL
    if lockMode ~= LOCK_FILTER_ALL then
        local isLocked = slotData.isPlayerLocked
        if isLocked == nil and slotData.bagId ~= nil and slotData.slotIndex ~= nil then
            isLocked = IsItemPlayerLocked(slotData.bagId, slotData.slotIndex)
        end
        if lockMode == LOCK_FILTER_ONLY and isLocked ~= true then return false end
        if lockMode == LOCK_FILTER_EXCLUDE and isLocked == true then return false end
    end
    return self:DoesSlotPassSmartFilters(slotData)
end

function KPH:UpdateArmoryFilterButton()
    if not self.armoryFilterButton then return end
    local mode = self.armoryFilterMode or ARMORY_FILTER_ALL
    self.armoryFilterButton:SetText("KEH: " .. ARMORY_FILTER_LABELS[mode])
end

function KPH:SetArmoryFilterMode(mode)
    mode = tonumber(mode) or ARMORY_FILTER_ALL
    if mode < ARMORY_FILTER_ALL or mode > ARMORY_FILTER_EXCLUDE then
        mode = ARMORY_FILTER_ALL
    end
    self.armoryFilterMode = mode
    self:UpdateArmoryFilterButton()
    if PLAYER_INVENTORY then
        PLAYER_INVENTORY:UpdateList(INVENTORY_BACKPACK, true)
    end
end

function KPH:CycleArmoryFilter()
    local mode = (self.armoryFilterMode or ARMORY_FILTER_ALL) + 1
    if mode > ARMORY_FILTER_EXCLUDE then mode = ARMORY_FILTER_ALL end
    self:SetArmoryFilterMode(mode)
end

function KPH:UpdateLockFilterButton()
    if not self.lockFilterButton then return end
    local mode = self.lockFilterMode or LOCK_FILTER_ALL
    self.lockFilterButton:SetText("KEH: " .. LOCK_FILTER_LABELS[mode])
end

function KPH:SetLockFilterMode(mode)
    mode = tonumber(mode) or LOCK_FILTER_ALL
    if mode < LOCK_FILTER_ALL or mode > LOCK_FILTER_EXCLUDE then
        mode = LOCK_FILTER_ALL
    end
    self.lockFilterMode = mode
    self:UpdateLockFilterButton()
    if PLAYER_INVENTORY then
        PLAYER_INVENTORY:UpdateList(INVENTORY_BACKPACK, true)
    end
end

function KPH:CycleLockFilter()
    local mode = (self.lockFilterMode or LOCK_FILTER_ALL) + 1
    if mode > LOCK_FILTER_EXCLUDE then mode = LOCK_FILTER_ALL end
    self:SetLockFilterMode(mode)
end

function KPH:CreateLegacyArmoryFilterButtons()
    if self.armoryFilterButton or not ZO_PlayerInventory then return end
    local button = WINDOW_MANAGER:CreateControlFromVirtual(
        self.name .. "ArmoryFilterButton", ZO_PlayerInventory, "ZO_DefaultButton")
    button:SetDimensions(120, 28)
    if ZO_PlayerInventoryTitle then
        button:SetAnchor(RIGHT, ZO_PlayerInventoryTitle, LEFT, -8, 0)
    elseif ZO_PlayerInventorySearchFiltersTextSearchBox then
        button:SetAnchor(RIGHT, ZO_PlayerInventorySearchFiltersTextSearchBox,
            LEFT, -174, -96)
    else
        button:SetAnchor(TOPLEFT, ZO_PlayerInventory, TOPLEFT, 170, 38)
    end
    button:SetHandler("OnClicked", function() self:CycleArmoryFilter() end)
    button:SetHandler("OnMouseEnter", function(control)
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -4)
        SetTooltipText(InformationTooltip,
            "Filter items used by a saved Armory build.")
    end)
    button:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)
    self.armoryFilterButton = button
    self:UpdateArmoryFilterButton()

    local lockButton = WINDOW_MANAGER:CreateControlFromVirtual(
        self.name .. "LockFilterButton", ZO_PlayerInventory, "ZO_DefaultButton")
    lockButton:SetDimensions(105, 28)
    lockButton:SetAnchor(RIGHT, button, LEFT, -6, 0)
    lockButton:SetHandler("OnClicked", function() self:CycleLockFilter() end)
    lockButton:SetHandler("OnMouseEnter", function(control)
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -4)
        SetTooltipText(InformationTooltip,
            "Filter items by ESO's player lock.")
    end)
    lockButton:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)
    self.lockFilterButton = lockButton
    self:UpdateLockFilterButton()
end

local SMART_FILTERS={
    {key="activeBuild",label="Active KEH Build"},
    {key="anyBuild",label="Any KEH Build"},
    {key="armory",label="Armory Items"},
    {key="setItem",label="Set Items"},
    {key="mythic",label="Mythics"},
    {key="locked",label="Locked"},
    {key="unlocked",label="Unlocked"},
    {key="research",label="Researchable Trait"},
    {key="intricate",label="Intricate"},
    {key="ornate",label="Ornate"},
    {key="valuable",label="TTC Value 10k+"},
    {key="duplicates",label="Duplicates"},
}

local SMART_FILTER_INCLUDE=1
local SMART_FILTER_EXCLUDE=-1

local function SmartFilterMode(value)
    -- Migrate the previous boolean checkbox format without losing selections.
    if value==true then return SMART_FILTER_INCLUDE end
    if value==SMART_FILTER_INCLUDE or value==SMART_FILTER_EXCLUDE then return value end
    return 0
end

local function InventoryIdentityKey(itemLink)
    local hasSet,_,_,_,_,setId=GetItemLinkSetInfo(itemLink,false)
    if hasSet then
        return string.format("s:%d:e:%d:w:%d:a:%d:t:%d",setId or 0,
            GetItemLinkEquipType(itemLink) or 0,
            GetItemLinkWeaponType(itemLink) or 0,
            GetItemLinkArmorType(itemLink) or 0,
            GetItemLinkTraitType(itemLink) or 0)
    end
    return "i:"..tostring(GetItemLinkItemId(itemLink) or 0)
end

function KPH:RebuildInventoryLocationCache()
    local cache={}
    local locations={
        {bag=BAG_BACKPACK,key="backpack"},
        {bag=BAG_BANK,key="bank"},
        {bag=BAG_SUBSCRIBER_BANK,key="bank"},
        {bag=BAG_WORN,key="worn"},
    }
    for _,location in ipairs(locations) do
        for slotIndex=0,GetBagSize(location.bag)-1 do
            local link=GetItemLink(location.bag,slotIndex,LINK_STYLE_DEFAULT)
            if link and link~="" then
                local key=InventoryIdentityKey(link)
                local counts=cache[key] or {backpack=0,bank=0,worn=0,total=0}
                counts[location.key]=counts[location.key]+1
                counts.total=counts.total+1
                cache[key]=counts
            end
        end
    end
    self.inventoryLocationCache=cache
    self.inventoryLocationCacheDirty=false
end

function KPH:GetInventoryLocationCounts(itemLink)
    if self.inventoryLocationCacheDirty or not self.inventoryLocationCache then
        self:RebuildInventoryLocationCache()
    end
    return self.inventoryLocationCache[InventoryIdentityKey(itemLink)] or
        {backpack=0,bank=0,worn=0,total=0}
end

local function ChoiceMatchesItem(choice,itemLink,exactTrait)
    local hasSet,_,_,_,_,setId=GetItemLinkSetInfo(itemLink,false)
    if not hasSet or choice.setId~=setId then return false end
    local itemWeapon=GetItemLinkWeaponType(itemLink)
    local choiceWeapon=choice.link and GetItemLinkWeaponType(choice.link) or
        choice.weaponType
    if choiceWeapon and choiceWeapon~=WEAPONTYPE_NONE and
       itemWeapon~=choiceWeapon then return false end
    local itemEquip=GetItemLinkEquipType(itemLink)
    local choiceEquip=choice.link and GetItemLinkEquipType(choice.link) or
        choice.equipType
    if choiceEquip and choiceEquip~=itemEquip then return false end
    local itemArmor=GetItemLinkArmorType(itemLink)
    local choiceArmor=choice.link and GetItemLinkArmorType(choice.link) or
        choice.armorType
    if choiceArmor and choiceArmor~=ARMORTYPE_NONE and
       itemArmor~=choiceArmor then return false end
    if exactTrait and choice.traitType and
       GetItemLinkTraitType(itemLink)~=choice.traitType then return false end
    return true
end

function KPH:GetBuildMatch(itemLink)
    local activeBase,activeExact,anyBase=false,false,false
    local plans=self.savedVariables.buildPlans or {}
    for name,build in pairs(plans) do
        for _,choice in pairs(build.slots or {}) do
            if ChoiceMatchesItem(choice,itemLink,false) then
                anyBase=true
                if name==self.savedVariables.activeBuildName then
                    activeBase=true
                    if ChoiceMatchesItem(choice,itemLink,true) then activeExact=true end
                end
            end
        end
    end
    return activeBase,activeExact,anyBase
end

function KPH:GetInventorySmartInfo(slotData)
    if not slotData or slotData.bagId==nil or slotData.slotIndex==nil then return {} end
    local link=GetItemLink(slotData.bagId,slotData.slotIndex,LINK_STYLE_DEFAULT)
    if not link or link=="" then return {} end
    local hasSet,_,_,_,_,setId=GetItemLinkSetInfo(link,false)
    local activeBuild,activeExact,anyBuild=self:GetBuildMatch(link)
    local trait=GetItemLinkTraitType(link)
    local intricate=trait==ITEM_TRAIT_TYPE_ARMOR_INTRICATE or
        trait==ITEM_TRAIT_TYPE_WEAPON_INTRICATE or
        trait==ITEM_TRAIT_TYPE_JEWELRY_INTRICATE
    local ornate=trait==ITEM_TRAIT_TYPE_ARMOR_ORNATE or
        trait==ITEM_TRAIT_TYPE_WEAPON_ORNATE or
        trait==ITEM_TRAIT_TYPE_JEWELRY_ORNATE
    local research=false
    if CanItemLinkBeTraitResearched then
        research=CanItemLinkBeTraitResearched(link)==true
    end
    local locked=slotData.isPlayerLocked
    if locked==nil then locked=IsItemPlayerLocked(slotData.bagId,slotData.slotIndex) end
    local armory=self:IsArmoryItem(slotData)
    local price=self:GetTTCSuggestedPrice(link)
    local counts=self:GetInventoryLocationCounts(link)
    return {
        link=link,hasSet=hasSet,setItem=hasSet,setId=setId,activeBuild=activeBuild,
        activeExact=activeExact,anyBuild=anyBuild,armory=armory,
        mythic=hasSet and ITEM_SET_TYPE_MYTHIC and
            GetItemSetType(setId)==ITEM_SET_TYPE_MYTHIC or false,
        locked=locked==true,unlocked=locked~=true,research=research,
        intricate=intricate,ornate=ornate,valuable=(price or 0)>=10000,
        duplicates=counts.total>1,counts=counts,
        protected=locked==true or armory or anyBuild,
    }
end

function KPH:DoesSlotPassSmartFilters(slotData)
    local preset=self.savedVariables.inventoryPreset or "all"
    local filters=self.savedVariables.inventorySmartFilters or {}
    local hasFilter=false
    for _,value in pairs(filters) do
        if SmartFilterMode(value)~=0 then hasFilter=true break end
    end
    if preset=="all" and not hasFilter then return true end
    local info=self:GetInventorySmartInfo(slotData)
    if preset=="keep" and not info.protected and not info.mythic then return false end
    if preset=="build" and not info.activeBuild then return false end
    if preset=="research" and not info.research then return false end
    if preset=="sell" and (info.protected or not (info.valuable or info.ornate)) then
        return false
    end
    if preset=="cleanup" and (info.protected or not
       (info.intricate or info.ornate or info.duplicates)) then return false end
    for _,definition in ipairs(SMART_FILTERS) do
        local mode=SmartFilterMode(filters[definition.key])
        if mode==SMART_FILTER_INCLUDE and not info[definition.key] then return false end
        if mode==SMART_FILTER_EXCLUDE and info[definition.key] then return false end
    end
    return true
end

function KPH:RefreshInventoryManagerLists()
    self.inventoryLocationCacheDirty=true
    if PLAYER_INVENTORY then
        PLAYER_INVENTORY:UpdateList(INVENTORY_BACKPACK,true)
        if PLAYER_INVENTORY.inventories[INVENTORY_BANK] then
            PLAYER_INVENTORY:UpdateList(INVENTORY_BANK,true)
        end
    end
end

function KPH:UpdateInventoryManagerPanel()
    if not self.inventoryManagerPresetButtons then return end
    local active=self.savedVariables.inventoryPreset or "all"
    for key,button in pairs(self.inventoryManagerPresetButtons) do
        button:SetText((active==key and "|c66CC66> " or "|cAAAAAA")..
            button.kehLabel.."|r")
    end
    local filters=self.savedVariables.inventorySmartFilters or {}
    for key,button in pairs(self.inventoryManagerFilterButtons or {}) do
        local mode=SmartFilterMode(filters[key])
        local marker=mode==SMART_FILTER_INCLUDE and "|c66CC66[+] " or
            (mode==SMART_FILTER_EXCLUDE and "|cE05A5A[-] " or "|c888888[ ] ")
        button:SetText(marker..button.kehLabel.."|r")
    end
end

function KPH:SetInventoryPreset(preset)
    self.savedVariables.inventoryPreset=preset
    self.savedVariables.inventorySmartFilters={}
    self:UpdateInventoryManagerPanel()
    self:RefreshInventoryManagerLists()
end

function KPH:ToggleInventorySmartFilter(key)
    self.savedVariables.inventoryPreset="all"
    local filters=self.savedVariables.inventorySmartFilters or {}
    self.savedVariables.inventorySmartFilters=filters
    local mode=SmartFilterMode(filters[key])
    if mode==0 then filters[key]=SMART_FILTER_INCLUDE
    elseif mode==SMART_FILTER_INCLUDE then filters[key]=SMART_FILTER_EXCLUDE
    else filters[key]=nil end
    self:UpdateInventoryManagerPanel()
    self:RefreshInventoryManagerLists()
end

function KPH:CreateInventoryManagerControls()
    if self.inventoryManagerButton or not ZO_PlayerInventory then return end
    local toggle=WINDOW_MANAGER:CreateControlFromVirtual(
        self.name.."InventoryManagerToggle",ZO_PlayerInventory,"ZO_DefaultButton")
    toggle:SetDimensions(155,30)
    toggle:SetAnchor(TOPLEFT,ZO_PlayerInventory,TOPLEFT,20,45)
    toggle:SetText("KEH Filters")
    toggle:SetHidden(true)
    local panel=WINDOW_MANAGER:CreateTopLevelWindow(
        self.name.."InventoryManagerPanel")
    panel:SetDimensions(370,530)
    if (self.savedVariables.inventoryManagerX or 0)>0 and
       (self.savedVariables.inventoryManagerY or 0)>0 then
        panel:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,
            self.savedVariables.inventoryManagerX,
            self.savedVariables.inventoryManagerY)
    else
        panel:SetAnchor(CENTER,GuiRoot,CENTER,0,0)
    end
    panel:SetMouseEnabled(true)
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:SetDrawTier(DT_HIGH)
    panel:SetDrawLayer(DL_OVERLAY)
    panel:SetDrawLevel(200)
    panel:SetHidden(true)
    panel:SetHandler("OnMoveStop",function(control)
        self.savedVariables.inventoryManagerX=control:GetLeft()
        self.savedVariables.inventoryManagerY=control:GetTop()
    end)
    local panelBG=WINDOW_MANAGER:CreateControl(
        self.name.."InventoryManagerPanelBG",panel,CT_BACKDROP)
    panelBG:SetAnchorFill(panel)
    panelBG:SetCenterTexture("EsoUI/Art/Tooltips/UI-TooltipCenter.dds")
    panelBG:SetEdgeTexture("EsoUI/Art/Tooltips/UI-Border.dds",128,16)
    panelBG:SetInsets(10,10,-10,-10)
    panelBG:SetMouseEnabled(false)
    local title=WINDOW_MANAGER:CreateControl(nil,panel,CT_LABEL)
    title:SetAnchor(TOPLEFT,panel,TOPLEFT,18,14)
    title:SetFont("ZoFontWinH2")
    title:SetText("KEH Inventory Manager")
    local close=WINDOW_MANAGER:CreateControl(nil,panel,CT_BUTTON)
    close:SetDimensions(32,32)
    close:SetAnchor(TOPRIGHT,panel,TOPRIGHT,-8,8)
    close:SetFont("ZoFontGameBold")
    close:SetText("X")
    close:SetNormalFontColor(1,0.4,0.3,1)
    close:SetHandler("OnClicked",function() panel:SetHidden(true) end)
    local presetLabel=WINDOW_MANAGER:CreateControl(nil,panel,CT_LABEL)
    presetLabel:SetAnchor(TOPLEFT,panel,TOPLEFT,18,52)
    presetLabel:SetFont("ZoFontGameBold")
    presetLabel:SetText("PRESETS")
    local presets={
        {key="all",label="All Items"},{key="keep",label="Keep / Protected"},
        {key="build",label="Active Build"},{key="research",label="Research"},
        {key="sell",label="Sell"},{key="cleanup",label="Cleanup"},
    }
    self.inventoryManagerPresetButtons={}
    for index,definition in ipairs(presets) do
        local presetKey=definition.key
        local button=WINDOW_MANAGER:CreateControl(nil,panel,CT_BUTTON)
        button:SetDimensions(330,24)
        button:SetAnchor(TOPLEFT,panel,TOPLEFT,20,72+(index-1)*24)
        button:SetFont("ZoFontGameSmall")
        button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        button.kehLabel=definition.label
        button:SetHandler("OnClicked",function()
            self:SetInventoryPreset(presetKey)
        end)
        self.inventoryManagerPresetButtons[presetKey]=button
    end
    local filterLabel=WINDOW_MANAGER:CreateControl(nil,panel,CT_LABEL)
    filterLabel:SetAnchor(TOPLEFT,panel,TOPLEFT,18,222)
    filterLabel:SetFont("ZoFontGameBold")
    filterLabel:SetText("SMART FILTERS  [+ only / - exclude]")
    self.inventoryManagerFilterButtons={}
    for index,definition in ipairs(SMART_FILTERS) do
        local filterKey=definition.key
        local button=WINDOW_MANAGER:CreateControl(nil,panel,CT_BUTTON)
        button:SetDimensions(330,22)
        button:SetAnchor(TOPLEFT,panel,TOPLEFT,20,244+(index-1)*22)
        button:SetFont("ZoFontGameSmall")
        button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        button.kehLabel=definition.label
        button:SetHandler("OnClicked",function()
            self:ToggleInventorySmartFilter(filterKey)
        end)
        self.inventoryManagerFilterButtons[filterKey]=button
    end
    toggle:SetHandler("OnClicked",function()
        panel:SetHidden(not panel:IsHidden())
        self:UpdateInventoryManagerPanel()
    end)
    if ZO_PlayerBank then
        local bankToggle=WINDOW_MANAGER:CreateControlFromVirtual(
            self.name.."BankInventoryManagerToggle",ZO_PlayerBank,"ZO_DefaultButton")
        bankToggle:SetDimensions(155,30)
        bankToggle:SetAnchor(TOPLEFT,ZO_PlayerBank,TOPLEFT,20,45)
        bankToggle:SetText("KEH Filters")
        bankToggle:SetHidden(true)
        bankToggle:SetHandler("OnClicked",function()
            panel:SetHidden(not panel:IsHidden())
            self:UpdateInventoryManagerPanel()
        end)
        self.bankInventoryManagerButton=bankToggle
    end
    self.inventoryManagerButton=toggle
    self.inventoryManagerPanel=panel
    self:UpdateInventoryManagerPanel()
end

function KPH:ToggleInventoryManagerPanel()
    if not self.inventoryManagerPanel then self:CreateInventoryManagerControls() end
    if not self.inventoryManagerPanel then return end
    self.inventoryManagerPanel:SetHidden(not self.inventoryManagerPanel:IsHidden())
    self:UpdateInventoryManagerPanel()
end

function KPH:CreateArmoryFilterButton()
    self:CreateInventoryManagerControls()
end

function KPH:ProtectArmoryItem(bagId, slotIndex)
    if not self.savedVariables or not self.savedVariables.protectArmoryItems then
        return false
    end
    if bagId == nil or slotIndex == nil or not IsItemInArmory(bagId, slotIndex) then
        return false
    end
    if IsItemPlayerLocked(bagId, slotIndex) or
       not CanItemBePlayerLocked(bagId, slotIndex) then
        return false
    end
    SetItemIsPlayerLocked(bagId, slotIndex, true)
    return true
end

function KPH:ProtectAllArmoryItems()
    if not self.savedVariables or not self.savedVariables.protectArmoryItems then return end
    local bags = { BAG_BACKPACK, BAG_WORN, BAG_BANK, BAG_SUBSCRIBER_BANK }
    for _, bagId in ipairs(bags) do
        local bagSize = GetBagSize(bagId)
        for slotIndex = 0, bagSize - 1 do
            self:ProtectArmoryItem(bagId, slotIndex)
        end
    end
    if PLAYER_INVENTORY then
        PLAYER_INVENTORY:RefreshAllInventoryOverlays(INVENTORY_BACKPACK)
    end
end

function KPH:NotifyValuableInventoryItem(bagId,slotIndex,isNewItem,
                                          stackCountChange)
    if not self.savedVariables.notifyValuableItems or bagId~=BAG_BACKPACK then return end
    if not isNewItem and (stackCountChange or 0)<=0 then return end
    if GetInteractionType and INTERACTION_BANK and
       GetInteractionType()==INTERACTION_BANK then return end
    local itemLink=GetItemLink(bagId,slotIndex,LINK_STYLE_DEFAULT)
    if not itemLink or itemLink=="" then return end
    local unitPrice=self:GetTTCSuggestedPrice(itemLink)
    if not unitPrice then return end
    local quantity=(stackCountChange and stackCountChange>0) and
        stackCountChange or GetSlotStackSize(bagId,slotIndex)
    quantity=math.max(1,quantity or 1)
    local totalValue=unitPrice*quantity
    local threshold=self.savedVariables.valuableItemThreshold or 10000
    if totalValue<threshold then return end
    local notificationKey=string.format("%d:%d:%s",bagId,slotIndex,itemLink)
    local now=GetFrameTimeMilliseconds()
    self.valuableNotificationCooldown=self.valuableNotificationCooldown or {}
    if now-(self.valuableNotificationCooldown[notificationKey] or 0)<3000 then return end
    self.valuableNotificationCooldown[notificationKey]=now
    local itemName=zo_strformat("<<C:1>>",GetItemLinkName(itemLink))
    local valueText=self:FormatGold(totalValue).." g"
    if quantity>1 then
        valueText=valueText..string.format(" total (%d x %s g)",quantity,
            self:FormatGold(unitPrice))
    end
    local message=CENTER_SCREEN_ANNOUNCE:CreateMessageParams(
        CSA_CATEGORY_SMALL_TEXT,SOUNDS.QUEST_OBJECTIVE_INCREMENT)
    message:SetSound(SOUNDS.QUEST_OBJECTIVE_INCREMENT)
    message:SetText(string.format("KEH: Valuable item! %s — ~%s",
        itemName,valueText))
    message:MarkSuppressIconFrame()
    message:MarkShowImmediately()
    CENTER_SCREEN_ANNOUNCE:QueueMessage(message)
    d(string.format("[KEH] Valuable item: %s — estimated %s.",itemLink,valueText))
end

function KPH:AddSuggestedPriceToInventoryRow(rowControl, slotData)
    if not self.savedVariables.showInventorySuggestedPrice or
       IsInGamepadPreferredMode() or not rowControl or not slotData then
        return
    end

    local bagId = slotData.bagId
    local slotIndex = slotData.slotIndex
    if bagId == nil or slotIndex == nil then return end

    local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_DEFAULT)
    local suggestedPrice, confidence = self:GetTTCSuggestedPrice(itemLink)
    if not suggestedPrice then return end

    local sellPriceControl = rowControl:GetNamedChild("SellPrice")
    if not sellPriceControl then return end
    local sellPriceLabel = sellPriceControl:GetNamedChild("Text")
    if not sellPriceLabel then return end

    local currentText = sellPriceLabel:GetText() or ""
    local color = self:GetConfidenceColor(confidence)
    sellPriceLabel:SetText(string.format("|c%s(%s)|r %s", color,
        self:FormatGold(suggestedPrice), currentText))
end

function KPH:HookNotepadInventoryRow(rowControl,slotData)
    if not rowControl then return end
    local button=rowControl.kehNotepadButton
    if not button then
        button=WINDOW_MANAGER:CreateControl(nil,rowControl,CT_BUTTON)
        button:SetDimensions(28,28)
        button:SetAnchor(RIGHT,rowControl,RIGHT,-112,0)
        button:SetFont("ZoFontGameBold")
        button:SetText("+")
        button:SetNormalFontColor(0.35,0.85,1,0.8)
        button:SetMouseOverFontColor(1,1,1,1)
        button:SetHandler("OnClicked",function(control)
            local data=control.kehNotepadSlotData
            if data then self:AddItemToNotepad(data.bagId,data.slotIndex) end
        end)
        button:SetHandler("OnMouseEnter",function(control)
            InitializeTooltip(InformationTooltip,control,TOPRIGHT,0,0,TOPLEFT)
            SetTooltipText(InformationTooltip,"Add item to KEH Notepad")
        end)
        button:SetHandler("OnMouseExit",function() ClearTooltip(InformationTooltip) end)
        rowControl.kehNotepadButton=button
    end
    button.kehNotepadSlotData=slotData
end

function KPH:MarkArmoryInventoryRow(rowControl, slotData)
    if not rowControl or not slotData then return end
    local nameControl = rowControl:GetNamedChild("Name")
    if not nameControl then return end
    local info=self:GetInventorySmartInfo(slotData)
    if not info.link then return end
    local badges={}
    if info.activeBuild then
        table.insert(badges,info.activeExact and "|c66CC66[B]|r" or "|cE89B35[B]|r")
    elseif info.anyBuild then table.insert(badges,"|c66AADD[b]|r") end
    if info.armory then table.insert(badges,"|c66CC66[A]|r") end
    if info.mythic then table.insert(badges,"|cD6B35A[M]|r") end
    if info.research then table.insert(badges,"|c66AADD[R]|r") end
    if info.intricate then table.insert(badges,"|cB388FF[I]|r") end
    if info.valuable then table.insert(badges,"|cE8C35A[T]|r") end
    local currentText=nameControl:GetText() or ""
    local countText=""
    if info.counts and info.counts.total>1 then
        countText=string.format(" |c777777(P%d B%d W%d)|r",
            info.counts.backpack,info.counts.bank,info.counts.worn)
    end
    if #badges>0 or countText~="" then
        nameControl:SetText(table.concat(badges,"").." "..currentText..countText)
    end
end

function KPH:InstallInventoryHooks()
    if self.inventoryHooksInstalled or not PLAYER_INVENTORY or
       not PLAYER_INVENTORY.inventories then return end

    local hookedDataTypes = {}
    for _, inventory in pairs(PLAYER_INVENTORY.inventories) do
        local listView = inventory.listView
        local dataType = listView and listView.dataTypes and listView.dataTypes[1]
        if dataType and type(dataType.setupCallback) == "function" and
           not hookedDataTypes[dataType] then
            hookedDataTypes[dataType] = true
            local originalCallback = dataType.setupCallback
            dataType.setupCallback = function(rowControl, slotData, ...)
                originalCallback(rowControl, slotData, ...)
                self:HookNotepadInventoryRow(rowControl,slotData)
                self:MarkArmoryInventoryRow(rowControl, slotData)
                self:AddSuggestedPriceToInventoryRow(rowControl, slotData)
            end
        end
    end
    if not self.armoryFilterHookInstalled and
       type(PLAYER_INVENTORY.ShouldAddSlotToList) == "function" then
        local originalShouldAddSlotToList = PLAYER_INVENTORY.ShouldAddSlotToList
        PLAYER_INVENTORY.ShouldAddSlotToList = function(inventoryManager,
                                                         inventory, slotData)
            if not originalShouldAddSlotToList(inventoryManager,
                                                inventory, slotData) then
                return false
            end
            return self:DoesSlotPassArmoryFilter(inventory, slotData)
        end
        self.armoryFilterHookInstalled = true
    end
    self:CreateArmoryFilterButton()
    self.inventoryHooksInstalled = true
end

function KPH:InitializeInventoryIntegration()
    self.armoryFilterMode = ARMORY_FILTER_ALL
    self.lockFilterMode = LOCK_FILTER_ALL
    self.inventoryLocationCacheDirty=true
    SLASH_COMMANDS["/kehfilters"]=function() self:ToggleInventoryManagerPanel() end
    SLASH_COMMANDS["/keharmory"] = function()
        self:CycleArmoryFilter()
        d(string.format("[KEH] Inventory filter: %s",
            ARMORY_FILTER_LABELS[self.armoryFilterMode]))
    end
    SLASH_COMMANDS["/kehlock"] = function()
        self:CycleLockFilter()
        d(string.format("[KEH] Lock filter: %s",
            LOCK_FILTER_LABELS[self.lockFilterMode]))
    end
    EVENT_MANAGER:RegisterForEvent(self.name .. "ArmoryProtectionSlot",
        EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
        function(_,bagId,slotIndex,isNewItem,_,_,stackCountChange)
            self.inventoryLocationCacheDirty=true
            zo_callLater(function()
                self:NotifyValuableInventoryItem(
                    bagId,slotIndex,isNewItem,stackCountChange)
            end,50)
            zo_callLater(function()
                self:ProtectArmoryItem(bagId, slotIndex)
            end, 1)
        end)
    if EVENT_ARMORY_BUILD_UPDATED then
        EVENT_MANAGER:RegisterForEvent(self.name .. "ArmoryProtectionBuild",
            EVENT_ARMORY_BUILD_UPDATED, function()
                zo_callLater(function() self:ProtectAllArmoryItems() end, 50)
            end)
    end
    if EVENT_CLOSE_BANK then
        EVENT_MANAGER:RegisterForEvent(self.name.."InventoryManagerBankClose",
            EVENT_CLOSE_BANK,function()
                if self.inventoryManagerPanel then
                    self.inventoryManagerPanel:SetHidden(true)
                end
            end)
    end
    EVENT_MANAGER:RegisterForEvent(self.name .. "Inventory", EVENT_PLAYER_ACTIVATED,
        function()
            EVENT_MANAGER:UnregisterForEvent(self.name .. "Inventory", EVENT_PLAYER_ACTIVATED)
            zo_callLater(function()
                self:InstallInventoryHooks()
                self:ProtectAllArmoryItems()
            end, 0)
        end)
end

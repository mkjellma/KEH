KjellmanESOHelper = KjellmanESOHelper or {}
local KPH = KjellmanESOHelper

KPH.name = "KjellmanESOHelper"
KPH.displayName = "Kjellman ESO Helper"
KPH.version = "2.7.2"
KPH.DEBUG = false
KPH.defaults = {
    autoFill = true,
    useSuggestedPrice = true,
    priceFactor = 100,
    roundPrice = true,
    showInventorySuggestedPrice = true,
    protectArmoryItems = true,
    plannedSetId = 0,
    plannedMythicSetId = 0,
    plannerNotifications = true,
    buildPlans = {},
    activeBuildName = "Build 1",
    buildLauncherX = 20,
    buildLauncherY = 300,
    notepadText = "",
    notepadTabs = {},
    notepadActiveTab = "General",
    notepadX = 380,
    notepadY = 220,
    inventoryPreset = "all",
    inventorySmartFilters = {},
    inventoryManagerX = 0,
    inventoryManagerY = 0,
    goldmakerPlans = {},
    goldmakerFarmList = {},
    goldmakerX = 0,
    goldmakerY = 0,
    fishingBiteSound = true,
    fishingBiteIndicator = true,
    notifyValuableItems = true,
    valuableItemThreshold = 10000,
    showStoreSuggestedPrice = true,
    focusNewQuests = true,
    showTraderPriceComparison = true,
}

KPH.state = {
    currentItemLink = nil,
    currentStackCount = 0,
    lastAutoFilledPrice = nil,
    userHasEditedPrice = false,
    isApplyingAutomaticPrice = false,
    isSettingUpPendingPost = false,
}

function KPH:DebugLog(message)
    if self.DEBUG then
        d(string.format("[KEH] %s", tostring(message)))
    end
end

function KPH:RoundSuggestedPrice(price)
    if not price or price < 0 then return nil end
    local step = 1
    if price >= 100000 then
        step = 1000
    elseif price >= 10000 then
        step = 100
    elseif price >= 1000 then
        step = 10
    end
    return math.floor((price / step) + 0.5) * step
end

function KPH:FormatGold(value)
    value = math.floor((tonumber(value) or 0) + 0.5)
    local text = tostring(value)
    while true do
        local replaced, count = text:gsub("^(%-?%d+)(%d%d%d)", "%1 %2")
        text = replaced
        if count == 0 then break end
    end
    return text
end

function KPH:GetConfidenceColor(confidence)
    local colors = {
        high = "66CC66",
        medium = "E89B35",
        low = "E05A5A",
    }
    return colors[confidence] or colors.low
end

function KPH:GetSelectedItemLink()
    if not TRADING_HOUSE or not TRADING_HOUSE.pendingItemSlot then return nil end
    return GetItemLink(BAG_BACKPACK, TRADING_HOUSE.pendingItemSlot)
end

function KPH:Initialize()
    self.savedVariables = ZO_SavedVars:NewAccountWide(
        "KjellmanPriceHelperSavedVariables", 1, nil, self.defaults)
    self:InitializeGuildStoreIntegration()
    self:InitializeInventoryIntegration()
    self:InitializeStoreIntegration()
    self:InitializeQuestIntegration()
    self:InitializeDealIntegration()
    self:InitializeNotepad()
    self:InitializeGoldmaker()
    self:InitializeFishingIntegration()
    self:InitializeBuildPlanner()
    self:InitializeMythicHelper()
    self:InitializeSettings()

    local function ToggleDebug()
        self.DEBUG = not self.DEBUG
        d(string.format("[KEH] Debug %s.", self.DEBUG and "på" or "av"))
    end
    local function ShowSelectedPrice()
        local itemLink = self:GetSelectedItemLink()
        if not itemLink or itemLink == "" then
            d("[KEH] Ingen vara är vald i Guild Store.")
            return
        end
        local result, reason = self:GetTTCUnitPrice(itemLink)
        if result then
            d(string.format("[KEH] %s: %s g/st (%s)", itemLink,
                self:FormatGold(result.unitPrice), result.source))
        else
            d(string.format("[KEH] Pris saknas: %s", reason or "okänd orsak"))
        end
    end
    SLASH_COMMANDS["/kehdebug"] = ToggleDebug
    SLASH_COMMANDS["/kehprice"] = ShowSelectedPrice
    -- Gamla kommandon behålls för befintliga användare och instruktioner.
    SLASH_COMMANDS["/kphdebug"] = ToggleDebug
    SLASH_COMMANDS["/kphprice"] = ShowSelectedPrice
end

local function OnAddonLoaded(_, addonName)
    if addonName ~= KPH.name then return end
    EVENT_MANAGER:UnregisterForEvent(KPH.name, EVENT_ADD_ON_LOADED)
    KPH:Initialize()
end

EVENT_MANAGER:RegisterForEvent(KPH.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)

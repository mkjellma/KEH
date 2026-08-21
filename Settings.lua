local KPH = KjellmanESOHelper

function KPH:InitializeSettings()
    local LAM = LibAddonMenu2
    if not LAM then
        self:DebugLog("LibAddonMenu-2.0 is missing; default settings are used")
        return
    end

    local panel = LAM:RegisterAddonPanel(self.name .. "Options", {
        type = "panel",
        name = self.displayName,
        displayName = self.displayName,
        author = "Kjellman",
        version = self.version,
        registerForRefresh = true,
        registerForDefaults = true,
    })
    LAM:RegisterOptionControls(self.name .. "Options", {
        {
            type = "checkbox", name = "Enable automatic price fill",
            getFunc = function() return self.savedVariables.autoFill end,
            setFunc = function(value) self.savedVariables.autoFill = value end,
            default = self.defaults.autoFill,
        },
        {
            type = "checkbox", name = "Use TTC suggested price",
            tooltip = "If suggested price is unavailable, KEH calculates a conservative estimate from sales average, minimum, listing average and listing count.",
            getFunc = function() return self.savedVariables.useSuggestedPrice end,
            setFunc = function(value) self.savedVariables.useSuggestedPrice = value end,
            default = self.defaults.useSuggestedPrice,
        },
        {
            type = "slider", name = "Price factor (%)", min = 1, max = 200, step = 1,
            getFunc = function() return self.savedVariables.priceFactor end,
            setFunc = function(value) self.savedVariables.priceFactor = value end,
            default = self.defaults.priceFactor,
        },
        {
            type = "checkbox", name = "Round suggested price",
            getFunc = function() return self.savedVariables.roundPrice end,
            setFunc = function(value) self.savedVariables.roundPrice = value end,
            default = self.defaults.roundPrice,
        },
        {
            type = "checkbox", name = "Show TTC suggested price in inventory",
            tooltip = "Shows the suggested unit price before the normal price. Green is high confidence, orange is lower confidence and red is uncertain.",
            getFunc = function() return self.savedVariables.showInventorySuggestedPrice end,
            setFunc = function(value)
                self.savedVariables.showInventorySuggestedPrice = value
                if PLAYER_INVENTORY then PLAYER_INVENTORY:RefreshAllInventorySlots() end
            end,
            default = self.defaults.showInventorySuggestedPrice,
        },
        {
            type = "checkbox", name = "Notify about valuable items",
            tooltip = "Shows an on-screen notification and plays a sound when a new backpack item or stack is estimated by TTC to be worth at least the selected threshold.",
            getFunc = function() return self.savedVariables.notifyValuableItems end,
            setFunc = function(value)
                self.savedVariables.notifyValuableItems = value
            end,
            default = self.defaults.notifyValuableItems,
        },
        {
            type = "slider", name = "Valuable item threshold (gold)",
            min = 1000, max = 100000, step = 1000,
            getFunc = function()
                return self.savedVariables.valuableItemThreshold
            end,
            setFunc = function(value)
                self.savedVariables.valuableItemThreshold = value
            end,
            default = self.defaults.valuableItemThreshold,
        },
        {
            type = "checkbox", name = "Automatically protect Armory items",
            tooltip = "Locks items used by an Armory build with ESO's player lock. This prevents selling, deconstruction and destruction. Items already locked remain locked if this option is disabled.",
            getFunc = function() return self.savedVariables.protectArmoryItems end,
            setFunc = function(value)
                self.savedVariables.protectArmoryItems = value
                if value then self:ProtectAllArmoryItems() end
            end,
            default = self.defaults.protectArmoryItems,
        },
        {
            type = "checkbox", name = "Notify when a tracked set piece is found",
            tooltip = "Shows on-screen text and plays a sound when a tracked set piece enters your inventory.",
            getFunc = function() return self.savedVariables.plannerNotifications end,
            setFunc = function(value)
                self.savedVariables.plannerNotifications = value
            end,
            default = self.defaults.plannerNotifications,
        },
        {
            type = "checkbox", name = "Show suggested price in stores",
            tooltip = "Shows estimated unit market value before the cost in NPC and PvP stores. The store's actual price is not changed.",
            getFunc = function() return self.savedVariables.showStoreSuggestedPrice end,
            setFunc = function(value)
                self.savedVariables.showStoreSuggestedPrice = value
                if STORE_WINDOW and STORE_WINDOW.list then
                    ZO_ScrollList_RefreshVisible(STORE_WINDOW.list)
                end
            end,
            default = self.defaults.showStoreSuggestedPrice,
        },
        {
            type = "checkbox", name = "Automatically focus new quests",
            tooltip = "Makes the most recently accepted quest active and assisted in the quest tracker.",
            getFunc = function() return self.savedVariables.focusNewQuests end,
            setFunc = function(value) self.savedVariables.focusNewQuests = value end,
            default = self.defaults.focusNewQuests,
        },
        {
            type = "header", name = "Fishing bite notification",
        },
        {
            type = "checkbox", name = "Fishing bite sound",
            tooltip = "Plays a double sound cue when it is time to reel in.",
            getFunc = function() return self.savedVariables.fishingBiteSound end,
            setFunc = function(value) self.savedVariables.fishingBiteSound = value end,
            default = self.defaults.fishingBiteSound,
        },
        {
            type = "checkbox", name = "Fishing bite indicator",
            tooltip = "Shows a large REEL IN! indicator when a fish bites.",
            getFunc = function() return self.savedVariables.fishingBiteIndicator end,
            setFunc = function(value)
                self.savedVariables.fishingBiteIndicator = value
                if not value and self.fishingIndicator then
                    self.fishingIndicator:SetHidden(true)
                end
            end,
            default = self.defaults.fishingBiteIndicator,
        },
        {
            type = "header", name = "Guild Trader price comparison",
        },
        {
            type = "checkbox", name = "Show percentage versus market price",
            tooltip = "Shows how far a listing's unit price is below or above KEH's market price. Green is cheaper, red is more expensive and orange indicates uncertain price data.",
            getFunc = function() return self.savedVariables.showTraderPriceComparison end,
            setFunc = function(value)
                self.savedVariables.showTraderPriceComparison = value
                self:RefreshTradingHouseRows()
            end,
            default = self.defaults.showTraderPriceComparison,
        },
    })
end

local KPH = KjellmanESOHelper

function KPH:InitializeSettings()
    local LAM = LibAddonMenu2
    if not LAM then
        self:DebugLog("LibAddonMenu-2.0 saknas; standardinställningar används")
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
            type = "checkbox", name = "Aktivera automatisk ifyllnad",
            getFunc = function() return self.savedVariables.autoFill end,
            setFunc = function(value) self.savedVariables.autoFill = value end,
            default = self.defaults.autoFill,
        },
        {
            type = "checkbox", name = "Använd TTC suggested price",
            tooltip = "Om värdet saknas beräknar KPH ett försiktigt estimat från sales average, minimum, listing average och antal poster.",
            getFunc = function() return self.savedVariables.useSuggestedPrice end,
            setFunc = function(value) self.savedVariables.useSuggestedPrice = value end,
            default = self.defaults.useSuggestedPrice,
        },
        {
            type = "slider", name = "Prisfaktor (%)", min = 1, max = 200, step = 1,
            getFunc = function() return self.savedVariables.priceFactor end,
            setFunc = function(value) self.savedVariables.priceFactor = value end,
            default = self.defaults.priceFactor,
        },
        {
            type = "checkbox", name = "Avrunda föreslaget pris",
            getFunc = function() return self.savedVariables.roundPrice end,
            setFunc = function(value) self.savedVariables.roundPrice = value end,
            default = self.defaults.roundPrice,
        },
        {
            type = "checkbox", name = "Visa TTC suggested price i inventory",
            tooltip = "Visar suggested price per styck före det vanliga priset. Grönt är hög tillförlitlighet, orange är lägre och rött är osäkert.",
            getFunc = function() return self.savedVariables.showInventorySuggestedPrice end,
            setFunc = function(value)
                self.savedVariables.showInventorySuggestedPrice = value
                if PLAYER_INVENTORY then PLAYER_INVENTORY:RefreshAllInventorySlots() end
            end,
            default = self.defaults.showInventorySuggestedPrice,
        },
        {
            type = "checkbox", name = "Notifiera om värdefulla föremål",
            tooltip = "Visar en skärmnotis och spelar ett ljud när ett nytt föremål eller en ny stack i backpacken uppskattas vara värd minst den valda gränsen enligt TTC.",
            getFunc = function() return self.savedVariables.notifyValuableItems end,
            setFunc = function(value)
                self.savedVariables.notifyValuableItems = value
            end,
            default = self.defaults.notifyValuableItems,
        },
        {
            type = "slider", name = "Gräns för värdefullt föremål (g)",
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
            type = "checkbox", name = "Skydda Armory-föremål automatiskt",
            tooltip = "Låser föremål som används i en Armory-build med ESO:s vanliga spelar-lås. Det hindrar försäljning, deconstruction och förstöring. Föremål som redan har låsts förblir låsta om funktionen stängs av.",
            getFunc = function() return self.savedVariables.protectArmoryItems end,
            setFunc = function(value)
                self.savedVariables.protectArmoryItems = value
                if value then self:ProtectAllArmoryItems() end
            end,
            default = self.defaults.protectArmoryItems,
        },
        {
            type = "checkbox", name = "Planner-notis när en del hittas",
            tooltip = "Visar text på skärmen och spelar ett ljud första gången en saknad del från det planerade setet hamnar i inventoryt.",
            getFunc = function() return self.savedVariables.plannerNotifications end,
            setFunc = function(value)
                self.savedVariables.plannerNotifications = value
            end,
            default = self.defaults.plannerNotifications,
        },
        {
            type = "checkbox", name = "Visa suggested price i butiker",
            tooltip = "Visar uppskattat marknadsvärde per styck direkt före kostnaden i NPC- och PvP-butiker. Butikens riktiga kostnad ändras inte.",
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
            type = "checkbox", name = "Fokusera nya quests automatiskt",
            tooltip = "Gör den senast accepterade questen till aktiv och assisterad quest i trackern.",
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
            type = "header", name = "Prisjämförelse i Guild Trader",
        },
        {
            type = "checkbox", name = "Visa procent mot normalpris",
            tooltip = "Visar hur mycket annonsens styckpris ligger under eller över KPH:s normalpris. Grönt är billigare, rött är dyrare och orange betyder osäkert prisunderlag.",
            getFunc = function() return self.savedVariables.showTraderPriceComparison end,
            setFunc = function(value)
                self.savedVariables.showTraderPriceComparison = value
                self:RefreshTradingHouseRows()
            end,
            default = self.defaults.showTraderPriceComparison,
        },
    })
end

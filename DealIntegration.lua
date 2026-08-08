local KPH = KjellmanESOHelper

local function HidePriceComparison(rowControl)
    if rowControl and rowControl.kphPriceComparison then
        rowControl.kphPriceComparison:SetHidden(true)
        rowControl.kphPriceComparison.priceData = nil
    end
end

function KPH:GetOrCreatePriceComparison(rowControl)
    if rowControl.kphPriceComparison then return rowControl.kphPriceComparison end

    local timeControl = rowControl:GetNamedChild("TimeRemaining")
    if not timeControl then return nil end

    -- Tiden flyttas lite uppåt och prisjämförelsen får en egen rad under den.
    if not rowControl.kphTimeAdjusted then
        local isValid, point, relativeTo, relativePoint, offsetX, offsetY =
            timeControl:GetAnchor(0)
        if isValid then
            timeControl:ClearAnchors()
            timeControl:SetAnchor(point, relativeTo, relativePoint,
                offsetX, offsetY - 10)
        end
        rowControl.kphTimeAdjusted = true
    end

    local unitPriceControl = rowControl:GetNamedChild("SellPricePerUnit")
    if unitPriceControl and not rowControl.kphUnitPriceAdjusted then
        local isValid, point, relativeTo, relativePoint, offsetX, offsetY =
            unitPriceControl:GetAnchor(0)
        if isValid then
            unitPriceControl:ClearAnchors()
            unitPriceControl:SetAnchor(point, relativeTo, relativePoint,
                offsetX, offsetY + 10)
        end
        rowControl.kphUnitPriceAdjusted = true
    end

    local controlName = rowControl:GetName() .. "KPHPriceComparison"
    local label = rowControl:CreateControl(controlName, CT_LABEL)
    label:SetDimensions(120, 18)
    label:SetAnchor(TOPLEFT, timeControl, BOTTOMLEFT, 0, 0)
    label:SetFont("ZoFontGameSmall")
    label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    label:SetDrawTier(DT_HIGH)
    label:SetDrawLayer(DL_OVERLAY)
    label:SetMouseEnabled(true)
    label:SetHandler("OnMouseEnter", function(control)
        local priceData = control.priceData
        if not priceData then return end
        InitializeTooltip(InformationTooltip, control, LEFT, -8, 0)
        InformationTooltip:AddLine("KEH prisjämförelse", "ZoFontWinH2",
            1, 0.82, 0.25, CENTER, MODIFY_TEXT_TYPE_NONE,
            TEXT_ALIGN_CENTER, true)
        InformationTooltip:AddLine(string.format("Normalt marknadspris: %s/st",
            self:FormatGold(priceData.marketPrice)))
        InformationTooltip:AddLine(string.format("Annonspris: %s/st",
            self:FormatGold(priceData.listingPrice)))
        InformationTooltip:AddLine(priceData.explanation)
        InformationTooltip:AddLine(string.format("Prisunderlag: %s",
            priceData.confidence == "low" and "osäkert" or "TTC/KPH"))
    end)
    label:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)
    label:SetHidden(true)
    rowControl.kphPriceComparison = label
    return label
end

function KPH:UpdatePriceComparison(rowControl, result)
    HidePriceComparison(rowControl)
    if IsInGamepadPreferredMode() or not rowControl or not result then return end
    if not self.savedVariables.showTraderPriceComparison then return end

    local itemLink = result.itemLink
    if not itemLink or itemLink == "" then
        local slotIndex = result.slotIndex or result.itemUniqueId
        if slotIndex then
            itemLink = GetTradingHouseSearchResultItemLink(
                slotIndex, LINK_STYLE_DEFAULT)
        end
    end
    if not itemLink or itemLink == "" then return end

    local stackCount = math.max(1, tonumber(result.stackCount) or 1)
    local listingPrice = tonumber(result.purchasePricePerUnit)
    if not listingPrice then
        local totalPrice = tonumber(result.purchasePrice)
        if totalPrice then listingPrice = totalPrice / stackCount end
    end
    if not listingPrice or listingPrice <= 0 then return end

    local marketPrice, confidence = self:GetTTCSuggestedPrice(itemLink)
    if not marketPrice or marketPrice <= 0 then return end

    -- Positivt betyder att annonsen är billigare än normalpriset.
    local percent = ((marketPrice - listingPrice) / marketPrice) * 100
    local label = self:GetOrCreatePriceComparison(rowControl)
    if not label then return end

    label:SetText(string.format("%+.1f%%", percent))
    if confidence == "low" then
        label:SetColor(0.95, 0.60, 0.15, 1) -- orange: osäkert underlag
    elseif percent > 0.05 then
        label:SetColor(0.20, 0.90, 0.25, 1) -- grön: under normalpris
    elseif percent < -0.05 then
        label:SetColor(1.00, 0.20, 0.20, 1) -- röd: över normalpris
    else
        label:SetColor(0.85, 0.85, 0.85, 1)
    end

    local explanation
    if percent > 0.05 then
        explanation = string.format("Annonsen ligger %.1f%% under normalpris.", percent)
    elseif percent < -0.05 then
        explanation = string.format("Annonsen ligger %.1f%% över normalpris.", -percent)
    else
        explanation = "Annonsen ligger ungefär på normalpris."
    end
    label.priceData = {
        marketPrice = marketPrice,
        listingPrice = listingPrice,
        confidence = confidence,
        explanation = explanation,
    }
    label:SetHidden(false)
end

function KPH:RefreshTradingHouseRows()
    if TRADING_HOUSE and TRADING_HOUSE.searchResultsList then
        ZO_ScrollList_RefreshVisible(TRADING_HOUSE.searchResultsList)
    end
end

function KPH:InstallPriceComparisonHook()
    if not TRADING_HOUSE or
       not TRADING_HOUSE.searchResultsList then return end

    local hookedCount = 0
    local dataTypes = TRADING_HOUSE.searchResultsList.dataTypes
    if not dataTypes then return end

    -- Direkt åtkomst till dataTypes gör att både vanliga och guild-specifika
    -- sökresultat kan få samma radvisning. Typ 1 och 3 täcker resultaten.
    for _, dataTypeIndex in ipairs({ 1, 3 }) do
        local dataType = dataTypes[dataTypeIndex]
        if dataType and type(dataType.setupCallback) == "function" and
           not dataType.kphPriceComparisonHook then
            local originalCallback = dataType.setupCallback
            dataType.setupCallback = function(rowControl, result, ...)
                originalCallback(rowControl, result, ...)
                HidePriceComparison(rowControl)
                zo_callLater(function()
                    self:UpdatePriceComparison(rowControl, result)
                end, 1)
            end
            dataType.kphPriceComparisonHook = true
            hookedCount = hookedCount + 1
        end
    end

    if hookedCount > 0 then
        self:RefreshTradingHouseRows()
        self:DebugLog(string.format("Prisjämförelse kopplad till %d radtyper",
            hookedCount))
    end
end

function KPH:InitializeDealIntegration()
    -- Trading House skapar sin resultatrad först när ett svar tas emot.
    -- Installera därför callbacken här, och försök igen vid varje svar om en
    -- annan addon eller UI-laddningen har ersatt/listat om radtypen.
    EVENT_MANAGER:RegisterForEvent(self.name .. "PriceComparison",
        EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, function()
            self:InstallPriceComparisonHook()
        end)

    EVENT_MANAGER:RegisterForEvent(self.name .. "PriceComparisonActivated",
        EVENT_PLAYER_ACTIVATED, function()
            zo_callLater(function() self:InstallPriceComparisonHook() end, 1)
        end)
    if type(ZO_TradingHouse_OnInitialized) == "function" then
        SecurePostHook("ZO_TradingHouse_OnInitialized", function()
            self:InstallPriceComparisonHook()
        end)
    end
end

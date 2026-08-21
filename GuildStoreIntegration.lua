local KPH = KjellmanESOHelper

function KPH:CreatePriceLabel()
    if self.priceLabel or not TRADING_HOUSE or not TRADING_HOUSE.postItemPane then return end
    local parent = TRADING_HOUSE.postItemPane
    local label = WINDOW_MANAGER:CreateControl(self.name .. "PriceLabel", parent, CT_LABEL)
    label:SetFont("ZoFontGame")
    label:SetColor(0.78, 0.78, 0.68, 1)
    label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    label:SetVerticalAlignment(TEXT_ALIGN_TOP)
    label:SetDimensions(390, 74)
    label:SetAnchor(TOPLEFT, TRADING_HOUSE.invoice, BOTTOMLEFT, 0, 8)
    label:SetText("KEH: select an item to sell")
    self.priceLabel = label
end

function KPH:SetStatus(text)
    self:CreatePriceLabel()
    if self.priceLabel then self.priceLabel:SetText(text or "") end
end

function KPH:ClearSelection()
    local state = self.state
    state.currentItemLink = nil
    state.currentStackCount = 0
    state.lastAutoFilledPrice = nil
    state.userHasEditedPrice = false
    self:SetStatus("KEH: select an item to sell")
end

function KPH:RefreshPendingPost()
    local tradingHouse = TRADING_HOUSE
    if not tradingHouse or not tradingHouse.pendingItemSlot then
        self:ClearSelection()
        return
    end

    local slot = tradingHouse.pendingItemSlot
    local itemLink = GetItemLink(BAG_BACKPACK, slot)
    local _, stackCount = GetItemInfo(BAG_BACKPACK, slot)
    stackCount = tonumber(stackCount) or 0
    if not itemLink or itemLink == "" or stackCount < 1 then
        self:ClearSelection()
        return
    end

    local state = self.state
    local isNewItem = itemLink ~= state.currentItemLink
    local stackChanged = stackCount ~= state.currentStackCount
    if isNewItem then
        state.currentItemLink = itemLink
        state.lastAutoFilledPrice = nil
        state.userHasEditedPrice = false
    end
    state.currentStackCount = stackCount

    local result, reason = self:GetTTCUnitPrice(itemLink)
    if not result then
        self:SetStatus(reason or "No TTC price data found")
        return
    end

    local factor = (tonumber(self.savedVariables.priceFactor) or 100) / 100
    local adjustedUnitPrice = result.unitPrice * factor
    local totalPrice = adjustedUnitPrice * stackCount
    if self.savedVariables.roundPrice then
        totalPrice = self:RoundSuggestedPrice(totalPrice)
    else
        totalPrice = math.floor(totalPrice + 0.5)
    end
    totalPrice = math.max(1, totalPrice)

    local status = "Suggested price calculated"
    local mayAutoFill = self.savedVariables.autoFill and
        (isNewItem or stackChanged) and not state.userHasEditedPrice
    if mayAutoFill then
        state.isApplyingAutomaticPrice = true
        tradingHouse:SetPendingPostPrice(totalPrice)
        state.isApplyingAutomaticPrice = false
        state.lastAutoFilledPrice = totalPrice
        status = "Price filled automatically"
    elseif state.userHasEditedPrice then
        status = "Manual price preserved"
    end

    self:SetStatus(string.format("TTC: %s gold/ea (%s)\nStack: %d   Suggested: %s gold\n%s",
        self:FormatGold(adjustedUnitPrice), result.source, stackCount,
        self:FormatGold(totalPrice), status))
end

function KPH:InitializeGuildStoreIntegration()
    if not TRADING_HOUSE or type(TRADING_HOUSE.SetupPendingPost) ~= "function" then
        self:DebugLog("The sell panel has not been created yet")
        if type(ZO_TradingHouse_OnInitialized) == "function" then
            SecurePostHook("ZO_TradingHouse_OnInitialized", function()
                self:InitializeGuildStoreIntegration()
            end)
        end
        return
    end
    if self.guildStoreHooksInstalled then return end
    self.guildStoreHooksInstalled = true
    self:CreatePriceLabel()

    ZO_PreHook(TRADING_HOUSE, "SetupPendingPost", function()
        self.state.isSettingUpPendingPost = true
        return false
    end)
    SecurePostHook(TRADING_HOUSE, "SetupPendingPost", function()
        self.state.isSettingUpPendingPost = false
        self:RefreshPendingPost()
    end)
    SecurePostHook(TRADING_HOUSE, "ClearPendingPost", function()
        self.state.isSettingUpPendingPost = false
        self:ClearSelection()
    end)
    SecurePostHook(TRADING_HOUSE, "SetPendingPostPrice", function(_, price)
        local state = self.state
        if not state.currentItemLink or state.isSettingUpPendingPost or
           state.isApplyingAutomaticPrice then return end
        price = tonumber(price)
        if not state.lastAutoFilledPrice or price ~= state.lastAutoFilledPrice then
            state.userHasEditedPrice = true
            self:DebugLog("Manual price change detected")
        end
    end)
end

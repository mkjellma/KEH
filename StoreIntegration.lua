local KPH = KjellmanESOHelper

function KPH:AddSuggestedPriceToStoreRow(control, data)
    if not control then return end

    local priceControl = control:GetNamedChild("SellPrice")
    local priceLabel = control.kphSuggestedPriceLabel
    if not priceLabel and priceControl then
        priceLabel = WINDOW_MANAGER:CreateControl(nil, control, CT_LABEL)
        priceLabel:SetFont("ZoFontGameShadow")
        priceLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
        priceLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        priceLabel:SetDimensions(110, 32)
        priceLabel:SetAnchor(RIGHT, priceControl, LEFT, -8, 0)
        priceLabel:SetDrawLayer(DL_OVERLAY)
        control.kphSuggestedPriceLabel = priceLabel
    end
    if priceLabel then priceLabel:SetHidden(true) end

    if not self.savedVariables.showStoreSuggestedPrice or
       IsInGamepadPreferredMode() or not data or
       data.slotIndex == nil then
        return
    end

    local itemLink = GetStoreItemLink(data.slotIndex, LINK_STYLE_DEFAULT)
    if not itemLink or itemLink == "" then return end
    local suggestedPrice, confidence = self:GetTTCSuggestedPrice(itemLink)
    if not suggestedPrice then return end

    if not priceLabel then return end
    local colors = {
        high = { 0.40, 0.80, 0.40 },
        medium = { 0.91, 0.61, 0.21 },
        low = { 0.88, 0.35, 0.35 },
    }
    local color = colors[confidence] or colors.low
    priceLabel:SetColor(color[1], color[2], color[3], 1)
    priceLabel:SetText(string.format("(%s)", self:FormatGold(suggestedPrice)))
    priceLabel:SetHidden(false)
end

function KPH:InstallStoreHook()
    if self.storeHookInstalled or not ZO_StoreManager or
       type(ZO_StoreManager.SetUpBuySlot) ~= "function" then
        return
    end
    self.storeHookInstalled = true
    SecurePostHook(ZO_StoreManager, "SetUpBuySlot", function(_, control, data)
        self:AddSuggestedPriceToStoreRow(control, data)
    end)
end

function KPH:InitializeStoreIntegration()
    EVENT_MANAGER:RegisterForEvent(self.name .. "Store", EVENT_PLAYER_ACTIVATED,
        function()
            EVENT_MANAGER:UnregisterForEvent(self.name .. "Store", EVENT_PLAYER_ACTIVATED)
            zo_callLater(function() self:InstallStoreHook() end, 0)
        end)
end

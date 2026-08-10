local KPH = KjellmanESOHelper

function KPH:CalculateTTCFallbackPrice(info)
    if not info then return nil end

    local average = tonumber(info.Avg)
    local minimum = tonumber(info.Min)
    local saleAverage = tonumber(info.SaleAvg)
    local listingCount = math.max(0, tonumber(info.EntryCount) or 0)
    local saleCount = math.max(0, tonumber(info.SaleEntryCount) or 0)

    -- Listing average can be distorted by optimistic outliers. Move only 25%
    -- from the current minimum towards average when both are available.
    local listingEstimate
    if minimum and minimum > 0 and average and average > 0 then
        listingEstimate = minimum + ((average - minimum) * 0.25)
    elseif average and average > 0 then
        listingEstimate = average
    elseif minimum and minimum > 0 then
        listingEstimate = minimum
    end

    if saleAverage and saleAverage > 0 and listingEstimate then
        -- Actual sales get up to 75% weight. A small history is blended more
        -- cautiously with current listings; large counts are capped.
        local saleWeight = math.min(saleCount, 10) * 3
        local listingWeight = math.max(1, math.min(listingCount, 10))
        saleWeight = math.max(3, saleWeight)
        listingWeight = math.max(1, listingWeight)
        return ((saleAverage * saleWeight) + (listingEstimate * listingWeight)) /
            (saleWeight + listingWeight)
    elseif saleAverage and saleAverage > 0 then
        return saleAverage
    end

    return listingEstimate
end

-- TTC documents GetPriceInfo as a public third-party function. Values in its
-- price table are unit prices: listing totals are normalized by item amount.
function KPH:GetTTCUnitPrice(itemLink)
    if type(itemLink) ~= "string" or itemLink == "" then
        return nil, "Ogiltig item link"
    end
    if not TamrielTradeCentrePrice or
       type(TamrielTradeCentrePrice.GetPriceInfo) ~= "function" then
        return nil, "Tamriel Trade Centre är inte laddat"
    end

    local ok, info = pcall(function()
        return TamrielTradeCentrePrice:GetPriceInfo(itemLink)
    end)
    if not ok then
        self:DebugLog("TTC GetPriceInfo misslyckades: " .. tostring(info))
        return nil, "TTC kunde inte läsa prisdata"
    end
    if not info then return nil, "Ingen TTC-prisdata hittades" end

    local unitPrice, source
    if self.savedVariables.useSuggestedPrice and tonumber(info.SuggestedPrice) then
        unitPrice, source = tonumber(info.SuggestedPrice), "suggested"
    elseif self.savedVariables.useSuggestedPrice then
        unitPrice, source = self:CalculateTTCFallbackPrice(info), "KPH estimate"
    elseif tonumber(info.SaleAvg) then
        unitPrice, source = tonumber(info.SaleAvg), "sales average"
    elseif tonumber(info.Avg) then
        unitPrice, source = tonumber(info.Avg), "listing average"
    end

    if not unitPrice or unitPrice <= 0 then
        return nil, "Ingen tillförlitlig TTC-prisdata hittades"
    end
    return { unitPrice = unitPrice, source = source, info = info }
end

function KPH:GetTTCSuggestedPrice(itemLink)
    if type(itemLink) ~= "string" or itemLink == "" then return nil end
    if not TamrielTradeCentrePrice or
       type(TamrielTradeCentrePrice.GetPriceInfo) ~= "function" then
        return nil
    end

    local ok, info = pcall(function()
        return TamrielTradeCentrePrice:GetPriceInfo(itemLink)
    end)
    if not ok or not info then return nil end
    local suggestedPrice = tonumber(info.SuggestedPrice)
    local hasSuggestedPrice = suggestedPrice and suggestedPrice > 0
    local price = hasSuggestedPrice and suggestedPrice or
        self:CalculateTTCFallbackPrice(info)
    if not price then return nil end

    local listingCount = math.max(0, tonumber(info.EntryCount) or 0)
    local saleCount = math.max(0, tonumber(info.SaleEntryCount) or 0)
    local confidenceScore = hasSuggestedPrice and 3 or 0

    if listingCount >= 10 then
        confidenceScore = confidenceScore + 2
    elseif listingCount >= 3 then
        confidenceScore = confidenceScore + 1
    end
    if saleCount >= 5 then
        confidenceScore = confidenceScore + 2
    elseif saleCount >= 1 then
        confidenceScore = confidenceScore + 1
    end

    local confidence = "low"
    if confidenceScore >= 5 then
        confidence = "high"
    elseif confidenceScore >= 2 then
        confidence = "medium"
    end
    return price, confidence
end

local function FindTTCPriceLeaf(node,depth)
    if type(node)~="table" or depth>8 then return nil end
    if tonumber(node.S) or tonumber(node.A) or tonumber(node.N) then return node end
    for _,child in pairs(node) do
        local found=FindTTCPriceLeaf(child,depth+1)
        if found then return found end
    end
end

-- TTC's lookup and price tables let Goldmaker value a curated material even
-- when the player does not currently own an item link for it.
function KPH:GetTTCPriceByName(itemName)
    if type(itemName)~="string" or itemName=="" or not TamrielTradeCentre or
       not TamrielTradeCentrePrice or not TamrielTradeCentre.ItemLookUpTable or
       not TamrielTradeCentrePrice.PriceTable then return nil end
    local types=TamrielTradeCentre.ItemLookUpTable[zo_strlower(itemName)]
    if type(types)~="table" then return nil end
    local data=TamrielTradeCentrePrice.PriceTable.Data
    if type(data)~="table" then return nil end
    local leaf
    for _,ttcId in pairs(types) do
        leaf=FindTTCPriceLeaf(data[ttcId],0)
        if leaf then break end
    end
    if not leaf then return nil end
    local suggested=tonumber(leaf.S)
    local average=tonumber(leaf.A)
    local minimum=tonumber(leaf.N)
    local saleAverage=tonumber(leaf.SA)
    local price=suggested
    if not price or price<=0 then
        price=self:CalculateTTCFallbackPrice({Avg=average,Min=minimum,
            SaleAvg=saleAverage,EntryCount=leaf.EC,SaleEntryCount=leaf.SE})
    end
    if not price or price<=0 then return nil end
    local listings=math.max(0,tonumber(leaf.EC) or 0)
    local sales=math.max(0,tonumber(leaf.SE) or 0)
    local confidence=(suggested and sales>=5) and "high" or
        ((listings>=3 or sales>=1) and "medium" or "low")
    return price,confidence,{EntryCount=listings,SaleEntryCount=sales,
        Avg=average,Min=minimum,SaleAvg=saleAverage,SuggestedPrice=suggested}
end

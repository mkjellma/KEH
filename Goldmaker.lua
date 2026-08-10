KjellmanESOHelper = KjellmanESOHelper or {}
local KPH=KjellmanESOHelper

local FARM_CANDIDATES={
    {name="Dreugh Wax",ease=0.75,source="Refine raw cloth/leather; clothing surveys and deconstruction"},
    {name="Tempering Alloy",ease=0.75,source="Refine raw ore; blacksmithing surveys and deconstruction"},
    {name="Rosin",ease=0.75,source="Refine raw wood; woodworking surveys and deconstruction"},
    {name="Chromium Plating",ease=0.45,source="Refine jewelry dust; jewelry surveys and deconstruction"},
    {name="Kuta",ease=0.65,source="Runestone nodes and enchanting surveys"},
    {name="Hakeijo",ease=0.30,source="Imperial City Tel Var merchant and rare Psijic portals"},
    {name="Perfect Roe",ease=0.35,source="Catch fish and fillet them"},
    {name="Aetherial Dust",ease=0.12,source="Very rare drop from base-game resource nodes"},
    {name="Potent Nirncrux",ease=0.22,source="Resource nodes in upper Craglorn"},
    {name="Fortified Nirncrux",ease=0.22,source="Resource nodes in upper Craglorn"},
    {name="Columbine",ease=0.90,source="Alchemy plant nodes and alchemy surveys"},
    {name="Corn Flower",ease=0.90,source="Alchemy plant nodes and alchemy surveys"},
    {name="Lady's Smock",ease=0.90,source="Alchemy plant nodes and alchemy surveys"},
    {name="Dragon Rheum",ease=0.30,source="Dragon fights in Northern and Southern Elsweyr"},
    {name="Powdered Mother of Pearl",ease=0.45,source="Giant clams along Summerset shores"},
    {name="Clam Gall",ease=0.45,source="Giant clams along Summerset shores"},
    {name="Mundane Rune",ease=0.85,source="Runestone nodes"},
    {name="Heartwood",ease=0.85,source="Wood nodes"},
    {name="Decorative Wax",ease=0.70,source="Containers and provisioning loot"},
    {name="Alchemical Resin",ease=0.85,source="Alchemy reagent nodes"},
    {name="Regulus",ease=0.85,source="Ore nodes"},
    {name="Bast",ease=0.85,source="Clothing material nodes"},
    {name="Clean Pelt",ease=0.70,source="Animals and leather-producing creatures"},
}

local function StackCount(link)
    if not link or link=="" then return 0,0,0,0 end
    local backpack,bank,craftBag=GetItemLinkStacks(link)
    backpack,bank,craftBag=backpack or 0,bank or 0,craftBag or 0
    return backpack+bank+craftBag,backpack,bank,craftBag
end

local function FindFarmMaterialLinks()
    local wanted={}
    for _,candidate in ipairs(FARM_CANDIDATES) do
        wanted[zo_strlower(candidate.name)]=true
    end
    local found={}
    local bags={BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK,BAG_VIRTUAL}
    for _,bag in ipairs(bags) do
        if bag then
            for slot=0,(GetBagSize(bag) or 0)-1 do
                local link=GetItemLink(bag,slot,LINK_STYLE_DEFAULT)
                if link and link~="" then
                    local lower=zo_strlower(zo_strformat("<<C:1>>",GetItemLinkName(link)))
                    if wanted[lower] and not found[lower] then found[lower]=link end
                end
            end
        end
    end
    return found
end

function KPH:GetGoldmakerFarmList()
    self.savedVariables.goldmakerFarmList=self.savedVariables.goldmakerFarmList or {}
    return self.savedVariables.goldmakerFarmList
end

function KPH:BuildGoldmakerFarmRanking()
    local ranking={}
    local ownedLinks=FindFarmMaterialLinks()
    for _,candidate in ipairs(FARM_CANDIDATES) do
        local price,confidence,info=self:GetTTCPriceByName(candidate.name)
        if price then
            local sales=math.max(0,tonumber(info and info.SaleEntryCount) or 0)
            local listings=math.max(0,tonumber(info and info.EntryCount) or 0)
            local demand=(1+math.min(sales,50)*0.035)/(1+math.min(listings,500)*0.001)
            local score=price*candidate.ease*demand
            local link=ownedLinks[zo_strlower(candidate.name)]
            local owned=link and StackCount(link) or 0
            table.insert(ranking,{name=candidate.name,source=candidate.source,
                ease=candidate.ease,price=price,confidence=confidence,
                sales=sales,listings=listings,score=score,owned=owned,link=link})
        end
    end
    table.sort(ranking,function(a,b) return a.score>b.score end)
    self.goldmakerFarmRanking=ranking
    return ranking
end

function KPH:IsGoldmakerFarmActive(name)
    for _,savedName in ipairs(self:GetGoldmakerFarmList()) do
        if savedName==name then return true end
    end
    return false
end

function KPH:AddGoldmakerFarmItem(item)
    if not self:IsGoldmakerFarmActive(item.name) then
        table.insert(self:GetGoldmakerFarmList(),item.name)
    end
    self.goldmakerSelectedFarm=item
    self:RefreshGoldmaker()
end

function KPH:RemoveGoldmakerFarmItem()
    local selected=self.goldmakerSelectedFarm
    if not selected then return end
    local list=self:GetGoldmakerFarmList()
    for index,name in ipairs(list) do
        if name==selected.name then table.remove(list,index) break end
    end
    self.goldmakerSelectedFarm=nil
    self:RefreshGoldmaker()
end

function KPH:ToggleGoldmakerFarmItem()
    local selected=self.goldmakerSelectedFarm
    if not selected then return end
    if self:IsGoldmakerFarmActive(selected.name) then
        local list=self:GetGoldmakerFarmList()
        for index,name in ipairs(list) do
            if name==selected.name then table.remove(list,index) break end
        end
    else
        table.insert(self:GetGoldmakerFarmList(),selected.name)
    end
    self:RefreshGoldmaker()
end

function KPH:SetGoldmakerSection(section)
    self.goldmakerSection=section
    self.goldmakerMode=section=="farming" and "farmBest" or "plans"
    if self.goldmakerSearchBackdrop then self.goldmakerSearchBackdrop:SetHidden(true) end
    self:RefreshGoldmaker()
end

local function FarmingHint(link)
    local itemType=GetItemLinkItemType(link)
    if itemType==ITEMTYPE_REAGENT then return "Harvest alchemy reagent nodes" end
    if itemType==ITEMTYPE_INGREDIENT then
        return "Provisioning containers, barrels, sacks or guild traders"
    end
    if itemType==ITEMTYPE_RAW_MATERIAL then return "Harvest material nodes" end
    if itemType==ITEMTYPE_STYLE_MATERIAL then return "Deconstruct gear or buy from traders" end
    return "Loot, harvesting or guild traders"
end

local function CraftTypeName(link)
    local itemType=GetItemLinkItemType(link)
    if itemType==ITEMTYPE_FOOD then return "Provisioning - Food" end
    if itemType==ITEMTYPE_DRINK then return "Provisioning - Drink" end
    if itemType==ITEMTYPE_FURNISHING then return "Furnishing" end
    if itemType==ITEMTYPE_POTION then return "Alchemy - Potion" end
    if itemType==ITEMTYPE_POISON then return "Alchemy - Poison" end
    if itemType==ITEMTYPE_GLYPH_ARMOR or itemType==ITEMTYPE_GLYPH_WEAPON or
       itemType==ITEMTYPE_GLYPH_JEWELRY then return "Enchanting" end
    return "Crafted item"
end

function KPH:BuildGoldmakerRecipeIndex()
    if self.goldmakerRecipeIndex then return end
    self.goldmakerRecipeIndex={}
    local listCount=type(GetNumRecipeLists)=="function" and GetNumRecipeLists() or 0
    for listIndex=1,listCount do
        local _,recipeCount=GetRecipeListInfo(listIndex)
        for recipeIndex=1,(recipeCount or 0) do
            local known,name,numIngredients=GetRecipeInfo(listIndex,recipeIndex)
            if known and name and name~="" then
                local resultLink=GetRecipeResultItemLink(
                    listIndex,recipeIndex,LINK_STYLE_DEFAULT)
                if resultLink and resultLink~="" then
                    table.insert(self.goldmakerRecipeIndex,{
                        listIndex=listIndex,recipeIndex=recipeIndex,
                        name=zo_strformat("<<C:1>>",name),
                        lower=zo_strlower(zo_strformat("<<C:1>>",name)),
                        resultLink=resultLink,numIngredients=numIngredients or 0,
                        craftType=CraftTypeName(resultLink),
                    })
                end
            end
        end
    end
    table.sort(self.goldmakerRecipeIndex,function(a,b) return a.name<b.name end)
end

function KPH:GetGoldmakerProfit(recipe)
    local resultPrice,resultConfidence=self:GetTTCSuggestedPrice(recipe.resultLink)
    if not resultPrice then return nil end
    local output=math.max(1,GetRecipeResultQuantity(recipe.listIndex,recipe.recipeIndex) or 1)
    local materialCost=0
    for ingredientIndex=1,(recipe.numIngredients or 0) do
        local link=GetRecipeIngredientItemLink(recipe.listIndex,recipe.recipeIndex,
            ingredientIndex,LINK_STYLE_DEFAULT)
        local quantity=GetRecipeIngredientRequiredQuantity(
            recipe.listIndex,recipe.recipeIndex,ingredientIndex) or 0
        local price=self:GetTTCSuggestedPrice(link)
        if not price or quantity<=0 then return nil end
        materialCost=materialCost+(price*quantity)
    end
    local net=(resultPrice*output*0.92)-materialCost
    local margin=materialCost>0 and (net/materialCost)*100 or 0
    local market=self:GetTTCUnitPrice(recipe.resultLink)
    local info=market and market.info or nil
    local listings=info and math.max(0,tonumber(info.EntryCount) or 0) or 0
    local sales=info and math.max(0,tonumber(info.SaleEntryCount) or 0) or 0
    local score=net*(1+math.min(sales,20)*0.025)/(1+math.min(listings,100)*0.002)
    return {recipe=recipe,net=net,margin=margin,materialCost=materialCost,
        salePrice=resultPrice,confidence=resultConfidence,output=output,
        listings=listings,sales=sales,score=score}
end

function KPH:BuildGoldmakerProfits()
    if self.goldmakerProfits then return self.goldmakerProfits end
    self:BuildGoldmakerRecipeIndex()
    local profits={}
    for _,recipe in ipairs(self.goldmakerRecipeIndex or {}) do
        local profit=self:GetGoldmakerProfit(recipe)
        if profit and profit.net>0 then table.insert(profits,profit) end
    end
    table.sort(profits,function(a,b) return a.score>b.score end)
    self.goldmakerProfits=profits
    return profits
end

function KPH:SetGoldmakerMode(mode)
    self.goldmakerMode=mode
    if self.goldmakerSearchBackdrop then self.goldmakerSearchBackdrop:SetHidden(true) end
    self:RefreshGoldmaker()
end

function KPH:GetGoldmakerRecipeMatches(search)
    self:BuildGoldmakerRecipeIndex()
    local needle=zo_strlower(zo_strtrim(search or ""))
    local matches={}
    if #needle<2 then return matches end
    for _,recipe in ipairs(self.goldmakerRecipeIndex or {}) do
        if string.find(recipe.lower,needle,1,true) then
            table.insert(matches,recipe)
        end
    end
    table.sort(matches,function(a,b)
        local ae=a.lower==needle
        local be=b.lower==needle
        if ae~=be then return ae end
        return a.name<b.name
    end)
    while #matches>6 do table.remove(matches) end
    return matches
end

function KPH:GetGoldmakerPlans()
    self.savedVariables.goldmakerPlans=self.savedVariables.goldmakerPlans or {}
    return self.savedVariables.goldmakerPlans
end

function KPH:AddGoldmakerRecipe(recipe)
    if self.goldmakerSearchBackdrop then
        self.goldmakerSearchBackdrop:SetHidden(true)
    end
    local plans=self:GetGoldmakerPlans()
    local itemId=GetItemLinkItemId(recipe.resultLink)
    for index,plan in ipairs(plans) do
        if plan.itemId==itemId then
            self.goldmakerActivePlan=index
            self:RefreshGoldmaker()
            return
        end
    end
    table.insert(plans,{
        listIndex=recipe.listIndex,recipeIndex=recipe.recipeIndex,
        itemId=itemId,name=recipe.name,target=20,
    })
    self.goldmakerActivePlan=#plans
    self:RefreshGoldmaker()
end

function KPH:GetGoldmakerPlanAnalysis(plan)
    if not plan then return nil end
    local known,name,numIngredients=GetRecipeInfo(plan.listIndex,plan.recipeIndex)
    if not known then return nil end
    local resultLink=GetRecipeResultItemLink(
        plan.listIndex,plan.recipeIndex,LINK_STYLE_DEFAULT)
    local output=math.max(1,GetRecipeResultQuantity(
        plan.listIndex,plan.recipeIndex) or 1)
    local stock=StackCount(resultLink)
    local target=math.max(1,tonumber(plan.target) or 1)
    local neededItems=math.max(0,target-stock)
    local craftsNeeded=math.ceil(neededItems/output)
    local materials={}
    local craftableIterations
    local materialCost=0
    for ingredientIndex=1,(numIngredients or 0) do
        local link=GetRecipeIngredientItemLink(plan.listIndex,plan.recipeIndex,
            ingredientIndex,LINK_STYLE_DEFAULT)
        local perCraft=GetRecipeIngredientRequiredQuantity(
            plan.listIndex,plan.recipeIndex,ingredientIndex) or 0
        if link and link~="" and perCraft>0 then
            local owned,backpack,bank,craftBag=StackCount(link)
            local required=perCraft*craftsNeeded
            local possible=math.floor(owned/perCraft)
            craftableIterations=craftableIterations and
                math.min(craftableIterations,possible) or possible
            local unitPrice,confidence=self:GetTTCSuggestedPrice(link)
            if unitPrice then materialCost=materialCost+(unitPrice*required) end
            table.insert(materials,{
                link=link,name=zo_strformat("<<C:1>>",GetItemLinkName(link)),
                perCraft=perCraft,required=required,owned=owned,
                missing=math.max(0,required-owned),backpack=backpack,
                bank=bank,craftBag=craftBag,unitPrice=unitPrice,
                confidence=confidence,hint=FarmingHint(link),
            })
        end
    end
    craftableIterations=craftableIterations or 0
    local craftableItems=math.min(neededItems,craftableIterations*output)
    local salePrice,saleConfidence=self:GetTTCSuggestedPrice(resultLink)
    local gross=salePrice and salePrice*neededItems or nil
    local net=gross and gross*0.92-materialCost or nil
    return {
        name=zo_strformat("<<C:1>>",name),resultLink=resultLink,
        output=output,stock=stock,target=target,neededItems=neededItems,
        craftsNeeded=craftsNeeded,craftableItems=craftableItems,
        materials=materials,salePrice=salePrice,
        saleConfidence=saleConfidence,materialCost=materialCost,
        estimatedNet=net,
    }
end

function KPH:ChangeGoldmakerTarget(amount)
    local plan=self:GetGoldmakerPlans()[self.goldmakerActivePlan or 1]
    if not plan then return end
    plan.target=math.max(1,math.min(9999,(tonumber(plan.target) or 1)+amount))
    self:RefreshGoldmaker()
end

function KPH:DeleteGoldmakerPlan()
    local plans=self:GetGoldmakerPlans()
    local index=self.goldmakerActivePlan or 1
    if not plans[index] then return end
    table.remove(plans,index)
    self.goldmakerActivePlan=math.min(index,#plans)
    self:RefreshGoldmaker()
end

function KPH:ExportGoldmakerToNotepad()
    local plan=self:GetGoldmakerPlans()[self.goldmakerActivePlan or 1]
    local analysis=self:GetGoldmakerPlanAnalysis(plan)
    if not analysis then return end
    self:ShowNotepad()
    self:SwitchNotepadTab("Farming")
    local lines={string.format("Goldmaker: %s — target %d",analysis.name,analysis.target)}
    for _,material in ipairs(analysis.materials) do
        local marker=material.missing==0 and "[x]" or "[ ]"
        table.insert(lines,string.format("%s %s: %d / %d (missing %d) — %s",
            marker,material.name,material.owned,material.required,
            material.missing,material.hint))
    end
    self:AppendNotepadText(table.concat(lines,"\n"))
end

function KPH:ExportGoldmakerFarmToNotepad()
    local item=self.goldmakerSelectedFarm
    if not item then return end
    self:ShowNotepad()
    self:SwitchNotepadTab("Farming")
    self:AppendNotepadText(string.format(
        "[ ] %s - TTC %s each - owned %d\n    Farm: %s",
        item.name,self:FormatGold(item.price),item.owned,item.source))
end

function KPH:RefreshGoldmakerFarming()
    local ranking=self:BuildGoldmakerFarmRanking()
    local activeMode=self.goldmakerMode=="farmActive"
    local shown={}
    if activeMode then
        local wanted={}
        for _,name in ipairs(self:GetGoldmakerFarmList()) do wanted[name]=true end
        for _,item in ipairs(ranking) do
            if wanted[item.name] then table.insert(shown,item) end
        end
    else shown=ranking end
    self.goldmakerListTitle:SetText(activeMode and "ACTIVE FARM LIST" or "BEST TO FARM")
    self.goldmakerModeButton:SetText(activeMode and "BEST TO FARM" or "ACTIVE FARM LIST")
    self.goldmakerMaterialsTitle:SetText("HOW TO FARM")
    self.goldmakerHowToFarm:SetHidden(false)
    self.goldmakerSearchContainer:SetHidden(true)
    for _,control in ipairs(self.goldmakerProductionControls) do control:SetHidden(true) end
    self.goldmakerExportButton:SetHidden(false)
    self.goldmakerDeleteButton:SetHidden(false)
    self.goldmakerExportButton:SetText("EXPORT TO FARMING NOTES")
    for index,button in ipairs(self.goldmakerPlanButtons) do
        local item=shown[index]
        if item then
            local selected=item
            local active=self:IsGoldmakerFarmActive(item.name) and " |c66CC66[ACTIVE]|r" or ""
            local color=item.confidence=="high" and "66CC66" or
                (item.confidence=="medium" and "E6A43A" or "E05A5A")
            button:SetText(string.format("|cFFFFFF%s|r%s  |c%s%s|r  |cAAAAAAscore %s|r",
                item.name,active,color,self:FormatGold(item.price),self:FormatGold(item.score)))
            button:SetHandler("OnClicked",function()
                self.goldmakerSelectedFarm=selected
                self:RefreshGoldmaker()
            end)
            button:SetHidden(false)
        else button:SetHidden(true) end
    end
    local selected=self.goldmakerSelectedFarm or shown[1]
    self.goldmakerSelectedFarm=selected
    if selected then
        local isActive=self:IsGoldmakerFarmActive(selected.name)
        self.goldmakerDeleteButton:SetText(isActive and "REMOVE FROM FARM LIST" or "ADD TO FARM LIST")
        self.goldmakerDeleteButton:SetNormalFontColor(isActive and 1 or 0.45,
            isActive and 0.4 or 1,isActive and 0.35 or 0.65,1)
        self.goldmakerTitle:SetText(selected.name)
        self.goldmakerSummary:SetText(string.format(
            "TTC value: %s each   Owned: %d   Confidence: %s\nSales signal: %d   Listings: %d   Farm score: %s",
            self:FormatGold(selected.price),selected.owned,selected.confidence,
            selected.sales,selected.listings,self:FormatGold(selected.score)))
        self.goldmakerHowToFarm:SetText(selected.source..
            "\n\nSelecting a row only shows its details. Use ADD TO FARM LIST below when you want to track it.")
    else
        self.goldmakerDeleteButton:SetHidden(true)
        self.goldmakerTitle:SetText(activeMode and "Your active farm list is empty" or "No TTC farming data")
        self.goldmakerSummary:SetText(activeMode and "Choose BEST TO FARM and click a material to add it." or
            "Update TTC price data and reopen Goldmaker.")
        self.goldmakerHowToFarm:SetText("")
    end
    for _,label in ipairs(self.goldmakerMaterialLabels) do label:SetHidden(true) end
end

function KPH:RefreshGoldmaker()
    if not self.goldmakerWindow then return end
    local farming=self.goldmakerSection=="farming"
    self.goldmakerProductionTab:SetNormalFontColor(farming and 0.65 or 1,farming and 0.65 or 0.82,0.35,1)
    self.goldmakerFarmingTab:SetNormalFontColor(farming and 1 or 0.65,farming and 0.82 or 0.65,0.35,1)
    if farming then self:RefreshGoldmakerFarming() return end
    self.goldmakerMaterialsTitle:SetText("MATERIALS — live inventory + Craft Bag")
    self.goldmakerHowToFarm:SetHidden(true)
    self.goldmakerSearchContainer:SetHidden(false)
    for _,control in ipairs(self.goldmakerProductionControls) do control:SetHidden(false) end
    self.goldmakerExportButton:SetText("EXPORT TO FARMING NOTES")
    self.goldmakerDeleteButton:SetText("DELETE PLAN")
    self.goldmakerDeleteButton:SetNormalFontColor(1,0.4,0.35,1)
    local plans=self:GetGoldmakerPlans()
    if #plans>0 and (not self.goldmakerActivePlan or
       self.goldmakerActivePlan>#plans) then self.goldmakerActivePlan=1 end
    local profitMode=self.goldmakerMode=="profit"
    local profits=profitMode and self:BuildGoldmakerProfits() or nil
    self.goldmakerListTitle:SetText(profitMode and "PROFITABLE CRAFTS" or "PRODUCTION PLANS")
    self.goldmakerModeButton:SetText(profitMode and "MY PLANS" or "PROFITABLE CRAFTS")
    for index,button in ipairs(self.goldmakerPlanButtons) do
        local plan=plans[index]
        local profit=profits and profits[index]
        if profitMode and profit then
            local selectedProfit=profit
            local color=profit.confidence=="high" and "66CC66" or
                (profit.confidence=="medium" and "E6A43A" or "E05A5A")
            button:SetText(string.format("|cFFFFFF%s|r  |c%s+%s|r  |cAAAAAA%.0f%% - %s|r",
                profit.recipe.name,color,self:FormatGold(profit.net),
                profit.margin,profit.recipe.craftType))
            button:SetHandler("OnClicked",function()
                self:AddGoldmakerRecipe(selectedProfit.recipe)
                self:SetGoldmakerMode("plans")
            end)
            button:SetHidden(false)
        elseif not profitMode and plan then
            local selectedIndex=index
            button:SetText((index==self.goldmakerActivePlan and
                "|c66CC66> " or "|cFFFFFF")..plan.name.." ×"..plan.target.."|r")
            button:SetHandler("OnClicked",function()
                self.goldmakerActivePlan=selectedIndex self:RefreshGoldmaker()
            end)
            button:SetHidden(false)
        else button:SetHidden(true) end
    end
    local plan=plans[self.goldmakerActivePlan or 1]
    local analysis=self:GetGoldmakerPlanAnalysis(plan)
    if profitMode then
        self.goldmakerTitle:SetText("Profit ranking")
        self.goldmakerSummary:SetText(#(profits or {})>0 and
            "Click a result to add it as a production plan.\nRanking uses net profit, TTC sales and market competition." or
            "No profitable crafts have complete TTC price data yet.")
        for _,label in ipairs(self.goldmakerMaterialLabels) do label:SetHidden(true) end
        return
    elseif not analysis then
        self.goldmakerTitle:SetText("Choose a known craft to create a production plan.")
        self.goldmakerSummary:SetText("Recipes and furnishing plans are indexed. Combination crafts are discovered at their crafting stations.")
        for _,label in ipairs(self.goldmakerMaterialLabels) do label:SetHidden(true) end
        return
    end
    self.goldmakerTitle:SetText(analysis.name)
    local profitText=analysis.estimatedNet and
        ("Estimated net: "..self:FormatGold(analysis.estimatedNet).." gold") or
        "Estimated net: TTC data incomplete"
    self.goldmakerSummary:SetText(string.format(
        "Target stock: %d   Owned: %d   Still needed: %d\nCraftable now: %d   Crafts needed: %d   Output/craft: %d\n%s",
        analysis.target,analysis.stock,analysis.neededItems,
        analysis.craftableItems,analysis.craftsNeeded,analysis.output,profitText))
    for index,label in ipairs(self.goldmakerMaterialLabels) do
        local material=analysis.materials[index]
        if material then
            local color=material.missing==0 and "66CC66" or "E05A5A"
            label:SetText(string.format(
                "|c%s%s|r\n|cFFFFFFOwned %d / Need %d / Missing %d|r  |c999999(Bag %d, Bank %d, Craft %d)|r\n|c66AADD%s|r",
                color,material.name,material.owned,material.required,
                material.missing,material.backpack,material.bank,
                material.craftBag,material.hint))
            label:SetHidden(false)
        else label:SetHidden(true) end
    end
end

function KPH:UpdateGoldmakerSearch(text)
    self.goldmakerSearchMatches=self:GetGoldmakerRecipeMatches(text)
    self.goldmakerSearchBackdrop:SetHidden(#self.goldmakerSearchMatches==0)
    for index,button in ipairs(self.goldmakerSearchButtons) do
        local recipe=self.goldmakerSearchMatches[index]
        if recipe then button:SetText(recipe.name) button:SetHidden(false)
        else button:SetHidden(true) end
    end
end

function KPH:ShowGoldmaker()
    self:CreateGoldmakerWindow()
    self.goldmakerWindow:SetHidden(false)
    SCENE_MANAGER:SetInUIMode(true)
    self:RefreshGoldmaker()
    zo_callLater(function()
        if self.goldmakerSearchEdit and not self.goldmakerWindow:IsHidden() then
            self.goldmakerSearchEdit:TakeFocus()
        end
    end,1)
end

function KPH:HideGoldmaker()
    if self.goldmakerSearchEdit then self.goldmakerSearchEdit:LoseFocus() end
    if self.goldmakerSearchBackdrop then self.goldmakerSearchBackdrop:SetHidden(true) end
    if self.goldmakerWindow then self.goldmakerWindow:SetHidden(true) end
end

function KPH:CreateGoldmakerWindow()
    if self.goldmakerWindow then return end
    local w=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."Goldmaker")
    w:SetDimensions(math.min(1260,GuiRoot:GetWidth()-30),760)
    if (self.savedVariables.goldmakerX or 0)>0 and
       (self.savedVariables.goldmakerY or 0)>0 then
        w:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,
            self.savedVariables.goldmakerX,self.savedVariables.goldmakerY)
    else w:SetAnchor(CENTER,GuiRoot,CENTER,0,0) end
    w:SetMouseEnabled(true) w:SetMovable(true) w:SetClampedToScreen(true) w:SetHidden(true)
    local bg=WINDOW_MANAGER:CreateControlFromVirtual(self.name.."GoldmakerBG",w,"ZO_DefaultBackdrop")
    bg:SetAnchorFill(w)
    local heading=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    heading:SetAnchor(TOPLEFT,w,TOPLEFT,22,16) heading:SetFont("ZoFontWinH1")
    heading:SetColor(1,0.78,0.25,1) heading:SetText("KEH Goldmaker — Production & Farming")
    local productionTab=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
    productionTab:SetDimensions(120,34) productionTab:SetAnchor(TOPLEFT,w,TOPLEFT,650,16)
    productionTab:SetFont("ZoFontGameBold") productionTab:SetText("PRODUCTION")
    productionTab:SetHandler("OnClicked",function() self:SetGoldmakerSection("production") end)
    local farmingTab=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
    farmingTab:SetDimensions(105,34) farmingTab:SetAnchor(LEFT,productionTab,RIGHT,8,0)
    farmingTab:SetFont("ZoFontGameBold") farmingTab:SetText("FARMING")
    farmingTab:SetHandler("OnClicked",function() self:SetGoldmakerSection("farming") end)
    local close=WINDOW_MANAGER:CreateControlFromVirtual(self.name.."GoldmakerClose",w,"ZO_CloseButton")
    close:SetAnchor(TOPRIGHT,w,TOPRIGHT,-8,8) close:SetHandler("OnClicked",function() self:HideGoldmaker() end)
    local searchBG=WINDOW_MANAGER:CreateControl(nil,w,CT_BACKDROP)
    searchBG:SetDimensions(490,38) searchBG:SetAnchor(TOPLEFT,w,TOPLEFT,22,62)
    searchBG:SetCenterColor(0,0,0,0.9) searchBG:SetEdgeColor(0.7,0.6,0.3,1)
    local edit=WINDOW_MANAGER:CreateControl(self.name.."GoldmakerSearch",searchBG,CT_EDITBOX)
    edit:SetAnchor(TOPLEFT,searchBG,TOPLEFT,9,4) edit:SetDimensions(472,30)
    edit:SetFont("ZoFontGame") edit:SetColor(1,1,1,1) edit:SetMaxInputChars(100)
    edit:SetMouseEnabled(true) edit:SetEditEnabled(true)
    edit:SetHandler("OnMouseDown",function(control) control:TakeFocus() end)
    edit:SetHandler("OnTextChanged",function(control) self:UpdateGoldmakerSearch(control:GetText()) end)
    edit:SetHandler("OnEnter",function()
        local recipe=self.goldmakerSearchMatches and self.goldmakerSearchMatches[1]
        if recipe then self:AddGoldmakerRecipe(recipe) end
    end)
    edit:SetText("")
    -- Suggestions need their own top-level window so later Goldmaker controls
    -- cannot paint over them or intercept their mouse clicks.
    local resultsBG=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."GoldmakerResults")
    resultsBG:SetDimensions(490,184) resultsBG:SetAnchor(TOPLEFT,searchBG,BOTTOMLEFT,0,2)
    resultsBG:SetDrawTier(DT_HIGH) resultsBG:SetDrawLayer(DL_OVERLAY) resultsBG:SetDrawLevel(300)
    resultsBG:SetMouseEnabled(true)
    resultsBG:SetHidden(true)
    local resultsBackdrop=WINDOW_MANAGER:CreateControlFromVirtual(
        self.name.."GoldmakerResultsBackdrop",resultsBG,"ZO_DefaultBackdrop")
    resultsBackdrop:SetAnchorFill(resultsBG)
    resultsBackdrop:SetMouseEnabled(false)
    local searchButtons={}
    for index=1,6 do
        local b=WINDOW_MANAGER:CreateControl(nil,resultsBG,CT_BUTTON)
        b:SetDimensions(470,28) b:SetAnchor(TOPLEFT,resultsBG,TOPLEFT,10,7+(index-1)*28)
        b:SetFont("ZoFontGameSmall") b:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        b:SetHandler("OnClicked",function()
            local recipe=self.goldmakerSearchMatches and self.goldmakerSearchMatches[index]
            if recipe then self:AddGoldmakerRecipe(recipe) end
        end)
        b:SetHidden(true) searchButtons[index]=b
    end
    edit:SetHandler("OnEscape",function(control)
        resultsBG:SetHidden(true)
        control:LoseFocus()
    end)
    local plansTitle=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    plansTitle:SetAnchor(TOPLEFT,w,TOPLEFT,22,300) plansTitle:SetFont("ZoFontGameBold")
    plansTitle:SetText("PRODUCTION PLANS")
    local modeButton=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
    modeButton:SetDimensions(190,32) modeButton:SetAnchor(TOPLEFT,w,TOPLEFT,930,18)
    modeButton:SetFont("ZoFontGameBold") modeButton:SetText("PROFITABLE CRAFTS")
    modeButton:SetNormalFontColor(0.45,1,0.65,1)
    modeButton:SetMouseOverFontColor(1,1,1,1)
    modeButton:SetHandler("OnClicked",function()
        if self.goldmakerSection=="farming" then
            self:SetGoldmakerMode(self.goldmakerMode=="farmActive" and "farmBest" or "farmActive")
        else
            self:SetGoldmakerMode(self.goldmakerMode=="profit" and "plans" or "profit")
        end
    end)
    local planButtons={}
    for index=1,8 do
        local b=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
        b:SetDimensions(490,34) b:SetAnchor(TOPLEFT,w,TOPLEFT,22,326+(index-1)*38)
        b:SetFont("ZoFontGame") b:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        b:SetHidden(true) planButtons[index]=b
    end
    local quantityLabel=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    quantityLabel:SetAnchor(TOPLEFT,w,TOPLEFT,22,636) quantityLabel:SetFont("ZoFontGameBold")
    quantityLabel:SetText("TARGET STOCK")
    local previous
    local quantityButtons={}
    for index,data in ipairs({{"-10",-10},{"-1",-1},{"+1",1},{"+10",10}}) do
        local b=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
        b:SetDimensions(76,34)
        if previous then b:SetAnchor(LEFT,previous,RIGHT,5,0) else b:SetAnchor(TOPLEFT,w,TOPLEFT,22,662) end
        b:SetFont("ZoFontGameBold") b:SetText(data[1])
        b:SetNormalFontColor(0.45,0.85,1,1)
        local amount=data[2] b:SetHandler("OnClicked",function() self:ChangeGoldmakerTarget(amount) end)
        table.insert(quantityButtons,b)
        previous=b
    end
    local export=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
    export:SetDimensions(275,38) export:SetAnchor(TOPLEFT,w,TOPLEFT,22,708)
    export:SetFont("ZoFontGameBold") export:SetText("EXPORT TO FARMING NOTES")
    export:SetNormalFontColor(0.45,1,0.65,1)
    export:SetHandler("OnClicked",function()
        if self.goldmakerSection=="farming" then self:ExportGoldmakerFarmToNotepad()
        else self:ExportGoldmakerToNotepad() end
    end)
    local delete=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
    delete:SetDimensions(200,38) delete:SetAnchor(LEFT,export,RIGHT,12,0)
    delete:SetFont("ZoFontGameBold") delete:SetText("DELETE PLAN")
    delete:SetNormalFontColor(1,0.4,0.35,1)
    delete:SetHandler("OnClicked",function()
        if self.goldmakerSection=="farming" then self:ToggleGoldmakerFarmItem()
        else self:DeleteGoldmakerPlan() end
    end)
    local detailTitle=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    detailTitle:SetAnchor(TOPLEFT,w,TOPLEFT,540,68) detailTitle:SetDimensions(680,32)
    detailTitle:SetFont("ZoFontWinH2") detailTitle:SetColor(1,0.85,0.35,1)
    local summary=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    summary:SetAnchor(TOPLEFT,w,TOPLEFT,540,106) summary:SetDimensions(680,78)
    summary:SetFont("ZoFontGame") summary:SetColor(1,1,1,1)
    local materialsTitle=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    materialsTitle:SetAnchor(TOPLEFT,w,TOPLEFT,540,190) materialsTitle:SetFont("ZoFontGameBold")
    materialsTitle:SetText("MATERIALS — live inventory + Craft Bag")
    local howToFarm=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    howToFarm:SetAnchor(TOPLEFT,w,TOPLEFT,540,220)
    howToFarm:SetDimensions(680,100) howToFarm:SetFont("ZoFontGame")
    howToFarm:SetColor(0.75,0.9,1,1) howToFarm:SetHidden(true)
    local materialLabels={}
    for index=1,8 do
        local label=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
        label:SetAnchor(TOPLEFT,w,TOPLEFT,540,218+(index-1)*54)
        label:SetDimensions(680,52) label:SetFont("ZoFontGameSmall")
        label:SetHidden(true) materialLabels[index]=label
    end
    w:SetHandler("OnMoveStop",function(control)
        self.savedVariables.goldmakerX=control:GetLeft()
        self.savedVariables.goldmakerY=control:GetTop()
    end)
    self.goldmakerWindow=w self.goldmakerSearchEdit=edit
    self.goldmakerSearchBackdrop=resultsBG self.goldmakerSearchButtons=searchButtons
    self.goldmakerPlanButtons=planButtons self.goldmakerTitle=detailTitle
    self.goldmakerSummary=summary self.goldmakerMaterialLabels=materialLabels
    self.goldmakerListTitle=plansTitle self.goldmakerModeButton=modeButton
    self.goldmakerMode=self.goldmakerMode or "plans"
    self.goldmakerSection=self.goldmakerSection or "production"
    self.goldmakerSearchContainer=searchBG
    self.goldmakerProductionTab=productionTab self.goldmakerFarmingTab=farmingTab
    self.goldmakerProductionControls={quantityLabel}
    for _,control in ipairs(quantityButtons) do table.insert(self.goldmakerProductionControls,control) end
    self.goldmakerExportButton=export self.goldmakerDeleteButton=delete
    self.goldmakerMaterialsTitle=materialsTitle self.goldmakerHowToFarm=howToFarm
end

function KPH:InitializeGoldmaker()
    self:GetGoldmakerPlans()
    SLASH_COMMANDS["/kehgold"]=function() self:ShowGoldmaker() end
    EVENT_MANAGER:RegisterForEvent(self.name.."GoldmakerInventory",
        EVENT_INVENTORY_SINGLE_SLOT_UPDATE,function()
            if self.goldmakerWindow and not self.goldmakerWindow:IsHidden() then
                zo_callLater(function() self:RefreshGoldmaker() end,100)
            end
        end)
end

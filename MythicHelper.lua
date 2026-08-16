local KPH = KjellmanESOHelper

local function Clean(value)
    return zo_strformat("<<C:1>>", value or "")
end

-- LibLeadDrop 1.0.0 predates Shattered Paths Signet. Keep these keyed by the
-- localized English lead names returned by the current game data so the helper
-- remains useful until the shared library publishes matching antiquity IDs.
local LEAD_HINT_FALLBACKS={
    ["flickering charcoal rubbings"]="Daedroth Larder World Boss, Coldharbour",
    ["fractured prismatic gem"]="Cynhamoth's Grove World Boss, Coldharbour",
    ["nugget of aetheric gold"]="Aba-Loria delve boss, Coldharbour",
    ["ossein ring mold"]="City of Ash II, chest after the final boss",
    ["starlight oil"]="The Wailing Maw delve boss, Coldharbour",
}

local function GetDropHint(antiquityId)
    if LibLeadDrop and LibLeadDrop.getLeadDropHint then
        local hint = LibLeadDrop.getLeadDropHint(antiquityId)
        if hint and hint ~= "" then return hint end
    end
    local leadName=zo_strlower(GetAntiquityName(antiquityId) or "")
    local fallback=LEAD_HINT_FALLBACKS[leadName]
    if fallback then return fallback end
    return "Exakt dropkälla kräver LibLeadDrop"
end

function KPH:BuildMythicIndex()
    if self.mythicIndex then return self.mythicIndex end
    local sets = {}
    local antiquityId = GetNextAntiquityId()
    while antiquityId do
        local setId = GetAntiquitySetId(antiquityId)
        if setId and setId > 0 and GetNumAntiquitySetAntiquities(setId) == 5 then
            sets[setId] = true
        end
        antiquityId = GetNextAntiquityId(antiquityId)
    end
    self.mythicIndex = {}
    for setId in pairs(sets) do
        local name = GetAntiquitySetName(setId)
        if name and name ~= "" then
            table.insert(self.mythicIndex, { id=setId, name=Clean(name), lower=zo_strlower(name) })
        end
    end
    table.sort(self.mythicIndex, function(a,b) return a.lower < b.lower end)
    return self.mythicIndex
end

function KPH:FindMythic(searchText)
    local needle = zo_strlower(zo_strtrim(searchText or ""))
    if needle == "" then return nil, {} end
    local matches, exact = {}, nil
    for _,entry in ipairs(self:BuildMythicIndex()) do
        if entry.lower == needle then exact = entry
        elseif string.find(entry.lower,needle,1,true) then table.insert(matches,entry) end
    end
    if exact then return exact,{exact} end
    if #matches == 1 then return matches[1],matches end
    return nil,matches
end

function KPH:BuildMythicText(setId)
    if not setId or setId <= 0 then
        return "|cE89B35Sök efter en Mythic ovan.|r\n\nExempel: Oakensoul, Pale Order eller Velothi."
    end
    local total = GetNumAntiquitySetAntiquities(setId)
    local owned = 0
    local lines = { string.format("|cFFFFFF%s|r",Clean(GetAntiquitySetName(setId))), "" }
    for index=1,total do
        local antiquityId = GetAntiquitySetAntiquityId(setId,index)
        local recovered = (GetNumAntiquitiesRecovered(antiquityId) or 0) > 0
        local hasLead = DoesAntiquityHaveLead(antiquityId)
        local marker,status
        if recovered then
            marker,status="|c66CC66✓|r","|c66CC66HITTAD|r"
            owned=owned+1
        elseif hasLead then marker,status="|cE89B35●|r","|cE89B35LEAD FINNS – SCRYA|r"
        else marker,status="|cE05A5A✗|r","|cE05A5ASAKNAS – LETA|r" end
        local zoneId=GetAntiquityZoneId(antiquityId)
        local zone=zoneId and Clean(GetZoneNameById(zoneId)) or "Okänd zon"
        table.insert(lines,string.format("%s |cFFFFFF%s|r  %s",marker,Clean(GetAntiquityName(antiquityId)),status))
        table.insert(lines,string.format("    |c8CC8FF%s|r — %s",zone,GetDropHint(antiquityId)))
        table.insert(lines,"")
    end
    table.insert(lines,2,string.format("|cAAAAAAFramsteg: %d/%d delar|r",owned,total))
    if not (LibLeadDrop and LibLeadDrop.getLeadDropHint) then
        table.insert(lines,"|c888888Installera LibLeadDrop för exakta dropkällor för alla leads.|r")
    end
    return table.concat(lines,"\n")
end

function KPH:SearchMythic(text)
    local match,matches=self:FindMythic(text)
    if match then
        self.savedVariables.plannedMythicSetId=match.id
        self.mythicHelperText:SetText(self:BuildMythicText(match.id))
        self:SelectMythicTab("details")
    elseif #matches>1 then
        local names={}
        for i=1,math.min(12,#matches) do table.insert(names,"• "..matches[i].name) end
        self.mythicHelperText:SetText("|cE89B35Flera Mythics matchar. Skriv mer exakt:|r\n\n"..table.concat(names,"\n"))
    else self.mythicHelperText:SetText("|cE05A5AIngen Mythic hittades.|r") end
end

function KPH:GetMythicRecoveredCount(setId)
    local recovered=0
    local hasLead=false
    local total=GetNumAntiquitySetAntiquities(setId)
    for index=1,total do
        local antiquityId=GetAntiquitySetAntiquityId(setId,index)
        if (GetNumAntiquitiesRecovered(antiquityId) or 0)>0 then
            recovered=recovered+1
        end
        if DoesAntiquityHaveLead(antiquityId) then hasLead=true end
    end
    return recovered,total,hasLead
end

function KPH:GetMythicItemLink(antiquitySetId)
    self.mythicItemLinks=self.mythicItemLinks or {}
    if self.mythicItemLinks[antiquitySetId]~=nil then
        return self.mythicItemLinks[antiquitySetId] or nil
    end
    local target=zo_strlower(GetAntiquitySetName(antiquitySetId) or "")
    local itemSetId=GetNextItemSetCollectionId(nil)
    while itemSetId do
        if zo_strlower(GetItemSetName(itemSetId) or "")==target then
            local numPieces=GetNumItemSetCollectionPieces(itemSetId)
            for index=1,numPieces do
                local pieceId=GetItemSetCollectionPieceInfo(itemSetId,index)
                local link=GetItemSetCollectionPieceItemLink(pieceId,
                    LINK_STYLE_DEFAULT,ITEM_TRAIT_TYPE_NONE,
                    ITEM_FUNCTIONAL_QUALITY_LEGENDARY)
                if link and link~="" then
                    self.mythicItemLinks[antiquitySetId]=link
                    return link
                end
            end
        end
        itemSetId=GetNextItemSetCollectionId(itemSetId)
    end
    self.mythicItemLinks[antiquitySetId]=false
end

function KPH:ShowMythicTooltip(control)
    local link=self:GetMythicItemLink(control.kehMythicSetId)
    if link and ItemTooltip then
        InitializeTooltip(ItemTooltip,control,RIGHT,-8,0,LEFT)
        ItemTooltip:SetLink(link)
    end
end

function KPH:RefreshMythicList()
    if not self.mythicListButtons then return end
    local entries=self:BuildMythicIndex()
    for index,button in ipairs(self.mythicListButtons) do
        local entry=entries[index]
        if entry then
            local recovered,total,hasLead=self:GetMythicRecoveredCount(entry.id)
            button:SetText(string.format("[%d/%d] %s",recovered,total,entry.name))
            if recovered==total then
                button:SetNormalFontColor(0.35,0.95,0.35,1)
            elseif recovered>0 or hasLead then
                button:SetNormalFontColor(0.95,0.62,0.18,1)
            else
                button:SetNormalFontColor(0.95,0.3,0.3,1)
            end
            button:SetMouseOverFontColor(1,1,1,1)
            button:SetHidden(false)
        else button:SetHidden(true) end
    end
end

function KPH:SelectMythicTab(tabName)
    if not self.mythicDetailsPanel then return end
    local showDetails=tabName~="list"
    self.mythicDetailsPanel:SetHidden(not showDetails)
    self.mythicListPanel:SetHidden(showDetails)
    self.mythicDetailsTab:SetNormalFontColor(
        showDetails and 1 or 0.65,showDetails and 0.85 or 0.65,
        showDetails and 0.35 or 0.65,1)
    self.mythicListTab:SetNormalFontColor(
        showDetails and 0.65 or 1,showDetails and 0.65 or 0.85,
        showDetails and 0.65 or 0.35,1)
    if not showDetails then self:RefreshMythicList() end
end

function KPH:CreateMythicHelperWindow()
    if self.mythicHelperWindow then return end
    local w=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."MythicHelper")
    w:SetDimensions(860,760) w:SetAnchor(CENTER,GuiRoot,CENTER,0,0)
    w:SetClampedToScreen(true) w:SetMouseEnabled(true) w:SetMovable(true) w:SetHidden(true)
    local bg=WINDOW_MANAGER:CreateControlFromVirtual(nil,w,"ZO_DefaultBackdrop") bg:SetAnchorFill(w)
    local title=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    title:SetAnchor(TOPLEFT,w,TOPLEFT,24,18) title:SetFont("ZoFontWinH1") title:SetText("KEH Mythic Helper")
    local close=WINDOW_MANAGER:CreateControlFromVirtual(nil,w,"ZO_CloseButton")
    close:SetAnchor(TOPRIGHT,w,TOPRIGHT,-8,8) close:SetHandler("OnClicked",function() w:SetHidden(true) end)
    local detailsTab=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
    detailsTab:SetDimensions(180,32) detailsTab:SetAnchor(TOPLEFT,w,TOPLEFT,24,58)
    detailsTab:SetFont("ZoFontGameBold") detailsTab:SetText("DETALJER")
    local listTab=WINDOW_MANAGER:CreateControl(nil,w,CT_BUTTON)
    listTab:SetDimensions(180,32) listTab:SetAnchor(LEFT,detailsTab,RIGHT,8,0)
    listTab:SetFont("ZoFontGameBold") listTab:SetText("ALLA MYTHICS")

    local detailsPanel=WINDOW_MANAGER:CreateControl(nil,w,CT_CONTROL)
    detailsPanel:SetAnchor(TOPLEFT,w,TOPLEFT,0,96)
    detailsPanel:SetAnchor(BOTTOMRIGHT,w,BOTTOMRIGHT,0,0)
    local editBg=WINDOW_MANAGER:CreateControlFromVirtual(nil,detailsPanel,"ZO_EditBackdrop")
    editBg:SetDimensions(590,38) editBg:SetAnchor(TOPLEFT,detailsPanel,TOPLEFT,24,0)
    local edit=WINDOW_MANAGER:CreateControlFromVirtual(nil,editBg,"ZO_DefaultEditForBackdrop")
    edit:SetAnchorFill(editBg) edit:SetMaxInputChars(80)
    edit:SetHandler("OnEnter",function(c) self:SearchMythic(c:GetText()) end)
    local search=WINDOW_MANAGER:CreateControlFromVirtual(nil,detailsPanel,"ZO_DefaultButton")
    search:SetDimensions(190,38) search:SetAnchor(LEFT,editBg,RIGHT,14,0) search:SetText("Sök Mythic")
    search:SetHandler("OnClicked",function() self:SearchMythic(edit:GetText()) end)
    local result=WINDOW_MANAGER:CreateControl(nil,detailsPanel,CT_LABEL)
    result:SetAnchor(TOPLEFT,detailsPanel,TOPLEFT,24,58)
    result:SetAnchor(BOTTOMRIGHT,detailsPanel,BOTTOMRIGHT,-24,-20)
    result:SetFont("ZoFontGame") result:SetVerticalAlignment(TEXT_ALIGN_TOP) result:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local listPanel=WINDOW_MANAGER:CreateControl(nil,w,CT_CONTROL)
    listPanel:SetAnchor(TOPLEFT,w,TOPLEFT,0,96)
    listPanel:SetAnchor(BOTTOMRIGHT,w,BOTTOMRIGHT,0,0)
    listPanel:SetHidden(true)
    local listHelp=WINDOW_MANAGER:CreateControl(nil,listPanel,CT_LABEL)
    listHelp:SetAnchor(TOPLEFT,listPanel,TOPLEFT,24,4)
    listHelp:SetFont("ZoFontGame")
    listHelp:SetText("|c66CC66Grön = komplett|r   |cE89B35Orange = påbörjad|r   |cE05A5ARöd = inga delar|r   Klicka för detaljer")
    local entries=self:BuildMythicIndex()
    local columns=3
    local rows=math.ceil(#entries/columns)
    self.mythicListButtons={}
    for index,entry in ipairs(entries) do
        local column=math.floor((index-1)/rows)
        local row=(index-1)%rows
        local button=WINDOW_MANAGER:CreateControl(
            self.name.."MythicList"..index,listPanel,CT_BUTTON)
        button:SetDimensions(260,24)
        button:SetAnchor(TOPLEFT,listPanel,TOPLEFT,24+column*272,38+row*25)
        button:SetFont("ZoFontGameSmall")
        button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        button.kehMythicSetId=entry.id
        button.kehMythicName=entry.name
        button:SetHandler("OnClicked",function(control)
            self.savedVariables.plannedMythicSetId=control.kehMythicSetId
            edit:SetText(control.kehMythicName)
            result:SetText(self:BuildMythicText(control.kehMythicSetId))
            self:SelectMythicTab("details")
        end)
        button:SetHandler("OnMouseEnter",function(control)
            self:ShowMythicTooltip(control)
        end)
        button:SetHandler("OnMouseExit",function()
            if ItemTooltip then ClearTooltip(ItemTooltip) end
        end)
        table.insert(self.mythicListButtons,button)
    end
    detailsTab:SetHandler("OnClicked",function() self:SelectMythicTab("details") end)
    listTab:SetHandler("OnClicked",function() self:SelectMythicTab("list") end)
    self.mythicDetailsPanel,self.mythicListPanel=detailsPanel,listPanel
    self.mythicDetailsTab,self.mythicListTab=detailsTab,listTab
    self.mythicHelperWindow,self.mythicHelperEdit,self.mythicHelperText=w,edit,result
    self:SelectMythicTab("details")
end

function KPH:ShowMythicHelper(searchText)
    self:CreateMythicHelperWindow() self.mythicHelperWindow:SetHidden(false)
    if searchText and zo_strtrim(searchText)~="" then
        self.mythicHelperEdit:SetText(searchText) self:SearchMythic(searchText)
    else
        self.mythicHelperText:SetText(self:BuildMythicText(self.savedVariables.plannedMythicSetId))
        self.mythicHelperEdit:TakeFocus()
    end
end

function KPH:InitializeMythicHelper()
    SLASH_COMMANDS["/kehmythic"]=function(text) self:ShowMythicHelper(text) end
    if EVENT_ANTIQUITY_LEAD_ACQUIRED then
        EVENT_MANAGER:RegisterForEvent(self.name.."MythicUpdated",EVENT_ANTIQUITY_LEAD_ACQUIRED,function()
            if self.mythicHelperWindow and not self.mythicHelperWindow:IsHidden() then
                self.mythicHelperText:SetText(self:BuildMythicText(self.savedVariables.plannedMythicSetId))
                self:RefreshMythicList()
            end
        end)
    end
end

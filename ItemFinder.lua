local KPH=KjellmanESOHelper

local function NormalizeLocationName(value)
    return zo_strlower(zo_strtrim(zo_strformat("<<C:1>>",value or "")))
end

local function FindZoneForCollectionNames(setId,names)
    if type(GetNumZones)~="function" or type(GetZoneNameByIndex)~="function" or
       type(GetZoneId)~="function" then return nil end
    local wanted={}
    for _,name in ipairs(names) do wanted[NormalizeLocationName(name)]=true end
    local setType=GetItemSetType(setId)
    local instanceType=setType==ITEM_SET_TYPE_DUNGEON or
        setType==ITEM_SET_TYPE_MONSTER or setType==ITEM_SET_TYPE_WEAPON
    local leafName=NormalizeLocationName(names[#names])
    local matchedZoneId,instanceZoneId
    for zoneIndex=1,GetNumZones() do
        local zoneName=GetZoneNameByIndex(zoneIndex)
        local normalizedZone=NormalizeLocationName(zoneName)
        if wanted[normalizedZone] then
            matchedZoneId=GetZoneId(zoneIndex)
            break
        elseif instanceType and leafName~="" and
               string.sub(normalizedZone,1,#leafName+1)==leafName.." " then
            -- A shared collection category such as "Fungal Grotto" maps to
            -- separate instance zones named "Fungal Grotto I" and "II".
            instanceZoneId=instanceZoneId or GetZoneId(zoneIndex)
        end
    end
    matchedZoneId=matchedZoneId or instanceZoneId
    if not matchedZoneId or matchedZoneId==0 then return nil end
    if instanceType and type(GetParentZoneId)=="function" then
        local parentId=GetParentZoneId(matchedZoneId)
        if parentId and parentId~=0 and parentId~=matchedZoneId then
            matchedZoneId=parentId
        end
    elseif type(GetZoneStoryZoneIdForZoneId)=="function" then
        local storyZoneId=GetZoneStoryZoneIdForZoneId(matchedZoneId)
        if storyZoneId and storyZoneId~=0 then matchedZoneId=storyZoneId end
    end
    local zoneName=type(GetZoneNameById)=="function" and
        GetZoneNameById(matchedZoneId) or nil
    return zoneName and zoneName~="" and zo_strformat("<<C:1>>",zoneName) or nil
end

local function CollectionLocation(setId)
    setId=KPH:CanonicalizeSetId(setId)
    local names=KPH:GetSetCollectionNames(setId)
    local location=KPH:GetSetCollectionLocation(setId)
    local zone=FindZoneForCollectionNames(setId,names)
    if not zone and #names>0 and GetItemSetType(setId)==ITEM_SET_TYPE_WORLD then
        zone=names[#names]
    end
    return location,zone or "Unknown zone"
end

local function PieceSource(setId,itemLink)
    return KPH:GetSetPieceSource(setId,itemLink)
end

local function GeneralSource(setId)
    return KPH:GetSetGeneralSource(setId)
end

function KPH:FindItemLocations(search)
    local query=zo_strtrim(search or "")
    local needle=zo_strlower(query)
    local results={}
    if #needle<3 then return results,"Enter at least 3 characters." end
    self:GetBuildSetMatches(needle)
    local candidates={}
    for _,entry in ipairs(self.buildSetSearchIndex or {}) do
        if string.find(entry.lower,needle,1,true) or
           string.find(needle,entry.lower,1,true) then
            table.insert(candidates,entry)
        end
    end
    table.sort(candidates,function(a,b)
        local aExact=a.lower==needle
        local bExact=b.lower==needle
        if aExact~=bExact then return aExact end
        return a.name<b.name
    end)
    for _,entry in ipairs(candidates) do
        local resolvedSetId=self:CanonicalizeSetId(entry.id,entry.name)
        local bestLink,bestName
        for index=1,(GetNumItemSetCollectionPieces(resolvedSetId) or 0) do
            local pieceId=GetItemSetCollectionPieceInfo(resolvedSetId,index)
            local link=GetItemSetCollectionPieceItemLink(pieceId,LINK_STYLE_DEFAULT,
                ITEM_TRAIT_TYPE_NONE,ITEM_FUNCTIONAL_QUALITY_MAGIC)
            if link and link~="" then
                local pieceName=zo_strformat("<<C:1>>",GetItemLinkName(link))
                local pieceLower=zo_strlower(pieceName)
                if pieceLower==needle or string.find(pieceLower,needle,1,true) or
                   string.find(needle,pieceLower,1,true) then
                    bestLink,bestName=link,pieceName
                    if pieceLower==needle then break end
                end
            end
        end
        local location,zone=CollectionLocation(resolvedSetId)
        table.insert(results,{
            setId=resolvedSetId,
            name=bestName or entry.name,
            setName=entry.name,
            location=location,
            zone=zone,
            source=bestLink and PieceSource(resolvedSetId,bestLink) or
                GeneralSource(resolvedSetId),
        })
        if #results>=8 then break end
    end
    if #results==0 then
        return results,"No set item found. Try the set name, e.g. Briarheart."
    end
    return results
end

function KPH:RefreshItemFinder()
    local results,message=self:FindItemLocations(self.itemFinderEdit:GetText())
    self.itemFinderMessage:SetText(message or
        string.format("%d result%s",#results,#results==1 and "" or "s"))
    for index,button in ipairs(self.itemFinderResults) do
        local result=results[index]
        if result then
            local setText=result.name==result.setName and "" or
                "  |cAAAAAA["..result.setName.."]|r"
            button:SetText(string.format(
                "|cFFFFFF%s|r%s  |cD6B35A[CLICK: ADD TO SET TRACKER]|r\n|cD6B35A%s|r  |cAAAAAA- %s|r  |c66AADDZone: %s|r",
                result.name,setText,result.location,result.source,result.zone))
            button.kehSetId=result.setId
            button:SetHidden(false)
        else button.kehSetId=nil button:SetHidden(true) end
    end
end

function KPH:HideItemFinder()
    if self.itemFinderEdit then self.itemFinderEdit:LoseFocus() end
    if self.itemFinderWindow then self.itemFinderWindow:SetHidden(true) end
    SCENE_MANAGER:SetInUIMode(false)
end

function KPH:ShowItemFinder()
    self:CreateItemFinderWindow()
    self.itemFinderWindow:SetHidden(false)
    SCENE_MANAGER:SetInUIMode(true)
    self.itemFinderEdit:TakeFocus()
end

function KPH:CreateItemFinderWindow()
    if self.itemFinderWindow then return end
    local w=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."ItemFinder")
    w:SetDimensions(math.min(1000,GuiRoot:GetWidth()-40),560)
    w:SetAnchor(CENTER,GuiRoot,CENTER,0,0)
    w:SetClampedToScreen(true)
    w:SetMouseEnabled(true)
    w:SetMovable(true)
    w:SetHidden(true)
    local bg=WINDOW_MANAGER:CreateControlFromVirtual(
        self.name.."ItemFinderBG",w,"ZO_DefaultBackdrop")
    bg:SetAnchorFill(w)
    local title=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    title:SetAnchor(TOPLEFT,w,TOPLEFT,24,18)
    title:SetFont("ZoFontWinH1")
    title:SetText("KEH Item Finder")
    local close=WINDOW_MANAGER:CreateControlFromVirtual(
        self.name.."ItemFinderClose",w,"ZO_CloseButton")
    close:SetAnchor(TOPRIGHT,w,TOPRIGHT,-8,8)
    close:SetHandler("OnClicked",function() self:HideItemFinder() end)
    local help=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    help:SetAnchor(TOPLEFT,title,BOTTOMLEFT,0,8)
    help:SetFont("ZoFontGame")
    help:SetText("Enter an English item or set name to find where it drops.")
    local editBG=WINDOW_MANAGER:CreateControl(nil,w,CT_BACKDROP)
    editBG:SetDimensions(720,40)
    editBG:SetAnchor(TOPLEFT,w,TOPLEFT,24,88)
    editBG:SetCenterColor(0,0,0,0.9)
    editBG:SetEdgeColor(0.7,0.65,0.45,1)
    local edit=WINDOW_MANAGER:CreateControl(
        self.name.."ItemFinderEdit",editBG,CT_EDITBOX)
    edit:SetAnchor(TOPLEFT,editBG,TOPLEFT,10,5)
    edit:SetDimensions(700,30)
    edit:SetFont("ZoFontGame")
    edit:SetColor(1,1,1,1)
    edit:SetMaxInputChars(120)
    edit:SetMouseEnabled(true)
    edit:SetEditEnabled(true)
    local search=WINDOW_MANAGER:CreateControl(
        self.name.."ItemFinderSearch",w,CT_BUTTON)
    search:SetDimensions(190,40)
    search:SetAnchor(LEFT,editBG,RIGHT,16,0)
    search:SetFont("ZoFontGameBold")
    search:SetText("Search")
    search:SetNormalFontColor(1,0.85,0.35,1)
    search:SetMouseOverFontColor(1,1,1,1)
    search:SetHandler("OnClicked",function() self:RefreshItemFinder() end)
    edit:SetHandler("OnEnter",function() self:RefreshItemFinder() end)
    edit:SetHandler("OnEscape",function() self:HideItemFinder() end)
    local message=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    message:SetAnchor(TOPLEFT,editBG,BOTTOMLEFT,0,10)
    message:SetDimensions(900,24)
    message:SetFont("ZoFontGameSmall")
    message:SetColor(0.75,0.75,0.75,1)
    local resultButtons={}
    for index=1,8 do
        local button=WINDOW_MANAGER:CreateControl(
            self.name.."ItemFinderResult"..index,w,CT_BUTTON)
        button:SetDimensions(940,48)
        button:SetAnchor(TOPLEFT,w,TOPLEFT,24,158+(index-1)*48)
        button:SetFont("ZoFontGameSmall")
        button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        button:SetVerticalAlignment(TEXT_ALIGN_CENTER)
        button:SetHandler("OnClicked",function(control)
            if control.kehSetId then self:AddSetTrackerSet(control.kehSetId,true) end
        end)
        button:SetHidden(true)
        resultButtons[index]=button
    end
    self.itemFinderWindow=w
    self.itemFinderEdit=edit
    self.itemFinderMessage=message
    self.itemFinderResults=resultButtons
end

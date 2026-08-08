local KPH=KjellmanESOHelper

local function NormalizeLocationName(value)
    return zo_strlower(zo_strtrim(zo_strformat("<<C:1>>",value or "")))
end

local function FindZoneForCollectionNames(setId,names)
    if type(GetNumZones)~="function" or type(GetZoneNameByIndex)~="function" or
       type(GetZoneId)~="function" then return nil end
    local wanted={}
    for _,name in ipairs(names) do wanted[NormalizeLocationName(name)]=true end
    local matchedZoneId
    for zoneIndex=1,GetNumZones() do
        local zoneName=GetZoneNameByIndex(zoneIndex)
        if wanted[NormalizeLocationName(zoneName)] then
            matchedZoneId=GetZoneId(zoneIndex)
        end
    end
    if not matchedZoneId or matchedZoneId==0 then return nil end
    local storyZoneId=type(GetZoneStoryZoneIdForZoneId)=="function" and
        GetZoneStoryZoneIdForZoneId(matchedZoneId) or nil
    local usedStoryZone=storyZoneId and storyZoneId~=0
    if usedStoryZone then matchedZoneId=storyZoneId end
    local setType=GetItemSetType(setId)
    if (setType==ITEM_SET_TYPE_DUNGEON or setType==ITEM_SET_TYPE_MONSTER or
        setType==ITEM_SET_TYPE_WEAPON) and not usedStoryZone and
        type(GetParentZoneId)=="function" then
        local parentId=GetParentZoneId(matchedZoneId)
        if parentId and parentId~=0 then matchedZoneId=parentId end
    end
    local zoneName=type(GetZoneNameById)=="function" and
        GetZoneNameById(matchedZoneId) or nil
    return zoneName and zoneName~="" and zo_strformat("<<C:1>>",zoneName) or nil
end

local function CollectionLocation(setId)
    local names={}
    local categoryId=GetItemSetCollectionCategoryId(setId)
    local safety=0
    while categoryId and categoryId>0 and safety<8 do
        local name=GetItemSetCollectionCategoryName(categoryId)
        if name and name~="" then table.insert(names,1,name) end
        categoryId=GetItemSetCollectionCategoryParentId(categoryId)
        safety=safety+1
    end
    local location=#names>0 and table.concat(names," > ") or "Unknown location"
    local zone=FindZoneForCollectionNames(setId,names)
    if not zone and GetItemSetType(setId)==ITEM_SET_TYPE_WORLD and #names>0 then
        zone=names[#names]
    end
    return location,zone or "Unknown zone"
end

local function PieceSource(setId,itemLink)
    local setType=GetItemSetType(setId)
    local equip=GetItemLinkEquipType(itemLink)
    local weapon=GetItemLinkWeaponType(itemLink)
    local isWeapon=weapon and weapon~=WEAPONTYPE_NONE
    if ITEM_SET_TYPE_MYTHIC and setType==ITEM_SET_TYPE_MYTHIC then
        return "Antiquities leads (often several zones)"
    elseif setType==ITEM_SET_TYPE_WORLD then
        if equip==EQUIP_TYPE_WAIST or equip==EQUIP_TYPE_FEET then return "Delve boss" end
        if equip==EQUIP_TYPE_HEAD or equip==EQUIP_TYPE_CHEST or
           equip==EQUIP_TYPE_LEGS then return "World boss" end
        if equip==EQUIP_TYPE_SHOULDERS or equip==EQUIP_TYPE_HAND then
            return "Public dungeon boss"
        end
        if equip==EQUIP_TYPE_RING or equip==EQUIP_TYPE_NECK then
            return "Dark Anchor / zone world event"
        end
        if isWeapon then return "World boss / public dungeon boss" end
        return "Overland activity / treasure chest"
    elseif setType==ITEM_SET_TYPE_DUNGEON then
        if isWeapon or equip==EQUIP_TYPE_RING or equip==EQUIP_TYPE_NECK then
            return "Dungeon final boss"
        end
        if equip==EQUIP_TYPE_WAIST or equip==EQUIP_TYPE_HAND or
           equip==EQUIP_TYPE_FEET then return "Dungeon mini-bosses" end
        return "Dungeon bosses"
    elseif setType==ITEM_SET_TYPE_MONSTER then
        if equip==EQUIP_TYPE_HEAD then return "Veteran dungeon final boss" end
        return "Undaunted shoulder coffer"
    elseif setType==ITEM_SET_TYPE_CRAFTED then return "Crafting station"
    elseif setType==ITEM_SET_TYPE_WEAPON then return "Arena / special activity"
    end
    return "Set activity"
end

local function GeneralSource(setId)
    local setType=GetItemSetType(setId)
    if ITEM_SET_TYPE_MYTHIC and setType==ITEM_SET_TYPE_MYTHIC then
        return "Antiquities leads (often several zones)"
    elseif setType==ITEM_SET_TYPE_WORLD then
        return "Overland bosses, delves, public dungeons and world events"
    elseif setType==ITEM_SET_TYPE_DUNGEON then
        return "Dungeon bosses; weapons and jewelry from the final boss"
    elseif setType==ITEM_SET_TYPE_MONSTER then
        return "Head: veteran final boss. Shoulder: Undaunted coffer"
    elseif setType==ITEM_SET_TYPE_CRAFTED then return "Crafting station"
    elseif setType==ITEM_SET_TYPE_WEAPON then return "Arena / special activity"
    end
    return "Set activity"
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
        local bestLink,bestName
        for index=1,GetNumItemSetCollectionPieces(entry.id) do
            local pieceId=GetItemSetCollectionPieceInfo(entry.id,index)
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
        local location,zone=CollectionLocation(entry.id)
        table.insert(results,{
            setId=entry.id,
            name=bestName or entry.name,
            setName=entry.name,
            location=location,
            zone=zone,
            source=bestLink and PieceSource(entry.id,bestLink) or
                GeneralSource(entry.id),
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
            button:SetText(string.format("|cFFFFFF%s|r%s\n|cD6B35A%s|r  |cAAAAAA— %s|r",
                result.name,setText,result.location,result.source))
            button:SetText(string.format(
                "|cFFFFFF%s|r%s\n|cD6B35A%s|r  |cAAAAAA- %s|r  |c66AADDZone: %s|r",
                result.name,setText,result.location,result.source,result.zone))
            button:SetHidden(false)
        else button:SetHidden(true) end
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
        button:SetHidden(true)
        resultButtons[index]=button
    end
    self.itemFinderWindow=w
    self.itemFinderEdit=edit
    self.itemFinderMessage=message
    self.itemFinderResults=resultButtons
end

local KPH = KjellmanESOHelper

local SLOTS = {
    { key="head", name="Head", equip=EQUIP_TYPE_HEAD },
    { key="shoulders", name="Shoulders", equip=EQUIP_TYPE_SHOULDERS },
    { key="chest", name="Chest", equip=EQUIP_TYPE_CHEST },
    { key="hands", name="Hands", equip=EQUIP_TYPE_HAND },
    { key="waist", name="Waist", equip=EQUIP_TYPE_WAIST },
    { key="legs", name="Legs", equip=EQUIP_TYPE_LEGS },
    { key="feet", name="Feet", equip=EQUIP_TYPE_FEET },
    { key="neck", name="Neck", equip=EQUIP_TYPE_NECK },
    { key="ring1", name="Ring 1", equip=EQUIP_TYPE_RING },
    { key="ring2", name="Ring 2", equip=EQUIP_TYPE_RING },
    { key="frontMain", name="Front bar – weapon", weapon=true, bar=1 },
    { key="frontOff", name="Front bar – offhand", offhand=true, bar=1 },
    { key="backMain", name="Back bar – weapon", weapon=true, bar=2 },
    { key="backOff", name="Back bar – offhand", offhand=true, bar=2 },
}

local ONE_HAND = {
    [WEAPONTYPE_AXE]=true, [WEAPONTYPE_HAMMER]=true,
    [WEAPONTYPE_SWORD]=true, [WEAPONTYPE_DAGGER]=true,
}

local ARMOR_EQUIP_TYPES = {
    [EQUIP_TYPE_HEAD]=true, [EQUIP_TYPE_SHOULDERS]=true,
    [EQUIP_TYPE_CHEST]=true, [EQUIP_TYPE_HAND]=true,
    [EQUIP_TYPE_WAIST]=true, [EQUIP_TYPE_LEGS]=true,
    [EQUIP_TYPE_FEET]=true,
}

local GENERIC_WEAPONS = {
    WEAPONTYPE_SWORD, WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_DAGGER,
    WEAPONTYPE_TWO_HANDED_SWORD, WEAPONTYPE_TWO_HANDED_AXE,
    WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_BOW, WEAPONTYPE_FIRE_STAFF,
    WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF,
    WEAPONTYPE_HEALING_STAFF,
}

local IMPORT_WEAPON_TYPES = {
    sword=WEAPONTYPE_SWORD,
    axe=WEAPONTYPE_AXE,
    mace=WEAPONTYPE_HAMMER,
    dagger=WEAPONTYPE_DAGGER,
    greatsword=WEAPONTYPE_TWO_HANDED_SWORD,
    battleaxe=WEAPONTYPE_TWO_HANDED_AXE,
    maul=WEAPONTYPE_TWO_HANDED_HAMMER,
    bow=WEAPONTYPE_BOW,
    infernostaff=WEAPONTYPE_FIRE_STAFF,
    firestaff=WEAPONTYPE_FIRE_STAFF,
    icestaff=WEAPONTYPE_FROST_STAFF,
    froststaff=WEAPONTYPE_FROST_STAFF,
    lightningstaff=WEAPONTYPE_LIGHTNING_STAFF,
    restorationstaff=WEAPONTYPE_HEALING_STAFF,
    healingstaff=WEAPONTYPE_HEALING_STAFF,
}

local WEAPON_TYPE_NAMES = {
    [WEAPONTYPE_SWORD]="Sword",
    [WEAPONTYPE_AXE]="Axe",
    [WEAPONTYPE_HAMMER]="Mace",
    [WEAPONTYPE_DAGGER]="Dagger",
    [WEAPONTYPE_TWO_HANDED_SWORD]="Greatsword",
    [WEAPONTYPE_TWO_HANDED_AXE]="Battle Axe",
    [WEAPONTYPE_TWO_HANDED_HAMMER]="Maul",
    [WEAPONTYPE_BOW]="Bow",
    [WEAPONTYPE_FIRE_STAFF]="Inferno Staff",
    [WEAPONTYPE_FROST_STAFF]="Ice Staff",
    [WEAPONTYPE_LIGHTNING_STAFF]="Lightning Staff",
    [WEAPONTYPE_HEALING_STAFF]="Restoration Staff",
}

local IMPORT_ARMOR_TYPES = {
    light=ARMORTYPE_LIGHT,
    medium=ARMORTYPE_MEDIUM,
    heavy=ARMORTYPE_HEAVY,
}

local ARMOR_TYPE_MARKERS = {
    [ARMORTYPE_LIGHT]="L",
    [ARMORTYPE_MEDIUM]="M",
    [ARMORTYPE_HEAVY]="H",
}

local ARMOR_TRAITS = {
    ITEM_TRAIT_TYPE_ARMOR_DIVINES, ITEM_TRAIT_TYPE_ARMOR_INFUSED,
    ITEM_TRAIT_TYPE_ARMOR_REINFORCED, ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE,
    ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED, ITEM_TRAIT_TYPE_ARMOR_STURDY,
    ITEM_TRAIT_TYPE_ARMOR_TRAINING, ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS,
    ITEM_TRAIT_TYPE_ARMOR_NIRNHONED,
}
local WEAPON_TRAITS = {
    ITEM_TRAIT_TYPE_WEAPON_PRECISE, ITEM_TRAIT_TYPE_WEAPON_SHARPENED,
    ITEM_TRAIT_TYPE_WEAPON_INFUSED, ITEM_TRAIT_TYPE_WEAPON_CHARGED,
    ITEM_TRAIT_TYPE_WEAPON_DEFENDING, ITEM_TRAIT_TYPE_WEAPON_POWERED,
    ITEM_TRAIT_TYPE_WEAPON_DECISIVE, ITEM_TRAIT_TYPE_WEAPON_TRAINING,
    ITEM_TRAIT_TYPE_WEAPON_NIRNHONED,
}
local JEWELRY_TRAITS = {
    ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY, ITEM_TRAIT_TYPE_JEWELRY_INFUSED,
    ITEM_TRAIT_TYPE_JEWELRY_SWIFT, ITEM_TRAIT_TYPE_JEWELRY_HARMONY,
    ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE, ITEM_TRAIT_TYPE_JEWELRY_TRIUNE,
    ITEM_TRAIT_TYPE_JEWELRY_ARCANE, ITEM_TRAIT_TYPE_JEWELRY_HEALTHY,
    ITEM_TRAIT_TYPE_JEWELRY_ROBUST,
}
local TRAIT_NAMES = {
    [ITEM_TRAIT_TYPE_ARMOR_DIVINES]="Divines",
    [ITEM_TRAIT_TYPE_ARMOR_INFUSED]="Infused",
    [ITEM_TRAIT_TYPE_ARMOR_REINFORCED]="Reinforced",
    [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE]="Impenetrable",
    [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED]="Well-fitted",
    [ITEM_TRAIT_TYPE_ARMOR_STURDY]="Sturdy",
    [ITEM_TRAIT_TYPE_ARMOR_TRAINING]="Training",
    [ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS]="Invigorating",
    [ITEM_TRAIT_TYPE_ARMOR_NIRNHONED]="Nirnhoned",
    [ITEM_TRAIT_TYPE_WEAPON_PRECISE]="Precise",
    [ITEM_TRAIT_TYPE_WEAPON_SHARPENED]="Sharpened",
    [ITEM_TRAIT_TYPE_WEAPON_INFUSED]="Infused",
    [ITEM_TRAIT_TYPE_WEAPON_CHARGED]="Charged",
    [ITEM_TRAIT_TYPE_WEAPON_DEFENDING]="Defending",
    [ITEM_TRAIT_TYPE_WEAPON_POWERED]="Powered",
    [ITEM_TRAIT_TYPE_WEAPON_DECISIVE]="Decisive",
    [ITEM_TRAIT_TYPE_WEAPON_TRAINING]="Training",
    [ITEM_TRAIT_TYPE_WEAPON_NIRNHONED]="Nirnhoned",
    [ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY]="Bloodthirsty",
    [ITEM_TRAIT_TYPE_JEWELRY_INFUSED]="Infused",
    [ITEM_TRAIT_TYPE_JEWELRY_SWIFT]="Swift",
    [ITEM_TRAIT_TYPE_JEWELRY_HARMONY]="Harmony",
    [ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE]="Protective",
    [ITEM_TRAIT_TYPE_JEWELRY_TRIUNE]="Triune",
    [ITEM_TRAIT_TYPE_JEWELRY_ARCANE]="Arcane",
    [ITEM_TRAIT_TYPE_JEWELRY_HEALTHY]="Healthy",
    [ITEM_TRAIT_TYPE_JEWELRY_ROBUST]="Robust",
}
local IMPORT_SLOT_ALIASES = {
    head="head",
    shoulders="shoulders", shoulder="shoulders",
    chest="chest",
    hands="hands", gloves="hands",
    waist="waist", belt="waist",
    legs="legs",
    feet="feet", boots="feet",
    neck="neck", necklace="neck",
    ring1="ring1", ringone="ring1",
    ring2="ring2", ringtwo="ring2",
    frontmain="frontMain", frontweapon="frontMain", frontbar="frontMain",
    frontoff="frontOff", frontoffhand="frontOff",
    backmain="backMain", backweapon="backMain", backbar="backMain",
    backoff="backOff", backoffhand="backOff",
}

local EXPORT_SLOT_NAMES = {
    head="Head", shoulders="Shoulders", chest="Chest", hands="Hands",
    waist="Waist", legs="Legs", feet="Feet", neck="Neck",
    ring1="Ring 1", ring2="Ring 2", frontMain="Front Main",
    frontOff="Front Off", backMain="Back Main", backOff="Back Off",
}

local IMPORT_PROMPT = [[Convert the ESO build we have discussed into the exact KEHBUILD format below.
Return ONLY the completed KEHBUILD block, without explanation or Markdown fences.
Use exact English ESO set names.
Use one equipment slot per line.
Armor weight must be Light, Medium or Heavy after a | character.
Weapon type must be Sword, Axe, Mace, Dagger, Greatsword, Battle Axe, Maul, Bow, Inferno Staff, Ice Staff, Lightning Staff or Restoration Staff.
Add the desired trait after a second | character. Jewelry uses the trait directly after the set name.
Armor traits: Divines, Infused, Reinforced, Impenetrable, Well-fitted, Sturdy, Training, Invigorating or Nirnhoned.
Weapon traits: Precise, Sharpened, Infused, Charged, Defending, Powered, Decisive, Training or Nirnhoned.
Jewelry traits: Bloodthirsty, Infused, Swift, Harmony, Protective, Triune, Arcane, Healthy or Robust.
Jewelry never has an armor weight. Use Ring 1: Set Name | Trait.
Use empty for an unused offhand.

KEHBUILD: Build Name
Head: Set Name | Weight | Trait
Shoulders: Set Name | Weight | Trait
Chest: Set Name | Weight | Trait
Hands: Set Name | Weight | Trait
Waist: Set Name | Weight | Trait
Legs: Set Name | Weight | Trait
Feet: Set Name | Weight | Trait
Neck: Set Name | Trait
Ring 1: Set Name | Trait
Ring 2: Set Name | Trait
Front Main: Set Name | Weapon Type | Trait
Front Off: Set Name | Weapon Type | Trait
Back Main: Set Name | Weapon Type | Trait
Back Off: empty]]

local function NormalizeImportKey(value)
    return zo_strlower(zo_strtrim(value or "")):gsub("[%s_%-]","")
end

local function FindSlotDef(key)
    for _,slotDef in ipairs(SLOTS) do
        if slotDef.key==key then return slotDef end
    end
end

local function TraitListForSlot(slotDef)
    if slotDef.weapon or slotDef.offhand then return WEAPON_TRAITS end
    if slotDef.equip==EQUIP_TYPE_RING or slotDef.equip==EQUIP_TYPE_NECK then
        return JEWELRY_TRAITS
    end
    return ARMOR_TRAITS
end

local function DefaultTraitForSlot(slotDef)
    if slotDef.weapon or slotDef.offhand then return ITEM_TRAIT_TYPE_WEAPON_PRECISE end
    if slotDef.equip==EQUIP_TYPE_RING or slotDef.equip==EQUIP_TYPE_NECK then
        return ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY
    end
    return ITEM_TRAIT_TYPE_ARMOR_DIVINES
end

local function FindTraitForSlot(slotDef,name)
    local normalized=NormalizeImportKey(name)
    if normalized=="prosperous" and not (slotDef.weapon or slotDef.offhand) then
        return ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS
    end
    for _,traitType in ipairs(TraitListForSlot(slotDef)) do
        if NormalizeImportKey(TRAIT_NAMES[traitType])==normalized then return traitType end
    end
end

local function StyleModalButton(control,textValue,r,g,b)
    control:SetText("")
    local background=WINDOW_MANAGER:CreateControl(nil,control,CT_BACKDROP)
    background:SetAnchorFill(control)
    background:SetCenterColor(r*0.22,g*0.22,b*0.22,0.98)
    background:SetEdgeColor(r,g,b,1)
    background:SetMouseEnabled(false)
    background:SetDrawTier(DT_HIGH)
    background:SetDrawLayer(DL_OVERLAY)
    background:SetDrawLevel(110)
    local label=WINDOW_MANAGER:CreateControl(nil,control,CT_LABEL)
    label:SetAnchorFill(control)
    label:SetFont("ZoFontGameBold")
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    label:SetColor(1,1,1,1)
    label:SetText(textValue)
    label:SetMouseEnabled(false)
    label:SetDrawTier(DT_HIGH)
    label:SetDrawLayer(DL_OVERLAY)
    label:SetDrawLevel(111)
end

local function SetIdentity(setId)
    return KPH:GetSetDataIdentity(setId)
end

local function PieceBaseKey(setId, link)
    local setKey=SetIdentity(setId)
    local weaponType = GetItemLinkWeaponType(link)
    if weaponType and weaponType ~= WEAPONTYPE_NONE then
        return string.format("%s:w:%d",setKey,weaponType)
    end
    local armorType=GetItemLinkArmorType(link)
    if armorType and armorType~=ARMORTYPE_NONE then
        return string.format("%s:e:%d:a:%d",setKey,
            GetItemLinkEquipType(link) or 0,armorType)
    end
    return string.format("%s:e:%d",setKey,GetItemLinkEquipType(link) or 0)
end

local function PieceKey(setId,link)
    local key=PieceBaseKey(setId,link)
    local traitType=GetItemLinkTraitType(link)
    if traitType and traitType~=ITEM_TRAIT_TYPE_NONE then
        key=key..":t:"..traitType
    end
    return key
end

local function IsTwoHanded(link)
    local equipType = GetItemLinkEquipType(link)
    return equipType == EQUIP_TYPE_TWO_HAND
end

local function ChoiceBaseKey(choice)
    local setKey=SetIdentity(choice.setId)
    local key
    if choice.link then
        local weaponType=GetItemLinkWeaponType(choice.link)
        if weaponType and weaponType~=WEAPONTYPE_NONE then
            key=string.format("%s:w:%d",setKey,weaponType)
        else
            local equipType=GetItemLinkEquipType(choice.link) or choice.equipType or 0
            local armorType=GetItemLinkArmorType(choice.link)
            if (not armorType or armorType==ARMORTYPE_NONE) and choice.armorType then
                armorType=choice.armorType
            end
            if armorType and armorType~=ARMORTYPE_NONE then
                key=string.format("%s:e:%d:a:%d",setKey,equipType,armorType)
            else key=string.format("%s:e:%d",setKey,equipType) end
        end
    elseif choice.weaponType then key=string.format("%s:w:%d",setKey,choice.weaponType)
    elseif choice.armorType then
        key=string.format("%s:e:%d:a:%d",setKey,
            choice.equipType or 0,choice.armorType)
    else
        key=string.format("%s:e:%d",setKey,choice.equipType or 0)
    end
    return key
end

local function ResolveChoiceArmorType(choice,slotDef)
    if not ARMOR_EQUIP_TYPES[slotDef.equip] then return nil end
    local armorType=choice.link and GetItemLinkArmorType(choice.link) or nil
    if armorType and armorType~=ARMORTYPE_NONE then return armorType end
    if choice.armorType and choice.armorType~=ARMORTYPE_NONE then
        return choice.armorType
    end
    for index=1,GetNumItemSetCollectionPieces(choice.setId) do
        local pieceId=GetItemSetCollectionPieceInfo(choice.setId,index)
        local link=GetItemSetCollectionPieceItemLink(pieceId,LINK_STYLE_DEFAULT,
            ITEM_TRAIT_TYPE_NONE,ITEM_FUNCTIONAL_QUALITY_MAGIC)
        if link and link~="" then
            armorType=GetItemLinkArmorType(link)
            if armorType and armorType~=ARMORTYPE_NONE then return armorType end
        end
    end
    for _,bagId in ipairs({BAG_WORN,BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK}) do
        for slotIndex=0,GetBagSize(bagId)-1 do
            local link=GetItemLink(bagId,slotIndex,LINK_STYLE_DEFAULT)
            if link and link~="" then
                local hasSet,_,_,_,_,setId=GetItemLinkSetInfo(link,false)
                if hasSet and SetIdentity(setId)==SetIdentity(choice.setId) then
                    armorType=GetItemLinkArmorType(link)
                    if armorType and armorType~=ARMORTYPE_NONE then return armorType end
                end
            end
        end
    end
end

local function ChoiceKey(choice)
    local key=ChoiceBaseKey(choice)
    if choice.traitType then key=key..":t:"..choice.traitType end
    return key
end

local function ChoiceIsTwoHanded(choice)
    if choice.link then return IsTwoHanded(choice.link) end
    local w=choice.weaponType
    return w==WEAPONTYPE_TWO_HANDED_SWORD or w==WEAPONTYPE_TWO_HANDED_AXE or
        w==WEAPONTYPE_TWO_HANDED_HAMMER or w==WEAPONTYPE_BOW or
        w==WEAPONTYPE_FIRE_STAFF or w==WEAPONTYPE_FROST_STAFF or
        w==WEAPONTYPE_LIGHTNING_STAFF or w==WEAPONTYPE_HEALING_STAFF
end

local function Compatible(slotDef, link)
    local equipType = GetItemLinkEquipType(link)
    local weaponType = GetItemLinkWeaponType(link)
    if slotDef.weapon then return weaponType and weaponType ~= WEAPONTYPE_NONE end
    if slotDef.offhand then
        return equipType == EQUIP_TYPE_OFF_HAND or ONE_HAND[weaponType] == true
    end
    return equipType == slotDef.equip
end

local function BuildSource(setId, link, equipOverride, weaponOverride)
    return KPH:GetSetPieceSource(setId,link,equipOverride,weaponOverride)
end

function KPH:GetActiveBuild()
    local plans = self.savedVariables.buildPlans
    local name = self.savedVariables.activeBuildName or "Build 1"
    if not plans[name] then plans[name] = { name=name, sets={}, slots={} } end
    return plans[name]
end

function KPH:CycleSavedBuild(direction)
    local names={}
    for name in pairs(self.savedVariables.buildPlans) do table.insert(names,name) end
    table.sort(names,function(a,b) return zo_strlower(a)<zo_strlower(b) end)
    if #names==0 then return end
    local current=1
    for index,name in ipairs(names) do
        if name==self.savedVariables.activeBuildName then current=index break end
    end
    current=((current-1+(direction or 1)) % #names)+1
    self.savedVariables.activeBuildName=names[current]
    self:RefreshBuildPlanner()
    d("[KEH] Active build: "..names[current])
end

function KPH:DeleteActiveBuild(button)
    if not self.deleteBuildArmed then
        self.deleteBuildArmed=true
        button:SetText("Click again to delete")
        zo_callLater(function()
            if self.deleteBuildArmed then
                self.deleteBuildArmed=false
                if button then button:SetText("Delete Build") end
            end
        end,5000)
        return
    end
    self.deleteBuildArmed=false
    local deleted=self.savedVariables.activeBuildName
    self.savedVariables.buildPlans[deleted]=nil
    local nextName
    for name in pairs(self.savedVariables.buildPlans) do
        if not nextName or zo_strlower(name)<zo_strlower(nextName) then nextName=name end
    end
    if not nextName then
        nextName="Build 1"
        self.savedVariables.buildPlans[nextName]={name=nextName,sets={},slots={}}
    end
    self.savedVariables.activeBuildName=nextName
    button:SetText("Delete Build")
    self:RefreshBuildPlanner()
    d("[KEH] Deleted build: "..deleted)
end

function KPH:FindBuildSet(search)
    local matches=self:GetBuildSetMatches(search)
    if matches[1] and matches[1].exact then return matches[1].id end
    if #matches == 1 then return matches[1].id end
    if #matches > 1 then
        d("[KEH] Multiple sets match. Enter a more exact name:")
        for i=1, math.min(10,#matches) do d("  "..matches[i].name) end
    else d("[KEH] No set found.") end
end

function KPH:GetBuildSetMatches(search)
    local needle=zo_strlower(zo_strtrim(search or ""))
    local matches={}
    if needle=="" then return matches end
    if not self.buildSetSearchIndex then
        self.buildSetSearchIndex={}
        local known={}
        local id=GetNextItemSetCollectionId(nil)
        while id do
            local name=GetItemSetName(id)
            if name and name~="" then
                table.insert(self.buildSetSearchIndex,{id=id,name=name,
                    lower=zo_strlower(name)})
                known[id]=true
            end
            id=GetNextItemSetCollectionId(id)
        end
        -- Crafted sets are not in the stickerbook and therefore not in the iterator.
        -- Set IDs are dense and inexpensive to scan once per UI load.
        for scannedId=1,3000 do
            if not known[scannedId] then
                local name=GetItemSetName(scannedId)
                if name and name~="" then
                    table.insert(self.buildSetSearchIndex,{id=scannedId,name=name,
                        lower=zo_strlower(name)})
                end
            end
        end
    end
    local seen={}
    for _,entry in ipairs(self.buildSetSearchIndex) do
        local id,name,lower=entry.id,entry.name,entry.lower
        if string.find(lower,needle,1,true) then
            id=self:CanonicalizeSetId(id,name)
            local identity=self:GetSetDataIdentity(id,name)
            if not seen[identity] then
                table.insert(matches,{id=id,name=name,exact=lower==needle})
                seen[identity]=true
            end
        end
    end
    table.sort(matches,function(a,b)
        if a.exact~=b.exact then return a.exact end
        return a.name<b.name
    end)
    while #matches>6 do table.remove(matches) end
    return matches
end

function KPH:FindExactBuildSet(search)
    local needle=zo_strlower(zo_strtrim(search or ""))
    for _,match in ipairs(self:GetBuildSetMatches(search)) do
        if zo_strlower(match.name)==needle then return match end
    end
end

function KPH:MakeBuildChoice(setId,slotDef,weaponType,armorType)
    local pieces=self:GetCompatibleBuildPieces(setId,slotDef)
    if weaponType then
        for _,piece in ipairs(pieces) do
            if GetItemLinkWeaponType(piece.link)==weaponType then
                return {setId=setId,pieceId=piece.pieceId,
                    collectionSlot=piece.collectionSlot,link=piece.link}
            end
        end
    end
    if armorType then
        for _,piece in ipairs(pieces) do
            if GetItemLinkArmorType(piece.link)==armorType then
                return {setId=setId,pieceId=piece.pieceId,
                    collectionSlot=piece.collectionSlot,link=piece.link}
            end
        end
        if #pieces>0 then
            return {setId=setId,pieceId=pieces[1].pieceId,
                collectionSlot=pieces[1].collectionSlot,link=pieces[1].link}
        end
    end
    if #pieces>0 and not weaponType and not armorType then
        return {setId=setId,pieceId=pieces[1].pieceId,
            collectionSlot=pieces[1].collectionSlot,link=pieces[1].link}
    end
    local choice={setId=setId,generic=true,
        crafted=GetItemSetType(setId)==ITEM_SET_TYPE_CRAFTED}
    if slotDef.weapon then choice.weaponType=weaponType or WEAPONTYPE_SWORD
    elseif slotDef.offhand then choice.weaponType=weaponType or WEAPONTYPE_DAGGER
    else
        choice.equipType=slotDef.equip
        if ARMOR_EQUIP_TYPES[slotDef.equip] and
           ARMOR_TYPE_MARKERS[armorType] then choice.armorType=armorType end
        if ARMOR_EQUIP_TYPES[slotDef.equip] and not choice.armorType and
           (GetItemSetType(setId)==ITEM_SET_TYPE_CRAFTED or
           GetItemSetType(setId)==ITEM_SET_TYPE_MONSTER) then
            choice.armorType=ARMORTYPE_MEDIUM
        end
    end
    return choice
end

function KPH:OpenBuildSlotSearch(slotDef)
    self.buildSearchSlot=slotDef
    self.buildSearchBackdrop:SetHidden(false)
    self.buildSearchEdit:SetText("")
    for _,button in ipairs(self.buildSearchButtons) do button:SetHidden(true) end
    self.buildSearchEdit:TakeFocus()
end

function KPH:UpdateBuildSlotSearch(text)
    local setSearch=text and text:match("^(.-)%s*|") or text
    self.buildSearchMatches=self:GetBuildSetMatches(setSearch or text)
    for i,button in ipairs(self.buildSearchButtons) do
        local match=self.buildSearchMatches[i]
        if match then
            button:SetText((i==1 and "|c66CC66> " or "|cFFFFFF")..match.name.."|r")
            button:SetHidden(false)
        else button:SetHidden(true) end
    end
end

function KPH:AcceptBuildSlotSearch(matchIndex)
    local slotDef=self.buildSearchSlot
    local text=zo_strtrim(self.buildSearchEdit:GetText() or "")
    local build=self:GetActiveBuild()
    if text=="" then
        build.slots[slotDef.key]=nil
    else
        local match=self.buildSearchMatches and self.buildSearchMatches[matchIndex or 1]
        if not match then
            PlaySound(SOUNDS.NEGATIVE_CLICK)
            zo_callLater(function() self.buildSearchEdit:TakeFocus() end,1)
            return
        end
        local pieces=self:GetCompatibleBuildPieces(match.id,slotDef)
        if #pieces==0 then
            -- Crafted and some monster/special sets may lack a usable
            -- Collections link. Slot type is enough for planning and physical
            -- ownership checks in those cases.
            local choice={setId=match.id,generic=true,
                crafted=GetItemSetType(match.id)==ITEM_SET_TYPE_CRAFTED}
            if slotDef.weapon then choice.weaponType=WEAPONTYPE_SWORD
            elseif slotDef.offhand then choice.weaponType=WEAPONTYPE_DAGGER
            else choice.equipType=slotDef.equip end
            build.slots[slotDef.key]=choice
        else
            build.slots[slotDef.key]={setId=match.id,pieceId=pieces[1].pieceId,
                collectionSlot=pieces[1].collectionSlot,link=pieces[1].link}
        end
        if slotDef.weapon or slotDef.offhand then
            local weaponName=text:match("|%s*(.-)%s*$")
            local weaponType=weaponName and
                IMPORT_WEAPON_TYPES[NormalizeImportKey(weaponName)]
            if weaponType then
                build.slots[slotDef.key]=self:MakeBuildChoice(
                    match.id,slotDef,weaponType)
            end
        else
            local armorName=text:match("|%s*(.-)%s*$")
            local armorType=armorName and
                IMPORT_ARMOR_TYPES[NormalizeImportKey(armorName)]
            if armorType then
                build.slots[slotDef.key]=self:MakeBuildChoice(
                    match.id,slotDef,nil,armorType)
            end
        end
        local fields={}
        for field in text:gmatch("[^|]+") do table.insert(fields,zo_strtrim(field)) end
        local isJewelry=slotDef.equip==EQUIP_TYPE_RING or
            slotDef.equip==EQUIP_TYPE_NECK
        local optionName
        if not isJewelry then optionName=fields[2] end
        local traitName
        if isJewelry then
            local accidentalWeight=fields[2] and
                IMPORT_ARMOR_TYPES[NormalizeImportKey(fields[2])]
            traitName=accidentalWeight and fields[3] or fields[2]
        else traitName=fields[3] end
        local weaponType=(slotDef.weapon or slotDef.offhand) and optionName and
            IMPORT_WEAPON_TYPES[NormalizeImportKey(optionName)]
        local armorType=ARMOR_EQUIP_TYPES[slotDef.equip] and optionName and
            IMPORT_ARMOR_TYPES[NormalizeImportKey(optionName)]
        if weaponType or armorType then
            build.slots[slotDef.key]=self:MakeBuildChoice(
                match.id,slotDef,weaponType,armorType)
        end
        if build.slots[slotDef.key] then
            build.slots[slotDef.key].traitType=
                FindTraitForSlot(slotDef,traitName) or DefaultTraitForSlot(slotDef)
        end
        local exists=false
        for _,id in ipairs(build.sets) do if id==match.id then exists=true end end
        if not exists then table.insert(build.sets,match.id) end
    end
    self.buildSearchBackdrop:SetHidden(true)
    self.buildSearchEdit:LoseFocus()
    self:RefreshBuildPlanner()
end

function KPH:ShowBuildPlanner()
    self:CreateBuildPlannerWindow()
    self:RefreshBuildPlanner()
    self.buildPlannerWindow:SetHidden(false)
    SCENE_MANAGER:SetInUIMode(true)
end

function KPH:ImportBuildText(text)
    local buildName="Imported Build"
    local entries,errors={},{}
    text=(text or ""):gsub("\r","")
    for line in text:gmatch("[^\n]+") do
        line=zo_strtrim(line)
        if line~="" and not line:match("^#") and
           line:sub(1,1)~=string.char(96) then
            local label,value=line:match("^([^:=]+)%s*[:=]%s*(.-)%s*$")
            local normalized=NormalizeImportKey(label)
            if normalized=="kehbuild" or normalized=="build" or normalized=="name" then
                if value and value~="" then buildName=value end
            else
                local slotKey=IMPORT_SLOT_ALIASES[normalized]
                if not slotKey then
                    table.insert(errors,"Unknown slot: "..tostring(label))
                elseif not value or value=="" or zo_strlower(value)=="empty" then
                    entries[slotKey]=false
                else
                    local fields={}
                    for field in value:gmatch("[^|]+") do
                        table.insert(fields,zo_strtrim(field))
                    end
                    local setName=fields[1] or value
                    local isWeaponSlot=slotKey=="frontMain" or slotKey=="frontOff" or
                        slotKey=="backMain" or slotKey=="backOff"
                    local slotDef=FindSlotDef(slotKey)
                    local isJewelry=slotDef.equip==EQUIP_TYPE_RING or
                        slotDef.equip==EQUIP_TYPE_NECK
                    local optionName
                    if not isJewelry then optionName=fields[2] end
                    local traitName
                    if isJewelry then
                        local accidentalWeight=fields[2] and
                            IMPORT_ARMOR_TYPES[NormalizeImportKey(fields[2])]
                        traitName=accidentalWeight and fields[3] or fields[2]
                    else traitName=fields[3] end
                    local weaponType,armorType,traitType
                    if optionName and optionName~="" then
                        if isWeaponSlot then
                            weaponType=IMPORT_WEAPON_TYPES[NormalizeImportKey(optionName)]
                            if not weaponType then
                                table.insert(errors,"Unknown weapon type: "..optionName)
                            end
                        else
                            armorType=IMPORT_ARMOR_TYPES[NormalizeImportKey(optionName)]
                            if not armorType then
                                table.insert(errors,"Unknown armor weight: "..optionName)
                            end
                        end
                    end
                    if traitName and traitName~="" then
                        traitType=FindTraitForSlot(slotDef,traitName)
                        if not traitType then
                            table.insert(errors,"Unknown trait: "..traitName)
                        end
                    else traitType=DefaultTraitForSlot(slotDef) end
                    local match=self:FindExactBuildSet(setName)
                    if not match then
                        table.insert(errors,"Set not found: "..setName)
                    elseif optionName and not weaponType and not armorType then
                        -- Keep the line unassigned until the option is corrected.
                    elseif traitName and not traitType then
                        -- Keep the line unassigned until the trait is corrected.
                    elseif weaponType and (slotKey=="frontOff" or slotKey=="backOff") and
                           not ONE_HAND[weaponType] then
                        table.insert(errors,"Offhand must be Sword, Axe, Mace or Dagger.")
                    else
                        entries[slotKey]={match=match,weaponType=weaponType,
                            armorType=armorType,traitType=traitType}
                    end
                end
            end
        end
    end
    if entries.frontMain and ChoiceIsTwoHanded(
       {weaponType=entries.frontMain.weaponType}) then entries.frontOff=false end
    if entries.backMain and ChoiceIsTwoHanded(
       {weaponType=entries.backMain.weaponType}) then entries.backOff=false end
    local count=0
    for _ in pairs(entries) do count=count+1 end
    if count==0 then
        d("[KEH] Import contains no valid equipment slots.")
        return false
    end
    local uniqueName=buildName
    local suffix=2
    while self.savedVariables.buildPlans[uniqueName] do
        uniqueName=buildName.." "..suffix
        suffix=suffix+1
    end
    local build={name=uniqueName,sets={},slots={}}
    local knownSets={}
    for slotKey,entry in pairs(entries) do
        if entry then
            local match=entry.match
            local slotDef=FindSlotDef(slotKey)
            build.slots[slotKey]=self:MakeBuildChoice(
                match.id,slotDef,entry.weaponType,entry.armorType)
            build.slots[slotKey].traitType=entry.traitType or
                DefaultTraitForSlot(slotDef)
            if not knownSets[match.id] then
                knownSets[match.id]=true
                table.insert(build.sets,match.id)
            end
        end
    end
    self.savedVariables.buildPlans[uniqueName]=build
    self.savedVariables.activeBuildName=uniqueName
    self.buildImportBackdrop:SetHidden(true)
    self.buildImportEdit:LoseFocus()
    self:RefreshBuildPlanner()
    d(string.format("[KEH] Imported %s (%d slots).",uniqueName,count))
    for _,message in ipairs(errors) do d("[KEH] "..message) end
    return true
end

function KPH:OpenBuildImport()
    self.buildSearchBackdrop:SetHidden(true)
    self.buildSearchEdit:LoseFocus()
    self.buildImportBackdrop:SetHidden(false)
    self.buildImportTitle:SetText("Import Build")
    self.buildImportHelp:SetText(
        "Copy the default prompt to ChatGPT (Ctrl+A, Ctrl+C). Replace it with the KEHBUILD response, then click Import.")
    self.buildImportConfirm:SetHidden(false)
    self.buildImportEdit:SetText(IMPORT_PROMPT)
    self.buildImportEdit:TakeFocus()
end

function KPH:ExportBuildText()
    local build=self:GetActiveBuild()
    local lines={"KEHBUILD: "..build.name}
    for _,slotDef in ipairs(SLOTS) do
        local choice=build.slots[slotDef.key]
        local value="empty"
        if choice then
            choice.traitType=choice.traitType or DefaultTraitForSlot(slotDef)
            value=GetItemSetName(choice.setId)
            local weaponType=choice.link and GetItemLinkWeaponType(choice.link) or
                choice.weaponType
            local armorType=choice.link and GetItemLinkArmorType(choice.link) or
                choice.armorType
            if WEAPON_TYPE_NAMES[weaponType] then
                value=value.." | "..WEAPON_TYPE_NAMES[weaponType]
            elseif ARMOR_TYPE_MARKERS[armorType] then
                local weights={[ARMORTYPE_LIGHT]="Light",
                    [ARMORTYPE_MEDIUM]="Medium",[ARMORTYPE_HEAVY]="Heavy"}
                value=value.." | "..weights[armorType]
            end
            if TRAIT_NAMES[choice.traitType] then
                value=value.." | "..TRAIT_NAMES[choice.traitType]
            end
        end
        table.insert(lines,EXPORT_SLOT_NAMES[slotDef.key]..": "..value)
    end
    return table.concat(lines,"\n")
end

function KPH:OpenBuildExport()
    self.buildSearchBackdrop:SetHidden(true)
    self.buildSearchEdit:LoseFocus()
    self.buildImportBackdrop:SetHidden(false)
    self.buildImportTitle:SetText("Export Build")
    self.buildImportHelp:SetText(
        "Copy this text with Ctrl+A, Ctrl+C and send it to a friend who uses KEH.")
    self.buildImportConfirm:SetHidden(true)
    self.buildImportEdit:SetText(self:ExportBuildText())
    self.buildImportEdit:TakeFocus()
end

function KPH:CloseBuildImport()
    if self.buildImportEdit then self.buildImportEdit:LoseFocus() end
    if self.buildImportBackdrop then self.buildImportBackdrop:SetHidden(true) end
end

function KPH:HideBuildPlanner()
    if self.buildSearchEdit then self.buildSearchEdit:LoseFocus() end
    self:CloseBuildImport()
    if self.buildPlannerWindow then self.buildPlannerWindow:SetHidden(true) end
    SCENE_MANAGER:SetInUIMode(false)
end

function KPH:GetCompatibleBuildPieces(setId, slotDef)
    local pieces = {}
    for index=1, GetNumItemSetCollectionPieces(setId) do
        local pieceId, collectionSlot = GetItemSetCollectionPieceInfo(setId,index)
        local link = GetItemSetCollectionPieceItemLink(pieceId, LINK_STYLE_DEFAULT,
            ITEM_TRAIT_TYPE_NONE, ITEM_FUNCTIONAL_QUALITY_MAGIC)
        if link and link ~= "" and Compatible(slotDef,link) then
            table.insert(pieces,{ pieceId=pieceId, collectionSlot=collectionSlot,
                link=link, name=zo_strformat("<<C:1>>",GetItemLinkName(link)) })
        end
    end
    return pieces
end

function KPH:GetBuildOwnedCounts()
    local baseCounts,exactCounts={},{}
    if not self.setOwnership then self:RefreshSetOwnership(false) end
    for _,item in ipairs(self:GetOwnedSetItemLinks()) do
        local link,setId=item.link,item.setId
        if link and link~="" and setId then
            local baseKey=PieceBaseKey(setId,link)
            local exactKey=PieceKey(setId,link)
            baseCounts[baseKey]=(baseCounts[baseKey] or 0)+1
            exactCounts[exactKey]=(exactCounts[exactKey] or 0)+1
        end
    end
    return baseCounts,exactCounts
end

function KPH:CycleBuildTrait(slotDef)
    local choice=self:GetActiveBuild().slots[slotDef.key]
    if not choice then return end
    local traits=TraitListForSlot(slotDef)
    local current=choice.traitType or DefaultTraitForSlot(slotDef)
    for index,traitType in ipairs(traits) do
        if traitType==current then
            choice.traitType=traits[(index % #traits)+1]
            PlaySound(SOUNDS.DEFAULT_CLICK)
            self:RefreshBuildPlanner()
            return
        end
    end
    choice.traitType=traits[1]
    self:RefreshBuildPlanner()
end

function KPH:ToggleManualBuildOwned(slotDef,traitOnly)
    local choice=self:GetActiveBuild().slots[slotDef.key]
    if not choice then return end
    if traitOnly then
        choice.manualTraitOwned=not choice.manualTraitOwned
        if choice.manualTraitOwned then choice.manualOwned=true end
    else
        choice.manualOwned=not choice.manualOwned
        if not choice.manualOwned then choice.manualTraitOwned=false end
    end
    self:RefreshBuildPlanner()
end

function KPH:CycleBuildSlot(slotDef, cyclePiece)
    local build=self:GetActiveBuild()
    local current=build.slots[slotDef.key]
    if cyclePiece and current then
        if ARMOR_EQUIP_TYPES[slotDef.equip] then
            -- ESO Collections sometimes reports only one representative weight.
            -- The planner must therefore store the user's L/M/H choice directly.
            local available={ARMORTYPE_LIGHT,ARMORTYPE_MEDIUM,ARMORTYPE_HEAVY}
            current.armorType=ResolveChoiceArmorType(current,slotDef)
            local previousType=current.armorType
            if #available>1 then
                local changed=false
                for index,armorType in ipairs(available) do
                    if armorType==current.armorType then
                        current.armorType=available[(index % #available)+1]
                        changed=true
                        break
                    end
                end
                if not changed then current.armorType=available[1] end
            elseif #available==1 then current.armorType=available[1] end
            if current.armorType and current.armorType~=previousType and current.link then
                -- Collection links for class sets often expose only one representative
                -- weight. Keep the planned weight explicitly instead of letting that
                -- link overwrite the user's right-click choice during refresh.
                current.link=nil
                current.pieceId=nil
                current.collectionSlot=nil
                current.generic=true
                current.equipType=slotDef.equip
            end
            PlaySound(SOUNDS.DEFAULT_CLICK)
            self:RefreshBuildPlanner()
            return
        end
        if slotDef.weapon or slotDef.offhand then
            local available={}
            -- Do not depend on the saved Collections set ID here. Crafted and
            -- aliased set IDs can return no pieces even though every weapon exists.
            for _,weaponType in ipairs(GENERIC_WEAPONS) do
                if slotDef.weapon or ONE_HAND[weaponType] then
                    table.insert(available,weaponType)
                end
            end
            local currentType=current.weaponType
            if (not currentType or currentType==WEAPONTYPE_NONE) and current.link then
                currentType=GetItemLinkWeaponType(current.link)
            end
            if #available>0 then
                local nextType=available[1]
                for index,weaponType in ipairs(available) do
                    if weaponType==currentType then
                        nextType=available[(index % #available)+1]
                        break
                    end
                end
                local replacement=self:MakeBuildChoice(
                    current.setId,slotDef,nextType)
                replacement.traitType=current.traitType
                replacement.manualOwned=current.manualOwned
                replacement.manualTraitOwned=current.manualTraitOwned
                build.slots[slotDef.key]=replacement
                PlaySound(SOUNDS.DEFAULT_CLICK)
                self:RefreshBuildPlanner()
            else
                PlaySound(SOUNDS.NEGATIVE_CLICK)
            end
            return
        end
        if current.generic and current.armorType and not slotDef.weapon and
           not slotDef.offhand then
            local armorTypes={ARMORTYPE_LIGHT,ARMORTYPE_MEDIUM,ARMORTYPE_HEAVY}
            for i,armorType in ipairs(armorTypes) do
                if armorType==current.armorType then
                    current.armorType=armorTypes[(i % #armorTypes)+1]
                    PlaySound(SOUNDS.DEFAULT_CLICK)
                    self:RefreshBuildPlanner()
                    return
                end
            end
        end
        local pieces=self:GetCompatibleBuildPieces(current.setId,slotDef)
        for i,p in ipairs(pieces) do
            if p.pieceId==current.pieceId then
                local nextPiece=pieces[(i % #pieces)+1]
                build.slots[slotDef.key]={setId=current.setId,pieceId=nextPiece.pieceId,
                    collectionSlot=nextPiece.collectionSlot,link=nextPiece.link,
                    traitType=current.traitType}
                PlaySound(SOUNDS.DEFAULT_CLICK)
                self:RefreshBuildPlanner() return
            end
        end
        return
    end
    local nextSetIndex=1
    if current then
        for i,id in ipairs(build.sets) do if id==current.setId then nextSetIndex=i+1 end end
    end
    if nextSetIndex>#build.sets then
        build.slots[slotDef.key]=nil
    else
        local setId=build.sets[nextSetIndex]
        local pieces=self:GetCompatibleBuildPieces(setId,slotDef)
        if #pieces>0 then
            build.slots[slotDef.key]={setId=setId,pieceId=pieces[1].pieceId,
                collectionSlot=pieces[1].collectionSlot,link=pieces[1].link,
                traitType=DefaultTraitForSlot(slotDef)}
        else build.slots[slotDef.key]=nil end
    end
    self:RefreshBuildPlanner()
end

function KPH:BuildCounterText(build)
    local base,front,back={},{},{}
    for _,def in ipairs(SLOTS) do
        local choice=build.slots[def.key]
        if choice then
            local amount=ChoiceIsTwoHanded(choice) and 2 or 1
            if def.bar==1 then front[choice.setId]=(front[choice.setId] or 0)+amount
            elseif def.bar==2 then back[choice.setId]=(back[choice.setId] or 0)+amount
            else base[choice.setId]=(base[choice.setId] or 0)+amount end
        end
    end
    local lines={}
    for _,setId in ipairs(build.sets) do
        table.insert(lines,string.format("%s: front %d / back %d",GetItemSetName(setId),
            (base[setId] or 0)+(front[setId] or 0),(base[setId] or 0)+(back[setId] or 0)))
    end
    return table.concat(lines,"   |   ")
end

function KPH:RefreshBuildPlanner()
    if not self.buildPlannerWindow then return end
    local build=self:GetActiveBuild()
    self.buildPlannerTitle:SetText("KEH Build Planner – "..build.name)
    self.buildPlannerCounters:SetText(self:BuildCounterText(build))
    local baseOwned,exactOwned=self:GetBuildOwnedCounts()
    local ownership={}
    for _,def in ipairs(SLOTS) do
        local choice=build.slots[def.key]
        if choice then
            if def.equip==EQUIP_TYPE_RING or def.equip==EQUIP_TYPE_NECK then
                choice.armorType=nil
            elseif ARMOR_EQUIP_TYPES[def.equip] then
                choice.armorType=ResolveChoiceArmorType(choice,def)
            end
            choice.traitType=choice.traitType or DefaultTraitForSlot(def)
            local exactKey=ChoiceKey(choice)
            if choice.manualTraitOwned then
                ownership[def.key]="exact"
            elseif (exactOwned[exactKey] or 0)>0 then
                local baseKey=ChoiceBaseKey(choice)
                exactOwned[exactKey]=exactOwned[exactKey]-1
                baseOwned[baseKey]=(baseOwned[baseKey] or 1)-1
                ownership[def.key]="exact"
            end
        end
    end
    for _,def in ipairs(SLOTS) do
        local choice=build.slots[def.key]
        if choice and not ownership[def.key] then
            local baseKey=ChoiceBaseKey(choice)
            if choice.manualOwned then
                ownership[def.key]="wrongTrait"
            elseif (baseOwned[baseKey] or 0)>0 then
                baseOwned[baseKey]=baseOwned[baseKey]-1
                ownership[def.key]="wrongTrait"
            end
        end
    end
    for _,def in ipairs(SLOTS) do
        local button=self.buildSlotButtons[def.key]
        local traitButton=self.buildTraitButtons[def.key]
        local choice=build.slots[def.key]
        if not choice then
            button:SetText("|c888888"..def.name..": not planned|r")
            traitButton:SetText("|c666666-|r")
        else
            local marker,color,status
            if ownership[def.key]=="exact" or ownership[def.key]=="wrongTrait" then
                marker,color,status="✓","66CC66","owned"
            elseif choice.collectionSlot and
                   IsItemSetCollectionSlotUnlocked(choice.setId,choice.collectionSlot) then
                marker,color,status="●","E89B35","reconstructable"
            else
                marker,color,status="✗","E05A5A","get: "..BuildSource(
                    choice.setId,choice.link,choice.equipType,choice.weaponType)
            end
            local itemName=choice.link and zo_strformat("<<C:1>>",GetItemLinkName(choice.link))
                or GetItemSetName(choice.setId)
            if not choice.link and choice.weaponType then
                itemName=itemName.." "..(WEAPON_TYPE_NAMES[choice.weaponType] or "Weapon")
            end
            local armorType=choice.link and GetItemLinkArmorType(choice.link) or nil
            if not armorType or armorType==ARMORTYPE_NONE then
                armorType=choice.armorType
            end
            if ARMOR_TYPE_MARKERS[armorType] then
                itemName=itemName.." ("..ARMOR_TYPE_MARKERS[armorType]..")"
            end
            button:SetText(string.format("|c%s%s %s: %s (%s)|r",color,marker,
                def.name,itemName,status))
            local traitColor=ownership[def.key]=="exact" and "66CC66" or "E05A5A"
            traitButton:SetText(string.format("|c%s%s|r",traitColor,
                TRAIT_NAMES[choice.traitType] or "No trait"))
        end
    end
end

function KPH:GetMissingBuildNoteLines()
    local build=self:GetActiveBuild()
    local baseOwned,exactOwned=self:GetBuildOwnedCounts()
    local ownership={}
    for _,def in ipairs(SLOTS) do
        local choice=build.slots[def.key]
        if choice then
            if def.equip==EQUIP_TYPE_RING or def.equip==EQUIP_TYPE_NECK then
                choice.armorType=nil
            elseif ARMOR_EQUIP_TYPES[def.equip] then
                choice.armorType=ResolveChoiceArmorType(choice,def)
            end
            choice.traitType=choice.traitType or DefaultTraitForSlot(def)
            local exactKey=ChoiceKey(choice)
            if choice.manualTraitOwned or (exactOwned[exactKey] or 0)>0 then
                ownership[def.key]="exact"
                if not choice.manualTraitOwned then
                    exactOwned[exactKey]=exactOwned[exactKey]-1
                    local baseKey=ChoiceBaseKey(choice)
                    baseOwned[baseKey]=(baseOwned[baseKey] or 1)-1
                end
            end
        end
    end
    for _,def in ipairs(SLOTS) do
        local choice=build.slots[def.key]
        if choice and not ownership[def.key] then
            local baseKey=ChoiceBaseKey(choice)
            if choice.manualOwned or (baseOwned[baseKey] or 0)>0 then
                ownership[def.key]="wrongTrait"
                if not choice.manualOwned then
                    baseOwned[baseKey]=baseOwned[baseKey]-1
                end
            end
        end
    end
    local lines={"Build: "..(build.name or "Build")}
    for _,def in ipairs(SLOTS) do
        local choice=build.slots[def.key]
        if choice and ownership[def.key]~="exact" then
            local itemName=choice.link and zo_strformat("<<C:1>>",GetItemLinkName(choice.link))
                or GetItemSetName(choice.setId)
            if not choice.link and choice.weaponType then
                itemName=itemName.." "..(WEAPON_TYPE_NAMES[choice.weaponType] or "Weapon")
            end
            local source=BuildSource(choice.setId,choice.link,
                choice.equipType,choice.weaponType)
            local prefix=ownership[def.key]=="wrongTrait" and "Change trait" or "Get"
            table.insert(lines,string.format("[ ] %s %s: %s | %s | %s",prefix,
                def.name,itemName,TRAIT_NAMES[choice.traitType] or "No trait",source))
        end
    end
    if #lines==1 then table.insert(lines,"[x] All planned pieces are owned") end
    return lines
end


function KPH:CreateBuildPlannerWindow()
    if self.buildPlannerWindow then return end
    local w=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."BuildPlanner")
    local windowWidth=math.min(1220,GuiRoot:GetWidth()-40)
    local columnGap=24
    local columnWidth=(windowWidth-48-columnGap)/2
    local traitWidth=110
    local itemWidth=columnWidth-traitWidth-6
    w:SetDimensions(windowWidth,560)
    w:SetAnchor(CENTER,GuiRoot,CENTER,0,0)
    w:SetClampedToScreen(true)
    w:SetMouseEnabled(true)
    w:SetMovable(true)
    w:SetHidden(true)
    local bg=WINDOW_MANAGER:CreateControlFromVirtual(self.name.."BuildPlannerBG",w,"ZO_DefaultBackdrop")
    bg:SetAnchorFill(w)
    local title=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    title:SetAnchor(TOPLEFT,w,TOPLEFT,24,18)
    title:SetFont("ZoFontWinH1")
    local close=WINDOW_MANAGER:CreateControlFromVirtual(self.name.."BuildPlannerClose",w,"ZO_CloseButton")
    close:SetAnchor(TOPRIGHT,w,TOPRIGHT,-8,8)
    close:SetHandler("OnClicked",function()self:HideBuildPlanner()end)
    local help=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    help:SetAnchor(TOPLEFT,w,TOPLEFT,24,58)
    help:SetFont("ZoFontGameSmall")
    local importOpen=WINDOW_MANAGER:CreateControl(
        self.name.."BuildImportOpen",w,CT_BUTTON)
    importOpen:SetDimensions(180,30)
    importOpen:SetAnchor(TOPRIGHT,w,TOPRIGHT,-50,52)
    importOpen:SetFont("ZoFontGameBold")
    importOpen:SetNormalFontColor(1,0.85,0.35,1)
    importOpen:SetMouseOverFontColor(1,1,1,1)
    importOpen:SetText("Import Build")
    importOpen:SetHandler("OnClicked",function() self:OpenBuildImport() end)
    help:SetText("Left: choose set. Right: weapon/weight. Shift+Right: trait. Ctrl+Left: mark owned.")
    local counters=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    counters:SetAnchor(TOPLEFT,w,TOPLEFT,24,88)
    counters:SetFont("ZoFontGame")
    counters:SetDimensions(windowWidth-50,28)

    local searchBG=WINDOW_MANAGER:CreateControl(
        self.name.."BuildSearchBG",w,CT_BACKDROP)
    searchBG:SetDimensions(560,198)
    searchBG:SetAnchor(TOP,w,TOP,0,62)
    searchBG:SetCenterTexture("EsoUI/Art/Tooltips/UI-TooltipCenter.dds")
    searchBG:SetEdgeTexture("EsoUI/Art/Tooltips/UI-Border.dds",128,16)
    searchBG:SetInsets(10,10,-10,-10)
    searchBG:SetDrawTier(DT_HIGH)
    searchBG:SetDrawLayer(DL_BACKGROUND)
    searchBG:SetDrawLevel(0)
    searchBG:SetMouseEnabled(false)
    searchBG:SetHidden(true)
    local edit=WINDOW_MANAGER:CreateControl(
        self.name.."BuildSearchEdit",searchBG,CT_EDITBOX)
    edit:SetAnchor(TOPLEFT,searchBG,TOPLEFT,18,10)
    edit:SetDimensions(524,28)
    edit:SetFont("ZoFontGame")
    edit:SetDrawTier(DT_HIGH)
    edit:SetDrawLayer(DL_OVERLAY)
    edit:SetDrawLevel(10)
    edit:SetColor(1,1,1,1)
    edit:SetMouseEnabled(true)
    edit:SetEditEnabled(true)
    edit:SetMaxInputChars(80)
    local searchButtons={}
    for i=1,6 do
        local resultButton=WINDOW_MANAGER:CreateControl(
            self.name.."BuildSearchResult"..i,searchBG,CT_BUTTON)
        resultButton:SetDimensions(524,23)
        resultButton:SetAnchor(TOPLEFT,edit,BOTTOMLEFT,0,5+(i-1)*24)
        resultButton:SetFont("ZoFontGameSmall")
        resultButton:SetDrawTier(DT_HIGH)
        resultButton:SetDrawLayer(DL_OVERLAY)
        resultButton:SetDrawLevel(20+i)
        resultButton:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        resultButton:SetHandler("OnClicked",function()
            self:AcceptBuildSlotSearch(i)
        end)
        resultButton:SetHidden(true)
        searchButtons[i]=resultButton
    end
    edit:SetHandler("OnTextChanged",function(control)
        self:UpdateBuildSlotSearch(control:GetText())
    end)
    edit:SetHandler("OnEnter",function() self:AcceptBuildSlotSearch() end)
    edit:SetHandler("OnEscape",function(control)
        control:LoseFocus()
        searchBG:SetHidden(true)
    end)
    local importBG=WINDOW_MANAGER:CreateControl(
        self.name.."BuildImportBG",w,CT_BACKDROP)
    importBG:SetDimensions(820,430)
    importBG:SetAnchor(CENTER,w,CENTER,0,0)
    importBG:SetCenterTexture("EsoUI/Art/Tooltips/UI-TooltipCenter.dds")
    importBG:SetEdgeTexture("EsoUI/Art/Tooltips/UI-Border.dds",128,16)
    importBG:SetInsets(12,12,-12,-12)
    importBG:SetDrawTier(DT_HIGH)
    importBG:SetDrawLayer(DL_OVERLAY)
    importBG:SetDrawLevel(100)
    importBG:SetMouseEnabled(true)
    importBG:SetHidden(true)
    local importTitle=WINDOW_MANAGER:CreateControl(nil,importBG,CT_LABEL)
    importTitle:SetAnchor(TOPLEFT,importBG,TOPLEFT,20,16)
    importTitle:SetFont("ZoFontWinH2")
    importTitle:SetText("Import Build")
    importTitle:SetDrawTier(DT_HIGH)
    importTitle:SetDrawLayer(DL_OVERLAY)
    importTitle:SetDrawLevel(101)
    local importClose=WINDOW_MANAGER:CreateControl(
        self.name.."BuildImportClose",importBG,CT_BUTTON)
    importClose:SetDimensions(36,36)
    importClose:SetAnchor(TOPRIGHT,importBG,TOPRIGHT,-10,8)
    importClose:SetFont("ZoFontWinH2")
    importClose:SetText("X")
    importClose:SetNormalFontColor(1,0.45,0.35,1)
    importClose:SetMouseOverFontColor(1,1,1,1)
    importClose:SetDrawTier(DT_HIGH)
    importClose:SetDrawLayer(DL_OVERLAY)
    importClose:SetDrawLevel(105)
    importClose:SetHandler("OnClicked",function() self:CloseBuildImport() end)
    StyleModalButton(importClose,"X",0.9,0.2,0.15)
    local importHelp=WINDOW_MANAGER:CreateControl(nil,importBG,CT_LABEL)
    importHelp:SetAnchor(TOPLEFT,importTitle,BOTTOMLEFT,0,6)
    importHelp:SetDimensions(770,38)
    importHelp:SetFont("ZoFontGameSmall")
    importHelp:SetText("Copy the default prompt to ChatGPT (Ctrl+A, Ctrl+C). Replace it with the KEHBUILD response, then click Import.")
    importHelp:SetDrawTier(DT_HIGH)
    importHelp:SetDrawLayer(DL_OVERLAY)
    importHelp:SetDrawLevel(101)
    local importEditBG=WINDOW_MANAGER:CreateControl(
        self.name.."BuildImportEditBG",importBG,CT_BACKDROP)
    importEditBG:SetAnchor(TOPLEFT,importBG,TOPLEFT,20,88)
    importEditBG:SetDimensions(780,275)
    importEditBG:SetCenterColor(0,0,0,0.9)
    importEditBG:SetEdgeColor(0.6,0.6,0.5,1)
    importEditBG:SetDrawTier(DT_HIGH)
    importEditBG:SetDrawLayer(DL_OVERLAY)
    importEditBG:SetDrawLevel(102)
    local importEdit=WINDOW_MANAGER:CreateControl(
        self.name.."BuildImportEdit",importEditBG,CT_EDITBOX)
    importEdit:SetAnchor(TOPLEFT,importEditBG,TOPLEFT,10,8)
    importEdit:SetDimensions(760,259)
    importEdit:SetFont("ZoFontGame")
    importEdit:SetColor(1,1,1,1)
    importEdit:SetMultiLine(true)
    importEdit:SetNewLineEnabled(true)
    importEdit:SetMaxInputChars(5000)
    importEdit:SetMouseEnabled(true)
    importEdit:SetEditEnabled(true)
    importEdit:SetDrawTier(DT_HIGH)
    importEdit:SetDrawLayer(DL_OVERLAY)
    importEdit:SetDrawLevel(103)
    local importConfirm=WINDOW_MANAGER:CreateControl(
        self.name.."BuildImportConfirm",importBG,CT_BUTTON)
    importConfirm:SetDimensions(180,34)
    importConfirm:SetAnchor(BOTTOMRIGHT,importBG,BOTTOMRIGHT,-20,-18)
    importConfirm:SetText("Import")
    importConfirm:SetFont("ZoFontGameBold")
    importConfirm:SetNormalFontColor(0.45,1,0.45,1)
    importConfirm:SetMouseOverFontColor(1,1,1,1)
    importConfirm:SetDrawTier(DT_HIGH)
    importConfirm:SetDrawLayer(DL_OVERLAY)
    importConfirm:SetDrawLevel(104)
    importConfirm:SetHandler("OnClicked",function()
        self:ImportBuildText(importEdit:GetText())
    end)
    StyleModalButton(importConfirm,"Import",0.2,0.75,0.25)
    local importCancel=WINDOW_MANAGER:CreateControl(
        self.name.."BuildImportCancel",importBG,CT_BUTTON)
    importCancel:SetDimensions(250,34)
    importCancel:SetAnchor(RIGHT,importConfirm,LEFT,-12,0)
    importCancel:SetText("Close / Release Keyboard")
    importCancel:SetFont("ZoFontGameBold")
    importCancel:SetNormalFontColor(1,0.55,0.45,1)
    importCancel:SetMouseOverFontColor(1,1,1,1)
    importCancel:SetDrawTier(DT_HIGH)
    importCancel:SetDrawLayer(DL_OVERLAY)
    importCancel:SetDrawLevel(104)
    importCancel:SetHandler("OnClicked",function()
        self:CloseBuildImport()
    end)
    StyleModalButton(importCancel,"Close / Release Keyboard",0.8,0.45,0.15)
    importEdit:SetHandler("OnEscape",function()
        self:CloseBuildImport()
    end)
    local previousBuild=WINDOW_MANAGER:CreateControl(
        self.name.."PreviousBuild",w,CT_BUTTON)
    previousBuild:SetDimensions(180,32)
    previousBuild:SetAnchor(BOTTOMLEFT,w,BOTTOMLEFT,24,-12)
    previousBuild:SetFont("ZoFontGameBold")
    previousBuild:SetText("< Previous Build")
    previousBuild:SetNormalFontColor(1,0.85,0.35,1)
    previousBuild:SetMouseOverFontColor(1,1,1,1)
    previousBuild:SetHandler("OnClicked",function() self:CycleSavedBuild(-1) end)
    local nextBuild=WINDOW_MANAGER:CreateControl(
        self.name.."NextBuild",w,CT_BUTTON)
    nextBuild:SetDimensions(180,32)
    nextBuild:SetAnchor(LEFT,previousBuild,RIGHT,12,0)
    nextBuild:SetFont("ZoFontGameBold")
    nextBuild:SetText("Next Build >")
    nextBuild:SetNormalFontColor(1,0.85,0.35,1)
    nextBuild:SetMouseOverFontColor(1,1,1,1)
    nextBuild:SetHandler("OnClicked",function() self:CycleSavedBuild(1) end)
    local deleteBuild=WINDOW_MANAGER:CreateControl(
        self.name.."DeleteBuild",w,CT_BUTTON)
    deleteBuild:SetDimensions(190,32)
    deleteBuild:SetAnchor(LEFT,nextBuild,RIGHT,12,0)
    deleteBuild:SetFont("ZoFontGameBold")
    deleteBuild:SetText("Delete Build")
    deleteBuild:SetNormalFontColor(1,0.45,0.35,1)
    deleteBuild:SetMouseOverFontColor(1,1,1,1)
    deleteBuild:SetHandler("OnClicked",function(control)
        self:DeleteActiveBuild(control)
    end)
    local exportBuild=WINDOW_MANAGER:CreateControl(
        self.name.."ExportBuild",w,CT_BUTTON)
    exportBuild:SetDimensions(180,32)
    exportBuild:SetAnchor(LEFT,deleteBuild,RIGHT,12,0)
    exportBuild:SetFont("ZoFontGameBold")
    exportBuild:SetText("Export Build")
    exportBuild:SetNormalFontColor(0.45,0.85,1,1)
    exportBuild:SetMouseOverFontColor(1,1,1,1)
    exportBuild:SetHandler("OnClicked",function() self:OpenBuildExport() end)
    self.buildSlotButtons={}
    self.buildTraitButtons={}
    for col=0,1 do
        local traitHeader=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
        traitHeader:SetDimensions(traitWidth,20)
        traitHeader:SetAnchor(TOPLEFT,w,TOPLEFT,
            24+col*(columnWidth+columnGap)+itemWidth+6,108)
        traitHeader:SetFont("ZoFontGameSmall")
        traitHeader:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        traitHeader:SetText("TRAIT")
    end
    for i,def in ipairs(SLOTS) do
        local col=(i-1)%2
        local row=math.floor((i-1)/2)
        local b=WINDOW_MANAGER:CreateControlFromVirtual(self.name.."BuildSlot"..i,w,"ZO_DefaultButton")
        b:SetDimensions(itemWidth,38)
        b:SetAnchor(TOPLEFT,w,TOPLEFT,
            24+col*(columnWidth+columnGap),128+row*52)
        b:SetFont("ZoFontGameSmall")
        b:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        b:SetHandler("OnMouseUp",function(_,mouseButton,upInside)
            if upInside==false then return end
            if mouseButton==MOUSE_BUTTON_INDEX_RIGHT then
                if IsShiftKeyDown() then self:CycleBuildTrait(def)
                else self:CycleBuildSlot(def,true) end
            elseif mouseButton==MOUSE_BUTTON_INDEX_LEFT then
                if IsControlKeyDown() then self:ToggleManualBuildOwned(def,false)
                else self:OpenBuildSlotSearch(def) end
            end
        end)
        self.buildSlotButtons[def.key]=b
        local traitButton=WINDOW_MANAGER:CreateControl(
            self.name.."BuildTrait"..i,w,CT_BUTTON)
        traitButton:SetDimensions(traitWidth,38)
        traitButton:SetAnchor(LEFT,b,RIGHT,6,0)
        traitButton:SetFont("ZoFontGameSmall")
        traitButton:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        traitButton:SetNormalFontColor(1,1,1,1)
        traitButton:SetMouseOverFontColor(1,0.85,0.35,1)
        traitButton:SetHandler("OnClicked",function()
            if IsControlKeyDown() then self:ToggleManualBuildOwned(def,true)
            else self:CycleBuildTrait(def) end
        end)
        self.buildTraitButtons[def.key]=traitButton
    end
    self.buildPlannerWindow=w
    self.buildPlannerTitle=title
    self.buildPlannerCounters=counters
    self.buildSearchBackdrop=searchBG
    self.buildSearchEdit=edit
    self.buildSearchButtons=searchButtons
    self.buildImportBackdrop=importBG
    self.buildImportEdit=importEdit
    self.buildImportTitle=importTitle
    self.buildImportHelp=importHelp
    self.buildImportConfirm=importConfirm
end

function KPH:CreateBuildLauncher()
    if self.buildLauncher then return end
    local launcher=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."BuildLauncher")
    launcher:SetDimensions(386,44)
    launcher:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,
        self.savedVariables.buildLauncherX or 20,
        self.savedVariables.buildLauncherY or 300)
    launcher:SetClampedToScreen(true)
    launcher:SetMouseEnabled(true)
    launcher:SetMovable(true)
    local bg=WINDOW_MANAGER:CreateControlFromVirtual(
        self.name.."BuildLauncherBG",launcher,"ZO_DefaultBackdrop")
    bg:SetAnchorFill(launcher)
    bg:SetMouseEnabled(false)
    local label=WINDOW_MANAGER:CreateControl(nil,launcher,CT_LABEL)
    label:SetDimensions(50,44)
    label:SetAnchor(LEFT,launcher,LEFT,0,0)
    label:SetFont("ZoFontGameBold")
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    label:SetColor(1,0.85,0.35,1)
    label:SetText("KEH")
    label:SetMouseEnabled(false)
    local function AddIconButton(key,anchor,texturePath,color,tooltip,callback)
        local button=WINDOW_MANAGER:CreateControl(
            self.name.."BuildLauncher"..key,launcher,CT_BUTTON)
        button:SetDimensions(46,40)
        button:SetAnchor(LEFT,anchor,RIGHT,2,0)
        local icon=WINDOW_MANAGER:CreateControl(nil,button,CT_TEXTURE)
        icon:SetDimensions(32,32)
        icon:SetAnchor(CENTER,button,CENTER,0,0)
        icon:SetTexture(texturePath)
        icon:SetColor(color[1],color[2],color[3],1)
        button:SetHandler("OnClicked",callback)
        button:SetHandler("OnMouseEnter",function(control)
            icon:SetColor(1,1,1,1)
            InitializeTooltip(InformationTooltip,control,BOTTOM,0,-6,TOP)
            SetTooltipText(InformationTooltip,tooltip)
        end)
        button:SetHandler("OnMouseExit",function()
            icon:SetColor(color[1],color[2],color[3],1)
            ClearTooltip(InformationTooltip)
        end)
        return button
    end
    local buildButton=AddIconButton("Build",label,
        "EsoUI/Art/MainMenu/menubar_character_up.dds",{1,0.85,0.35},
        "Build Planner",function() self:ShowBuildPlanner() end)
    local findButton=AddIconButton("Find",buildButton,
        "EsoUI/Art/MainMenu/menubar_map_up.dds",{0.45,0.85,1},
        "Item Finder",function() self:ShowItemFinder() end)
    local setsButton=AddIconButton("Sets",findButton,
        "EsoUI/Art/MainMenu/menubar_collections_up.dds",{0.95,0.65,0.3},
        "Set Tracker",function()
            self:CreateSetPlannerWindow()
            self:RefreshSetPlanner()
            self.setPlannerWindow:SetHidden(false)
            SCENE_MANAGER:SetInUIMode(true)
        end)
    local inventoryButton=AddIconButton("Inventory",setsButton,
        "EsoUI/Art/MainMenu/menubar_inventory_up.dds",{0.55,1,0.55},
        "Inventory Manager",function() self:ToggleInventoryManagerPanel() end)
    local notesButton=AddIconButton("Notes",inventoryButton,
        "EsoUI/Art/MainMenu/menubar_journal_up.dds",{1,0.75,0.35},
        "Notepad",function() self:ToggleNotepad() end)
    local mythicButton=AddIconButton("Mythic",notesButton,
        "EsoUI/Art/MainMenu/menubar_skills_up.dds",{0.8,0.55,1},
        "Mythic Helper",function() self:ShowMythicHelper() end)
    AddIconButton("Gold",mythicButton,
        "EsoUI/Art/currency/currency_gold.dds",{1,0.78,0.2},
        "Goldmaker",function() self:ShowGoldmaker() end)
    launcher:SetHandler("OnMouseDown",function(control)
        control.kehStartLeft=control:GetLeft()
        control.kehStartTop=control:GetTop()
    end)
    launcher:SetHandler("OnMouseUp",function(control,mouseButton,upInside)
        if mouseButton==MOUSE_BUTTON_INDEX_LEFT and upInside then
            local moved=math.abs((control:GetLeft() or 0)-(control.kehStartLeft or 0))+
                math.abs((control:GetTop() or 0)-(control.kehStartTop or 0))
            if moved<4 then self:ShowBuildPlanner() end
        end
    end)
    launcher:SetHandler("OnMoveStop",function(control)
        self.savedVariables.buildLauncherX=control:GetLeft()
        self.savedVariables.buildLauncherY=control:GetTop()
    end)
    self.buildLauncher=launcher
end

function KPH:InitializeBuildPlanner()
    self.buildSetSearchIndex=nil
    self:GetActiveBuild()
    self:CreateBuildLauncher()
    SLASH_COMMANDS["/kehimport"]=function()
        self:ShowBuildPlanner()
        self:OpenBuildImport()
    end
    SLASH_COMMANDS["/kehplan"]=function(text)
        local id=self:FindBuildSet(text)
        if not id then return end
        local build=self:GetActiveBuild()
        for _,existing in ipairs(build.sets) do if existing==id then
            d("[KEH] The set is already in this build.")
            return
        end end
        table.insert(build.sets,id)
        d("[KEH] Added "..GetItemSetName(id).." to "..build.name)
        self:ShowBuildPlanner()
    end
    SLASH_COMMANDS["/kehbuild"]=function(text)
        text=zo_strtrim(text or "")
        local command,name=text:match("^(%S+)%s*(.-)$")
        if command=="list" then
            d("[KEH] Saved builds:")
            for buildName in pairs(self.savedVariables.buildPlans) do
                local marker=buildName==self.savedVariables.activeBuildName and "* " or "  "
                d(marker..buildName)
            end
        elseif command=="new" and name~="" then
            self.savedVariables.activeBuildName=name
            self.savedVariables.buildPlans[name]={name=name,sets={},slots={}}
        elseif command=="use" and self.savedVariables.buildPlans[name] then
            self.savedVariables.activeBuildName=name
        elseif command=="delete" and self.savedVariables.buildPlans[name] then
            self.savedVariables.buildPlans[name]=nil
            self.savedVariables.activeBuildName="Build 1"
        end
        self:ShowBuildPlanner()
    end
    self.buildNotifiedKeys={}
    EVENT_MANAGER:RegisterForEvent(self.name.."BuildPlannerLoot",
        EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
        function(_,bagId,slotIndex,isNewItem,_,_,stackCountChange)
            if not self.savedVariables.plannerNotifications then return end
            if bagId~=BAG_BACKPACK or (not isNewItem and (stackCountChange or 0)<=0) then return end
            local link=GetItemLink(bagId,slotIndex,LINK_STYLE_DEFAULT)
            if not link or link=="" then return end
            local hasSet,_,_,_,_,setId=GetItemLinkSetInfo(link,false)
            if not hasSet then return end
            local foundKey=PieceBaseKey(setId,link)
            for _,choice in pairs(self:GetActiveBuild().slots) do
                if choice.setId==setId and ChoiceBaseKey(choice)==foundKey and
                   not self.buildNotifiedKeys[foundKey] then
                    self.buildNotifiedKeys[foundKey]=true
                    self:ShowPlannerPieceFound(link)
                    self:RefreshBuildPlanner()
                    return
                end
            end
        end)
end

local KPH = KjellmanESOHelper

function KPH:IsLibSetsReady()
    return LibSets and type(LibSets.AreSetsLoaded) == "function" and
        LibSets.AreSetsLoaded()
end

function KPH:GetLibSetsIdByName(name)
    if not self:IsLibSetsReady() or not name or name == "" or
       type(LibSets.GetSetByName) ~= "function" then return nil end
    local formattedName = zo_strformat("<<C:1>>", name)
    local exactId = LibSets.GetSetByName(formattedName, "en")
    if exactId then return exactId end
    if not self.libSetsNormalizedNameIndex and
       type(LibSets.GetAllSetNames) == "function" then
        self.libSetsNormalizedNameIndex = {}
        for candidateId, names in pairs(LibSets.GetAllSetNames() or {}) do
            for _, candidateName in pairs(names or {}) do
                local key = self:NormalizeSetDataName(candidateName)
                if key ~= "" then
                    self.libSetsNormalizedNameIndex[key] = candidateId
                end
            end
        end
    end
    return self.libSetsNormalizedNameIndex and
        self.libSetsNormalizedNameIndex[self:NormalizeSetDataName(formattedName)]
end

function KPH:NormalizeSetDataName(value)
    local name = zo_strlower(zo_strformat("<<C:1>>", value or ""))
    return name:gsub("['’`%-%.%s]", "")
end

function KPH:GetSetDataIdentity(setId, knownName)
    local name = knownName or GetItemSetName(setId)
    if name and name ~= "" then return zo_strlower(name) end
    return tostring(setId or 0)
end

function KPH:CanonicalizeSetId(setId, knownName)
    if not setId or setId <= 0 then return setId end
    local name = knownName or GetItemSetName(setId)
    if name and name ~= "" then
        return self:GetLibSetsIdByName(name) or setId
    end
    return setId
end

function KPH:GetLibSetsPieceDefinitions(setId)
    if not self:IsLibSetsReady() or type(LibSets.GetSetItemIds) ~= "function" or
       type(LibSets.buildItemLink) ~= "function" then return {} end
    setId = self:CanonicalizeSetId(setId)
    local itemIds = LibSets.GetSetItemIds(setId)
    local pieces, seen = {}, {}
    for itemId in pairs(itemIds or {}) do
        local link = LibSets.buildItemLink(itemId, 367)
        if link and link ~= "" then
            local key = self:GetSetPieceTypeKey(link)
            if key and not seen[key] then
                table.insert(pieces, {
                    key = key,
                    name = zo_strformat("<<C:1>>", GetItemLinkName(link)),
                    link = link,
                    itemId = itemId,
                })
                seen[key] = true
            end
        end
    end
    table.sort(pieces, function(a, b) return (a.name or "") < (b.name or "") end)
    return pieces
end

function KPH:GetSetDataPieceDefinitions(setId)
    setId = self:CanonicalizeSetId(setId)
    local pieces = {}
    local count = GetNumItemSetCollectionPieces(setId) or 0
    for index = 1, count do
        local pieceId, collectionSlot = GetItemSetCollectionPieceInfo(setId, index)
        local link = GetItemSetCollectionPieceItemLink(pieceId, LINK_STYLE_DEFAULT,
            ITEM_TRAIT_TYPE_NONE, ITEM_FUNCTIONAL_QUALITY_MAGIC)
        if link and link ~= "" then
            table.insert(pieces, {
                key = self:GetSetPieceTypeKey(link),
                name = zo_strformat("<<C:1>>", GetItemLinkName(link)),
                link = link,
                collectionSlot = collectionSlot,
            })
        end
    end
    if #pieces > 0 then return pieces, true end
    pieces = self:GetLibSetsPieceDefinitions(setId)
    if #pieces > 0 then return pieces, false end
    return self:GetCraftedSetPieceDefinitions(), false
end

function KPH:GetSetCollectionNames(setId)
    setId = self:CanonicalizeSetId(setId)
    local names, categoryId, safety = {}, GetItemSetCollectionCategoryId(setId), 0
    while categoryId and categoryId > 0 and safety < 8 do
        local name = GetItemSetCollectionCategoryName(categoryId)
        if name and name ~= "" then table.insert(names, 1, name) end
        categoryId = GetItemSetCollectionCategoryParentId(categoryId)
        safety = safety + 1
    end
    return names
end

function KPH:GetSetCollectionLocation(setId)
    local names = self:GetSetCollectionNames(setId)
    return #names > 0 and table.concat(names, " > ") or "Unknown location"
end

function KPH:GetSetPieceTypeKey(itemLink)
    local weaponType = GetItemLinkWeaponType(itemLink)
    if weaponType and weaponType ~= WEAPONTYPE_NONE then
        return string.format("w:%d", weaponType)
    end
    local equipType = GetItemLinkEquipType(itemLink) or 0
    local armorType = GetItemLinkArmorType(itemLink)
    if armorType and armorType ~= ARMORTYPE_NONE then
        return string.format("e:%d:a:%d", equipType, armorType)
    end
    return string.format("e:%d", equipType)
end

function KPH:GetSetPieceSource(setId, itemLink, equipOverride, weaponOverride)
    setId = self:CanonicalizeSetId(setId)
    local setType = GetItemSetType(setId)
    local equipType = itemLink and GetItemLinkEquipType(itemLink) or equipOverride
    local weaponType = itemLink and GetItemLinkWeaponType(itemLink) or weaponOverride
    local isWeapon = weaponType and weaponType ~= WEAPONTYPE_NONE
    if ITEM_SET_TYPE_MYTHIC and setType == ITEM_SET_TYPE_MYTHIC then
        return "Antiquities leads (often several zones)"
    elseif setType == ITEM_SET_TYPE_WORLD then
        if equipType == EQUIP_TYPE_WAIST or equipType == EQUIP_TYPE_FEET then
            return "Delve boss"
        elseif equipType == EQUIP_TYPE_HEAD or equipType == EQUIP_TYPE_CHEST or
               equipType == EQUIP_TYPE_LEGS then return "World boss"
        elseif equipType == EQUIP_TYPE_SHOULDERS or equipType == EQUIP_TYPE_HAND then
            return "Public dungeon boss"
        elseif equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK then
            return "Dark Anchor / zone world event"
        elseif isWeapon then return "World boss / public dungeon boss" end
        return "Overland activity / treasure chest"
    elseif setType == ITEM_SET_TYPE_DUNGEON then
        if isWeapon or equipType == EQUIP_TYPE_RING or equipType == EQUIP_TYPE_NECK then
            return "Dungeon final boss"
        elseif equipType == EQUIP_TYPE_WAIST or equipType == EQUIP_TYPE_HAND or
               equipType == EQUIP_TYPE_FEET then return "Dungeon mini-bosses" end
        return "Dungeon bosses"
    elseif setType == ITEM_SET_TYPE_MONSTER then
        return equipType == EQUIP_TYPE_HEAD and "Veteran dungeon final boss" or
            "Undaunted shoulder coffer"
    elseif setType == ITEM_SET_TYPE_CRAFTED then return "Crafting station"
    elseif setType == ITEM_SET_TYPE_WEAPON then return "Arena / special activity" end
    return "Set activity"
end

function KPH:GetSetGeneralSource(setId)
    setId = self:CanonicalizeSetId(setId)
    local setType = GetItemSetType(setId)
    if ITEM_SET_TYPE_MYTHIC and setType == ITEM_SET_TYPE_MYTHIC then
        return "Antiquities leads (often several zones)"
    elseif setType == ITEM_SET_TYPE_WORLD then
        return "Overland bosses, delves, public dungeons and world events"
    elseif setType == ITEM_SET_TYPE_DUNGEON then
        return "Dungeon bosses; weapons and jewelry from the final boss"
    elseif setType == ITEM_SET_TYPE_MONSTER then
        return "Head: veteran final boss. Shoulder: Undaunted coffer"
    elseif setType == ITEM_SET_TYPE_CRAFTED then return "Crafting station"
    elseif setType == ITEM_SET_TYPE_WEAPON then return "Arena / special activity" end
    return "Set activity"
end

function KPH:GetCraftedSetPieceDefinitions()
    if self.craftedSetPieceDefinitions then return self.craftedSetPieceDefinitions end
    local definitions = {}
    local armorTypes = {
        { name="Light", value=ARMORTYPE_LIGHT },
        { name="Medium", value=ARMORTYPE_MEDIUM },
        { name="Heavy", value=ARMORTYPE_HEAVY },
    }
    local armorSlots = {
        { name="Head", value=EQUIP_TYPE_HEAD },
        { name="Shoulders", value=EQUIP_TYPE_SHOULDERS },
        { name="Chest", value=EQUIP_TYPE_CHEST },
        { name="Hands", value=EQUIP_TYPE_HAND },
        { name="Waist", value=EQUIP_TYPE_WAIST },
        { name="Legs", value=EQUIP_TYPE_LEGS },
        { name="Feet", value=EQUIP_TYPE_FEET },
    }
    for _, armor in ipairs(armorTypes) do
        for _, slot in ipairs(armorSlots) do
            table.insert(definitions, {
                name=armor.name .. " " .. slot.name,
                key=string.format("e:%d:a:%d", slot.value, armor.value),
            })
        end
    end
    local remaining = {
        { name="Necklace", key="e:"..EQUIP_TYPE_NECK },
        { name="Ring", key="e:"..EQUIP_TYPE_RING },
        { name="Sword", key="w:"..WEAPONTYPE_SWORD },
        { name="Axe", key="w:"..WEAPONTYPE_AXE },
        { name="Mace", key="w:"..WEAPONTYPE_HAMMER },
        { name="Dagger", key="w:"..WEAPONTYPE_DAGGER },
        { name="Greatsword", key="w:"..WEAPONTYPE_TWO_HANDED_SWORD },
        { name="Battle Axe", key="w:"..WEAPONTYPE_TWO_HANDED_AXE },
        { name="Maul", key="w:"..WEAPONTYPE_TWO_HANDED_HAMMER },
        { name="Bow", key="w:"..WEAPONTYPE_BOW },
        { name="Inferno Staff", key="w:"..WEAPONTYPE_FIRE_STAFF },
        { name="Ice Staff", key="w:"..WEAPONTYPE_FROST_STAFF },
        { name="Lightning Staff", key="w:"..WEAPONTYPE_LIGHTNING_STAFF },
        { name="Restoration Staff", key="w:"..WEAPONTYPE_HEALING_STAFF },
        { name="Shield", key="w:"..WEAPONTYPE_SHIELD },
    }
    for _, definition in ipairs(remaining) do
        table.insert(definitions, definition)
    end
    self.craftedSetPieceDefinitions = definitions
    return definitions
end

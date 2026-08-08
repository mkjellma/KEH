KjellmanESOHelper = KjellmanESOHelper or {}
local KPH = KjellmanESOHelper
local NOTE_TABS={"General","Farming","Shopping","Build"}

function KPH:EnsureNotepadData()
    self.savedVariables.notepadTabs=self.savedVariables.notepadTabs or {}
    if not self.savedVariables.notepadTabs.General then
        self.savedVariables.notepadTabs.General=self.savedVariables.notepadText or ""
    end
    for _,name in ipairs(NOTE_TABS) do
        if self.savedVariables.notepadTabs[name]==nil then
            self.savedVariables.notepadTabs[name]=""
        end
    end
    self.savedVariables.notepadActiveTab=
        self.savedVariables.notepadActiveTab or "General"
end

function KPH:SaveNotepadTab()
    if not self.notepadEdit then return end
    self:EnsureNotepadData()
    local name=self.savedVariables.notepadActiveTab
    self.savedVariables.notepadTabs[name]=self.notepadEdit:GetText() or ""
    if name=="General" then self.savedVariables.notepadText=self.savedVariables.notepadTabs[name] end
end

function KPH:SwitchNotepadTab(name)
    self:SaveNotepadTab()
    self.savedVariables.notepadActiveTab=name
    self.notepadEdit:SetText(self.savedVariables.notepadTabs[name] or "")
    for tabName,button in pairs(self.notepadTabButtons or {}) do
        button:SetNormalFontColor(tabName==name and 1 or 0.7,
            tabName==name and 0.8 or 0.7,tabName==name and 0.3 or 0.7,1)
    end
    self:FocusNotepad()
end

function KPH:AppendNotepadText(text)
    local old=self.notepadEdit:GetText() or ""
    local separator=old=="" and "" or (old:sub(-1)=="\n" and "" or "\n")
    self.notepadEdit:SetText(old..separator..(text or ""))
    self:SaveNotepadTab()
    self:FocusNotepad()
end

function KPH:AddChecklistLine()
    self:AppendNotepadText("[ ] ")
end

function KPH:ToggleChecklistLines()
    local text=self.notepadEdit:GetText() or ""
    local changed=false
    text=text:gsub("%[ %]",function()
        if changed then return "[ ]" end
        changed=true return "[x]"
    end)
    if not changed then
        text=text:gsub("%[[xX]%]",function()
            if changed then return "[x]" end
            changed=true return "[ ]"
        end)
    end
    self.notepadEdit:SetText(text)
    self:SaveNotepadTab()
    self:FocusNotepad()
end

function KPH:AddMissingBuildToNotepad()
    self:SwitchNotepadTab("Build")
    self:AppendNotepadText(table.concat(self:GetMissingBuildNoteLines(),"\n"))
end

function KPH:ExportNotepadText()
    self:SaveNotepadTab()
    local lines={"KEHNOTE:1"}
    for _,name in ipairs(NOTE_TABS) do
        table.insert(lines,"[["..name.."]]")
        table.insert(lines,self.savedVariables.notepadTabs[name] or "")
    end
    return table.concat(lines,"\n")
end

function KPH:ImportNotepadText(text)
    if not text or not text:find("^KEHNOTE:1") then return false end
    local tabs={}
    local current
    for line in (text.."\n"):gmatch("(.-)\n") do
        local name=line:match("^%[%[(.-)%]%]$")
        if name then current=name tabs[current]=""
        elseif current then
            tabs[current]=tabs[current]..(tabs[current]=="" and "" or "\n")..line
        end
    end
    for _,name in ipairs(NOTE_TABS) do
        if tabs[name]~=nil then self.savedVariables.notepadTabs[name]=tabs[name] end
    end
    self:SwitchNotepadTab(self.savedVariables.notepadActiveTab)
    return true
end

function KPH:OpenNotepadTransfer()
    if not self.notepadTransfer then
        local panel=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."NotepadTransfer")
        panel:SetDimensions(650,470)
        panel:SetAnchor(CENTER,GuiRoot,CENTER,0,0)
        panel:SetMouseEnabled(true)
        panel:SetHidden(true)
        local bg=WINDOW_MANAGER:CreateControlFromVirtual(
            self.name.."NotepadTransferBG",panel,"ZO_DefaultBackdrop")
        bg:SetAnchorFill(panel)
        local title=WINDOW_MANAGER:CreateControl(nil,panel,CT_LABEL)
        title:SetAnchor(TOPLEFT,panel,TOPLEFT,18,14)
        title:SetFont("ZoFontWinH2")
        title:SetText("KEHNOTE Export / Import")
        local help=WINDOW_MANAGER:CreateControl(nil,panel,CT_LABEL)
        help:SetAnchor(TOPLEFT,panel,TOPLEFT,18,48)
        help:SetFont("ZoFontGameSmall")
        help:SetText("Copy this block, or replace it with a KEHNOTE block and click IMPORT.")
        local editBG=WINDOW_MANAGER:CreateControlFromVirtual(
            self.name.."NotepadTransferEditBG",panel,"ZO_DefaultBackdrop")
        editBG:SetAnchor(TOPLEFT,panel,TOPLEFT,18,75)
        editBG:SetAnchor(BOTTOMRIGHT,panel,BOTTOMRIGHT,-18,-58)
        local edit=WINDOW_MANAGER:CreateControl(
            self.name.."NotepadTransferEdit",editBG,CT_EDITBOX)
        edit:SetAnchor(TOPLEFT,editBG,TOPLEFT,10,8)
        edit:SetAnchor(BOTTOMRIGHT,editBG,BOTTOMRIGHT,-10,-8)
        edit:SetFont("ZoFontGame")
        edit:SetMultiLine(true)
        edit:SetMaxInputChars(30000)
        local close=WINDOW_MANAGER:CreateControl(nil,panel,CT_BUTTON)
        close:SetDimensions(150,34)
        close:SetAnchor(BOTTOMLEFT,panel,BOTTOMLEFT,120,-12)
        close:SetFont("ZoFontGameBold")
        close:SetText("CLOSE")
        close:SetNormalFontColor(1,0.45,0.4,1)
        close:SetHandler("OnClicked",function()
            edit:LoseFocus() panel:SetHidden(true) self:FocusNotepad()
        end)
        local import=WINDOW_MANAGER:CreateControl(nil,panel,CT_BUTTON)
        import:SetDimensions(150,34)
        import:SetAnchor(BOTTOMRIGHT,panel,BOTTOMRIGHT,-120,-12)
        import:SetFont("ZoFontGameBold")
        import:SetText("IMPORT")
        import:SetNormalFontColor(0.45,1,0.55,1)
        import:SetHandler("OnClicked",function()
            if self:ImportNotepadText(edit:GetText()) then
                PlaySound(SOUNDS.DEFAULT_CLICK)
                edit:LoseFocus() panel:SetHidden(true) self:FocusNotepad()
            else PlaySound(SOUNDS.NEGATIVE_CLICK) end
        end)
        self.notepadTransfer=panel
        self.notepadTransferEdit=edit
    end
    self.notepadTransferEdit:SetText(self:ExportNotepadText())
    self.notepadTransfer:SetHidden(false)
    SetGameCameraUIMode(true)
    self.notepadTransferEdit:TakeFocus()
end

function KPH:FocusNotepad()
    if not self.notepadWindow or self.notepadWindow:IsHidden() then return end
    SetGameCameraUIMode(true)
    zo_callLater(function()
        if self.notepadEdit and not self.notepadWindow:IsHidden() then
            self.notepadEdit:TakeFocus()
        end
    end,1)
end

function KPH:ShowNotepad()
    if not self.notepadWindow then self:CreateNotepadWindow() end
    self.notepadWindow:SetHidden(false)
    self:FocusNotepad()
end

function KPH:ToggleNotepad()
    if not self.notepadWindow then self:CreateNotepadWindow() end
    if self.notepadWindow:IsHidden() then
        self:ShowNotepad()
    else
        self:SaveNotepadTab()
        self.notepadEdit:LoseFocus()
        self.notepadWindow:SetHidden(true)
    end
end

function KPH:AddItemToNotepad(bagId,slotIndex)
    if bagId==nil or slotIndex==nil then return false end
    local link=GetItemLink(bagId,slotIndex,LINK_STYLE_DEFAULT)
    if not link or link=="" then return false end
    if not self.notepadWindow then self:CreateNotepadWindow() end
    local amount=GetSlotStackSize(bagId,slotIndex) or 1
    local line="- "..link
    if amount>1 then line=line.." x"..tostring(amount) end
    self.notepadWindow:SetHidden(false)
    self:AppendNotepadText(line)
    PlaySound(SOUNDS.DEFAULT_CLICK)
    return true
end

function KPH:CreateNotepadWindow()
    if self.notepadWindow then return end
    local w=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."Notepad")
    self:EnsureNotepadData()
    w:SetDimensions(720,500)
    w:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,
        self.savedVariables.notepadX or 380,
        self.savedVariables.notepadY or 220)
    w:SetClampedToScreen(true)
    w:SetMouseEnabled(true)
    w:SetMovable(true)
    w:SetHidden(true)

    local bg=WINDOW_MANAGER:CreateControlFromVirtual(
        self.name.."NotepadBG",w,"ZO_DefaultBackdrop")
    bg:SetAnchorFill(w)
    bg:SetMouseEnabled(true)

    local title=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    title:SetAnchor(TOPLEFT,w,TOPLEFT,18,14)
    title:SetFont("ZoFontWinH2")
    title:SetColor(1,0.85,0.35,1)
    title:SetText("KEH Notepad")

    local help=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    help:SetAnchor(TOPRIGHT,w,TOPRIGHT,-54,19)
    help:SetFont("ZoFontGameSmall")
    help:SetColor(0.75,0.75,0.75,1)
    help:SetText("Use the blue + button on an inventory item to add it")

    local close=WINDOW_MANAGER:CreateControl(self.name.."NotepadClose",w,CT_BUTTON)
    close:SetDimensions(34,34)
    close:SetAnchor(TOPRIGHT,w,TOPRIGHT,-8,7)
    close:SetFont("ZoFontWinH2")
    close:SetText("X")
    close:SetNormalFontColor(1,0.35,0.3,1)
    close:SetMouseOverFontColor(1,1,1,1)
    close:SetHandler("OnClicked",function() self:ToggleNotepad() end)

    self.notepadTabButtons={}
    local previous
    for _,name in ipairs(NOTE_TABS) do
        local tab=WINDOW_MANAGER:CreateControl(self.name.."NotepadTab"..name,w,CT_BUTTON)
        tab:SetDimensions(105,30)
        if previous then tab:SetAnchor(LEFT,previous,RIGHT,4,0)
        else tab:SetAnchor(TOPLEFT,w,TOPLEFT,16,52) end
        tab:SetFont("ZoFontGameBold")
        tab:SetText(name)
        tab:SetMouseOverFontColor(1,1,1,1)
        tab:SetHandler("OnClicked",function() self:SwitchNotepadTab(name) end)
        self.notepadTabButtons[name]=tab
        previous=tab
    end

    local actions={
        {"+ TASK",function() self:AddChecklistLine() end},
        {"TOGGLE",function() self:ToggleChecklistLines() end},
        {"MISSING BUILD",function() self:AddMissingBuildToNotepad() end},
        {"EXPORT / IMPORT",function() self:OpenNotepadTransfer() end},
    }
    previous=nil
    for index,action in ipairs(actions) do
        local button=WINDOW_MANAGER:CreateControl(self.name.."NotepadAction"..index,w,CT_BUTTON)
        button:SetDimensions(index==3 and 145 or (index==4 and 170 or 92),30)
        if previous then button:SetAnchor(LEFT,previous,RIGHT,5,0)
        else button:SetAnchor(TOPLEFT,w,TOPLEFT,16,87) end
        button:SetFont("ZoFontGameBold")
        button:SetText(action[1])
        button:SetNormalFontColor(0.45,0.85,1,1)
        button:SetMouseOverFontColor(1,1,1,1)
        button:SetHandler("OnClicked",action[2])
        previous=button
    end

    local editBG=WINDOW_MANAGER:CreateControlFromVirtual(
        self.name.."NotepadEditBG",w,"ZO_DefaultBackdrop")
    editBG:SetAnchor(TOPLEFT,w,TOPLEFT,16,124)
    editBG:SetAnchor(BOTTOMRIGHT,w,BOTTOMRIGHT,-16,-18)
    editBG:SetMouseEnabled(true)

    local edit=WINDOW_MANAGER:CreateControl(self.name.."NotepadEdit",editBG,CT_EDITBOX)
    edit:SetAnchor(TOPLEFT,editBG,TOPLEFT,12,10)
    edit:SetAnchor(BOTTOMRIGHT,editBG,BOTTOMRIGHT,-12,-10)
    edit:SetFont("ZoFontGame")
    edit:SetColor(1,1,1,1)
    edit:SetMultiLine(true)
    edit:SetMaxInputChars(12000)
    edit:SetText(self.savedVariables.notepadTabs[
        self.savedVariables.notepadActiveTab] or "")
    edit:SetHandler("OnTextChanged",function(control)
        local name=self.savedVariables.notepadActiveTab
        self.savedVariables.notepadTabs[name]=control:GetText() or ""
        if name=="General" then self.savedVariables.notepadText=control:GetText() or "" end
    end)
    edit:SetHandler("OnMouseDown",function() self:FocusNotepad() end)

    local function Refocus()
        self:FocusNotepad()
    end
    w:SetHandler("OnMouseUp",Refocus)
    bg:SetHandler("OnMouseUp",Refocus)
    editBG:SetHandler("OnMouseUp",Refocus)
    w:SetHandler("OnMoveStop",function(control)
        self.savedVariables.notepadX=control:GetLeft()
        self.savedVariables.notepadY=control:GetTop()
        self:FocusNotepad()
    end)

    self.notepadWindow=w
    self.notepadEdit=edit
    self:SwitchNotepadTab(self.savedVariables.notepadActiveTab)
end

function KPH:InitializeNotepad()
    self:CreateNotepadWindow()
    SLASH_COMMANDS["/kehnotes"]=function() self:ToggleNotepad() end
    SLASH_COMMANDS["/kehnote"]=SLASH_COMMANDS["/kehnotes"]
end

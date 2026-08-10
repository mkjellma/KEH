local KPH=KjellmanESOHelper

function KPH:CreateFishingIndicator()
    if self.fishingIndicator then return end
    local w=WINDOW_MANAGER:CreateTopLevelWindow(self.name.."FishingIndicator")
    w:SetDimensions(420,100)
    w:SetAnchor(CENTER,GuiRoot,CENTER,0,-170)
    w:SetDrawTier(DT_HIGH) w:SetDrawLayer(DL_OVERLAY) w:SetDrawLevel(500)
    w:SetMouseEnabled(false) w:SetHidden(true)
    local bg=WINDOW_MANAGER:CreateControlFromVirtual(
        self.name.."FishingIndicatorBG",w,"ZO_DefaultBackdrop")
    bg:SetAnchorFill(w) bg:SetCenterColor(0.02,0.02,0.02,0.92)
    bg:SetEdgeColor(0.2,0.85,1,1) bg:SetMouseEnabled(false)
    local label=WINDOW_MANAGER:CreateControl(nil,w,CT_LABEL)
    label:SetAnchor(CENTER,w,CENTER,0,0)
    label:SetFont("ZoFontWinH1") label:SetColor(0.3,0.9,1,1)
    label:SetText("REEL IN!")
    self.fishingIndicator=w
end

function KPH:NotifyFishingBite()
    local now=GetFrameTimeMilliseconds()
    if now-(self.lastFishingBiteNotification or 0)<2000 then return end
    self.lastFishingBiteNotification=now
    if self.savedVariables.fishingBiteSound then
        PlaySound(SOUNDS.QUEST_OBJECTIVE_INCREMENT)
        zo_callLater(function()
            if self.savedVariables.fishingBiteSound then
                PlaySound(SOUNDS.QUEST_OBJECTIVE_INCREMENT)
            end
        end,220)
    end
    if self.savedVariables.fishingBiteIndicator then
        self:CreateFishingIndicator()
        self.fishingIndicator:SetHidden(false)
        zo_callLater(function()
            if self.fishingIndicator then self.fishingIndicator:SetHidden(true) end
        end,1800)
    end
end

function KPH:InitializeFishingIntegration()
    SLASH_COMMANDS["/kehfishalert"]=function() self:NotifyFishingBite() end
    if not EVENT_VIBRATION then
        self:DebugLog("Fishing vibration event is unavailable")
        return
    end
    local namespace=self.name.."Fishing"
    if EVENT_FISHING_LURE_SET then
        EVENT_MANAGER:RegisterForEvent(namespace,EVENT_FISHING_LURE_SET,
            function() self.fishingLureActive=true end)
    end
    if EVENT_FISHING_LURE_CLEARED then
        EVENT_MANAGER:RegisterForEvent(namespace,EVENT_FISHING_LURE_CLEARED,
            function() self.fishingLureActive=false end)
    end
    EVENT_MANAGER:RegisterForEvent(namespace,EVENT_VIBRATION,
        function(_,duration)
            duration=tonumber(duration) or 0
            -- A fishing bite has a distinctive 2500 ms vibration. Lure events
            -- are not reliable on every input mode, so they must not gate it.
            if math.abs(duration-2500)<=100 then
                self:NotifyFishingBite()
            end
        end)
end

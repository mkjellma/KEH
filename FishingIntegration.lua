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

local function PlayFishingAlertSound()
    -- Use a prominent UI sound. Some clients do not expose every SOUNDS key,
    -- so retain the old quest sound as a safe fallback.
    local sound=SOUNDS and (SOUNDS.DUEL_START or SOUNDS.GENERAL_ALERT_ERROR or
        SOUNDS.QUEST_OBJECTIVE_INCREMENT)
    if sound then PlaySound(sound) end
end

function KPH:NotifyFishingBite(force)
    local now=GetFrameTimeMilliseconds()
    if not force and now-(self.lastFishingBiteNotification or 0)<2000 then return end
    self.lastFishingBiteNotification=now
    if self.savedVariables.fishingBiteSound then
        PlayFishingAlertSound()
        zo_callLater(function()
            if self.savedVariables.fishingBiteSound then
                PlayFishingAlertSound()
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
    -- The test command must always play, even if a real bite just fired.
    SLASH_COMMANDS["/kehfishalert"]=function() self:NotifyFishingBite(true) end
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
        function(...)
            -- EVENT_MANAGER normally supplies eventCode before duration, but
            -- scanning the arguments also works on clients/input modes that
            -- expose a slightly different callback signature.
            local duration=0
            for index=1,select("#",...) do
                local value=tonumber((select(index,...)))
                if value and value>=2250 and value<=2750 then
                    duration=value
                    break
                end
            end
            -- A fishing bite has a distinctive 2500 ms vibration. Lure events
            -- are not reliable on every input mode, so they must not gate it.
            if math.abs(duration-2500)<=250 then
                self:NotifyFishingBite()
            end
        end)
end

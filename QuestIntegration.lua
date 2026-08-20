local KPH = KjellmanESOHelper

function KPH:FocusQuest(journalIndex)
    journalIndex = tonumber(journalIndex)
    if not self.savedVariables.focusNewQuests or not journalIndex or
       not IsValidQuestIndex(journalIndex) then
        return
    end

    local parameter2 = 0
    if CanTrack(TRACK_TYPE_QUEST, journalIndex, parameter2) or
       GetIsTracked(TRACK_TYPE_QUEST, journalIndex, parameter2) then
        SetTracked(TRACK_TYPE_QUEST, true, journalIndex, parameter2)
        SetTrackedIsAssisted(TRACK_TYPE_QUEST, true, journalIndex, parameter2)
        self:DebugLog("New quest focused: " .. tostring(GetJournalQuestName(journalIndex)))
    end
end

function KPH:InitializeQuestIntegration()
    EVENT_MANAGER:RegisterForEvent(self.name .. "QuestFocus", EVENT_QUEST_ADDED,
        function(_, journalIndex)
            -- Let the journal and base-game tracker finish their event chain first.
            zo_callLater(function() self:FocusQuest(journalIndex) end, 50)
        end)
end

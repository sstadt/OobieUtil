-- ------------------------
-- CONFIG
-- ------------------------

-- Faction watch timeout
-- Time in seconds until faction watch is turned off after a faction update
-- 60 = 1 minute, 900 = 15 min, etc.
local OobieUtil_FactionWatchTimeout = 600

-- Auto repair
-- 1 for on, nil for off
local OobieUtil_AutoRepair = 1

-- Auto repair from guild bank, if available
-- 1 for on, nil for off
local OobieUtil_GuildBankAutoRepair = nil

-- ------------------------
-- END CONFIG: DO NOT EDIT
-- BELOW HERE UNLESS YOU
-- KNOW WHAT YOU ARE DOING
-- ------------------------

-- ------------------------
-- GLOBAL VARIABLES
-- ------------------------

OobieUtil=CreateFrame("Frame", "OobieUtil", UIParent)

-- faction watch timeout
local OobieUtil_FactionWatchActive = 1
OobieUtil.TimeSinceLastUpdate = 0

local miks = false

-- -------------------------
-- DISABLE/MOVE BLIZZ STUFF
-- -------------------------

if IsAddOnLoaded("MikScrollingBattleText") then
	UIErrorsFrame:Hide()
	miks = true
end

-- -------------------------
-- ONLOAD FUNCTION
-- -------------------------

function OobieUtil_OnLoad()

	OobieUtil:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
	OobieUtil:RegisterEvent("CHAT_MSG_LOOT")
	OobieUtil:RegisterEvent("CHAT_MSG_WHISPER")
	OobieUtil:RegisterEvent("DUEL_REQUESTED")
	OobieUtil:RegisterEvent("MERCHANT_SHOW")
	OobieUtil:RegisterEvent("PLAYER_XP_UPDATE")
	OobieUtil:RegisterEvent("TRAINER_SHOW")
	OobieUtil:RegisterEvent("UI_ERROR_MESSAGE")
	OobieUtil:RegisterEvent("UI_INFO_MESSAGE")
	OobieUtil:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	OobieUtil:SetScript("OnEvent", OobieUtil.OnEvent)

end

-- -------------------------
-- ONUPDATE FUNCTION
-- -------------------------

function OobieUtil_OnUpdate(elapsed)
	
	if OobieUtil_FactionWatchActive then
		OobieUtil.TimeSinceLastUpdate = OobieUtil.TimeSinceLastUpdate + elapsed
		if (OobieUtil.TimeSinceLastUpdate > OobieUtil_FactionWatchTimeout) then
			SetWatchedFactionIndex(0)
			OobieUtil.TimeSinceLastUpdate = 0
			OobieUtil_FactionWatchActive = nil
		end
	end

end

-- -------------------------
-- ONEVENT FUNCTION
-- -------------------------
	
function OobieUtil:OnEvent(event, ...)

	local arg1, arg2 = ...
	
	if (event=="CHAT_MSG_COMBAT_FACTION_CHANGE") then
	
		local factionToWatch = nil
		
		if string.find(arg1, "Guild") then
			factionLookUp = GetGuildInfo("player")
		else
			factionLookUp = arg1
		end
		
		if UnitLevel("player") == 90 then
			--Set Faction watched when reputation increases
			p(GetNumFactions())
			for factionIndex=1,GetNumFactions() do
				local factionName = GetFactionInfo(factionIndex)
				if (string.find(factionLookUp,factionName)) then
					if not(IsFactionInactive(factionIndex)) then
						factionToWatch = factionIndex
					end
				end
			end
			
			if factionToWatch ~= nil then
				local _, _, _, _, _, factionValue = GetFactionInfo(factionToWatch)
			
				if factionValue < 42000 then
					OobieUtil_FactionWatchActive = 1
					OobieUtil.TimeSinceLastUpdate = 0
					SetWatchedFactionIndex(factionToWatch)
				end
			end
			
		end
		
	end

	if (event=="CHAT_MSG_LOOT") then
		
		if string.find(arg1, "You receive loot") and string.find(arg1, "cffa335ee") then
			PlaySoundFile("Interface\\AddOns\\OobieUtil\\Item.ogg")
		end
		
	end
	
	if (event=="CHAT_MSG_WHISPER") then
	
		local zoneName = GetRealZoneText()
		if (arg1=="doobie") then
			InviteUnit(arg2)
		end
		
	end
	
	if (event=="DUEL_REQUESTED") then
	
		CancelDuel()
		
	end
	
	if (event=="MERCHANT_SHOW") then
	
		if CanMerchantRepair() then
			local repairCost = GetRepairAllCost()
			
			if repairCost > 0 then
			
				local repairString = GetCoinText(repairCost," ")
				
				if CanGuildBankRepair() and OobieUtil_GuildBankAutoRepair then
					RepairAllItems(1)
					repairString = repairString.." (Guild Funds)"
				else
					RepairAllItems()
				end
				
				DEFAULT_CHAT_FRAME:AddMessage("Equipment repaired at a cost of "..repairString, 1, 1, 0)
				
			end
		end
		
	end
	
	if (event=="PLAYER_XP_UPDATE") then
	
		--Set xp watch
		SetWatchedFactionIndex(0)
		
	end
	
	if (event=="TRAINER_SHOW") then
	
		SetTrainerServiceTypeFilter("unavailable", 0)
		
	end

	if (event=="UI_INFO_MESSAGE") and miks then
		
		MikSBT.DisplayMessage(arg1,MikSBT.DISPLAYTYPE_NOTIFICATION,false,255,255,0)

	end

	if (event=="UI_ERROR_MESSAGE") and miks then
	
		if not(string.find(arg1,"not ready")) and not(string.find(arg1,"drink any more")) and not(string.find(arg1,"Another action is in progress")) then
			MikSBT.DisplayMessage(arg1,MikSBT.DISPLAYTYPE_NOTIFICATION,false,255,0,0)
		end

	end

	if (event=="UNIT_SPELLCAST_SUCCEEDED") then
	
		if (string.find(arg2, "Portal:")) or (string.find(arg2, "Gate")) and (arg1 == "player") then
			PlaySoundFile("Interface\\AddOns\\OobieUtil\\gate.ogg")
		end
		
	end

end


-- -------------------------
-- OOBIEUTIL FUNCTIONS
-- -------------------------

-- p FUNCTION
-- Print.  Handy for debugging.
function p(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg, 1, .4, .4)
end


-- ------------------------
-- CONFIG
-- ------------------------

-- Faction watch timeout
-- Time in seconds until faction watch is turned off after a faction update
-- 60 = 1 minute, 900 = 15 min, etc.
local OobieUtil_FactionWatchTimeout = 0

-- Auto repair
-- 1 for on, nil for off
local OobieUtil_AutoRepair = 1

-- Auto repair from guild bank, if available
-- 1 for on, nil for off
local OobieUtil_GuildBankAutoRepair = nil

-- Auto sell grey items at a vendor
-- 1 for on, nil for off
local OobieUtil_SellGreyItems = 1

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

-- if IsAddOnLoaded("MikScrollingBattleText") then
-- 	UIErrorsFrame:Hide()
-- 	miks = true
-- end

-- ------------------------
-- EVENT ACTIONS
-- ------------------------

local OobieUtil_actions = {

	["CHAT_MSG_COMBAT_FACTION_CHANGE"] = function(arg1, arg2)
		local factionToWatch = nil

		if string.find(arg1, "Guild") then
			factionLookUp = GetGuildInfo("player")
		else
			factionLookUp = arg1
		end

		if UnitLevel("player") == 110 then
			--Set Faction watched when reputation increases
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
	end,

	["CHAT_MSG_LOOT"] = function(arg1, arg2)
		if string.find(arg1, "You receive loot") and string.find(arg1, "cffa335ee") then
			PlaySoundFile("Interface\\AddOns\\OobieUtil\\Item.ogg")
		end
	end,

	["CHAT_MSG_WHISPER"] = function(arg1, arg2)
		local zoneName = GetRealZoneText()
		if (arg1=="doobie") then
			InviteUnit(arg2)
		end
	end,

	["DUEL_REQUESTED"] = function(arg1, arg2)
		CancelDuel()
	end,

	["MERCHANT_SHOW"] = function(arg1, arg2)
		-- sell all grey items
		if OobieUtil_SellGreyItems then
			for bag = 0,4,1 do
				for slot = 1, GetContainerNumSlots(bag), 1 do
					local name = GetContainerItemLink(bag,slot)
					if name and string.find(name,"ff9d9d9d") then
						UseContainerItem(bag,slot)
					end
				end
			end

			-- todo, total up the cost and dd that to the output
			OobieUtil_Notify("Sold Grey Items")
		end

		-- auto repair
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

				OobieUtil_Notify("Equipment repaired at a cost of |cFFffffff"..repairString.."|r")

			end
		end
	end,

	["PLAYER_XP_UPDATE"] = function(arg1, arg2)
		SetWatchedFactionIndex(0)
	end,

	-- ["TRAINER_SHOW"] = function(arg1, arg2)
	-- 	SetTrainerServiceTypeFilter("unavailable", 0)
	-- end,

	-- ["UI_ERROR_MESSAGE"] = function(arg1, arg2)
	-- 	MikSBT.DisplayMessage(arg1,MikSBT.DISPLAYTYPE_NOTIFICATION,false,255,255,0)
	-- end,
	--
	-- ["UI_INFO_MESSAGE"] = function(arg1, arg2)
	-- 	if not(string.find(arg1,"not ready")) and not(string.find(arg1,"drink any more")) and not(string.find(arg1,"Another action is in progress")) then
	-- 		MikSBT.DisplayMessage(arg1,MikSBT.DISPLAYTYPE_NOTIFICATION,false,255,0,0)
	-- 	end
	-- end,

	["UNIT_SPELLCAST_SUCCEEDED"] = function(arg1, arg2)
		if (string.find(arg2, "Portal:")) or (string.find(arg2, "Gate")) and (arg1 == "player") then
			PlaySoundFile("Interface\\AddOns\\OobieUtil\\gate.ogg")
		end
	end
}

-- -------------------------
-- ONLOAD FUNCTION
-- -------------------------

function OobieUtil_OnLoad()

	for event, action in pairs(OobieUtil_actions) do
		OobieUtil:RegisterEvent(event)
	end

	OobieUtil:SetScript("OnEvent", OobieUtil.OnEvent)

end

-- -------------------------
-- ONUPDATE FUNCTION
-- -------------------------

function OobieUtil_OnUpdate(elapsed)

	if OobieUtil_FactionWatchActive and OobieUtil_FactionWatchTimeout > 0 then
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

function OobieUtil:OnEvent(event, arg1, arg2)

	OobieUtil_actions[event](arg1,arg2)

end


-- -------------------------
-- OOBIEUTIL FUNCTIONS
-- -------------------------

-- OobieUtil_Notify
-- Use for outputting notifications to the chat window
function OobieUtil_Notify(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFFf1bb17OobieUtil|r "..msg, .1, .9, .8)
end

-- p FUNCTION
-- Print.  Handy for debugging.
function p(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFFf1bb17OobieUtil[Debug]|r "..msg, 1, .4, .4)
end



-- All Done!
OobieUtil_Notify("Loaded")

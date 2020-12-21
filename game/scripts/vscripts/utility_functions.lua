--[[ utility_functions.lua ]]

local radiantPointsAchieved = 0
local direPointsAchieved = 0
local announcerLockedReady = true
local announcerContestedReady = true
local announcerRadiantLeading = false
local announcerDireLeading = false

---------------------------------------------------------------------------
-- Create 20 second wave timer for respawning
---------------------------------------------------------------------------
function CConquestGameMode:RespawnWaveTimer()
	respawnWaveTime = respawnWaveTime + 0.25
	if respawnWaveTime > 10 then
		respawnWaveTime = 0
	end
end

---------------------------------------------------------------------------
-- Update minimap icons for capture points
---------------------------------------------------------------------------
function UpdateCPDisplay( i, ent )
	if ent == nil then return end

	local owner = m_cp_info[i].owner

	-- default is DOTA_TEAM_NOTEAM
	local r = 255
	local g = 255
	local b = 255

    if owner == DOTA_TEAM_GOODGUYS then
		r = 0
		g = 255
		b = 0
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 0, 255, 0, 400, 100, DOTA_TEAM_GOODGUYS )
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 255, 0, 0, 400, 100, DOTA_TEAM_BADGUYS )
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 0, 255, 0, 400, 100, 1 )
    elseif owner == DOTA_TEAM_BADGUYS then
		r = 255
		g = 0
		b = 0
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 0, 255, 0, 400, 100, DOTA_TEAM_BADGUYS )
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 255, 0, 0, 400, 100, DOTA_TEAM_GOODGUYS )
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 255, 0, 0, 400, 100, 1 )
	else
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 255, 255, 255, 400, 100, DOTA_TEAM_BADGUYS )
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 255, 255, 255, 400, 100, DOTA_TEAM_GOODGUYS )
		GameRules:AddMinimapDebugPointForTeam( -ent:entindex(), ent:GetAbsOrigin(), 255, 255, 255, 400, 100, 1 )
    end

	--GameRules:AddMinimapDebugPoint( -ent:entindex(), ent:GetAbsOrigin(), r, g, b, 400, 100 )
end

function CConquestGameMode:UpdateWaypointDisplay()
	local entranceRadiant = Entities:FindByName( nil, "teleport_particle_radiant" )
	local exitRadiant = Entities:FindByName( nil, "teleport_particle_exit_radiant" )
	if entranceRadiant ~= nil and exitRadiant ~= nil then
		GameRules:AddMinimapDebugPointForTeam( -entranceRadiant:entindex(), entranceRadiant:GetAbsOrigin(), 255, 255, 255, 300, 100, DOTA_TEAM_GOODGUYS )
		GameRules:AddMinimapDebugPointForTeam( -exitRadiant:entindex(), exitRadiant:GetAbsOrigin(), 255, 255, 255, 200, 300, DOTA_TEAM_GOODGUYS )
	end
	local entranceDire = Entities:FindByName( nil, "teleport_particle_dire" )
	local exitDire = Entities:FindByName( nil, "teleport_particle_exit_dire" )
	if entranceDire ~= nil and exitDire ~= nil then
		GameRules:AddMinimapDebugPointForTeam( -entranceDire:entindex(), entranceDire:GetAbsOrigin(), 255, 255, 255, 300, 100, DOTA_TEAM_BADGUYS )
		GameRules:AddMinimapDebugPointForTeam( -exitDire:entindex(), exitDire:GetAbsOrigin(), 255, 255, 255, 300, 100, DOTA_TEAM_BADGUYS )
	end
end

---------------------------------------------------------------------------
-- Update scoreboard for team points
---------------------------------------------------------------------------
function CConquestGameMode:UpdateScoreboard()
	--print( "CConquestGameMode:UpdateScoreboard()" )
	local gamemode = GameRules:GetGameModeEntity()
	for i = numControlPoints, 1, -1 do
		self:ThinkUpdateCP( i )
		UpdateCPDisplay( i, Entities:FindByName( nil, "cp"..i ) )
	end
	if all_points_owned == true then
		--print("All points owned")
		if points_fortified == false then
			-- Point system for win condition
			-- First pass numbers (0.1, 0.25, 0.5, 1, 4, 8)
			if m_points_owned[DOTA_TEAM_GOODGUYS] == 0 then
				radiantTotal = radiantTotal + 0
			elseif m_points_owned[DOTA_TEAM_GOODGUYS] == 1 then
				radiantTotal = radiantTotal + 0
			elseif m_points_owned[DOTA_TEAM_GOODGUYS] == 2 then
				radiantTotal = radiantTotal + 0
			elseif m_points_owned[DOTA_TEAM_GOODGUYS] == 3 then
				radiantTotal = radiantTotal + 1
			elseif m_points_owned[DOTA_TEAM_GOODGUYS] == 4 then
				radiantTotal = radiantTotal + 3
			elseif m_points_owned[DOTA_TEAM_GOODGUYS] == 5 then
				radiantTotal = radiantTotal + 6
			end
			if m_points_owned[DOTA_TEAM_BADGUYS] == 0 then
				direTotal = direTotal + 0
			elseif m_points_owned[DOTA_TEAM_BADGUYS] == 1 then
				direTotal = direTotal + 0
			elseif m_points_owned[DOTA_TEAM_BADGUYS] == 2 then
				direTotal = direTotal + 0
			elseif m_points_owned[DOTA_TEAM_BADGUYS] == 3 then
				direTotal = direTotal + 1
			elseif m_points_owned[DOTA_TEAM_BADGUYS] == 4 then
				direTotal = direTotal + 3
			elseif m_points_owned[DOTA_TEAM_BADGUYS] == 5 then
				direTotal = direTotal + 6
			end
		end
	end
	-- Determine when a team has taken the lead
	if radiantTotal > direTotal then
		announcerRadiantLeading = true
		if announcerDireLeading == true then
			--print("Radiant has just taken the lead")
			CConquestGameMode:AnnouncerTakenTheLead( DOTA_TEAM_GOODGUYS )
		end
		announcerDireLeading = false
	elseif direTotal > radiantTotal then
		announcerDireLeading = true
		if announcerRadiantLeading == true then
			--print("Dire has just taken the lead")
			CConquestGameMode:AnnouncerTakenTheLead( DOTA_TEAM_BADGUYS )
		end
		announcerRadiantLeading = false
	end

	if radiantTotal >= pointGoal then
		radiantTotal = pointGoal
	end
	
	if direTotal >= pointGoal then
		direTotal = pointGoal
	end
	
	local score_table =
	{
		radiant = radiantTotal,
		dire = direTotal,
	}
	CustomNetTables:SetTableValue( "game_state", "score_table", score_table )

	local broadcast_team_points = 
	{
		radiant = math.floor(radiantTotal),
		dire = math.floor(direTotal),
	}
	CustomGameEventManager:Send_ServerToAllClients( "team_points", broadcast_team_points )
	CConquestGameMode:TeamPointAchievements()
	-- Win Condition
	if radiantTotal >= pointGoal then
		CConquestGameMode:EndGame(DOTA_TEAM_GOODGUYS)
	elseif direTotal >= pointGoal then
		CConquestGameMode:EndGame(DOTA_TEAM_BADGUYS)
	end
end

function CConquestGameMode:TeamPointAchievements()
	local team = nil
	local pointsAchieved = 0
	if radiantTotal >= 1000 and radiantPointsAchieved == 0 then
		team = 2
		radiantPointsAchieved = radiantPointsAchieved + 1
		pointsAchieved = radiantPointsAchieved
	elseif direTotal >= 1000 and direPointsAchieved == 0 then
		team = 3
		direPointsAchieved = direPointsAchieved + 1
		pointsAchieved = direPointsAchieved
	elseif radiantTotal >= 2000 and radiantPointsAchieved == 1 then
		team = 2
		radiantPointsAchieved = radiantPointsAchieved + 1
		pointsAchieved = radiantPointsAchieved
	elseif direTotal >= 2000 and direPointsAchieved == 1 then
		team = 3
		direPointsAchieved = direPointsAchieved + 1
		pointsAchieved = direPointsAchieved
	elseif radiantTotal >= 3000 and radiantPointsAchieved == 2 then
		team = 2
		radiantPointsAchieved = radiantPointsAchieved + 1
		pointsAchieved = radiantPointsAchieved
	elseif direTotal >= 3000 and direPointsAchieved == 2 then
		team = 3
		direPointsAchieved = direPointsAchieved + 1
		pointsAchieved = direPointsAchieved
	elseif radiantTotal >= 4000 and radiantPointsAchieved == 3 then
		team = 2
		radiantPointsAchieved = radiantPointsAchieved + 1
		pointsAchieved = radiantPointsAchieved
	elseif direTotal >= 4000 and direPointsAchieved == 3 then
		team = 3
		direPointsAchieved = direPointsAchieved + 1
		pointsAchieved = direPointsAchieved
	elseif radiantTotal >= 4900 and radiantPointsAchieved == 4 then
		team = 2
		radiantPointsAchieved = radiantPointsAchieved + 1
		pointsAchieved = radiantPointsAchieved
		points = radiantTotal
		--CConquestGameMode:BroadcastCountdown( team_number, points )
	elseif direTotal >= 4900 and direPointsAchieved == 4 then
		team = 3
		direPointsAchieved = direPointsAchieved + 1
		pointsAchieved = direPointsAchieved
		points = direTotal
		--CConquestGameMode:BroadcastCountdown( team_number, points )
	end
	if team ~= nil then
		CConquestGameMode:BroadcastPointNotifications( team, pointsAchieved )
	end
end

function CConquestGameMode:BroadcastPointNotifications( team, pointsAchieved )
	print("Team Points Achieved")
	if pointsAchieved < 5 then
		CConquestGameMode:OnTeamMilestoneReached( team, pointsAchieved )
	end
	local point_notification = 
	{
		achieving_team = team,
		achieving_points = pointsAchieved
	}
	CustomGameEventManager:Send_ServerToAllClients( "point_notification", point_notification )
end

function CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	local broadcast_team = 
	{
		team = team_number,
		capture_points = number_of_points
	}
	CustomGameEventManager:Send_ServerToAllClients( "broadcast_team", broadcast_team )
end

function CConquestGameMode:BroadcastCountdown( team_number, points )
	local countdown_notification = 
	{
		team = team_number,
		score = points
	}
	CustomGameEventManager:Send_ServerToAllClients( "countdown_notification", countdown_notification )
end

---------------------------------------------------------------------------
-- Waypoint Setup
---------------------------------------------------------------------------
function CConquestGameMode:EnableWaypoint( team )
	if team == DOTA_TEAM_GOODGUYS then
		DoEntFire( "teleport_particle_radiant", "Start", "0", 0, self, self )
		--DoEntFire( "teleport_particle_dire", "Stop", "0", 0, self, self )
		DoEntFire( "teleport_particle_exit_radiant", "Start", "0", 0, self, self )
		--DoEntFire( "teleport_particle_exit_dire", "Stop", "0", 0, self, self )
		local waypoint = Entities:FindByName( nil, "teleport_particle_radiant" )
		if waypoint == nil then return end
		local waypoint_exit = Entities:FindByName( nil, "teleport_particle_exit_radiant" )
		local waypoint_location = waypoint:GetAbsOrigin()
		local waypoint_exit_location = waypoint_exit:GetAbsOrigin()

		local tooltipEntrance = CreateItem( "item_waypoint_entrance_radiant", nil, nil )
		CreateItemOnPositionSync( waypoint_location, tooltipEntrance )

		local broadcast_waypoint = 
		{
			team = 2,
			location = waypoint_location,
			exit = waypoint_exit_location
		}
		CustomGameEventManager:Send_ServerToAllClients( "waypoint_notification", broadcast_waypoint )
	else
		--DoEntFire( "teleport_particle_radiant", "Stop", "0", 0, self, self )
		DoEntFire( "teleport_particle_dire", "Start", "0", 0, self, self )
		--DoEntFire( "teleport_particle_exit_radiant", "Stop", "0", 0, self, self )
		DoEntFire( "teleport_particle_exit_dire", "Start", "0", 0, self, self )
		local waypoint = Entities:FindByName( nil, "teleport_particle_dire" )
		if waypoint == nil then return end
		local waypoint_exit = Entities:FindByName( nil, "teleport_particle_exit_dire" )
		local waypoint_location = waypoint:GetAbsOrigin()
		local waypoint_exit_location = waypoint_exit:GetAbsOrigin()

		local tooltipEntrance = CreateItem( "item_waypoint_entrance_dire", nil, nil )
		CreateItemOnPositionSync( waypoint_location, tooltipEntrance )

		local broadcast_waypoint = 
		{
			team = 3,
			location = waypoint_location,
			exit = waypoint_exit_location
		}
		CustomGameEventManager:Send_ServerToAllClients( "waypoint_notification", broadcast_waypoint )
	end
	CConquestGameMode:UpdateWaypointDisplay()
	CConquestGameMode:EnableTooltipItems()
end

function CConquestGameMode:EnableTooltipItems()
	-- Creating items that contain the tooltip information for new mechanics
	-- Pendulum
	local radiantPendulumButton = Entities:FindByName( nil, "trigger_pendulum_radiant_button" )
	if radiantPendulumButton ~= nil then
		local radiantPendulumLocation = radiantPendulumButton:GetAbsOrigin()
		local radiantTooltipPendulum = CreateItem( "item_button_pendulum_radiant", nil, nil )
		CreateItemOnPositionSync( radiantPendulumLocation, radiantTooltipPendulum )
	end

	local direPendulumButton = Entities:FindByName( nil, "trigger_pendulum_dire_button" )
	if direPendulumButton ~= nil then
		local direPendulumLocation = direPendulumButton:GetAbsOrigin()
		local direTooltipPendulum = CreateItem( "item_button_pendulum_dire", nil, nil )
		CreateItemOnPositionSync( direPendulumLocation, direTooltipPendulum )
	end

	-- Fire Trap
	local radiantFiretrapButton = Entities:FindByName( nil, "npc_dota_fire_trap_cp1_button" )
	if radiantFiretrapButton ~= nil then
		local radiantFiretrapLocation = radiantFiretrapButton:GetAbsOrigin()
		local radiantTooltipFiretrap = CreateItem( "item_button_firetrap_radiant", nil, nil )
		CreateItemOnPositionSync( radiantFiretrapLocation, radiantTooltipFiretrap )
	end
	local direFiretrapButton = Entities:FindByName( nil, "npc_dota_fire_trap_cp5_button" )
	if direFiretrapButton ~= nil then
		local direFiretrapLocation = direFiretrapButton:GetAbsOrigin()
		local direTooltipFiretrap = CreateItem( "item_button_firetrap_dire", nil, nil )
		CreateItemOnPositionSync( direFiretrapLocation, direTooltipFiretrap )
	end

	local radiantFiretrapButton = Entities:FindByName( nil, "npc_dota_fire_trap_cp2_button" )
	if radiantFiretrapButton ~= nil then
		local radiantFiretrapLocation = radiantFiretrapButton:GetAbsOrigin()
		local radiantTooltipFiretrap = CreateItem( "item_button_firetrap_radiant", nil, nil )
		CreateItemOnPositionSync( radiantFiretrapLocation, radiantTooltipFiretrap )
	end
	local direFiretrapButton = Entities:FindByName( nil, "npc_dota_fire_trap_cp4_button" )
	if direFiretrapButton ~= nil then
		local direFiretrapLocation = direFiretrapButton:GetAbsOrigin()
		local direTooltipFiretrap = CreateItem( "item_button_firetrap_dire", nil, nil )
		CreateItemOnPositionSync( direFiretrapLocation, direTooltipFiretrap )
	end

	local radiantFiretrapButton = Entities:FindByName( nil, "npc_dota_fire_trap_cp3_radiant_button" )
	if radiantFiretrapButton ~= nil then
		local radiantFiretrapLocation = radiantFiretrapButton:GetAbsOrigin()
		local radiantTooltipFiretrap = CreateItem( "item_button_firetrap_radiant", nil, nil )
		CreateItemOnPositionSync( radiantFiretrapLocation, radiantTooltipFiretrap )
	end
	local direFiretrapButton = Entities:FindByName( nil, "npc_dota_fire_trap_cp3_dire_button" )
	if direFiretrapButton ~= nil then
		local direFiretrapLocation = direFiretrapButton:GetAbsOrigin()
		local direTooltipFiretrap = CreateItem( "item_button_firetrap_dire", nil, nil )
		CreateItemOnPositionSync( direFiretrapLocation, direTooltipFiretrap )
	end

	-- Venom Trap
	local radiantVenomtrapButton = Entities:FindByName( nil, "npc_dota_venom_trap_radiant_button" )
	if radiantVenomtrapButton ~= nil then
		local radiantVenomtrapLocation = radiantVenomtrapButton:GetAbsOrigin()
		local radiantTooltipVenomtrap = CreateItem( "item_button_venomtrap_radiant", nil, nil )
		CreateItemOnPositionSync( radiantVenomtrapLocation, radiantTooltipVenomtrap )
	end
	local direVenomtrapButton = Entities:FindByName( nil, "npc_dota_venom_trap_dire_button" )
	if direVenomtrapButton ~= nil then
		local direVenomtrapLocation = direVenomtrapButton:GetAbsOrigin()
		local direTooltipVenomtrap = CreateItem( "item_button_venomtrap_dire", nil, nil )
		CreateItemOnPositionSync( direVenomtrapLocation, direTooltipVenomtrap )
	end

	-- Boulder Trap
	local radiantBoulderButton = Entities:FindByName( nil, "radiant_boulder_trap_button" )
	if radiantBoulderButton ~= nil then
		local radiantBouldertrapLocation = radiantBoulderButton:GetAbsOrigin()
		local radiantTooltipBouldertrap = CreateItem( "item_button_boulder_radiant", nil, nil )
		CreateItemOnPositionSync( radiantBouldertrapLocation, radiantTooltipBouldertrap )
	end
	local direBoulderButton = Entities:FindByName( nil, "dire_boulder_trap_button" )
	if direBoulderButton ~= nil then
		local direBouldertrapLocation = direBoulderButton:GetAbsOrigin()
		local direTooltipBouldertrap = CreateItem( "item_button_boulder_dire", nil, nil )
		CreateItemOnPositionSync( direBouldertrapLocation, direTooltipBouldertrap )
	end
end

---------------------------------------------------------------------------
-- Grant gold and xp for team that captures a point
---------------------------------------------------------------------------
function CConquestGameMode:GrantGoldAndXP(team)
	--print("Granting Gold and XP")
	--print(team)
	local members = HeroList:GetAllHeroes()
	local playersHit = {}
	for _,hero in ipairs(members) do
		--print(hero:GetTeamNumber())
		if hero:GetTeamNumber() == team then
			--print("This hero is a member of the team")
			local memberID = hero:GetPlayerID()
			if playersHit[memberID] == nil then
				playersHit[memberID] = true
				hero:AddExperience( 200, 0, false, false )
				PlayerResource:ModifyGold( memberID, 200, true, 0 )
			end
		end
	end
end

---------------------------------------------------------------------------
-- Custom Game Announcer Lines
---------------------------------------------------------------------------
function CConquestGameMode:AnnouncerConquest()
	--print("Announcer Conquest")
	--EmitAnnouncerSound("announcer_ann_custom_mode_02")
	EmitAnnouncerSound("announcer_announcer_battle_begin_01")
end

function CConquestGameMode:AnnouncerBegin()
	--print("Announcer Begin")
	--EmitAnnouncerSound("announcer_ann_custom_begin")
end

function CConquestGameMode:AnnouncerEndGame( team )
	--print("Ending Announcer")
	local allHeroes = HeroList:GetAllHeroes()
	local caster = nil
	local randomLine = RandomInt(1,2)
	for _,t in pairs ( { DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS } ) do
		if t == team then
			if randomLine == 1 then
				EmitAnnouncerSoundForTeam( "announcer_ann_custom_end_01", t )
			else
				EmitAnnouncerSoundForTeam( "announcer_ann_custom_end_02", t )
			end
		else
			if randomLine == 1 then
				EmitAnnouncerSoundForTeam( "announcer_ann_custom_end_03", t )
			else
				EmitAnnouncerSoundForTeam( "announcer_ann_custom_end_04", t )
			end
		end
	end
	if team == DOTA_TEAM_GOODGUYS then
		EmitAnnouncerSoundForTeam( "announcer_announcer_victory_rad", 1 )
	else
		EmitAnnouncerSoundForTeam( "announcer_announcer_victory_dire", 1 )
	end
end

function CConquestGameMode:AnnouncerPointIsLocked( index, cappingTeam )
	if announcerLockedReady == false then
		return
	end
	print("Point is locked")
	announcerLockedReady = false
	local gamemode = GameRules:GetGameModeEntity()
	local allHeroes = HeroList:GetAllHeroes()
	local caster = nil
	local cp = Entities:FindByName( nil, "cp_particle_fortification_0" .. index )
	local location = cp:GetAbsOrigin()
	EmitAnnouncerSoundForTeamOnLocation( "announcer_ann_custom_team_alerts_06", cappingTeam, location )
	gamemode:SetContextThink( "AnnouncerResetLocked", function() return CConquestGameMode:AnnouncerPointIsLockedReset() end, 10 )
end

function CConquestGameMode:AnnouncerPointIsLockedReset()
	announcerLockedReady = true
end

function CConquestGameMode:AnnouncerPointBeingContested( index, cappingTeam )
	if announcerContestedReady == false then
		return
	end
	--print("Point is being captured")
	announcerContestedReady = false
	local gamemode = GameRules:GetGameModeEntity()
	local allHeroes = HeroList:GetAllHeroes()
	local caster = nil
	local msgTeam = DOTA_TEAM_GOODGUYS
	if cappingTeam == DOTA_TEAM_GOODGUYS then
		msgTeam = DOTA_TEAM_BADGUYS
	end
	if randomLine == 1 then
		EmitAnnouncerSoundForTeam( "announcer_ann_custom_team_alerts_09", msgTeam )
	else
		EmitAnnouncerSoundForTeam( "announcer_ann_custom_team_alerts_10", msgTeam )
	end
	gamemode:SetContextThink( "AnnouncerResetContested", function() return CConquestGameMode:AnnouncerPointBeingContestedReset() end, 10 )
end

function CConquestGameMode:AnnouncerPointBeingContestedReset()
	announcerContestedReady = true
end

function CConquestGameMode:AnnouncerTakenTheLead( team )
	--print("New team in the lead")
	local gamemode = GameRules:GetGameModeEntity()
	local allHeroes = HeroList:GetAllHeroes()
	local caster = nil
	local randomLine = RandomInt(1,2)
	for _,t in pairs( { DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS } ) do
		if t == team then
			if randomLine == 1 then
				EmitAnnouncerSoundForTeam( "announcer_ann_custom_team_alerts_01", t )
			else
				EmitAnnouncerSoundForTeam( "announcer_ann_custom_team_alerts_02", t )
			end
		else
			if randomLine == 1 then
				EmitAnnouncerSoundForTeam( "announcer_ann_custom_team_alerts_03", t )
			else
				EmitAnnouncerSoundForTeam( "announcer_ann_custom_team_alerts_04", t )
			end
		end
	end
end

function CConquestGameMode:AnnouncerFortified()
	--print("Announcer Fortified")
	local randomLine = RandomInt(1,2)
	if randomLine == 1 then
		EmitAnnouncerSound("announcer_ann_custom_structures_01")
	else
		EmitAnnouncerSound("announcer_ann_custom_structures_02")
	end
end

--[[ events.lua ]]

---------------------------------------------------------------------------
-- Event: Game state change handler
---------------------------------------------------------------------------
function CConquestGameMode:OnGameRulesStateChange()
	--print( "CConquestGameMode:OnGameRulesStateChange" )
	local nNewState = GameRules:State_Get()
	if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		local gamemode = GameRules:GetGameModeEntity()
		gamemode:SetContextThink( "AnnouncerConquest", function() return CConquestGameMode:AnnouncerConquest() end, 7.5 )
		gamemode:SetContextThink( "AnnouncerBegin", function() return CConquestGameMode:AnnouncerBegin() end, 9.25 )
		-- Setting up particles
		--print("setting up particles for default owners")
		CConquestGameMode:ParticleUpdate( 1, DOTA_TEAM_GOODGUYS )
		CConquestGameMode:ParticleUpdate( 2, DOTA_TEAM_GOODGUYS )
		CConquestGameMode:ParticleUpdate( 4, DOTA_TEAM_BADGUYS )
		CConquestGameMode:ParticleUpdate( 5, DOTA_TEAM_BADGUYS )
	end
	if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		_G.game_in_progress = true
		CConquestGameMode:EnableWaypoint( DOTA_TEAM_GOODGUYS )
		CConquestGameMode:EnableWaypoint( DOTA_TEAM_BADGUYS )
		if GetMapName() == "haunted_colosseum" then
			EmitGlobalSound("Conquest.Stinger.GameBegin")
		else
			EmitGlobalSound("Conquest.Stinger.GameBegin.Generic")
		end
		GameRules:SetTimeOfDay( 0.50 )
	end
end

---------------------------------------------------------------------------
-- Event: NPC Spawned
---------------------------------------------------------------------------
function CConquestGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	--print( "CConquestGameMode:OnNPCSpawned" )
	-- Setting a custom buyback cooldown
	if spawnedUnit:IsRealHero() then
		--Hero has spawned
	end
end

---------------------------------------------------------------------------
-- Event: Entity killed
---------------------------------------------------------------------------
function CConquestGameMode:OnEntityKilled( event )
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	if killedUnit == nil then return end
	--print(killedUnit:GetClassname())
	-- Check to see if it's a hero
	if killedUnit:IsRealHero() then
		local attacker = EntIndexToHScript( event.entindex_attacker )
		-- Add 20 seconds for Necro ultimate
		local extraTime = 0
		if event.entindex_inflictor ~= nil then
			local inflictor_index = event.entindex_inflictor
			if inflictor_index ~= nil then
				local ability = EntIndexToHScript( event.entindex_inflictor )
				if ability ~= nil then
					if ability:GetAbilityName() ~= nil then
						if ability:GetAbilityName() == "necrolyte_reapers_scythe" then
							print("Killed by Necro Ult")
							extraTime = 20
						end
					end
				end
			end
		end
		CConquestGameMode:CheckForLootItemDrop( killedUnit )
		-- Add more time if the team is leading
		local team = killedUnit:GetTeam()
		local teamTime = 5

		-- Change respawn time based on points
		local difference = 0
		if team == 2 and radiantTotal > direTotal then
			difference = radiantTotal - direTotal
		elseif team == 3 and direTotal > radiantTotal then
			difference = direTotal - radiantTotal
		end
		if difference > 500 and difference <= 2000 then
			teamTime = 15
		elseif difference > 2000 and difference <= 4000 then
			teamTime = 25
		elseif difference > 4000 then
			teamTime = 35
		end

		-- Change the respawn time based on the hero's level
		local baseTime = 0
		local level = killedUnit:GetLevel()
		if level > 9 and level < 20 then
			baseTime = 10
		elseif level >= 20 then
			baseTime = 20
		end

		local respawnTime = killedUnit:GetRespawnTime()
		-- Change the respawn time depending on if the team is leading or trailing
		if killedUnit:IsReincarnating() == true then
			print("Set Time for Wraith King respawn disabled")
			return nil
		else
			if respawnWaveTime < 5 then
				killedUnit:SetTimeUntilRespawn( math.floor(10 - respawnWaveTime) + teamTime + extraTime + baseTime )
			else
				killedUnit:SetTimeUntilRespawn( math.floor(10 + (10 - respawnWaveTime)) + teamTime + extraTime + baseTime )
			end
		end
	elseif killedUnit:GetClassname() == "npc_dota_creep_neutral" then
		--print("Golem has been killed")
		CConquestGameMode:CheckForLootItemDrop( killedUnit )
	end
end

---------------------------------------------------------------------------
-- Event: Item picked up
---------------------------------------------------------------------------
function CConquestGameMode:OnItemPickUp( event )
	local item = EntIndexToHScript( event.ItemEntityIndex )
	local owner = EntIndexToHScript( event.HeroEntityIndex )
	local playerID = owner:GetPlayerID()
	item:SetPurchaser( owner )
	--print("Item has been picked up")
	r = 100
	if event.itemname == "item_bag_of_gold" then
		StartSoundEvent( "General.Coins", owner )
		PlayerResource:ModifyGold( owner:GetPlayerID(), r, true, 0 )
		SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, r, nil )
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	elseif event.itemname == "item_fountain_potion" then
		local health = owner:GetHealth()
		local maxHealth = owner:GetMaxHealth()
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	elseif event.itemname == "item_mango_juice" then
		local m = owner:GetMaxMana()
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	elseif event.itemname == "item_health_treat" then
		local health = owner:GetHealth()
		local maxHealth = owner:GetMaxHealth()
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	elseif event.itemname == "item_mana_treat" then
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	elseif event.itemname == "item_halloween_candy" then
		StartSoundEvent( "General.Coins", owner )
		PlayerResource:ModifyGold( owner:GetPlayerID(), 300, true, 0 )
		SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, r, nil )
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	end
end

---------------------------------------------------------------------------
-- Event: Waypoint entered
---------------------------------------------------------------------------
function CConquestGameMode:OnWaypointStartTouch( hero, team, heroIndex )
	local teleportUnit = EntIndexToHScript( heroIndex )
	if teleportUnit:IsRealHero() ~= true then
		return
	end
	if _G.game_in_progress == true then
		--print(hero .. " is using the waypoint" )
		local heroHandle = EntIndexToHScript(heroIndex)
		local player = heroHandle:GetPlayerID()
		
		heroHandle:Stop()
		--DoEntFire( "death_".. m_team_name[team] .."_teleport", "TeleportEntity", hero, 0, self, self )
		local exit = Entities:FindByName( nil, "death_radiant_teleport" )
		if team == DOTA_TEAM_BADGUYS then
			exit = Entities:FindByName( nil, "death_dire_teleport" )
		end
		local exitPosition = exit:GetAbsOrigin()
		-- Teleport the hero
		FindClearSpaceForUnit( heroHandle, exitPosition, true );

		local tpEffects = ParticleManager:CreateParticle( "particles/waypoint/waypoint_ground_flash_holo.vpcf", PATTACH_ABSORIGIN, heroHandle )
		ParticleManager:SetParticleControlEnt( tpEffects, PATTACH_ABSORIGIN, heroHandle, PATTACH_ABSORIGIN, "attach_origin", heroHandle:GetAbsOrigin(), true )
		heroHandle:Attribute_SetIntValue( "effectsID", tpEffects )

		DoEntFire( "teleport_particle_".. m_team_name[team], "Start", "", 0, self, self )
		PlayerResource:SetCameraTarget( player, heroHandle )
		StartSoundEvent( "Portal.Hero_Appear", heroHandle )
		heroHandle:SetContextThink( "KillSetCameraTarget", function() return PlayerResource:SetCameraTarget( player, nil ) end, 0.2 )
		heroHandle:SetContextThink( "KillTPEffects", function() return ParticleManager:DestroyParticle( tpEffects, true ) end, 3 )
	end
end

---------------------------------------------------------------------------
-- Event: Point Captured
---------------------------------------------------------------------------
function CConquestGameMode:OnPointCaptured( point )
	if point == 3 then
		if m_points_owned[DOTA_TEAM_GOODGUYS] > 2 then
			--CConquestGameMode:EnableWaypoint( DOTA_TEAM_GOODGUYS )
			local team_number = 2
			local number_of_points = m_points_owned[DOTA_TEAM_GOODGUYS]
			CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
		else
			--CConquestGameMode:EnableWaypoint( DOTA_TEAM_BADGUYS )
			local team_number = 3
			local number_of_points = m_points_owned[DOTA_TEAM_BADGUYS]
			CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
		end
	end
	if point == 4 and m_points_owned[DOTA_TEAM_GOODGUYS] == 3 then
		local team_number = 2
		local number_of_points = m_points_owned[DOTA_TEAM_GOODGUYS]
		CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	elseif point == 4 and m_points_owned[DOTA_TEAM_GOODGUYS] == 4 then
		local team_number = 2
		local number_of_points = m_points_owned[DOTA_TEAM_GOODGUYS]
		CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	elseif point == 5 and m_points_owned[DOTA_TEAM_GOODGUYS] == 5 then
		local team_number = 2
		local number_of_points = m_points_owned[DOTA_TEAM_GOODGUYS]
		CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	elseif point == 5 and m_points_owned[DOTA_TEAM_GOODGUYS] == 4 then
		local team_number = 2
		local number_of_points = m_points_owned[DOTA_TEAM_GOODGUYS]
		CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	elseif point == 2 and m_points_owned[DOTA_TEAM_BADGUYS] == 3 then
		local team_number = 3
		local number_of_points = m_points_owned[DOTA_TEAM_BADGUYS]
		CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	elseif point == 2 and m_points_owned[DOTA_TEAM_BADGUYS] == 4 then
		local team_number = 3
		local number_of_points = m_points_owned[DOTA_TEAM_BADGUYS]
		CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	elseif point == 1 and m_points_owned[DOTA_TEAM_BADGUYS] == 5 then
		local team_number = 3
		local number_of_points = m_points_owned[DOTA_TEAM_BADGUYS]
		CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	elseif point == 1 and m_points_owned[DOTA_TEAM_BADGUYS] == 4 then
		local team_number = 3
		local number_of_points = m_points_owned[DOTA_TEAM_BADGUYS]
		CConquestGameMode:BroadcastControlPointsOwned( team_number, number_of_points )
	end
end

---------------------------------------------------------------------------
-- Event: Milestone Achieved
---------------------------------------------------------------------------
function CConquestGameMode:OnTeamMilestoneReached( team, pointsAchieved )
	print("Granting reward for team milestone")
	local opposingTeam = 2
	if team == 2 then
		opposingTeam = 3
	end
	if GetMapName() == "haunted_colosseum" then
		EmitGlobalSound("Conquest.Stinger.HulkCreep")
	else
		EmitGlobalSound("Conquest.Stinger.HulkCreep.Generic")
	end
	CConquestGameMode:SpawnCreeps( opposingTeam, pointsAchieved )
end


function CConquestGameMode:OnPlayerConnect()
	self:ControlPointUpdateParticles()
end
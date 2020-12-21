--[[ capture_points.lua ]]

---------------------------------------------------------------------------
-- Capture Point States
---------------------------------------------------------------------------
function CConquestGameMode:UpdateCPNetworking( cp_number )
--	print( "UpdateCPNetworking: "..cp_number )

	local cp_name = "cp" .. cp_number
	
	local cpInfo = m_cp_info[ cp_number ]

	network_state = {}
	network_state.cp_name = cp_name
	network_state.cp_number = cp_number
	network_state.cp_owner = cpInfo.owner
	network_state.is_locked = self:IsPointLocked(cp_number)
	network_state.last_team_capturing_cp = cpInfo.last_team_capturing
	network_state.players_capturing = cpInfo.num_capturing
	network_state.pro_capturing = cpInfo.num_pro_capture
	network_state.anti_capturing = cpInfo.num_anti_capture
	network_state.is_fortified = self:IsPointFortified(cp_number)

	-- Get the percentage of the progress bar for UI
	network_state.percentage_captured = 0
	
	if cpInfo.last_team_capturing ~= DOTA_TEAM_NOTEAM then
		network_state.percentage_captured = math.max( 0, math.min( 100, math.floor( cpInfo.cp_timer[cpInfo.last_team_capturing] ) ) )
	end

--	for k,v in pairs(network_state) do
--		print( tostring(k) .. " = " .. tostring(v) )
--	end
	-- DeepPrint( network_state )

	CustomNetTables:SetTableValue( "control_points", cp_name, network_state )
end

function CConquestGameMode:UpdateGameStateNetworking( game_timer )
	network_state =
	{
		cp_game_timer = game_timer,
	}
	CustomNetTables:SetTableValue( "game_state", "game_state", network_state )
end

---------------------------------------------------------------------------
-- Capture Point Logic
---------------------------------------------------------------------------
function CConquestGameMode:AnyCPsBeingCaptured()
	for i = 1, #m_cp_info do
		if m_cp_info[i].capture_in_progress then
			return true
		end
	end
	return false
end

function CConquestGameMode:ControlPointTimer()
	local prev_second = math.floor( cp_game_timer )
	cp_game_timer = cp_game_timer - cp_update_period
	local new_second = math.floor( cp_game_timer )
	
	--print( "ControlPointTimer: " .. cp_game_timer )
	self:UpdateGameStateNetworking( cp_game_timer )

	--What happens if the timer runs out
	if prev_second ~= new_second then
		local t = new_second
		if t == 0 then
			--print( "Control Point Timer has expired" )
			if radiantTotal > direTotal then
				CConquestGameMode:EndGame(DOTA_TEAM_GOODGUYS)
			elseif direTotal > radiantTotal then
				CConquestGameMode:EndGame(DOTA_TEAM_BADGUYS)
			else
				EmitGlobalSound("Conquest.overtime")
				cp_game_timer = cp_game_timer + 31
			end
		end

		if t == 120 then
			print("2 minutes left")
			EmitGlobalSound("Conquest.announcer_2min")
		elseif t == 60 then
			EmitGlobalSound("Conquest.announcer_60sec")
		elseif t == 30 then
			EmitGlobalSound("Conquest.announcer_30sec")
		elseif t == 10 then
			EmitGlobalSound("Conquest.announcer_10sec")
		elseif t == 5 then
			EmitGlobalSound("Conquest.announcer_5sec")
		elseif t == 4 then
			EmitGlobalSound("Conquest.announcer_4sec")
		elseif t == 3 then
			EmitGlobalSound("Conquest.announcer_3sec")
		elseif t == 2 then
			EmitGlobalSound("Conquest.announcer_2sec")
		elseif t == 1 then
			EmitGlobalSound("Conquest.announcer_1sec")
		end
	end
end

---------------------------------------------------------------------------
-- Capture Point Triggers
---------------------------------------------------------------------------
function CConquestGameMode:DoCapturePoint(point, newTeam)
	--print( "Capture point " .. point .. " for team " .. newTeam )
	local oldTeam = m_cp_info[point].owner
	local gamemode = GameRules:GetGameModeEntity().CConquestGameMode
	m_cp_info[point].owner = newTeam

	local oldOwnerString = m_team_name[oldTeam]
	local newOwnerString = m_team_name[newTeam]
--	DeepPrint(m_team_name)
	--print( newOwnerString .." taking point " .. point .. " from " .. oldOwnerString )

	m_points_owned[newTeam] = m_points_owned[newTeam] + 1
	m_points_owned[oldTeam] = m_points_owned[oldTeam] - 1

	CConquestGameMode:GrantGoldAndXP(newTeam)
	CConquestGameMode:ParticleUpdate(point, newTeam)
	CConquestGameMode:OnPointCaptured(point)
end

function CConquestGameMode:OnCPStartTouch( index, team )
	m_cp_info[index].touch_counter[team] = m_cp_info[index].touch_counter[team] + 1
end

function CConquestGameMode:OnCPEndTouch( index, team )
	m_cp_info[index].touch_counter[team] = m_cp_info[index].touch_counter[team] - 1

	self:OnTriggerExitCounterCheck( index, team )
end

function CConquestGameMode:OnTriggerExitCounterCheck( index, team )
	if m_cp_info[index].touch_counter[team] == 0 then
--		self:CaptureStoppedForTeam( index, team )

		if m_cp_info[index].touch_counter[DOTA_TEAM_GOODGUYS] == 0 and m_cp_info[index].touch_counter[DOTA_TEAM_BADGUYS] == 0 then
--			self:CaptureStoppedForAllTeams( index )
			DoEntFire( "cp_particle_0"..index, "Stop", "0", 0, self, self )
		end
	end
end

---------------------------------------------------------------------------
-- Initial Capture Point Setup
---------------------------------------------------------------------------
function CConquestGameMode:ControlPointSetup()
	CConquestGameMode.cp_index = {}

	for i = 1, numControlPoints do
		CConquestGameMode.cp_index["cp"..i] = i
		
		m_points_owned[ m_cp_info[i].owner ] = m_points_owned[ m_cp_info[i].owner ] + 1
		
		local cpname = "cp"..i
		local ent = Entities:FindByName( nil, cpname )
		if ent ~= nil then
			GameRules:AddMinimapDebugPoint( -ent:entindex(), ent:GetAbsOrigin(), 255, 255, 255, 400, 100 )
			self:UpdateCPNetworking( i )
			DoEntFire( "cp3_particle_neutral", "Start", "0", 0, self, self )
		end
	end
end

function CConquestGameMode:ControlPointUpdateParticles()
	for i = 1, numControlPoints do
		local cp_particle_name = "cp"..i.."_particle_neutral"
		local cpParticleEnt = Entities:FindByName( nil, cp_particle_name )
		if cpParticleEnt ~= nil then
			-- Clear out existing particles...
			local existingParticle = cpParticleEnt:Attribute_GetIntValue( "particleID_owner", -1 )
			if existingParticle ~= -1 then
				ParticleManager:DestroyParticle( existingParticle, true )
				cpParticleEnt:Attribute_SetIntValue( "particleID_owner", -1 )
			end
			existingParticle = cpParticleEnt:Attribute_GetIntValue( "particleID_enemy", -1 )
			if existingParticle ~= -1 then
				ParticleManager:DestroyParticle( existingParticle, true )
				cpParticleEnt:Attribute_SetIntValue( "particleID_enemy", -1 )
			end
			existingParticle = cpParticleEnt:Attribute_GetIntValue( "particleID_spectator", -1 )
			if existingParticle ~= -1 then
				ParticleManager:DestroyParticle( existingParticle, true )
				cpParticleEnt:Attribute_SetIntValue( "particleID_spectator", -1 )
			end

			-- Attach ownership particles...
			local nCurrentTeam = cpParticleEnt:Attribute_GetIntValue( "team_owner", DOTA_TEAM_NOTEAM )
			if nCurrentTeam ~= DOTA_TEAM_NOTEAM then
				local nTeamParticle = -1
				local nEnemyParticle = -1
				local nSpectatorParticle = -1
				if nCurrentTeam == DOTA_TEAM_GOODGUYS then
					nTeamParticle = ParticleManager:CreateParticleForTeam( "particles/customgames/capturepoints/cp_allied_"..i..".vpcf", PATTACH_ABSORIGIN, cpParticleEnt, DOTA_TEAM_GOODGUYS )
					nSpectatorParticle = ParticleManager:CreateParticleForTeam( "particles/customgames/capturepoints/cp_allied_"..i..".vpcf", PATTACH_ABSORIGIN, cpParticleEnt, 1 )
					nEnemyParticle = ParticleManager:CreateParticleForTeam( "particles/customgames/capturepoints/cp_enemy_"..(numControlPoints-i+1)..".vpcf", PATTACH_ABSORIGIN, cpParticleEnt, DOTA_TEAM_BADGUYS )
				else
					nEnemyParticle = ParticleManager:CreateParticleForTeam( "particles/customgames/capturepoints/cp_enemy_"..i..".vpcf", PATTACH_ABSORIGIN, cpParticleEnt, DOTA_TEAM_GOODGUYS )
					nSpectatorParticle = ParticleManager:CreateParticleForTeam( "particles/customgames/capturepoints/cp_enemy_"..i..".vpcf", PATTACH_ABSORIGIN, cpParticleEnt, 1 )
					nTeamParticle = ParticleManager:CreateParticleForTeam( "particles/customgames/capturepoints/cp_allied_"..(numControlPoints-i+1)..".vpcf", PATTACH_ABSORIGIN, cpParticleEnt, DOTA_TEAM_BADGUYS )
				end
				cpParticleEnt:Attribute_SetIntValue( "particleID_owner", nTeamParticle )
				cpParticleEnt:Attribute_SetIntValue( "particleID_enemy", nEnemyParticle )
				cpParticleEnt:Attribute_SetIntValue( "particleID_spectator", nSpectatorParticle )
				ParticleManager:SetParticleControlEnt( nTeamParticle, 0, cpParticleEnt, PATTACH_ABSORIGIN, nil, cpParticleEnt:GetAbsOrigin(), true )
				ParticleManager:SetParticleControlEnt( nEnemyParticle, 0, cpParticleEnt, PATTACH_ABSORIGIN, nil, cpParticleEnt:GetAbsOrigin(), true )
				ParticleManager:SetParticleControlEnt( nSpectatorParticle, 0, cpParticleEnt, PATTACH_ABSORIGIN, nil, cpParticleEnt:GetAbsOrigin(), true )
			end
		end
	end
end

---------------------------------------------------------------------------
-- Update particles
---------------------------------------------------------------------------
function CConquestGameMode:ParticleUpdate( point, newTeam )
	-- switch text and effects display from the previous owner to the new owner
	if GetMapName() == "test" then return end
	local cp_particle = Entities:FindAllByName( "cp" .. point .. "_particle_neutral" )
	cp_particle[1]:Attribute_SetIntValue( "team_owner", newTeam )
	if point == 3 then
		DoEntFire( "cp3_particle_neutral", "StopPlayEndCap", "0", 0, self, self )
	end
	DoEntFire( "cp_particle_0"..point, "StopPlayEndCap", "0", 0, self, self )
	self:ControlPointUpdateParticles()
end

---------------------------------------------------------------------------
-- Cheat convar for testing
---------------------------------------------------------------------------
function CConquestGameMode:TestCapturePoint( cmdName, point, newTeam )
	print( "Test capture point: " .. point .. " for " .. newTeam )
	CConquestGameMode:DoCapturePoint( tonumber(point), tonumber(newTeam) )
end

---------------------------------------------------------------------------
-- Locked control points
---------------------------------------------------------------------------
function CConquestGameMode:IsPointLocked( index )
	local owner = m_cp_info[index].owner
	if owner == DOTA_TEAM_NOTEAM then
		return false
	end

	if owner == DOTA_TEAM_GOODGUYS then
		if index == ( #m_cp_info ) then
			return false -- final point is never locked
		end

		return ( m_cp_info[index+1].owner ~= DOTA_TEAM_BADGUYS )
	else
		if index == 1 then
			return false -- final point is never locked
		end

		return ( m_cp_info[index-1].owner ~= DOTA_TEAM_GOODGUYS )
	end
end

---------------------------------------------------------------------------
-- Fortified control points
---------------------------------------------------------------------------
function CConquestGameMode:IsPointFortified( index )
	local owner = m_cp_info[index].owner
	if owner == DOTA_TEAM_NOTEAM then
		return false
	end

	if points_fortified == true then
		local particleLocation = "cp_particle_fortification_0"..index
		DoEntFire( "cp_particle_fortification_0"..index, "Start", "0", 0, self, self )
		return true
	else
		return false
	end
end

function CConquestGameMode:RemoveGlyph()
	print("Removing Glyph")
	DoEntFire( "cp_particle_fortification_01", "Stop", "0", 0, self, self )
	DoEntFire( "cp_particle_fortification_02", "Stop", "0", 0, self, self )
	DoEntFire( "cp_particle_fortification_03", "Stop", "0", 0, self, self )
	DoEntFire( "cp_particle_fortification_04", "Stop", "0", 0, self, self )
	DoEntFire( "cp_particle_fortification_05", "Stop", "0", 0, self, self )
	_G.points_fortified = false
end

---------------------------------------------------------------------------
-- Capture rate
---------------------------------------------------------------------------

local COOLDOWN_RATE = -5

function CConquestGameMode:ThinkUpdateCP( index )

	local goodTouchCount = m_cp_info[index].touch_counter[DOTA_TEAM_GOODGUYS]
	local badTouchCount = m_cp_info[index].touch_counter[DOTA_TEAM_BADGUYS]
	if goodTouchCount ~= 0 or badTouchCount ~= 0 then
		--print( "ThinkUpdateCP :" .. index )
		--print("goodTouchCount = " .. goodTouchCount )
		--print("badTouchCount = " .. badTouchCount )
	end

	if goodTouchCount == 0 and badTouchCount == 0 then
		-- nobody on the point
		self:ThinkUpdateCP_Modify( index, COOLDOWN_RATE, COOLDOWN_RATE, 0, 0 )

	elseif goodTouchCount == badTouchCount then
		-- teams are blocking each other, no progress change
		self:ThinkUpdateCP_Modify( index, 0, 0, 0, 0 )

	elseif goodTouchCount > badTouchCount then
		-- radiant capturing
		self:ThinkUpdateCP_Modify( index, self:CalculateCaptureRate( index, DOTA_TEAM_GOODGUYS, goodTouchCount - badTouchCount ), COOLDOWN_RATE, goodTouchCount, badTouchCount )
	
	elseif badTouchCount > goodTouchCount then
		-- dire capturing
		self:ThinkUpdateCP_Modify( index, COOLDOWN_RATE, self:CalculateCaptureRate( index, DOTA_TEAM_BADGUYS, badTouchCount - goodTouchCount ), badTouchCount, goodTouchCount )
	end

	-- Cooldown if capture point is already owned

end

function CConquestGameMode:CalculateCaptureRate( index, cappingTeam, cappingPlayerCount )
	local radiantScore = m_points_owned[DOTA_TEAM_GOODGUYS]
	local direScore = m_points_owned[DOTA_TEAM_BADGUYS]
	local currentPointOwner = m_cp_info[index].owner

	--print("CalculateCaptureRate")
	if currentPointOwner == cappingTeam then
		--print("Capping team already owns the point")
		-- already owned, behave like the point is empty
		return 0
	end

	if self:IsPointLocked( index ) then
		-- locked, behave like the point is empty
		CConquestGameMode:AnnouncerPointIsLocked( index, cappingTeam )
		return 0
	end

	-- Glyph will prevent enemy team from capturing
	if self:IsPointFortified( index ) then
		-- fortified, behave like the point is empty
		--print("Capture Points are fortified")
		return 0
	end

	-- Determine how many players are on each team
	local numberOnTeam = math.floor( HeroList:GetHeroCount() / 2 )
	--print( "numberOnTeam = " .. numberOnTeam )

	local a = 0
	local n = 0
	local playerCountMultiplier = 2
	a = ( cappingPlayerCount * playerCountMultiplier ) + n
	--print("Capture Rate is " .. a)

	-- Make it faster for a team who owns more capture points to capture the point
	local cp_increase = 1
	if currentPointOwner ~= DOTA_TEAM_NOTEAM then
		CConquestGameMode:AnnouncerPointBeingContested( index, cappingTeam )
		if radiantScore > direScore and cappingTeam == DOTA_TEAM_GOODGUYS then
			--print("Radiant will capture at a faster rate")
			cp_increase = 2
		elseif direScore > radiantScore and cappingTeam == DOTA_TEAM_BADGUYS then
			--print("Dire will capture at a faster rate")
			cp_increase = 2
		end
	end
	
	return 2 + a + cp_increase
end

function CConquestGameMode:ThinkUpdateCP_Modify( index, radiantCaptureRate, direCaptureRate, numProCapture, numAntiCapture )
--	print( "ThinkUpdateCP_Modify :" .. index .. ", r = " .. radiantCaptureRate .. ", d = " .. direCaptureRate )
	local numCapturing = numProCapture - numAntiCapture
	local cpInfo = m_cp_info[ index ]
	
	local oldGoodTimer = cpInfo.cp_timer[ DOTA_TEAM_GOODGUYS ]
	local oldBadTimer = cpInfo.cp_timer[ DOTA_TEAM_BADGUYS ]
	-- Progression of capturing a point adds the number of heroes touching to the rate increase
	local newGoodTimer = oldGoodTimer + ( cp_update_period * radiantCaptureRate )
	local newBadTimer = oldBadTimer + ( cp_update_period * direCaptureRate )
	
	m_cp_info[index].num_capturing = numCapturing
	m_cp_info[index].num_pro_capture = numProCapture
	m_cp_info[index].num_anti_capture = numAntiCapture

	-- actually capturing? - nuke the enemy progress
	if radiantCaptureRate > 0 then
		m_cp_info[index].capture_in_progress = true
		m_cp_info[index].last_team_capturing = DOTA_TEAM_GOODGUYS
		newBadTimer = 0
	elseif direCaptureRate > 0 then
		m_cp_info[index].capture_in_progress = true
		m_cp_info[index].last_team_capturing = DOTA_TEAM_BADGUYS
		newGoodTimer = 0
	else
		m_cp_info[index].capture_in_progress = false
		m_cp_info[index].num_capturing = 0
	end

	if newGoodTimer < 0 then
		newGoodTimer = 0
	end
	
	if newBadTimer < 0 then
		newBadTimer = 0
	end
	
	-- Capture Point Particles
	if radiantCaptureRate > 0 or direCaptureRate > 0 then
		local cp_entity = Entities:FindByName( nil, "cp_particle_0" .. index )
		DoEntFire( "cp_particle_0"..index, "Start", "0", 0, self, self )
		if GetMapName() == "haunted_colosseum" then
			EmitSoundOn( "Conquest.capture_point_timer", cp_entity )
		else
			EmitSoundOn( "Conquest.capture_point_timer.Generic", cp_entity )
		end
	else
		DoEntFire( "cp_particle_0"..index, "StopPlayEndCap", "0", 0, self, self )
	end

	-- Team has successfully captured a point
	if newGoodTimer >= g_cp_limit then
		--print("Radiant has captured CP "..index)
		if GetMapName() == "haunted_colosseum" then
			EmitGlobalSound("conquest.stinger.capture_radiant")
		else
			EmitGlobalSound("conquest.stinger.capture_radiant")
			--EmitGlobalSound("conquest.stinger.capture_radiant.generic")
		end
		self:DoCapturePoint( index, DOTA_TEAM_GOODGUYS )
		newGoodTimer = 0
		newBadTimer = 0
	end
	
	if newBadTimer >= g_cp_limit then
		--print("Dire has captured CP "..index)
		if GetMapName() == "haunted_colosseum" then
			EmitGlobalSound("conquest.stinger.capture_dire")
		else
			EmitGlobalSound("conquest.stinger.capture_dire")
			--EmitGlobalSound("conquest.stinger.capture_dire.generic")
		end
		self:DoCapturePoint( index, DOTA_TEAM_BADGUYS )
		newGoodTimer = 0
		newBadTimer = 0
	end
	
	m_cp_info[index].cp_timer[DOTA_TEAM_GOODGUYS] = newGoodTimer
	m_cp_info[index].cp_timer[DOTA_TEAM_BADGUYS] = newBadTimer
	self:UpdateCPNetworking( index )
end

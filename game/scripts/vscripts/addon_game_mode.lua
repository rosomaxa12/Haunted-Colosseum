--[[
Conquest Game Mode
]]

_G.numControlPoints = 5
_G.radiantTotal = 0
_G.direTotal = 0
_G.pointGoal = 5000
_G.all_points_owned = false
_G.game_in_progress = false
_G.allSpawned = false
_G.respawnWaveTime = 0
_G.fireTrapTime = 0
_G.g_cp_limit = 100
_G.points_fortified = false
_G.cp_game_timer = 1201
_G.cp_update_period = 0.25 -- update 4 times per second

---------------------------------------------------------------------------
-- CConquestGameMode class
---------------------------------------------------------------------------
if CConquestGameMode == nil then
	_G.CConquestGameMode = class({}) -- put CConquestGameMode in the global scope
end
---------------------------------------------------------------------------
-- Required .lua files
---------------------------------------------------------------------------
require( "events" )
require( "utility_functions" )
require( "capture_points" )
require( "traps" )

---------------------------------------------------------------------------
-- Capture Points Defined
---------------------------------------------------------------------------
_G.m_points_owned = 
{
	[DOTA_TEAM_NOTEAM] = 0,
	[DOTA_TEAM_GOODGUYS] = 0,
	[DOTA_TEAM_BADGUYS] = 0
}

_G.m_team_name = 
{
	[DOTA_TEAM_NOTEAM] = "neutral",
	[DOTA_TEAM_GOODGUYS] = "radiant",
	[DOTA_TEAM_BADGUYS] = "dire"
}

_G.m_cp_info =
{
	{ capture_in_progress = false, cp_timer = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, touch_counter = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, num_capturing = 0, last_team_capturing = DOTA_TEAM_NOTEAM, owner = DOTA_TEAM_GOODGUYS, },
	{ capture_in_progress = false, cp_timer = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, touch_counter = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, num_capturing = 0, last_team_capturing = DOTA_TEAM_NOTEAM, owner = DOTA_TEAM_GOODGUYS, },
	{ capture_in_progress = false, cp_timer = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, touch_counter = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, num_capturing = 0, last_team_capturing = DOTA_TEAM_NOTEAM, owner = DOTA_TEAM_NOTEAM, },
	{ capture_in_progress = false, cp_timer = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, touch_counter = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, num_capturing = 0, last_team_capturing = DOTA_TEAM_NOTEAM, owner = DOTA_TEAM_BADGUYS, },
	{ capture_in_progress = false, cp_timer = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, touch_counter = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }, num_capturing = 0, last_team_capturing = DOTA_TEAM_NOTEAM, owner = DOTA_TEAM_BADGUYS },
}

---------------------------------------------------------------------------
-- Traps Defined
---------------------------------------------------------------------------
_G.m_trap_info =
{
	{ isTrapActivated = false, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_GOODGUYS, isButtonReady = true, npc_name = "npc_dota_fire_trap_cp1", targetName = "npc_dota_fire_trap_cp1_target", npc_name_alt = "npc_dota_fire_trap_cp1_alt", targetName_alt = "npc_dota_fire_trap_cp1_target_alt", modelName = "fire_trap_cp1_model", modelName_alt = "fire_trap_cp1_model_alt"  },
	{ isTrapActivated = false, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_GOODGUYS, isButtonReady = true, npc_name = "npc_dota_fire_trap_cp2", targetName = "npc_dota_fire_trap_cp2_target", npc_name_alt = "npc_dota_fire_trap_cp2_alt", targetName_alt = "npc_dota_fire_trap_cp2_target_alt", modelName = "fire_trap_cp2_model", modelName_alt = "fire_trap_cp2_model_alt"  },
	{ isTrapActivated = false, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_GOODGUYS, isButtonReady = true, npc_name = "npc_dota_fire_trap_cp3_radiant", targetName = "npc_dota_fire_trap_cp3_radiant_target", npc_name_alt = "npc_dota_fire_trap_cp3_radiant_alt", targetName_alt = "npc_dota_fire_trap_cp3_radiant_target_alt", modelName = "fire_trap_cp3_radiant_model", modelName_alt = "fire_trap_cp3_radiant_model_alt"  },
	{ isTrapActivated = false, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_BADGUYS, isButtonReady = true, npc_name = "npc_dota_fire_trap_cp3_dire", targetName = "npc_dota_fire_trap_cp3_dire_target", npc_name_alt = "npc_dota_fire_trap_cp3_dire_alt", targetName_alt = "npc_dota_fire_trap_cp3_dire_target_alt", modelName = "fire_trap_cp3_dire_model", modelName_alt = "fire_trap_cp3_dire_model_alt"  },
	{ isTrapActivated = false, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_BADGUYS, isButtonReady = true, npc_name = "npc_dota_fire_trap_cp4", targetName = "npc_dota_fire_trap_cp4_target", npc_name_alt = "npc_dota_fire_trap_cp4_alt", targetName_alt = "npc_dota_fire_trap_cp4_target_alt", modelName = "fire_trap_cp4_model", modelName_alt = "fire_trap_cp4_model_alt"  },
	{ isTrapActivated = false, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_BADGUYS, isButtonReady = true, npc_name = "npc_dota_fire_trap_cp5", targetName = "npc_dota_fire_trap_cp5_target", npc_name_alt = "npc_dota_fire_trap_cp5_alt", targetName_alt = "npc_dota_fire_trap_cp5_target_alt", modelName = "fire_trap_cp5_model", modelName_alt = "fire_trap_cp5_model_alt"  },
	{ isTrapActivated = false, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_GOODGUYS, isButtonReady = true, npc_name = "npc_dota_venom_trap_radiant", targetName = "npc_dota_venom_trap_radiant_target", npc_name_alt = "npc_dota_venom_trap_radiant_alt", targetName_alt = "npc_dota_venom_trap_radiant_target_alt", modelName = "venom_trap_radiant_model", modelName_alt = "venom_trap_radiant_model_alt" },
	{ isTrapActivated = false, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_BADGUYS, isButtonReady = true, npc_name = "npc_dota_venom_trap_dire", targetName = "npc_dota_venom_trap_dire_target", npc_name_alt = "npc_dota_venom_trap_dire_alt", targetName_alt = "npc_dota_venom_trap_dire_target_alt", modelName = "venom_trap_dire_model", modelName_alt = "venom_trap_dire_model_alt" }
}

_G.m_pendulum_info =
{
	{ isPendulumReady = true, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_GOODGUYS, isButtonReady = true, npc_name = "npc_dota_pendulum_trap_radiant", pendulum_name = "trap_pendulum_radiant" },
	{ isPendulumReady = true, touchers = { [DOTA_TEAM_GOODGUYS] = {}, [DOTA_TEAM_BADGUYS] = {} }, owner = DOTA_TEAM_BADGUYS, isButtonReady = true, npc_name = "npc_dota_pendulum_trap_dire", pendulum_name = "trap_pendulum_dire" }
}

---------------------------------------------------------------------------
-- Precache
---------------------------------------------------------------------------
function Precache( context )
	--Cache the item drops
	PrecacheItemByNameSync( "item_bag_of_gold", context )
	PrecacheModel( "item_bag_of_gold", context )

	PrecacheItemByNameSync( "item_fountain_potion", context )
	PrecacheModel( "item_fountain_potion", context )

	PrecacheItemByNameSync( "item_mango_juice", context )
	PrecacheModel( "item_mango_juice", context )

	PrecacheItemByNameSync( "item_candy", context )
	PrecacheModel( "item_candy", context )

	PrecacheItemByNameSync( "item_waypoint_entrance", context )
	PrecacheModel( "item_waypoint_entrance", context )

    PrecacheUnitByNameSync( "npc_dota_creep_radiant_hulk", context )
    PrecacheModel( "npc_dota_creep_radiant_hulk", context )

    PrecacheUnitByNameSync( "npc_dota_creep_radiant_golem", context )
    PrecacheModel( "npc_dota_creep_radiant_golem", context )

    PrecacheUnitByNameSync( "npc_dota_creep_dire_hulk", context )
    PrecacheModel( "npc_dota_creep_dire_hulk", context )

    PrecacheUnitByNameSync( "npc_dota_creep_dire_golem", context )
    PrecacheModel( "npc_dota_creep_dire_golem", context )

	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_warlock.vsndevts", context )

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_dragon_knight", context )

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_venomancer", context )

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_axe", context )

	PrecacheResource( "particle_folder", "particles/units/heroes/hero_life_stealer", context )

	--Cache new particles
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_wind.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_allied_1.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_enemy_1.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_wood.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_allied_2.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_enemy_2.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_earth.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_allied_3.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_enemy_3.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_metal.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_allied_4.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_enemy_4.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_fire.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_allied_5.vpcf", context )
	PrecacheResource( "particle", "particles/customgames/capturepoints/cp_enemy_5.vpcf", context )

	PrecacheResource( "particle", "particles/addons_gameplay/player_deferred_light.vpcf", context )
	PrecacheResource( "particle", "particles/newplayer_fx/npx_landslide_debris.vpcf", context )
	PrecacheResource( "particle", "particles/items2_fx/teleport_end_ground_flash.vpcf", context )
	PrecacheResource( "particle", "particles/fire_trap/trap_breathe_fire.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_axe/axe_culling_blade.vpcf", context )
	PrecacheResource( "particle", "particles/creeps/lane_creeps/creep_radiant_hulk_ambient.vpcf", context )
	PrecacheResource( "particle", "particles/creeps/lane_creeps/creep_dire_hulk_flames.vpcf", context )
	PrecacheResource( "particle", "particles/waypoint/waypoint_ground_flash_holo.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/lone_druid/lone_druid_cauldron/lone_druid_bear_entangle_dust_cauldron.vpcf", context )

	--Cache custom sounds
	PrecacheResource( "soundfile", "soundevents/soundevents_conquest.vsndevts", context )
end

---------------------------------------------------------------------------
-- Create the game mode
---------------------------------------------------------------------------
function Activate()
	CConquestGameMode:InitGameMode()
end

---------------------------------------------------------------------------
-- Initializer
---------------------------------------------------------------------------
function CConquestGameMode:InitGameMode()
	print( "Conquest Mode is loaded." )

	self.gameHasEnded = false
	-- Setting up for Many Players
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 5 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 5 )
	GameRules:GetGameModeEntity().CConquestGameMode = self
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 1 )
	GameRules:SetCustomGameSetupAutoLaunchDelay(15)
	GameRules:SetStrategyTime(10)
	GameRules:SetHeroSelectionTime( 30 )
	GameRules:SetHeroSelectPenaltyTime( 10.0 )
	GameRules:SetPreGameTime( 13 )
	GameRules:SetCustomGameEndDelay( 0 )
	GameRules:SetShowcaseTime( 0 )
	GameRules:SetTimeOfDay( 0.75 )
	GameRules:SetFirstBloodActive( true )
	GameRules:GetGameModeEntity():SetAnnouncerDisabled( false )
	GameRules:GetGameModeEntity():SetRecommendedItemsDisabled( false )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetHideKillMessageHeaders( true )
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath( false )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( false )
	GameRules:GetGameModeEntity():SetModifyGoldFilter( Dynamic_Wrap( CConquestGameMode, "ModifyGoldFilter" ), self )
	GameRules:GetGameModeEntity():SetModifyExperienceFilter( Dynamic_Wrap( CConquestGameMode, "ModifyExperienceFilter" ), self )
	GameRules:GetGameModeEntity():SetRuneEnabled( 0, true ) --Double Damage
	GameRules:GetGameModeEntity():SetRuneEnabled( 1, true ) --Haste
	GameRules:GetGameModeEntity():SetRuneEnabled( 2, true ) --Illusion
	GameRules:GetGameModeEntity():SetRuneEnabled( 3, true ) --Invis
	GameRules:GetGameModeEntity():SetRuneEnabled( 4, true ) --Regen
	GameRules:GetGameModeEntity():SetRuneEnabled( 5, false ) --Bounty
	GameRules:GetGameModeEntity():SetStickyItemDisabled( false ) --Remove TP Scroll
	GameRules:GetGameModeEntity():SetDefaultStickyItem( "item_boots" )
	GameRules:GetGameModeEntity():SetFountainPercentageHealthRegen( 0 )
	GameRules:GetGameModeEntity():SetFountainPercentageManaRegen( 0 )
	GameRules:GetGameModeEntity():SetFountainConstantManaRegen( 0 )
	GameRules:GetGameModeEntity():SetCustomBuybackCooldownEnabled( true )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( CConquestGameMode, "ExecuteOrderFilter" ), self )

	-- Hook into game events
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CConquestGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CConquestGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "dota_item_picked_up", Dynamic_Wrap( CConquestGameMode, "OnItemPickUp"), self )
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CConquestGameMode, "OnGameRulesStateChange" ), self )
	ListenToGameEvent( "player_connect", Dynamic_Wrap( CConquestGameMode, "OnPlayerConnect"), self )
	
	Convars:RegisterCommand( "conquest_capture_point", function(...) return self:TestCapturePoint( ... ) end, "Captures a point.", FCVAR_CHEAT )
	Convars:RegisterCommand( "conquest_spawn_creeps", function(...) return self:TestCreepSpawn( ... ) end, "Spawns creeps.", FCVAR_CHEAT )
	Convars:RegisterCommand( "conquest_start_pendulum", function(...) return self:TestPendulum( ... ) end, "Start the pendulum.", FCVAR_CHEAT )
	Convars:SetInt( "dota_server_side_animation_heroesonly", 0 )
	Convars:SetInt( "dota_daynightcycle_pause", 1 )
	
	-- Set up the Control Point Entities
	CConquestGameMode:ControlPointSetup()
	CConquestGameMode:SetUpFountains()
	CConquestGameMode:PendulumSetup()
end


---------------------------------------------------------------------------
-- Set up fountain regen
---------------------------------------------------------------------------
function CConquestGameMode:SetUpFountains()

	LinkLuaModifier( "modifier_fountain_aura_lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier( "modifier_fountain_aura_effect_lua", LUA_MODIFIER_MOTION_NONE )

	local fountainEntities = Entities:FindAllByClassname( "ent_dota_fountain")
	for _,fountainEnt in pairs( fountainEntities ) do
		--print("fountain unit " .. tostring( fountainEnt ) )
		fountainEnt:AddNewModifier( fountainEnt, nil, "modifier_fountain_aura_lua", {} )

	end
end


---------------------------------------------------------------------------
-- Evaluate the state of the game
---------------------------------------------------------------------------
function CConquestGameMode:OnThink()
	--print( "CConquestGameMode:OnThink()" )
	if GameRules:IsGamePaused() == true then
		--print( "Skipping OnThink because game is paused." )
		return cp_update_period
	end
	
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		CConquestGameMode:ThinkLootExpiration()
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end

	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print("Game in progress")
		CConquestGameMode:UpdateScoreboard()
		CConquestGameMode:RespawnWaveTimer()
		-- Starting the CP timer when all points have been captured by either team
		--print( "CConquestGameMode:OnThink " .. m_points_owned[DOTA_TEAM_GOODGUYS] .. " " .. m_points_owned[DOTA_TEAM_BADGUYS] )
		if m_points_owned[DOTA_TEAM_GOODGUYS] + m_points_owned[DOTA_TEAM_BADGUYS] == 5 and self.gameHasEnded == false then
			--print("All points owned")
			_G.all_points_owned = true
			--CConquestGameMode:ControlPointTimer()
		end
	end
	return cp_update_period
end

---------------------------------------------------------------------------
-- Loot drop
---------------------------------------------------------------------------
function CConquestGameMode:CheckForLootItemDrop( killedUnit )
	--print("Creating item to drop")
	local tableindex = 0
	local r = ""
	local c = RandomInt(1,100)
	if c < 20 then
		r = "item_bag_of_gold"
	elseif c >= 20 and c <= 50 then
		r = "item_fountain_potion"
	elseif c > 50 and c <= 80 then
		r = "item_mango_juice"
	else
		return nil
	end	

	if killedUnit:GetClassname() == "npc_dota_creep_neutral" then
		--print("Golem dropping gold coin")
		local modelID = killedUnit:Attribute_GetIntValue( "modelID", -1 )
		--print(modelID)
		if modelID == -1 then
			--print("Gold")
			r = "item_bag_of_gold" 
		else
			--print("Candy")
			r = "item_halloween_candy"
		end
	end
	local newItem = CreateItem( r, nil, nil )
	local drop = CreateItemOnPositionSync( killedUnit:GetAbsOrigin(), newItem )
	newItem:LaunchLoot( false, 300, 0.75, killedUnit:GetAbsOrigin() + RandomVector( RandomFloat( 250, 400 ) ) )
end

function CConquestGameMode:ThinkLootExpiration()
	local flCutoffTime = GameRules:GetGameTime() - 10
	for _,item in pairs( Entities:FindAllByClassname( "dota_item_drop")) do
		local containedItem = item:GetContainedItem()
		if containedItem ~= nil then
			if containedItem:GetAbilityName() == "item_bag_of_gold" 
				or containedItem:GetAbilityName() == "item_fountain_potion" 
				or containedItem:GetAbilityName() == "item_mango_juice"
				or containedItem:GetAbilityName() == "item_halloween_candy" then
					CConquestGameMode:ProcessItemForLootExpiration( item, flCutoffTime )
			end
		end
	end
end

function CConquestGameMode:ProcessItemForLootExpiration( item, flCutoffTime )
	if item:IsNull() then
		return false
	end
	if item:GetCreationTime() >= flCutoffTime then
		return true
	end

	local containedItem = item:GetContainedItem()
	if containedItem and containedItem:GetAbilityName() == "item_bag_of_gold" then
		if self._currentRound and self._currentRound.OnGoldBagExpired then
			self._currentRound:OnGoldBagExpired()
		end
	end

	local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, item )
	ParticleManager:SetParticleControl( nFXIndex, 0, item:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )
	local inventoryItem = item:GetContainedItem()
	if inventoryItem then
		UTIL_Remove( inventoryItem )
	end
	EmitGlobalSound("Item.PickUpWorld")
	UTIL_Remove( item )
	return false

end

---------------------------------------------------------------------------
-- Spawn Creeps
---------------------------------------------------------------------------
function CConquestGameMode:SpawnCreeps( team, phase )
	local numberToSpawn = phase
	local creeps = ""
	if team == 2 then
		--print("Radiant Spawn Creeps")
	    local SpawnLocation = Entities:FindByName( nil, "radiant_creep_mega" )
	    local waypointlocation = Entities:FindByName( nil, "radiant_creep_path_1" )
		if SpawnLocation == nil then
			--print("Couldn't find spawn location")
			return
		end
		for i = 1, numberToSpawn do
			local randomModel = RandomInt(1,2)
			if randomModel == 1 then
				creeps = "npc_dota_creep_radiant_hulk"
			else
				creeps = "npc_dota_creep_radiant_golem"
			end
		    local creature = CreateUnitByName( creeps, SpawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_GOODGUYS )
		    --print ("Spawning Radiant Creeps")
			creature:SetInitialGoalEntity( waypointlocation )
			local creatureEffects = ParticleManager:CreateParticle( "particles/creeps/lane_creeps/creep_radiant_hulk_ambient.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, creature )
			ParticleManager:SetParticleControlEnt( creatureEffects, 0, creature, PATTACH_POINT_FOLLOW, "attach_hitloc", creature:GetAbsOrigin(), false )
			creature:Attribute_SetIntValue( "effectsID", creatureEffects )
			local sightEffects = ParticleManager:CreateParticle( "particles/items2_fx/ward_true_sight.vpcf", PATTACH_OVERHEAD_FOLLOW, creature )
			ParticleManager:SetParticleControlEnt( sightEffects, 0, creature, PATTACH_OVERHEAD_FOLLOW, "follow_overhead", creature:GetAbsOrigin(), false )
			creature:Attribute_SetIntValue( "sightID", sightEffects )
			if randomModel == 2 then
				creature:Attribute_SetIntValue( "modelID", 1 )
			end
		end
	elseif team == 3 then
		--print("Dire Spawn Creeps")
	    local SpawnLocation = Entities:FindByName( nil, "dire_creep_mega" )
	    local waypointlocation = Entities:FindByName( nil, "dire_creep_path_1" )
		if SpawnLocation == nil then
			--print("Couldn't find spawn location")
			return
		end
		for i = 1, numberToSpawn do
			local randomModel = RandomInt(1,2)
			if randomModel == 1 then
				creeps = "npc_dota_creep_dire_hulk"
			else
				creeps = "npc_dota_creep_dire_golem"
			end
		    local creature = CreateUnitByName( creeps, SpawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )
		    --print ("Spawning Dire Creeps")
			creature:SetInitialGoalEntity( waypointlocation )
			local creatureEffects = ParticleManager:CreateParticle( "particles/creeps/lane_creeps/creep_dire_hulk_flames.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, creature )
			ParticleManager:SetParticleControlEnt( creatureEffects, 0, creature, PATTACH_POINT_FOLLOW, "attach_hitloc", creature:GetAbsOrigin(), false )
			creature:Attribute_SetIntValue( "effectsID", creatureEffects )
			local sightEffects = ParticleManager:CreateParticle( "particles/items2_fx/ward_true_sight.vpcf", PATTACH_OVERHEAD_FOLLOW, creature )
			ParticleManager:SetParticleControlEnt( sightEffects, 0, creature, PATTACH_OVERHEAD_FOLLOW, "follow_overhead", creature:GetAbsOrigin(), false )
			creature:Attribute_SetIntValue( "sightID", sightEffects )
			if randomModel == 2 then
				creature:Attribute_SetIntValue( "modelID", 1 )
			end
		end
	end
end

---------------------------------------------------------------------------
-- Cheat convar for testing
---------------------------------------------------------------------------
function CConquestGameMode:TestCreepSpawn( cmdName, team, phase )
	--print( "Test creep spawn: " .. team )
	CConquestGameMode:SpawnCreeps(tonumber(team), tonumber(phase))
end

---------------------------------------------------------------------------
-- End Game Conditions
---------------------------------------------------------------------------
function CConquestGameMode:EndGame(team)
	CConquestGameMode:AnnouncerEndGame( team )
	GameRules:SetGameWinner(team)
	self.gameHasEnded = true
	for i = 1, numControlPoints do
		DoEntFire( "cp"..i, "Disable", "0", 0, self, self )
	end
end

---------------------------------------------------------------------------
-- Not allowing bounty for kills
---------------------------------------------------------------------------

function CConquestGameMode:ModifyGoldFilter( filterTable )
	--[[for k, v in pairs( filterTable ) do
		print("ModifyGold: " .. k .. " " .. tostring(v) )
	end
	]]
	--local reason = filterTable["reason_const"]
	if game_in_progress == false then
		return false
	end
	return true
end


function CConquestGameMode:ModifyExperienceFilter( filterTable )
	--[[for k, v in pairs( filterTable ) do
		print("ModifyXP: " .. k .. " " .. tostring(v) )
	end
	]]
	--local reason = filterTable["reason_const"]
	if game_in_progress == false then
		return false
	end
	return true
end

---------------------------------------------------------------------------
-- Filters
---------------------------------------------------------------------------

function CConquestGameMode:ExecuteOrderFilter( filterTable )
	local orderType = filterTable["order_type"]
	local playerID = filterTable["issuer_player_id_const"]
	if orderType == DOTA_UNIT_ORDER_BUYBACK then 
		-- Set the buyback cooldown to 3 minutes for this player
		PlayerResource:SetCustomBuybackCooldown( playerID, 180 )
		return true
	end
	if orderType == DOTA_UNIT_ORDER_GLYPH then
		print("Glyph has been used")
		local team = PlayerResource:GetTeam(playerID)
		-- Stop capture on all points
		CConquestGameMode:AnnouncerFortified()
		EmitGlobalSound("Conquest.Glyph.Cast")
		_G.points_fortified = true
		GameRules:GetGameModeEntity():SetContextThink( "RemoveGlyph", function() CConquestGameMode:RemoveGlyph() end, 10 )
		return true
	end
	if ( orderType ~= DOTA_UNIT_ORDER_PICKUP_ITEM or filterTable["issuer_player_id_const"] == -1 ) then
		return true
	else
		local item = EntIndexToHScript( filterTable["entindex_target"] )
		if item == nil then
			return true
		end
		local pickedItem = item:GetContainedItem()
		--print(pickedItem:GetAbilityName())
		if pickedItem == nil then
			return true
		end
		if pickedItem:GetAbilityName() == "item_waypoint_entrance_radiant" or 
		pickedItem:GetAbilityName() == "item_button_pendulum_radiant" or
		pickedItem:GetAbilityName() == "item_button_firetrap_radiant" or
		pickedItem:GetAbilityName() == "item_button_venomtrap_radiant" or
		pickedItem:GetAbilityName() == "item_waypoint_entrance_dire" or 
		pickedItem:GetAbilityName() == "item_button_pendulum_dire" or
		pickedItem:GetAbilityName() == "item_button_firetrap_dire" or
		pickedItem:GetAbilityName() == "item_button_venomtrap_dire" then
			local position = item:GetAbsOrigin()
			filterTable["position_x"] = position.x
			filterTable["position_y"] = position.y
			filterTable["position_z"] = position.z
			filterTable["order_type"] = DOTA_UNIT_ORDER_MOVE_TO_POSITION
			return true
		end
	end
	return true
end

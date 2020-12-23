
modifier_patreon_courier = {
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	RemoveOnDeath = function() return false end,

	DeclareFunctions = function()
		return {
			MODIFIER_PROPERTY_MOVESPEED_MAX,
			MODIFIER_PROPERTY_MOVESPEED_LIMIT,
			MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
			MODIFIER_PROPERTY_FIXED_DAY_VISION,
			MODIFIER_PROPERTY_FIXED_NIGHT_VISION,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_MODEL_CHANGE,
			MODIFIER_EVENT_ON_MODEL_CHANGED,
		}
	end,
	GetFixedDayVision = function() return 150 end,
	GetFixedNightVision = function() return 150 end,
}

function modifier_patreon_courier:GetModifierMoveSpeed_Max()
	if self:GetCaster():HasFlyMovementCapability() then
		return 1600
	else
		return 1600
	end
end

function modifier_patreon_courier:GetModifierMoveSpeed_Limit()
	if self:GetCaster():HasFlyMovementCapability() then
		return 1600
	else
		return 1600
	end
end

function modifier_patreon_courier:GetModifierMoveSpeed_Absolute()
	if self:GetCaster():HasFlyMovementCapability() then
		return 1600
	else
		return 1600
	end
end

function modifier_patreon_courier:OnTakeDamage()
	if self:GetCaster():GetHealth() < 1 then
		local courier_spawn = {}
		courier_spawn[2] = Entities:FindByClassname(nil, "info_courier_spawn_radiant")
		courier_spawn[3] = Entities:FindByClassname(nil, "info_courier_spawn_dire")
		self:GetCaster():SetHealth( self:GetCaster():GetMaxHealth() )
		self:GetCaster():SetAbsOrigin(courier_spawn[self:GetCaster():GetTeam()]:GetAbsOrigin())
		self:GetCaster():AddNewModifier(self:GetCaster(), nil, "modifier_stunned", { duration = 60 })
	end
end

function modifier_patreon_courier:GetModifierModelChange()
	return "models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl"
end

function modifier_patreon_courier:OnModelChanged()
	local parent = self:GetParent()
	parent:SetModel("models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl")
	parent:SetOriginalModel("models/items/juggernaut/ward/fortunes_tout/fortunes_tout.vmdl")
end
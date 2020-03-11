AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("clStopStream")
util.AddNetworkString("clPauseStream")
util.AddNetworkString("clPlayStream")
util.AddNetworkString("clRadioMenu")
util.AddNetworkString("svPauseStream")
util.AddNetworkString("svPlayStream")

function ENT:Initialize()
	self:SetModel("models/props/cs_office/radio.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	
	self.damage = 100
end

function ENT:OnTakeDamage(dmg)
	self.damage = self.damage - dmg:GetDamage()
	if (self.damage <= 0) then
		self:Destruct()
		self:Remove()
	end
end

function ENT:Destruct()
	local vPoint = self:GetPos()
	local effectdata = EffectData()
	effectdata:SetStart(vPoint)
	effectdata:SetOrigin(vPoint)
	effectdata:SetScale(1)
	util.Effect("Explosion", effectdata)
end

function ENT:Use(activator,caller)
	local owner = self:Getowning_ent()
	
	if activator == owner then
		net.Start("clRadioMenu")
		net.Send(activator)
	end
end

net.Receive("svPauseStream", function( l, ply )
	for _, ent in pairs(ents.FindByClass('radio')) do
		if ent:Getowning_ent() == ply then
			for _k, _v in pairs(player.GetAll()) do
				net.Start("clPauseStream")
					net.WriteEntity(ent)
				net.Send(_v)
			end
			
			break
		end
	end
end)

net.Receive("svPlayStream", function( l, ply )
	stream = net.ReadString() or nil
	
	if stream then
		for _, ent in pairs(ents.FindByClass('radio')) do
			if ent:Getowning_ent() == ply then
				ent.Stream = stream
				
				for _k, _v in pairs(player.GetAll()) do
					net.Start("clPlayStream")
						net.WriteString(stream)
						net.WriteEntity(ent)
					net.Send(_v)
				end
			end
		end
	end
end)

hook.Add("PlayerInitialSpawn", "syncRadio", function( ply )
	timer.Simple(5, function()
		for _, ent in pairs(ents.FindByClass('radio')) do
			if ent.Stream then
				net.Start("clPlayStream")
					net.WriteString(ent.Stream)
					net.WriteEntity(ent)
				net.Send(ply)
			end
		end
	end)
end)


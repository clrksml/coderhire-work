AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/thrusters/jetpack.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetActive(false)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetFuel(500)
	
	if string.find(engine.ActiveGamemode():lower(), "darkrp") then
		self:SetOwner(self:Getowning_ent())
	end
end

function ENT:Think()
	if !self.Sound then
		self.Sound = CreateSound(self, "npc/env_headcrabcanister/hiss.wav")
	end
	
	if !self:GetOwner() then if self.Sound:IsPlaying() then self:SetActive(false) end return end
	if !self:GetOwner():Alive() then if self.Sound:IsPlaying() then self:SetActive(false) end return end
	
	local pos, ang = self:GetOwner():GetBonePosition(self:GetOwner():LookupBone("ValveBiped.Bip01_Spine"))
	local ang2 = Angle(ang.p, ang.y, ang.r)
	ang2:RotateAroundAxis(ang:Right(), 90)
	ang2:RotateAroundAxis(ang:Up(), 0)
	ang2:RotateAroundAxis(ang:Forward(), 90)
	
	self:SetPos(pos + (ang:Up() * 0) + (ang:Right() * 5) + (ang:Forward() * 13))
	self:SetAngles(ang2)
	
	if !self:GetOwner():KeyDown(IN_JUMP) and !self:GetOwner():KeyDown(IN_JUMP) and !self:GetOwner():KeyDown(IN_USE) or self:GetFuel() <= 0 then
		if self.Sound:IsPlaying() then
			self.Sound:Stop()
		end
		if self:GetActive() then
			self:GetOwner():SetMoveType(MOVETYPE_WALK)
			self:SetActive(false)
		end
	end
	
	if self:GetFuel() <= 0 and string.find(engine.ActiveGamemode():lower(), "darkrp") then
		DarkRP.notify(ply, 1, 4, "You can buy fuel by typing /buyjpfuel .")
	end
	
	if self:GetOwner():KeyDown(IN_JUMP) and !self:GetOwner():KeyDown(IN_USE) and self:GetFuel() > 0 then
		self:GetOwner():SetVelocity(self:GetOwner():GetAimVector() * 250 + Vector(0, 0, 50))
		self:GetOwner():SetMoveType(MOVETYPE_FLY)
		self:SetActive(true)
		self:SetFuel(math.Clamp(self:GetFuel() - 1, 0, 500))
		
		if !self.Sound:IsPlaying() then
			self.Sound:Play()
		end
	elseif self:GetOwner():KeyDown(IN_USE) and self:GetOwner():KeyDown(IN_JUMP) and self:GetFuel() > 0 then
		self:GetOwner():SetLocalVelocity((self:GetOwner():GetForward() * 50) + (self:GetOwner():GetUp() * 50) + Vector(0, 0, 100))
		self:GetOwner():SetMoveType(MOVETYPE_FLY)
		self:SetActive(true)
		self:SetFuel(math.Clamp(self:GetFuel() - 0.2, 0, 500))
		
		if !self.Sound:IsPlaying() then
			self.Sound:Play()
		end
	end
end

function ENT:OnRemove()
	self:SetActive(false)
	
	self.Sound:Stop()
end

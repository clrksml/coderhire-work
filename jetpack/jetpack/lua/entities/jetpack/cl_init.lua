include("shared.lua")

function ENT:Initialize()
	if string.find(engine.ActiveGamemode():lower(), "darkrp") then
		self:GetOwner():ChatPrint(string.upper(input.LookupBinding("jump")) .. " to move in a upward forward direction.")
		self:GetOwner():ChatPrint(string.upper(input.LookupBinding("jump")) .. " and " .. string.upper(input.LookupBinding("use")) .. " to move forward in a hover.")
	end
end

function ENT:Draw()
	if self:GetOwner() then
		local pos, ang = self:GetOwner():GetBonePosition(self:GetOwner():LookupBone("ValveBiped.Bip01_Spine"))
		local ang2 = Angle(ang.p, ang.y, ang.r)
		ang2:RotateAroundAxis(ang:Right(), 90)
		ang2:RotateAroundAxis(ang:Up(), 0)
		ang2:RotateAroundAxis(ang:Forward(), 90)
		
		self:SetPos(pos + (ang:Up() * 0) + (ang:Right() * 5) + (ang:Forward() * 10))
		self:SetAngles(ang2)
		
		if self:GetActive() then
			local pos, ang = self:GetOwner():GetBonePosition(self:GetOwner():LookupBone("ValveBiped.Bip01_Spine"))
			local emitter = ParticleEmitter(self:GetOwner():GetPos())
			
			local particle = emitter:Add("particle/warp1_warp.vmt", pos - (ang:Forward() *2))
			particle:SetColor(255, 255, 255, 255)
			particle:SetVelocity(Vector(0, 0, 10))
			particle:SetDieTime(0.1)
			particle:SetStartSize(3)
			particle:SetEndSize(3)
			
			emitter:Finish()
		end
		
		self:DrawModel()
	end
end

function ENT:Think()
	self:Draw()
end


if SERVER then
	AddCSLuaFile("shared.lua")
end

ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = "models/dav0r/hoverball.mdl"

AccessorFunc( ENT, "radius", "Radius", FORCE_NUMBER )
AccessorFunc( ENT, "dmg", "Dmg", FORCE_NUMBER )
AccessorFunc( ENT, "scale", "Scale", FORCE_NUMBER )

function ENT:Initialize()
	if not self:GetRadius() then self:SetRadius(256) end
	if not self:GetDmg() then self:SetDmg(25) end
	if not self:GetScale() then self:SetScale(38) end
	
	self:SetMaterial("models/debug/debugwhite")
	self:SetColor(Color(0, 0, 0))
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	if SERVER then
		util.SpriteTrail(self, 0, Color(0, 0, 0), false, 0, 1.5, 0.25, 1, "trails/smoke.vmt")
		
		self.glow = ents.Create("env_sprite")
		self.glow:SetPos(self:GetPos())
		self.glow:SetRenderFX(1)
		self.glow:SetRenderMode(9)
		self.glow:SetColor(Color(255, 0, 0))
		self.glow:SetKeyValue("model", "light_glow03.spr")
		self.glow:SetKeyValue("GlowProxySize", "5")
		self.glow:SetKeyValue("framerate", "15")
		self.glow:SetParent(self)
		self.glow:Spawn()
		
		timer.Simple(2, function()
			if !IsValid(self) then return end
			
			self:GetPhysicsObject():EnableDrag(true)
		end)
	end
	
	return self.BaseClass.Initialize(self)
end

function ENT:Touch(ent)
	if SERVER then
		if IsValid(ent) and ent:IsPlayer() then
			self:SetScale(self:GetScale() / 2)
			self:SetExplodeTime(CurTime() - 1)
		end
	end
end

function ENT:Think()
	local etime = self:GetExplodeTime() or 0
	if etime != 0 and etime < CurTime() then
		if SERVER and (not IsValid(self:GetThrower())) then
			self:Remove()
			etime = 0
			return
		end
		
		local spos = self:GetPos()
		local tr = util.TraceLine({start=spos, endpos=spos + Vector(0,0,-32), mask=MASK_SHOT_HULL, filter=self.thrower})
		
		local success, err = pcall(self.Explode, self, tr)
		if not success then
			self:Remove()
			ErrorNoHalt("ERROR CAUGHT: ttt_grenade_proj: " .. err .. "\n")
		end
	end
	
	if SERVER then
		if self.lastThink and self.lastThink <= CurTime() then
			self:EmitSound("Grenade.Blip")
			self.lastThink = CurTime() + 0.4
		elseif !self.lastThink then
			self:EmitSound("Grenade.Blip")
			self.lastThink = CurTime() + 0.2
		end
	end
end

function ENT:Explode(tr)
	if SERVER then
		if !IsValid(self) then return end
		
		self:SetNoDraw(true)
		self:SetSolid(SOLID_NONE)
		
		if tr.Fraction != 1.0 then
			self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
		end
		
		local pos = self:GetPos()
		
		if util.PointContents(pos) == CONTENTS_WATER then
			self:Remove()
			return
		end
		
		local effect = EffectData()
		effect:SetStart(pos)
		effect:SetOrigin(pos)
		effect:SetRadius(self:GetRadius())
		effect:SetMagnitude(self:GetDmg())
		effect:SetScale(self:GetScale())
		
		if tr.Fraction != 1.0 then
			effect:SetNormal(tr.HitNormal)
		end
		
		util.Effect("Explosion", effect, true, true)
		util.BlastDamage(self, self:GetThrower(), pos, self:GetRadius(), 75)
		
		self:SetDetonateExact(0)
		
		self:Remove()
	else
		if !IsValid(self) then return end
		
		local spos = self:GetPos()
		local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-128), filter=self})
		util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
		
		self:SetDetonateExact(0)
	end
end

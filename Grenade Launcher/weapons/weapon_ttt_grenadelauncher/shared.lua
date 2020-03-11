if SERVER then
	AddCSLuaFile("shared.lua")
	
	resource.AddSingleFile("materials/VGUI/ttt/icon_nadelauncher.vtf")
	resource.AddSingleFile("materials/VGUI/ttt/icon_nadelauncher.vmt")
end

SWEP.HoldType = "physgun"

if CLIENT then
	SWEP.PrintName = "Grenade Launcher"
	SWEP.Author = "Clark (Aide)"
	SWEP.Slot = 7
	
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "A launcher device that launches explosive balls.\nReload to switch from/to timed detonation or hit detonation."
	}
	
	SWEP.Icon = "VGUI/ttt/icon_nadelauncher"
	
	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 54
end

SWEP.Base					= "weapon_tttbase"
SWEP.Primary.Sound			= Sound( "weapons/ar2/fire1.wav" )
SWEP.Primary.Ammo			= "nadeproj"
SWEP.Primary.ClipSize		= 3
SWEP.Primary.DefaultClip	= 3
SWEP.Primary.Automatic		= true
SWEP.Primary.Delay			= 1
SWEP.Primary.Cone 			= 0.005
SWEP.Primary.Recoil 		= 2
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "nadeproj"
SWEP.Secondary.Delay		= 3
SWEP.Secondary.Recoil 		= 2

// The following effect the damage, scale, and radius of the primary fire explosion.
SWEP.Primary.Damage			= 25
SWEP.Primary.Scale			= 38
SWEP.Primary.Radius			= 256

// The following effect the damage, scale, and radius of the secondary fire explosion.
SWEP.Secondary.Damage		= 19
SWEP.Secondary.Scale		= 15
SWEP.Secondary.Radius		= 128

SWEP.Projectile				= "ttt_grenade_proj"
SWEP.AutoSpawnable			= false
SWEP.NoSights				= true
SWEP.Kind					= WEAPON_EQUIP2
SWEP.CanBuy					= {ROLE_TRAITOR}
SWEP.WeaponID				= AMMO_PUSH

SWEP.UseHands				= true
SWEP.ViewModel				= "models/weapons/c_physcannon.mdl"
SWEP.WorldModel				= "models/weapons/w_physics.mdl"

function SWEP:Initialize()
	if SERVER then
		self:SetSkin(0)
		
		self.NextReload = CurTime()
	end
	
	return self.BaseClass.Initialize(self)
end

function SWEP:PrimaryAttack()
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	local tr = self.Owner:GetEyeTrace()
	
	if self.Weapon:Clip1() <= 0 then
		self:DryFire(self.SetNextPrimaryFire)
		return false
	end
	self:TakePrimaryAmmo(1)
	self:EmitSound(self.Primary.Sound)
	
	if (!SERVER) then return end
	
	local gren = ents.Create(self.Projectile)
	gren:SetPos(self.Owner:EyePos() + (self.Owner:GetAimVector() * 125) + Vector(0, 0, 10))
	gren:SetAngles(self.Owner:EyeAngles())
	gren:Spawn()
	gren:PhysWake()
	gren:SetThrower(self.Owner)
	gren:GetPhysicsObject():SetMass(0.75)
	gren:GetPhysicsObject():EnableDrag(false)
	gren:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector():GetNormalized() * 2000)
	gren:SetRadius(self.Primary.Radius or 256)
	gren:SetDmg(self.Primary.Damage or 15)
	gren:SetScale(self.Primary.Scale or 19)
	gren:SetDetonateExact(CurTime() + 3)
end

function SWEP:SecondaryAttack()
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	local tr = self.Owner:GetEyeTrace()
	
	if self.Weapon:Clip1() <= 0 then
		self:DryFire(self.SetNextPrimaryFire)
		return false
	end
	
	timer.Create(self.Owner:UniqueID() .. "_nades", 0.20, self.Weapon:Clip1(), function()
		if !IsValid(self.Owner) or !IsValid(self) then return end
		if self.Weapon:Clip1() <= 0 then return end
		
		self:TakePrimaryAmmo(1)
		self:EmitSound(self.Primary.Sound)
		
		if (!SERVER) then return end
		
		local gren = ents.Create(self.Projectile)
		gren:SetPos(self.Owner:EyePos() + (self.Owner:GetAimVector() * 125) + Vector(0, 0, 10))
		gren:SetAngles(self.Owner:EyeAngles())
		gren:Spawn()
		gren:PhysWake()
		gren:SetThrower(self.Owner)
		gren:GetPhysicsObject():SetMass(0.75)
		gren:GetPhysicsObject():EnableDrag(false)
		gren:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector():GetNormalized() * 2000)
		gren:SetRadius(self.Secondary.Radius or 256)
		gren:SetDmg(self.Secondary.Damage or 15)
		gren:SetScale(self.Secondary.Scale or 19)
		gren:SetDetonateExact(CurTime() + 3)
	end)
end

function SWEP:PreDrop(death_drop)
	return self.BaseClass.PreDrop(self)
end

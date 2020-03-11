ENT.Type = "anim"
ENT.PrintName = "Jet Pack"
ENT.Author = "Clark (Aide)"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT;

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Owner")
	self:NetworkVar("Entity", 1, "owning_ent")
	self:NetworkVar("Bool", 0, "Active")
	self:NetworkVar("Float", 0, "Fuel")
end

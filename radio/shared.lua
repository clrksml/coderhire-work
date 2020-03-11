ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Radio"
ENT.Author = "Clark (Aide)"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "owning_ent")
end

DarkRP.createEntity("Radio", {
	ent = "radio",
	model = "models/props/cs_office/radio.mdl",
	price = 500,
	max = 1,
	cmd = "buyradio",
})

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Shipment"
ENT.Author = "philxyz"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int",0,"contents")
	self:NetworkVar("Int",1, "count")
	self:NetworkVar("Float", 0, "gunspawn")
	self:NetworkVar("Entity", 0, "owning_ent")
	self:NetworkVar("Entity", 1, "gunModel")
	self:NetworkVar("Bool", 0, "buyable")
	self:NetworkVar("Float", 1, "buyprice")
end

DarkRP.declareChatCommand{
	command = "splitshipment",
	description = "Split the shipment you're looking at.",
	delay = 1.5
}

DarkRP.declareChatCommand{
	command = "makeshipment",
	description = "Create a shipment from a dropped weapon.",
	delay = 1.5
}

DarkRP.declareChatCommand{
	command = "buyable",
	description = "Whether a player can buy directly from a shipment or not.",
	delay = 1.5
}

DarkRP.declareChatCommand{
	command = "setprice",
	description = "Sets the price of each weapon in a buyable shipment.",
	delay = 1.5
}

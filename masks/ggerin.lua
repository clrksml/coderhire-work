ITEM.Name = 'Game Grump Erin'
ITEM.Price = 140
ITEM.Material = 'pointshop/masks/ggerin.png'
ITEM.Scale = 1.25

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

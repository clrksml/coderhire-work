ITEM.Name = 'Kirby'
ITEM.Price = 130
ITEM.Material = 'pointshop/masks/kirby.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

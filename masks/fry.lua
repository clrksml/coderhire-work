ITEM.Name = 'Fry'
ITEM.Price = 230
ITEM.Material = 'pointshop/masks/fry.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

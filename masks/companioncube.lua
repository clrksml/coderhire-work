ITEM.Name = 'Companion Cube'
ITEM.Price = 150
ITEM.Material = 'pointshop/masks/companioncube.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

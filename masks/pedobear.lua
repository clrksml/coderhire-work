ITEM.Name = 'Pedo Bear'
ITEM.Price = 125
ITEM.Material = 'pointshop/masks/pedobear.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

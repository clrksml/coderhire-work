ITEM.Name = 'Daft Punk Thomas'
ITEM.Price = 220
ITEM.Material = 'pointshop/masks/daftpunkthomas.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

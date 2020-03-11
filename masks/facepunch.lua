ITEM.Name = 'Facepunch'
ITEM.Price = 100
ITEM.Material = 'pointshop/masks/facepunch.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

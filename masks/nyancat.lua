ITEM.Name = 'Nyan Cat'
ITEM.Price = 170
ITEM.Material = 'pointshop/masks/nyancat.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

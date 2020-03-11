ITEM.Name = 'Meatwad'
ITEM.Price = 210
ITEM.Material = 'pointshop/masks/meatwad.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

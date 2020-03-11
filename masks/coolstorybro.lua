ITEM.Name = 'Cool Story Bro'
ITEM.Price = 180
ITEM.Material = 'pointshop/masks/coolstorybro.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

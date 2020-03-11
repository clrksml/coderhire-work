ITEM.Name = 'Awesome Face'
ITEM.Price = 140
ITEM.Material = 'pointshop/masks/awesomeface.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

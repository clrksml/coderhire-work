ITEM.Name = 'Pikachu'
ITEM.Price = 200
ITEM.Material = 'pointshop/masks/pikachu.png'
ITEM.Scale = 1.5

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

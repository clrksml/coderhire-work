ITEM.Name = 'Peter Griffin'
ITEM.Price = 145
ITEM.Material = 'pointshop/masks/petergriffin.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

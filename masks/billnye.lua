ITEM.Name = 'Bill Nye'
ITEM.Price = 125
ITEM.Material = 'pointshop/masks/billnye.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

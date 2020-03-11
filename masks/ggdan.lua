ITEM.Name = 'Game Grump Dan'
ITEM.Price = 140
ITEM.Material = 'pointshop/masks/ggdan.png'
ITEM.Scale = 1

function ITEM:OnEquip(ply, modifications)
	ply:PS_AddClientsideMask(self.ID)
end

function ITEM:OnHolster(ply)
	ply:PS_RemoveClientsideMask(self.ID)
end

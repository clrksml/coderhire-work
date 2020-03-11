/*---------------------------------------------------------------------------
Create a shipment from a spawned_weapon
---------------------------------------------------------------------------*/
local function createShipment(ply, args)
	local id = tonumber(args) or -1
	local ent = Entity(id)

	ent = IsValid(ent) and ent or ply:GetEyeTrace().Entity

	if not IsValid(ent) or ent:GetClass() ~= "spawned_weapon" then
		DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", "argument", ""))
		return
	end

	local shipID
	for k,v in pairs(CustomShipments) do
		if v.entity == ent.weaponclass then
			shipID = k
			break
		end
	end

	if not shipID then
		DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("unable", "/makeshipment", ""))
		return
	end

	local crate = ents.Create(CustomShipments[shipID].shipmentClass or "spawned_shipment")
	crate.SID = ply.SID
	crate:SetPos(ent:GetPos())
	crate.nodupe = true
	crate:SetContents(shipID, ent.dt.amount)
	crate:Spawn()
	crate:SetPlayer(ply)
	crate:Setowning_ent(ply)
	crate:Setbuyable(ent:Getbuyable())
	crate:Setbuyprice(ent:Getbuyprice())
	crate.clip1 = ent.clip1
	crate.clip2 = ent.clip2
	crate.ammoadd = ent.ammoadd or 0

	SafeRemoveEntity(ent)

	local phys = crate:GetPhysicsObject()
	phys:Wake()
end
DarkRP.defineChatCommand("makeshipment", createShipment)

/*---------------------------------------------------------------------------
Split a shipment in two
---------------------------------------------------------------------------*/
local function splitShipment(ply, args)
	local id = tonumber(args) or -1
	local ent = Entity(id)

	ent = IsValid(ent) and ent or ply:GetEyeTrace().Entity

	if not IsValid(ent) or ent:GetClass() ~= "spawned_shipment" or ent:Getcount() < 2 then
		DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", "argument", ""))
		return
	end
	
	local count = math.floor(ent:Getcount() / 2)
	ent:Setcount(ent:Getcount() - count)

	local crate = ents.Create("spawned_shipment")
	crate.SID = ply.SID
	crate:SetPos(ent:GetPos())
	crate.nodupe = true
	crate:Setowning_ent(ply)
	crate:SetContents(ent:Getcontents(), count)
	crate:SetPlayer(ply)
	crate:Spawn()
	crate:Setbuyable(ent:Getbuyable())
	crate:Setbuyprice(ent:Getbuyprice())

	local phys = crate:GetPhysicsObject()
	phys:Wake()
	
	crate.clip1 = ent.clip1
	crate.clip2 = ent.clip2
	crate.ammoadd = ent.ammoadd
end
DarkRP.defineChatCommand("splitshipment", splitShipment)

/*---------------------------------------------------------------------------
Make a shipment buyable.
---------------------------------------------------------------------------*/
local function buyableShipment(ply, args)
	local ent = IsValid(ent) and ent or ply:GetEyeTrace().Entity
	
	if !IsValid(ent) or ent:GetClass() ~= "spawned_shipment" then
		DarkRP.notify(ply, 1, 4, "You must be looking at a shipment.")
		return
	end
	
	if ent:Getowning_ent() != ply then
		DarkRP.notify(ply, 1, 4, "You must be looking at a shipment that you own.")
		return
	end
	
	local contents = ent:Getcontents()
	if !table.HasValue(CustomShipments[contents].allowed, ply:Team()) then
		DarkRP.notify(ply, 1, 4, "Your job isn't allowed to sell shipments.")
		return
	end
	
	if ent:Getbuyable() then
		ent:Setbuyable(false)
		
		DarkRP.notify(ply, 1, 4, "Player can no longer buy weapons from this shipment.")
	else
		ent:Setbuyable(true)
		
		DarkRP.notify(ply, 1, 4, "Player can now buy weapons from this shipment.")
		DarkRP.notify(ply, 1, 4, "Type /setprice <amount> to set the price of each weapon.")
	end
end
DarkRP.defineChatCommand("buyable", buyableShipment)

/*---------------------------------------------------------------------------
Make the price for a shipment buyable.
---------------------------------------------------------------------------*/
local function setpriceShipment(ply, args)
	local price = tonumber(args) or 0
	local ent = IsValid(ent) and ent or ply:GetEyeTrace().Entity
	
	if !IsValid(ent) or ent:GetClass() ~= "spawned_shipment" then
		DarkRP.notify(ply, 1, 4, "You must be looking at a shipment.")
		return
	end
	
	if ent:Getowning_ent() != ply then
		DarkRP.notify(ply, 1, 4, "You must be looking at a shipment that you own.")
		return
	end
	
	if price <= 0 then
		DarkRP.notify(ply, 1, 4, "The amount has to be " .. GAMEMODE.Config.currency .. "1 or more.")
		return
	end
	
	local contents = ent:Getcontents()
	
	if price < (CustomShipments[contents].price / CustomShipments[contents].amount) then
		DarkRP.notify(ply, 1, 3, "Your currently selling your shipsment at loss of " .. GAMEMODE.Config.currency .. ((CustomShipments[contents].price / CustomShipments[contents].amount) - price) / CustomShipments[contents].amount .. " per item.")
	end
	
	if !table.HasValue(CustomShipments[contents].allowed, ply:Team()) then
		DarkRP.notify(ply, 1, 4, "Your job isn't allowed to sell shipments.")
		return
	end
	
	if ent:Getbuyable() then
		ent:Setbuyprice(price)
		DarkRP.notify(ply, 1, 4, "Each weapon will now be sold for " .. GAMEMODE.Config.currency .. price .. ".")
	else
		DarkRP.notify(ply, 1, 4, "The shipment has to be buyable first.")
	end
end
DarkRP.defineChatCommand("setprice", setpriceShipment)

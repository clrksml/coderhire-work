AddCSLuaFile()

local _Detective = true // Can detectives buy a jet pack?
local _Traitor = true // Can traitors buy a jet pack?

hook.Add("InitPostEntity", "DarkRP_AddJetPack", function()
	if !string.find(engine.ActiveGamemode():lower(), "darkrp") then return end
	
	DarkRP.createEntity("Jet Pack", {
		ent = "jetpack",
		model = "models/thrusters/jetpack.mdl",
		price = 5000,
		max = 1,
		cmd = "buyjetpack",
	})
	
	if SERVER then
		local function buyJPFuel(ply , args)
			if !IsValid(ply) then return end
			
			local found = false
			for _, ent in pairs(ents.FindByClass("jetpack")) do
				if IsValid(ent) and ent:GetOwner() == ply then
					found = ent
				end
			end
			
			if !found then
				DarkRP.notify(ply, 1, 4, "You must own a jet pack to be able to buy fuel.")
				
				return
			else
				if ply:canAfford(500) then
					if found:GetFuel() < 500 then
						found:SetFuel(500)
						ply:addMoney(-500)
						DarkRP.notify(ply, 1, 4, "Your jet pack has been refuelled.")
					end
				else
					DarkRP.notify(ply, 1, 4, "You don't have enough money for the fuel.")
					
					return
				end
			end
		end
		DarkRP.defineChatCommand("buyjpfuel", buyJPFuel)
	end
end)

if SERVER then
	resource.AddSingleFile("materials/VGUI/ttt/icon_jetpack.vtf")
	resource.AddSingleFile("materials/VGUI/ttt/icon_jetpack.vmt")
	
	hook.Add("DoPlayerDeath", "RemoveJetPack", function( ply )
		for k, v in pairs(ents.FindByClass("jetpack")) do
			if IsValid(v) and v:GetOwner() == ply then
				v:SetActive(false)
				v:Remove()
			end
		end
	end)
end

hook.Add("InitPostEntity", "TTT_AddJetpack", function()
	if !string.find(engine.ActiveGamemode():lower(), "terror") then return end
	
	EQUIP_JETPACK = 8
	
	local jetPack = {  
		id			= EQUIP_JETPACK,
		loadout		= false,
		type		= "item_passive",
		material	= "VGUI/ttt/icon_jetpack",
		name		= "Jet Pack",
		desc		= "Manipulate movement with this simple device.\nJUMP key to 'move'.\nJUMP + USE key to 'hover'."
	}
	
	if _Detective then
		table.insert(EquipmentItems[ROLE_DETECTIVE], jetPack)
	end
	
	if _Traitor then
		table.insert(EquipmentItems[ROLE_TRAITOR], jetPack)
	end
end)

hook.Add("TTTOrderedEquipment", "BoughtJetPack", function(ply, equipment, is_item)
	if !string.find(engine.ActiveGamemode():lower(), "terror") then return end
	
	if IsValid(ply) and equipment == EQUIP_JETPACK then
		local jetpack = ents.Create("jetpack")
		jetpack:Spawn()
		jetpack:SetOwner(ply)
	end
end)

if SERVER then
	hook.Add("TTTPrepareRound", "RemoveJetPacks", function( ply )
		if !string.find(engine.ActiveGamemode():lower(), "terror") then return end
		
		for k, v in pairs(ents.FindByClass("jetpack")) do
			if IsValid(v) and v:GetOwner() == ply then
				v:SetActive(false)
				v:Remove()
			end
		end
	end)
end

if CLIENT then
	hook.Add("HUDPaint", "DrawFuel", function()
		for _, ent in pairs(ents.FindByClass("jetpack")) do
			if IsValid(ent) and ent:GetOwner() == LocalPlayer() then
				ent:SetNoDraw(true)
				
				draw.RoundedBox(6, ScrW() - 151, 0, 150, 20, Color(0, 0, 0, 180))
				draw.RoundedBox(6, ScrW() - 151, 0, math.Clamp((ent:GetFuel() / 3.3), 1, 150), 20, Color(50, 205, 50))
				draw.SimpleText("Fuel", "Trebuchet18", ScrW() - 148, 0, Color(255, 255, 255), 0, 0)
			end
		end
	end)
end

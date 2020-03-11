if CATEGORY then
	CATEGORY.Name = 'Masks'
	CATEGORY.Icon = 'eye'
	CATEGORY.AllowedEquipped = 1
	CATEGORY.AllowedUserGroups = {} // Reference this -> http://pointshop.burt0n.net/categories/properties#allowed-user-groups
end

local UseRender = true // Increasing performance but disabled 3rd person mask viewing on self.

if SERVER then
	PS.ClientsideMasks = {}
	
	util.AddNetworkString('PS_SendClientsideMasks')
	util.AddNetworkString('PS_AddClientsideMask')
	util.AddNetworkString('PS_RemoveClientsideMask')
	
	local Player = FindMetaTable('Player')
	
	hook.Add("Initialize", "PS_Initialize.AddFiles", function()
		for k, v in SortedPairs(PS.Items) do
			if v.Category == "Masks" then 
				resource.AddFile('materials/' .. v.Material)
			end
		end
	end)
	
	hook.Add("PlayerInitialSpawn", "PS_PlayerInitialSpawn.SendMasks", function( ply )
		timer.Simple(1, function()
			if !IsValid(ply) then return end
			
			ply:PS_SendClientsideMasks()
		end)
	end)
	
	function Player:PS_SendClientsideMasks()
		net.Start('PS_SendClientsideMasks')
			net.WriteTable(PS.ClientsideMasks)
		net.Send(self)
	end
	
	function Player:PS_AddClientsideMask(item_id)
		if not PS.Items[item_id] then return false end
		if not self:PS_HasItem(item_id) then return false end
		
		net.Start('PS_AddClientsideMask')
			net.WriteEntity(self)
			net.WriteString(item_id)
		net.Broadcast()
		
		if not PS.ClientsideMasks[self] then PS.ClientsideMasks[self] = {} end
		
		PS.ClientsideMasks[self][item_id] = item_id
	end
	
	function Player:PS_RemoveClientsideMask(item_id)
		if not PS.Items[item_id] then return false end
		if not self:PS_HasItem(item_id) then return false end
		if not PS.ClientsideMasks[self] or not PS.ClientsideMasks[self][item_id] then return false end
		
		net.Start('PS_RemoveClientsideMask')
			net.WriteEntity(self)
			net.WriteString(item_id)
		net.Broadcast()
		
		PS.ClientsideMasks[self][item_id] = nil
	end
end

if CLIENT then
	PS.ClientsideMasks = {}
	
	local invalidplayeritems = {}
	local Player = FindMetaTable('Player')
	local DrawMasks = true
	
	hook.Add("InitPostEntity", "PS_InitPostEntity.SetBools", function()
		if UseRender != LocalPlayer():GetPData("userender", UseRender) then UseRender = !UseRender end
		if DrawMask != LocalPlayer():GetPData("drawmask", DrawMask) then DrawMask = !DrawMask end
		
		MsgN("PointShop Masks - You can toggle(on/off) drawing masks by using 'ps_drawmaks' in console.")
		MsgN("PointShop Masks - You can toggle(on/off) using render library or cam library by using 'ps_userender' in console")
	end)
	
	function Player:PS_AddClientsideMask(item_id)
		if not PS.Items[item_id] then return false end
		
		local ITEM = PS.Items[item_id]
		
		if not PS.ClientsideMasks[self] then PS.ClientsideMasks[self] = {} end
		PS.ClientsideMasks[self][item_id] = ITEM
	end
	
	function Player:PS_RemoveClientsideMask(item_id)
		if not PS.Items[item_id] then return false end
		if not PS.ClientsideMasks[self] then return false end
		if not PS.ClientsideMasks[self][item_id] then return false end
		
		PS.ClientsideMasks[self][item_id] = nil
	end
	
	net.Receive('PS_AddClientsideMask', function(length)
		local ply = net.ReadEntity()
		local item_id = net.ReadString()
		
		if not IsValid(ply) then
			if not invalidplayeritems[ply] then
				invalidplayeritems[ply] = {}
			end
			
			table.insert(invalidplayeritems[ply], item_id)
			return
		end
		
		ply:PS_AddClientsideMask(item_id)
	end)
	
	net.Receive('PS_RemoveClientsideMask', function(length)
		local ply = net.ReadEntity()
		local item_id = net.ReadString()
		
		if not ply or not IsValid(ply) or not ply:IsPlayer() then return end
		
		ply:PS_RemoveClientsideMask(item_id)
	end)
	
	net.Receive('PS_SendClientsideMasks', function(length)
		local itms = net.ReadTable()
		
		for ply, items in pairs(itms) do
			if not IsValid(ply) then
				invalidplayeritems[ply] = items
				continue
			end
				
			for _, item_id in pairs(items) do
				if PS.Items[item_id] then
					ply:PS_AddClientsideMask(item_id)
				end
			end
		end
	end)
	
	concommand.Add("ps_drawmasks", function( ply, cmd, args )
		DrawMask = !DrawMask
		ply:SetPData("drawmask", DrawMask)
	end)
	
	concommand.Add("ps_userender", function( ply, cmd, args )
		UseRender = !UseRender
		ply:SetPData("userender", UseRender)
	end)
	
	hook.Add('PostPlayerDraw', 'PS_PostPlayerDraw.DrawMask', function(ply)
		if not ply:Alive() then return end
		if not PS.ClientsideMasks[ply] then return end
		if !DrawMask then return end
		
		for mask, item in pairs(PS.ClientsideMasks[ply]) do
			if not PS.Items[mask] then PS.ClientsideMask[ply][mask] = nil continue end
			
			local pos = 105
			local ang = 1212
			local attach_id = ply:LookupAttachment("eyes")
			
			if not attach_id then return end
			
			local attach = ply:GetAttachment(attach_id)
			
			if not attach then return end
			
			pos = attach.Pos
			ang = attach.Ang
			
			if UseRender then
				render.SetMaterial(Material(item.Material, "noclamp smooth"))
				render.DrawQuadEasy(pos + (ply:GetForward() * 2.5) + ((ply:GetUp() * item.Scale) * 0.5), ply:GetAimVector(), 10 * item.Scale, 10 * item.Scale, Color(255, 255, 255), 180)
			else
				ang:RotateAroundAxis(ang:Forward(), 90)
				ang:RotateAroundAxis(ang:Right(), -90)
				
				cam.Start3D2D(pos - (ang:Forward() * (5 * item.Scale)) + (ang:Right() * (-5 * item.Scale)) + (ang:Up() * 2.5), ang, item.Scale)
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(Material(item.Material, "noclamp smooth"))
					surface.DrawTexturedRect(0, 0, 10, 10)
				cam.End3D2D()
			end
		end
	end)
end
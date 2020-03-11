require('mysqloo')

local HOST = "127.0.0.1"
local USER = "root"
local PASS = ""
local NAME = "ulx"
local PORT = 3306

local ucl = ULib.ucl

local ENABLE_BANS = true // Whether you want global bans to be enabled (true). Set false if you want to use ULX-GLobal-Bans addon or ULX-SourceBans.
local ENABLE_BACKUP = true // Whether you want to still store bans, groups, and users in text files incase of mysql connection failure.
local REFRESH_TIME = 180 // The amount of time(in seconds) you want the server to refresh users and bans.

gameevent.Listen("player_connect")

function ULib.Connect()
	ULib.MySQL = mysqloo.connect(HOST, USER, PASS, NAME, PORT)
	ULib.MySQL.onConnected = function()
		ULib.MySQLConnected = true
		
		ULib.ucl.getGroups()
		ULib.ucl.getUsers()
		ULib.getBans()
	end
	ULib.MySQL.onConnectionFailed = function(db, err)
		ULib.MySQLConnected = false
		print("Failed to connect to database -> " .. err)
	end
	ULib.MySQL:connect()
end
ULib.Connect()

function ULib.MySQL:DoQuery(query, func)
	if string.GetChar(query, query:len()) != ";" then query = query .. ";" end
	
	file.Append("query.txt", query .. "\n")
	
	local query1 = ULib.MySQL:query(query)
	query1.onAborted = function( q )
		print("Query Aborted:", q)
	end
	query1.onError = function( q, e, s )
		print("Query Failure:", e)
	end
	if func then
		query1.onSuccess = function(q) func(q:getData()) end
	end
	query1:start()
end

function ULib.ucl.getGroups()
	ULib.ucl.groups = {}
	
	ULib.MySQL:DoQuery("SELECT * FROM `groups`", function( data )
		for k, v in pairs(data) do
			if v['can_target'] == "" or v['can_target'] == " " then
				v['can_target'] = nil
			end
			
			if v['inherit_from'] == "" or v['inherit_from'] == " " then
				v['inherit_from'] = nil
			end
			
			ULib.ucl.groups[v['name']] = { allow = util.JSONToTable(v['allow']) or {}, can_target = v['can_target'] or nil, inherit_from = v['inherit_from'] or nil }
		end
	end)
end

function ULib.ucl.getUsers()
	ULib.ucl.users = {}
	
	ULib.MySQL:DoQuery("SELECT * FROM `users`", function( data )
		for k, v in pairs(data) do
			ULib.ucl.users[v['steamid']] = { allow = util.JSONToTable(v['allow']) or {}, name = v['name'] or nil, deny = util.JSONToTable(v['deny']) or {}, group = v['group'] or "user" }
		end
	end)
end

function ULib.getBans()
	if !ENABLE_BANS then return end
	ULib.bans = {}
	
	ULib.MySQL:DoQuery("SELECT * FROM `bans`", function( data )
		for k, v in pairs(data) do
			ULib.bans[v['steamid']] = { reason = v['reason'], admin = v['admin'], unban = tonumber(v['unban']), time = tonumber(v['time']), name = v['name'] }
			
			if v['modified_time'] then
				ULib.bans[v['steamid']].modified_time = v['modified_time']
			end
			
			if v['modified_admin'] then
				ULib.bans[v['steamid']].modified_admin = v['modified_admin']
			end
		end
	end)
end

function ULib.refreshGroups()
	ULib.MySQL:DoQuery("SELECT * FROM `groups`", function( data )
		for k, v in pairs(data) do
			if !ULib.ucl.groups[v['name']] then
				ULib.ucl.groups[v['name']] = { allow = util.JSONToTable(v['allow']) or {}, can_target = v['can_target'] or nil, inherit_from = v['inherit_from'] or nil }
			else
				ULib.ucl.groups[v['name']].allow = util.JSONToTable(v['allow']) or {}
				ULib.ucl.groups[v['name']].inherit_from = v['inherit_from'] or nil
				ULib.ucl.groups[v['name']].can_target = v['can_target'] or nil
			end
			
			if k and k == #data then
				hook.Call( ULib.HOOK_UCLCHANGED )
			end
		end
	end)
end

function ULib.refreshUsers()
	ULib.MySQL:DoQuery("SELECT * FROM `users`", function( data )
		for k, v in pairs(data) do
			if !ULib.ucl.users[v['steamid']] then
				ULib.ucl.users[v['steamid']] = { allow = util.JSONToTable(v['allow']) or {}, name = v['name'] or "", deny = util.JSONToTable(v['deny']) or {}, group = v['group'] or "user" }
			else
				if v['allow'] then
					ULib.ucl.users[v['steamid']].allow = util.JSONToTable(v['allow'])
				end
				
				if v['deny'] then
					ULib.ucl.users[v['steamid']].deny = util.JSONToTable(v['deny'])
				end
				
				if v['group'] then
					ULib.ucl.users[v['steamid']].group = v['group']
				end
			end
			
			if k and k == #data then
				xgui.updateData( {}, "users", ULib.ucl.users)
			end
		end
	end)
end

function ULib.refreshBans()
	if !ENABLE_BANS then return end
	
	ULib.MySQL:DoQuery("SELECT * FROM `bans`", function( data )
		for k, v in pairs(data) do
			if tonumber(v['unban']) > os.time() or tonumber(v['unban']) == 0 then
				if !ULib.bans[v['steamid']] then
					ULib.bans[v['steamid']] = { reason = v['reason'], admin = v['admin'], unban = tonumber(v['unban']), time = tonumber(v['time']), name = v['name'] }
					
					local temp = {}
					temp[v['steamid']] = ULib.bans[v['steamid']]
					xgui.addData({}, "bans", temp)
				else
					ULib.bans[v['steamid']] = { reason = v['reason'], admin = v['admin'], unban = tonumber(v['unban']), time = tonumber(v['time']), name = v['name'] }
					
					if v['modified_time'] then
						ULib.bans[v['steamid']].modified_time = v['modified_time']
					end
					
					if v['modified_admin'] then
						ULib.bans[v['steamid']].modified_admin = tonumber(v['modified_admin'])
					end
				end
			else
				ULib.unban(v['steamid'])
			end
		end
	end)
end

local _addban = ULib.addBan
function ULib.addBan( steamid, time, reason, name, admin )
	if !ENABLE_BANS then return _addban( steamid, time, reason, name, admin ) end
	
	local strTime = time ~= 0 and string.format( "for %s minute(s)", time ) or "permanently"
	local showReason = string.format( "Banned %s: %s", strTime, reason )
	
	local players = player.GetAll()
	for i=1, #players do
		if players[ i ]:SteamID() == steamid then
			ULib.kick( players[ i ], showReason, admin )
		end
	end
	
	game.ConsoleCommand( string.format( "kickid %s %s\n", steamid, showReason or "" ) )
	
	local admin_name
	if admin then
		admin_name = "(Console)"
		if admin:IsValid() then
			admin_name = string.format( "%s(%s)", admin:Name(), admin:SteamID() )
		end
	end
	
	local t = {}
	if ULib.bans[ steamid ] then
		t = ULib.bans[ steamid ]
		t.modified_admin = admin_name
		t.modified_time = os.time()
	else
		t.admin = admin_name
	end
	t.time = t.time or os.time()
	if time > 0 then
		t.unban = ( ( time * 60 ) + os.time() )
	else
		t.unban = 0
	end
	if reason then
		t.reason = reason
	end
	if name then
		t.name = name
	end
	
	ULib.bans[ steamid ] = t
	
	local banfound = false
	
	ULib.MySQL:DoQuery("SELECT * FROM `bans` WHERE `steamid`='" .. steamid .. "'", function( data )
		data = data[1]
		
		if data and data['steamid'] then
			ULib.MySQL:DoQuery("UPDATE `bans` SET `reason`='" .. ULib.MySQL:escape(t.reason) .. "', `admin`='" .. ULib.MySQL:escape(t.admin) .. "' WHERE `steamid`='" .. steamid .. "'")
			
			banfound = true
		end
	end)
	
	if !banfound then
		ULib.MySQL:DoQuery("INSERT INTO `bans` (`steamid`, `reason`, `admin`, `unban`, `time`, `name`) VALUES('" .. ULib.MySQL:escape(steamid) .. "', '" .. ULib.MySQL:escape(t.reason or "") .. "', '" .. ULib.MySQL:escape(t.admin or "Console") .. "', '" .. t.unban .. "', '" .. t.time .. "', '" .. ULib.MySQL:escape(t.name or "SteamID Ban") .. "')")
	end
	
	ULib.MySQL:DoQuery("SELECT * FROM `bans`", function( data )
		for k, v in pairs(data) do
			if tonumber(v['unban']) > os.time() or tonumber(v['unban']) == 0 then
				ULib.bans[v['steamid']] = { reason = v['reason'], admin = v['admin'], unban = tonumber(v['unban']), time = tonumber(v['time']), name = v['name'] }
			else
				ULib.unban(v['steamid'])
			end
		end
	end)
end

local _unban = ULib.unban
function ULib.unban( steamid )
	if !ENABLE_BANS then return _unban(steamid) end
	
	ULib.MySQL:DoQuery("SELECT `steamid` FROM `bans` WHERE `steamid`='" .. steamid .. "'", function( data )
		data = data[1]
		
		if data and data['steamid'] then
			ULib.MySQL:DoQuery("DELETE FROM `bans` WHERE `steamid`='" .. steamid .. "'")
		end
	end)
	
	ULib.bans[ steamid ] = nil
	
	xgui.removeData( {}, "bans", { steamid } )
	
	if ENABLE_BACKUP then
		ULib.fileWrite( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) )
	end
end

function ULib.ucl.addGroup( name, allows, inherit_from )
	ULib.checkArg( 1, "ULib.ULib.ucl.addGroup", "string", name )
	ULib.checkArg( 2, "ULib.ULib.ucl.addGroup", {"nil","table"}, allows )
	ULib.checkArg( 3, "ULib.ULib.ucl.addGroup", {"nil","string"}, inherit_from )
	allows = allows or {}
	inherit_from = inherit_from or "user"
	
	if ULib.ucl.groups[ name ] then return error( "Group already exists, cannot add again (" .. name .. ")", 2 ) end
	if inherit_from then
		if inherit_from == name then return error( "Group cannot inherit from itself", 2 ) end
		if not ULib.ucl.groups[ inherit_from ] then return error( "Invalid group for inheritance (" .. tostring( inherit_from ) .. ")", 2 ) end
	end
	
	for k, v in ipairs( allows ) do allows[ k ] = v:lower() end
	
	ULib.ucl.groups[ name ] = { allow=allows, inherit_from=inherit_from }
	
	local query = "`name`"
	local query2 = "'" .. ULib.MySQL:escape(name) .. "'"
	
	query = query .. ", `allow`"
	query2 = query2 .. ", '" .. ULib.MySQL:escape(util.TableToJSON(allows)) .. "'"
	
	query = query .. ", `inherit_from`"
	query2 = query2 .. ", '" .. ULib.MySQL:escape(inherit_from) .. "'"
	
	ULib.MySQL:DoQuery("INSERT INTO `groups` (" .. query .. ") VALUES(" .. query2 .. ")")
	
	ULib.ucl.saveGroups()
	
	hook.Call( ULib.HOOK_UCLCHANGED )
end

function ucl.groupAllow( name, access, revoke )
	ULib.checkArg( 1, "ULib.ucl.groupAllow", "string", name )
	ULib.checkArg( 2, "ULib.ucl.groupAllow", {"string","table"}, access )
	ULib.checkArg( 3, "ULib.ucl.groupAllow", {"nil","boolean"}, revoke )
	
	if type( access ) == "string" then access = { access } end
	if not ucl.groups[ name ] then return error( "Group does not exist for changing access (" .. name .. ")", 2 ) end
	
	local allow = ucl.groups[ name ].allow
	
	local changed = false
	for k, v in pairs( access ) do
		local access = v:lower()
		local accesstag
		if type( k ) == "string" then
			accesstag = v:lower()
			access = k:lower()
		end
		
		if not revoke and (allow[ access ] ~= accesstag or (not accesstag and not ULib.findInTable( allow, access ))) then
			changed = true
			if not accesstag then
				table.insert( allow, access )
				allow[ access ] = nil -- Ensure no access tag
			else
				allow[ access ] = accesstag
				if ULib.findInTable( allow, access ) then -- Ensure removal of non-access tag version
					table.remove( allow, ULib.findInTable( allow, access ) )
				end
			end
		elseif revoke and (allow[ access ] or ULib.findInTable( allow, access )) then
			changed = true
			
			allow[ access ] = nil -- Remove any accessTags
			if ULib.findInTable( allow, access ) then
				table.remove( allow, ULib.findInTable( allow, access ) )
			end
		end
	end
	
	local group = ULib.ucl.groups[name]
	ULib.MySQL:DoQuery("UPDATE `groups` SET `allow`='"  .. ULib.MySQL:escape(util.TableToJSON(group.allow)) ..  "', `inherit_from`='" .. ULib.MySQL:escape(group.inherit_from or "user") .. "', `can_target`='" .. ULib.MySQL:escape(group.can_target or "") .. "' WHERE `name`='" .. name .. "'")
	
	if changed then
		for id, userInfo in pairs( ucl.authed ) do
			local ply = ULib.getPlyByID( id )
			if ply and ply:CheckGroup( name ) then
				ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Inform the masses
			end
		end
		
		ucl.saveGroups()
		
		hook.Call( ULib.HOOK_UCLCHANGED )
	end
	
	return changed
end

function ULib.ucl.renameGroup( orig, new )
	ULib.checkArg( 1, "ULib.ULib.ucl.renameGroup", "string", orig )
	ULib.checkArg( 2, "ULib.ULib.ucl.renameGroup", "string", new )
	
	if orig == ULib.ACCESS_ALL then return error( "This group (" .. orig .. ") cannot be renamed!", 2 ) end
	if not ULib.ucl.groups[ orig ] then return error( "Group does not exist for renaming (" .. orig .. ")", 2 ) end
	if ULib.ucl.groups[ new ] then return error( "Group already exists, cannot rename (" .. new .. ")", 2 ) end
	
	for id, userInfo in pairs( ULib.ucl.users ) do
		if userInfo.group == orig then
			userInfo.group = new
		end
	end
	
	for id, userInfo in pairs( ULib.ucl.authed ) do
		local ply = ULib.getPlyByID( id )
		if ply and ply:CheckGroup( orig ) then
			if ply:GetUserGroup() == orig then
				ULib.queueFunctionCall( ply.SetUserGroup, ply, new ) -- Queued so group will be removed
			else
				ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Inform the masses
			end
		end
	end
	
	ULib.ucl.groups[ new ] = ULib.ucl.groups[ orig ] -- Copy!
	ULib.ucl.groups[ orig ] = nil
	
	ULib.MySQL:DoQuery("DELETE FROM `groups` WHERE `name`='" .. orig .. "'")
	
	local query = "`name`"
	local query2 = "'" .. ULib.MySQL:escape(new) .. "'"
	
	if ULib.ucl.groups[ new ].allow then
		query = query .. ", `allow`"
		query2 = query2 .. ", '" .. ULib.MySQL:escape(util.TableToJSON(ULib.ucl.groups[ new ].allow)) .. "'"
	end
	
	if ULib.ucl.groups[ new ].can_target then
		query = query .. ", `can_target`"
		query2 = query2 .. ", '" .. ULib.MySQL:escape(ULib.ucl.groups[ new ].can_target) .. "'"
	end
	
	if ULib.ucl.groups[ new ].inherit_from then
		query = query .. ", `inherit_from`"
		query2 = query2 .. ", '" .. ULib.MySQL:escape(ULib.ucl.groups[ new ].inherit_from) .. "'"
	end
	
	ULib.MySQL:DoQuery("INSERT INTO `groups` (" .. query .. ") VALUES(" .. query2 .. ")")
	
	for _, groupInfo in pairs( ULib.ucl.groups ) do
		if groupInfo.inherit_from == orig then
			groupInfo.inherit_from = new
		end
	end
	
	ULib.ucl.saveUsers()
	ULib.ucl.saveGroups()
	
	hook.Call( ULib.HOOK_UCLCHANGED )
end

function ULib.ucl.removeGroup( name )
	ULib.checkArg( 1, "ULib.ULib.ucl.removeGroup", "string", name )
	
	if name == ULib.ACCESS_ALL then return error( "This group (" .. name .. ") cannot be removed!", 2 ) end
	if not ULib.ucl.groups[ name ] then return error( "Group does not exist for removing (" .. name .. ")", 2 ) end
	
	local inherits_from = ULib.ucl.groupInheritsFrom( name )
	if inherits_from == ULib.ACCESS_ALL then inherits_from = nil end -- Easier
	
	for id, userInfo in pairs( ULib.ucl.users ) do
		if userInfo.group == name then
			userInfo.group = inherits_from
			ULib.MySQL:DoQuery("DELETE FROM `users` WHERE `steamid`='" .. id .. "'")
		end
	end
	
	for id, userInfo in pairs( ULib.ucl.authed ) do
		local ply = ULib.getPlyByID( id )
		if ply and ply:CheckGroup( name ) then
			if ply:GetUserGroup() == name then
				ULib.queueFunctionCall( ply.SetUserGroup, ply, inherits_from or ULib.ACCESS_ALL ) -- Queued so group will be removed
			else
				ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Inform the masses
			end
		end
	end
	
	ULib.MySQL:DoQuery("DELETE FROM `groups` WHERE `name`='" .. name .. "'")
	
	ULib.ucl.groups[ name ] = nil
	for _, groupInfo in pairs( ULib.ucl.groups ) do
		if groupInfo.inherit_from == name then
			groupInfo.inherit_from = inherits_from
		end
	end
	
	ULib.ucl.saveUsers()
	ULib.ucl.saveGroups()
	
	hook.Call( ULib.HOOK_UCLCHANGED )
end

function ULib.ucl.addUser( id, allows, denies, group )
	ULib.checkArg( 1, "ULib.ULib.ucl.addUser", "string", id )
	ULib.checkArg( 2, "ULib.ULib.ucl.addUser", {"nil","table"}, allows )
	ULib.checkArg( 3, "ULib.ULib.ucl.addUser", {"nil","table"}, denies )
	ULib.checkArg( 4, "ULib.ULib.ucl.addUser", {"nil","string"}, group )

	id = id:upper() -- In case of steamid, needs to be upper case
	allows = allows or {}
	denies = denies or {}
	if allows == ULib.DEFAULT_GRANT_ACCESS.allow then allows = table.Copy( allows ) end -- Otherwise we'd be changing all guest access
	if denies == ULib.DEFAULT_GRANT_ACCESS.deny then denies = table.Copy( denies ) end -- Otherwise we'd be changing all guest access
	if group and not ULib.ucl.groups[ group ] then return error( "Group does not exist for adding user to (" .. group .. ")", 2 ) end

	-- Lower case'ify
	for k, v in ipairs( allows ) do allows[ k ] = v:lower() end
	for k, v in ipairs( denies ) do denies[ k ] = v:lower() end

	local name
	if ULib.ucl.users[ id ] and ULib.ucl.users[ id ].name then name = ULib.ucl.users[ id ].name end -- Preserve name
	ULib.ucl.users[ id ] = { allow=allows, deny=denies, group=group, name=name }
	
	ULib.MySQL:DoQuery("INSERT INTO `users` (`steamid`, `deny`, `allow`, `name`, `group`) VALUES('" .. ULib.MySQL:escape(id) .. "', '" .. ULib.MySQL:escape(util.TableToJSON(denies)) .. "', '" .. ULib.MySQL:escape(util.TableToJSON(allows)) .. "', '" .. ULib.MySQL:escape(name or "") .. "', '" .. ULib.MySQL:escape(group) .. "')")
	
	ULib.ucl.saveUsers()
	
	local ply = ULib.getPlyByID( id )
	if ply then
		ULib.ucl.probe( ply )
	else -- Otherwise this gets called twice
		hook.Call( ULib.HOOK_UCLCHANGED )
	end
end

function ULib.ucl.removeUser( id )
	ULib.checkArg( 1, "ULib.ULib.ucl.addUser", "string", id )
	id = id:upper() -- In case of steamid, needs to be upper case
	
	local userInfo = ULib.ucl.users[ id ] or ULib.ucl.authed[ id ] -- Check both tables
	if not userInfo then return error( "User id does not exist for removing (" .. id .. ")", 2 ) end
	
	local changed = false
	
	if ULib.ucl.authed[ id ] and not ULib.ucl.users[ id ] then -- Different ids between offline and authed
		local ply = ULib.getPlyByID( id )
		if not ply then return error( "SANITY CHECK FAILED!" ) end -- Should never be invalid
		
		local ip = ULib.splitPort( ply:IPAddress() )
		local checkIndexes = { ply:UniqueID(), ip, ply:SteamID() }
		
		for _, index in ipairs( checkIndexes ) do
			if ULib.ucl.users[ index ] then
				changed = true
				ULib.ucl.users[ index ] = nil
				break -- Only match the first one
			end
		end
		
		ULib.MySQL:DoQuery("DELETE FROM `users` WHERE `steamid`='" .. ply:SteamID() .. "'")
	else
		changed = true
		ULib.ucl.users[ id ] = nil
		
		ULib.MySQL:DoQuery("DELETE FROM `users` WHERE `steamid`='" .. id .. "'")
	end
	
	ULib.ucl.saveUsers()
	
	local ply = ULib.getPlyByID( id )
	if ply then
		ply:SetUserGroup( ULib.ACCESS_ALL, true )
		ULib.ucl.probe( ply ) -- Reprobe
	else -- Otherwise this is called twice
		hook.Call( ULib.HOOK_UCLCHANGED )
	end
end

function ULib.ucl.userAllow( id, access, revoke, deny )
	ULib.checkArg( 1, "ULib.ULib.ucl.userAllow", "string", id )
	ULib.checkArg( 2, "ULib.ULib.ucl.userAllow", {"string","table"}, access )
	ULib.checkArg( 3, "ULib.ULib.ucl.userAllow", {"nil","boolean"}, revoke )
	ULib.checkArg( 4, "ULib.ULib.ucl.userAllow", {"nil","boolean"}, deny )
	
	id = id:upper() -- In case of steamid, needs to be upper case
	if type( access ) == "string" then access = { access } end
	
	local uid = id
	if not ULib.ucl.authed[ uid ] then -- Check to see if it's a steamid or IP
		local ply = ULib.getPlyByID( id )
		if ply and ply:IsValid() then
			uid = ply:UniqueID()
		end
	end
	
	local userInfo = ULib.ucl.users[ id ] or ULib.ucl.authed[ uid ] -- Check both tables
	if not userInfo then return error( "User id does not exist for changing access (" .. id .. ")", 2 ) end
	
	if userInfo.guest then
		local allows = {}
		local denies = {}
		if not revoke and not deny then allows = access
		elseif not revoke and deny then denies = access end
		
		ULib.ucl.addUser( id, allows, denies )
		return true -- And we're done
	end
	
	local accessTable = userInfo.allow
	local otherTable = userInfo.deny
	if deny then
		accessTable = userInfo.deny
		otherTable = userInfo.allow
	end
	
	local changed = false
	for k, v in pairs( access ) do
		local access = v:lower()
		local accesstag
		if type( k ) == "string" then
			access = k:lower()
			if not revoke and not deny then -- Not valid to have accessTags unless this is the case
				accesstag = v:lower()
			end
		end
		
		if not revoke and (accessTable[ access ] ~= accesstag or (not accesstag and not ULib.findInTable( accessTable, access ))) then
			changed = true
			if not accesstag then
				table.insert( accessTable, access )
				accessTable[ access ] = nil -- Ensure no access tag
			else
				accessTable[ access ] = accesstag
				if ULib.findInTable( accessTable, access ) then -- Ensure removal of non-access tag version
					table.remove( accessTable, ULib.findInTable( accessTable, access ) )
				end
			end
			
			if deny then
				otherTable[ access ] = nil -- Remove any accessTags
			end
			if ULib.findInTable( otherTable, access ) then
				table.remove( otherTable, ULib.findInTable( otherTable, access ) )
			end
		elseif revoke and (accessTable[ access ] or ULib.findInTable( accessTable, access )) then
			changed = true
			
			if not deny then
				accessTable[ access ] = nil -- Remove any accessTags
			end
			if ULib.findInTable( accessTable, access ) then
				table.remove( accessTable, ULib.findInTable( accessTable, access ) )
			end
		end
	end
	
	local ply = ULib.getPlyByID( id )
	
	if ply then
		local v = ULib.ULib.ucl.users[ply:SteamID()]
		
		ULib.MySQL:DoQuery("UPDATE `users` SET `deny`='" .. ULib.MySQL:escape(util.TableToJSON(v.deny)) .. "', `allow`='"  .. ULib.MySQL:escape(util.TableToJSON(v.allow)) ..  "', `name`='" .. ULib.MySQL:escape(v.name) .. "', `group`='" .. ULib.MySQL:escape(v.group) .. "' WHERE `steamid`='" .. ply:SteamID() .. "'")
	end
	
	if changed then
		if ply then
			ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Inform the masses
		end
		
		hook.Call( ULib.HOOK_UCLCHANGED )
	end
	
	ULib.ucl.saveUsers()
	
	return changed
end

hook.Add("PlayerInitialSpawn", "PlayerBanned", function( ply )
	if ENABLE_BANS then
		for k, v in pairs(ULib.bans) do
			if k == ply:SteamID() then
				if tonumber(v.unban) < os.time() and tonumber(v.unban) != 0 then
					ULib.unban(ply:SteamID())
				end
			end
		end
		
		ULib.MySQL:DoQuery("SELECT * FROM `bans` WHERE `steamid`='" .. ply:SteamID() .. "'", function( data )
			data = data[1]
			
			if data then
				if !data['reason'] then
					data['reason'] = "No reason given"
				end
				
				if !data['admin'] then
					data['admin'] = "Console"
				end
				
				local time = "for " .. string.NiceTime(os.difftime(data['unban'], os.time()))
				
				if data['unban'] == 0 then
					time = "Permanent"
				end
				
				game.ConsoleCommand(string.format("kickid %s %s %s\n", ply:UserID(), "Banned for " .. data['reason'] .. " by " .. data['admin'], time ) )
			end
		end)
	end
end)

hook.Add("player_connect", "DenyAccessPlayerBanned", function( data )
	if ENABLE_BANS then
		for k, v in pairs(ULib.bans) do
			if k == data['networkid'] then
				if tonumber(v.unban) > os.time() or tonumber(v.unban) == 0 then
					if !v.reason then
						v.reason = "No reason given"
					end
					
					if !v.admin then
						v.admin = "Console"
					end
					
					local time = "for " .. string.NiceTime(os.difftime(v.unban, os.time()))
					
					if v.unban == 0 then
						time = "Permanent"
					end
					
					game.ConsoleCommand(string.format("kickid %s %s %s\n", data['userid'], "Banned for " .. v.reason .. " by " .. v.admin, time ) )
				end
			end
		end
	end
end)

function ULib.SyncData( ply, cmd, args )
	if IsValid(ply) then ply:ChatPrint("This should only be run in the servers console.") return end
	
	MsgN("This may take sometime depending on the size of files.")
	MsgN("ULX MySQL Sync started.")
	
	ULib.MySQL:DoQuery("DROP TABLE IF EXISTS `bans`")
	ULib.MySQL:DoQuery("DROP TABLE IF EXISTS `groups`")
	ULib.MySQL:DoQuery("DROP TABLE IF EXISTS `users`")
	
	ULib.MySQL:DoQuery("CREATE TABLE IF NOT EXISTS `bans` (`steamid` varchar(32), `reason` text DEFAULT NULL, `admin` text DEFAULT NULL, `unban` int(11) NOT NULL, `time` int(11) NOT NULL, `name` text DEFAULT NULL, `modified_time` text DEFAULT NULL, `modified_admin` text DEFAULT NULL, PRIMARY KEY (`steamid`));")
	ULib.MySQL:DoQuery("CREATE TABLE IF NOT EXISTS `groups` (`name` text DEFAULT NULL, `allow` longtext DEFAULT NULL, `inherit_from` text DEFAULT NULL, `can_target` text DEFAULT NULL);")
	ULib.MySQL:DoQuery("CREATE TABLE IF NOT EXISTS `users` (`steamid` varchar(32), `deny` text DEFAULT NULL, `allow` text DEFAULT NULL, `name` text DEFAULT NULL,  `group` text DEFAULT NULL, PRIMARY KEY (`steamid`));")
	
	local err, groups, users, bans = "", {}, {}, {}
	
	groups, err = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( ULib.UCL_GROUPS ), "/" ) )
	users, err = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( ULib.UCL_USERS ), "/" ) )
	bans, err = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( ULib.BANS_FILE ), "/" ) )
	
	for k, v in pairs(groups) do
		local query = "`name`"
		local query2 = "'" .. ULib.MySQL:escape(k) .. "'"
		
		if v.allow then
			query = query .. ", `allow`"
			query2 = query2 .. ", '" .. ULib.MySQL:escape(util.TableToJSON(v.allow)) .. "'"
		end
		
		if v.can_target then
			query = query .. ", `can_target`"
			query2 = query2 .. ", '" .. ULib.MySQL:escape(v.can_target) .. "'"
		end
		
		if v.inherit_from then
			query = query .. ", `inherit_from`"
			query2 = query2 .. ", '" .. ULib.MySQL:escape(v.inherit_from) .. "'"
		end
		
		ULib.MySQL:DoQuery("INSERT INTO `groups` (" .. query .. ") VALUES(" .. query2 .. ")")
	end
	
	for k, v in pairs(users) do
		local deny, allow, name, group = "[]", "[]", "", "user"
		
		if v.deny then
			deny = util.TableToJSON(v.deny)
		end
		
		if v.allow then
			allow = util.TableToJSON(v.allow)
		end
		
		if v.name then
			name = v.name
		end
		
		if v.group then
			group = v.group
		end
		
		ULib.MySQL:DoQuery("INSERT INTO `users` (`steamid`, `deny`, `allow`, `name`, `group`) VALUES('" .. ULib.MySQL:escape(k) .. "', '" .. ULib.MySQL:escape(deny) .. "', '" .. ULib.MySQL:escape(allow) .. "', '" .. ULib.MySQL:escape(name) .. "', '" .. ULib.MySQL:escape(group) .. "')")
	end
	
	for k, v in pairs(bans) do
		if !v.reason then
			v.reason = "No reason given."
		end
		
		if !v.admin then
			v.admin = "Console"
		end
		
		if !v.name then
			v.name = k
		end
		
		if !v.time then
			v.time = os.time()
		end
		
		if !v.unban then
			v.unban = 0
		end
		
		if string.find(v.unban, "e+") then
			v.unban = 0
		end
		
		local query = "`steamid`, `reason`, `admin`, `unban`, `time`, `name`"
		local query2 = "'" .. ULib.MySQL:escape(k) .. "', '" .. ULib.MySQL:escape(v.reason) .. "', '" .. ULib.MySQL:escape(v.admin) .. "', '" .. v.unban .. "', '" .. v.time .. "', '" .. ULib.MySQL:escape(v.name) .. "'"
		
		if v.modified_time then
			query = query .. ", `modified_time`"
			query2 = query2 .. ", '" .. v.modified_time .. "'"
		end
		
		if v.modified_admin then
			query = query .. ", `modified_admin`"
			query2 = query2 .. ", '" .. v.modified_admin .. "'"
		end
		
		ULib.MySQL:DoQuery("INSERT INTO `bans` (" .. query .. ") VALUES(" .. query2 .. ")")
	end
	
	MsgN("ULX MySQL Sync completed.\tQuerys: " .. table.Count(bans) + table.Count(groups) + table.Count(users))
	
	timer.Simple(2, function()
		ULib.ucl.getGroups()
		ULib.ucl.getUsers()
		ULib.getBans()
	end)
end
concommand.Add("ulx_mysql_sync", ULib.SyncData)

timer.Create("refreshAll", REFRESH_TIME, 0, function()
	if !ULib.MySQLConnected then MsgC(Color(255, 0, 0), "ULX MySQL isn't connected to the database.\n") return end
	
	ULib.refreshGroups()
	ULib.refreshUsers()
	ULib.refreshBans()
end)

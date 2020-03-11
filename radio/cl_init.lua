include("shared.lua")

function RadioMenu()
	local DFrame1 = vgui.Create('DFrame')
	DFrame1:SetSize(300, 52)
	DFrame1:SetPos(0, 0)
	DFrame1:SetTitle("")
	DFrame1:ShowCloseButton(false)
	DFrame1:SetSizable(false)
	DFrame1:Center()
	DFrame1:MakePopup()
	DFrame1.Paint = function()
		draw.RoundedBox(2, 0, 0, DFrame1:GetWide(), DFrame1:GetTall(), Color(35, 35, 35))
	end
	
	local DButton1 = vgui.Create("DButton", DFrame1)
	DButton1:SetSize(50, 20)
	DButton1:SetPos(DFrame1:GetWide() - 51, 1)
	DButton1:SetText("CLOSE")
	DButton1:SetTextColor(Color(255, 255, 255))
	DButton1:SetFont("Trebuchet18")
	DButton1.DoClick = function()
		DFrame1:Close()
	end
	DButton1.Paint = function()
		draw.RoundedBox(2, 0, 0, DButton1:GetWide(), DButton1:GetTall(), Color(255, 104, 104))
	end
	
	local DButton2 = vgui.Create("DButton", DFrame1)
	DButton2:SetSize(50, 20)
	DButton2:SetPos(DFrame1:GetWide() - 102, 1)
	DButton2:SetText("PAUSE")
	DButton2:SetTextColor(Color(255, 255, 255))
	DButton2:SetFont("Trebuchet18")
	DButton2.DoClick = function()
		net.Start("svPauseStream")
		net.SendToServer()
		
		DFrame1:Close()
	end
	DButton2.Paint = function()
		draw.RoundedBox(2, 0, 0, DButton2:GetWide(), DButton2:GetTall(), Color(255, 104, 104))
	end
	
	local DButton3 = vgui.Create("DButton", DFrame1)
	DButton3:SetSize(50, 20)
	DButton3:SetPos(DFrame1:GetWide() - 153, 1)
	DButton3:SetText("HELP")
	DButton3:SetTextColor(Color(255, 255, 255))
	DButton3:SetFont("Trebuchet18")
	DButton3.DoClick = function()
		LocalPlayer():ChatPrint("Open your console for information on how to use DarkRP Radio")
		
		local str = "\n\nThe radio uses url to play songs currently support formats such as pls and wav/mp3.\nIt also will accept a direct link to shoutcast page.\n\n"
		MsgC(Color(255, 200, 200), str)
		
		DFrame1:Close()
	end
	DButton3.Paint = function()
		draw.RoundedBox(2, 0, 0, DButton3:GetWide(), DButton3:GetTall(), Color(255, 104, 104))
	end
	
	local DLabel1 = vgui.Create('DLabel', DFrame1)
	DLabel1:SetPos(4, 1)
	DLabel1:SetText('Stream URL')
	DLabel1:SetTextColor(Color(255, 255, 255))
	DLabel1:SetFont("Trebuchet24")
	DLabel1:SizeToContents()
	
	local DTextEntry1 = vgui.Create('DTextEntry', DFrame1)
	DTextEntry1:SetSize(272, 20)
	DTextEntry1:SetPos(2, 25)
	DTextEntry1:SetText('')
	DTextEntry1.OnEnter = function() end
	
	local DButton3 = vgui.Create('DButton', DFrame1)
	DButton3:SetSize(20, 20)
	DButton3:SetPos(276, 25)
	DButton3:SetTextColor(Color(255, 255, 255))
	DButton3:SetText('X')
	DButton3.Paint = function()
		draw.RoundedBox(2, 0, 0, DButton3:GetWide(), DButton3:GetTall(), Color(255, 104, 104))
	end
	DButton3.DoClick = function()
		net.Start("svPlayStream")
			net.WriteString(DTextEntry1:GetValue())
		net.SendToServer()
		
		DFrame1:Close()
	end
end
net.Receive("clRadioMenu", RadioMenu)

function ENT.PauseStream()
	local ent = net.ReadEntity()
	
	if IsValid(ent) and ent.Radio:IsValid() then
		if !ent.paused then
			ent.paused = true
			ent.Radio:Pause()
		else
			ent.paused = false
			ent.Radio:Play()
		end
	end
end
net.Receive("clPauseStream", ENT.PauseStream)

function ENT.PlayStream()
	local stream, ent, pl = net.ReadString(), net.ReadEntity(), LocalPlayer()
	
	if IsValid(ent) then
		ent.Stream = stream
		
		sound.PlayURL(stream, "3d mono play loop", function( chan )
			if chan and chan:IsValid() then
				if ent.Radio and ent.Radio:IsValid() then
					ent.Radio:Stop()
				end
				
				ent.Radio = chan
				
				if ent.Radio then
					ent.Radio:Play()
					ent.Radio:SetPos(ent:GetPos())
					ent.Radio:SetVolume(1)
				end
			end
		end)
	end
end
net.Receive("clPlayStream", ENT.PlayStream)

function ENT:OnRemove()
	if self.Radio then
		self.Radio:Stop()
	end
end

function ENT:Think()
	if self.Radio then
		self.Radio:SetPos(self:GetPos())
	end
end

function ENT:Draw()
	self:DrawModel()
	
	local Pos = self:GetPos()
	local Ang = self:GetAngles()
	
	local owner = self:Getowning_ent()
	owner = (IsValid(owner) and owner:Nick()) or DarkRP.getPhrase("unknown")
	
	surface.SetFont("HUDNumber5")
	local text = "Radio"
	local TextWidth = surface.GetTextSize(text)
	
	Ang:RotateAroundAxis(Ang:Forward(), 90)
	local TextAng = Ang
	
	TextAng:RotateAroundAxis(TextAng:Right(), CurTime() * -180)
	
	cam.Start3D2D(Pos + Ang:Right() * -30, TextAng, 0.2)
		draw.WordBox(2, -TextWidth*0.5 + 5, -30, text, "HUDNumber5", Color(140, 0, 0, 100), Color(255,255,255,255))
	cam.End3D2D()
end

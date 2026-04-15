local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local CoreGui=game:GetService("CoreGui")
local HttpService=game:GetService("HttpService")
local LP=Players.LocalPlayer
local WIN_W,TITLE_H,TAB_H,STATUS_H,CONTENT_H=440,32,30,380,380
local WIN_H=TITLE_H+TAB_H+CONTENT_H+STATUS_H-CONTENT_H+CONTENT_H
WIN_H=TITLE_H+TAB_H+CONTENT_H+22
local function Create(class,props,children)
	local i=Instance.new(class)
	for k,v in pairs(props or{})do i[k]=v end
	for _,c in ipairs(children or{})do c.Parent=i end
	return i
end
local function Tween(i,p,t)TweenService:Create(i,TweenInfo.new(t or.15,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p):Play()end
local function MakeDraggable(frame,handle)
	local drag,inp,ds,sp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			drag=true;ds=i.Position;sp=frame.Position
			i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then drag=false end end)
		end
	end)
	handle.InputChanged:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseMovement then inp=i end end)
	UIS.InputChanged:Connect(function(i)
		if drag and i==inp then local d=i.Position-ds;frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)end
	end)
end
local function C3Hex(c)return string.format("#%02X%02X%02X",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5))end
local function HexC3(hex)
	hex=hex:gsub("#","");if #hex~=6 then return nil end
	local r,g,b=tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16)
	return r and g and b and Color3.fromRGB(r,g,b)
end
local T={
	Bg0=Color3.fromRGB(10,10,12),Bg1=Color3.fromRGB(15,15,18),Bg2=Color3.fromRGB(20,20,24),
	Bg3=Color3.fromRGB(28,28,34),Input=Color3.fromRGB(12,12,15),Hover=Color3.fromRGB(32,32,40),
	Accent=Color3.fromRGB(210,100,130),AccentDim=Color3.fromRGB(150,65,90),AccentGlow=Color3.fromRGB(240,130,160),
	Purple=Color3.fromRGB(155,120,210),PurpleDim=Color3.fromRGB(100,75,155),
	TextHi=Color3.fromRGB(238,235,230),TextMid=Color3.fromRGB(140,138,148),TextLo=Color3.fromRGB(55,53,65),
	Border=Color3.fromRGB(30,30,38),BorderHi=Color3.fromRGB(50,48,62),ToggleOff=Color3.fromRGB(32,32,42),
	Green=Color3.fromRGB(52,180,80),Red=Color3.fromRGB(220,70,70),
}
local Library={}
Library.__index=Library
Library.Toggles={}
Library.Options={}
Library._connections={}
Library._cleanups={}
Library._binds={}
Library._depListeners={}
Library._themeRefs={}
getgenv().PunchyLib=Library
local function TR(inst,prop,key)table.insert(Library._themeRefs,{inst,prop,key});return inst end
local function ApplyTheme()
	for _,r in ipairs(Library._themeRefs)do pcall(function()r[1][r[2]]=T[r[3]]end)end
end
local ScreenGui
do
	pcall(function()if CoreGui:FindFirstChild("PunchyLib")then CoreGui.PunchyLib:Destroy()end end)
	pcall(function()if LP.PlayerGui:FindFirstChild("PunchyLib")then LP.PlayerGui.PunchyLib:Destroy()end end)
	ScreenGui=Instance.new("ScreenGui")
	ScreenGui.Name="PunchyLib";ScreenGui.ResetOnSpawn=false
	ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Global;ScreenGui.DisplayOrder=999
	local ok=pcall(function()
		if gethui then ScreenGui.Parent=gethui()
		elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui);ScreenGui.Parent=CoreGui
		else ScreenGui.Parent=CoreGui end
	end)
	if not ok or not ScreenGui.Parent then ScreenGui.Parent=LP:WaitForChild("PlayerGui")end
end
Library._screenGui=ScreenGui
local CPHolder=Create("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=2000,Visible=true,Parent=ScreenGui})
Library._cpHolder=CPHolder
local _openCP=nil
CPHolder.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 and _openCP then
		local mp=UIS:GetMouseLocation()
		local p=_openCP.AbsolutePosition;local sz=_openCP.AbsoluteSize
		if mp.X<p.X or mp.X>p.X+sz.X or mp.Y<p.Y or mp.Y>p.Y+sz.Y then
			_openCP.Visible=false;_openCP=nil
		end
	end
end)
local _nGui,_nStack,_nOrder=nil,nil,0
do
	pcall(function()if CoreGui:FindFirstChild("PunchyNotifs")then CoreGui.PunchyNotifs:Destroy()end end)
	_nGui=Instance.new("ScreenGui");_nGui.Name="PunchyNotifs";_nGui.ResetOnSpawn=false
	_nGui.DisplayOrder=10000;_nGui.ZIndexBehavior=Enum.ZIndexBehavior.Global
	local ok=pcall(function()
		if gethui then _nGui.Parent=gethui()
		elseif syn and syn.protect_gui then syn.protect_gui(_nGui);_nGui.Parent=CoreGui
		else _nGui.Parent=CoreGui end
	end)
	if not ok or not _nGui.Parent then _nGui.Parent=LP:WaitForChild("PlayerGui")end
	Library._notifGui=_nGui
	_nStack=Create("Frame",{Size=UDim2.new(0,248,1,-20),Position=UDim2.new(1,-260,0,10),BackgroundTransparency=1,BorderSizePixel=0,Parent=_nGui},{
		Create("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,VerticalAlignment=Enum.VerticalAlignment.Bottom,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)})
	})
end
function Library:Notify(msg,duration,kind)
	duration=duration or 3;_nOrder=_nOrder+1
	local ac=kind=="error"and T.Red or kind=="success"and T.Green or T.Accent
	local ic=kind=="error"and"✕"or kind=="success"and"✓"or"i"
	local card=Create("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=T.Bg1,BorderSizePixel=0,LayoutOrder=_nOrder,ClipsDescendants=false,Parent=_nStack},{
		Create("UICorner",{CornerRadius=UDim.new(0,6)}),Create("UIStroke",{Color=T.BorderHi,Thickness=1})
	})
	Create("Frame",{Size=UDim2.new(0,3,1,-14),Position=UDim2.new(0,0,0,7),BackgroundColor3=ac,BorderSizePixel=0,Parent=card},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
	Create("TextLabel",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,10,0.5,-8),BackgroundColor3=ac,Text=ic,TextColor3=Color3.new(1,1,1),TextSize=9,Font=Enum.Font.GothamBold,Parent=card},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
	Create("TextLabel",{Size=UDim2.new(1,-38,1,-8),Position=UDim2.new(0,32,0,4),BackgroundTransparency=1,Text=msg,TextColor3=T.TextHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=card})
	local prog=Create("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=ac,BorderSizePixel=0,Parent=card},{Create("UICorner",{CornerRadius=UDim.new(0,1)})})
	card.BackgroundTransparency=0.2;Tween(card,{BackgroundTransparency=0},0.18)
	TweenService:Create(prog,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,2)}):Play()
	task.delay(duration,function()Tween(card,{BackgroundTransparency=1},0.22);task.wait(0.23);pcall(function()card:Destroy()end)end)
end
local KBLFrame=Create("Frame",{
	Name="KeybindList",Size=UDim2.new(0,180,0,0),Position=UDim2.new(0,12,0.5,-50),AnchorPoint=Vector2.new(0,0.5),
	BackgroundColor3=T.Bg0,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,ClipsDescendants=false,Visible=false,Parent=ScreenGui
},{Create("UICorner",{CornerRadius=UDim.new(0,6)}),Create("UIStroke",{Color=T.BorderHi,Thickness=1})})
Create("Frame",{Size=UDim2.new(0,32,0,2),Position=UDim2.new(0,10,0,0),BackgroundColor3=T.Accent,BorderSizePixel=0,ZIndex=3,Parent=KBLFrame},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
local kblHdr=Create("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=T.Bg1,BorderSizePixel=0,Parent=KBLFrame},{
	Create("UICorner",{CornerRadius=UDim.new(0,6)}),
	Create("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),BackgroundColor3=T.Bg1,BorderSizePixel=0}),
	Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=T.Border,BorderSizePixel=0}),
})
Create("Frame",{Size=UDim2.new(0,3,0,12),Position=UDim2.new(0,8,0.5,-6),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=kblHdr},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
Create("TextLabel",{Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,17,0,0),BackgroundTransparency=1,Text="KEYBINDS",TextColor3=T.TextMid,TextSize=8,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=kblHdr})
local kblCount=Create("TextLabel",{Size=UDim2.new(0,16,0,12),Position=UDim2.new(1,-22,0.5,-6),BackgroundColor3=T.Bg3,BorderSizePixel=0,Text="0",TextColor3=T.TextMid,TextSize=8,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,Parent=kblHdr},{
	Create("UICorner",{CornerRadius=UDim.new(1,0)}),Create("UIStroke",{Color=T.Border,Thickness=1})
})
MakeDraggable(KBLFrame,kblHdr)
local kblBody=Create("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,26),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,Parent=KBLFrame},{
	Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)}),
	Create("UIPadding",{PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,4)}),
})
Library._kblFrame=KBLFrame;Library._kblBody=kblBody;Library._kblEntries={}
local function refreshKBL()
	local count=0
	for id,entry in pairs(Library._kblEntries)do
		local b=Library._binds[id]
		if b and b.key and entry and entry.frame and entry.frame.Parent then
			entry.keyLabel.Text=b.key.Name:upper()
			local active=b.state
			entry.stateChip.Text=b.mode=="toggle"and(active and"ON"or"OFF")or(active and"HELD"or"HOLD")
			entry.stateChip.TextColor3=active and T.TextHi or T.TextLo
			entry.stateChip.BackgroundColor3=active and T.AccentDim or T.Bg3
			entry.bar.BackgroundColor3=active and T.Accent or T.TextLo
			entry.nameLabel.TextColor3=active and T.TextHi or T.TextMid
			local s=entry.stateChip:FindFirstChildOfClass("UIStroke")
			if s then s.Color=active and T.Accent or T.Border end
			count=count+1
		end
	end
	kblCount.Text=tostring(count);kblCount.TextColor3=count>0 and T.Accent or T.TextMid
	local show=count>0
	if show~=KBLFrame.Visible then
		if show then
			KBLFrame.Visible=true
		else
			task.delay(0.15,function()
				local c2=0;for _ in pairs(Library._kblEntries)do c2=c2+1 end
				if c2==0 then KBLFrame.Visible=false end
			end)
		end
	end
end
table.insert(Library._connections,UIS.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	for _,b in pairs(Library._binds)do
		if b.key and inp.KeyCode==b.key then
			if b.mode=="toggle"then b.state=not b.state;pcall(b.onDown,b.state);refreshKBL()
			elseif b.mode=="hold"and not b.state then b.state=true;pcall(b.onDown,true);refreshKBL()end
		end
	end
end))
table.insert(Library._connections,UIS.InputEnded:Connect(function(inp)
	for _,b in pairs(Library._binds)do
		if b.key and inp.KeyCode==b.key and b.mode=="hold"and b.state then
			b.state=false;pcall(b.onUp,false);refreshKBL()
		end
	end
end))
function Library:RegisterBind(id,key,mode,onDown,onUp)
	Library._binds[id]={key=key,mode=mode or"toggle",state=false,onDown=onDown or function()end,onUp=onUp or function()end}
end
function Library:SetBind(id,key)if Library._binds[id]then Library._binds[id].key=key end;refreshKBL()end
function Library:RemoveBind(id)
	Library._binds[id]=nil
	if Library._kblEntries[id]then pcall(function()Library._kblEntries[id].frame:Destroy()end);Library._kblEntries[id]=nil end
	refreshKBL()
end
function Library:SetThemeColor(key,color)
	T[key]=color;ApplyTheme()
end
function Library:GetThemeColor(key)return T[key]end
function Library:SaveConfig(name,folder)
	folder=folder or"Punchy";name=name or"default"
	local ok=pcall(function()
		if not isfolder(folder)then makefolder(folder)end
		local data={}
		for k,t in pairs(Library.Toggles)do pcall(function()data["T_"..k]=t.Value end)end
		for k,o in pairs(Library.Options)do
			pcall(function()
				local v=o.Value
				if typeof(v)=="Color3"then data["O_"..k]={_t="c3",r=v.R,g=v.G,b=v.B}
				elseif typeof(v)=="EnumItem"then data["O_"..k]={_t="en",n=v.Name}
				else data["O_"..k]=v end
			end)
		end
		writefile(folder.."/"..name..".json",HttpService:JSONEncode(data))
	end)
	if ok then Library:Notify("Saved: "..name,2,"success")else Library:Notify("Save failed!",2,"error")end
end
function Library:LoadConfig(name,folder)
	folder=folder or"Punchy";name=name or"default"
	local ok,raw=pcall(readfile,folder.."/"..name..".json")
	if not ok or not raw then Library:Notify("No config: "..name,2,"error");return end
	local ok2,data=pcall(HttpService.JSONDecode,HttpService,raw)
	if not ok2 then Library:Notify("Config corrupted!",2,"error");return end
	for k,v in pairs(data)do
		if k:sub(1,2)=="T_"then pcall(function()local t=Library.Toggles[k:sub(3)];if t then t:SetValue(v)end end)
		elseif k:sub(1,2)=="O_"then
			pcall(function()
				local o=Library.Options[k:sub(3)];if not o then return end
				if type(v)=="table"and v._t=="c3"then o:SetValue(Color3.new(v.r,v.g,v.b))
				elseif type(v)=="table"and v._t=="en"then local ok3,ev=pcall(function()return Enum.KeyCode[v.n]end);if ok3 and ev then o:SetValue(ev)end
				else o:SetValue(v)end
			end)
		end
	end
	Library:Notify("Loaded: "..name,2,"success")
end
function Library:DeleteConfig(name,folder)
	folder=folder or"Punchy";name=name or"default"
	local ok=pcall(delfile,folder.."/"..name..".json")
	if ok then Library:Notify("Deleted: "..name,2,"success")else Library:Notify("Delete failed!",2,"error")end
end
function Library:GetProfiles(folder)
	folder=folder or"Punchy";local list={}
	pcall(function()
		if not isfolder(folder)then return end
		for _,f in ipairs(listfiles(folder))do local n=f:match("([^/\\]+)%.json$");if n then table.insert(list,n)end end
	end)
	return list
end
function Library:RegisterCleanup(fn)table.insert(Library._cleanups,fn)end
local function BuildLogo(parent,x,y)
	for i,b in ipairs({{12,12},{8,8},{5,5}})do
		Create("Frame",{Size=UDim2.new(0,3,0,b[1]),Position=UDim2.new(0,x+(i-1)*5,0,y+(12-b[2])),
			BackgroundColor3=i==1 and T.AccentGlow or i==2 and T.Accent or T.AccentDim,BorderSizePixel=0,Parent=parent
		},{Create("UICorner",{CornerRadius=UDim.new(0,1)})})
	end
end
local function MakeColorPicker(k,defaultColor,cb)
	local h,s,v=Color3.toHSV(defaultColor);local cur=defaultColor
	local SV_W,SV_H,HUE_W,PAD=148,110,14,10
	local tW=PAD+SV_W+PAD/2+HUE_W+PAD;local tH=PAD+SV_H+8+22+PAD
	local pf=Create("Frame",{Size=UDim2.new(0,tW,0,tH),BackgroundColor3=T.Bg2,BorderSizePixel=0,Visible=false,ZIndex=3000,Parent=CPHolder},{
		Create("UICorner",{CornerRadius=UDim.new(0,6)}),Create("UIStroke",{Color=T.BorderHi,Thickness=1})
	})
	local svA=Create("Frame",{Size=UDim2.new(0,SV_W,0,SV_H),Position=UDim2.new(0,PAD,0,PAD),BackgroundColor3=Color3.fromHSV(h,1,1),BorderSizePixel=0,ClipsDescendants=true,ZIndex=3001,Parent=pf},{Create("UICorner",{CornerRadius=UDim.new(0,3)})})
	local so=Create("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=3002,Parent=svA})
	Create("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Rotation=0,Parent=so})
	local vo=Create("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=3003,Parent=svA})
	Create("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=vo})
	local svc=Create("Frame",{Size=UDim2.new(0,10,0,10),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(s,0,1-v,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=3004,Parent=svA},{Create("UICorner",{CornerRadius=UDim.new(1,0)}),Create("UIStroke",{Color=Color3.new(0,0,0),Thickness=1.5})})
	local hb=Create("Frame",{Size=UDim2.new(0,HUE_W,0,SV_H),Position=UDim2.new(0,PAD+SV_W+PAD/2,0,PAD),BorderSizePixel=0,ClipsDescendants=true,ZIndex=3001,Parent=pf},{Create("UICorner",{CornerRadius=UDim.new(0,3)})})
	Create("UIGradient",{Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(.167,Color3.fromHSV(.167,1,1)),
		ColorSequenceKeypoint.new(.333,Color3.fromHSV(.333,1,1)),ColorSequenceKeypoint.new(.5,Color3.fromHSV(.5,1,1)),
		ColorSequenceKeypoint.new(.667,Color3.fromHSV(.667,1,1)),ColorSequenceKeypoint.new(.833,Color3.fromHSV(.833,1,1)),
		ColorSequenceKeypoint.new(1,Color3.fromHSV(0,1,1)),
	}),Rotation=90,Parent=hb})
	local hc=Create("Frame",{Size=UDim2.new(1,4,0,3),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,h,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=3002,Parent=hb},{Create("UICorner",{CornerRadius=UDim.new(1,0)}),Create("UIStroke",{Color=Color3.new(0,0,0),Thickness=1})})
	local bY=PAD+SV_H+8
	local ps=Create("Frame",{Size=UDim2.new(0,22,0,18),Position=UDim2.new(0,PAD,0,bY+2),BackgroundColor3=cur,BorderSizePixel=0,ZIndex=3001,Parent=pf},{Create("UICorner",{CornerRadius=UDim.new(0,3)}),Create("UIStroke",{Color=T.BorderHi,Thickness=1})})
	local hx=Create("TextBox",{Size=UDim2.new(0,tW-PAD*2-28,0,22),Position=UDim2.new(0,PAD+28,0,bY),BackgroundColor3=T.Input,BorderSizePixel=0,Text=C3Hex(cur),TextColor3=T.TextHi,PlaceholderText="#RRGGBB",PlaceholderColor3=T.TextLo,TextSize=10,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=3001,Parent=pf},{Create("UICorner",{CornerRadius=UDim.new(0,3)}),Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UIPadding",{PaddingLeft=UDim.new(0,6)})})
	local function upd(nh,ns,nv)
		h=math.clamp(nh or h,0,1);s=math.clamp(ns or s,0,1);v=math.clamp(nv or v,0,1)
		cur=Color3.fromHSV(h,s,v);svA.BackgroundColor3=Color3.fromHSV(h,1,1)
		svc.Position=UDim2.new(s,0,1-v,0);hc.Position=UDim2.new(.5,0,h,0)
		ps.BackgroundColor3=cur;hx.Text=C3Hex(cur);pcall(cb,cur)
		local o=Library.Options[k];if o then o._val=cur end
	end
	local svD,huD=false,false
	svA.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			svD=true;local a=svA.AbsolutePosition;local sz=svA.AbsoluteSize
			upd(h,math.clamp((i.Position.X-a.X)/sz.X,0,1),1-math.clamp((i.Position.Y-a.Y)/sz.Y,0,1))
		end
	end)
	hb.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			huD=true;local a=hb.AbsolutePosition;local sz=hb.AbsoluteSize
			upd(math.clamp((i.Position.Y-a.Y)/sz.Y,0,1),s,v)
		end
	end)
	table.insert(Library._connections,UIS.InputChanged:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseMovement then
			if svD then local a=svA.AbsolutePosition;local sz=svA.AbsoluteSize;upd(h,math.clamp((i.Position.X-a.X)/sz.X,0,1),1-math.clamp((i.Position.Y-a.Y)/sz.Y,0,1))end
			if huD then local a=hb.AbsolutePosition;local sz=hb.AbsoluteSize;upd(math.clamp((i.Position.Y-a.Y)/sz.Y,0,1),s,v)end
		end
	end))
	table.insert(Library._connections,UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then svD=false;huD=false end
	end))
	local hxSt=hx:FindFirstChildOfClass("UIStroke")
	hx.Focused:Connect(function()if hxSt then Tween(hxSt,{Color=T.Accent},.12)end end)
	hx.FocusLost:Connect(function()
		if hxSt then Tween(hxSt,{Color=T.BorderHi},.12)end
		local nc=HexC3(hx.Text);if nc then local nh,ns,nv=Color3.toHSV(nc);upd(nh,ns,nv)else hx.Text=C3Hex(cur)end
	end)
	local function openPicker(sw)
		if _openCP and _openCP~=pf then _openCP.Visible=false end
		local cam=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
		local a=sw.AbsolutePosition
		local px=a.X+sw.AbsoluteSize.X+6
		local py=a.Y-4
		if px+tW>cam.X-4 then px=a.X-tW-6 end
		if py+tH>cam.Y-4 then py=cam.Y-tH-4 end
		if py<4 then py=4 end
		pf.Position=UDim2.new(0,px,0,py);pf.Visible=true;_openCP=pf;upd(h,s,v)
	end
	return pf,openPicker,function()return cur end,function(nc)
		local nh,ns,nv=Color3.toHSV(nc);h,s,v=nh,ns,nv;cur=nc
		svA.BackgroundColor3=Color3.fromHSV(h,1,1);svc.Position=UDim2.new(s,0,1-v,0)
		hc.Position=UDim2.new(.5,0,h,0);ps.BackgroundColor3=cur;hx.Text=C3Hex(cur)
	end
end
local function MakeModeMenu(row,getMode,setMode)
	local menu=Create("Frame",{Size=UDim2.new(0,80,0,50),BackgroundColor3=T.Bg2,BorderSizePixel=0,Visible=false,ZIndex=400,Parent=ScreenGui},{
		Create("UICorner",{CornerRadius=UDim.new(0,4)}),Create("UIStroke",{Color=T.BorderHi,Thickness=1}),
		Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder})
	})
	local function MItem(txt,mode)
		local btn=Create("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text=txt,TextColor3=T.TextHi,TextSize=10,Font=Enum.Font.Gotham,BorderSizePixel=0,ZIndex=401,Parent=menu},{Create("UIPadding",{PaddingLeft=UDim.new(0,8)})})
		btn.TextXAlignment=Enum.TextXAlignment.Left
		btn.MouseButton1Click:Connect(function()setMode(mode);menu.Visible=false end)
		btn.MouseEnter:Connect(function()Tween(btn,{TextColor3=T.Accent},.08)end)
		btn.MouseLeave:Connect(function()Tween(btn,{TextColor3=T.TextHi},.08)end)
	end
	MItem("Toggle","toggle");MItem("Hold","hold")
	row.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton2 then
			local mp=UIS:GetMouseLocation();menu.Position=UDim2.new(0,mp.X,0,mp.Y);menu.Visible=true
		end
	end)
	UIS.InputBegan:Connect(function(inp,gpe)
		if not gpe and inp.UserInputType==Enum.UserInputType.MouseButton1 and menu.Visible then
			local mp=UIS:GetMouseLocation();local p=menu.AbsolutePosition;local sz=menu.AbsoluteSize
			if mp.X<p.X or mp.X>p.X+sz.X or mp.Y<p.Y or mp.Y>p.Y+sz.Y then menu.Visible=false end
		end
	end)
end
function Library:CreateWindow(cfg)
	cfg=cfg or{}
	local title=cfg.Title or"Punchy";local subtitle=cfg.SubTitle or""
	local key=cfg.Key or Enum.KeyCode.Insert
	local center=cfg.Center~=false;local autoshow=cfg.AutoShow~=false
	local keyRef={v=key};Library._keyRef=keyRef
	local pos=center and UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)or UDim2.new(0,60,0,60)
	local WF=Create("Frame",{Name="Window",Size=UDim2.new(0,WIN_W,0,WIN_H),Position=pos,
		BackgroundColor3=T.Bg1,BorderSizePixel=0,ClipsDescendants=false,Visible=autoshow,Parent=ScreenGui
	},{Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,6)})})
	TR(WF,"BackgroundColor3","Bg1");TR(WF:FindFirstChildOfClass("UIStroke"),"Color","BorderHi")
	Create("Frame",{Size=UDim2.new(0,80,0,2),Position=UDim2.new(0,20,0,0),BackgroundColor3=T.Accent,BorderSizePixel=0,ZIndex=2,Parent=WF},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
	local TB=Create("Frame",{Size=UDim2.new(1,0,0,TITLE_H),BackgroundColor3=T.Bg0,BorderSizePixel=0,Parent=WF},{
		Create("UICorner",{CornerRadius=UDim.new(0,6)}),
		Create("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),BackgroundColor3=T.Bg0,BorderSizePixel=0}),
		Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=T.Border,BorderSizePixel=0}),
	})
	TR(TB,"BackgroundColor3","Bg0");TR(TB:GetChildren()[2],"BackgroundColor3","Bg0");TR(TB:GetChildren()[3],"BackgroundColor3","Border")
	MakeDraggable(WF,TB)
	BuildLogo(TB,12,10)
	Create("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(0,30,0,0),BackgroundTransparency=1,Text=title:upper(),TextColor3=T.TextHi,TextSize=12,Font=Enum.Font.GothamBlack,TextXAlignment=Enum.TextXAlignment.Left,Parent=TB})
	if subtitle~=""then
		Create("Frame",{Size=UDim2.new(0,1,0,12),Position=UDim2.new(0,112,0.5,-6),BackgroundColor3=T.TextLo,BorderSizePixel=0,Parent=TB})
		Create("TextLabel",{Size=UDim2.new(0,140,1,0),Position=UDim2.new(0,120,0,0),BackgroundTransparency=1,Text=subtitle,TextColor3=T.TextMid,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=TB})
	end
	local keyBadge=Create("TextLabel",{Size=UDim2.new(0,58,0,17),Position=UDim2.new(1,-88,0.5,-8),BackgroundColor3=T.Bg2,BorderSizePixel=0,Text=keyRef.v.Name:upper(),TextColor3=T.TextMid,TextSize=9,Font=Enum.Font.GothamMedium,Parent=TB},{
		Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,3)})
	})
	local CloseBtn=Create("TextButton",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(1,-20,0.5,-6),BackgroundColor3=T.Red,BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=TB},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
	CloseBtn.MouseEnter:Connect(function()Tween(CloseBtn,{BackgroundColor3=Color3.fromRGB(255,100,100)},.1)end)
	CloseBtn.MouseLeave:Connect(function()Tween(CloseBtn,{BackgroundColor3=T.Red},.1)end)
	local isAnim=false
	local function closeW()
		if isAnim then return end;isAnim=true
		local p=WF.Position;Tween(WF,{Position=UDim2.new(p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset+10)},.12)
		task.wait(.13);WF.Visible=false;WF.Position=p;isAnim=false
	end
	local function openW()
		if isAnim then return end;isAnim=true
		local p=WF.Position;WF.Position=UDim2.new(p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset-8);WF.Visible=true
		Tween(WF,{Position=UDim2.new(p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset+8)},.15)
		task.wait(.16);isAnim=false
	end
	CloseBtn.MouseButton1Click:Connect(closeW)
	local TabBar=Create("Frame",{Size=UDim2.new(1,0,0,TAB_H),Position=UDim2.new(0,0,0,TITLE_H),BackgroundColor3=T.Bg0,BorderSizePixel=0,Parent=WF},{
		Create("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder}),
		Create("UIPadding",{PaddingLeft=UDim.new(0,6)})
	})
	TR(TabBar,"BackgroundColor3","Bg0")
	Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,TITLE_H-1),BackgroundColor3=T.Border,BorderSizePixel=0,ZIndex=2,Parent=WF})
	Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,TITLE_H+TAB_H-1),BackgroundColor3=T.Border,BorderSizePixel=0,ZIndex=2,Parent=WF})
	local ContentArea=Create("ScrollingFrame",{Name="ContentArea",Size=UDim2.new(1,0,0,CONTENT_H),Position=UDim2.new(0,0,0,TITLE_H+TAB_H),
		BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=T.BorderHi,
		ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.new(0,0,0,0),
		AutomaticCanvasSize=Enum.AutomaticSize.Y,ClipsDescendants=true,Parent=WF
	})
	local SB=Create("Frame",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,WIN_H-22),BackgroundColor3=T.Bg0,BorderSizePixel=0,Parent=WF},{
		Create("UICorner",{CornerRadius=UDim.new(0,6)}),
		Create("Frame",{Size=UDim2.new(1,0,0,8),BackgroundColor3=T.Bg0,BorderSizePixel=0}),
		Create("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=T.Border,BorderSizePixel=0})
	})
	TR(SB,"BackgroundColor3","Bg0");TR(SB:GetChildren()[1],"BackgroundColor3","Bg0");TR(SB:GetChildren()[2],"BackgroundColor3","Border")
	Create("Frame",{Size=UDim2.new(0,5,0,5),Position=UDim2.new(0,10,0.5,-2),BackgroundColor3=T.Green,BorderSizePixel=0,Parent=SB},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
	Create("TextLabel",{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,20,0,0),BackgroundTransparency=1,Text="INJECTED",TextColor3=T.Green,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=SB})
	local PingLbl=Create("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(1,-85,0,0),BackgroundTransparency=1,Text="12ms · v3.1",TextColor3=T.TextLo,TextSize=9,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Right,Parent=SB})
	task.spawn(function()
		while task.wait(2.5)do
			if not WF or not WF.Parent then break end
			local ms=math.random(6,26);PingLbl.Text=ms.."ms · v3.1";PingLbl.TextColor3=ms>20 and Color3.fromRGB(210,160,50)or T.TextLo
		end
	end)
	table.insert(Library._connections,UIS.InputBegan:Connect(function(inp,gpe)
		if not gpe and inp.KeyCode==keyRef.v then if WF.Visible then closeW()else openW()end end
	end))
	local Window={_frame=WF,_tabBar=TabBar,_content=ContentArea,_tabs={},_activeTab=nil,_keyRef=keyRef,_keyBadge=keyBadge}
	function Window:_switchTab(tab)
		for _,t in ipairs(self._tabs)do
			t._page.Visible=false;Tween(t._btn,{TextColor3=T.TextMid},.12);t._ind.BackgroundTransparency=1
		end
		tab._page.Visible=true;Tween(tab._btn,{TextColor3=T.Accent},.12);tab._ind.BackgroundTransparency=0;self._activeTab=tab
	end
	function Window:AddTab(name)
		local tabW=math.max(64,#name*8+28)
		local btn=Create("TextButton",{Size=UDim2.new(0,tabW,1,0),BackgroundTransparency=1,Text=name,TextColor3=T.TextMid,TextSize=11,Font=Enum.Font.GothamMedium,BorderSizePixel=0,LayoutOrder=#TabBar:GetChildren(),Parent=TabBar})
		local ind=Create("Frame",{Size=UDim2.new(1,-16,0,2),Position=UDim2.new(0,8,1,-2),BackgroundColor3=T.Accent,BackgroundTransparency=1,BorderSizePixel=0,Parent=btn},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
		local page=Create("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false,Parent=ContentArea},{
			Create("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Top}),
			Create("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,16)}),
		})
		local tab={_btn=btn,_ind=ind,_page=page,_win=self,_lCol=nil,_rCol=nil}
		local function getCol(side)
			local w=side=="Left"and"_lCol"or"_rCol"
			if not tab[w]then
				tab[w]=Create("Frame",{Size=UDim2.new(0.5,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=side=="Left"and 1 or 2,Parent=page},{
					Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)})
				})
			end
			return tab[w]
		end
		local function makeGB(gbName,side)
			local col=getCol(side)
			local box=Create("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=T.Bg2,BorderSizePixel=0,LayoutOrder=#col:GetChildren(),Parent=col},{
				Create("UIStroke",{Color=T.Border,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,5)})
			})
			TR(box,"BackgroundColor3","Bg2");TR(box:FindFirstChildOfClass("UIStroke"),"Color","Border")
			local hdr=Create("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=T.Bg1,BorderSizePixel=0,Parent=box},{
				Create("UICorner",{CornerRadius=UDim.new(0,5)}),
				Create("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,1,-6),BackgroundColor3=T.Bg1,BorderSizePixel=0}),
				Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=T.Border,BorderSizePixel=0}),
			})
			TR(hdr,"BackgroundColor3","Bg1");TR(hdr:GetChildren()[1],"BackgroundColor3","Bg1");TR(hdr:GetChildren()[2],"BackgroundColor3","Border")
			Create("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=gbName:upper(),TextColor3=T.TextMid,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=hdr})
			local body=Create("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,24),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=box},{
				Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)}),
				Create("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,6)}),
			})
			local GB={_body=body}
			local function addDep(ctrl,deps)
				if not deps then return end
				local function check()
					local vis=true
					for _,d in ipairs(deps)do
						local t=Library.Toggles[d]
						if t and not t.Value then vis=false;break end
					end
					if ctrl.Parent then ctrl.Visible=vis end
				end
				check()
				for _,d in ipairs(deps)do
					if not Library._depListeners[d]then Library._depListeners[d]={}end
					table.insert(Library._depListeners[d],check)
				end
			end
			local function fireDepListeners(k)
				if Library._depListeners[k]then for _,fn in ipairs(Library._depListeners[k])do pcall(fn)end end
			end
			function GB:AddToggle(k,c2)
				c2=c2 or{};local text=c2.Text or k;local default=c2.Default~=nil and c2.Default or false
				local cb=c2.Callback or function()end;local color=c2.Color or"accent"
				local ac=color=="purple"and T.Purple or T.Accent;local ad=color=="purple"and T.PurpleDim or T.AccentDim
				local row=Create("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text="",BorderSizePixel=0,LayoutOrder=#body:GetChildren(),Parent=body},{Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)})})
				Create("TextLabel",{Size=UDim2.new(1,-38,1,0),BackgroundTransparency=1,Text=text,TextColor3=T.TextHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
				local pill=Create("Frame",{Size=UDim2.new(0,30,0,15),Position=UDim2.new(1,-30,0.5,-7),BackgroundColor3=T.ToggleOff,BorderSizePixel=0,Parent=row},{Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				local thumb=Create("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(0,2,0.5,-5),BackgroundColor3=T.TextLo,BorderSizePixel=0,Parent=pill},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				local value=default;local stroke=pill:FindFirstChildOfClass("UIStroke")
				local function apply(v2,silent)
					value=v2
					if v2 then Tween(pill,{BackgroundColor3=ad},.15);Tween(thumb,{Position=UDim2.new(0,18,0.5,-5),BackgroundColor3=ac},.15);stroke.Color=ac
					else Tween(pill,{BackgroundColor3=T.ToggleOff},.15);Tween(thumb,{Position=UDim2.new(0,2,0.5,-5),BackgroundColor3=T.TextLo},.15);stroke.Color=T.BorderHi end
					if not silent then pcall(cb,v2);fireDepListeners(k)end
				end
				apply(default,true)
				row.MouseButton1Click:Connect(function()apply(not value)end)
				row.MouseEnter:Connect(function()row.BackgroundColor3=T.Hover;row.BackgroundTransparency=0 end)
				row.MouseLeave:Connect(function()row.BackgroundTransparency=1 end)
				addDep(row,c2.Deps)
				local To={}
				To.SetValue=function(_,v2)apply(v2)end
				setmetatable(To,{__index=function(_,k2)if k2=="Value"then return value end end,__newindex=function(_,k2,v2)if k2=="Value"then apply(v2)end end})
				Library.Toggles[k]=To;return To
			end
			function GB:AddSlider(k,c2)
				c2=c2 or{};local text=c2.Text or k;local min=c2.Min or 0;local max=c2.Max or 100
				local default=c2.Default~=nil and c2.Default or min;local rounding=c2.Rounding~=nil and c2.Rounding or 0
				local suffix=c2.Suffix or"";local color=c2.Color or"accent";local cb=c2.Callback or function()end
				local ac=color=="purple"and T.Purple or T.Accent
				local wrap=Create("Frame",{Size=UDim2.new(1,0,0,46),BackgroundTransparency=1,LayoutOrder=#body:GetChildren(),Parent=body},{Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)})})
				Create("TextLabel",{Size=UDim2.new(0.6,0,0,18),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,Text=text,TextColor3=T.TextHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
				local valL=Create("TextLabel",{Size=UDim2.new(0.4,0,0,18),Position=UDim2.new(0.6,0,0,2),BackgroundTransparency=1,Text=tostring(default)..suffix,TextColor3=ac,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,Parent=wrap})
				local track=Create("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,0,30),BackgroundColor3=T.Bg0,BorderSizePixel=0,ClipsDescendants=false,Parent=wrap},{Create("UIStroke",{Color=T.Border,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				local fc=Create("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,Parent=track});Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=fc})
				local fill=Create("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=ac,BorderSizePixel=0,Parent=fc},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				local thumb=Create("TextButton",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,-7,0.5,-7),BackgroundColor3=T.TextHi,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=6,Parent=track},{Create("UIStroke",{Color=ac,Thickness=1.5}),Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				local value=default;local slD=false
				local function applyP(pct)
					pct=math.clamp(pct,0,1);local raw=min+(max-min)*pct
					if rounding==0 then value=math.round(raw)else local m=10^rounding;value=math.floor(raw*m+.5)/m end
					fill.Size=UDim2.new(pct,0,1,0);thumb.Position=UDim2.new(pct,-7,0.5,-7);valL.Text=tostring(value)..suffix;pcall(cb,value)
				end
				applyP((default-min)/(max-min))
				thumb.MouseButton1Down:Connect(function()slD=true;Tween(thumb,{Size=UDim2.new(0,16,0,16),Position=UDim2.new(thumb.Position.X.Scale,thumb.Position.X.Offset-1,0.5,-8)},.08)end)
				track.InputBegan:Connect(function(inp)if inp.UserInputType==Enum.UserInputType.MouseButton1 then slD=true;applyP((UIS:GetMouseLocation().X-track.AbsolutePosition.X)/track.AbsoluteSize.X)end end)
				UIS.InputChanged:Connect(function(inp)if slD and inp.UserInputType==Enum.UserInputType.MouseMovement then applyP((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X)end end)
				UIS.InputEnded:Connect(function(inp)if inp.UserInputType==Enum.UserInputType.MouseButton1 and slD then slD=false;Tween(thumb,{Size=UDim2.new(0,14,0,14),Position=UDim2.new(thumb.Position.X.Scale,thumb.Position.X.Offset+1,0.5,-7)},.08)end end)
				addDep(wrap,c2.Deps)
				local S={};S.SetValue=function(_,v2)applyP((v2-min)/(max-min))end
				setmetatable(S,{__index=function(_,k2)if k2=="Value"then return value end end,__newindex=function(_,k2,v2)if k2=="Value"then applyP((v2-min)/(max-min))end end})
				Library.Options[k]=S;return S
			end
			function GB:AddDropdown(k,c2)
				c2=c2 or{};local text=c2.Text or k;local vals=c2.Values or{};local default=c2.Default or(vals[1]or"")
				local cb=c2.Callback or function()end;local multi=c2.Multi or false
				local wrap=Create("Frame",{Size=UDim2.new(1,0,0,52),BackgroundTransparency=1,ClipsDescendants=false,LayoutOrder=#body:GetChildren(),Parent=body},{Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)})})
				Create("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,Text=text,TextColor3=T.TextMid,TextSize=10,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
				local db=Create("TextButton",{Size=UDim2.new(1,0,0,24),Position=UDim2.new(0,0,0,22),BackgroundColor3=T.Input,BorderSizePixel=0,Text="",Parent=wrap},{Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,3)})})
				local selL=Create("TextLabel",{Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text=multi and"None"or default,TextColor3=T.TextHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=db})
				local aL=Create("Frame",{Size=UDim2.new(0,6,0,1),Position=UDim2.new(1,-17,0.5,1),BackgroundColor3=T.TextMid,BorderSizePixel=0,Parent=db},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				local aR=Create("Frame",{Size=UDim2.new(0,6,0,1),Position=UDim2.new(1,-12,0.5,1),BackgroundColor3=T.TextMid,BorderSizePixel=0,Parent=db},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				aL.Rotation=35;aR.Rotation=-35
				local lf=Create("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,1,3),BackgroundColor3=T.Bg3,BorderSizePixel=0,Visible=false,ZIndex=25,Parent=db},{Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,3)}),Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder})})
				local value=multi and{}or default;local open=false
				local function dispText()
					if not multi then return value end
					local ks={};for k2 in pairs(value)do table.insert(ks,k2)end
					return #ks==0 and"None"or #ks==1 and ks[1]or #ks.." selected"
				end
				local function buildList()
					for _,c3 in ipairs(lf:GetChildren())do if c3:IsA("TextButton")then c3:Destroy()end end
					for _,v2 in ipairs(vals)do
						local isSel=multi and value[v2]or v2==value
						local opt=Create("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundColor3=T.Bg3,BorderSizePixel=0,Text=v2,TextColor3=isSel and T.Accent or T.TextHi,TextSize=11,Font=isSel and Enum.Font.GothamMedium or Enum.Font.Gotham,ZIndex=26,Parent=lf},{Create("UIPadding",{PaddingLeft=UDim.new(0,10)})})
						opt.TextXAlignment=Enum.TextXAlignment.Left
						if multi then
							Create("TextLabel",{Size=UDim2.new(0,18,1,0),Position=UDim2.new(1,-20,0,0),BackgroundTransparency=1,Text=isSel and"✓"or"",TextColor3=T.Accent,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=27,Parent=opt})
							opt.MouseButton1Click:Connect(function()if value[v2]then value[v2]=nil else value[v2]=true end;selL.Text=dispText();pcall(cb,value);buildList()end)
						else
							opt.MouseButton1Click:Connect(function()value=v2;selL.Text=v2;open=false;lf.Visible=false;pcall(cb,v2);buildList()end)
						end
						opt.MouseEnter:Connect(function()Tween(opt,{BackgroundColor3=T.Hover},.08)end)
						opt.MouseLeave:Connect(function()Tween(opt,{BackgroundColor3=T.Bg3},.08)end)
					end
					lf.Size=UDim2.new(1,0,0,#vals*24)
				end
				buildList()
				db.MouseButton1Click:Connect(function()open=not open;lf.Visible=open;Tween(aL,{Rotation=open and-35 or 35},.1);Tween(aR,{Rotation=open and 35 or-35},.1)end)
				db.MouseEnter:Connect(function()Tween(db,{BackgroundColor3=T.Hover},.1)end)
				db.MouseLeave:Connect(function()Tween(db,{BackgroundColor3=T.Input},.1)end)
				addDep(wrap,c2.Deps)
				local D={Values=vals}
				D.SetValue=function(_,v2)if multi then if type(v2)=="table"then value=v2 else value[v2]=true end else value=v2 end;selL.Text=dispText();pcall(cb,value);buildList()end
				D.GetValue=function(_)return value end
				setmetatable(D,{__index=function(_,k2)if k2=="Value"then return value end end,__newindex=function(_,k2,v2)if k2=="Value"then D:SetValue(v2)end end})
				Library.Options[k]=D;return D
			end
			function GB:AddColorPicker(k,c2)
				c2=c2 or{};local text=c2.Text or k;local default=c2.Default or T.Accent;local cb=c2.Callback or function()end
				local row=Create("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=#body:GetChildren(),Parent=body},{Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)})})
				Create("TextLabel",{Size=UDim2.new(1,-28,1,0),BackgroundTransparency=1,Text=text,TextColor3=T.TextHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
				local sw=Create("TextButton",{Size=UDim2.new(0,20,0,14),Position=UDim2.new(1,-20,0.5,-7),BackgroundColor3=default,BorderSizePixel=0,Text="",Parent=row},{Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,3)})})
				local cur=default
				local _,openP,_,setPC=MakeColorPicker(k,default,function(nc)cur=nc;sw.BackgroundColor3=nc;pcall(cb,nc)end)
				sw.MouseButton1Click:Connect(function()openP(sw)end)
				addDep(row,c2.Deps)
				local CP={_val=default}
				CP.SetValue=function(_,v2)cur=v2;sw.BackgroundColor3=v2;setPC(v2);pcall(cb,v2)end
				setmetatable(CP,{__index=function(_,k2)if k2=="Value"then return cur end end,__newindex=function(_,k2,v2)if k2=="Value"then CP:SetValue(v2)end end})
				Library.Options[k]=CP;return CP
			end
			function GB:AddKeybind(k,c2)
				c2=c2 or{};local text=c2.Text or k;local default=c2.Default or Enum.KeyCode.Unknown
				local mode=c2.Mode or"toggle";local cb=c2.Callback or function()end;local holdCb=c2.HoldCallback or function()end
				local curMode=mode
				local row=Create("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text="",BorderSizePixel=0,LayoutOrder=#body:GetChildren(),Parent=body},{Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)})})
				Create("TextLabel",{Size=UDim2.new(1,-64,1,0),BackgroundTransparency=1,Text=text,TextColor3=T.TextHi,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
				local badge=Create("TextLabel",{Size=UDim2.new(0,56,0,17),Position=UDim2.new(1,-56,0.5,-8),BackgroundColor3=T.Input,BorderSizePixel=0,Text="["..default.Name:upper().."]",TextColor3=T.TextMid,TextSize=9,Font=Enum.Font.GothamMedium,Parent=row},{Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,3)})})
				local value=default;local binding=false
				local kblE=Create("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=#kblBody:GetChildren(),Parent=kblBody})
				local kblHov=Create("Frame",{Size=UDim2.new(1,-6,1,-1),Position=UDim2.new(0,3,0,0),BackgroundColor3=T.Bg1,BackgroundTransparency=1,BorderSizePixel=0,Parent=kblE},{Create("UICorner",{CornerRadius=UDim.new(0,3)})})
				local kblBar=Create("Frame",{Size=UDim2.new(0,2,0,12),Position=UDim2.new(0,6,0.5,-6),BackgroundColor3=T.TextLo,BorderSizePixel=0,Parent=kblE},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
				local kblLbl=Create("TextLabel",{Size=UDim2.new(1,-100,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text=text,TextColor3=T.TextMid,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=kblE})
				local kblKey=Create("TextLabel",{Size=UDim2.new(0,38,0,14),Position=UDim2.new(1,-82,0.5,-7),BackgroundColor3=T.Bg3,BorderSizePixel=0,Text=default.Name:upper(),TextColor3=T.TextLo,TextSize=7,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Center,Parent=kblE},{Create("UICorner",{CornerRadius=UDim.new(0,2)}),Create("UIStroke",{Color=T.Border,Thickness=1})})
				local kblState=Create("TextLabel",{Size=UDim2.new(0,28,0,14),Position=UDim2.new(1,-38,0.5,-7),BackgroundColor3=T.Bg3,BorderSizePixel=0,Text=mode=="hold"and"HOLD"or"OFF",TextColor3=T.TextLo,TextSize=7,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,Parent=kblE},{Create("UICorner",{CornerRadius=UDim.new(0,2)}),Create("UIStroke",{Color=T.Border,Thickness=1})})
				kblE.MouseEnter:Connect(function()Tween(kblHov,{BackgroundTransparency=0.6},.1)end)
				kblE.MouseLeave:Connect(function()Tween(kblHov,{BackgroundTransparency=1},.1)end)
				Library._kblEntries[k]={frame=kblE,bar=kblBar,keyLabel=kblKey,stateChip=kblState,nameLabel=kblLbl}
				refreshKBL()
				local function setMode(m)
					curMode=m
					if Library._binds[k]then Library._binds[k].mode=m end
					refreshKBL()
				end
				MakeModeMenu(row,function()return curMode end,setMode)
				row.MouseButton1Click:Connect(function()
					binding=true;badge.Text="[ . . . ]";badge.TextColor3=T.Accent;Tween(badge,{BackgroundColor3=T.Bg3},.1)
				end)
				row.MouseEnter:Connect(function()row.BackgroundColor3=T.Hover;row.BackgroundTransparency=0 end)
				row.MouseLeave:Connect(function()row.BackgroundTransparency=1 end)
				UIS.InputBegan:Connect(function(inp,gpe)
					if binding and not gpe and inp.UserInputType==Enum.UserInputType.Keyboard then
						if inp.KeyCode==Enum.KeyCode.Escape then binding=false;badge.Text="["..value.Name:upper().."]";badge.TextColor3=T.TextMid;Tween(badge,{BackgroundColor3=T.Input},.1);return end
						binding=false;value=inp.KeyCode
						badge.Text="["..inp.KeyCode.Name:upper().."]";badge.TextColor3=T.TextMid
						kblKey.Text=inp.KeyCode.Name:upper()
						Tween(badge,{BackgroundColor3=T.Input},.1)
						if k=="MenuKey"then keyRef.v=inp.KeyCode;keyBadge.Text=inp.KeyCode.Name:upper()end
						Library:RegisterBind(k,value,curMode,cb,holdCb);pcall(cb,value)
					end
				end)
				Library:RegisterBind(k,default,curMode,cb,holdCb)
				addDep(row,c2.Deps)
				local KB={}
				KB.SetValue=function(_,v2)value=v2;badge.Text="["..v2.Name:upper().."]";kblKey.Text=v2.Name:upper();if k=="MenuKey"then keyRef.v=v2;keyBadge.Text=v2.Name:upper()end;Library:SetBind(k,v2)end
				setmetatable(KB,{__index=function(_,k2)if k2=="Value"then return value end end,__newindex=function(_,k2,v2)if k2=="Value"then KB:SetValue(v2)end end})
				Library.Options[k]=KB;return KB
			end
			function GB:AddTextbox(k,c2)
				c2=c2 or{};local text=c2.Text or k;local default=c2.Default or"";local placeholder=c2.Placeholder or"Enter value..."
				local clearOnFocus=c2.ClearOnFocus~=false;local cb=c2.Callback or function()end
				local wrap=Create("Frame",{Size=UDim2.new(1,0,0,52),BackgroundTransparency=1,LayoutOrder=#body:GetChildren(),Parent=body},{Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)})})
				Create("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,Text=text,TextColor3=T.TextMid,TextSize=10,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
				local ib=Create("TextBox",{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,22),BackgroundColor3=T.Input,BorderSizePixel=0,Text=default,PlaceholderText=placeholder,TextColor3=T.TextHi,PlaceholderColor3=T.TextLo,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=clearOnFocus,Parent=wrap},{Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,3)}),Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,6)})})
				local st=ib:FindFirstChildOfClass("UIStroke")
				ib.Focused:Connect(function()Tween(st,{Color=T.Accent},.12)end)
				ib.FocusLost:Connect(function(enter)Tween(st,{Color=T.BorderHi},.12);pcall(cb,ib.Text,enter)end)
				addDep(wrap,c2.Deps)
				local TX={};TX.SetValue=function(_,v2)ib.Text=tostring(v2)end
				setmetatable(TX,{__index=function(_,k2)if k2=="Value"then return ib.Text end end,__newindex=function(_,k2,v2)if k2=="Value"then ib.Text=tostring(v2)end end})
				Library.Options[k]=TX;return TX
			end
			function GB:AddButton(c2)
				c2=c2 or{};local text=c2.Text or"Button";local cb=c2.Callback or function()end
				local wrap=Create("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,LayoutOrder=#body:GetChildren(),Parent=body},{Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)})})
				local btn=Create("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=T.Bg3,BorderSizePixel=0,Text=text,TextColor3=T.TextHi,TextSize=11,Font=Enum.Font.GothamMedium,Parent=wrap},{Create("UIStroke",{Color=T.BorderHi,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,4)})})
				TR(btn,"BackgroundColor3","Bg3");TR(btn:FindFirstChildOfClass("UIStroke"),"Color","BorderHi")
				btn.MouseButton1Click:Connect(function()Tween(btn,{BackgroundColor3=T.AccentDim},.08);task.wait(.14);Tween(btn,{BackgroundColor3=T.Bg3},.14);pcall(cb)end)
				btn.MouseEnter:Connect(function()Tween(btn,{BackgroundColor3=T.Hover},.1)end)
				btn.MouseLeave:Connect(function()Tween(btn,{BackgroundColor3=T.Bg3},.1)end)
				addDep(wrap,c2.Deps)
			end
			function GB:AddLabel(text,id,c2)
				c2=c2 or{}
				local lbl=Create("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text=text,TextColor3=T.TextMid,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=#body:GetChildren(),Parent=body},{Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,2)})})
				addDep(lbl,c2 and c2.Deps)
				if id then local L={};L.SetText=function(_,t)lbl.Text=t end;L.SetColor=function(_,c3)lbl.TextColor3=c3 end;Library.Options[id]=L;return L end
			end
			function GB:AddDivider()
				local wrap=Create("Frame",{Size=UDim2.new(1,0,0,10),BackgroundTransparency=1,LayoutOrder=#body:GetChildren(),Parent=body})
				Create("Frame",{Size=UDim2.new(1,-22,0,1),Position=UDim2.new(0,11,0.5,0),BackgroundColor3=T.Border,BorderSizePixel=0,Parent=wrap})
			end
			function GB:AddThemeColor(label,themeKey)
				return self:AddColorPicker("__tc_"..themeKey,{Text=label,Default=T[themeKey],Callback=function(nc)T[themeKey]=nc;ApplyTheme()end})
			end
			function GB:BuildConfigList(folder)
				folder=folder or"Punchy"
				local nameBox=self:AddTextbox("__cfg_name",{Text="Config Name",Default="default",Placeholder="Enter config name...",ClearOnFocus=false})
				local profileDD
				self:AddButton({Text="Save Config",Callback=function()
					Library:SaveConfig(nameBox.Value,folder)
					if profileDD then
						local profs=Library:GetProfiles(folder);if #profs==0 then profs={"No configs found"}end
						profileDD.Values=profs;profileDD:SetValue(nameBox.Value)
					end
				end})
				local function getP()local l=Library:GetProfiles(folder);if #l==0 then l={"No configs found"}end;return l end
				profileDD=self:AddDropdown("__cfg_profile",{Text="Load Profile",Values=getP(),Default=Library:GetProfiles(folder)[1]or""})
				self:AddButton({Text="Load Config",Callback=function()local s=profileDD.Value;if s and s~="No configs found"then Library:LoadConfig(s,folder)end end})
				self:AddButton({Text="Delete Config",Callback=function()local s=profileDD.Value;if s and s~="No configs found"then Library:DeleteConfig(s,folder);local u=getP();profileDD.Values=u;profileDD:SetValue(u[1]or"")end end})
				self:AddButton({Text="Refresh List",Callback=function()local u=getP();profileDD.Values=u;profileDD:SetValue(u[1]or"")end})
			end
			function GB:BuildDefaultConfigSection(folder)
				folder=folder or"Punchy"
				self:BuildConfigList(folder)
				self:AddDivider()
				self:AddToggle("__AutoLoad",{Text="Auto Load on Inject",Default=false})
				self:AddTextbox("__AutoLoadName",{Text="Auto Load Config",Default="default",Placeholder="Config name...",ClearOnFocus=false})
				self:AddToggle("__AutoSave",{Text="Auto Save on Exit",Default=false})
				self:AddButton({Text="Open Config Folder",Callback=function()
					local ok=pcall(function()if not isfolder(folder)then makefolder(folder)end end)
					Library:Notify(ok and"Folder ready: "..folder or"Could not open folder",2,ok and"success"or"error")
				end})
				self:AddButton({Text="Unload",Callback=function()Library:Unload()end})
			end
			function GB:BuildThemeList(folder)
				folder=folder or"PunchyThemes"
				local nameBox=self:AddTextbox("__th_name",{Text="Theme Name",Default="default",Placeholder="Enter theme name...",ClearOnFocus=false})
				local themeDD
				local function getT()local l=Library:GetThemes(folder);if #l==0 then l={"No themes found"}end;return l end
				self:AddButton({Text="Save Theme",Callback=function()
					Library:SaveTheme(nameBox.Value,folder)
					if themeDD then local u=getT();themeDD.Values=u;themeDD:SetValue(nameBox.Value)end
				end})
				themeDD=self:AddDropdown("__th_profile",{Text="Theme List",Values=getT(),Default=Library:GetThemes(folder)[1]or""})
				self:AddButton({Text="Load Theme",Callback=function()local s=themeDD.Value;if s and s~="No themes found"then Library:LoadTheme(s,folder)end end})
				self:AddButton({Text="Refresh List",Callback=function()local u=getT();themeDD.Values=u;themeDD:SetValue(u[1]or"")end})
			end
			function GB:AddUnloadButton()
				self:AddButton({Text="Unload",Callback=function()Library:Unload()end})
			end
			return GB
		end
		function tab:AddLeftGroupbox(name)return makeGB(name,"Left")end
		function tab:AddRightGroupbox(name)return makeGB(name,"Right")end
		btn.MouseButton1Click:Connect(function()self:_switchTab(tab)end)
		btn.MouseEnter:Connect(function()if self._activeTab~=tab then Tween(btn,{TextColor3=T.TextHi},.1)end end)
		btn.MouseLeave:Connect(function()if self._activeTab~=tab then Tween(btn,{TextColor3=T.TextMid},.1)end end)
		table.insert(self._tabs,tab)
		if #self._tabs==1 then self:_switchTab(tab)end
		return tab
	end
	function Window:Unload()
		for _,c in ipairs(Library._connections)do pcall(function()c:Disconnect()end)end
		Library._connections={};for _,fn in ipairs(Library._cleanups)do pcall(fn)end
		Library._cleanups={};Library._binds={};Library._kblEntries={}
		pcall(function()Library._screenGui:Destroy()end);pcall(function()Library._notifGui:Destroy()end)
	end
	Library._window=Window
	return Window
end
function Library:SaveTheme(name,folder)
	folder=folder or"PunchyThemes";name=name or"default"
	local ok=pcall(function()
		if not isfolder(folder)then makefolder(folder)end
		local data={}
		for k,v in pairs(T)do data[k]={r=v.R,g=v.G,b=v.B}end
		writefile(folder.."/"..name..".json",HttpService:JSONEncode(data))
	end)
	if ok then Library:Notify("Theme saved: "..name,2,"success")else Library:Notify("Theme save failed!",2,"error")end
end
function Library:LoadTheme(name,folder)
	folder=folder or"PunchyThemes";name=name or"default"
	local ok,raw=pcall(readfile,folder.."/"..name..".json")
	if not ok or not raw then Library:Notify("No theme: "..name,2,"error");return end
	local ok2,data=pcall(HttpService.JSONDecode,HttpService,raw)
	if not ok2 then Library:Notify("Theme corrupted!",2,"error");return end
	for k,v in pairs(data)do if T[k]and type(v)=="table"then T[k]=Color3.new(v.r,v.g,v.b)end end
	ApplyTheme();Library:Notify("Theme loaded: "..name,2,"success")
end
function Library:GetThemes(folder)
	folder=folder or"PunchyThemes";local list={}
	pcall(function()
		if not isfolder(folder)then return end
		for _,f in ipairs(listfiles(folder))do local n=f:match("([^/\\]+)%.json$");if n then table.insert(list,n)end end
	end)
	return list
end
function Library:Unload()if self._window then self._window:Unload()end end
return Library

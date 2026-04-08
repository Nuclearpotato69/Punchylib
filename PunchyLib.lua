local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

local WIN_W     = 440
local TITLE_H   = 32
local TAB_H     = 30
local STATUS_H  = 22
local CONTENT_H = 380
local WIN_H     = TITLE_H + TAB_H + CONTENT_H + STATUS_H

local function Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	return inst
end

local function Tween(inst, props, t)
	TweenService:Create(inst, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function MakeDraggable(frame, handle)
	local dragging, dragInput, dragStart, startPos
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; dragStart = i.Position; startPos = frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i == dragInput then
			local d = i.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local function HSVtoColor3(h, s, v)
	return Color3.fromHSV(h, s, v)
end

local function Color3toHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
end

local function HextoColor3(hex)
	hex = hex:gsub("#","")
	if #hex ~= 6 then return nil end
	local r = tonumber(hex:sub(1,2),16)
	local g = tonumber(hex:sub(3,4),16)
	local b = tonumber(hex:sub(5,6),16)
	if not r or not g or not b then return nil end
	return Color3.fromRGB(r, g, b)
end

local T = {
	Bg0       = Color3.fromRGB(10,  10,  12),
	Bg1       = Color3.fromRGB(15,  15,  18),
	Bg2       = Color3.fromRGB(20,  20,  24),
	Bg3       = Color3.fromRGB(28,  28,  34),
	Input     = Color3.fromRGB(12,  12,  15),
	Hover     = Color3.fromRGB(32,  32,  40),
	Accent    = Color3.fromRGB(210, 100, 130),
	AccentDim = Color3.fromRGB(150, 65,  90),
	AccentGlow= Color3.fromRGB(240, 130, 160),
	Purple    = Color3.fromRGB(155, 120, 210),
	PurpleDim = Color3.fromRGB(100, 75,  155),
	TextHi    = Color3.fromRGB(238, 235, 230),
	TextMid   = Color3.fromRGB(140, 138, 148),
	TextLo    = Color3.fromRGB(55,  53,  65),
	Border    = Color3.fromRGB(30,  30,  38),
	BorderHi  = Color3.fromRGB(50,  48,  62),
	ToggleOff = Color3.fromRGB(32,  32,  42),
	Green     = Color3.fromRGB(52,  180, 80),
	Red       = Color3.fromRGB(220, 70,  70),
}

local Library   = {}
Library.__index = Library
Library.Toggles  = {}
Library.Options  = {}
Library._connections = {}
Library._cleanups    = {}
Library._binds       = {}
getgenv().PunchyLib  = Library

local ScreenGui
do
	pcall(function() if CoreGui:FindFirstChild("PunchyLib") then CoreGui.PunchyLib:Destroy() end end)
	pcall(function() if LocalPlayer.PlayerGui:FindFirstChild("PunchyLib") then LocalPlayer.PlayerGui.PunchyLib:Destroy() end end)
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name           = "PunchyLib"
	ScreenGui.ResetOnSpawn   = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	ScreenGui.DisplayOrder   = 999
	local ok = pcall(function()
		if gethui then ScreenGui.Parent = gethui()
		elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui
		else ScreenGui.Parent = CoreGui end
	end)
	if not ok or not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end
Library._screenGui = ScreenGui

local ColorPickerOverlay = Create("Frame", {
	Size                 = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel      = 0,
	ZIndex               = 500,
	Visible              = false,
	Parent               = ScreenGui,
})
Library._cpOverlay = ColorPickerOverlay

local _notifGui, _notifStack
do
	pcall(function() if CoreGui:FindFirstChild("PunchyNotifs") then CoreGui.PunchyNotifs:Destroy() end end)
	_notifGui = Instance.new("ScreenGui")
	_notifGui.Name           = "PunchyNotifs"
	_notifGui.ResetOnSpawn   = false
	_notifGui.DisplayOrder   = 10000
	_notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	local ok = pcall(function()
		if gethui then _notifGui.Parent = gethui()
		elseif syn and syn.protect_gui then syn.protect_gui(_notifGui); _notifGui.Parent = CoreGui
		else _notifGui.Parent = CoreGui end
	end)
	if not ok or not _notifGui.Parent then _notifGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	Library._notifGui = _notifGui

	_notifStack = Create("Frame", {
		Size                 = UDim2.new(0, 248, 1, -20),
		Position             = UDim2.new(1, -260, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		Parent               = _notifGui,
	})
	Create("UIListLayout", {
		FillDirection      = Enum.FillDirection.Vertical,
		VerticalAlignment  = Enum.VerticalAlignment.Bottom,
		SortOrder          = Enum.SortOrder.LayoutOrder,
		Padding            = UDim.new(0, 5),
		Parent             = _notifStack,
	})
end

local _notifOrder = 0

function Library:Notify(msg, duration, kind)
	duration = duration or 3
	_notifOrder = _notifOrder + 1
	local accent = kind == "error" and T.Red or kind == "success" and T.Green or T.Accent
	local icon   = kind == "error" and "✕"   or kind == "success" and "✓"     or "i"

	local card = Create("Frame", {
		Size             = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = T.Bg1,
		BorderSizePixel  = 0,
		LayoutOrder      = _notifOrder,
		ClipsDescendants = false,
		Parent           = _notifStack,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
	})

	Create("Frame", {
		Size             = UDim2.new(0, 3, 1, -14),
		Position         = UDim2.new(0, 0, 0, 7),
		BackgroundColor3 = accent,
		BorderSizePixel  = 0,
		Parent           = card,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	Create("TextLabel", {
		Size               = UDim2.new(0, 16, 0, 16),
		Position           = UDim2.new(0, 10, 0.5, -8),
		BackgroundColor3   = accent,
		BackgroundTransparency = 0,
		Text               = icon,
		TextColor3         = Color3.new(1, 1, 1),
		TextSize           = 9,
		Font               = Enum.Font.GothamBold,
		Parent             = card,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	Create("TextLabel", {
		Size               = UDim2.new(1, -38, 1, -8),
		Position           = UDim2.new(0, 32, 0, 4),
		BackgroundTransparency = 1,
		Text               = msg,
		TextColor3         = T.TextHi,
		TextSize           = 11,
		Font               = Enum.Font.Gotham,
		TextXAlignment     = Enum.TextXAlignment.Left,
		TextWrapped        = true,
		Parent             = card,
	})

	local prog = Create("Frame", {
		Size             = UDim2.new(1, 0, 0, 2),
		Position         = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = accent,
		BorderSizePixel  = 0,
		Parent           = card,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 1) }) })

	card.BackgroundTransparency = 0.2
	Tween(card, { BackgroundTransparency = 0 }, 0.18)
	TweenService:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

	task.delay(duration, function()
		Tween(card, { BackgroundTransparency = 1 }, 0.22)
		task.wait(0.23)
		pcall(function() card:Destroy() end)
	end)
end

local KeybindListFrame = Create("Frame", {
	Name                 = "KeybindList",
	Size                 = UDim2.new(0, 152, 0, 0),
	Position             = UDim2.new(0, 8, 0.5, 0),
	BackgroundColor3     = T.Bg1,
	BorderSizePixel      = 0,
	AutomaticSize        = Enum.AutomaticSize.Y,
	Visible              = false,
	Parent               = ScreenGui,
}, {
	Create("UICorner",  { CornerRadius = UDim.new(0, 5) }),
	Create("UIStroke",  { Color = T.BorderHi, Thickness = 1 }),
})

local kblHeader = Create("Frame", {
	Size             = UDim2.new(1, 0, 0, 22),
	BackgroundColor3 = T.Bg0,
	BorderSizePixel  = 0,
	Parent           = KeybindListFrame,
}, {
	Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
	Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = T.Bg0, BorderSizePixel = 0 }),
	Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.Border, BorderSizePixel = 0 }),
})
Create("TextLabel", {
	Size               = UDim2.new(1, -16, 1, 0),
	Position           = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	Text               = "KEYBINDS",
	TextColor3         = T.TextMid,
	TextSize           = 8,
	Font               = Enum.Font.GothamBold,
	TextXAlignment     = Enum.TextXAlignment.Left,
	Parent             = kblHeader,
})
local kblBody = Create("Frame", {
	Size             = UDim2.new(1, 0, 0, 0),
	Position         = UDim2.new(0, 0, 0, 22),
	AutomaticSize    = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel  = 0,
	Parent           = KeybindListFrame,
}, {
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }),
	Create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 4) }),
})
MakeDraggable(KeybindListFrame, kblHeader)
Library._kblFrame = KeybindListFrame
Library._kblBody  = kblBody
-- FIX: _kblEntries stores plain Lua tables {frame, keyLabel, stateLabel}
-- so we never attempt to set arbitrary properties on Roblox Instances.
Library._kblEntries = {}

local function refreshKBL()
	local count = 0
	for id, entry in pairs(Library._kblEntries) do
		local b = Library._binds[id]
		-- FIX: entry is now a Lua table; check entry.frame.Parent instead of entry.Parent
		if b and b.key and entry and entry.frame and entry.frame.Parent then
			local keyName = b.key.Name:upper()
			entry.keyLabel.Text = "["..keyName.."]"
			if b.mode == "toggle" then
				entry.stateLabel.Text       = b.state and "ON" or "OFF"
				entry.stateLabel.TextColor3 = b.state and T.Green or T.Red
			else
				entry.stateLabel.Text       = b.state and "HOLD" or ""
				entry.stateLabel.TextColor3 = T.TextMid
			end
			count = count + 1
		end
	end
	KeybindListFrame.Visible = count > 0
end

local _kbDown = UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	for _, b in pairs(Library._binds) do
		if b.key and inp.KeyCode == b.key then
			if b.mode == "toggle" then
				b.state = not b.state
				pcall(b.onDown, b.state)
				refreshKBL()
			elseif b.mode == "hold" and not b.state then
				b.state = true
				pcall(b.onDown, true)
				refreshKBL()
			end
		end
	end
end)

local _kbUp = UserInputService.InputEnded:Connect(function(inp)
	for _, b in pairs(Library._binds) do
		if b.key and inp.KeyCode == b.key and b.mode == "hold" and b.state then
			b.state = false
			pcall(b.onUp, false)
			refreshKBL()
		end
	end
end)

table.insert(Library._connections, _kbDown)
table.insert(Library._connections, _kbUp)

function Library:RegisterBind(id, key, mode, onDown, onUp)
	Library._binds[id] = { key = key, mode = mode or "toggle", state = false, onDown = onDown or function() end, onUp = onUp or function() end }
end

function Library:SetBind(id, key)
	if Library._binds[id] then Library._binds[id].key = key end
	refreshKBL()
end

function Library:RemoveBind(id)
	Library._binds[id] = nil
	if Library._kblEntries[id] then
		-- FIX: entry is a table now, so destroy entry.frame not entry itself
		pcall(function() Library._kblEntries[id].frame:Destroy() end)
		Library._kblEntries[id] = nil
	end
	refreshKBL()
end

function Library:SaveConfig(name, folder)
	folder = folder or "Punchy"
	name   = name   or "default"
	local ok, err = pcall(function()
		if not isfolder(folder) then makefolder(folder) end
		local data = {}
		for k, t in pairs(Library.Toggles) do
			pcall(function() data["T_"..k] = t.Value end)
		end
		for k, o in pairs(Library.Options) do
			pcall(function()
				local v = o.Value
				if typeof(v) == "Color3" then
					data["O_"..k] = { _t = "c3", r = v.R, g = v.G, b = v.B }
				elseif typeof(v) == "EnumItem" then
					data["O_"..k] = { _t = "en", n = v.Name }
				else
					data["O_"..k] = v
				end
			end)
		end
		writefile(folder.."/"..name..".json", HttpService:JSONEncode(data))
	end)
	if ok then
		Library:Notify("Saved: "..name, 2, "success")
	else
		Library:Notify("Save failed!", 2, "error")
	end
end

function Library:LoadConfig(name, folder)
	folder = folder or "Punchy"
	name   = name   or "default"
	local ok, raw = pcall(readfile, folder.."/"..name..".json")
	if not ok or not raw then Library:Notify("No config: "..name, 2, "error"); return end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok2 then Library:Notify("Config corrupted!", 2, "error"); return end
	for k, v in pairs(data) do
		if k:sub(1,2) == "T_" then
			pcall(function()
				local tog = Library.Toggles[k:sub(3)]
				if tog then tog:SetValue(v) end
			end)
		elseif k:sub(1,2) == "O_" then
			pcall(function()
				local opt = Library.Options[k:sub(3)]
				if opt then
					if type(v) == "table" and v._t == "c3" then
						opt:SetValue(Color3.new(v.r, v.g, v.b))
					elseif type(v) == "table" and v._t == "en" then
						local eok, eval = pcall(function() return Enum.KeyCode[v.n] end)
						if eok and eval then opt:SetValue(eval) end
					else
						opt:SetValue(v)
					end
				end
			end)
		end
	end
	Library:Notify("Loaded: "..name, 2, "success")
end

function Library:DeleteConfig(name, folder)
	folder = folder or "Punchy"
	name   = name   or "default"
	local ok = pcall(delfile, folder.."/"..name..".json")
	if ok then
		Library:Notify("Deleted: "..name, 2, "success")
	else
		Library:Notify("Delete failed!", 2, "error")
	end
end

function Library:GetProfiles(folder)
	folder = folder or "Punchy"
	local list = {}
	pcall(function()
		if not isfolder(folder) then return end
		for _, f in ipairs(listfiles(folder)) do
			local n = f:match("([^/\\]+)%.json$")
			if n then table.insert(list, n) end
		end
	end)
	return list
end

function Library:RegisterCleanup(fn)
	table.insert(Library._cleanups, fn)
end

local function BuildLogo(parent, x, y)
	local bars = { {12,12},{8,8},{5,5} }
	for i, b in ipairs(bars) do
		Create("Frame", {
			Size             = UDim2.new(0, 3, 0, b[1]),
			Position         = UDim2.new(0, x+(i-1)*5, 0, y+(12-b[2])),
			BackgroundColor3 = i==1 and T.AccentGlow or i==2 and T.Accent or T.AccentDim,
			BorderSizePixel  = 0, Parent = parent,
		}, { Create("UICorner", { CornerRadius = UDim.new(0,1) }) })
	end
end

local function MakeColorPicker(k, defaultColor, cb, parentFrame)
	local h, s, v = Color3.toHSV(defaultColor)
	local currentColor = defaultColor
	local pickerOpen = false
	local pickerFrame

	local SV_W, SV_H = 148, 110
	local HUE_W      = 14
	local PAD        = 10

	local totalW = PAD + SV_W + PAD/2 + HUE_W + PAD
	local totalH = PAD + SV_H + 8 + 22 + PAD

	pickerFrame = Create("Frame", {
		Size             = UDim2.new(0, totalW, 0, totalH),
		BackgroundColor3 = T.Bg2,
		BorderSizePixel  = 0,
		Visible          = false,
		ZIndex           = 600,
		Parent           = ColorPickerOverlay,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
	})

	local svArea = Create("Frame", {
		Size             = UDim2.new(0, SV_W, 0, SV_H),
		Position         = UDim2.new(0, PAD, 0, PAD),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		ZIndex           = 601,
		Parent           = pickerFrame,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 3) }) })

	local satOvl = Create("Frame", {
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 602,
		Parent           = svArea,
	})
	Create("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Rotation     = 0,
		Parent       = satOvl,
	})

	local valOvl = Create("Frame", {
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel  = 0,
		ZIndex           = 603,
		Parent           = svArea,
	})
	Create("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
		Rotation     = 90,
		Parent       = valOvl,
	})

	local svCursor = Create("Frame", {
		Size             = UDim2.new(0, 10, 0, 10),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(s, 0, 1-v, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 604,
		Parent           = svArea,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5 }),
	})

	local hueBar = Create("Frame", {
		Size             = UDim2.new(0, HUE_W, 0, SV_H),
		Position         = UDim2.new(0, PAD + SV_W + PAD/2, 0, PAD),
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		ZIndex           = 601,
		Parent           = pickerFrame,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 3) }) })
	Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,    1, 1)),
			ColorSequenceKeypoint.new(0.167,Color3.fromHSV(0.167,1, 1)),
			ColorSequenceKeypoint.new(0.333,Color3.fromHSV(0.333,1, 1)),
			ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5,  1, 1)),
			ColorSequenceKeypoint.new(0.667,Color3.fromHSV(0.667,1, 1)),
			ColorSequenceKeypoint.new(0.833,Color3.fromHSV(0.833,1, 1)),
			ColorSequenceKeypoint.new(1,    Color3.fromHSV(0,    1, 1)),
		}),
		Rotation = 90,
		Parent   = hueBar,
	})
	local hueCursor = Create("Frame", {
		Size             = UDim2.new(1, 4, 0, 3),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0.5, 0, h, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 602,
		Parent           = hueBar,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1 }),
	})

	local bottomY = PAD + SV_H + 8

	local previewSwatch = Create("Frame", {
		Size             = UDim2.new(0, 22, 0, 18),
		Position         = UDim2.new(0, PAD, 0, bottomY + 2),
		BackgroundColor3 = currentColor,
		BorderSizePixel  = 0,
		ZIndex           = 601,
		Parent           = pickerFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
		Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
	})

	local hexBox = Create("TextBox", {
		Size               = UDim2.new(0, totalW - PAD*2 - 28, 0, 22),
		Position           = UDim2.new(0, PAD + 28, 0, bottomY),
		BackgroundColor3   = T.Input,
		BorderSizePixel    = 0,
		Text               = Color3toHex(currentColor),
		TextColor3         = T.TextHi,
		PlaceholderText    = "#RRGGBB",
		PlaceholderColor3  = T.TextLo,
		TextSize           = 10,
		Font               = Enum.Font.GothamMedium,
		TextXAlignment     = Enum.TextXAlignment.Left,
		ClearTextOnFocus   = false,
		ZIndex             = 601,
		Parent             = pickerFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
		Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
	})

	local function updateFromHSV(nh, ns, nv)
		h = math.clamp(nh or h, 0, 1)
		s = math.clamp(ns or s, 0, 1)
		v = math.clamp(nv or v, 0, 1)
		currentColor = Color3.fromHSV(h, s, v)
		svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position       = UDim2.new(s, 0, 1-v, 0)
		hueCursor.Position      = UDim2.new(0.5, 0, h, 0)
		previewSwatch.BackgroundColor3 = currentColor
		hexBox.Text             = Color3toHex(currentColor)
		pcall(cb, currentColor)
		local opt = Library.Options[k]
		if opt then opt._val = currentColor end
	end

	local svDrag, hueDrag = false, false

	local function svFromMouse(mouseX, mouseY)
		local abs = svArea.AbsolutePosition
		local siz = svArea.AbsoluteSize
		local ns  = math.clamp((mouseX - abs.X) / siz.X, 0, 1)
		local nv  = 1 - math.clamp((mouseY - abs.Y) / siz.Y, 0, 1)
		updateFromHSV(h, ns, nv)
	end

	local function hueFromMouse(mouseY)
		local abs = hueBar.AbsolutePosition
		local siz = hueBar.AbsoluteSize
		local nh  = math.clamp((mouseY - abs.Y) / siz.Y, 0, 1)
		updateFromHSV(nh, s, v)
	end

	svArea.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = true
			svFromMouse(inp.Position.X, inp.Position.Y)
		end
	end)
	hueBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			hueDrag = true
			hueFromMouse(inp.Position.Y)
		end
	end)
	local svHueConn = UserInputService.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then
			if svDrag  then svFromMouse(inp.Position.X, inp.Position.Y)  end
			if hueDrag then hueFromMouse(inp.Position.Y)                  end
		end
	end)
	local svHueEndConn = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = false; hueDrag = false
		end
	end)
	table.insert(Library._connections, svHueConn)
	table.insert(Library._connections, svHueEndConn)

	local hexStroke = hexBox:FindFirstChildOfClass("UIStroke")
	hexBox.Focused:Connect(function()    if hexStroke then Tween(hexStroke, { Color = T.Accent }, 0.12) end end)
	hexBox.FocusLost:Connect(function()
		if hexStroke then Tween(hexStroke, { Color = T.BorderHi }, 0.12) end
		local nc = HextoColor3(hexBox.Text)
		if nc then
			local nh, ns, nv = Color3.toHSV(nc)
			updateFromHSV(nh, ns, nv)
		else
			hexBox.Text = Color3toHex(currentColor)
		end
	end)

	local cpConn = ColorPickerOverlay.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			local mp   = UserInputService:GetMouseLocation()
			local pos  = pickerFrame.AbsolutePosition
			local siz  = pickerFrame.AbsoluteSize
			if mp.X < pos.X or mp.X > pos.X+siz.X or mp.Y < pos.Y or mp.Y > pos.Y+siz.Y then
				pickerOpen = false
				pickerFrame.Visible = false
				ColorPickerOverlay.Visible = false
			end
		end
	end)
	table.insert(Library._connections, cpConn)

	local function openPicker(swatch)
		local abs  = swatch.AbsolutePosition
		local camSz = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		local px = abs.X + swatch.AbsoluteSize.X + 4
		local py = abs.Y - 4
		if px + totalW > camSz.X then px = abs.X - totalW - 4 end
		if py + totalH > camSz.Y then py = camSz.Y - totalH - 4 end
		if py < 0 then py = 4 end
		pickerFrame.Position = UDim2.new(0, px, 0, py)
		pickerOpen = true
		pickerFrame.Visible = true
		ColorPickerOverlay.Visible = true
		updateFromHSV(h, s, v)
	end

	return pickerFrame, openPicker, function() return currentColor end, function(nc)
		local nh, ns, nv = Color3.toHSV(nc)
		h, s, v = nh, ns, nv
		currentColor = nc
		svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position       = UDim2.new(s, 0, 1-v, 0)
		hueCursor.Position      = UDim2.new(0.5, 0, h, 0)
		previewSwatch.BackgroundColor3 = currentColor
		hexBox.Text             = Color3toHex(currentColor)
	end
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title    = cfg.Title    or "Punchy"
	local subtitle = cfg.SubTitle or ""
	local key      = cfg.Key      or Enum.KeyCode.Insert
	local center   = cfg.Center   ~= false
	local autoshow = cfg.AutoShow ~= false

	local keyRef = { v = key }
	Library._keyRef = keyRef

	local pos = center and UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2) or UDim2.new(0,60,0,60)

	local WinFrame = Create("Frame", {
		Name             = "Window",
		Size             = UDim2.new(0,WIN_W,0,WIN_H),
		Position         = pos,
		BackgroundColor3 = T.Bg1,
		BorderSizePixel  = 0,
		ClipsDescendants = false,
		Visible          = autoshow,
		Parent           = ScreenGui,
	}, {
		Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
		Create("UICorner", { CornerRadius = UDim.new(0,6) }),
	})

	Create("Frame", {
		Size             = UDim2.new(0,80,0,2),
		Position         = UDim2.new(0,20,0,0),
		BackgroundColor3 = T.Accent,
		BorderSizePixel  = 0, ZIndex = 2, Parent = WinFrame,
	}, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

	local Titlebar = Create("Frame", {
		Size             = UDim2.new(1,0,0,TITLE_H),
		BackgroundColor3 = T.Bg0,
		BorderSizePixel  = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0,6) }),
		Create("Frame", { Size=UDim2.new(1,0,0,8), Position=UDim2.new(0,0,1,-8), BackgroundColor3=T.Bg0, BorderSizePixel=0 }),
		Create("Frame", { Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=T.Border, BorderSizePixel=0 }),
	})

	MakeDraggable(WinFrame, Titlebar)
	BuildLogo(Titlebar, 12, 10)

	Create("TextLabel", {
		Size               = UDim2.new(0,80,1,0), Position = UDim2.new(0,30,0,0),
		BackgroundTransparency = 1, Text = title:upper(),
		TextColor3         = T.TextHi, TextSize = 12, Font = Enum.Font.GothamBlack,
		TextXAlignment     = Enum.TextXAlignment.Left, Parent = Titlebar,
	})

	if subtitle ~= "" then
		Create("Frame", { Size=UDim2.new(0,1,0,12), Position=UDim2.new(0,112,0.5,-6), BackgroundColor3=T.TextLo, BorderSizePixel=0, Parent=Titlebar })
		Create("TextLabel", {
			Size=UDim2.new(0,140,1,0), Position=UDim2.new(0,120,0,0),
			BackgroundTransparency=1, Text=subtitle,
			TextColor3=T.TextMid, TextSize=10, Font=Enum.Font.Gotham,
			TextXAlignment=Enum.TextXAlignment.Left, Parent=Titlebar,
		})
	end

	local keyBadge = Create("TextLabel", {
		Size               = UDim2.new(0,58,0,17), Position = UDim2.new(1,-88,0.5,-8),
		BackgroundColor3   = T.Bg2, BorderSizePixel = 0,
		Text               = keyRef.v.Name:upper(), TextColor3 = T.TextMid,
		TextSize           = 9, Font = Enum.Font.GothamMedium, Parent = Titlebar,
	}, { Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }), Create("UICorner",{ CornerRadius=UDim.new(0,3) }) })

	local CloseBtn = Create("TextButton", {
		Size             = UDim2.new(0,12,0,12), Position = UDim2.new(1,-20,0.5,-6),
		BackgroundColor3 = T.Red, BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Parent = Titlebar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

	CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(255,100,100) }, 0.1) end)
	CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { BackgroundColor3 = T.Red }, 0.1) end)

	local isAnimating = false
	local function closeWindow()
		if isAnimating then return end
		isAnimating = true
		local p = WinFrame.Position
		Tween(WinFrame, { Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset+10) }, 0.12)
		task.wait(0.13); WinFrame.Visible = false; WinFrame.Position = p; isAnimating = false
	end
	local function openWindow()
		if isAnimating then return end
		isAnimating = true
		local p = WinFrame.Position
		WinFrame.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset-8)
		WinFrame.Visible  = true
		Tween(WinFrame, { Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset+8) }, 0.15)
		task.wait(0.16); isAnimating = false
	end

	CloseBtn.MouseButton1Click:Connect(closeWindow)

	local TabBar = Create("Frame", {
		Size             = UDim2.new(1,0,0,TAB_H),
		Position         = UDim2.new(0,0,0,TITLE_H),
		BackgroundColor3 = T.Bg0, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UIListLayout", { FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", { PaddingLeft=UDim.new(0,6) }),
	})
	Create("Frame", { Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,TITLE_H-1),      BackgroundColor3=T.Border, BorderSizePixel=0, ZIndex=2, Parent=WinFrame })
	Create("Frame", { Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,TITLE_H+TAB_H-1), BackgroundColor3=T.Border, BorderSizePixel=0, ZIndex=2, Parent=WinFrame })

	local ContentArea = Create("ScrollingFrame", {
		Name                 = "ContentArea",
		Size                 = UDim2.new(1,0,0,CONTENT_H),
		Position             = UDim2.new(0,0,0,TITLE_H+TAB_H),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness   = 3,
		ScrollBarImageColor3 = T.BorderHi,
		ScrollingDirection   = Enum.ScrollingDirection.Y,
		CanvasSize           = UDim2.new(0,0,0,0),
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
		ClipsDescendants     = true,
		Parent               = WinFrame,
	})

	local StatusBar = Create("Frame", {
		Size             = UDim2.new(1,0,0,STATUS_H),
		Position         = UDim2.new(0,0,0,WIN_H-STATUS_H),
		BackgroundColor3 = T.Bg0, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius=UDim.new(0,6) }),
		Create("Frame", { Size=UDim2.new(1,0,0,8), BackgroundColor3=T.Bg0, BorderSizePixel=0 }),
		Create("Frame", { Size=UDim2.new(1,0,0,1), BackgroundColor3=T.Border, BorderSizePixel=0 }),
	})

	Create("Frame", { Size=UDim2.new(0,5,0,5), Position=UDim2.new(0,10,0.5,-2), BackgroundColor3=T.Green, BorderSizePixel=0, Parent=StatusBar }, { Create("UICorner",{CornerRadius=UDim.new(1,0)}) })
	Create("TextLabel", { Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,20,0,0), BackgroundTransparency=1, Text="INJECTED", TextColor3=T.Green, TextSize=9, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=StatusBar })

	local PingLabel = Create("TextLabel", {
		Size=UDim2.new(0,80,1,0), Position=UDim2.new(1,-85,0,0),
		BackgroundTransparency=1, Text="12ms · v3.1", TextColor3=T.TextLo,
		TextSize=9, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Right, Parent=StatusBar,
	})
	task.spawn(function()
		while task.wait(2.5) do
			if not WinFrame or not WinFrame.Parent then break end
			local ms = math.random(6,26)
			PingLabel.Text = ms.."ms · v3.1"
			PingLabel.TextColor3 = ms > 20 and Color3.fromRGB(210,160,50) or T.TextLo
		end
	end)

	local menuKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == keyRef.v then
			if WinFrame.Visible then closeWindow() else openWindow() end
		end
	end)
	table.insert(Library._connections, menuKeyConn)

	local Window = {
		_frame     = WinFrame,
		_tabBar    = TabBar,
		_content   = ContentArea,
		_tabs      = {},
		_activeTab = nil,
		_keyRef    = keyRef,
		_keyBadge  = keyBadge,
	}

	function Window:_switchTab(tab)
		for _, t in ipairs(self._tabs) do
			t._page.Visible = false
			Tween(t._btn, { TextColor3 = T.TextMid }, 0.12)
			t._indicator.BackgroundTransparency = 1
		end
		tab._page.Visible = true
		Tween(tab._btn, { TextColor3 = T.Accent }, 0.12)
		tab._indicator.BackgroundTransparency = 0
		self._activeTab = tab
	end

	function Window:AddTab(name)
		local tabW = math.max(64, #name*8+28)
		local btn = Create("TextButton", {
			Size = UDim2.new(0,tabW,1,0),
			BackgroundTransparency=1, Text=name,
			TextColor3=T.TextMid, TextSize=11,
			Font=Enum.Font.GothamMedium, BorderSizePixel=0,
			LayoutOrder=#TabBar:GetChildren(), Parent=TabBar,
		})
		local indicator = Create("Frame", {
			Size=UDim2.new(1,-16,0,2), Position=UDim2.new(0,8,1,-2),
			BackgroundColor3=T.Accent, BackgroundTransparency=1,
			BorderSizePixel=0, Parent=btn,
		}, { Create("UICorner",{ CornerRadius=UDim.new(1,0) }) })
		local page = Create("Frame", {
			Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
			BackgroundTransparency=1, Visible=false, Parent=ContentArea,
		}, {
			Create("UIListLayout",{ FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Top }),
			Create("UIPadding",{ PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,16) }),
		})
		local tab = { _btn=btn, _indicator=indicator, _page=page, _win=self, _leftCol=nil, _rightCol=nil }

		local function getOrMakeCol(side)
			local which = side=="Left" and "_leftCol" or "_rightCol"
			if not tab[which] then
				tab[which] = Create("Frame", {
					Size=UDim2.new(0.5,-4,0,0), AutomaticSize=Enum.AutomaticSize.Y,
					BackgroundTransparency=1, LayoutOrder=side=="Left" and 1 or 2, Parent=page,
				}, { Create("UIListLayout",{ SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8) }) })
			end
			return tab[which]
		end

		local function makeGroupbox(gbName, side)
			local col = getOrMakeCol(side)
			local box = Create("Frame", {
				Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
				BackgroundColor3=T.Bg2, BorderSizePixel=0,
				LayoutOrder=#col:GetChildren(), Parent=col,
			}, {
				Create("UIStroke",{ Color=T.Border, Thickness=1 }),
				Create("UICorner",{ CornerRadius=UDim.new(0,5) }),
			})
			local hdr = Create("Frame", {
				Size=UDim2.new(1,0,0,24), BackgroundColor3=T.Bg1, BorderSizePixel=0, Parent=box,
			}, {
				Create("UICorner",{ CornerRadius=UDim.new(0,5) }),
				Create("Frame",{ Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,1,-6), BackgroundColor3=T.Bg1, BorderSizePixel=0 }),
				Create("Frame",{ Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=T.Border, BorderSizePixel=0 }),
			})
			Create("TextLabel", {
				Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,12,0,0),
				BackgroundTransparency=1, Text=gbName:upper(),
				TextColor3=T.TextMid, TextSize=9, Font=Enum.Font.GothamBold,
				TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr,
			})
			local body = Create("Frame", {
				Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,24),
				AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, Parent=box,
			}, {
				Create("UIListLayout",{ SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,0) }),
				Create("UIPadding",{ PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,6) }),
			})

			local GB = { _body = body }

			function GB:AddToggle(k, c2)
				c2 = c2 or {}
				local text      = c2.Text    or k
				local default   = c2.Default ~= nil and c2.Default or false
				local cb        = c2.Callback or function() end
				local color     = c2.Color   or "accent"
				local accentCol = color=="purple" and T.Purple   or T.Accent
				local accentDim = color=="purple" and T.PurpleDim or T.AccentDim

				local row = Create("TextButton", {
					Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, Text="",
					BorderSizePixel=0, LayoutOrder=#body:GetChildren(), Parent=body,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,10) }) })
				Create("TextLabel", {
					Size=UDim2.new(1,-38,1,0), BackgroundTransparency=1,
					Text=text, TextColor3=T.TextHi, TextSize=11,
					Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
				})
				local pill = Create("Frame", {
					Size=UDim2.new(0,30,0,15), Position=UDim2.new(1,-30,0.5,-7),
					BackgroundColor3=T.ToggleOff, BorderSizePixel=0, Parent=row,
				}, {
					Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }),
					Create("UICorner",{ CornerRadius=UDim.new(1,0) }),
				})
				local thumb = Create("Frame", {
					Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,2,0.5,-5),
					BackgroundColor3=T.TextLo, BorderSizePixel=0, Parent=pill,
				}, { Create("UICorner",{ CornerRadius=UDim.new(1,0) }) })
				local value  = default
				local stroke = pill:FindFirstChildOfClass("UIStroke")
				local function apply(v2, silent)
					value = v2
					if v2 then
						Tween(pill,  { BackgroundColor3=accentDim }, 0.15)
						Tween(thumb, { Position=UDim2.new(0,18,0.5,-5), BackgroundColor3=accentCol }, 0.15)
						stroke.Color = accentCol
					else
						Tween(pill,  { BackgroundColor3=T.ToggleOff }, 0.15)
						Tween(thumb, { Position=UDim2.new(0,2,0.5,-5), BackgroundColor3=T.TextLo }, 0.15)
						stroke.Color = T.BorderHi
					end
					if not silent then pcall(cb, v2) end
				end
				apply(default, true)
				row.MouseButton1Click:Connect(function() apply(not value) end)
				row.MouseEnter:Connect(function() row.BackgroundColor3=T.Hover; row.BackgroundTransparency=0 end)
				row.MouseLeave:Connect(function() row.BackgroundTransparency=1 end)
				local To = {}
				To.SetValue = function(_, v2) apply(v2) end
				setmetatable(To, {
					__index    = function(_, k2) if k2=="Value" then return value end end,
					__newindex = function(_, k2, v2) if k2=="Value" then apply(v2) end end,
				})
				Library.Toggles[k] = To
				return To
			end

			function GB:AddSlider(k, c2)
				c2 = c2 or {}
				local text     = c2.Text     or k
				local min      = c2.Min      or 0
				local max      = c2.Max      or 100
				local default  = c2.Default  ~= nil and c2.Default or min
				local rounding = c2.Rounding ~= nil and c2.Rounding or 0
				local suffix   = c2.Suffix   or ""
				local color    = c2.Color    or "accent"
				local cb       = c2.Callback or function() end
				local ac       = color=="purple" and T.Purple or T.Accent
				local acDim    = color=="purple" and T.PurpleDim or T.AccentDim

				local wrap = Create("Frame", {
					Size=UDim2.new(1,0,0,46), BackgroundTransparency=1,
					LayoutOrder=#body:GetChildren(), Parent=body,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,10) }) })
				Create("TextLabel", {
					Size=UDim2.new(0.6,0,0,18), Position=UDim2.new(0,0,0,2),
					BackgroundTransparency=1, Text=text, TextColor3=T.TextHi,
					TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap,
				})
				local valLabel = Create("TextLabel", {
					Size=UDim2.new(0.4,0,0,18), Position=UDim2.new(0.6,0,0,2),
					BackgroundTransparency=1, Text=tostring(default)..suffix,
					TextColor3=ac, TextSize=11, Font=Enum.Font.GothamBold,
					TextXAlignment=Enum.TextXAlignment.Right, Parent=wrap,
				})
				local track = Create("Frame", {
					Size=UDim2.new(1,0,0,8), Position=UDim2.new(0,0,0,30),
					BackgroundColor3=T.Bg0, BorderSizePixel=0, ClipsDescendants=false, Parent=wrap,
				}, { Create("UIStroke",{ Color=T.Border, Thickness=1 }), Create("UICorner",{ CornerRadius=UDim.new(1,0) }) })
				local fillClip = Create("Frame", { Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true, Parent=track })
				Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=fillClip })
				local fill = Create("Frame", { Size=UDim2.new(0,0,1,0), BackgroundColor3=ac, BorderSizePixel=0, Parent=fillClip }, { Create("UICorner",{ CornerRadius=UDim.new(1,0) }) })
				local thumb = Create("TextButton", {
					Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,-7,0.5,-7),
					BackgroundColor3=T.TextHi, BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=6, Parent=track,
				}, { Create("UIStroke",{ Color=ac, Thickness=1.5 }), Create("UICorner",{ CornerRadius=UDim.new(1,0) }) })
				local value = default; local slDrag = false
				local function applyPct(pct)
					pct = math.clamp(pct, 0, 1)
					local raw = min + (max-min)*pct
					if rounding==0 then value=math.round(raw)
					else local m=10^rounding; value=math.floor(raw*m+0.5)/m end
					fill.Size      = UDim2.new(pct,0,1,0)
					thumb.Position = UDim2.new(pct,-7,0.5,-7)
					valLabel.Text  = tostring(value)..suffix
					pcall(cb, value)
				end
				applyPct((default-min)/(max-min))
				thumb.MouseButton1Down:Connect(function()
					slDrag=true
					Tween(thumb, { Size=UDim2.new(0,16,0,16), Position=UDim2.new(thumb.Position.X.Scale, thumb.Position.X.Offset-1, 0.5,-8) }, 0.08)
				end)
				track.InputBegan:Connect(function(inp)
					if inp.UserInputType==Enum.UserInputType.MouseButton1 then
						slDrag=true
						applyPct((UserInputService:GetMouseLocation().X-track.AbsolutePosition.X)/track.AbsoluteSize.X)
					end
				end)
				UserInputService.InputChanged:Connect(function(inp)
					if slDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then
						applyPct((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType==Enum.UserInputType.MouseButton1 and slDrag then
						slDrag=false
						Tween(thumb, { Size=UDim2.new(0,14,0,14), Position=UDim2.new(thumb.Position.X.Scale, thumb.Position.X.Offset+1, 0.5,-7) }, 0.08)
					end
				end)
				local S = {}
				S.SetValue = function(_, v2) applyPct((v2-min)/(max-min)) end
				setmetatable(S, {
					__index    = function(_, k2) if k2=="Value" then return value end end,
					__newindex = function(_, k2, v2) if k2=="Value" then applyPct((v2-min)/(max-min)) end end,
				})
				Library.Options[k] = S
				return S
			end

			function GB:AddDropdown(k, c2)
				c2 = c2 or {}
				local text    = c2.Text    or k
				local vals    = c2.Values  or {}
				local default = c2.Default or (vals[1] or "")
				local cb      = c2.Callback or function() end
				local multi   = c2.Multi   or false

				local wrap = Create("Frame", {
					Size=UDim2.new(1,0,0,52), BackgroundTransparency=1,
					ClipsDescendants=false, LayoutOrder=#body:GetChildren(), Parent=body,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,10) }) })
				Create("TextLabel", {
					Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,2),
					BackgroundTransparency=1, Text=text, TextColor3=T.TextMid,
					TextSize=10, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap,
				})
				local dropBtn = Create("TextButton", {
					Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,0,22),
					BackgroundColor3=T.Input, BorderSizePixel=0, Text="", Parent=wrap,
				}, { Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }), Create("UICorner",{ CornerRadius=UDim.new(0,3) }) })
				local selLabel = Create("TextLabel", {
					Size=UDim2.new(1,-24,1,0), Position=UDim2.new(0,8,0,0),
					BackgroundTransparency=1, Text=multi and "None" or default, TextColor3=T.TextHi,
					TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=dropBtn,
				})
				local arrowL = Create("Frame",{ Size=UDim2.new(0,6,0,1), Position=UDim2.new(1,-17,0.5,1), BackgroundColor3=T.TextMid, BorderSizePixel=0, Parent=dropBtn },{ Create("UICorner",{CornerRadius=UDim.new(1,0)}) })
				local arrowR = Create("Frame",{ Size=UDim2.new(0,6,0,1), Position=UDim2.new(1,-12,0.5,1), BackgroundColor3=T.TextMid, BorderSizePixel=0, Parent=dropBtn },{ Create("UICorner",{CornerRadius=UDim.new(1,0)}) })
				arrowL.Rotation=35; arrowR.Rotation=-35
				local listFrame = Create("Frame", {
					Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,1,3),
					BackgroundColor3=T.Bg3, BorderSizePixel=0, Visible=false, ZIndex=25, Parent=dropBtn,
				}, { Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }), Create("UICorner",{ CornerRadius=UDim.new(0,3) }), Create("UIListLayout",{ SortOrder=Enum.SortOrder.LayoutOrder }) })
				local value = multi and {} or default
				local open = false

				local function getDisplayText()
					if not multi then return value end
					local keys = {}
					for k2, _ in pairs(value) do table.insert(keys, k2) end
					if #keys == 0 then return "None"
					elseif #keys == 1 then return keys[1]
					else return #keys.." selected" end
				end

				local function buildList()
					for _, c3 in ipairs(listFrame:GetChildren()) do if c3:IsA("TextButton") then c3:Destroy() end end
					for _, v2 in ipairs(vals) do
						local isSelected = multi and value[v2] or v2 == value
						local opt = Create("TextButton", {
							Size=UDim2.new(1,0,0,24), BackgroundColor3=T.Bg3, BorderSizePixel=0,
							Text=v2, TextColor3=isSelected and T.Accent or T.TextHi,
							TextSize=11, Font=isSelected and Enum.Font.GothamMedium or Enum.Font.Gotham,
							ZIndex=26, Parent=listFrame,
						}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,10) }) })
						opt.TextXAlignment=Enum.TextXAlignment.Left
						if multi then
							local checkMark = Create("TextLabel", {
								Size=UDim2.new(0,18,1,0), Position=UDim2.new(1,-20,0,0),
								BackgroundTransparency=1, Text=isSelected and "✓" or "",
								TextColor3=T.Accent, TextSize=11, Font=Enum.Font.GothamBold,
								ZIndex=27, Parent=opt,
							})
							opt.MouseButton1Click:Connect(function()
								if value[v2] then value[v2]=nil else value[v2]=true end
								selLabel.Text = getDisplayText()
								pcall(cb, value)
								buildList()
							end)
						else
							opt.MouseButton1Click:Connect(function()
								value=v2; selLabel.Text=v2; open=false; listFrame.Visible=false
								pcall(cb,v2); buildList()
							end)
						end
						opt.MouseEnter:Connect(function() Tween(opt,{ BackgroundColor3=T.Hover },0.08) end)
						opt.MouseLeave:Connect(function() Tween(opt,{ BackgroundColor3=T.Bg3 },0.08) end)
					end
					listFrame.Size=UDim2.new(1,0,0,#vals*24)
				end
				buildList()
				dropBtn.MouseButton1Click:Connect(function()
					open=not open; listFrame.Visible=open
					Tween(arrowL,{ Rotation=open and -35 or 35 },0.1)
					Tween(arrowR,{ Rotation=open and 35 or -35 },0.1)
				end)
				dropBtn.MouseEnter:Connect(function() Tween(dropBtn,{ BackgroundColor3=T.Hover },0.1) end)
				dropBtn.MouseLeave:Connect(function() Tween(dropBtn,{ BackgroundColor3=T.Input },0.1) end)
				local D = { Values=vals }
				D.SetValue = function(_, v2)
					if multi then
						if type(v2)=="table" then value=v2 else value[v2]=true end
					else value=v2 end
					selLabel.Text=getDisplayText(); pcall(cb,value); buildList()
				end
				D.GetValue = function(_) return value end
				setmetatable(D, { __index=function(_,k2) if k2=="Value" then return value end end, __newindex=function(_,k2,v2) if k2=="Value" then D:SetValue(v2) end end })
				Library.Options[k] = D
				return D
			end

			function GB:AddColorPicker(k, c2)
				c2 = c2 or {}
				local text    = c2.Text    or k
				local default = c2.Default or T.Accent
				local cb      = c2.Callback or function() end

				local row = Create("Frame", {
					Size=UDim2.new(1,0,0,28), BackgroundTransparency=1,
					LayoutOrder=#body:GetChildren(), Parent=body,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,10) }) })
				Create("TextLabel", {
					Size=UDim2.new(1,-28,1,0), BackgroundTransparency=1,
					Text=text, TextColor3=T.TextHi, TextSize=11,
					Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
				})
				local swatch = Create("TextButton", {
					Size=UDim2.new(0,20,0,14), Position=UDim2.new(1,-20,0.5,-7),
					BackgroundColor3=default, BorderSizePixel=0, Text="", Parent=row,
				}, { Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }), Create("UICorner",{ CornerRadius=UDim.new(0,3) }) })

				local currentColor = default
				local _, openPicker, getColor, setPickerColor = MakeColorPicker(k, default, function(nc)
					currentColor = nc
					swatch.BackgroundColor3 = nc
					pcall(cb, nc)
				end, ColorPickerOverlay)

				swatch.MouseButton1Click:Connect(function()
					openPicker(swatch)
				end)

				local CP = { _val = default }
				CP.SetValue = function(_, v2)
					currentColor = v2
					swatch.BackgroundColor3 = v2
					setPickerColor(v2)
					pcall(cb, v2)
				end
				setmetatable(CP, {
					__index    = function(_, k2) if k2=="Value" then return currentColor end end,
					__newindex = function(_, k2, v2) if k2=="Value" then CP:SetValue(v2) end end,
				})
				Library.Options[k] = CP
				return CP
			end

			function GB:AddKeybind(k, c2)
				c2 = c2 or {}
				local text    = c2.Text    or k
				local default = c2.Default or Enum.KeyCode.Unknown
				local mode    = c2.Mode    or "toggle"
				local cb      = c2.Callback or function() end
				local holdCb  = c2.HoldCallback or function() end

				local row = Create("TextButton", {
					Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, Text="",
					BorderSizePixel=0, LayoutOrder=#body:GetChildren(), Parent=body,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,10) }) })
				Create("TextLabel", {
					Size=UDim2.new(1,-64,1,0), BackgroundTransparency=1,
					Text=text, TextColor3=T.TextHi, TextSize=11,
					Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
				})
				local badge = Create("TextLabel", {
					Size=UDim2.new(0,56,0,17), Position=UDim2.new(1,-56,0.5,-8),
					BackgroundColor3=T.Input, BorderSizePixel=0,
					Text="["..default.Name:upper().."]", TextColor3=T.TextMid,
					TextSize=9, Font=Enum.Font.GothamMedium, Parent=row,
				}, { Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }), Create("UICorner",{ CornerRadius=UDim.new(0,3) }) })
				local value=default; local binding=false

				local kblEntry = Create("Frame", {
					Size=UDim2.new(1,0,0,22),
					BackgroundTransparency=1,
					BorderSizePixel=0,
					LayoutOrder=#kblBody:GetChildren(),
					Parent=kblBody,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,8) }) })
				local kblLabel = Create("TextLabel", {
					Size=UDim2.new(0.6,0,1,0),
					BackgroundTransparency=1,
					Text=text,
					TextColor3=T.TextMid,
					TextSize=9,
					Font=Enum.Font.Gotham,
					TextXAlignment=Enum.TextXAlignment.Left,
					Parent=kblEntry,
				})
				local kblKey = Create("TextLabel", {
					Size=UDim2.new(0.4,0,1,0),
					Position=UDim2.new(0.6,0,0,0),
					BackgroundTransparency=1,
					Text="["..default.Name:upper().."]",
					TextColor3=T.TextLo,
					TextSize=9,
					Font=Enum.Font.GothamMedium,
					TextXAlignment=Enum.TextXAlignment.Right,
					Parent=kblEntry,
				})
				local kblState = Create("TextLabel", {
					Size=UDim2.new(1,0,0,10),
					BackgroundTransparency=1,
					Text="",
					TextColor3=T.TextMid,
					TextSize=8,
					Font=Enum.Font.GothamBold,
					TextXAlignment=Enum.TextXAlignment.Right,
					Parent=kblEntry,
				})

				-- FIX: store as a plain Lua table instead of setting properties on a
				-- Roblox Instance (which throws "X is not a valid member of Frame").
				Library._kblEntries[k] = {
					frame      = kblEntry,
					keyLabel   = kblKey,
					stateLabel = kblState,
				}
				refreshKBL()

				row.MouseButton1Click:Connect(function()
					binding=true; badge.Text="[ . . . ]"; badge.TextColor3=T.Accent
					Tween(badge,{ BackgroundColor3=T.Bg3 },0.1)
				end)
				row.MouseEnter:Connect(function() row.BackgroundColor3=T.Hover; row.BackgroundTransparency=0 end)
				row.MouseLeave:Connect(function() row.BackgroundTransparency=1 end)
				UserInputService.InputBegan:Connect(function(inp, gpe)
					if binding and not gpe and inp.UserInputType==Enum.UserInputType.Keyboard then
						if inp.KeyCode == Enum.KeyCode.Escape then
							binding=false; badge.Text="["..value.Name:upper().."]"; badge.TextColor3=T.TextMid
							Tween(badge,{ BackgroundColor3=T.Input },0.1); return
						end
						binding=false; value=inp.KeyCode
						badge.Text="["..inp.KeyCode.Name:upper().."]"
						badge.TextColor3=T.TextMid
						kblKey.Text="["..inp.KeyCode.Name:upper().."]"
						Tween(badge,{ BackgroundColor3=T.Input },0.1)
						if k=="MenuKey" then keyRef.v=inp.KeyCode; keyBadge.Text=inp.KeyCode.Name:upper() end
						Library:RegisterBind(k, value, mode, cb, holdCb)
						pcall(cb, value)
					end
				end)
				Library:RegisterBind(k, default, mode, cb, holdCb)
				local KB = {}
				KB.SetValue = function(_, v2)
					value=v2; badge.Text="["..v2.Name:upper().."]"; kblKey.Text="["..v2.Name:upper().."]"
					if k=="MenuKey" then keyRef.v=v2; keyBadge.Text=v2.Name:upper() end
					Library:SetBind(k, v2)
				end
				setmetatable(KB, { __index=function(_,k2) if k2=="Value" then return value end end, __newindex=function(_,k2,v2) if k2=="Value" then KB:SetValue(v2) end end })
				Library.Options[k] = KB
				return KB
			end

			function GB:AddTextbox(k, c2)
				c2 = c2 or {}
				local text         = c2.Text          or k
				local default      = c2.Default        or ""
				local placeholder  = c2.Placeholder    or "Enter value..."
				local clearOnFocus = c2.ClearOnFocus   ~= false
				local cb           = c2.Callback       or function() end

				local wrap = Create("Frame", {
					Size=UDim2.new(1,0,0,52), BackgroundTransparency=1,
					LayoutOrder=#body:GetChildren(), Parent=body,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,10) }) })
				Create("TextLabel", {
					Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,2),
					BackgroundTransparency=1, Text=text, TextColor3=T.TextMid,
					TextSize=10, Font=Enum.Font.GothamMedium,
					TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap,
				})
				local inputBox = Create("TextBox", {
					Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,22),
					BackgroundColor3=T.Input, BorderSizePixel=0,
					Text=default, PlaceholderText=placeholder,
					TextColor3=T.TextHi, PlaceholderColor3=T.TextLo,
					TextSize=11, Font=Enum.Font.Gotham,
					TextXAlignment=Enum.TextXAlignment.Left,
					ClearTextOnFocus=clearOnFocus,
					Parent=wrap,
				}, {
					Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }),
					Create("UICorner",{ CornerRadius=UDim.new(0,3) }),
					Create("UIPadding",{ PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,6) }),
				})
				local stroke = inputBox:FindFirstChildOfClass("UIStroke")
				inputBox.Focused:Connect(function()    Tween(stroke,{ Color=T.Accent },0.12)  end)
				inputBox.FocusLost:Connect(function(enter)
					Tween(stroke,{ Color=T.BorderHi },0.12)
					pcall(cb, inputBox.Text, enter)
				end)
				local TX = {}
				TX.SetValue = function(_, v2) inputBox.Text = tostring(v2) end
				setmetatable(TX, {
					__index    = function(_,k2) if k2=="Value" then return inputBox.Text end end,
					__newindex = function(_,k2,v2) if k2=="Value" then inputBox.Text=tostring(v2) end end,
				})
				Library.Options[k] = TX
				return TX
			end

			function GB:AddButton(c2)
				c2 = c2 or {}
				local text = c2.Text     or "Button"
				local cb   = c2.Callback or function() end
				local wrap = Create("Frame", {
					Size=UDim2.new(1,0,0,34), BackgroundTransparency=1,
					LayoutOrder=#body:GetChildren(), Parent=body,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4) }) })
				local btn = Create("TextButton", {
					Size=UDim2.new(1,0,1,0), BackgroundColor3=T.Bg3, BorderSizePixel=0,
					Text=text, TextColor3=T.TextHi, TextSize=11, Font=Enum.Font.GothamMedium, Parent=wrap,
				}, { Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }), Create("UICorner",{ CornerRadius=UDim.new(0,4) }) })
				btn.MouseButton1Click:Connect(function()
					Tween(btn,{ BackgroundColor3=T.AccentDim },0.08)
					task.wait(0.14)
					Tween(btn,{ BackgroundColor3=T.Bg3 },0.14)
					pcall(cb)
				end)
				btn.MouseEnter:Connect(function() Tween(btn,{ BackgroundColor3=T.Hover },0.1) end)
				btn.MouseLeave:Connect(function() Tween(btn,{ BackgroundColor3=T.Bg3 },0.1) end)
			end

			function GB:AddLabel(text, id)
				local lbl = Create("TextLabel", {
					Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, Text=text,
					TextColor3=T.TextMid, TextSize=10, Font=Enum.Font.Gotham,
					TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
					LayoutOrder=#body:GetChildren(), Parent=body,
				}, { Create("UIPadding",{ PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,10) }) })
				if id then
					local L = {}
					L.SetText = function(_, t) lbl.Text = t end
					L.SetColor = function(_, c3) lbl.TextColor3 = c3 end
					Library.Options[id] = L
					return L
				end
			end

			function GB:AddDivider()
				local wrap = Create("Frame", {
					Size=UDim2.new(1,0,0,10), BackgroundTransparency=1,
					LayoutOrder=#body:GetChildren(), Parent=body,
				})
				Create("Frame", {
					Size=UDim2.new(1,-22,0,1), Position=UDim2.new(0,11,0.5,0),
					BackgroundColor3=T.Border, BorderSizePixel=0, Parent=wrap,
				})
			end

			function GB:BuildConfigList(folder)
				folder = folder or "Punchy"
				local profileNames = Library:GetProfiles(folder)

				local nameBox = self:AddTextbox("__cfg_name", {
					Text        = "Config Name",
					Default     = "default",
					Placeholder = "Enter config name...",
					ClearOnFocus = false,
				})

				-- FIX: forward-declare profileDropdown so the Save button closure can
				-- reference it after it is assigned below (Lua local scoping rule).
				local profileDropdown

				self:AddButton({
					Text = "Save Config",
					Callback = function()
						Library:SaveConfig(nameBox.Value, folder)
						-- profileDropdown is assigned by the time any button is clicked
						if profileDropdown then
							profileDropdown:SetValue(nameBox.Value)
						end
					end,
				})

				local function getProfiles()
					local list = Library:GetProfiles(folder)
					if #list == 0 then list = { "No configs found" } end
					return list
				end

				-- Assign (not re-declare) so the closure above sees the value
				profileDropdown = self:AddDropdown("__cfg_profile", {
					Text   = "Load Profile",
					Values = getProfiles(),
					Default = profileNames[1] or "",
				})

				self:AddButton({
					Text = "Load Config",
					Callback = function()
						local sel = profileDropdown.Value
						if sel and sel ~= "No configs found" then
							Library:LoadConfig(sel, folder)
						end
					end,
				})

				self:AddButton({
					Text = "Delete Config",
					Callback = function()
						local sel = profileDropdown.Value
						if sel and sel ~= "No configs found" then
							Library:DeleteConfig(sel, folder)
							local updated = getProfiles()
							profileDropdown.Values = updated
							profileDropdown:SetValue(updated[1] or "")
						end
					end,
				})

				self:AddButton({
					Text = "Refresh List",
					Callback = function()
						local updated = getProfiles()
						profileDropdown.Values = updated
						profileDropdown:SetValue(updated[1] or "")
					end,
				})
			end

			return GB
		end

		function tab:AddLeftGroupbox(name)  return makeGroupbox(name, "Left")  end
		function tab:AddRightGroupbox(name) return makeGroupbox(name, "Right") end

		btn.MouseButton1Click:Connect(function() self:_switchTab(tab) end)
		btn.MouseEnter:Connect(function() if self._activeTab~=tab then Tween(btn,{ TextColor3=T.TextHi },0.1) end end)
		btn.MouseLeave:Connect(function() if self._activeTab~=tab then Tween(btn,{ TextColor3=T.TextMid },0.1) end end)
		table.insert(self._tabs, tab)
		if #self._tabs==1 then self:_switchTab(tab) end
		return tab
	end

	function Window:AddESPPreview()
		local espColor  = T.Accent
		local charClone = nil
		local cloneHRP  = nil
		local partRelCF = {}
		local rotAngle  = 0
		local bindMap   = nil
		local tickCount = 0

		local PW, PH = 148, 270
		local previewFrame = Create("Frame", {
			Name             = "ESPPreview",
			Size             = UDim2.new(0,PW,0,PH),
			Position         = UDim2.new(1,14,0,0),
			BackgroundColor3 = T.Bg1,
			BorderSizePixel  = 0, Visible = true, Parent = WinFrame,
		}, { Create("UIStroke",{ Color=T.BorderHi, Thickness=1 }), Create("UICorner",{ CornerRadius=UDim.new(0,6) }) })

		Create("Frame", {
			Size=UDim2.new(0,56,0,2), Position=UDim2.new(0,10,0,0),
			BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=2, Parent=previewFrame,
		}, { Create("UICorner",{ CornerRadius=UDim.new(1,0) }) })

		local hdr = Create("Frame", {
			Size=UDim2.new(1,0,0,28), BackgroundColor3=T.Bg0, BorderSizePixel=0, Parent=previewFrame,
		}, {
			Create("UICorner",{ CornerRadius=UDim.new(0,6) }),
			Create("Frame",{ Size=UDim2.new(1,0,0,8), Position=UDim2.new(0,0,1,-8), BackgroundColor3=T.Bg0, BorderSizePixel=0 }),
			Create("Frame",{ Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=T.Border, BorderSizePixel=0 }),
		})
		Create("TextLabel", {
			Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0),
			BackgroundTransparency=1, Text="ESP PREVIEW",
			TextColor3=T.TextMid, TextSize=9, Font=Enum.Font.GothamBold,
			TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr,
		})
		local accentDot = Create("Frame", {
			Size=UDim2.new(0,6,0,6), Position=UDim2.new(1,-12,0.5,-3),
			BackgroundColor3=T.Accent, BorderSizePixel=0, Parent=hdr,
		}, { Create("UICorner",{ CornerRadius=UDim.new(1,0) }) })
		MakeDraggable(previewFrame, hdr)

		local VP_H = PH - 28
		local vp = Create("ViewportFrame", {
			Size=UDim2.new(1,0,0,VP_H), Position=UDim2.new(0,0,0,28),
			BackgroundColor3=Color3.fromRGB(7,6,13),
			Ambient=Color3.fromRGB(110,105,140),
			LightDirection=Vector3.new(-0.6,-1,-0.5),
			LightColor=Color3.fromRGB(255,248,235),
			ClipsDescendants=true, Parent=previewFrame,
		}, { Create("UICorner",{ CornerRadius=UDim.new(0,6) }) })
		local wm = Instance.new("WorldModel"); wm.Parent = vp
		local vpCam = Instance.new("Camera"); vpCam.FieldOfView=42; vpCam.Parent=vp; vp.CurrentCamera=vpCam

		local function setupClone()
			if charClone then
				pcall(function() charClone:Destroy() end)
				charClone=nil; cloneHRP=nil; partRelCF={}
			end
			local char = LocalPlayer.Character
			if not char then return false end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return false end
			local ok, clone = pcall(function() return char:Clone() end)
			if not ok or not clone then return false end
			charClone = clone
			pcall(function() charClone.Name = "PunchyPreviewChar" end)
			for _, d in ipairs(charClone:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript")
				or d:IsA("Animator") or d:IsA("Animation") or d:IsA("BodyMover")
				or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("Highlight")
				or d:IsA("SelectionBox") or d:IsA("ParticleEmitter") then
					pcall(function() d:Destroy() end)
				end
			end
			cloneHRP = charClone:FindFirstChild("HumanoidRootPart")
			if not cloneHRP then pcall(function() charClone:Destroy() end); charClone=nil; return false end
			local hum = charClone:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				hum.HealthDisplayType   = Enum.HumanoidHealthDisplayType.AlwaysOff
			end
			for _, p in ipairs(charClone:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored=true; p.CanCollide=false; p.CastShadow=false
					if p~=cloneHRP then
						partRelCF[p] = cloneHRP.CFrame:ToObjectSpace(p.CFrame)
					end
				end
			end
			cloneHRP.CFrame = CFrame.new(0,0,0)
			for p, rel in pairs(partRelCF) do
				if p and p.Parent then p.CFrame=CFrame.new(0,0,0)*rel end
			end
			charClone.Parent = wm
			local charH = 5; local cy = charH*0.43
			vpCam.CFrame = CFrame.new(Vector3.new(0,cy,charH*1.3), Vector3.new(0,cy,0))
			return true
		end

		task.spawn(function()
			local success = false
			for i=1,25 do
				local ok, result = pcall(setupClone)
				if ok and result then success = true; break end
				task.wait(0.4)
			end
		end)

		local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
			task.spawn(function()
				char:WaitForChild("HumanoidRootPart", 10)
				task.wait(0.5)
				pcall(setupClone)
			end)
		end)
		table.insert(Library._connections, charAddedConn)

		local playerName = LocalPlayer.Name

		local nameTag = Create("TextLabel", {
			Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4),
			BackgroundTransparency=1, Text=playerName,
			TextColor3=espColor, TextSize=9, Font=Enum.Font.GothamBold,
			TextXAlignment=Enum.TextXAlignment.Center,
			TextStrokeTransparency=0.4, TextStrokeColor3=Color3.new(0,0,0),
			ZIndex=12, Visible=true, Parent=vp,
		})

		local distTag = Create("TextLabel", {
			Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,0,18),
			BackgroundTransparency=1, Text="42m",
			TextColor3=T.TextMid, TextSize=8, Font=Enum.Font.Gotham,
			TextXAlignment=Enum.TextXAlignment.Center,
			TextStrokeTransparency=0.5, ZIndex=12, Visible=true, Parent=vp,
		})

		local weaponTag = Create("TextLabel", {
			Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,0,28),
			BackgroundTransparency=1, Text="AK-47",
			TextColor3=T.TextMid, TextSize=7, Font=Enum.Font.Gotham,
			TextXAlignment=Enum.TextXAlignment.Center,
			TextStrokeTransparency=0.5, ZIndex=12, Visible=false, Parent=vp,
		})

		local BX,BW,BY,BH = 0.18,0.64,0.155,0.800
		local boxFrame = Create("Frame", {
			Size=UDim2.new(BW,0,BH,0), Position=UDim2.new(BX,0,BY,0),
			BackgroundTransparency=1, BorderSizePixel=0, ZIndex=8, Visible=true, Parent=vp,
		})
		local boxStroke = Create("UIStroke",{ Color=espColor, Thickness=1.5, Parent=boxFrame })

		local fillFrame = Create("Frame", {
			Size=UDim2.new(1,0,1,0), BackgroundColor3=espColor,
			BackgroundTransparency=0.8, BorderSizePixel=0, ZIndex=7, Visible=false, Parent=boxFrame,
		})

		local hbBg = Create("Frame", {
			Size=UDim2.new(0,4,1,-4), Position=UDim2.new(0,-9,0,2),
			BackgroundColor3=Color3.fromRGB(22,7,7), BorderSizePixel=0, ZIndex=8, Visible=true, Parent=boxFrame,
		}, { Create("UICorner",{ CornerRadius=UDim.new(0,2) }) })
		local hbFill = Create("Frame", {
			Size=UDim2.new(1,0,0.72,0), Position=UDim2.new(0,0,0.28,0),
			BackgroundColor3=T.Green, BorderSizePixel=0, Parent=hbBg,
		}, { Create("UICorner",{ CornerRadius=UDim.new(0,2) }) })

		local armorBg = Create("Frame", {
			Size=UDim2.new(0,4,1,-4), Position=UDim2.new(1,5,0,2),
			BackgroundColor3=Color3.fromRGB(8,18,30), BorderSizePixel=0, ZIndex=8, Visible=false, Parent=boxFrame,
		}, { Create("UICorner",{ CornerRadius=UDim.new(0,2) }) })
		local armorFill = Create("Frame", {
			Size=UDim2.new(1,0,0.55,0), Position=UDim2.new(0,0,0.45,0),
			BackgroundColor3=Color3.fromRGB(80,160,240), BorderSizePixel=0, Parent=armorBg,
		}, { Create("UICorner",{ CornerRadius=UDim.new(0,2) }) })

		local snapLine = Create("Frame", {
			Size=UDim2.new(0,1,0,0),
			Position=UDim2.new(0.5,0,1,0),
			AnchorPoint=Vector2.new(0.5,1),
			BackgroundColor3=espColor,
			BackgroundTransparency=0.4,
			BorderSizePixel=0,
			ZIndex=6,
			Visible=false,
			Parent=vp,
		})

		local skelFrame = Create("Frame", { Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=9, Visible=true, Parent=boxFrame })
		local skelLines = {}

		local function SkelLine(x1,y1,x2,y2)
			local dx,dy=x2-x1,y2-y1; local len=math.sqrt(dx*dx+dy*dy)
			if len<1 then return end
			local angle=math.deg(math.atan2(dy,dx)); local cx2,cy2=(x1+x2)/2,(y1+y2)/2
			local bw = boxFrame.AbsoluteSize.X > 0 and boxFrame.AbsoluteSize.X or 82
			local bh = boxFrame.AbsoluteSize.Y > 0 and boxFrame.AbsoluteSize.Y or 190
			local line = Create("Frame", {
				Size=UDim2.new(0,len,0,1.5), Position=UDim2.new(0,cx2-len/2,0,cy2-0.75),
				Rotation=angle, BackgroundColor3=espColor, BorderSizePixel=0, ZIndex=9, Parent=skelFrame,
			}, { Create("UICorner",{ CornerRadius=UDim.new(1,0) }) })
			table.insert(skelLines, line)
		end

		SkelLine(41,6,41,26)
		SkelLine(41,26,16,34); SkelLine(41,26,66,34)
		SkelLine(16,34,10,82); SkelLine(10,82,8,116)
		SkelLine(66,34,72,82); SkelLine(72,82,74,116)
		SkelLine(41,26,41,100)
		SkelLine(41,100,26,107); SkelLine(41,100,56,107)
		SkelLine(26,107,24,152); SkelLine(24,152,22,170)
		SkelLine(56,107,58,152); SkelLine(58,152,60,170)

		local headDot = Create("Frame", {
			Size=UDim2.new(0,10,0,10),
			Position=UDim2.new(0,36,0,0),
			BackgroundTransparency=1,
			BorderSizePixel=0,
			ZIndex=9,
			Visible=true,
			Parent=skelFrame,
		}, {
			Create("UICorner",{ CornerRadius=UDim.new(1,0) }),
			Create("UIStroke",{ Color=espColor, Thickness=1.5 }),
		})

		local chamHL = Instance.new("Highlight")
		chamHL.FillTransparency=0.5; chamHL.OutlineTransparency=0.3
		chamHL.FillColor=espColor; chamHL.OutlineColor=espColor
		chamHL.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; chamHL.Enabled=false
		-- FIX: parent the Highlight to the WorldModel first so it is valid,
		-- then set Adornee once the clone is ready.
		chamHL.Parent = wm
		task.delay(0.5, function()
			if charClone and charClone.Parent then
				chamHL.Adornee = charClone
			end
		end)

		local function updateColor(col)
			espColor=col; accentDot.BackgroundColor3=col; boxStroke.Color=col
			fillFrame.BackgroundColor3=col; nameTag.TextColor3=col
			chamHL.FillColor=col; chamHL.OutlineColor=col; snapLine.BackgroundColor3=col
			for _, l in ipairs(skelLines) do if l and l.Parent then l.BackgroundColor3=col end end
			if headDot then
				local st = headDot:FindFirstChildOfClass("UIStroke")
				if st then st.Color=col end
			end
		end

		local distSim = 0
		local rotConn = RunService.Heartbeat:Connect(function(dt)
			rotAngle = rotAngle + dt*42
			distSim  = distSim  + dt*0.4
			local simDist = math.floor(35 + math.sin(distSim)*22)
			distTag.Text  = simDist.."m"
			if cloneHRP and cloneHRP.Parent then
				local newCF = CFrame.Angles(0, math.rad(rotAngle), 0)
				pcall(function()
					cloneHRP.CFrame = newCF
					for p, rel in pairs(partRelCF) do
						if p and p.Parent then p.CFrame=newCF*rel end
					end
				end)
			end
			tickCount = tickCount + 1
			if tickCount >= 5 and bindMap then
				tickCount = 0
				local bm = bindMap
				local function tog(id) return bm[id] and Library.Toggles[bm[id]] and Library.Toggles[bm[id]].Value end
				local function opt(id) return bm[id] and Library.Options[bm[id]] and Library.Options[bm[id]].Value end

				local en      = tog("enabled")
				local col     = opt("color")
				local filled  = tog("filled")
				local fillT   = opt("fillTrans")
				local skel    = tog("skeleton")
				local headESP = tog("headESP")
				local chamsEn = tog("chams")
				local chamsC  = opt("chamsColor")
				local chamsT  = opt("chamsTrans")
				local armorEn = tog("armor")
				local snapEn  = tog("snapline")
				local weapEn  = tog("weapon")

				if col then updateColor(col) end

				local show = en ~= false and en ~= nil
				boxFrame.Visible = show
				hbBg.Visible     = show
				nameTag.Visible  = show
				distTag.Visible  = show

				if filled ~= nil then fillFrame.Visible = filled end
				if fillT  ~= nil then fillFrame.BackgroundTransparency = fillT/100 end
				if skel   ~= nil then skelFrame.Visible = skel end
				if headESP ~= nil then headDot.Visible = headESP end
				if armorEn ~= nil then armorBg.Visible = armorEn end
				if snapEn  ~= nil then snapLine.Visible = snapEn end
				if weapEn  ~= nil then weaponTag.Visible = weapEn end

				if chamsEn ~= nil then
					chamHL.Enabled = chamsEn
					if chamsC then chamHL.FillColor=chamsC; chamHL.OutlineColor=chamsC end
					if chamsT then chamHL.FillTransparency=chamsT/100 end
					if chamsEn and charClone and charClone.Parent and not chamHL.Adornee then
						chamHL.Adornee = charClone
					end
				end
			end
		end)
		table.insert(Library._connections, rotConn)

		local Preview = {}

		function Preview:BindKeys(map)
			bindMap = map
		end

		function Preview:Refresh()
			if not bindMap then return end
			tickCount = 99
		end

		function Preview:SetVisible(v)   previewFrame.Visible = v end
		function Preview:SetColor(color) updateColor(color) end

		function Preview:SetBox(en, filled, trans)
			boxFrame.Visible = en
			hbBg.Visible     = en
			nameTag.Visible  = en
			distTag.Visible  = en
			if filled ~= nil then fillFrame.Visible = filled end
			if trans  ~= nil then fillFrame.BackgroundTransparency = trans end
		end

		function Preview:SetFilled(en, trans)
			fillFrame.Visible = en
			if trans ~= nil then fillFrame.BackgroundTransparency = trans end
		end

		function Preview:SetSkeleton(en) skelFrame.Visible = en end

		function Preview:SetChams(en, color, trans)
			chamHL.Enabled = en
			if color then updateColor(color) end
			if trans  then chamHL.FillTransparency = trans end
			if en and charClone and charClone.Parent and not chamHL.Adornee then
				chamHL.Adornee = charClone
			end
		end

		return Preview
	end

	function Window:Unload()
		for _, c in ipairs(Library._connections) do pcall(function() c:Disconnect() end) end
		Library._connections = {}
		for _, fn in ipairs(Library._cleanups) do pcall(fn) end
		Library._cleanups = {}
		Library._binds    = {}
		Library._kblEntries = {}
		pcall(function() Library._screenGui:Destroy() end)
		pcall(function() Library._notifGui:Destroy() end)
	end

	Library._window = Window
	return Window
end

function Library:Unload()
	if self._window then self._window:Unload() end
end

return Library

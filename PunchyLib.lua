--[[
    PunchyLib v3.0
--]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local WIN_W     = 430
local TITLE_H   = 32
local TAB_H     = 30
local STATUS_H  = 22
local CONTENT_H = 360
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

local T = {
	Bg0         = Color3.fromRGB(10,  10,  12),
	Bg1         = Color3.fromRGB(15,  15,  18),
	Bg2         = Color3.fromRGB(20,  20,  24),
	Bg3         = Color3.fromRGB(28,  28,  34),
	Input       = Color3.fromRGB(12,  12,  15),
	Hover       = Color3.fromRGB(32,  32,  40),
	Accent      = Color3.fromRGB(210, 100, 130),
	AccentDim   = Color3.fromRGB(150, 65,  90),
	AccentGlow  = Color3.fromRGB(240, 130, 160),
	Purple      = Color3.fromRGB(155, 120, 210),
	PurpleDim   = Color3.fromRGB(100, 75,  155),
	TextHi      = Color3.fromRGB(238, 235, 230),
	TextMid     = Color3.fromRGB(140, 138, 148),
	TextLo      = Color3.fromRGB(55,  53,  65),
	Border      = Color3.fromRGB(30,  30,  38),
	BorderHi    = Color3.fromRGB(50,  48,  62),
	ToggleOff   = Color3.fromRGB(32,  32,  42),
	Green       = Color3.fromRGB(52,  180, 80),
	Red         = Color3.fromRGB(220, 70,  70),
}

local Library   = {}
Library.__index = Library
Library.Toggles = {}
Library.Options = {}
Library._connections = {}
getgenv().PunchyLib = Library

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

local function BuildLogo(parent, x, y)
	local bars = { {12, 12}, {8, 8}, {5, 5} }
	for i, b in ipairs(bars) do
		Create("Frame", {
			Size = UDim2.new(0, 3, 0, b[1]),
			Position = UDim2.new(0, x + (i-1)*5, 0, y + (12 - b[2])),
			BackgroundColor3 = i == 1 and T.AccentGlow or i == 2 and T.Accent or T.AccentDim,
			BorderSizePixel = 0, Parent = parent,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 1) }) })
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

	local pos = center and UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) or UDim2.new(0, 60, 0, 60)

	local WinFrame = Create("Frame", {
		Name = "Window", Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = pos,
		BackgroundColor3 = T.Bg1, BorderSizePixel = 0, ClipsDescendants = false,
		Visible = autoshow, Parent = ScreenGui,
	}, {
		Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
	})

	Create("Frame", {
		Size = UDim2.new(0, 80, 0, 2), Position = UDim2.new(0, 20, 0, 0),
		BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 2, Parent = WinFrame,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local Titlebar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, TITLE_H), BackgroundColor3 = T.Bg0,
		BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = T.Bg0, BorderSizePixel = 0 }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.Border, BorderSizePixel = 0 }),
	})

	MakeDraggable(WinFrame, Titlebar)
	BuildLogo(Titlebar, 12, 10)

	Create("TextLabel", {
		Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(0, 30, 0, 0),
		BackgroundTransparency = 1, Text = title:upper(),
		TextColor3 = T.TextHi, TextSize = 12, Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = Titlebar,
	})

	if subtitle ~= "" then
		Create("Frame", { Size = UDim2.new(0, 1, 0, 12), Position = UDim2.new(0, 112, 0.5, -6), BackgroundColor3 = T.TextLo, BorderSizePixel = 0, Parent = Titlebar })
		Create("TextLabel", {
			Size = UDim2.new(0, 140, 1, 0), Position = UDim2.new(0, 120, 0, 0),
			BackgroundTransparency = 1, Text = subtitle,
			TextColor3 = T.TextMid, TextSize = 10, Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = Titlebar,
		})
	end

	local keyBadge = Create("TextLabel", {
		Size = UDim2.new(0, 58, 0, 17), Position = UDim2.new(1, -88, 0.5, -8),
		BackgroundColor3 = T.Bg2, BorderSizePixel = 0,
		Text = keyRef.v.Name:upper(), TextColor3 = T.TextMid, TextSize = 9,
		Font = Enum.Font.GothamMedium, Parent = Titlebar,
	}, { Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 3) }) })

	local CloseBtn = Create("TextButton", {
		Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -20, 0.5, -6),
		BackgroundColor3 = T.Red, BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Parent = Titlebar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(255, 100, 100) }, 0.1) end)
	CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { BackgroundColor3 = T.Red }, 0.1) end)

	-- ── FIXED close: no child transparency tweening, just slide + hide ──
	local isAnimating = false
	local function closeWindow()
		if isAnimating then return end
		isAnimating = true
		local p = WinFrame.Position
		Tween(WinFrame, {
			Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 10),
		}, 0.12)
		task.wait(0.13)
		WinFrame.Visible = false
		WinFrame.Position = p  -- reset so re-open works perfectly
		isAnimating = false
	end

	local function openWindow()
		if isAnimating then return end
		isAnimating = true
		local p = WinFrame.Position
		WinFrame.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset - 8)
		WinFrame.Visible = true
		Tween(WinFrame, {
			Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 8),
		}, 0.15)
		task.wait(0.16)
		isAnimating = false
	end

	CloseBtn.MouseButton1Click:Connect(closeWindow)

	-- Tab bar
	local TabBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, TAB_H),
		Position = UDim2.new(0, 0, 0, TITLE_H),
		BackgroundColor3 = T.Bg0, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
	})
	Create("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,TITLE_H-1), BackgroundColor3 = T.Border, BorderSizePixel = 0, ZIndex = 2, Parent = WinFrame })
	Create("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,TITLE_H+TAB_H-1), BackgroundColor3 = T.Border, BorderSizePixel = 0, ZIndex = 2, Parent = WinFrame })

	local ContentArea = Create("ScrollingFrame", {
		Name = "ContentArea",
		Size = UDim2.new(1, 0, 0, CONTENT_H),
		Position = UDim2.new(0, 0, 0, TITLE_H + TAB_H),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.BorderHi,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = WinFrame,
	})

	local StatusBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, STATUS_H),
		Position = UDim2.new(0, 0, 0, WIN_H - STATUS_H),
		BackgroundColor3 = T.Bg0, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = T.Bg0, BorderSizePixel = 0 }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Border, BorderSizePixel = 0 }),
	})

	Create("Frame", {
		Size = UDim2.new(0, 5, 0, 5), Position = UDim2.new(0, 10, 0.5, -2),
		BackgroundColor3 = T.Green, BorderSizePixel = 0, Parent = StatusBar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	Create("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1, Text = "INJECTED",
		TextColor3 = T.Green, TextSize = 9, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusBar,
	})

	local PingLabel = Create("TextLabel", {
		Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -85, 0, 0),
		BackgroundTransparency = 1, Text = "12ms · v3.0", TextColor3 = T.TextLo,
		TextSize = 9, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Right, Parent = StatusBar,
	})

	task.spawn(function()
		while task.wait(2.5) do
			if not WinFrame or not WinFrame.Parent then break end
			local ms = math.random(6, 26)
			PingLabel.Text = ms.."ms · v3.0"
			PingLabel.TextColor3 = ms > 20 and Color3.fromRGB(210, 160, 50) or T.TextLo
		end
	end)

	local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == keyRef.v then
			if WinFrame.Visible then
				closeWindow()
			else
				openWindow()
			end
		end
	end)
	table.insert(Library._connections, keyConn)

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
		local tabW = math.max(64, #name * 8 + 28)

		local btn = Create("TextButton", {
			Size = UDim2.new(0, tabW, 1, 0),
			BackgroundTransparency = 1, Text = name,
			TextColor3 = T.TextMid, TextSize = 11,
			Font = Enum.Font.GothamMedium, BorderSizePixel = 0,
			LayoutOrder = #TabBar:GetChildren(), Parent = TabBar,
		})

		local indicator = Create("Frame", {
			Size = UDim2.new(1, -16, 0, 2), Position = UDim2.new(0, 8, 1, -2),
			BackgroundColor3 = T.Accent, BackgroundTransparency = 1,
			BorderSizePixel = 0, Parent = btn,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		local page = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Visible = false, Parent = ContentArea,
		}, {
			Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 16) }),
		})

		local tab = { _btn = btn, _indicator = indicator, _page = page, _win = self, _leftCol = nil, _rightCol = nil }

		local function getOrMakeCol(side)
			local which = side == "Left" and "_leftCol" or "_rightCol"
			if not tab[which] then
				tab[which] = Create("Frame", {
					Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1, LayoutOrder = side == "Left" and 1 or 2, Parent = page,
				}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }) })
			end
			return tab[which]
		end

		local function makeGroupbox(gbName, side)
			local col = getOrMakeCol(side)

			local box = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = T.Bg2, BorderSizePixel = 0,
				LayoutOrder = #col:GetChildren(), Parent = col,
			}, {
				Create("UIStroke", { Color = T.Border, Thickness = 1 }),
				Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
			})

			local hdr = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.Bg1,
				BorderSizePixel = 0, Parent = box,
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
				Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = T.Bg1, BorderSizePixel = 0 }),
				Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.Border, BorderSizePixel = 0 }),
			})

			Create("TextLabel", {
				Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 12, 0, 0),
				BackgroundTransparency = 1, Text = gbName:upper(),
				TextColor3 = T.TextMid, TextSize = 9, Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = hdr,
			})

			local body = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 24),
				AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = box,
			}, {
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }),
				Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6) }),
			})

			local GB = { _body = body }

			function GB:AddToggle(k, c2)
				c2 = c2 or {}
				local text    = c2.Text    or k
				local default = c2.Default ~= nil and c2.Default or false
				local cb      = c2.Callback or function() end
				local color   = c2.Color or "accent"
				local accentCol = color == "purple" and T.Purple or T.Accent
				local accentDim = color == "purple" and T.PurpleDim or T.AccentDim

				local row = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "",
					BorderSizePixel = 0, LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }) })

				Create("TextLabel", {
					Size = UDim2.new(1, -38, 1, 0), BackgroundTransparency = 1,
					Text = text, TextColor3 = T.TextHi, TextSize = 11,
					Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
				})

				local pill = Create("Frame", {
					Size = UDim2.new(0, 30, 0, 15), Position = UDim2.new(1, -30, 0.5, -7),
					BackgroundColor3 = T.ToggleOff, BorderSizePixel = 0, Parent = row,
				}, {
					Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
					Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				})

				local thumb = Create("Frame", {
					Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 2, 0.5, -5),
					BackgroundColor3 = T.TextLo, BorderSizePixel = 0, Parent = pill,
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local value  = default
				local stroke = pill:FindFirstChildOfClass("UIStroke")

				local function apply(v, silent)
					value = v
					if v then
						Tween(pill,  { BackgroundColor3 = accentDim }, 0.15)
						Tween(thumb, { Position = UDim2.new(0, 18, 0.5, -5), BackgroundColor3 = accentCol }, 0.15)
						stroke.Color = accentCol
					else
						Tween(pill,  { BackgroundColor3 = T.ToggleOff }, 0.15)
						Tween(thumb, { Position = UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = T.TextLo }, 0.15)
						stroke.Color = T.BorderHi
					end
					if not silent then pcall(cb, v) end
				end

				apply(default, true)
				row.MouseButton1Click:Connect(function() apply(not value) end)
				row.MouseEnter:Connect(function() row.BackgroundColor3 = T.Hover; row.BackgroundTransparency = 0 end)
				row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)

				local To = {}
				To.SetValue = function(_, v) apply(v) end
				setmetatable(To, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then apply(v) end end })
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
				local ac       = color == "purple" and T.Purple or T.Accent
				local acDim    = color == "purple" and T.PurpleDim or T.AccentDim

				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }) })

				Create("TextLabel", {
					Size = UDim2.new(0.6, 0, 0, 18), Position = UDim2.new(0, 0, 0, 2),
					BackgroundTransparency = 1, Text = text, TextColor3 = T.TextHi,
					TextSize = 11, Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap,
				})

				local valLabel = Create("TextLabel", {
					Size = UDim2.new(0.4, 0, 0, 18), Position = UDim2.new(0.6, 0, 0, 2),
					BackgroundTransparency = 1, Text = tostring(default)..suffix,
					TextColor3 = ac, TextSize = 11, Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Right, Parent = wrap,
				})

				local track = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0, 30),
					BackgroundColor3 = T.Bg0, BorderSizePixel = 0, ClipsDescendants = false, Parent = wrap,
				}, {
					Create("UIStroke", { Color = T.Border, Thickness = 1 }),
					Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				})

				local fillClip = Create("Frame", {
					Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
					BorderSizePixel = 0, ClipsDescendants = true, Parent = track,
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fillClip })

				local fill = Create("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = ac, BorderSizePixel = 0, Parent = fillClip,
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local thumb = Create("TextButton", {
					Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, -7, 0.5, -7),
					BackgroundColor3 = T.TextHi, BorderSizePixel = 0,
					Text = "", AutoButtonColor = false, ZIndex = 6, Parent = track,
				}, {
					Create("UIStroke", { Color = ac, Thickness = 1.5 }),
					Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				})

				local value  = default
				local slDrag = false

				local function applyPct(pct)
					pct = math.clamp(pct, 0, 1)
					local raw = min + (max - min) * pct
					if rounding == 0 then
						value = math.round(raw)
					else
						local m = 10^rounding
						value = math.floor(raw * m + 0.5) / m
					end
					fill.Size      = UDim2.new(pct, 0, 1, 0)
					thumb.Position = UDim2.new(pct, -7, 0.5, -7)
					valLabel.Text  = tostring(value)..suffix
					pcall(cb, value)
				end

				applyPct((default - min) / (max - min))

				thumb.MouseButton1Down:Connect(function()
					slDrag = true
					Tween(thumb, { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(thumb.Position.X.Scale, thumb.Position.X.Offset - 1, 0.5, -8) }, 0.08)
				end)
				track.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then
						slDrag = true
						local mx = UserInputService:GetMouseLocation().X
						applyPct((mx - track.AbsolutePosition.X) / track.AbsoluteSize.X)
					end
				end)
				UserInputService.InputChanged:Connect(function(inp)
					if slDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
						applyPct((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 and slDrag then
						slDrag = false
						Tween(thumb, { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(thumb.Position.X.Scale, thumb.Position.X.Offset + 1, 0.5, -7) }, 0.08)
					end
				end)

				local S = {}
				S.SetValue = function(_, v) applyPct((v - min) / (max - min)) end
				setmetatable(S, {
					__index    = function(_, k2) if k2 == "Value" then return value end end,
					__newindex = function(_, k2, v) if k2 == "Value" then applyPct((v - min) / (max - min)) end end,
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

				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1,
					ClipsDescendants = false, LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }) })

				Create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 2),
					BackgroundTransparency = 1, Text = text, TextColor3 = T.TextMid,
					TextSize = 10, Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap,
				})

				local dropBtn = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 22),
					BackgroundColor3 = T.Input, BorderSizePixel = 0, Text = "", Parent = wrap,
				}, {
					Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
					Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
				})

				local selLabel = Create("TextLabel", {
					Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 8, 0, 0),
					BackgroundTransparency = 1, Text = default, TextColor3 = T.TextHi,
					TextSize = 11, Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left, Parent = dropBtn,
				})

				local arrowL = Create("Frame", { Size = UDim2.new(0,6,0,1), Position = UDim2.new(1,-17,0.5,1), BackgroundColor3 = T.TextMid, BorderSizePixel = 0, Parent = dropBtn }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })
				local arrowR = Create("Frame", { Size = UDim2.new(0,6,0,1), Position = UDim2.new(1,-12,0.5,1), BackgroundColor3 = T.TextMid, BorderSizePixel = 0, Parent = dropBtn }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })
				arrowL.Rotation = 35; arrowR.Rotation = -35

				local listFrame = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 3),
					BackgroundColor3 = T.Bg3, BorderSizePixel = 0, Visible = false, ZIndex = 25, Parent = dropBtn,
				}, {
					Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
					Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
					Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
				})

				local value = default; local open = false

				local function buildList()
					for _, c3 in ipairs(listFrame:GetChildren()) do if c3:IsA("TextButton") then c3:Destroy() end end
					for _, v2 in ipairs(vals) do
						local opt = Create("TextButton", {
							Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.Bg3, BorderSizePixel = 0,
							Text = v2, TextColor3 = v2 == value and T.Accent or T.TextHi,
							TextSize = 11, Font = v2 == value and Enum.Font.GothamMedium or Enum.Font.Gotham,
							ZIndex = 26, Parent = listFrame,
						}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })
						opt.TextXAlignment = Enum.TextXAlignment.Left
						opt.MouseButton1Click:Connect(function()
							value = v2; selLabel.Text = v2; open = false; listFrame.Visible = false
							pcall(cb, v2); buildList()
						end)
						opt.MouseEnter:Connect(function() Tween(opt, { BackgroundColor3 = T.Hover }, 0.08) end)
						opt.MouseLeave:Connect(function() Tween(opt, { BackgroundColor3 = T.Bg3 }, 0.08) end)
					end
					listFrame.Size = UDim2.new(1, 0, 0, #vals * 24)
				end

				buildList()
				dropBtn.MouseButton1Click:Connect(function()
					open = not open; listFrame.Visible = open
					Tween(arrowL, { Rotation = open and -35 or 35 }, 0.1)
					Tween(arrowR, { Rotation = open and 35 or -35 }, 0.1)
				end)
				dropBtn.MouseEnter:Connect(function() Tween(dropBtn, { BackgroundColor3 = T.Hover }, 0.1) end)
				dropBtn.MouseLeave:Connect(function() Tween(dropBtn, { BackgroundColor3 = T.Input }, 0.1) end)

				local D = { Values = vals }
				D.SetValue = function(_, v) value = v; selLabel.Text = v; pcall(cb, v); buildList() end
				setmetatable(D, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then D:SetValue(v) end end })
				Library.Options[k] = D
				return D
			end

			function GB:AddColorPicker(k, c2)
				c2 = c2 or {}
				local text    = c2.Text    or k
				local default = c2.Default or T.Accent
				local cb      = c2.Callback or function() end

				local row = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }) })

				Create("TextLabel", {
					Size = UDim2.new(1, -28, 1, 0), BackgroundTransparency = 1,
					Text = text, TextColor3 = T.TextHi, TextSize = 11,
					Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
				})

				local swatch = Create("TextButton", {
					Size = UDim2.new(0, 18, 0, 13), Position = UDim2.new(1, -18, 0.5, -6),
					BackgroundColor3 = default, BorderSizePixel = 0, Text = "", Parent = row,
				}, {
					Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
					Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
				})

				local value = default
				local presets = {
					Color3.fromRGB(210,100,130), Color3.fromRGB(155,120,210),
					Color3.fromRGB(60,200,120),  Color3.fromRGB(210,180,60),
					Color3.fromRGB(60,160,210),  Color3.fromRGB(230,228,222),
				}

				swatch.MouseButton1Click:Connect(function()
					local idx = 1
					for i, c3 in ipairs(presets) do if c3 == value then idx = i % #presets + 1; break end end
					value = presets[idx]; swatch.BackgroundColor3 = value; pcall(cb, value)
				end)

				local CP = {}
				CP.SetValue = function(_, v) value = v; swatch.BackgroundColor3 = v; pcall(cb, v) end
				setmetatable(CP, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then CP:SetValue(v) end end })
				Library.Options[k] = CP
				return CP
			end

			function GB:AddKeybind(k, c2)
				c2 = c2 or {}
				local text    = c2.Text    or k
				local default = c2.Default or Enum.KeyCode.Unknown
				local cb      = c2.Callback or function() end

				local row = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "",
					BorderSizePixel = 0, LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }) })

				Create("TextLabel", {
					Size = UDim2.new(1, -64, 1, 0), BackgroundTransparency = 1,
					Text = text, TextColor3 = T.TextHi, TextSize = 11,
					Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
				})

				local badge = Create("TextLabel", {
					Size = UDim2.new(0, 56, 0, 17), Position = UDim2.new(1, -56, 0.5, -8),
					BackgroundColor3 = T.Input, BorderSizePixel = 0,
					Text = "["..default.Name:upper().."]", TextColor3 = T.TextMid,
					TextSize = 9, Font = Enum.Font.GothamMedium, Parent = row,
				}, {
					Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
					Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
				})

				local value = default; local binding = false

				row.MouseButton1Click:Connect(function()
					binding = true
					badge.Text = "[ . . . ]"; badge.TextColor3 = T.Accent
					Tween(badge, { BackgroundColor3 = T.Bg3 }, 0.1)
				end)
				row.MouseEnter:Connect(function() row.BackgroundColor3 = T.Hover; row.BackgroundTransparency = 0 end)
				row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)

				UserInputService.InputBegan:Connect(function(inp, gpe)
					if binding and not gpe and inp.UserInputType == Enum.UserInputType.Keyboard then
						binding = false; value = inp.KeyCode
						badge.Text = "["..inp.KeyCode.Name:upper().."]"
						badge.TextColor3 = T.TextMid
						Tween(badge, { BackgroundColor3 = T.Input }, 0.1)
						if k == "MenuKey" then
							keyRef.v = inp.KeyCode
							keyBadge.Text = inp.KeyCode.Name:upper()
						end
						pcall(cb, value)
					end
				end)

				local KB = {}
				KB.SetValue = function(_, v)
					value = v; badge.Text = "["..v.Name:upper().."]"
					if k == "MenuKey" then keyRef.v = v; keyBadge.Text = v.Name:upper() end
				end
				setmetatable(KB, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then KB:SetValue(v) end end })
				Library.Options[k] = KB
				return KB
			end

			function GB:AddButton(c2)
				c2 = c2 or {}
				local text = c2.Text or "Button"
				local cb   = c2.Callback or function() end

				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }) })

				local btn = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = T.Bg3,
					BorderSizePixel = 0, Text = text, TextColor3 = T.TextHi,
					TextSize = 11, Font = Enum.Font.GothamMedium, Parent = wrap,
				}, {
					Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
					Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				})

				btn.MouseButton1Click:Connect(function()
					Tween(btn, { BackgroundColor3 = T.AccentDim }, 0.08)
					task.wait(0.14)
					Tween(btn, { BackgroundColor3 = T.Bg3 }, 0.14)
					pcall(cb)
				end)
				btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = T.Hover }, 0.1) end)
				btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = T.Bg3 }, 0.1) end)
			end

			function GB:AddLabel(text)
				Create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text,
					TextColor3 = T.TextMid, TextSize = 10, Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }) })
			end

			function GB:AddDivider()
				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				})
				Create("Frame", {
					Size = UDim2.new(1, -22, 0, 1), Position = UDim2.new(0, 11, 0.5, 0),
					BackgroundColor3 = T.Border, BorderSizePixel = 0, Parent = wrap,
				})
			end

			return GB
		end

		function tab:AddLeftGroupbox(name)  return makeGroupbox(name, "Left")  end
		function tab:AddRightGroupbox(name) return makeGroupbox(name, "Right") end

		btn.MouseButton1Click:Connect(function() self:_switchTab(tab) end)
		btn.MouseEnter:Connect(function()
			if self._activeTab ~= tab then Tween(btn, { TextColor3 = T.TextHi }, 0.1) end
		end)
		btn.MouseLeave:Connect(function()
			if self._activeTab ~= tab then Tween(btn, { TextColor3 = T.TextMid }, 0.1) end
		end)

		table.insert(self._tabs, tab)
		if #self._tabs == 1 then self:_switchTab(tab) end
		return tab
	end

	-- ================================================================
	--  ESP PREVIEW  —  3D ViewportFrame with rotating character clone
	-- ================================================================
	function Window:AddESPPreview()
		local espColor  = T.Accent
		local charClone = nil
		local cloneHRP  = nil
		local partRelCF = {}
		local rotAngle  = 0

		-- Outer panel (floats to the right of the main window)
		local PW, PH = 136, 246
		local previewFrame = Create("Frame", {
			Name             = "ESPPreview",
			Size             = UDim2.new(0, PW, 0, PH),
			Position         = UDim2.new(1, 12, 0, 0),
			BackgroundColor3 = T.Bg1,
			BorderSizePixel  = 0,
			Visible          = true,
			Parent           = WinFrame,
		}, {
			Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		})

		-- Top accent bar
		Create("Frame", {
			Size = UDim2.new(0, 52, 0, 2), Position = UDim2.new(0, 10, 0, 0),
			BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 2, Parent = previewFrame,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		-- Header
		local hdr = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.Bg0,
			BorderSizePixel = 0, Parent = previewFrame,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("Frame", { Size = UDim2.new(1,0,0,8), Position = UDim2.new(0,0,1,-8), BackgroundColor3 = T.Bg0, BorderSizePixel = 0 }),
			Create("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1), BackgroundColor3 = T.Border, BorderSizePixel = 0 }),
		})

		Create("TextLabel", {
			Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,10,0,0),
			BackgroundTransparency = 1, Text = "ESP PREVIEW",
			TextColor3 = T.TextMid, TextSize = 9, Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = hdr,
		})

		local accentDot = Create("Frame", {
			Size = UDim2.new(0,6,0,6), Position = UDim2.new(1,-12,0.5,-3),
			BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = hdr,
		}, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

		MakeDraggable(previewFrame, hdr)

		-- ViewportFrame
		local VP_H = PH - 28
		local vp = Create("ViewportFrame", {
			Size             = UDim2.new(1, 0, 0, VP_H),
			Position         = UDim2.new(0, 0, 0, 28),
			BackgroundColor3 = Color3.fromRGB(7, 6, 13),
			Ambient          = Color3.fromRGB(110, 105, 140),
			LightDirection   = Vector3.new(-0.6, -1, -0.5),
			LightColor       = Color3.fromRGB(255, 248, 235),
			ClipsDescendants = true,
			Parent           = previewFrame,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 6) }) })

		-- WorldModel (hosts the 3D character clone)
		local wm = Instance.new("WorldModel")
		wm.Parent = vp

		-- Camera
		local vpCam = Instance.new("Camera")
		vpCam.FieldOfView = 42
		vpCam.Parent = vp
		vp.CurrentCamera = vpCam

		-- ── Character clone setup ──
		local function setupClone()
			-- Clean up existing
			if charClone then
				pcall(function() charClone:Destroy() end)
				charClone = nil; cloneHRP = nil; partRelCF = {}
			end

			local char = LocalPlayer.Character
			if not char then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end

			charClone = char:Clone()
			charClone.Name = "PunchyPreviewChar"

			-- Strip everything that doesn't contribute to the look
			for _, d in ipairs(charClone:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript")
				   or d:IsA("Animator") or d:IsA("Animation") or d:IsA("BodyMover")
				   or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("Highlight")
				   or d:IsA("SelectionBox") or d:IsA("ParticleEmitter") then
					pcall(function() d:Destroy() end)
				end
			end

			cloneHRP = charClone:FindFirstChild("HumanoidRootPart")
			if not cloneHRP then charClone:Destroy(); charClone = nil; return end

			-- Hide humanoid UI
			local hum = charClone:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				hum.HealthDisplayType   = Enum.HumanoidHealthDisplayType.AlwaysOff
			end

			-- Anchor all parts and capture relative CFrames from HRP
			for _, p in ipairs(charClone:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored   = true
					p.CanCollide = false
					p.CastShadow = false
					if p ~= cloneHRP then
						partRelCF[p] = cloneHRP.CFrame:ToObjectSpace(p.CFrame)
					end
				end
			end

			-- Place at world origin
			cloneHRP.CFrame = CFrame.new(0, 0, 0)
			for p, rel in pairs(partRelCF) do
				if p and p.Parent then p.CFrame = CFrame.new(0,0,0) * rel end
			end

			charClone.Parent = wm

			-- Position camera to frame the full character
			-- R6 height ≈ 5 studs, centre ≈ Y 2.  R15 similar.
			local charH = 5
			local cy    = charH * 0.43
			vpCam.CFrame = CFrame.new(Vector3.new(0, cy, charH * 1.25), Vector3.new(0, cy, 0))
		end

		pcall(setupClone)
		LocalPlayer.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 10)
			task.wait(0.6)
			pcall(setupClone)
		end)

		-- Slow auto-rotation
		local rotConn = RunService.Heartbeat:Connect(function(dt)
			rotAngle = rotAngle + dt * 48
			if not cloneHRP or not cloneHRP.Parent then return end
			local newCF = CFrame.Angles(0, math.rad(rotAngle), 0)
			cloneHRP.CFrame = newCF
			for p, rel in pairs(partRelCF) do
				if p and p.Parent then p.CFrame = newCF * rel end
			end
		end)
		table.insert(Library._connections, rotConn)

		-- ── 2D overlay elements (placed inside vp, on top of the 3D scene) ──

		-- Nametag
		local nameTag = Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 15),
			Position = UDim2.new(0, 0, 0, 3),
			BackgroundTransparency = 1,
			Text = LocalPlayer.DisplayName or "Player",
			TextColor3 = espColor,
			TextSize = 10, Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextStrokeTransparency = 0.45,
			TextStrokeColor3 = Color3.new(0,0,0),
			ZIndex = 12, Visible = false, Parent = vp,
		})

		local distTag = Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 11),
			Position = UDim2.new(0, 0, 0, 19),
			BackgroundTransparency = 1,
			Text = "0m",
			TextColor3 = T.TextMid,
			TextSize = 9, Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextStrokeTransparency = 0.5,
			ZIndex = 12, Visible = false, Parent = vp,
		})

		-- Box frame — covers roughly the character silhouette in the viewport
		-- VP is 136 wide, VP_H tall.  Character fills ≈ 60% width, starts at ~Y 30
		local BX = 0.20   -- left padding (scale)
		local BW = 0.60   -- box width (scale)
		local BY = 0.165  -- top Y (scale)
		local BH = 0.790  -- height (scale)

		local boxFrame = Create("Frame", {
			Size             = UDim2.new(BW, 0, BH, 0),
			Position         = UDim2.new(BX, 0, BY, 0),
			BackgroundTransparency = 1,
			BorderSizePixel  = 0,
			ZIndex           = 8,
			Visible          = false,
			Parent           = vp,
		})
		local boxStroke = Create("UIStroke", { Color = espColor, Thickness = 1.5, Parent = boxFrame })

		local fillFrame = Create("Frame", {
			Size             = UDim2.new(1,0,1,0),
			BackgroundColor3 = espColor,
			BackgroundTransparency = 0.75,
			BorderSizePixel  = 0,
			ZIndex           = 7,
			Visible          = false,
			Parent           = boxFrame,
		})

		-- Health bar (left of box)
		local hbBg = Create("Frame", {
			Size             = UDim2.new(0, 4, 1, 0),
			Position         = UDim2.new(0, -8, 0, 0),
			BackgroundColor3 = Color3.fromRGB(22, 7, 7),
			BorderSizePixel  = 0,
			ZIndex           = 8,
			Visible          = false,
			Parent           = boxFrame,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

		Create("Frame", {
			Size             = UDim2.new(1, 0, 0.72, 0),
			Position         = UDim2.new(0, 0, 0.28, 0),
			BackgroundColor3 = T.Green,
			BorderSizePixel  = 0,
			Parent           = hbBg,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

		-- Skeleton overlay (pixel coords relative to boxFrame)
		-- boxFrame absolute ≈ 82 × 167 px (BW*136 × BH*VP_H)
		local skelFrame = Create("Frame", {
			Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 9, Visible = false, Parent = boxFrame,
		})

		local skelLines = {}

		-- Draw a rotated 1-px-tall line between two absolute-pixel points inside skelFrame
		local function SkelLine(x1, y1, x2, y2)
			local dx, dy  = x2 - x1, y2 - y1
			local len     = math.sqrt(dx*dx + dy*dy)
			if len < 1 then return end
			local angle   = math.deg(math.atan2(dy, dx))
			local cx, cy2 = (x1+x2)/2, (y1+y2)/2
			local line = Create("Frame", {
				Size             = UDim2.new(0, len, 0, 2),
				Position         = UDim2.new(0, cx - len/2, 0, cy2 - 1),
				Rotation         = angle,
				BackgroundColor3 = espColor,
				BorderSizePixel  = 0,
				ZIndex           = 9,
				Parent           = skelFrame,
			}, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })
			table.insert(skelLines, line)
		end

		-- R6 joint positions, box ≈ 82 × 167 px
		SkelLine(41,  5, 41, 24)          -- head → neck
		SkelLine(41, 24, 16, 32)          -- neck → L shoulder
		SkelLine(41, 24, 66, 32)          -- neck → R shoulder
		SkelLine(16, 32, 11, 78)          -- L arm upper
		SkelLine(11, 78,  9,110)          -- L arm lower
		SkelLine(66, 32, 71, 78)          -- R arm upper
		SkelLine(71, 78, 73,110)          -- R arm lower
		SkelLine(41, 24, 41, 97)          -- spine
		SkelLine(41, 97, 26,103)          -- L hip
		SkelLine(41, 97, 56,103)          -- R hip
		SkelLine(26,103, 24,148)          -- L thigh
		SkelLine(24,148, 23,165)          -- L shin
		SkelLine(56,103, 58,148)          -- R thigh
		SkelLine(58,148, 59,165)          -- R shin

		-- Chams: a Highlight on the clone itself (shows through geometry)
		local chamHL = Instance.new("Highlight")
		chamHL.FillTransparency    = 0.45
		chamHL.OutlineTransparency = 1
		chamHL.FillColor           = espColor
		chamHL.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
		chamHL.Enabled             = false

		-- Attach chamHL once the clone is ready
		task.delay(0.2, function()
			if charClone then
				chamHL.Adornee = charClone
				chamHL.Parent  = charClone
			end
		end)

		-- ── Internal colour propagation ──
		local function updateColor(col)
			espColor = col
			accentDot.BackgroundColor3  = col
			boxStroke.Color             = col
			fillFrame.BackgroundColor3  = col
			nameTag.TextColor3          = col
			chamHL.FillColor            = col
			for _, l in ipairs(skelLines) do
				if l and l.Parent then l.BackgroundColor3 = col end
			end
		end

		-- ── Public Preview API ──
		local Preview = {}

		function Preview:SetVisible(v)
			previewFrame.Visible = v
		end

		function Preview:SetBox(en, filled, trans)
			boxFrame.Visible = en
			hbBg.Visible     = en
			nameTag.Visible  = en
			distTag.Visible  = en
			if filled ~= nil then fillFrame.Visible = filled end
			if trans   ~= nil then fillFrame.BackgroundTransparency = trans end
		end

		function Preview:SetFilled(en, trans)
			fillFrame.Visible = en
			if trans ~= nil then fillFrame.BackgroundTransparency = trans end
		end

		function Preview:SetSkeleton(en)
			skelFrame.Visible = en
		end

		function Preview:SetChams(en, color)
			chamHL.Enabled = en
			if color then updateColor(color) end
			-- Re-attach if needed
			if charClone and not chamHL.Adornee then
				chamHL.Adornee = charClone
				chamHL.Parent  = charClone
			end
		end

		function Preview:SetColor(color)
			updateColor(color)
		end

		return Preview
	end

	function Window:Unload()
		for _, c in ipairs(Library._connections) do pcall(function() c:Disconnect() end) end
		Library._connections = {}
		local sg = Library._screenGui
		if sg then
			pcall(function() sg:Destroy() end)
			pcall(function() sg.Enabled = false end)
			pcall(function() sg.Parent = nil end)
		end
	end

	Library._window = Window
	return Window
end

function Library:Unload()
	if self._window then self._window:Unload() end
end

return Library

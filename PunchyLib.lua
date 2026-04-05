--[[
    PunchyLib v3.0
--]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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

-- Abstract logo: 3 descending bars (histogram mark)
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

	-- Subtle top accent line
	Create("Frame", {
		Size = UDim2.new(0, 80, 0, 2), Position = UDim2.new(0, 20, 0, 0),
		BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 2, Parent = WinFrame,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	-- Title bar
	local Titlebar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, TITLE_H), BackgroundColor3 = T.Bg0,
		BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = T.Bg0, BorderSizePixel = 0 }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.Border, BorderSizePixel = 0 }),
	})

	MakeDraggable(WinFrame, Titlebar)

	-- Abstract logo mark
	BuildLogo(Titlebar, 12, 10)

	-- Title text
	local titleStr = title:upper()
	local titleLabel = Create("TextLabel", {
		Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(0, 30, 0, 0),
		BackgroundTransparency = 1, Text = titleStr,
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

	-- Key badge
	local keyBadge = Create("TextLabel", {
		Size = UDim2.new(0, 58, 0, 17), Position = UDim2.new(1, -88, 0.5, -8),
		BackgroundColor3 = T.Bg2, BorderSizePixel = 0,
		Text = keyRef.v.Name:upper(), TextColor3 = T.TextMid, TextSize = 9,
		Font = Enum.Font.GothamMedium, Parent = Titlebar,
	}, { Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 3) }) })

	-- Close button only (red dot)
	local CloseBtn = Create("TextButton", {
		Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -20, 0.5, -6),
		BackgroundColor3 = T.Red, BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Parent = Titlebar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(255, 100, 100) }, 0.1) end)
	CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { BackgroundColor3 = T.Red }, 0.1) end)

	CloseBtn.MouseButton1Click:Connect(function()
		Tween(WinFrame, { Position = UDim2.new(WinFrame.Position.X.Scale, WinFrame.Position.X.Offset, WinFrame.Position.Y.Scale, WinFrame.Position.Y.Offset - 8) }, 0.12)
		Tween(WinFrame, { BackgroundTransparency = 1 }, 0.18)
		-- fade all children
		for _, d in ipairs(WinFrame:GetDescendants()) do
			if d:IsA("GuiObject") and d ~= WinFrame then
				pcall(function() Tween(d, { BackgroundTransparency = 1 }, 0.18) end)
				pcall(function() Tween(d, { TextTransparency = 1 }, 0.18) end)
				pcall(function() Tween(d, { ImageTransparency = 1 }, 0.18) end)
			end
		end
		task.wait(0.22)
		WinFrame.Visible = false
		WinFrame.BackgroundTransparency = 0
	end)

	-- Tab bar (borders parented to WinFrame separately — NOT inside TabBar, avoids UIListLayout eating them)
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

	-- Scrollable content
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

	-- Status bar
	local StatusBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, STATUS_H),
		Position = UDim2.new(0, 0, 0, WIN_H - STATUS_H),
		BackgroundColor3 = T.Bg0, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = T.Bg0, BorderSizePixel = 0 }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Border, BorderSizePixel = 0 }),
	})

	local statusDot = Create("Frame", {
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

	-- Key toggle (reads keyRef.v so it updates when changed)
	local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == keyRef.v then
			WinFrame.Visible = not WinFrame.Visible
		end
	end)
	table.insert(Library._connections, keyConn)

	local Window = {
		_frame    = WinFrame,
		_tabBar   = TabBar,
		_content  = ContentArea,
		_tabs     = {},
		_activeTab= nil,
		_keyRef   = keyRef,
		_keyBadge = keyBadge,
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

			-- Left accent border
			Create("Frame", {
				Size = UDim2.new(0, 2, 1, -10), Position = UDim2.new(0, 0, 0, 5),
				BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 2, Parent = box,
			}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

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
				local text = c2.Text or k
				local default = c2.Default ~= nil and c2.Default or false
				local cb = c2.Callback or function() end
				local color = c2.Color or "accent"
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

				local value = default
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
				local text = c2.Text or k
				local min = c2.Min or 0; local max = c2.Max or 100
				local default = c2.Default ~= nil and c2.Default or min
				local rounding = c2.Rounding ~= nil and c2.Rounding or 0
				local suffix = c2.Suffix or ""
				local color = c2.Color or "accent"
				local cb = c2.Callback or function() end
				local ac = color == "purple" and T.Purple or T.Accent

				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }) })

				Create("TextLabel", {
					Size = UDim2.new(0.65, 0, 0, 18), Position = UDim2.new(0, 0, 0, 2),
					BackgroundTransparency = 1, Text = text, TextColor3 = T.TextHi,
					TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap,
				})

				local valLabel = Create("TextLabel", {
					Size = UDim2.new(0.35, 0, 0, 18), Position = UDim2.new(0.65, 0, 0, 2),
					BackgroundTransparency = 1, Text = tostring(default)..suffix,
					TextColor3 = ac, TextSize = 11, Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Right, Parent = wrap,
				})

				local trackBg = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 0, 30),
					BackgroundColor3 = T.Input, BorderSizePixel = 0,
					Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = wrap,
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local fill = Create("Frame", {
					Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ac,
					BorderSizePixel = 0, Parent = trackBg,
				})

				-- Thumb (outside clip so it can overflow the track height)
				local thumbWrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0.5, -7),
					BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Parent = trackBg,
				})

				local thumbBtn = Create("TextButton", {
					Size = UDim2.new(0, 13, 0, 13), Position = UDim2.new(0, -6, 0.5, -6),
					BackgroundColor3 = T.TextHi, BorderSizePixel = 0, Text = "", ZIndex = 6,
					Parent = thumbWrap,
				}, {
					Create("UIStroke", { Color = ac, Thickness = 2 }),
					Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				})

				local value = default
				local slDrag = false

				local function applyPct(pct)
					pct = math.clamp(pct, 0, 1)
					local raw = min + (max - min) * pct
					if rounding == 0 then value = math.round(raw)
					else local m = 10^rounding; value = math.floor(raw*m+0.5)/m end
					fill.Size         = UDim2.new(pct, 0, 1, 0)
					thumbBtn.Position = UDim2.new(pct, -6, 0.5, -6)
					valLabel.Text     = tostring(value)..suffix
					pcall(cb, value)
				end

				applyPct((default - min) / (max - min))

				thumbBtn.MouseButton1Down:Connect(function() slDrag = true end)
				trackBg.MouseButton1Down:Connect(function()
					slDrag = true
					local mx = UserInputService:GetMouseLocation().X
					applyPct((mx - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X)
				end)
				UserInputService.InputChanged:Connect(function(inp)
					if slDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
						applyPct((inp.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then slDrag = false end
				end)

				local S = {}
				S.SetValue = function(_, v) applyPct((v-min)/(max-min)) end
				setmetatable(S, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then applyPct((v-min)/(max-min)) end end })
				Library.Options[k] = S
				return S
			end

			function GB:AddDropdown(k, c2)
				c2 = c2 or {}
				local text = c2.Text or k; local vals = c2.Values or {}
				local default = c2.Default or (vals[1] or "")
				local cb = c2.Callback or function() end

				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1,
					ClipsDescendants = false, LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 10) }) })

				Create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 2),
					BackgroundTransparency = 1, Text = text, TextColor3 = T.TextMid,
					TextSize = 10, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap,
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
					TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = dropBtn,
				})

				-- Arrow indicator (two small frames making a "v")
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
				local text = c2.Text or k; local default = c2.Default or T.Accent
				local cb = c2.Callback or function() end

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
				local text = c2.Text or k; local default = c2.Default or Enum.KeyCode.Unknown
				local cb = c2.Callback or function() end

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
						-- Update window toggle key if this is the MenuKey
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
				local text = c2.Text or "Button"; local cb = c2.Callback or function() end

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
				btn.MouseEnter:Connect(function()
					Tween(btn, { BackgroundColor3 = T.Hover }, 0.1)
					btn:FindFirstChildOfClass("UIStroke").Color = T.Accent
				end)
				btn.MouseLeave:Connect(function()
					Tween(btn, { BackgroundColor3 = T.Bg3 }, 0.1)
					btn:FindFirstChildOfClass("UIStroke").Color = T.BorderHi
				end)
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

	-- ESP Preview: manually built R6 mannequin — zero character access, zero AvatarEditorPrompts
	function Window:AddESPPreview()
		local espColor = T.Accent

		local previewFrame = Create("Frame", {
			Name = "ESPPreview", Size = UDim2.new(0, 124, 0, 280),
			Position = UDim2.new(1, 10, 0, 0),
			BackgroundColor3 = T.Bg1, BorderSizePixel = 0, Visible = true, Parent = WinFrame,
		}, {
			Create("UIStroke", { Color = T.BorderHi, Thickness = 1 }),
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		})

		-- Top accent line
		Create("Frame", {
			Size = UDim2.new(0, 50, 0, 2), Position = UDim2.new(0, 12, 0, 0),
			BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 2, Parent = previewFrame,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		local hdr = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.Bg0, BorderSizePixel = 0, Parent = previewFrame,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = T.Bg0, BorderSizePixel = 0 }),
			Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.Border, BorderSizePixel = 0 }),
		})

		Create("TextLabel", {
			Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
			BackgroundTransparency = 1, Text = "ESP PREVIEW", TextColor3 = T.TextMid,
			TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = hdr,
		})

		local dot = Create("Frame", {
			Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(1, -12, 0.5, -3),
			BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = hdr,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		MakeDraggable(previewFrame, hdr)

		local canvas = Create("Frame", {
			Size = UDim2.new(1, 0, 1, -28), Position = UDim2.new(0, 0, 0, 28),
			BackgroundColor3 = Color3.fromRGB(5, 5, 8), BorderSizePixel = 0,
			ClipsDescendants = true, Parent = previewFrame,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 6) }) })

		-- Subtle grid floor
		for i = 0, 5 do
			Create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0.58 + i*0.08, 0),
				BackgroundColor3 = Color3.fromRGB(22, 20, 30),
				BorderSizePixel = 0, Parent = canvas,
			})
		end
		for i = 0, 4 do
			Create("Frame", {
				Size = UDim2.new(0, 1, 0.45, 0),
				Position = UDim2.new(0.1 + i*0.2, 0, 0.56, 0),
				BackgroundColor3 = Color3.fromRGB(22, 20, 30),
				BorderSizePixel = 0, Parent = canvas,
			})
		end

		-- ViewportFrame with manually constructed R6 mannequin (no character cloning)
		local viewport = Create("ViewportFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Ambient      = Color3.fromRGB(100, 90, 115),
			LightColor   = Color3.fromRGB(255, 245, 255),
			LightDirection = Vector3.new(-0.8, -2, -0.6),
			Parent = canvas,
		})

		local cam = Create("Camera", { FieldOfView = 28, Parent = viewport })
		viewport.CurrentCamera = cam
		cam.CFrame = CFrame.new(Vector3.new(0, 3.1, 9.5), Vector3.new(0, 3.1, 0))

		local wm = Create("WorldModel", { Parent = viewport })

		local skin  = Color3.fromRGB(250, 200, 160)
		local shirt = Color3.fromRGB(38, 36, 52)
		local pant  = Color3.fromRGB(26, 24, 38)
		local shoe  = Color3.fromRGB(14, 12, 18)

		local function P(sz, pos, col, shape)
			local p = Instance.new("Part")
			p.Size = sz; p.CFrame = CFrame.new(pos)
			p.Anchored = true; p.CanCollide = false; p.CastShadow = false
			p.Material = Enum.Material.SmoothPlastic; p.Color = col
			if shape then p.Shape = shape end
			p.Parent = wm
			return p
		end

		-- Head
		P(Vector3.new(1.3,1.3,1.3), Vector3.new(0,5.25,0), skin, Enum.PartType.Ball)
		-- Neck
		P(Vector3.new(0.45,0.35,0.45), Vector3.new(0,4.5,0), skin)
		-- Torso upper
		P(Vector3.new(2,1.15,1.05), Vector3.new(0,3.7,0), shirt)
		-- Torso lower
		P(Vector3.new(2,0.9,1.05), Vector3.new(0,2.65,0), shirt)
		-- Belt line
		P(Vector3.new(2.05,0.12,1.1), Vector3.new(0,2.16,0), Color3.fromRGB(20,18,28))
		-- Left upper arm
		P(Vector3.new(0.92,1.15,0.92), Vector3.new(-1.47,3.65,0), shirt)
		-- Left lower arm
		P(Vector3.new(0.85,1.05,0.85), Vector3.new(-1.47,2.3,0), skin)
		-- Right upper arm
		P(Vector3.new(0.92,1.15,0.92), Vector3.new(1.47,3.65,0), shirt)
		-- Right lower arm
		P(Vector3.new(0.85,1.05,0.85), Vector3.new(1.47,2.3,0), skin)
		-- Left upper leg
		P(Vector3.new(0.95,1.25,0.95), Vector3.new(-0.55,1.5,0), pant)
		-- Left lower leg
		P(Vector3.new(0.9,1.1,0.9),   Vector3.new(-0.55,0.2,0), pant)
		-- Left shoe
		P(Vector3.new(0.96,0.28,1.2), Vector3.new(-0.55,-0.5,0.08), shoe)
		-- Right upper leg
		P(Vector3.new(0.95,1.25,0.95), Vector3.new(0.55,1.5,0), pant)
		-- Right lower leg
		P(Vector3.new(0.9,1.1,0.9),   Vector3.new(0.55,0.2,0), pant)
		-- Right shoe
		P(Vector3.new(0.96,0.28,1.2), Vector3.new(0.55,-0.5,0.08), shoe)
		-- Floor shadow
		P(Vector3.new(3,0.04,2), Vector3.new(0,-0.65,0), Color3.fromRGB(8,7,12))

		-- 2D ESP overlays layered on canvas
		local boxStroke = Instance.new("UIStroke"); boxStroke.Color = espColor; boxStroke.Thickness = 1.5
		local boxFrame = Create("Frame", {
			Size = UDim2.new(0, 56, 0, 150), Position = UDim2.new(0.5, -28, 0, 6),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Visible = false, Parent = canvas,
		})
		boxStroke.Parent = boxFrame

		local fillFrame = Create("Frame", {
			Size = UDim2.new(1,0,1,0), BackgroundColor3 = espColor,
			BackgroundTransparency = 0.75, BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = boxFrame,
		})

		local skelFrame = Create("Frame", {
			Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
			BorderSizePixel = 0, ZIndex = 6, Visible = false, Parent = boxFrame,
		})
		local skelDefs = {
			{0.5,0,    4,1}, {0.5,0.06, 8,1}, {0.5,0.17,24,1},
			{0.5,0.45,10,1}, {0.5,0.58,20,1}, {0.5,0.77,16,1},
		}
		local skelLines = {}
		for _, sd in ipairs(skelDefs) do
			table.insert(skelLines, Create("Frame", {
				Size = UDim2.new(0,sd[3],0,sd[4]),
				Position = UDim2.new(sd[1],-sd[3]/2,sd[2],0),
				BackgroundColor3 = espColor, BorderSizePixel = 0, Parent = skelFrame,
			}))
		end

		-- Healthbar
		local hbBg = Create("Frame", {
			Size = UDim2.new(0, 3, 0, 150), Position = UDim2.new(0, -8, 0, 6),
			BackgroundColor3 = Color3.fromRGB(40,12,12), BorderSizePixel = 0, ZIndex = 5, Visible = false, Parent = canvas,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local hbFill = Create("Frame", {
			Size = UDim2.new(1, 0, 0.75, 0), Position = UDim2.new(0, 0, 0.25, 0),
			BackgroundColor3 = T.Green, BorderSizePixel = 0, Parent = hbBg,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		-- Nametag
		local nameTag = Create("TextLabel", {
			Size = UDim2.new(1, 16, 0, 14), Position = UDim2.new(0, -8, 0, -16),
			BackgroundTransparency = 1, Text = "Enemy", TextColor3 = espColor,
			TextSize = 10, Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 7, Visible = false, Parent = boxFrame,
		})

		-- Chams overlay
		local chamOverlay = Create("Frame", {
			Size = UDim2.new(1,0,1,0), BackgroundColor3 = espColor,
			BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 3, Visible = false, Parent = canvas,
		})

		local function updateColor(col)
			espColor = col; dot.BackgroundColor3 = col
			boxStroke.Color = col; fillFrame.BackgroundColor3 = col
			nameTag.TextColor3 = col
			for _, l in ipairs(skelLines) do l.BackgroundColor3 = col end
		end

		local Preview = {}
		function Preview:SetVisible(v) previewFrame.Visible = v end
		function Preview:SetBox(en, filled, trans)
			boxFrame.Visible = en; hbBg.Visible = en; nameTag.Visible = en
			if filled ~= nil then fillFrame.Visible = filled end
			if trans   ~= nil then fillFrame.BackgroundTransparency = trans end
		end
		function Preview:SetFilled(en, trans)
			fillFrame.Visible = en
			if trans ~= nil then fillFrame.BackgroundTransparency = trans end
		end
		function Preview:SetSkeleton(en) skelFrame.Visible = en end
		function Preview:SetChams(en, color)
			chamOverlay.Visible = en
			if color then updateColor(color); chamOverlay.BackgroundColor3 = color end
		end
		function Preview:SetColor(color) updateColor(color) end
		return Preview
	end

	function Window:Unload()
		-- Disconnect all tracked connections
		for _, c in ipairs(Library._connections) do pcall(function() c:Disconnect() end) end
		Library._connections = {}
		-- Destroy ScreenGui
		local sg = Library._screenGui
		if sg then
			pcall(function() sg:Destroy() end)
			-- Fallback if destroy is blocked
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

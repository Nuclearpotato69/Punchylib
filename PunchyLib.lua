local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

local function Tween(inst, props, t)
	TweenService:Create(inst, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function MakeDraggable(frame, handle)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = input.Position
			startPos  = frame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMove then
			local d = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

local Theme = {
	BgBase       = Color3.fromRGB(14,  14,  16),
	BgPanel      = Color3.fromRGB(19,  19,  22),
	BgInput      = Color3.fromRGB(11,  11,  13),
	BgHover      = Color3.fromRGB(30,  30,  38),
	Accent       = Color3.fromRGB(212, 116, 138),
	AccentDim    = Color3.fromRGB(158, 74,  94),
	Purple       = Color3.fromRGB(160, 127, 212),
	PurpleDim    = Color3.fromRGB(106, 79,  160),
	TextPrimary  = Color3.fromRGB(232, 230, 224),
	TextSecond   = Color3.fromRGB(106, 104, 112),
	TextDim      = Color3.fromRGB(58,  56,  64),
	Border       = Color3.fromRGB(34,  34,  40),
	BorderBright = Color3.fromRGB(46,  46,  58),
	ToggleOff    = Color3.fromRGB(37,  37,  48),
	Green        = Color3.fromRGB(46,  166, 67),
}

local Library   = {}
Library.__index = Library
Library.Toggles = {}
Library.Options = {}
getgenv().PunchyLib = Library

local ScreenGui
do
	pcall(function() if CoreGui:FindFirstChild("PunchyLib") then CoreGui.PunchyLib:Destroy() end end)
	pcall(function() if LocalPlayer.PlayerGui:FindFirstChild("PunchyLib") then LocalPlayer.PlayerGui.PunchyLib:Destroy() end end)
	ScreenGui                = Instance.new("ScreenGui")
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

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title    = cfg.Title    or "Punchy"
	local subtitle = cfg.SubTitle or ""
	local key      = cfg.Key      or Enum.KeyCode.Insert
	local center   = cfg.Center   ~= false
	local autoshow = cfg.AutoShow ~= false

	local pos = center and UDim2.new(0.5, -210, 0.5, -160) or UDim2.new(0, 60, 0, 60)

	local WinFrame = Create("Frame", {
		Name = "Window", Size = UDim2.new(0, 420, 0, 58), Position = pos,
		BackgroundColor3 = Theme.BgPanel, BorderSizePixel = 0, ClipsDescendants = false,
		Visible = autoshow, Parent = ScreenGui,
	}, {
		Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
		Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
	})

	local Titlebar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.BgBase,
		BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0 }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }),
	})

	Create("TextLabel", {
		Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 8, 0.5, -10),
		BackgroundTransparency = 1, Text = "⬡", TextColor3 = Theme.Accent,
		TextScaled = true, Font = Enum.Font.GothamBold, Parent = Titlebar,
	})

	local titleRow = Create("Frame", {
		Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(0, 34, 0, 0),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = Titlebar,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })

	if #title > 0 then
		local body = title:upper():sub(1, -2)
		local last = title:upper():sub(-1)
		if #body > 0 then
			Create("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = body, TextColor3 = Theme.TextPrimary, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = titleRow })
		end
		Create("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = last, TextColor3 = Theme.Accent, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = titleRow })
	end

	if subtitle ~= "" then
		Create("TextLabel", { Size = UDim2.new(0, 10, 1, 0), BackgroundTransparency = 1, Text = "|", TextColor3 = Theme.TextDim, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 3, Parent = titleRow })
		Create("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = subtitle, TextColor3 = Theme.TextSecond, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4, Parent = titleRow })
	end

	local ctrlRow = Create("Frame", {
		Size = UDim2.new(0, 0, 0, 20), Position = UDim2.new(1, -10, 0.5, -10),
		AnchorPoint = Vector2.new(1, 0.5), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1, Parent = Titlebar,
	}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }) })

	Create("TextButton", {
		Size = UDim2.new(0, 50, 0, 16), BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0,
		Text = key.Name:upper(), TextColor3 = Theme.TextSecond, TextSize = 9,
		Font = Enum.Font.GothamMedium, LayoutOrder = 1, Parent = ctrlRow,
	}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

	local MinBtn = Create("TextButton", {
		Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Color3.fromRGB(254, 188, 46),
		BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = 2, Parent = ctrlRow,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local CloseBtn = Create("TextButton", {
		Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Color3.fromRGB(255, 95, 87),
		BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = 3, Parent = ctrlRow,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	MinBtn.MouseEnter:Connect(function()   Tween(MinBtn,   { BackgroundColor3 = Color3.fromRGB(254, 210, 80) }, 0.1) end)
	MinBtn.MouseLeave:Connect(function()   Tween(MinBtn,   { BackgroundColor3 = Color3.fromRGB(254, 188, 46) }, 0.1) end)
	CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(255, 130, 120) }, 0.1) end)
	CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(255, 95,  87)  }, 0.1) end)

	MakeDraggable(WinFrame, Titlebar)

	local TabBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }),
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
	})

	local ContentArea = Create("Frame", {
		Name = "ContentArea", Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 58),
		BackgroundTransparency = 1, ClipsDescendants = false, Parent = WinFrame,
	})

	local StatusBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 58),
		BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0 }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }),
	})

	Create("Frame", {
		Size = UDim2.new(0, 5, 0, 5), Position = UDim2.new(0, 10, 0.5, -2),
		BackgroundColor3 = Theme.Green, BorderSizePixel = 0, Parent = StatusBar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	Create("TextLabel", {
		Size = UDim2.new(0.7, 0, 1, 0), Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1, RichText = true,
		Text = string.format('<font color="#2ea643" weight="700">✓ INJECTED</font> <font color="#3a3840">·</font> <font color="#d4748a">%s</font>', subtitle ~= "" and subtitle or "Ready"),
		TextSize = 9, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusBar,
	})

	local PingLabel = Create("TextLabel", {
		Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -68, 0, 0),
		BackgroundTransparency = 1, Text = "12ms  v2.0", TextColor3 = Theme.TextDim,
		TextSize = 9, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Right, Parent = StatusBar,
	})

	task.spawn(function()
		while task.wait(2.5) do
			local ms = math.random(7, 24)
			PingLabel.Text = ms .. "ms  v2.0"
			PingLabel.TextColor3 = ms > 18 and Color3.fromRGB(212, 170, 67) or Theme.Green
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == key then WinFrame.Visible = not WinFrame.Visible end
	end)

	local minimized = false
	MinBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		ContentArea.Visible = not minimized
		StatusBar.Visible   = not minimized
	end)

	CloseBtn.MouseButton1Click:Connect(function()
		Tween(WinFrame, { BackgroundTransparency = 1 }, 0.2)
		task.wait(0.25)
		WinFrame.Visible = false
		WinFrame.BackgroundTransparency = 0
	end)

	local Window = {
		_frame = WinFrame, _tabBar = TabBar, _content = ContentArea,
		_statusBar = StatusBar, _tabs = {}, _activeTab = nil, _screenGui = ScreenGui,
	}

	function Window:_updateHeight()
		local h = self._activeTab and self._activeTab._page.AbsoluteSize.Y or 0
		ContentArea.Size   = UDim2.new(1, 0, 0, h)
		StatusBar.Position = UDim2.new(0, 0, 0, 58 + h)
		WinFrame.Size      = UDim2.new(0, 420, 0, 58 + h + 22)
	end

	function Window:_switchTab(tab)
		for _, t in ipairs(self._tabs) do
			t._page.Visible = false
			Tween(t._btn, { TextColor3 = Theme.TextSecond }, 0.12)
			t._indicator.BackgroundTransparency = 1
		end
		tab._page.Visible = true
		Tween(tab._btn, { TextColor3 = Theme.Accent }, 0.12)
		tab._indicator.BackgroundTransparency = 0
		self._activeTab = tab
		self:_updateHeight()
	end

	function Window:AddTab(name)
		local btn = Create("TextButton", {
			Size = UDim2.new(0, 0, 1, -1), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1, Text = name, TextColor3 = Theme.TextSecond,
			TextSize = 11, Font = Enum.Font.GothamMedium, BorderSizePixel = 0, Parent = TabBar,
		}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) }) })

		local indicator = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 1.5), Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
			BorderSizePixel = 0, Parent = btn,
		})

		local page = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 10), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Visible = false, Parent = ContentArea,
		}, {
			Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
		})

		local tab = { _btn = btn, _indicator = indicator, _page = page, _win = self, _leftCol = nil, _rightCol = nil }

		page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if self._activeTab == tab then self:_updateHeight() end
		end)

		local function getOrMakeCol(side)
			local which = side == "Left" and "_leftCol" or "_rightCol"
			if not tab[which] then
				tab[which] = Create("Frame", {
					Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1, LayoutOrder = side == "Left" and 1 or 2, Parent = page,
				}, { Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 7) }) })
			end
			return tab[which]
		end

		local function makeGroupbox(gbName, side)
			local col = getOrMakeCol(side)
			local box = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.BgPanel, BorderSizePixel = 0,
				LayoutOrder = #col:GetChildren(), Parent = col,
			}, {
				Create("UIStroke", { Color = Theme.Border, Thickness = 1 }),
				Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
			})

			local hdr = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Theme.BgBase,
				BorderSizePixel = 0, Parent = box,
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
				Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0 }),
				Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }),
			})

			Create("TextLabel", {
				Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 8, 0, 0),
				BackgroundTransparency = 1, Text = gbName:upper(), TextColor3 = Theme.TextSecond,
				TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = hdr,
			})

			local body = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 20),
				AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = box,
			}, {
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }),
				Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
			})

			local GB = { _body = body }

			function GB:AddToggle(k, c2)
				c2 = c2 or {}
				local text = c2.Text or k; local default = c2.Default ~= nil and c2.Default or false
				local cb = c2.Callback or function() end; local color = c2.Color or "accent"
				local accentCol = color == "purple" and Theme.Purple or Theme.Accent
				local accentDim = color == "purple" and Theme.PurpleDim or Theme.AccentDim

				local row = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "",
					BorderSizePixel = 0, LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })

				Create("TextLabel", { Size = UDim2.new(1, -36, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })

				local pill = Create("Frame", {
					Size = UDim2.new(0, 28, 0, 14), Position = UDim2.new(1, -28, 0.5, -7),
					BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0, Parent = row,
				}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local thumb = Create("Frame", {
					Size = UDim2.new(0, 9, 0, 9), Position = UDim2.new(0, 2, 0.5, -4),
					BackgroundColor3 = Theme.TextDim, BorderSizePixel = 0, Parent = pill,
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local value = default
				local stroke = pill:FindFirstChildOfClass("UIStroke")

				local function apply(v, silent)
					value = v
					if v then
						Tween(pill, { BackgroundColor3 = accentDim }, 0.15)
						Tween(thumb, { Position = UDim2.new(0, 16, 0.5, -4), BackgroundColor3 = accentCol }, 0.15)
						stroke.Color = accentCol
					else
						Tween(pill, { BackgroundColor3 = Theme.ToggleOff }, 0.15)
						Tween(thumb, { Position = UDim2.new(0, 2, 0.5, -4), BackgroundColor3 = Theme.TextDim }, 0.15)
						stroke.Color = Theme.BorderBright
					end
					if not silent then pcall(cb, v) end
				end

				apply(default, true)
				row.MouseButton1Click:Connect(function() apply(not value) end)
				row.MouseEnter:Connect(function() row.BackgroundColor3 = Theme.BgHover; row.BackgroundTransparency = 0 end)
				row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)

				local T = {}
				T.SetValue = function(_, v) apply(v) end
				setmetatable(T, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then apply(v) end end })
				Library.Toggles[k] = T
				return T
			end

			function GB:AddSlider(k, c2)
				c2 = c2 or {}
				local text = c2.Text or k; local min = c2.Min or 0; local max = c2.Max or 100
				local default = c2.Default ~= nil and c2.Default or min
				local rounding = c2.Rounding ~= nil and c2.Rounding or 0
				local suffix = c2.Suffix or ""; local color = c2.Color or "accent"
				local cb = c2.Callback or function() end
				local ac = color == "purple" and Theme.Purple or Theme.Accent

				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })

				Create("TextLabel", { Size = UDim2.new(0.55, 0, 0, 16), Position = UDim2.new(0, 0, 0, 3), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap })

				local valLabel = Create("TextLabel", { Size = UDim2.new(0.45, 0, 0, 16), Position = UDim2.new(0.55, 0, 0, 3), BackgroundTransparency = 1, Text = tostring(default)..suffix, TextColor3 = Theme.TextSecond, TextSize = 10, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Right, Parent = wrap })

				local trackBg = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 0, 28),
					BackgroundColor3 = Color3.fromRGB(22, 22, 30), BorderSizePixel = 0, Parent = wrap,
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local fill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ac, BorderSizePixel = 0, Parent = trackBg }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local thumbBtn = Create("TextButton", {
					Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, -4, 0.5, -4),
					BackgroundColor3 = ac, BorderSizePixel = 0, Text = "", ZIndex = 5, Parent = trackBg,
				}, { Create("UIStroke", { Color = Color3.fromRGB(255,255,255), Transparency = 0.85, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				local value = default
				local function applyPct(pct)
					pct = math.clamp(pct, 0, 1)
					local raw = min + (max - min) * pct
					if rounding == 0 then value = math.round(raw)
					else local m = 10^rounding; value = math.floor(raw * m + 0.5) / m end
					fill.Size = UDim2.new(pct, 0, 1, 0)
					thumbBtn.Position = UDim2.new(pct, -4, 0.5, -4)
					valLabel.Text = tostring(value)..suffix
					pcall(cb, value)
				end

				applyPct((default - min) / (max - min))

				local slDrag = false
				thumbBtn.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then slDrag = true end end)
				trackBg.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then
						slDrag = true
						applyPct((inp.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X)
					end
				end)
				UserInputService.InputChanged:Connect(function(inp)
					if slDrag and inp.UserInputType == Enum.UserInputType.MouseMove then
						applyPct((inp.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then slDrag = false end end)

				local S = {}
				S.SetValue = function(_, v) applyPct((v - min) / (max - min)) end
				setmetatable(S, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then applyPct((v - min) / (max - min)) end end })
				Library.Options[k] = S
				return S
			end

			function GB:AddDropdown(k, c2)
				c2 = c2 or {}
				local text = c2.Text or k; local vals = c2.Values or {}
				local default = c2.Default or (vals[1] or ""); local cb = c2.Callback or function() end

				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1,
					ClipsDescendants = false, LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })

				Create("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap })

				local dropBtn = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 22),
					BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0, Text = "", Parent = wrap,
				}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

				local selLabel = Create("TextLabel", { Size = UDim2.new(1, -22, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = default, TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = dropBtn })
				Create("TextLabel", { Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -18, 0, 0), BackgroundTransparency = 1, Text = "▾", TextColor3 = Theme.TextSecond, TextSize = 11, Font = Enum.Font.GothamBold, Parent = dropBtn })

				local listFrame = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 2),
					BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0, Visible = false, ZIndex = 20, Parent = dropBtn,
				}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 2) }), Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })

				local value = default; local open = false

				local function buildList()
					for _, c3 in ipairs(listFrame:GetChildren()) do if c3:IsA("TextButton") then c3:Destroy() end end
					for _, v2 in ipairs(vals) do
						local opt = Create("TextButton", {
							Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0,
							Text = v2, TextColor3 = v2 == value and Theme.Accent or Theme.TextPrimary,
							TextSize = 11, Font = Enum.Font.Gotham, ZIndex = 21, Parent = listFrame,
						}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }) })
						opt.TextXAlignment = Enum.TextXAlignment.Left
						opt.MouseButton1Click:Connect(function()
							value = v2; selLabel.Text = v2; open = false; listFrame.Visible = false
							pcall(cb, v2); buildList()
						end)
						opt.MouseEnter:Connect(function() Tween(opt, { BackgroundColor3 = Theme.BgHover }, 0.08) end)
						opt.MouseLeave:Connect(function() Tween(opt, { BackgroundColor3 = Theme.BgInput }, 0.08) end)
					end
					listFrame.Size = UDim2.new(1, 0, 0, #vals * 22)
				end

				buildList()
				dropBtn.MouseButton1Click:Connect(function() open = not open; listFrame.Visible = open end)
				dropBtn.MouseEnter:Connect(function() Tween(dropBtn, { BackgroundColor3 = Theme.BgHover }, 0.1) end)
				dropBtn.MouseLeave:Connect(function() Tween(dropBtn, { BackgroundColor3 = Theme.BgInput }, 0.1) end)

				local D = { Values = vals }
				D.SetValue = function(_, v) value = v; selLabel.Text = v; pcall(cb, v); buildList() end
				setmetatable(D, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then D:SetValue(v) end end })
				Library.Options[k] = D
				return D
			end

			function GB:AddColorPicker(k, c2)
				c2 = c2 or {}
				local text = c2.Text or k; local default = c2.Default or Theme.Accent; local cb = c2.Callback or function() end

				local row = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })

				Create("TextLabel", { Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })

				local swatch = Create("TextButton", {
					Size = UDim2.new(0, 15, 0, 11), Position = UDim2.new(1, -15, 0.5, -5),
					BackgroundColor3 = default, BorderSizePixel = 0, Text = "", Parent = row,
				}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

				local value = default
				local presets = { Color3.fromRGB(212,116,138), Color3.fromRGB(160,127,212), Color3.fromRGB(67,200,120), Color3.fromRGB(200,180,67), Color3.fromRGB(67,160,200), Color3.fromRGB(232,230,224) }

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
				local text = c2.Text or k; local default = c2.Default or Enum.KeyCode.Unknown; local cb = c2.Callback or function() end

				local row = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "",
					BorderSizePixel = 0, LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })

				Create("TextLabel", { Size = UDim2.new(1, -60, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })

				local badge = Create("TextLabel", {
					Size = UDim2.new(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
					Position = UDim2.new(1, 0, 0.5, -8), AnchorPoint = Vector2.new(1, 0),
					BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0,
					Text = "["..default.Name:upper().."]", TextColor3 = Theme.TextSecond,
					TextSize = 9, Font = Enum.Font.GothamMedium, Parent = row,
				}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 2) }), Create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }) })

				local value = default; local binding = false
				row.MouseButton1Click:Connect(function() binding = true; badge.Text = "[...]"; badge.TextColor3 = Theme.Accent end)
				row.MouseEnter:Connect(function() row.BackgroundColor3 = Theme.BgHover; row.BackgroundTransparency = 0 end)
				row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)

				UserInputService.InputBegan:Connect(function(inp, gpe)
					if binding and not gpe and inp.UserInputType == Enum.UserInputType.Keyboard then
						binding = false; value = inp.KeyCode
						badge.Text = "["..inp.KeyCode.Name:upper().."]"; badge.TextColor3 = Theme.TextSecond
						pcall(cb, value)
					end
				end)

				local KB = {}
				KB.SetValue = function(_, v) value = v; badge.Text = "["..v.Name:upper().."]" end
				setmetatable(KB, { __index = function(_, k2) if k2 == "Value" then return value end end, __newindex = function(_, k2, v) if k2 == "Value" then KB:SetValue(v) end end })
				Library.Options[k] = KB
				return KB
			end

			function GB:AddButton(c2)
				c2 = c2 or {}
				local text = c2.Text or "Button"; local cb = c2.Callback or function() end

				local wrap = Create("Frame", {
					Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }) })

				local btn = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0,
					Text = text, TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.GothamMedium, Parent = wrap,
				}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

				btn.MouseButton1Click:Connect(function()
					Tween(btn, { BackgroundColor3 = Theme.AccentDim }, 0.08)
					task.wait(0.12)
					Tween(btn, { BackgroundColor3 = Theme.BgInput }, 0.12)
					pcall(cb)
				end)
				btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Theme.BgHover }, 0.1) end)
				btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Theme.BgInput }, 0.1) end)
			end

			function GB:AddLabel(text)
				Create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = text,
					TextColor3 = Theme.TextSecond, TextSize = 10, Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
			end

			function GB:AddDivider()
				local wrap = Create("Frame", { Size = UDim2.new(1, 0, 0, 9), BackgroundTransparency = 1, LayoutOrder = #body:GetChildren(), Parent = body })
				Create("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 0.5, 0), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = wrap })
			end

			return GB
		end

		function tab:AddLeftGroupbox(name)  return makeGroupbox(name, "Left")  end
		function tab:AddRightGroupbox(name) return makeGroupbox(name, "Right") end

		btn.MouseButton1Click:Connect(function() self:_switchTab(tab) end)
		btn.MouseEnter:Connect(function() if self._activeTab ~= tab then Tween(btn, { TextColor3 = Theme.TextPrimary }, 0.1) end end)
		btn.MouseLeave:Connect(function() if self._activeTab ~= tab then Tween(btn, { TextColor3 = Theme.TextSecond }, 0.1) end end)

		table.insert(self._tabs, tab)
		if #self._tabs == 1 then self:_switchTab(tab) end
		return tab
	end

	function Window:AddESPPreview()
		local espColor = Theme.Accent
		local chamColor = Theme.Accent

		local previewFrame = Create("Frame", {
			Name = "ESPPreview", Size = UDim2.new(0, 114, 0, 260), Position = UDim2.new(1, 8, 0, 0),
			BackgroundColor3 = Theme.BgPanel, BorderSizePixel = 0, Visible = true, Parent = WinFrame,
		}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })

		local hdr = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0, Parent = previewFrame,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0 }),
			Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }),
		})

		Create("TextLabel", { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = "ESP PREVIEW", TextColor3 = Theme.TextSecond, TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = hdr })

		local dot = Create("Frame", {
			Size = UDim2.new(0, 5, 0, 5), Position = UDim2.new(1, -10, 0.5, -2),
			BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = hdr,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		MakeDraggable(previewFrame, hdr)

		local canvas = Create("Frame", {
			Size = UDim2.new(1, 0, 1, -26), Position = UDim2.new(0, 0, 0, 26),
			BackgroundColor3 = Color3.fromRGB(6, 6, 7), BorderSizePixel = 0, ClipsDescendants = true, Parent = previewFrame,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })

		Create("Frame", {
			Size = UDim2.new(0, 66, 0, 7), Position = UDim2.new(0.5, -33, 1, -10),
			BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.65, BorderSizePixel = 0, ZIndex = 2, Parent = canvas,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		local silhouetteColor = Color3.fromRGB(45, 42, 55)

		local silParts = {
			{ s = UDim2.new(0,16,0,16), p = UDim2.new(0.5,-8,0,18) },
			{ s = UDim2.new(0,22,0,28), p = UDim2.new(0.5,-11,0,40) },
			{ s = UDim2.new(0,8, 0,24), p = UDim2.new(0.5,-19,0,42) },
			{ s = UDim2.new(0,8, 0,24), p = UDim2.new(0.5,11, 0,42) },
			{ s = UDim2.new(0,11,0,36), p = UDim2.new(0.5,-14,0,68) },
			{ s = UDim2.new(0,11,0,36), p = UDim2.new(0.5,3,  0,68) },
			{ s = UDim2.new(0,10,0,28), p = UDim2.new(0.5,-13,0,104) },
			{ s = UDim2.new(0,10,0,28), p = UDim2.new(0.5,3,  0,104) },
		}
		local silFrames = {}
		for _, sp in ipairs(silParts) do
			local f = Create("Frame", { Size = sp.s, Position = sp.p, BackgroundColor3 = silhouetteColor, BorderSizePixel = 0, ZIndex = 2, Parent = canvas })
			table.insert(silFrames, f)
		end
		silFrames[1].Parent = Create("Frame", { Size = UDim2.new(0,16,0,16), Position = UDim2.new(0.5,-8,0,18), BackgroundColor3 = silhouetteColor, BorderSizePixel = 0, ZIndex = 2, Parent = canvas }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		local boxStroke = Create("UIStroke", { Color = espColor, Thickness = 1.5 })
		local boxFrame = Create("Frame", {
			Size = UDim2.new(0, 46, 0, 130), Position = UDim2.new(0.5, -23, 0, 12),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Visible = false, Parent = canvas,
		})
		boxStroke.Parent = boxFrame

		local fillFrame = Create("Frame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = espColor,
			BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = boxFrame,
		})

		local skelFrame = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6, Visible = false, Parent = boxFrame })
		local skelDefs = { {0.5,0,14,1},{0.5,0.09,8,1},{0.5,0.19,22,1},{0.5,0.46,12,1},{0.5,0.6,18,1},{0.5,0.77,16,1} }
		local skelLines = {}
		for _, sd in ipairs(skelDefs) do
			local l = Create("Frame", { Size = UDim2.new(0,sd[3],0,sd[4]), Position = UDim2.new(sd[1],-sd[3]/2,sd[2],0), BackgroundColor3 = espColor, BorderSizePixel = 0, Parent = skelFrame })
			table.insert(skelLines, l)
		end

		local chamOverlay = Create("Frame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = chamColor,
			BackgroundTransparency = 0.67, BorderSizePixel = 0, ZIndex = 3, Visible = false, Parent = canvas,
		})

		local function updateColor(col)
			espColor = col
			dot.BackgroundColor3 = col
			boxStroke.Color = col
			fillFrame.BackgroundColor3 = col
			for _, l in ipairs(skelLines) do l.BackgroundColor3 = col end
		end

		local Preview = {}

		function Preview:SetVisible(v) previewFrame.Visible = v end

		function Preview:SetBox(en, filled, trans)
			boxFrame.Visible = en
			if filled ~= nil then fillFrame.Visible = filled end
			if trans ~= nil then fillFrame.BackgroundTransparency = trans end
		end

		function Preview:SetFilled(en, trans)
			fillFrame.Visible = en
			if trans ~= nil then fillFrame.BackgroundTransparency = trans end
		end

		function Preview:SetSkeleton(en) skelFrame.Visible = en end

		function Preview:SetChams(en, color)
			chamOverlay.Visible = en
			if color then
				chamColor = color
				chamOverlay.BackgroundColor3 = color
				for _, f in ipairs(silFrames) do f.BackgroundColor3 = en and color or silhouetteColor end
			end
		end

		function Preview:SetColor(color) updateColor(color) end

		return Preview
	end

	return Window
end

return Library

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local WIN_W   = 420
local WIN_H   = 440  -- fixed height always
local TAB_H   = 28
local TITLE_H = 30
local STATUS_H= 22
local CONTENT_H = WIN_H - TITLE_H - TAB_H - STATUS_H  -- 360

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

	-- mutable key reference so keybind can update it
	local keyRef = { v = key }
	Library._keyRef = keyRef

	local pos = center and UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) or UDim2.new(0, 60, 0, 60)

	local WinFrame = Create("Frame", {
		Name = "Window", Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = pos,
		BackgroundColor3 = Theme.BgPanel, BorderSizePixel = 0, ClipsDescendants = false,
		Visible = autoshow, Parent = ScreenGui,
	}, {
		Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
		Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
	})

	-- Title bar
	local Titlebar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, TITLE_H), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0 }),
		Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 }),
	})

	MakeDraggable(WinFrame, Titlebar)

	-- Logo dot (replaces broken unicode icon)
	local logoDot = Create("Frame", {
		Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 10, 0.5, -4),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = Titlebar,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })
	-- inner dot
	Create("Frame", {
		Size = UDim2.new(0, 4, 0, 4), Position = UDim2.new(0.5, -2, 0.5, -2),
		BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0, Parent = logoDot,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	-- Title: "PUNCHY | Phantom Forces"
	local fullTitle = title:upper() .. (subtitle ~= "" and ("  |  " .. subtitle) or "")
	Create("TextLabel", {
		Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 26, 0, 0),
		BackgroundTransparency = 1, Text = fullTitle,
		TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = Titlebar,
	})

	-- Key badge
	local keyBadge = Create("TextLabel", {
		Size = UDim2.new(0, 54, 0, 16), Position = UDim2.new(1, -94, 0.5, -8),
		BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0,
		Text = keyRef.v.Name:upper(), TextColor3 = Theme.TextSecond, TextSize = 9,
		Font = Enum.Font.GothamMedium, Parent = Titlebar,
	}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

	local MinBtn = Create("TextButton", {
		Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -30, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(254, 188, 46), BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Parent = Titlebar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local CloseBtn = Create("TextButton", {
		Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -14, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(255, 95, 87), BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Parent = Titlebar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	MinBtn.MouseEnter:Connect(function()   Tween(MinBtn,   { BackgroundColor3 = Color3.fromRGB(254, 210, 80)  }, 0.1) end)
	MinBtn.MouseLeave:Connect(function()   Tween(MinBtn,   { BackgroundColor3 = Color3.fromRGB(254, 188, 46)  }, 0.1) end)
	CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(255, 130, 120) }, 0.1) end)
	CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(255, 95,  87)  }, 0.1) end)

	-- Tab bar (borders parented to WinFrame, not TabBar, to keep them out of UIListLayout)
	local TabBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, TAB_H), Position = UDim2.new(0, 0, 0, TITLE_H),
		BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0, Parent = WinFrame,
	}, {
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 4) }),
	})
	Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, TITLE_H), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = WinFrame })
	Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, TITLE_H + TAB_H - 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = WinFrame })

	-- Content scroll area (fixed height, scrollable)
	local ContentArea = Create("ScrollingFrame", {
		Name = "ContentArea",
		Size = UDim2.new(1, 0, 0, CONTENT_H),
		Position = UDim2.new(0, 0, 0, TITLE_H + TAB_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.BorderBright,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true,
		Parent = WinFrame,
	})

	-- Status bar
	local StatusBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, STATUS_H),
		Position = UDim2.new(0, 0, 0, WIN_H - STATUS_H),
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
		Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1, RichText = true,
		Text = '<font color="#2ea643" weight="700">INJECTED</font>',
		TextSize = 9, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusBar,
	})

	local PingLabel = Create("TextLabel", {
		Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -85, 0, 0),
		BackgroundTransparency = 1, Text = "12ms  v2.0", TextColor3 = Theme.TextDim,
		TextSize = 9, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Right, Parent = StatusBar,
	})

	task.spawn(function()
		while task.wait(2.5) do
			local ms = math.random(7, 24)
			PingLabel.Text = ms.."ms  v2.0"
			PingLabel.TextColor3 = ms > 18 and Color3.fromRGB(212, 170, 67) or Theme.Green
		end
	end)

	-- Toggle visibility on key press (reads from mutable keyRef)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == keyRef.v then
			WinFrame.Visible = not WinFrame.Visible
		end
	end)

	local minimized = false
	MinBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		ContentArea.Visible = not minimized
		StatusBar.Visible   = not minimized
		WinFrame.Size = minimized and UDim2.new(0, WIN_W, 0, TITLE_H + TAB_H + STATUS_H) or UDim2.new(0, WIN_W, 0, WIN_H)
	end)

	CloseBtn.MouseButton1Click:Connect(function()
		Tween(WinFrame, { BackgroundTransparency = 1 }, 0.2)
		task.wait(0.25)
		WinFrame.Visible = false
		WinFrame.BackgroundTransparency = 0
	end)

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
			Tween(t._btn, { TextColor3 = Theme.TextSecond }, 0.12)
			t._indicator.BackgroundTransparency = 1
		end
		tab._page.Visible = true
		Tween(tab._btn, { TextColor3 = Theme.Accent }, 0.12)
		tab._indicator.BackgroundTransparency = 0
		self._activeTab = tab
		-- update scroll canvas to page content height
		ContentArea.CanvasSize = UDim2.new(0, 0, 0, math.max(tab._page.AbsoluteSize.Y, CONTENT_H))
	end

	function Window:AddTab(name)
		local tabW = math.max(60, #name * 8 + 26)

		local btn = Create("TextButton", {
			Size = UDim2.new(0, tabW, 1, -1),
			BackgroundTransparency = 1, Text = name,
			TextColor3 = Theme.TextSecond, TextSize = 11,
			Font = Enum.Font.GothamMedium, BorderSizePixel = 0,
			LayoutOrder = #TabBar:GetChildren(), Parent = TabBar,
		})

		local indicator = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
			BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
			BorderSizePixel = 0, Parent = btn,
		})

		local page = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Visible = false, Parent = ContentArea,
		}, {
			Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
		})

		local tab = { _btn = btn, _indicator = indicator, _page = page, _win = self, _leftCol = nil, _rightCol = nil }

		page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if self._activeTab == tab then
				ContentArea.CanvasSize = UDim2.new(0, 0, 0, math.max(page.AbsoluteSize.Y, CONTENT_H))
			end
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
			}, { Create("UIStroke", { Color = Theme.Border, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 3) }) })

			local hdr = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0, Parent = box,
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
						Tween(pill,  { BackgroundColor3 = accentDim }, 0.15)
						Tween(thumb, { Position = UDim2.new(0, 16, 0.5, -4), BackgroundColor3 = accentCol }, 0.15)
						stroke.Color = accentCol
					else
						Tween(pill,  { BackgroundColor3 = Theme.ToggleOff }, 0.15)
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
					Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1,
					LayoutOrder = #body:GetChildren(), Parent = body,
				}, { Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })

				Create("TextLabel", { Size = UDim2.new(0.6, 0, 0, 18), Position = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.TextPrimary, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap })

				local valLabel = Create("TextLabel", { Size = UDim2.new(0.4, 0, 0, 18), Position = UDim2.new(0.6, 0, 0, 2), BackgroundTransparency = 1, Text = tostring(default)..suffix, TextColor3 = Theme.Accent, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = wrap })

				-- Track: thin pill, clips fill so no corner artifacts
				local trackBg = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 28),
					BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0, ClipsDescendants = true,
					Text = "", AutoButtonColor = false, Parent = wrap,
				}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

				-- Fill (no UICorner - clipped by parent)
				local fill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ac, BorderSizePixel = 0, Parent = trackBg })

				-- Thumb sits on WinFrame layer to not be clipped
				local thumbBtn = Create("TextButton", {
					Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, -6, 0.5, -6),
					BackgroundColor3 = ac, BorderSizePixel = 0, Text = "", ZIndex = 8,
					Parent = trackBg,
				}, {
					Create("UIStroke", { Color = Color3.fromRGB(255,255,255), Transparency = 0.8, Thickness = 1 }),
					Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				})

				-- Make thumb not clipped by giving it a higher ZIndex and making track not ClipsDescendants for it
				-- Actually thumb needs to overflow, so we put it outside the track
				thumbBtn.ClipsDescendants = false

				local value = default
				local slDrag = false

				local function applyPct(pct)
					pct = math.clamp(pct, 0, 1)
					local raw = min + (max - min) * pct
					if rounding == 0 then value = math.round(raw)
					else local m = 10^rounding; value = math.floor(raw * m + 0.5) / m end
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
				Create("TextLabel", { Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -18, 0, 0), BackgroundTransparency = 1, Text = "v", TextColor3 = Theme.TextSecond, TextSize = 9, Font = Enum.Font.GothamBold, Parent = dropBtn })

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
					Size = UDim2.new(0, 52, 0, 16), Position = UDim2.new(1, -52, 0.5, -8),
					BackgroundColor3 = Theme.BgInput, BorderSizePixel = 0,
					Text = "["..default.Name:upper().."]", TextColor3 = Theme.TextSecond,
					TextSize = 9, Font = Enum.Font.GothamMedium, Parent = row,
				}, { Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }), Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

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
				KB.SetValue = function(_, v)
					value = v
					badge.Text = "["..v.Name:upper().."]"
					-- If this is the menu key, update the keyRef and badge in titlebar
					if k == "MenuKey" then
						keyRef.v = v
						keyBadge.Text = v.Name:upper()
					end
				end
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

	-- ESP Preview: manually built R6 mannequin in ViewportFrame (no character cloning = no AvatarEditorPrompts)
	function Window:AddESPPreview()
		local espColor  = Theme.Accent

		local previewFrame = Create("Frame", {
			Name = "ESPPreview", Size = UDim2.new(0, 120, 0, 270), Position = UDim2.new(1, 8, 0, 0),
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
			Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(1, -12, 0.5, -3),
			BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = hdr,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		MakeDraggable(previewFrame, hdr)

		local canvas = Create("Frame", {
			Size = UDim2.new(1, 0, 1, -26), Position = UDim2.new(0, 0, 0, 26),
			BackgroundColor3 = Color3.fromRGB(6, 6, 8), BorderSizePixel = 0,
			ClipsDescendants = true, Parent = previewFrame,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })

		-- Grid floor lines for depth
		for i = 0, 3 do
			Create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0.6 + i * 0.12, 0),
				BackgroundColor3 = Color3.fromRGB(28, 28, 36), BorderSizePixel = 0, Parent = canvas,
			})
		end

		-- ViewportFrame with manually built R6 mannequin
		local viewport = Create("ViewportFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Ambient = Color3.fromRGB(120, 110, 130),
			LightColor = Color3.fromRGB(255, 248, 255),
			LightDirection = Vector3.new(-1, -2, -0.5),
			Parent = canvas,
		})

		local cam = Create("Camera", { FieldOfView = 30, Parent = viewport })
		viewport.CurrentCamera = cam
		cam.CFrame = CFrame.new(Vector3.new(0, 2.8, 9), Vector3.new(0, 2.8, 0))

		local worldModel = Create("WorldModel", { Parent = viewport })

		local skinColor  = Color3.fromRGB(255, 203, 164)
		local shirtColor = Color3.fromRGB(35, 35, 48)
		local pantColor  = Color3.fromRGB(25, 25, 38)
		local shoeColor  = Color3.fromRGB(15, 15, 20)

		local function makePart(sz, pos, col, shape)
			local p = Instance.new("Part")
			p.Size = sz
			p.CFrame = CFrame.new(pos)
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			p.Material = Enum.Material.SmoothPlastic
			p.Color = col
			if shape then p.Shape = shape end
			p.Parent = worldModel
			return p
		end

		-- R6 rig, facing camera (+Z = toward cam at z=9)
		-- Head
		makePart(Vector3.new(1.25, 1.25, 1.25), Vector3.new(0, 5.125, 0), skinColor, Enum.PartType.Ball)
		-- Neck stub
		makePart(Vector3.new(0.4, 0.3, 0.4), Vector3.new(0, 4.4, 0), skinColor)
		-- Torso
		makePart(Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), shirtColor)
		-- Left Arm
		makePart(Vector3.new(0.9, 1.1, 0.9), Vector3.new(-1.45, 3.45, 0), shirtColor)
		makePart(Vector3.new(0.85, 1.1, 0.85), Vector3.new(-1.45, 2.1, 0), skinColor)
		-- Right Arm
		makePart(Vector3.new(0.9, 1.1, 0.9), Vector3.new(1.45, 3.45, 0), shirtColor)
		makePart(Vector3.new(0.85, 1.1, 0.85), Vector3.new(1.45, 2.1, 0), skinColor)
		-- Left Leg
		makePart(Vector3.new(0.95, 1.2, 0.95), Vector3.new(-0.55, 1.4, 0), pantColor)
		makePart(Vector3.new(0.9, 1.2, 0.9), Vector3.new(-0.55, 0.1, 0), pantColor)
		makePart(Vector3.new(0.95, 0.3, 1.15), Vector3.new(-0.55, -0.55, 0.1), shoeColor)
		-- Right Leg
		makePart(Vector3.new(0.95, 1.2, 0.95), Vector3.new(0.55, 1.4, 0), pantColor)
		makePart(Vector3.new(0.9, 1.2, 0.9), Vector3.new(0.55, 0.1, 0), pantColor)
		makePart(Vector3.new(0.95, 0.3, 1.15), Vector3.new(0.55, -0.55, 0.1), shoeColor)
		-- Floor shadow
		makePart(Vector3.new(2.5, 0.05, 1.5), Vector3.new(0, -0.7, 0), Color3.fromRGB(10,10,14))

		-- ESP overlays drawn on top of viewport
		local boxStroke = Instance.new("UIStroke"); boxStroke.Color = espColor; boxStroke.Thickness = 1.5
		local boxFrame = Create("Frame", {
			Size = UDim2.new(0, 52, 0, 145), Position = UDim2.new(0.5, -26, 0, 8),
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Visible = false, Parent = canvas,
		})
		boxStroke.Parent = boxFrame

		local fillFrame = Create("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = espColor, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = boxFrame })

		-- Skeleton lines matching the mannequin
		local skelFrame = Create("Frame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6, Visible = false, Parent = boxFrame })
		local skelDefs = {
			{0.5,0,  4,1},{0.5,0.06,8,1},{0.5,0.17,22,1},
			{0.5,0.44,10,1},{0.5,0.57,18,1},{0.5,0.76,16,1},
		}
		local skelLines = {}
		for _, sd in ipairs(skelDefs) do
			table.insert(skelLines, Create("Frame", { Size = UDim2.new(0,sd[3],0,sd[4]), Position = UDim2.new(sd[1],-sd[3]/2,sd[2],0), BackgroundColor3 = espColor, BorderSizePixel = 0, Parent = skelFrame }))
		end

		-- Healthbar on left
		local healthBg = Create("Frame", {
			Size = UDim2.new(0, 3, 0, 145), Position = UDim2.new(0, -7, 0, 8),
			BackgroundColor3 = Color3.fromRGB(40, 15, 15), BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = canvas,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local healthFill = Create("Frame", {
			Size = UDim2.new(1, 0, 0.8, 0), Position = UDim2.new(0, 0, 0.2, 0),
			BackgroundColor3 = Theme.Green, BorderSizePixel = 0, Parent = healthBg,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

		-- Nametag
		local nameTag = Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, -10),
			BackgroundTransparency = 1, Text = "Player", TextColor3 = espColor,
			TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 6, Visible = false, Parent = boxFrame,
		})

		local chamOverlay = Create("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = espColor, BackgroundTransparency = 0.75, BorderSizePixel = 0, ZIndex = 3, Visible = false, Parent = canvas })

		local function updateColor(col)
			espColor = col; dot.BackgroundColor3 = col; boxStroke.Color = col
			fillFrame.BackgroundColor3 = col; nameTag.TextColor3 = col
			for _, l in ipairs(skelLines) do l.BackgroundColor3 = col end
		end

		local Preview = {}
		function Preview:SetVisible(v) previewFrame.Visible = v end
		function Preview:SetBox(en, filled, trans)
			boxFrame.Visible = en; healthBg.Visible = en; nameTag.Visible = en
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
			if color then espColor = color; chamOverlay.BackgroundColor3 = color; updateColor(color) end
		end
		function Preview:SetColor(color) updateColor(color) end
		return Preview
	end

	-- Unload: properly destroys the ScreenGui
	function Window:Unload()
		pcall(function() ScreenGui:Destroy() end)
	end
	Library._window = Window

	return Window
end

-- Expose unload at library level
function Library:Unload()
	if self._window then self._window:Unload() end
end

return Library

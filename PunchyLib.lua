--[[
    PunchyLib.lua
    A Roblox executor GUI library styled after the Punchy mockup.
    Inspired by Linoria's API structure.

    API OVERVIEW:
    ─────────────────────────────────────────────────
    local Library = loadstring(game:HttpGet(URL))()

    local Window = Library:CreateWindow({
        Title   = "Punchy",
        SubTitle = "Phantom Forces",
        Key     = Enum.KeyCode.Insert,
        Center  = true,
        AutoShow = true,
    })

    local Tab = Window:AddTab("Legit")

    local Box = Tab:AddLeftGroupbox("Aimbot")
    -- or --
    local Box = Tab:AddRightGroupbox("ESP")

    Box:AddToggle("UniqueKey", { Text = "Enable", Default = false, Callback = function(v) end })
    Box:AddSlider("UniqueKey", { Text = "FOV", Min = 0, Max = 180, Default = 90, Rounding = 0, Callback = function(v) end })
    Box:AddDropdown("UniqueKey", { Text = "Bone", Values = {"Head","Torso"}, Default = "Head", Callback = function(v) end })
    Box:AddColorPicker("UniqueKey", { Text = "Color", Default = Color3.fromRGB(212,116,138), Callback = function(v) end })
    Box:AddKeybind("UniqueKey", { Text = "Aim Key", Default = Enum.KeyCode.C, Callback = function(v) end })
    Box:AddButton({ Text = "Do Something", Callback = function() end })
    Box:AddLabel("Some info text")
    Box:AddDivider()

    -- Access values anywhere:
    print(Library.Toggles["UniqueKey"].Value)
    print(Library.Options["UniqueKey"].Value)
    ─────────────────────────────────────────────────
]]

-- ─── Services ───────────────────────────────────────────────────────────────
local Players        = cloneref and cloneref(game:GetService("Players"))        or game:GetService("Players")
local RunService     = cloneref and cloneref(game:GetService("RunService"))      or game:GetService("RunService")
local TweenService   = cloneref and cloneref(game:GetService("TweenService"))    or game:GetService("TweenService")
local UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService")
local CoreGui        = cloneref and cloneref(game:GetService("CoreGui"))         or game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ─── Utility ────────────────────────────────────────────────────────────────
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(inst, props, t)
    TweenService:Create(inst, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMove then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ─── Theme ──────────────────────────────────────────────────────────────────
local Theme = {
    BgBase      = Color3.fromRGB(14,  14,  16),
    BgPanel     = Color3.fromRGB(19,  19,  22),
    BgHover     = Color3.fromRGB(30,  30,  38),
    Accent      = Color3.fromRGB(212, 116, 138),
    AccentDim   = Color3.fromRGB(158, 74,  94),
    Purple      = Color3.fromRGB(160, 127, 212),
    PurpleDim   = Color3.fromRGB(106, 79,  160),
    TextPrimary = Color3.fromRGB(232, 230, 224),
    TextSecond  = Color3.fromRGB(106, 104, 112),
    TextDim     = Color3.fromRGB(58,  56,  64),
    Border      = Color3.fromRGB(34,  34,  40),
    BorderBright= Color3.fromRGB(46,  46,  58),
    ToggleOff   = Color3.fromRGB(37,  37,  48),
    Green       = Color3.fromRGB(46,  166, 67),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0,   0,   0),
}

-- ─── Font (JetBrains Mono via custom font id or fallback) ───────────────────
local FONT      = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular)
local FONT_BOLD = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)

-- ─── Library Object ─────────────────────────────────────────────────────────
local Library = {}
Library.__index = Library

Library.Toggles = {}  -- [key] = { Value = bool, SetValue = fn }
Library.Options  = {}  -- [key] = { Value = any,  SetValue = fn }

getgenv().PunchyLib = Library

-- ─── Window ─────────────────────────────────────────────────────────────────
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "Punchy"
    local subtitle = cfg.SubTitle or ""
    local key      = cfg.Key      or Enum.KeyCode.Insert
    local center   = cfg.Center   ~= false
    local autoshow = cfg.AutoShow ~= false

    -- ── Root ScreenGui ──
    local ScreenGui = Create("ScreenGui", {
        Name            = "PunchyLib",
        ZIndexBehavior  = Enum.ZIndexBehavior.Global,
        ResetOnSpawn    = false,
        DisplayOrder    = 999,
    })
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
        ScreenGui.Parent = CoreGui
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ── Main Window Frame ──
    local startPos = center
        and UDim2.new(0.5, -210, 0.5, -160)
        or  UDim2.new(0,   60,   0,   60)

    local WinFrame = Create("Frame", {
        Name            = "Window",
        Size            = UDim2.new(0, 420, 0, 0), -- height auto via layout
        Position        = startPos,
        BackgroundColor3= Theme.BgPanel,
        BorderSizePixel = 0,
        ClipsDescendants= true,
        Visible         = autoshow,
        Parent          = ScreenGui,
    }, {
        Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
        Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
    })

    -- ── Titlebar ──
    local Titlebar = Create("Frame", {
        Name            = "Titlebar",
        Size            = UDim2.new(1, 0, 0, 30),
        BackgroundColor3= Theme.BgBase,
        BorderSizePixel = 0,
        Parent          = WinFrame,
    }, {
        Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
    })

    -- Logo icon (lightning bolt ImageLabel — use a simple triangle as placeholder)
    local LogoFrame = Create("Frame", {
        Size            = UDim2.new(0, 20, 0, 20),
        Position        = UDim2.new(0, 10, 0.5, -10),
        BackgroundTransparency = 1,
        Parent          = Titlebar,
    })
    -- Draw bolt shape via a colored label (simple stand-in; swap with ImageLabel + bolt asset)
    Create("TextLabel", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text            = "⚡",
        TextColor3      = Theme.Accent,
        TextScaled      = true,
        Font            = Enum.Font.GothamBold,
        Parent          = LogoFrame,
    })

    -- Title text
    local TitleLabel = Create("TextLabel", {
        Size            = UDim2.new(0, 200, 1, 0),
        Position        = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1,
        RichText        = true,
        Text            = string.format(
            '<font color="#e8e6e0" weight="700">%s</font><font color="#d4748a" weight="700">·</font>',
            title:upper()
        ) .. (subtitle ~= "" and string.format(' <font color="#6a6870" size="11">%s</font>', subtitle) or ""),
        TextColor3      = Theme.TextPrimary,
        TextSize        = 12,
        FontFace        = FONT_BOLD,
        TextXAlignment  = Enum.TextXAlignment.Left,
        Parent          = Titlebar,
    })

    -- Keybind badge
    local KeyBadge = Create("TextButton", {
        Size            = UDim2.new(0, 46, 0, 16),
        Position        = UDim2.new(1, -90, 0.5, -8),
        BackgroundColor3= Theme.BgBase,
        BorderSizePixel = 0,
        Text            = key.Name:upper(),
        TextColor3      = Theme.TextSecond,
        TextSize        = 9,
        FontFace        = FONT,
        Parent          = Titlebar,
    }, {
        Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
        Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
    })

    -- Min / Close buttons
    local function WinDot(color, xOffset)
        return Create("TextButton", {
            Size            = UDim2.new(0, 10, 0, 10),
            Position        = UDim2.new(1, xOffset, 0.5, -5),
            BackgroundColor3= color,
            BorderSizePixel = 0,
            Text            = "",
            Parent          = Titlebar,
        }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    end
    local MinBtn   = WinDot(Color3.fromRGB(254,188,46),  -28)
    local CloseBtn = WinDot(Color3.fromRGB(255, 95, 87), -14)

    MakeDraggable(WinFrame, Titlebar)

    -- ── Tab bar ──
    local TabBar = Create("Frame", {
        Name            = "TabBar",
        Size            = UDim2.new(1, 0, 0, 28),
        Position        = UDim2.new(0, 0, 0, 30),
        BackgroundColor3= Theme.BgBase,
        BorderSizePixel = 0,
        ClipsDescendants= true,
        Parent          = WinFrame,
    }, {
        Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        Create("UIListLayout", {
            FillDirection  = Enum.FillDirection.Horizontal,
            SortOrder      = Enum.SortOrder.LayoutOrder,
            Padding        = UDim.new(0, 0),
        }),
    })

    -- ── Content area (tab pages live here) ──
    local ContentArea = Create("Frame", {
        Name            = "ContentArea",
        Size            = UDim2.new(1, 0, 0, 0), -- resized per tab
        Position        = UDim2.new(0, 0, 0, 58),
        BackgroundTransparency = 1,
        ClipsDescendants= false,
        Parent          = WinFrame,
    })

    -- ── Status bar ──
    local StatusBar = Create("Frame", {
        Name            = "StatusBar",
        Size            = UDim2.new(1, 0, 0, 22),
        BackgroundColor3= Theme.BgBase,
        BorderSizePixel = 0,
        Parent          = WinFrame,
    }, {
        Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
    })

    -- Status dot
    Create("Frame", {
        Size            = UDim2.new(0, 5, 0, 5),
        Position        = UDim2.new(0, 10, 0.5, -2),
        BackgroundColor3= Theme.Green,
        BorderSizePixel = 0,
        Parent          = StatusBar,
    }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

    -- Status text
    local StatusText = Create("TextLabel", {
        Size            = UDim2.new(0.6, 0, 1, 0),
        Position        = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        RichText        = true,
        Text            = string.format(
            '<font color="#2ea643" weight="700">✓ INJECTED</font> <font color="#3a3840">·</font> <font color="#d4748a">%s</font>',
            subtitle ~= "" and subtitle or "Ready"
        ),
        TextSize        = 9,
        FontFace        = FONT,
        TextXAlignment  = Enum.TextXAlignment.Left,
        Parent          = StatusBar,
    })

    -- Ping label
    local PingLabel = Create("TextLabel", {
        Size            = UDim2.new(0, 60, 1, 0),
        Position        = UDim2.new(1, -70, 0, 0),
        BackgroundTransparency = 1,
        Text            = "12ms  v1.0",
        TextColor3      = Theme.TextDim,
        TextSize        = 9,
        FontFace        = FONT,
        TextXAlignment  = Enum.TextXAlignment.Right,
        Parent          = StatusBar,
    })

    -- Fake ping loop
    task.spawn(function()
        while task.wait(2.5) do
            local ms = math.random(7, 24)
            PingLabel.Text = ms .. "ms  v1.0"
            PingLabel.TextColor3 = ms > 18 and Color3.fromRGB(212,170,67) or Theme.Green
        end
    end)

    -- ── Toggle visibility with keybind ──
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == key then
            WinFrame.Visible = not WinFrame.Visible
        end
    end)

    -- ── Min / Close logic ──
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        ContentArea.Visible = not minimized
        StatusBar.Visible   = not minimized
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(WinFrame, { BackgroundTransparency = 1 }, 0.2)
        task.wait(0.2)
        WinFrame.Visible = false
        WinFrame.BackgroundTransparency = 0
    end)

    -- ── Window object ──────────────────────────────────────────────────────
    local Window = {}
    Window._tabBar      = TabBar
    Window._content     = ContentArea
    Window._statusBar   = StatusBar
    Window._frame       = WinFrame
    Window._tabs        = {}
    Window._activeTab   = nil

    function Window:_updateHeight()
        local h = 0
        if self._activeTab then
            self._content.Size = self._activeTab._page.Size
            h = self._activeTab._page.Size.Y.Offset
        end
        WinFrame.Size = UDim2.new(0, 420, 0, 58 + h + 22)
        StatusBar.Position = UDim2.new(0, 0, 0, 58 + h)
    end

    function Window:_switchTab(tab)
        for _, t in ipairs(self._tabs) do
            t._page.Visible = false
            Tween(t._btn, { TextColor3 = Theme.TextSecond }, 0.1)
            t._indicator.BackgroundTransparency = 1
        end
        tab._page.Visible = true
        Tween(tab._btn, { TextColor3 = Theme.Accent }, 0.1)
        tab._indicator.BackgroundTransparency = 0
        self._activeTab = tab
        self:_updateHeight()
    end

    function Window:AddTab(name)
        -- Tab button
        local btn = Create("TextButton", {
            Size            = UDim2.new(0, 0, 1, -1),
            AutomaticSize   = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text            = name,
            TextColor3      = Theme.TextSecond,
            TextSize        = 11,
            FontFace        = FONT,
            BorderSizePixel = 0,
            Parent          = TabBar,
        })
        -- bottom underline indicator
        local indicator = Create("Frame", {
            Size            = UDim2.new(1, 0, 0, 1.5),
            Position        = UDim2.new(0, 0, 1, -1),
            BackgroundColor3= Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent          = btn,
        })
        -- padding inside btn
        Create("UIPadding", { PaddingLeft = UDim.new(0,13), PaddingRight = UDim.new(0,13), Parent = btn })

        -- Tab page (two column layout)
        local page = Create("Frame", {
            Size            = UDim2.new(1, 0, 0, 10),
            BackgroundTransparency = 1,
            Visible         = false,
            Parent          = ContentArea,
        })
        local pageLayout = Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding       = UDim.new(0, 8),
            SortOrder     = Enum.SortOrder.LayoutOrder,
            Parent        = page,
        })
        Create("UIPadding", {
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10),
            PaddingTop    = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            Parent        = page,
        })

        local Tab = {}
        Tab._btn       = btn
        Tab._indicator = indicator
        Tab._page      = page
        Tab._win       = self
        Tab._leftCol   = nil
        Tab._rightCol  = nil

        function Tab:_getOrMakeCol(side)
            local which = side == "Left" and "_leftCol" or "_rightCol"
            if not self[which] then
                local col = Create("Frame", {
                    Size            = UDim2.new(0.5, -4, 0, 0),
                    AutomaticSize   = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    LayoutOrder     = side == "Left" and 1 or 2,
                    Parent          = page,
                })
                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding   = UDim.new(0, 7),
                    Parent    = col,
                })
                self[which] = col
            end
            return self[which]
        end

        function Tab:_afterLayout()
            -- resize page height to tallest column
            local lh = self._leftCol  and self._leftCol.AbsoluteSize.Y  or 0
            local rh = self._rightCol and self._rightCol.AbsoluteSize.Y or 0
            local h  = math.max(lh, rh)
            page.Size = UDim2.new(1, 0, 0, h + 20)
            self._win:_updateHeight()
        end

        function Tab:AddLeftGroupbox(name)
            return self:_makeGroupbox(name, "Left")
        end

        function Tab:AddRightGroupbox(name)
            return self:_makeGroupbox(name, "Right")
        end

        function Tab:_makeGroupbox(name, side)
            local col = self:_getOrMakeCol(side)

            local box = Create("Frame", {
                Size            = UDim2.new(1, 0, 0, 0),
                AutomaticSize   = Enum.AutomaticSize.Y,
                BackgroundColor3= Theme.BgPanel,
                BorderSizePixel = 0,
                LayoutOrder     = #col:GetChildren(),
                Parent          = col,
            }, {
                Create("UIStroke", { Color = Theme.Border, Thickness = 1 }),
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })

            -- Section header
            local hdr = Create("Frame", {
                Name            = "Header",
                Size            = UDim2.new(1, 0, 0, 20),
                BackgroundColor3= Theme.BgBase,
                BorderSizePixel = 0,
                Parent          = box,
            }, {
                Create("UIStroke", { Color = Theme.Border, Thickness = 1 }),
            })
            Create("TextLabel", {
                Size            = UDim2.new(1, -8, 1, 0),
                Position        = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text            = name:upper(),
                TextColor3      = Theme.TextSecond,
                TextSize        = 9,
                FontFace        = FONT_BOLD,
                TextXAlignment  = Enum.TextXAlignment.Left,
                LetterSpacing   = 2,
                Parent          = hdr,
            })

            -- Body container
            local body = Create("Frame", {
                Name            = "Body",
                Size            = UDim2.new(1, 0, 0, 0),
                Position        = UDim2.new(0, 0, 0, 20),
                AutomaticSize   = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent          = box,
            })
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 0),
                Parent    = body,
            })
            Create("UIPadding", {
                PaddingTop    = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                Parent        = body,
            })

            -- After any resize, relay the tab height
            body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                tab:_afterLayout()
            end)

            -- ── Groupbox Object ───────────────────────────────────────────
            local Groupbox = {}
            Groupbox._body = body
            Groupbox._tab  = tab

            -- ── Toggle ───────────────────────────────────────────────────
            function Groupbox:AddToggle(key, cfg2)
                cfg2 = cfg2 or {}
                local text     = cfg2.Text    or key
                local default  = cfg2.Default ~= nil and cfg2.Default or false
                local callback = cfg2.Callback or function() end

                local row = Create("TextButton", {
                    Size            = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Text            = "",
                    BorderSizePixel = 0,
                    LayoutOrder     = #body:GetChildren(),
                    Parent          = body,
                })
                Create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = row })

                Create("TextLabel", {
                    Size            = UDim2.new(1, -40, 1, 0),
                    BackgroundTransparency = 1,
                    Text            = text,
                    TextColor3      = Theme.TextPrimary,
                    TextSize        = 11,
                    FontFace        = FONT,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    Parent          = row,
                })

                -- Toggle pill
                local pill = Create("Frame", {
                    Size     = UDim2.new(0, 28, 0, 14),
                    Position = UDim2.new(1, -28, 0.5, -7),
                    BackgroundColor3 = Theme.ToggleOff,
                    BorderSizePixel  = 0,
                    Parent           = row,
                }, {
                    Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })
                local thumb = Create("Frame", {
                    Size     = UDim2.new(0, 9, 0, 9),
                    Position = UDim2.new(0, 2, 0.5, -4),
                    BackgroundColor3 = Theme.TextDim,
                    BorderSizePixel  = 0,
                    Parent           = pill,
                }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

                local value = default

                local function apply(v, silent)
                    value = v
                    if v then
                        Tween(pill,  { BackgroundColor3 = Theme.AccentDim }, 0.15)
                        Tween(thumb, { Position = UDim2.new(0, 16, 0.5, -4), BackgroundColor3 = Theme.Accent }, 0.15)
                        pill:FindFirstChildOfClass("UIStroke").Color = Theme.Accent
                    else
                        Tween(pill,  { BackgroundColor3 = Theme.ToggleOff }, 0.15)
                        Tween(thumb, { Position = UDim2.new(0, 2, 0.5, -4), BackgroundColor3 = Theme.TextDim }, 0.15)
                        pill:FindFirstChildOfClass("UIStroke").Color = Theme.BorderBright
                    end
                    if not silent then callback(v) end
                end

                apply(default, true)

                row.MouseButton1Click:Connect(function() apply(not value) end)
                row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.BgHover }, 0.1) end)
                row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Color3.new(0,0,0) }, 0.1); row.BackgroundTransparency = 1 end)

                local Toggle = {
                    Value = value,
                    SetValue = function(self, v) apply(v) end,
                }
                setmetatable(Toggle, { __newindex = function(t, k, v)
                    if k == "Value" then apply(v) end
                end })

                Library.Toggles[key] = Toggle
                return Toggle
            end

            -- ── Slider ───────────────────────────────────────────────────
            function Groupbox:AddSlider(key, cfg2)
                cfg2 = cfg2 or {}
                local text     = cfg2.Text     or key
                local min      = cfg2.Min      or 0
                local max      = cfg2.Max      or 100
                local default  = cfg2.Default  or min
                local rounding = cfg2.Rounding ~= nil and cfg2.Rounding or 0
                local suffix   = cfg2.Suffix   or ""
                local callback = cfg2.Callback or function() end
                local color    = cfg2.Color    or "accent" -- "accent" or "purple"

                local wrap = Create("Frame", {
                    Size            = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    LayoutOrder     = #body:GetChildren(),
                    Parent          = body,
                })
                Create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = wrap })

                local nameLabel = Create("TextLabel", {
                    Size            = UDim2.new(0.6, 0, 0, 16),
                    Position        = UDim2.new(0, 0, 0, 2),
                    BackgroundTransparency = 1,
                    Text            = text,
                    TextColor3      = Theme.TextPrimary,
                    TextSize        = 11,
                    FontFace        = FONT,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    Parent          = wrap,
                })
                local valLabel = Create("TextLabel", {
                    Size            = UDim2.new(0.4, 0, 0, 16),
                    Position        = UDim2.new(0.6, 0, 0, 2),
                    BackgroundTransparency = 1,
                    Text            = tostring(default) .. suffix,
                    TextColor3      = Theme.TextSecond,
                    TextSize        = 10,
                    FontFace        = FONT,
                    TextXAlignment  = Enum.TextXAlignment.Right,
                    Parent          = wrap,
                })

                local trackBg = Create("Frame", {
                    Size            = UDim2.new(1, 0, 0, 3),
                    Position        = UDim2.new(0, 0, 0, 26),
                    BackgroundColor3= Color3.fromRGB(26,26,34),
                    BorderSizePixel = 0,
                    Parent          = wrap,
                }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

                local accentColor = color == "purple" and Theme.Purple or Theme.Accent
                local fill = Create("Frame", {
                    Size            = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3= accentColor,
                    BorderSizePixel = 0,
                    Parent          = trackBg,
                }, { Create("UICorner", { CornerRadius = UDim.new(1,0) }) })

                local thumbBtn = Create("TextButton", {
                    Size            = UDim2.new(0, 8, 0, 8),
                    Position        = UDim2.new(0, 0, 0.5, -4),
                    BackgroundColor3= accentColor,
                    BorderSizePixel = 0,
                    Text            = "",
                    ZIndex          = 5,
                    Parent          = trackBg,
                }, {
                    Create("UIStroke", { Color = Color3.fromRGB(255,255,255), Transparency = 0.85, Thickness = 1 }),
                    Create("UICorner", { CornerRadius = UDim.new(1,0) }),
                })

                local value = default

                local function applyPct(pct)
                    pct = math.clamp(pct, 0, 1)
                    value = min + (max - min) * pct
                    if rounding == 0 then value = math.round(value) else
                        local m = 10^rounding; value = math.floor(value*m+0.5)/m
                    end
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    thumbBtn.Position = UDim2.new(pct, -4, 0.5, -4)
                    valLabel.Text = tostring(value) .. suffix
                    callback(value)
                end

                local initPct = (default - min) / (max - min)
                applyPct(initPct)

                local dragging2 = false
                thumbBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging2 = true end
                end)
                trackBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging2 = true
                        local pct = (input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X
                        applyPct(pct)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging2 and input.UserInputType == Enum.UserInputType.MouseMove then
                        local pct = (input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X
                        applyPct(pct)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging2 = false end
                end)

                local Slider = {
                    Value    = value,
                    SetValue = function(self, v)
                        applyPct((v - min) / (max - min))
                    end,
                }
                Library.Options[key] = Slider
                return Slider
            end

            -- ── Dropdown ─────────────────────────────────────────────────
            function Groupbox:AddDropdown(key, cfg2)
                cfg2 = cfg2 or {}
                local text     = cfg2.Text     or key
                local values   = cfg2.Values   or {}
                local default  = cfg2.Default  or (values[1] or "")
                local callback = cfg2.Callback or function() end

                local wrap = Create("Frame", {
                    Size            = UDim2.new(1, 0, 0, 48),
                    BackgroundTransparency = 1,
                    LayoutOrder     = #body:GetChildren(),
                    ClipsDescendants= false,
                    Parent          = body,
                })
                Create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = wrap })

                Create("TextLabel", {
                    Size            = UDim2.new(1, 0, 0, 16),
                    Position        = UDim2.new(0, 0, 0, 2),
                    BackgroundTransparency = 1,
                    Text            = text,
                    TextColor3      = Theme.TextPrimary,
                    TextSize        = 11,
                    FontFace        = FONT,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    Parent          = wrap,
                })

                local dropBtn = Create("TextButton", {
                    Size            = UDim2.new(1, 0, 0, 22),
                    Position        = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3= Theme.BgBase,
                    BorderSizePixel = 0,
                    Text            = "",
                    Parent          = wrap,
                }, {
                    Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
                    Create("UICorner", { CornerRadius = UDim.new(0,2) }),
                })
                local selectedLabel = Create("TextLabel", {
                    Size            = UDim2.new(1, -24, 1, 0),
                    Position        = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = default,
                    TextColor3      = Theme.TextPrimary,
                    TextSize        = 11,
                    FontFace        = FONT,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    Parent          = dropBtn,
                })
                Create("TextLabel", { -- chevron
                    Size            = UDim2.new(0, 16, 1, 0),
                    Position        = UDim2.new(1, -18, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = "▾",
                    TextColor3      = Theme.TextSecond,
                    TextSize        = 11,
                    FontFace        = FONT,
                    Parent          = dropBtn,
                })

                -- dropdown list (rendered above everything)
                local listFrame = Create("Frame", {
                    Size            = UDim2.new(1, 0, 0, 0),
                    Position        = UDim2.new(0, 0, 1, 2),
                    BackgroundColor3= Theme.BgBase,
                    BorderSizePixel = 0,
                    Visible         = false,
                    ZIndex          = 20,
                    Parent          = dropBtn,
                }, {
                    Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
                    Create("UICorner", { CornerRadius = UDim.new(0,2) }),
                    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,0) }),
                })

                local value = default
                local open  = false

                local function buildList()
                    for _, c in ipairs(listFrame:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, v2 in ipairs(values) do
                        local opt = Create("TextButton", {
                            Size            = UDim2.new(1, 0, 0, 22),
                            BackgroundColor3= Theme.BgBase,
                            BorderSizePixel = 0,
                            Text            = v2,
                            TextColor3      = v2 == value and Theme.Accent or Theme.TextPrimary,
                            TextSize        = 11,
                            FontFace        = FONT,
                            ZIndex          = 21,
                            Parent          = listFrame,
                        })
                        Create("UIPadding", { PaddingLeft = UDim.new(0,8), Parent = opt })
                        opt.TextXAlignment = Enum.TextXAlignment.Left
                        opt.MouseButton1Click:Connect(function()
                            value = v2
                            selectedLabel.Text = v2
                            open = false
                            listFrame.Visible = false
                            callback(v2)
                            buildList()
                        end)
                        opt.MouseEnter:Connect(function() Tween(opt, { BackgroundColor3 = Theme.BgHover }, 0.08) end)
                        opt.MouseLeave:Connect(function() Tween(opt, { BackgroundColor3 = Theme.BgBase }, 0.08) end)
                    end
                    listFrame.Size = UDim2.new(1, 0, 0, #values * 22 + 4)
                end

                buildList()

                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    listFrame.Visible = open
                end)

                local Dropdown = {
                    Value    = value,
                    Values   = values,
                    SetValue = function(self, v)
                        value = v
                        selectedLabel.Text = v
                        callback(v)
                        buildList()
                    end,
                }
                Library.Options[key] = Dropdown
                return Dropdown
            end

            -- ── ColorPicker ───────────────────────────────────────────────
            function Groupbox:AddColorPicker(key, cfg2)
                cfg2 = cfg2 or {}
                local text     = cfg2.Text     or key
                local default  = cfg2.Default  or Theme.Accent
                local callback = cfg2.Callback or function() end

                local row = Create("Frame", {
                    Size            = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    LayoutOrder     = #body:GetChildren(),
                    Parent          = body,
                })
                Create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = row })

                Create("TextLabel", {
                    Size            = UDim2.new(1, -24, 1, 0),
                    BackgroundTransparency = 1,
                    Text            = text,
                    TextColor3      = Theme.TextPrimary,
                    TextSize        = 11,
                    FontFace        = FONT,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    Parent          = row,
                })

                local swatch = Create("TextButton", {
                    Size            = UDim2.new(0, 15, 0, 11),
                    Position        = UDim2.new(1, -15, 0.5, -5),
                    BackgroundColor3= default,
                    BorderSizePixel = 0,
                    Text            = "",
                    Parent          = row,
                }, {
                    Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
                    Create("UICorner", { CornerRadius = UDim.new(0,2) }),
                })

                -- Simple HEX input popup on click
                local value = default
                swatch.MouseButton1Click:Connect(function()
                    -- In a real executor you'd open a full HSV picker.
                    -- Here we cycle some preset colors as a demo.
                    local presets = {
                        Color3.fromRGB(212,116,138),
                        Color3.fromRGB(160,127,212),
                        Color3.fromRGB(67,200,120),
                        Color3.fromRGB(200,180,67),
                        Color3.fromRGB(255,255,255),
                    }
                    local idx = 1
                    for i, c in ipairs(presets) do
                        if c == value then idx = i % #presets + 1; break end
                    end
                    value = presets[idx]
                    swatch.BackgroundColor3 = value
                    callback(value)
                end)

                local CP = { Value = value, SetValue = function(self, v) value = v; swatch.BackgroundColor3 = v; callback(v) end }
                Library.Options[key] = CP
                return CP
            end

            -- ── Keybind ───────────────────────────────────────────────────
            function Groupbox:AddKeybind(key, cfg2)
                cfg2 = cfg2 or {}
                local text     = cfg2.Text     or key
                local default  = cfg2.Default  or Enum.KeyCode.Unknown
                local callback = cfg2.Callback or function() end

                local row = Create("TextButton", {
                    Size            = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Text            = "",
                    BorderSizePixel = 0,
                    LayoutOrder     = #body:GetChildren(),
                    Parent          = body,
                })
                Create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = row })

                Create("TextLabel", {
                    Size            = UDim2.new(0.6, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text            = text,
                    TextColor3      = Theme.TextPrimary,
                    TextSize        = 11,
                    FontFace        = FONT,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    Parent          = row,
                })

                local badge = Create("TextLabel", {
                    Size            = UDim2.new(0, 0, 0, 16),
                    AutomaticSize   = Enum.AutomaticSize.X,
                    Position        = UDim2.new(1, 0, 0.5, -8),
                    AnchorPoint     = Vector2.new(1, 0),
                    BackgroundColor3= Theme.BgBase,
                    BorderSizePixel = 0,
                    Text            = default.Name:upper(),
                    TextColor3      = Theme.TextSecond,
                    TextSize        = 9,
                    FontFace        = FONT,
                    Parent          = row,
                }, {
                    Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
                    Create("UICorner", { CornerRadius = UDim.new(0,2) }),
                    Create("UIPadding", { PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4) }),
                })

                local value   = default
                local binding = false

                row.MouseButton1Click:Connect(function()
                    binding = true
                    badge.Text = "..."
                    badge.TextColor3 = Theme.Accent
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if binding and not gpe then
                        binding = false
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            value = input.KeyCode
                            badge.Text = input.KeyCode.Name:upper()
                            badge.TextColor3 = Theme.TextSecond
                            callback(value)
                        end
                    end
                end)

                local KB = { Value = value, SetValue = function(self, v) value = v; badge.Text = v.Name:upper() end }
                Library.Options[key] = KB
                return KB
            end

            -- ── Button ────────────────────────────────────────────────────
            function Groupbox:AddButton(cfg2)
                cfg2 = cfg2 or {}
                local text     = cfg2.Text     or "Button"
                local callback = cfg2.Callback or function() end

                local btn = Create("TextButton", {
                    Size            = UDim2.new(1, -16, 0, 24),
                    Position        = UDim2.new(0, 8, 0, 0),
                    BackgroundColor3= Theme.BgBase,
                    BorderSizePixel = 0,
                    Text            = text,
                    TextColor3      = Theme.TextPrimary,
                    TextSize        = 11,
                    FontFace        = FONT,
                    LayoutOrder     = #body:GetChildren(),
                    Parent          = body,
                }, {
                    Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
                    Create("UICorner", { CornerRadius = UDim.new(0,2) }),
                })
                Create("UIPadding", { PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4), Parent = body })

                btn.MouseButton1Click:Connect(function()
                    Tween(btn, { BackgroundColor3 = Theme.AccentDim }, 0.1)
                    task.wait(0.15)
                    Tween(btn, { BackgroundColor3 = Theme.BgBase }, 0.15)
                    callback()
                end)
                btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Theme.BgHover }, 0.1) end)
                btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Theme.BgBase }, 0.1) end)
            end

            -- ── Label ─────────────────────────────────────────────────────
            function Groupbox:AddLabel(text)
                Create("TextLabel", {
                    Size            = UDim2.new(1, -16, 0, 20),
                    Position        = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text            = text,
                    TextColor3      = Theme.TextSecond,
                    TextSize        = 10,
                    FontFace        = FONT,
                    TextXAlignment  = Enum.TextXAlignment.Left,
                    TextWrapped     = true,
                    LayoutOrder     = #body:GetChildren(),
                    Parent          = body,
                })
            end

            -- ── Divider ───────────────────────────────────────────────────
            function Groupbox:AddDivider()
                Create("Frame", {
                    Size            = UDim2.new(1, -16, 0, 1),
                    Position        = UDim2.new(0, 8, 0, 0),
                    BackgroundColor3= Theme.Border,
                    BorderSizePixel = 0,
                    LayoutOrder     = #body:GetChildren(),
                    Parent          = body,
                })
            end

            return Groupbox
        end -- _makeGroupbox

        btn.MouseButton1Click:Connect(function()
            self:_switchTab(tab)
        end)

        table.insert(self._tabs, tab)
        if #self._tabs == 1 then
            self:_switchTab(tab)
        end

        return tab
    end -- AddTab

    return Window
end -- CreateWindow

return Library

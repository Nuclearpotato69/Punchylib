--[[
    PunchyLib.lua  ·  v2.0
    ──────────────────────────────────────────────────────────────────────
    Universal Roblox executor GUI library.
    Compatible with: Synapse X, KRNL, Fluxus, Solara, Wave, Delta, Xeno
    No cloneref required. Safe GUI parenting on all executors.

    API:
        local Library = loadstring(game:HttpGet(URL))()

        local Window = Library:CreateWindow({
            Title    = "MyScript",
            SubTitle = "Game Name",
            Key      = Enum.KeyCode.Insert,
            Center   = true,
            AutoShow = true,
        })

        local Tab  = Window:AddTab("Combat")
        local Box  = Tab:AddLeftGroupbox("Aimbot")
        local Box2 = Tab:AddRightGroupbox("ESP")

        Box:AddToggle("Key", { Text="Enable", Default=false, Callback=function(v) end })
        Box:AddSlider("Key", { Text="FOV", Min=0, Max=180, Default=90, Suffix="°", Callback=function(v) end })
        Box:AddDropdown("Key", { Text="Bone", Values={"Head","Torso"}, Default="Head", Callback=function(v) end })
        Box:AddColorPicker("Key", { Text="Color", Default=Color3.fromRGB(212,116,138), Callback=function(v) end })
        Box:AddKeybind("Key", { Text="Key", Default=Enum.KeyCode.C, Callback=function(v) end })
        Box:AddButton({ Text="Click Me", Callback=function() end })
        Box:AddLabel("Some text")
        Box:AddDivider()

        -- ESP Preview: live ViewportFrame clone of your character with ESP overlays
        local ESPPreview = Window:AddESPPreview()
        ESPPreview:SetBox(true)           -- show/hide box
        ESPPreview:SetChams(true, color)  -- chams on/off + color
        ESPPreview:SetSkeleton(true)      -- skeleton on/off
        ESPPreview:SetFilled(true, 0.5)   -- filled box + transparency
        ESPPreview:SetColor(color)        -- change ESP color
        ESPPreview:SetVisible(bool)       -- show/hide the whole panel

        -- Access values anywhere:
        Library.Toggles["Key"].Value          → bool
        Library.Options["Key"].Value          → any
        Library.Toggles["Key"]:SetValue(bool)
        Library.Options["Key"]:SetValue(val)
    ──────────────────────────────────────────────────────────────────────
]]

-- ─── Services (no cloneref — works everywhere) ───────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ─── Utility ─────────────────────────────────────────────────────────────────
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
            dragging = true; dragStart = input.Position; startPos = frame.Position
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

-- ─── R6 + R15 skeleton helper ─────────────────────────────────────────────────
local function GetSkeleton(char)
    local pairs2 = {}
    local function add(a, b)
        if char:FindFirstChild(a) and char:FindFirstChild(b) then
            table.insert(pairs2, {char[a], char[b]})
        end
    end
    if char:FindFirstChild("UpperTorso") then
        add("Head","UpperTorso") add("UpperTorso","LowerTorso")
        add("UpperTorso","LeftUpperArm") add("LeftUpperArm","LeftLowerArm") add("LeftLowerArm","LeftHand")
        add("UpperTorso","RightUpperArm") add("RightUpperArm","RightLowerArm") add("RightLowerArm","RightHand")
        add("LowerTorso","LeftUpperLeg") add("LeftUpperLeg","LeftLowerLeg") add("LeftLowerLeg","LeftFoot")
        add("LowerTorso","RightUpperLeg") add("RightUpperLeg","RightLowerLeg") add("RightLowerLeg","RightFoot")
    else
        add("Head","Torso") add("Torso","Left Arm") add("Torso","Right Arm")
        add("Torso","Left Leg") add("Torso","Right Leg")
    end
    return pairs2
end

-- ─── Theme ────────────────────────────────────────────────────────────────────
local Theme = {
    BgBase       = Color3.fromRGB(14,  14,  16),
    BgPanel      = Color3.fromRGB(19,  19,  22),
    BgHover      = Color3.fromRGB(30,  30,  38),
    Accent       = Color3.fromRGB(212, 116, 138),
    AccentDim    = Color3.fromRGB(158, 74,  94),
    Purple       = Color3.fromRGB(160, 127, 212),
    TextPrimary  = Color3.fromRGB(232, 230, 224),
    TextSecond   = Color3.fromRGB(106, 104, 112),
    TextDim      = Color3.fromRGB(58,  56,  64),
    Border       = Color3.fromRGB(34,  34,  40),
    BorderBright = Color3.fromRGB(46,  46,  58),
    ToggleOff    = Color3.fromRGB(37,  37,  48),
    Green        = Color3.fromRGB(46,  166, 67),
}

-- ─── Library ──────────────────────────────────────────────────────────────────
local Library   = {}
Library.__index = Library
Library.Toggles = {}
Library.Options  = {}
getgenv().PunchyLib = Library

-- ─── ScreenGui (safe for all executors) ──────────────────────────────────────
local ScreenGui
do
    -- Destroy any old instance first
    pcall(function() if CoreGui:FindFirstChild("PunchyLib") then CoreGui.PunchyLib:Destroy() end end)
    pcall(function() if LocalPlayer.PlayerGui:FindFirstChild("PunchyLib") then LocalPlayer.PlayerGui.PunchyLib:Destroy() end end)

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "PunchyLib"
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.DisplayOrder   = 999

    local ok = pcall(function()
        if gethui then
            ScreenGui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            ScreenGui.Parent = CoreGui
        else
            ScreenGui.Parent = CoreGui
        end
    end)
    if not ok or not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end
Library._screenGui = ScreenGui

-- ═══════════════════════════════════════════════════════════════════════════════
--  CreateWindow
-- ═══════════════════════════════════════════════════════════════════════════════
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "Punchy"
    local subtitle = cfg.SubTitle or ""
    local key      = cfg.Key      or Enum.KeyCode.Insert
    local center   = cfg.Center   ~= false
    local autoshow = cfg.AutoShow ~= false

    local pos = center and UDim2.new(0.5, -210, 0.5, -160) or UDim2.new(0, 60, 0, 60)

    -- ── Root frame ──
    local WinFrame = Create("Frame", {
        Name = "Window", Size = UDim2.new(0, 420, 0, 58),
        Position = pos, BackgroundColor3 = Theme.BgPanel,
        BorderSizePixel = 0, ClipsDescendants = false,
        Visible = autoshow, Parent = ScreenGui,
    }, {
        Create("UIStroke", { Color = Theme.BorderBright, Thickness = 1 }),
        Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
    })

    -- ── Titlebar ──
    local Titlebar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.BgBase,
        BorderSizePixel = 0, Parent = WinFrame,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
        Create("Frame", { Size = UDim2.new(1,0,0,6), Position = UDim2.new(0,0,1,-6), BackgroundColor3 = Theme.BgBase, BorderSizePixel = 0 }),
        Create("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1), BackgroundColor3 = Theme.Border,  BorderSizePixel = 0 }),
    })

    Create("TextLabel", { Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,10,0.5,-9),
        BackgroundTransparency=1, Text="⚡", TextColor3=Theme.Accent, TextScaled=true, Font=Enum.Font.GothamBold, Parent=Titlebar })

    Create("TextLabel", {
        Size=UDim2.new(0,220,1,0), Position=UDim2.new(0,32,0,0), BackgroundTransparency=1, RichText=true,
        Text=string.format('<font color="#e8e6e0" weight="700">%s</font><font color="#d4748a" weight="700"> ·</font>%s',
            title:upper(), subtitle~="" and string.format(' <font color="#6a6870" size="11">%s</font>', subtitle) or ""),
        TextColor3=Theme.TextPrimary, TextSize=12, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=Titlebar,
    })

    Create("TextButton", {
        Size=UDim2.new(0,50,0,16), Position=UDim2.new(1,-88,0.5,-8),
        BackgroundColor3=Theme.BgPanel, BorderSizePixel=0,
        Text=key.Name:upper(), TextColor3=Theme.TextSecond, TextSize=9, Font=Enum.Font.GothamMedium, Parent=Titlebar,
    }, { Create("UIStroke",{Color=Theme.BorderBright,Thickness=1}), Create("UICorner",{CornerRadius=UDim.new(0,2)}) })

    local MinBtn = Create("TextButton", {
        Size=UDim2.new(0,10,0,10), Position=UDim2.new(1,-28,0.5,-5),
        BackgroundColor3=Color3.fromRGB(254,188,46), BorderSizePixel=0, Text="", Parent=Titlebar,
    }, { Create("UICorner",{CornerRadius=UDim.new(1,0)}) })

    local CloseBtn = Create("TextButton", {
        Size=UDim2.new(0,10,0,10), Position=UDim2.new(1,-14,0.5,-5),
        BackgroundColor3=Color3.fromRGB(255,95,87), BorderSizePixel=0, Text="", Parent=Titlebar,
    }, { Create("UICorner",{CornerRadius=UDim.new(1,0)}) })

    MakeDraggable(WinFrame, Titlebar)

    -- ── Tab bar ──
    local TabBar = Create("Frame", {
        Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,30),
        BackgroundColor3=Theme.BgBase, BorderSizePixel=0, Parent=WinFrame,
    }, {
        Create("Frame",{Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.Border, BorderSizePixel=0}),
        Create("Frame",{Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=Theme.Border, BorderSizePixel=0}),
        Create("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder}),
    })

    -- ── Content area ──
    local ContentArea = Create("Frame", {
        Name="ContentArea", Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,58),
        BackgroundTransparency=1, ClipsDescendants=false, Parent=WinFrame,
    })

    -- ── Status bar ──
    local StatusBar = Create("Frame", {
        Size=UDim2.new(1,0,0,22), Position=UDim2.new(0,0,0,58),
        BackgroundColor3=Theme.BgBase, BorderSizePixel=0, Parent=WinFrame,
    }, {
        Create("UICorner",{CornerRadius=UDim.new(0,5)}),
        Create("Frame",{Size=UDim2.new(1,0,0,6), BackgroundColor3=Theme.BgBase, BorderSizePixel=0}),
        Create("Frame",{Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.Border, BorderSizePixel=0}),
    })

    Create("Frame", { Size=UDim2.new(0,5,0,5), Position=UDim2.new(0,10,0.5,-2),
        BackgroundColor3=Theme.Green, BorderSizePixel=0, Parent=StatusBar,
    }, { Create("UICorner",{CornerRadius=UDim.new(1,0)}) })

    Create("TextLabel", {
        Size=UDim2.new(0.7,0,1,0), Position=UDim2.new(0,20,0,0), BackgroundTransparency=1, RichText=true,
        Text=string.format('<font color="#2ea643" weight="700">✓ INJECTED</font> <font color="#3a3840">·</font> <font color="#d4748a">%s</font>',
            subtitle~="" and subtitle or "Ready"),
        TextSize=9, Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left, Parent=StatusBar,
    })

    local PingLabel = Create("TextLabel", {
        Size=UDim2.new(0,60,1,0), Position=UDim2.new(1,-68,0,0), BackgroundTransparency=1,
        Text="12ms  v2.0", TextColor3=Theme.TextDim, TextSize=9, Font=Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Right, Parent=StatusBar,
    })
    task.spawn(function()
        while task.wait(2.5) do
            local ms = math.random(7,24)
            PingLabel.Text = ms.."ms  v2.0"
            PingLabel.TextColor3 = ms>18 and Color3.fromRGB(212,170,67) or Theme.Green
        end
    end)

    -- Toggle key
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
        Tween(WinFrame, {BackgroundTransparency=1}, 0.2)
        task.wait(0.25)
        WinFrame.Visible = false
        WinFrame.BackgroundTransparency = 0
    end)

    -- ── Window object ─────────────────────────────────────────────────────────
    local Window = { _frame=WinFrame, _tabBar=TabBar, _content=ContentArea,
                     _statusBar=StatusBar, _tabs={}, _activeTab=nil, _screenGui=ScreenGui }

    function Window:_updateHeight()
        local h = self._activeTab and self._activeTab._page.AbsoluteSize.Y or 0
        ContentArea.Size   = UDim2.new(1,0,0,h)
        StatusBar.Position = UDim2.new(0,0,0,58+h)
        WinFrame.Size      = UDim2.new(0,420,0,58+h+22)
    end

    function Window:_switchTab(tab)
        for _, t in ipairs(self._tabs) do
            t._page.Visible = false
            Tween(t._btn, {TextColor3=Theme.TextSecond}, 0.12)
            t._indicator.BackgroundTransparency = 1
        end
        tab._page.Visible = true
        Tween(tab._btn, {TextColor3=Theme.Accent}, 0.12)
        tab._indicator.BackgroundTransparency = 0
        self._activeTab = tab
        self:_updateHeight()
    end

    -- ── AddTab ────────────────────────────────────────────────────────────────
    function Window:AddTab(name)
        local btn = Create("TextButton", {
            Size=UDim2.new(0,0,1,-1), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundTransparency=1, Text=name, TextColor3=Theme.TextSecond,
            TextSize=11, Font=Enum.Font.GothamMedium, BorderSizePixel=0, Parent=TabBar,
        }, { Create("UIPadding",{PaddingLeft=UDim.new(0,13),PaddingRight=UDim.new(0,13)}) })

        local indicator = Create("Frame", {
            Size=UDim2.new(1,0,0,1.5), Position=UDim2.new(0,0,1,-1),
            BackgroundColor3=Theme.Accent, BackgroundTransparency=1, BorderSizePixel=0, Parent=btn,
        })

        local page = Create("Frame", {
            Size=UDim2.new(1,0,0,10), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Visible=false, Parent=ContentArea,
        }, {
            Create("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder}),
            Create("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10)}),
        })

        local tab = { _btn=btn, _indicator=indicator, _page=page, _win=self, _leftCol=nil, _rightCol=nil }

        page:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if self._activeTab == tab then self:_updateHeight() end
        end)

        local function getOrMakeCol(side)
            local which = side=="Left" and "_leftCol" or "_rightCol"
            if not tab[which] then
                tab[which] = Create("Frame", {
                    Size=UDim2.new(0.5,-4,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                    BackgroundTransparency=1, LayoutOrder=side=="Left" and 1 or 2, Parent=page,
                }, { Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,7)}) })
            end
            return tab[which]
        end

        -- ── makeGroupbox ──────────────────────────────────────────────────────
        local function makeGroupbox(gbName, side)
            local col = getOrMakeCol(side)

            local box = Create("Frame", {
                Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=Theme.BgPanel, BorderSizePixel=0, LayoutOrder=#col:GetChildren(), Parent=col,
            }, {
                Create("UIStroke",{Color=Theme.Border,Thickness=1}),
                Create("UICorner",{CornerRadius=UDim.new(0,3)}),
            })

            local hdr = Create("Frame", {
                Size=UDim2.new(1,0,0,20), BackgroundColor3=Theme.BgBase, BorderSizePixel=0, Parent=box,
            }, {
                Create("UICorner",{CornerRadius=UDim.new(0,3)}),
                Create("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,1,-6),BackgroundColor3=Theme.BgBase,BorderSizePixel=0}),
                Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Theme.Border,BorderSizePixel=0}),
            })
            Create("TextLabel", {
                Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,8,0,0),
                BackgroundTransparency=1, Text=gbName:upper(), TextColor3=Theme.TextSecond,
                TextSize=9, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr,
            })

            local body = Create("Frame", {
                Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,20),
                AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, Parent=box,
            }, {
                Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)}),
                Create("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)}),
            })

            -- ── GB object ─────────────────────────────────────────────────────
            local GB = { _body = body }

            function GB:AddToggle(k, c2)
                c2 = c2 or {}
                local text=c2.Text or k; local default=c2.Default~=nil and c2.Default or false; local cb=c2.Callback or function()end
                local row = Create("TextButton",{
                    Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text="",BorderSizePixel=0,
                    LayoutOrder=#body:GetChildren(),Parent=body,
                },{Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})})
                Create("TextLabel",{Size=UDim2.new(1,-36,1,0),BackgroundTransparency=1,Text=text,
                    TextColor3=Theme.TextPrimary,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
                local pill=Create("Frame",{Size=UDim2.new(0,28,0,14),Position=UDim2.new(1,-28,0.5,-7),
                    BackgroundColor3=Theme.ToggleOff,BorderSizePixel=0,Parent=row,
                },{Create("UIStroke",{Color=Theme.BorderBright,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(1,0)})})
                local thumb=Create("Frame",{Size=UDim2.new(0,9,0,9),Position=UDim2.new(0,2,0.5,-4),
                    BackgroundColor3=Theme.TextDim,BorderSizePixel=0,Parent=pill,
                },{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
                local value=default; local stroke=pill:FindFirstChildOfClass("UIStroke")
                local function apply(v, silent)
                    value=v
                    if v then
                        Tween(pill,{BackgroundColor3=Theme.AccentDim},0.15)
                        Tween(thumb,{Position=UDim2.new(0,16,0.5,-4),BackgroundColor3=Theme.Accent},0.15)
                        stroke.Color=Theme.Accent
                    else
                        Tween(pill,{BackgroundColor3=Theme.ToggleOff},0.15)
                        Tween(thumb,{Position=UDim2.new(0,2,0.5,-4),BackgroundColor3=Theme.TextDim},0.15)
                        stroke.Color=Theme.BorderBright
                    end
                    if not silent then pcall(cb,v) end
                end
                apply(default,true)
                row.MouseButton1Click:Connect(function() apply(not value) end)
                row.MouseEnter:Connect(function() row.BackgroundColor3=Theme.BgHover;row.BackgroundTransparency=0 end)
                row.MouseLeave:Connect(function() row.BackgroundTransparency=1 end)
                local T={}; T.SetValue=function(_,v) apply(v) end
                setmetatable(T,{__index=function(_,k2) if k2=="Value" then return value end end,
                    __newindex=function(_,k2,v) if k2=="Value" then apply(v) end end})
                Library.Toggles[k]=T; return T
            end

            function GB:AddSlider(k, c2)
                c2=c2 or {}
                local text=c2.Text or k; local min=c2.Min or 0; local max=c2.Max or 100
                local default=c2.Default~=nil and c2.Default or min; local rounding=c2.Rounding~=nil and c2.Rounding or 0
                local suffix=c2.Suffix or ""; local color=c2.Color or "accent"; local cb=c2.Callback or function()end
                local wrap=Create("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,
                    LayoutOrder=#body:GetChildren(),Parent=body,
                },{Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})})
                Create("TextLabel",{Size=UDim2.new(0.55,0,0,16),Position=UDim2.new(0,0,0,2),
                    BackgroundTransparency=1,Text=text,TextColor3=Theme.TextPrimary,TextSize=11,
                    Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
                local valLabel=Create("TextLabel",{Size=UDim2.new(0.45,0,0,16),Position=UDim2.new(0.55,0,0,2),
                    BackgroundTransparency=1,Text=tostring(default)..suffix,TextColor3=Theme.TextSecond,
                    TextSize=10,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Right,Parent=wrap})
                local trackBg=Create("Frame",{Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,0,27),
                    BackgroundColor3=Color3.fromRGB(26,26,34),BorderSizePixel=0,Parent=wrap,
                },{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
                local ac=color=="purple" and Theme.Purple or Theme.Accent
                local fill=Create("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=ac,BorderSizePixel=0,Parent=trackBg},
                    {Create("UICorner",{CornerRadius=UDim.new(1,0)})})
                local thumbBtn=Create("TextButton",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(0,-5,0.5,-5),
                    BackgroundColor3=ac,BorderSizePixel=0,Text="",ZIndex=5,Parent=trackBg,
                },{Create("UIStroke",{Color=Color3.fromRGB(255,255,255),Transparency=0.85,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(1,0)})})
                local value=default
                local function applyPct(pct)
                    pct=math.clamp(pct,0,1)
                    local raw=min+(max-min)*pct
                    value=rounding==0 and math.round(raw) or (function() local m=10^rounding; return math.floor(raw*m+0.5)/m end)()
                    fill.Size=UDim2.new(pct,0,1,0); thumbBtn.Position=UDim2.new(pct,-5,0.5,-5)
                    valLabel.Text=tostring(value)..suffix; pcall(cb,value)
                end
                applyPct((default-min)/(max-min))
                local slDrag=false
                thumbBtn.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then slDrag=true end end)
                trackBg.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.MouseButton1 then slDrag=true
                        applyPct((inp.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X) end end)
                UserInputService.InputChanged:Connect(function(inp)
                    if slDrag and inp.UserInputType==Enum.UserInputType.MouseMove then
                        applyPct((inp.Position.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X) end end)
                UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then slDrag=false end end)
                local S={}; S.SetValue=function(_,v) applyPct((v-min)/(max-min)) end
                setmetatable(S,{__index=function(_,k2) if k2=="Value" then return value end end,
                    __newindex=function(_,k2,v) if k2=="Value" then applyPct((v-min)/(max-min)) end end})
                Library.Options[k]=S; return S
            end

            function GB:AddDropdown(k, c2)
                c2=c2 or {}
                local text=c2.Text or k; local vals=c2.Values or {}
                local default=c2.Default or (vals[1] or ""); local cb=c2.Callback or function()end
                local wrap=Create("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,
                    ClipsDescendants=false,LayoutOrder=#body:GetChildren(),Parent=body,
                },{Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})})
                Create("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,2),
                    BackgroundTransparency=1,Text=text,TextColor3=Theme.TextPrimary,TextSize=11,
                    Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
                local dropBtn=Create("TextButton",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,22),
                    BackgroundColor3=Theme.BgBase,BorderSizePixel=0,Text="",Parent=wrap,
                },{Create("UIStroke",{Color=Theme.BorderBright,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,2)})})
                local selLabel=Create("TextLabel",{Size=UDim2.new(1,-22,1,0),Position=UDim2.new(0,8,0,0),
                    BackgroundTransparency=1,Text=default,TextColor3=Theme.TextPrimary,TextSize=11,
                    Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=dropBtn})
                Create("TextLabel",{Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-18,0,0),
                    BackgroundTransparency=1,Text="▾",TextColor3=Theme.TextSecond,TextSize=11,Font=Enum.Font.GothamBold,Parent=dropBtn})
                local listFrame=Create("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,1,2),
                    BackgroundColor3=Theme.BgBase,BorderSizePixel=0,Visible=false,ZIndex=20,Parent=dropBtn,
                },{Create("UIStroke",{Color=Theme.BorderBright,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,2)}),
                   Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder})})
                local value=default; local open=false
                local function buildList()
                    for _,c3 in ipairs(listFrame:GetChildren()) do if c3:IsA("TextButton") then c3:Destroy() end end
                    for _,v2 in ipairs(vals) do
                        local opt=Create("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundColor3=Theme.BgBase,
                            BorderSizePixel=0,Text=v2,TextColor3=v2==value and Theme.Accent or Theme.TextPrimary,
                            TextSize=11,Font=Enum.Font.Gotham,ZIndex=21,Parent=listFrame,
                        },{Create("UIPadding",{PaddingLeft=UDim.new(0,8)})})
                        opt.TextXAlignment=Enum.TextXAlignment.Left
                        opt.MouseButton1Click:Connect(function()
                            value=v2;selLabel.Text=v2;open=false;listFrame.Visible=false;pcall(cb,v2);buildList() end)
                        opt.MouseEnter:Connect(function() Tween(opt,{BackgroundColor3=Theme.BgHover},0.08) end)
                        opt.MouseLeave:Connect(function() Tween(opt,{BackgroundColor3=Theme.BgBase},0.08) end)
                    end
                    listFrame.Size=UDim2.new(1,0,0,#vals*22)
                end
                buildList()
                dropBtn.MouseButton1Click:Connect(function() open=not open;listFrame.Visible=open end)
                local D={Values=vals}; D.SetValue=function(_,v) value=v;selLabel.Text=v;pcall(cb,v);buildList() end
                setmetatable(D,{__index=function(_,k2) if k2=="Value" then return value end end,
                    __newindex=function(_,k2,v) if k2=="Value" then D:SetValue(v) end end})
                Library.Options[k]=D; return D
            end

            function GB:AddColorPicker(k, c2)
                c2=c2 or {}
                local text=c2.Text or k; local default=c2.Default or Theme.Accent; local cb=c2.Callback or function()end
                local row=Create("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
                    LayoutOrder=#body:GetChildren(),Parent=body,
                },{Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})})
                Create("TextLabel",{Size=UDim2.new(1,-24,1,0),BackgroundTransparency=1,Text=text,
                    TextColor3=Theme.TextPrimary,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
                local swatch=Create("TextButton",{Size=UDim2.new(0,15,0,11),Position=UDim2.new(1,-15,0.5,-5),
                    BackgroundColor3=default,BorderSizePixel=0,Text="",Parent=row,
                },{Create("UIStroke",{Color=Theme.BorderBright,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,2)})})
                local value=default
                local presets={Color3.fromRGB(212,116,138),Color3.fromRGB(160,127,212),Color3.fromRGB(67,200,120),
                    Color3.fromRGB(200,180,67),Color3.fromRGB(67,160,200),Color3.fromRGB(255,255,255)}
                swatch.MouseButton1Click:Connect(function()
                    local idx=1
                    for i,c3 in ipairs(presets) do if c3==value then idx=i%#presets+1;break end end
                    value=presets[idx];swatch.BackgroundColor3=value;pcall(cb,value)
                end)
                local CP={}; CP.SetValue=function(_,v) value=v;swatch.BackgroundColor3=v;pcall(cb,v) end
                setmetatable(CP,{__index=function(_,k2) if k2=="Value" then return value end end,
                    __newindex=function(_,k2,v) if k2=="Value" then CP:SetValue(v) end end})
                Library.Options[k]=CP; return CP
            end

            function GB:AddKeybind(k, c2)
                c2=c2 or {}
                local text=c2.Text or k; local default=c2.Default or Enum.KeyCode.Unknown; local cb=c2.Callback or function()end
                local row=Create("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
                    Text="",BorderSizePixel=0,LayoutOrder=#body:GetChildren(),Parent=body,
                },{Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})})
                Create("TextLabel",{Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text=text,
                    TextColor3=Theme.TextPrimary,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
                local badge=Create("TextLabel",{Size=UDim2.new(0,0,0,16),AutomaticSize=Enum.AutomaticSize.X,
                    Position=UDim2.new(1,0,0.5,-8),AnchorPoint=Vector2.new(1,0),BackgroundColor3=Theme.BgBase,
                    BorderSizePixel=0,Text="["..default.Name:upper().."]",TextColor3=Theme.TextSecond,
                    TextSize=9,Font=Enum.Font.GothamMedium,Parent=row,
                },{Create("UIStroke",{Color=Theme.BorderBright,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,2)}),
                   Create("UIPadding",{PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4)})})
                local value=default; local binding=false
                row.MouseButton1Click:Connect(function() binding=true;badge.Text="[...]";badge.TextColor3=Theme.Accent end)
                UserInputService.InputBegan:Connect(function(inp,gpe)
                    if binding and not gpe and inp.UserInputType==Enum.UserInputType.Keyboard then
                        binding=false;value=inp.KeyCode
                        badge.Text="["..inp.KeyCode.Name:upper().."]";badge.TextColor3=Theme.TextSecond;pcall(cb,value)
                    end
                end)
                local KB={}; KB.SetValue=function(_,v) value=v;badge.Text="["..v.Name:upper().."]" end
                setmetatable(KB,{__index=function(_,k2) if k2=="Value" then return value end end,
                    __newindex=function(_,k2,v) if k2=="Value" then KB:SetValue(v) end end})
                Library.Options[k]=KB; return KB
            end

            function GB:AddButton(c2)
                c2=c2 or {}
                local text=c2.Text or "Button"; local cb=c2.Callback or function()end
                local wrap=Create("Frame",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,
                    LayoutOrder=#body:GetChildren(),Parent=body,
                },{Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)})})
                local btn=Create("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Theme.BgBase,
                    BorderSizePixel=0,Text=text,TextColor3=Theme.TextPrimary,TextSize=11,Font=Enum.Font.GothamMedium,Parent=wrap,
                },{Create("UIStroke",{Color=Theme.BorderBright,Thickness=1}),Create("UICorner",{CornerRadius=UDim.new(0,2)})})
                btn.MouseButton1Click:Connect(function()
                    Tween(btn,{BackgroundColor3=Theme.AccentDim},0.08);task.wait(0.12);Tween(btn,{BackgroundColor3=Theme.BgBase},0.12);pcall(cb)
                end)
                btn.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=Theme.BgHover},0.1) end)
                btn.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=Theme.BgBase},0.1)  end)
            end

            function GB:AddLabel(text)
                Create("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=text,
                    TextColor3=Theme.TextSecond,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
                    TextWrapped=true,LayoutOrder=#body:GetChildren(),Parent=body,
                },{Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})})
            end

            function GB:AddDivider()
                local wrap=Create("Frame",{Size=UDim2.new(1,0,0,9),BackgroundTransparency=1,
                    LayoutOrder=#body:GetChildren(),Parent=body})
                Create("Frame",{Size=UDim2.new(1,-16,0,1),Position=UDim2.new(0,8,0.5,0),
                    BackgroundColor3=Theme.Border,BorderSizePixel=0,Parent=wrap})
            end

            return GB
        end -- makeGroupbox

        function tab:AddLeftGroupbox(name)  return makeGroupbox(name,"Left")  end
        function tab:AddRightGroupbox(name) return makeGroupbox(name,"Right") end

        btn.MouseButton1Click:Connect(function() self:_switchTab(tab) end)
        table.insert(self._tabs, tab)
        if #self._tabs == 1 then self:_switchTab(tab) end
        return tab
    end -- AddTab

    -- ══════════════════════════════════════════════════════════════════════════
    --  AddESPPreview  (ViewportFrame + live character clone + ESP overlays)
    --  Technique from Mercury lib — WorldModel inside ViewportFrame,
    --  clone the local player's character into it, project 3D→2D for overlays.
    -- ══════════════════════════════════════════════════════════════════════════
    function Window:AddESPPreview()
        local previewFrame = Create("Frame", {
            Name="ESPPreview", Size=UDim2.new(0,200,0,280),
            Position=UDim2.new(1,12,0,0),   -- docked right of the main window
            BackgroundColor3=Theme.BgPanel, BorderSizePixel=0, Visible=true, Parent=WinFrame,
        }, {
            Create("UIStroke",{Color=Theme.BorderBright,Thickness=1}),
            Create("UICorner",{CornerRadius=UDim.new(0,5)}),
        })

        -- Header
        local hdr=Create("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=Theme.BgBase,BorderSizePixel=0,Parent=previewFrame},{
            Create("UICorner",{CornerRadius=UDim.new(0,5)}),
            Create("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,1,-6),BackgroundColor3=Theme.BgBase,BorderSizePixel=0}),
            Create("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Theme.Border,BorderSizePixel=0}),
        })
        Create("TextLabel",{Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,
            Text="ESP Preview",TextColor3=Theme.TextSecond,TextSize=9,Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=hdr})
        Create("Frame",{Size=UDim2.new(0,5,0,5),Position=UDim2.new(1,-12,0.5,-2),
            BackgroundColor3=Theme.Accent,BorderSizePixel=0,Parent=hdr},
            {Create("UICorner",{CornerRadius=UDim.new(1,0)})})
        MakeDraggable(previewFrame, hdr)

        -- ViewportFrame
        -- sits at offset (8, 34) inside previewFrame — remember this for 2D projection
        local VP_X, VP_Y = 8, 34
        local viewport=Create("ViewportFrame",{
            Size=UDim2.new(1,-16,1,-44), Position=UDim2.new(0,VP_X,0,VP_Y),
            BackgroundTransparency=1, BorderSizePixel=0, Parent=previewFrame,
        })
        local cam=Create("Camera",{FieldOfView=50, Parent=viewport})
        viewport.CurrentCamera=cam

        -- WorldModel holds the 3D character clone
        local worldModel=Create("WorldModel",{Parent=viewport})

        -- 2D ESP overlays (drawn over the ViewportFrame, parented to previewFrame so coords align)
        local espBox=Create("Frame",{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1,
            BorderSizePixel=2,BorderColor3=Theme.Accent,Visible=false,ZIndex=5,Parent=previewFrame})

        local skelContainer=Create("Frame",{Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=6,Parent=previewFrame})

        local bones={}
        for i=1,15 do
            bones[i]=Create("Frame",{BackgroundColor3=Theme.Accent,BorderSizePixel=0,
                AnchorPoint=Vector2.new(0.5,0.5),ZIndex=6,Parent=skelContainer})
        end

        -- ESP state
        local espState={boxes=false,chams=false,skeleton=false,filled=false,fillTrans=0.5,color=Theme.Accent}

        -- Clone character and run the render loop
        task.spawn(function()
            local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            -- wait for full load
            local t0=tick()
            while not char:FindFirstChild("HumanoidRootPart") and tick()-t0<10 do task.wait(0.1) end

            local function setupClone(c)
                c.Archivable=true
                local clone=c:Clone()
                clone.Parent=worldModel
                if clone.PrimaryPart then clone:SetPrimaryPartCFrame(CFrame.new(0,0,0)) end
                cam.CFrame=CFrame.new(Vector3.new(-3,2,7),Vector3.new(0,1,0))
                return clone
            end

            local charClone=setupClone(char)

            LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(1)
                if charClone then charClone:Destroy() end
                charClone=setupClone(newChar)
            end)

            RunService.RenderStepped:Connect(function()
                if not charClone or not charClone.PrimaryPart then return end

                -- Slow spin
                charClone:SetPrimaryPartCFrame(charClone.PrimaryPart.CFrame * CFrame.Angles(0,math.rad(0.4),0))

                -- Chams
                for _,part in ipairs(charClone:GetChildren()) do
                    if part:IsA("BasePart") then
                        if espState.chams then
                            part.Material=Enum.Material.Neon
                            part.Color=espState.color
                        else
                            part.Material=Enum.Material.SmoothPlastic
                            local orig=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(part.Name)
                            part.Color=(orig and orig:IsA("BasePart")) and orig.Color or Color3.new(1,1,1)
                        end
                    end
                end

                -- Project for box + skeleton
                local head=charClone:FindFirstChild("Head")
                local root=charClone:FindFirstChild("HumanoidRootPart")
                if not head or not root then
                    espBox.Visible=false
                    for _,b in ipairs(bones) do b.Visible=false end
                    return
                end

                local headVP,onScreen=cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    -- Box
                    if espState.boxes then
                        local topVP   =cam:WorldToViewportPoint(root.Position+Vector3.new(0,3,0))
                        local botVP   =cam:WorldToViewportPoint(root.Position+Vector3.new(0,-3.5,0))
                        local sizeY   =math.abs(topVP.Y-botVP.Y)
                        local sizeX   =sizeY/1.5
                        espBox.Visible=true
                        espBox.BorderColor3=espState.color
                        espBox.BackgroundColor3=espState.color
                        espBox.BackgroundTransparency=espState.filled and espState.fillTrans or 1
                        espBox.Size=UDim2.new(0,sizeX,0,sizeY)
                        espBox.Position=UDim2.new(0,headVP.X+VP_X-sizeX/2,0,headVP.Y+VP_Y-sizeY/4)
                    else
                        espBox.Visible=false
                    end

                    -- Skeleton
                    if espState.skeleton then
                        local joints=GetSkeleton(charClone)
                        for i,joint in ipairs(joints) do
                            if bones[i] then
                                local p1,o1=cam:WorldToViewportPoint(joint[1].Position)
                                local p2,o2=cam:WorldToViewportPoint(joint[2].Position)
                                if o1 and o2 then
                                    bones[i].Visible=true
                                    bones[i].BackgroundColor3=espState.color
                                    local mag=(Vector2.new(p1.X,p1.Y)-Vector2.new(p2.X,p2.Y)).Magnitude
                                    bones[i].Size=UDim2.new(0,mag,0,1)
                                    bones[i].Position=UDim2.new(0,(p1.X+p2.X)/2+VP_X,0,(p1.Y+p2.Y)/2+VP_Y)
                                    bones[i].Rotation=math.deg(math.atan2(p2.Y-p1.Y,p2.X-p1.X))
                                else bones[i].Visible=false end
                            end
                        end
                        for i=#GetSkeleton(charClone)+1,15 do if bones[i] then bones[i].Visible=false end end
                    else
                        for _,b in ipairs(bones) do b.Visible=false end
                    end
                else
                    espBox.Visible=false
                    for _,b in ipairs(bones) do b.Visible=false end
                end
            end)
        end)

        -- Public API
        local Preview={}
        function Preview:SetVisible(v)    previewFrame.Visible=v end
        function Preview:SetBox(en,filled,trans)
            espState.boxes=en
            if filled~=nil then espState.filled=filled end
            if trans~=nil  then espState.fillTrans=trans end
        end
        function Preview:SetChams(en,color)
            espState.chams=en
            if color then espState.color=color end
        end
        function Preview:SetSkeleton(en) espState.skeleton=en end
        function Preview:SetFilled(en,trans)
            espState.filled=en
            if trans~=nil then espState.fillTrans=trans end
        end
        function Preview:SetColor(color)
            espState.color=color
            espBox.BorderColor3=color
            for _,b in ipairs(bones) do b.BackgroundColor3=color end
        end
        return Preview
    end -- AddESPPreview

    return Window
end -- CreateWindow

return Library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RenderStepped = RunService.RenderStepped

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local Library = {
    Font = Enum.Font.Code,
    Colors = {
        Background  = Color3.fromRGB(13, 13, 13),
        Panel       = Color3.fromRGB(14, 14, 14),
        PanelInner  = Color3.fromRGB(18, 18, 18),
        OuterBorder = Color3.fromRGB(26, 26, 26),
        InnerBorder = Color3.fromRGB(55, 55, 55),
        DividerLine = Color3.fromRGB(31, 31, 31),
        Accent      = Color3.fromRGB(199, 36, 177),
        Text        = Color3.fromRGB(255, 255, 255),
        TextDim     = Color3.fromRGB(150, 150, 150),
        TextGroup   = Color3.fromRGB(140, 140, 140),
    },
    Registry = {},
    RegistryMap = {},
    OpenedFrames = {},
    ScreenGui = nil,
    Windows = {},
}

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, math.clamp(V / 1.5, 0, 1))
end

Library.Colors.AccentDark = Library:GetDarkerColor(Library.Colors.Accent)

function Library:Create(Class, Properties)
    local Instance_ = Class
    if type(Class) == "string" then
        Instance_ = Instance.new(Class)
    end
    for Property, Value in next, Properties do
        Instance_[Property] = Value
    end
    return Instance_
end

function Library:AddStroke(Parent, Color, Thickness)
    return Library:Create("UIStroke", {
        Color = Color,
        Thickness = Thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Parent,
    })
end

function Library:AddToRegistry(Instance, Properties)
    local Idx = #Library.Registry + 1
    local Data = { Instance = Instance, Properties = Properties, Idx = Idx }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
end

function Library:SafeCallback(Func, ...)
    if not Func then return end
    local Ok, Err = pcall(Func, ...)
    if not Ok then
        warn("[Stealth] Callback error: " .. tostring(Err))
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
        return true
    end
    return false
end

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        if Library:IsMouseOverFrame(Frame) then
            return true
        end
    end
    return false
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance]
        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library.Colors[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end)
    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance]
        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library.Colors[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14)
    local Tooltip = Library:Create("Frame", {
        BackgroundColor3 = Library.Colors.Panel,
        BorderColor3 = Library.Colors.OuterBorder,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.fromOffset(X + 8, Y + 6),
        ZIndex = 1000,
        Parent = Library.ScreenGui,
        Visible = false,
    })
    Library:Create("TextLabel", {
        Position = UDim2.fromOffset(4, 2),
        Size = UDim2.fromOffset(X, Y),
        BackgroundTransparency = 1,
        Font = Library.Font,
        Text = InfoStr,
        TextColor3 = Library.Colors.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1001,
        Parent = Tooltip,
    })
    local Hovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        Hovering = true
        Tooltip.Visible = true
        task.spawn(function()
            while Hovering do
                Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
                RunService.Heartbeat:Wait()
            end
        end)
    end)
    HoverInstance.MouseLeave:Connect(function()
        Hovering = false
        Tooltip.Visible = false
    end)
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local StartPos = Vector2.new(Mouse.X - Instance.AbsolutePosition.X, Mouse.Y - Instance.AbsolutePosition.Y)
            if StartPos.Y > (Cutoff or 40) then return end
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local Target = Instance.Parent.Parent
                Target.Position = UDim2.new(
                    0, Mouse.X - StartPos.X + (Target.Size.X.Offset * Target.AnchorPoint.X),
                    0, Mouse.Y - StartPos.Y + (Target.Size.Y.Offset * Target.AnchorPoint.Y)
                )
                RenderStepped:Wait()
            end
        end
    end)
end

function Library:Init()
    local ScreenGui = Library:Create("ScreenGui", {
        Name = "StealthMenu",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        Parent = CoreGui,
    })
    ProtectGui(ScreenGui)
    Library.ScreenGui = ScreenGui
end

Library:Init()

function Library:CreateWindow(Options)
    Options = Options or {}
    local Title = Options.Title or "Stealth.xyz"
    local Build = Options.Build or "build: beta"
    local Center = Options.Center ~= false
    local AutoShow = Options.AutoShow ~= false
    local ToggleKey = Options.ToggleKey or Enum.KeyCode.Insert
    local Watermark = Options.Watermark == true

    local WINDOW_SIZE = UDim2.fromOffset(580, 580)
    local PADDING = 15
    local SUBTAB_BAR_HEIGHT = 26

    local Outer = Library:Create("Frame", {
        Name = "Outer",
        AnchorPoint = Center and Vector2.new(0.5, 0.5) or Vector2.new(0, 0),
        Position = Center and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(200, 200),
        Size = WINDOW_SIZE,
        BackgroundColor3 = Library.Colors.Background,
        BorderSizePixel = 0,
        Active = true,
        Visible = AutoShow,
        Parent = Library.ScreenGui,
    })
    Library:AddStroke(Outer, Library.Colors.OuterBorder, 1)

    local Inner = Library:Create("Frame", {
        Name = "Inner",
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(1, -6, 1, -6),
        BackgroundColor3 = Library.Colors.Background,
        BorderSizePixel = 0,
        Parent = Outer,
    })
    Library:AddStroke(Inner, Library.Colors.InnerBorder, 1)

    local Header = Library:Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        Active = true,
        Parent = Inner,
    })

    Library:Create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Font = Library.Font,
        Text = Title,
        TextColor3 = Library.Colors.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Header,
    })

    Library:Create("TextLabel", {
        Name = "Build",
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Library.Font,
        Text = Build,
        TextColor3 = Library.Colors.TextDim,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Header,
    })

    Library:MakeDraggable(Header, 56)

    local TabBar = Library:Create("Frame", {
        Name = "TabBar",
        Position = UDim2.fromOffset(PADDING, 58),
        Size = UDim2.new(1, -PADDING * 2, 0, 22),
        BackgroundTransparency = 1,
        Parent = Inner,
    })

    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 40),
        Parent = TabBar,
    })

    Library:Create("Frame", {
        Name = "Divider1",
        Position = UDim2.fromOffset(0, 84),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Library.Colors.DividerLine,
        BorderSizePixel = 0,
        Parent = Inner,
    })

    local Panel = Library:Create("Frame", {
        Name = "Panel",
        Position = UDim2.fromOffset(PADDING, 92),
        Size = UDim2.new(1, -PADDING * 2, 1, -92 - PADDING),
        BackgroundColor3 = Library.Colors.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Inner,
    })
    Library:AddStroke(Panel, Library.Colors.InnerBorder, 1)

    local SubTabBar = Library:Create("Frame", {
        Name = "SubTabBar",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, SUBTAB_BAR_HEIGHT),
        BackgroundTransparency = 1,
        Parent = Panel,
    })

    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 40),
        Parent = SubTabBar,
    })

    Library:Create("Frame", {
        Name = "PanelDivider",
        Position = UDim2.fromOffset(0, SUBTAB_BAR_HEIGHT),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Library.Colors.DividerLine,
        BorderSizePixel = 0,
        Parent = Panel,
    })

    local GroupArea = Library:Create("Frame", {
        Name = "GroupArea",
        Position = UDim2.fromOffset(0, SUBTAB_BAR_HEIGHT + 1),
        Size = UDim2.new(1, 0, 1, -(SUBTAB_BAR_HEIGHT + 1)),
        BackgroundTransparency = 1,
        Parent = Panel,
    })

    Library:Create("Frame", {
        Name = "GroupDivider",
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Library.Colors.DividerLine,
        BorderSizePixel = 0,
        Parent = GroupArea,
    })

    local Window = {
        Gui = Outer,
        Inner = Inner,
        Header = Header,
        TabBar = TabBar,
        Panel = Panel,
        SubTabBar = SubTabBar,
        GroupArea = GroupArea,
        Tabs = {},
        ActiveTab = nil,
        ActiveSubTab = nil,
        ToggleKey = ToggleKey,
        Visible = AutoShow,
    }

    function Window:SetVisible(State)
        State = State and true or false
        Window.Visible = State
        Outer.Visible = State
    end

    function Window:Show() Window:SetVisible(true) end
    function Window:Hide() Window:SetVisible(false) end
    function Window:Toggle() Window:SetVisible(not Window.Visible) end

    UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if GameProcessed then return end
        if Input.KeyCode == Window.ToggleKey then
            Window:Toggle()
        end
    end)

    function Window:Tab(TabName)
        local TabObj = {
            Name = TabName,
            SubTabs = {},
            Window = Window,
            Button = nil,
        }

        local Button = Library:Create("TextLabel", {
            Name = "Tab_" .. TabName,
            Size = UDim2.fromOffset(80, 20),
            BackgroundTransparency = 1,
            Font = Library.Font,
            Text = TabName,
            TextColor3 = Library.Colors.TextDim,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            LayoutOrder = #Window.Tabs + 1,
            Parent = TabBar,
        })
        Library:AddToRegistry(Button, { TextColor3 = "TextDim" })
        TabObj.Button = Button

        Button.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Window:SelectTab(TabName)
            end
        end)

        table.insert(Window.Tabs, TabObj)
        Window.Tabs[TabName] = TabObj

        if #Window.Tabs == 1 then
            Window:SelectTab(TabName)
        end

        function TabObj:SubTab(SubName)
            local SubObj = {
                Name = SubName,
                Tab = TabObj,
                Window = Window,
                Groups = {},
                Button = nil,
            }

            local SubButton = Library:Create("TextLabel", {
                Name = "SubTab_" .. SubName,
                Size = UDim2.fromOffset(80, 20),
                BackgroundTransparency = 1,
                Font = Library.Font,
                Text = SubName,
                TextColor3 = Library.Colors.TextDim,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Visible = false,
                LayoutOrder = #TabObj.SubTabs + 1,
                Parent = SubTabBar,
            })
            Library:AddToRegistry(SubButton, { TextColor3 = "TextDim" })
            SubObj.Button = SubButton

            SubButton.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Window:SelectSubTab(TabName, SubName)
                end
            end)

            table.insert(TabObj.SubTabs, SubObj)
            TabObj.SubTabs[SubName] = SubObj

            function SubObj:Group(LeftTitle, RightTitle)
                local LeftGroup = Library:Create("Frame", {
                    Name = "Group_Left",
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Position = UDim2.fromOffset(0, 0),
                    BackgroundTransparency = 1,
                    Visible = false,
                    Parent = GroupArea,
                })

                local RightGroup = Library:Create("Frame", {
                    Name = "Group_Right",
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Visible = false,
                    Parent = GroupArea,
                })

                Library:Create("TextLabel", {
                    Position = UDim2.fromOffset(0, 10),
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    Text = LeftTitle or "",
                    TextColor3 = Library.Colors.TextGroup,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Parent = LeftGroup,
                })

                Library:Create("Frame", {
                    Position = UDim2.fromOffset(0, 28),
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Library.Colors.DividerLine,
                    BorderSizePixel = 0,
                    Parent = LeftGroup,
                })

                Library:Create("TextLabel", {
                    Position = UDim2.fromOffset(0, 10),
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    Text = RightTitle or "",
                    TextColor3 = Library.Colors.TextGroup,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Parent = RightGroup,
                })

                Library:Create("Frame", {
                    Position = UDim2.fromOffset(0, 28),
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Library.Colors.DividerLine,
                    BorderSizePixel = 0,
                    Parent = RightGroup,
                })

                local LeftList = Library:Create("Frame", {
                    Position = UDim2.fromOffset(10, 36),
                    Size = UDim2.new(1, -20, 1, -46),
                    BackgroundTransparency = 1,
                    Parent = LeftGroup,
                })
                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                    Parent = LeftList,
                })

                local RightList = Library:Create("Frame", {
                    Position = UDim2.fromOffset(10, 36),
                    Size = UDim2.new(1, -20, 1, -46),
                    BackgroundTransparency = 1,
                    Parent = RightGroup,
                })
                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 6),
                    Parent = RightList,
                })

                local LeftObj = { Frame = LeftGroup, List = LeftList, Order = 0 }
                local RightObj = { Frame = RightGroup, List = RightList, Order = 0 }

                function LeftObj:NextOrder()
                    LeftObj.Order = LeftObj.Order + 1
                    return LeftObj.Order
                end
                function RightObj:NextOrder()
                    RightObj.Order = RightObj.Order + 1
                    return RightObj.Order
                end

                local GroupResult = {
                    Left = LeftObj,
                    Right = RightObj,
                    LeftFrame = LeftGroup,
                    RightFrame = RightGroup,
                }

                table.insert(SubObj.Groups, GroupResult)
                return GroupResult
            end

            table.insert(TabObj.SubTabs, SubObj)
            TabObj.SubTabs[SubName] = SubObj

            return SubObj
        end

        return TabObj
    end

    function Window:SelectTab(TabName)
        Window.ActiveTab = TabName
        for _, Tab in ipairs(Window.Tabs) do
            if type(Tab) == "table" and Tab.Name then
                if Tab.Name == TabName then
                    Tab.Button.TextColor3 = Library.Colors.Accent
                    Library.RegistryMap[Tab.Button].Properties.TextColor3 = "Accent"
                else
                    Tab.Button.TextColor3 = Library.Colors.TextDim
                    Library.RegistryMap[Tab.Button].Properties.TextColor3 = "TextDim"
                end
                for _, Sub in ipairs(Tab.SubTabs) do
                    Sub.Button.Visible = (Tab.Name == TabName)
                    for _, Grp in ipairs(Sub.Groups) do
                        Grp.LeftFrame.Visible = false
                        Grp.RightFrame.Visible = false
                    end
                end
            end
        end

        local ActiveTab = Window.Tabs[TabName]
        if ActiveTab and ActiveTab.SubTabs[1] then
            Window:SelectSubTab(TabName, ActiveTab.SubTabs[1].Name)
        end
    end

    function Window:SelectSubTab(TabName, SubName)
        Window.ActiveSubTab = SubName
        local Tab = Window.Tabs[TabName]
        if not Tab then return end

        for _, Sub in ipairs(Tab.SubTabs) do
            local IsActive = (Sub.Name == SubName)
            Sub.Button.TextColor3 = IsActive and Library.Colors.Accent or Library.Colors.TextDim
            Library.RegistryMap[Sub.Button].Properties.TextColor3 = IsActive and "Accent" or "TextDim"
            for _, Grp in ipairs(Sub.Groups) do
                Grp.LeftFrame.Visible = IsActive
                Grp.RightFrame.Visible = IsActive
            end
        end
    end

    if Watermark then
        Window.Watermark = Library:CreateWatermark(Title)
    end

    Library.Windows[#Library.Windows + 1] = Window
    return Window
end

function Library:CreateWatermark(Title)
    local MARGIN = 10
    local HEIGHT = 26
    local PADDING_X = 10
    local SEPARATOR = " | "

    local WmGui = Library:Create("ScreenGui", {
        Name = "StealthWatermark",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        Parent = CoreGui,
    })
    ProtectGui(WmGui)

    local Outer = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -MARGIN, 0, MARGIN),
        Size = UDim2.fromOffset(10, HEIGHT),
        BackgroundColor3 = Library.Colors.Background,
        BorderSizePixel = 0,
        Active = false,
        Parent = WmGui,
    })
    Library:AddStroke(Outer, Library.Colors.OuterBorder, 1)

    local Inner = Library:Create("Frame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(1, -6, 1, -6),
        BackgroundColor3 = Library.Colors.Background,
        BorderSizePixel = 0,
        Active = false,
        Parent = Outer,
    })
    Library:AddStroke(Inner, Library.Colors.InnerBorder, 1)

    Library:Create("Frame", {
        Position = UDim2.fromOffset(0, 4),
        Size = UDim2.new(0, 2, 1, -8),
        BackgroundColor3 = Library.Colors.Accent,
        BorderSizePixel = 0,
        Parent = Inner,
    })

    local Label = Library:Create("TextLabel", {
        Position = UDim2.fromOffset(PADDING_X, 0),
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        Text = "",
        TextColor3 = Library.Colors.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Inner,
    })

    local Fps = 0
    local FrameCount = 0
    local LastTime = tick()

    RenderStepped:Connect(function()
        FrameCount = FrameCount + 1
        local Now = tick()
        if Now - LastTime >= 0.5 then
            Fps = math.floor(FrameCount / (Now - LastTime) + 0.5)
            FrameCount = 0
            LastTime = Now
        end
    end)

    local function GetPing()
        local Ok, Value = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if Ok and Value then
            return math.floor(Value + 0.5)
        end
        return 0
    end

    local function Update()
        local Text = Title
            .. SEPARATOR .. os.date("%H:%M:%S")
            .. SEPARATOR .. Fps .. " FPS"
            .. SEPARATOR .. GetPing() .. " ms"
        Label.Text = Text
        local TextSize = Label.TextBounds.X
        Outer.Size = UDim2.fromOffset(TextSize + PADDING_X * 2 + 6, HEIGHT)
        Label.Size = UDim2.new(0, TextSize, 1, 0)
    end

    task.spawn(function()
        while task.wait(0.25) do
            Update()
        end
    end)
    Update()

    return { Gui = WmGui, Frame = Outer }
end

return Library
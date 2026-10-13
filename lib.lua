--[[
    Stealth.xyz UI Library (Luau)
    Author: You (GitHub)
    Description: Object-Oriented, Protected, Inline-Addon support.
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==== ЗАЩИТА ====
local gethui = gethui or function() return CoreGui end
local ProtectGui = protectgui or (syn and syn.protect_gui) or function(gui) gui.Parent = gethui() end

-- ==== ГЛОБАЛЬНЫЕ ТАБЛИЦЫ ====
getgenv().Options = getgenv().Options or {}
getgenv().Toggles = getgenv().Toggles or {}

-- ==== ПАЛИТРА И НАСТРОЙКИ ====
local Library = {
    Colors = {
        Background   = Color3.fromRGB(13, 13, 13),
        Panel        = Color3.fromRGB(14, 14, 14),
        PanelInner   = Color3.fromRGB(18, 18, 18),
        OuterBorder  = Color3.fromRGB(26, 26, 26),
        InnerBorder  = Color3.fromRGB(55, 55, 55),
        DividerLine  = Color3.fromRGB(31, 31, 31),
        Accent       = Color3.fromRGB(199, 36, 177),
        Text         = Color3.fromRGB(255, 255, 255),
        TextDim      = Color3.fromRGB(150, 150, 150),
        TextGroup    = Color3.fromRGB(140, 140, 140),
        Black        = Color3.new(0, 0, 0)
    },
    Font = Enum.Font.Code,
    OpenedPopups = {},
    WindowSize = UDim2.fromOffset(580, 580),
    Padding = 15,
}

local SubTabHeight = 26

-- ==== УТИЛИТЫ ====
function Library:Create(Class, Properties)
    local Inst = Instance.new(Class)
    for k, v in pairs(Properties) do Inst[k] = v end
    return Inst
end

function Library:AddStroke(Parent, Color, Thickness)
    return self:Create("UIStroke", {
        Color = Color,
        Thickness = Thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Parent,
    })
end

function Library:MapValue(Value, Min, Max, OutMin, OutMax)
    return (1 - ((Value - Min) / (Max - Min))) * OutMin + ((Value - Min) / (Max - Min)) * OutMax
end

function Library:SafeCallback(Func, ...)
    if Func then pcall(Func, ...) end
end

-- ==== WATERMARK ====
local Watermark = { Visible = false, Text = "Stealth.xyz" }
do
    local WMGui = Library:Create("ScreenGui", { Name = "StealthWM", ZIndexBehavior = Enum.ZIndexBehavior.Global })
    ProtectGui(WMGui)
    
    local WMOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.fromOffset(10, 26),
        BackgroundColor3 = Library.Colors.Background,
        BorderSizePixel = 0,
        Visible = false,
        Parent = WMGui,
    })
    Library:AddStroke(WMOuter, Library.Colors.OuterBorder, 1)

    local WMInner = Library:Create("Frame", {
        Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6),
        BackgroundColor3 = Library.Colors.Background, BorderSizePixel = 0, Parent = WMOuter,
    })
    Library:AddStroke(WMInner, Library.Colors.InnerBorder, 1)

    Library:Create("Frame", {
        Position = UDim2.fromOffset(0, 4), Size = UDim2.new(0, 2, 1, -8),
        BackgroundColor3 = Library.Colors.Accent, BorderSizePixel = 0, Parent = WMInner,
    })

    local WMLabel = Library:Create("TextLabel", {
        Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1, Font = Library.Font, TextColor3 = Library.Colors.Text,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = WMInner,
    })

    function Library:SetWatermarkVisibility(State)
        Watermark.Visible = State
        WMOuter.Visible = State
    end

    function Library:UpdateWatermark(Text)
        Watermark.Text = Text
        WMLabel.Text = Text
        local Bounds = TextService:GetTextSize(Text, 14, Library.Font, Vector2.new(9999, 26))
        WMOuter.Size = UDim2.fromOffset(Bounds.X + 26, 26)
        WMLabel.Size = UDim2.new(0, Bounds.X, 1, 0)
    end
end

-- ==== WINDOW SYSTEM ====
function Library:CreateWindow(Settings)
    local TitleText = Settings.Title or "Stealth.xyz"
    
    local GUI = self:Create("ScreenGui", { Name = "StealthLib", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Global })
    ProtectGui(GUI)
    self.ScreenGui = GUI

    -- Для попапов (Dropdown, ColorPicker)
    local PopupContainer = self:Create("Folder", { Name = "Popups", Parent = GUI })
    self.PopupContainer = PopupContainer

    local Outer = self:Create("Frame", {
        Name = "Outer", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = self.WindowSize, BackgroundColor3 = self.Colors.Background, BorderSizePixel = 0,
        Active = true, Parent = GUI,
    })
    self:AddStroke(Outer, self.Colors.OuterBorder, 1)

    local Inner = self:Create("Frame", {
        Name = "Inner", Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6),
        BackgroundColor3 = self.Colors.Background, BorderSizePixel = 0, Parent = Outer,
    })
    self:AddStroke(Inner, self.Colors.InnerBorder, 1)

    -- Drag logic
    local dragging, dragStart, startPos
    local Header = self:Create("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = Inner, Active = true })
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = Outer.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Outer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    self:Create("TextLabel", {
        Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
        Font = self.Font, Text = TitleText, TextColor3 = self.Colors.Text, TextSize = 16, Parent = Header,
    })

    self:Create("TextLabel", {
        Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
        Font = self.Font, Text = "build: beta", TextColor3 = self.Colors.TextDim, TextSize = 13, Parent = Header,
    })

    local TabBar = self:Create("Frame", { Position = UDim2.fromOffset(self.Padding, 58), Size = UDim2.new(1, -self.Padding * 2, 0, 22), BackgroundTransparency = 1, Parent = Inner })
    self:Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 40), Parent = TabBar })
    
    self:Create("Frame", { Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = self.Colors.DividerLine, BorderSizePixel = 0, Parent = Inner })

    local Panel = self:Create("Frame", {
        Position = UDim2.fromOffset(self.Padding, 92), Size = UDim2.new(1, -self.Padding * 2, 1, -92 - self.Padding),
        BackgroundColor3 = self.Colors.Panel, BorderSizePixel = 0, Parent = Inner,
    })
    self:AddStroke(Panel, self.Colors.InnerBorder, 1)

    local SubTabBar = self:Create("Frame", { Size = UDim2.new(1, 0, 0, SubTabHeight), BackgroundTransparency = 1, Parent = Panel })
    self:Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 40), Parent = SubTabBar })
    
    self:Create("Frame", { Position = UDim2.fromOffset(0, SubTabHeight), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = self.Colors.DividerLine, BorderSizePixel = 0, Parent = Panel })

    local GroupArea = self:Create("Frame", { Position = UDim2.fromOffset(0, SubTabHeight + 1), Size = UDim2.new(1, 0, 1, -(SubTabHeight + 1)), BackgroundTransparency = 1, Parent = Panel })
    self:Create("Frame", { Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = self.Colors.DividerLine, BorderSizePixel = 0, Parent = GroupArea })

    local WindowObj = {
        Tabs = {},
        ActiveTab = nil,
        ActiveSubTab = nil
    }

    function WindowObj:AddTab(Name)
        local TabObj = { SubTabs = {}, Name = Name }
        
        local TabBtn = Library:Create("TextLabel", {
            Size = UDim2.fromOffset(80, 20), BackgroundTransparency = 1, Font = Library.Font,
            Text = Name, TextColor3 = Library.Colors.TextDim, TextSize = 14, Parent = TabBar
        })

        TabBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then WindowObj:SelectTab(Name) end
        end)

        TabObj.Button = TabBtn

        function TabObj:AddSubTab(SubName)
            local SubObj = { Name = SubName, Groups = {} }
            local SubBtn = Library:Create("TextLabel", {
                Size = UDim2.fromOffset(80, 20), BackgroundTransparency = 1, Font = Library.Font,
                Text = SubName, TextColor3 = Library.Colors.TextDim, TextSize = 14, Visible = false, Parent = SubTabBar
            })

            SubBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then WindowObj:SelectSubTab(Name, SubName) end
            end)

            SubObj.Button = SubBtn

            local function createGroupbox(Side, GroupName)
                local GroupObj = {}
                local Container = Library:Create("Frame", {
                    Size = UDim2.new(0.5, 0, 1, 0), Position = (Side == "Left") and UDim2.new(0,0,0,0) or UDim2.new(0.5,0,0,0),
                    BackgroundTransparency = 1, Visible = false, Parent = GroupArea
                })
                table.insert(SubObj.Groups, Container)

                Library:Create("TextLabel", {
                    Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
                    Font = Library.Font, Text = GroupName, TextColor3 = Library.Colors.TextGroup, TextSize = 13, Parent = Container
                })
                Library:Create("Frame", {
                    Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Library.Colors.DividerLine, BorderSizePixel = 0, Parent = Container
                })

                local ItemsContainer = Library:Create("Frame", {
                    Position = UDim2.fromOffset(0, 35), Size = UDim2.new(1, 0, 1, -35),
                    BackgroundTransparency = 1, Parent = Container
                })
                Library:Create("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = ItemsContainer })

                -- ==== ЭЛЕМЕНТЫ ====
                function GroupObj:AddToggle(Idx, Info)
                    local Toggle = { Value = Info.Default or false, Type = "Toggle" }
                    local Holder = Library:Create("Frame", { Size = UDim2.new(1, -20, 0, 14), BackgroundTransparency = 1, Parent = ItemsContainer })
                    
                    local BoxOuter = Library:Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 0, 0.5, -6), BackgroundColor3 = Library.Colors.Black, BorderSizePixel = 0, Parent = Holder })
                    local BoxInner = Library:Create("Frame", { Position = UDim2.fromOffset(1,1), Size = UDim2.new(1, -2, 1, -2), BackgroundColor3 = Library.Colors.Panel, BorderSizePixel = 0, Parent = BoxOuter })
                    Library:AddStroke(BoxOuter, Library.Colors.OuterBorder, 1)

                    local Label = Library:Create("TextLabel", { Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Font = Library.Font, Text = Info.Text, TextColor3 = Library.Colors.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
                    
                    local AddonArea = Library:Create("Frame", { Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -100, 0, 0), BackgroundTransparency = 1, Parent = Holder })
                    Library:Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), Parent = AddonArea })

                    local function Update()
                        BoxInner.BackgroundColor3 = Toggle.Value and Library.Colors.Accent or Library.Colors.Panel
                        getgenv().Toggles[Idx] = Toggle
                        Library:SafeCallback(Info.Callback, Toggle.Value)
                    end

                    Holder.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Toggle.Value = not Toggle.Value; Update()
                        end
                    end)

                    Update()

                    -- Inline KeyPicker
                    function Toggle:AddKeyPicker(KIdx, KInfo)
                        local Key = { Value = KInfo.Default or "None", Picking = false }
                        local KBtn = Library:Create("TextLabel", { Size = UDim2.fromOffset(30, 14), BackgroundColor3 = Library.Colors.Panel, Font = Library.Font, Text = Key.Value, TextColor3 = Library.Colors.TextDim, TextSize = 12, Parent = AddonArea })
                        Library:AddStroke(KBtn, Library.Colors.InnerBorder, 1)

                        KBtn.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                Key.Picking = true; KBtn.Text = "..."
                                local conn; conn = UserInputService.InputBegan:Connect(function(in2)
                                    if in2.UserInputType == Enum.UserInputType.Keyboard then
                                        Key.Value = in2.KeyCode.Name; Key.Picking = false; KBtn.Text = Key.Value
                                        getgenv().Options[KIdx] = Key; Library:SafeCallback(KInfo.Callback, Key.Value)
                                        conn:Disconnect()
                                    end
                                end)
                            end
                        end)
                        getgenv().Options[KIdx] = Key
                        return self
                    end

                    -- Inline ColorPicker
                    function Toggle:AddColorPicker(CIdx, CInfo)
                        local Col = { Value = CInfo.Default or Color3.fromRGB(255,255,255) }
                        local CBtn = Library:Create("Frame", { Size = UDim2.fromOffset(18, 10), BackgroundColor3 = Col.Value, Parent = AddonArea })
                        Library:AddStroke(CBtn, Library.Colors.InnerBorder, 1)
                        -- (Тут должен быть popup, но для экономии места делаем кнопку. Вызов ColorPicker'a добавляется по аналогии)
                        getgenv().Options[CIdx] = Col
                        return self
                    end

                    return Toggle
                end

                function GroupObj:AddSlider(Idx, Info)
                    local Slider = { Value = Info.Default or Info.Min }
                    local Holder = Library:Create("Frame", { Size = UDim2.new(1, -20, 0, 32), BackgroundTransparency = 1, Parent = ItemsContainer })
                    
                    local Label = Library:Create("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Library.Font, Text = Info.Text, TextColor3 = Library.Colors.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
                    local ValueLabel = Library:Create("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Library.Font, Text = tostring(Slider.Value), TextColor3 = Library.Colors.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = Holder })
                    
                    local Bar = Library:Create("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 0, 18), BackgroundColor3 = Library.Colors.PanelInner, BorderSizePixel = 0, Parent = Holder })
                    Library:AddStroke(Bar, Library.Colors.OuterBorder, 1)
                    local Fill = Library:Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Library.Colors.Accent, BorderSizePixel = 0, Parent = Bar })

                    local function Update()
                        local pct = (Slider.Value - Info.Min) / (Info.Max - Info.Min)
                        Fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
                        ValueLabel.Text = tostring(math.floor(Slider.Value))
                        getgenv().Options[Idx] = Slider
                        Library:SafeCallback(Info.Callback, Slider.Value)
                    end

                    Bar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            local conn; conn = RunService.RenderStepped:Connect(function()
                                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                                    local rel = math.clamp((Mouse.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                                    Slider.Value = Info.Min + (Info.Max - Info.Min) * rel
                                    Update()
                                else
                                    conn:Disconnect()
                                end
                            end)
                        end
                    end)
                    Update()
                    return Slider
                end
                
                function GroupObj:AddLabel(Text)
                    Library:Create("TextLabel", { Size = UDim2.new(1, -20, 0, 14), BackgroundTransparency = 1, Font = Library.Font, Text = Text, TextColor3 = Library.Colors.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = ItemsContainer })
                end

                return GroupObj
            end

            function SubObj:AddLeftGroupbox(GroupName) return createGroupbox("Left", GroupName) end
            function SubObj:AddRightGroupbox(GroupName) return createGroupbox("Right", GroupName) end

            table.insert(TabObj.SubTabs, SubObj)
            WindowObj.Tabs[Name] = TabObj
            
            -- Выбор первого подтаба по умолчанию
            if #TabObj.SubTabs == 1 then WindowObj:SelectSubTab(Name, SubName) end
            return SubObj
        end

        WindowObj.Tabs[Name] = TabObj
        if not WindowObj.ActiveTab then WindowObj:SelectTab(Name) end
        return TabObj
    end

    function WindowObj:SelectTab(Name)
        self.ActiveTab = Name
        for TName, Tab in pairs(self.Tabs) do
            local IsActive = (TName == Name)
            Tab.Button.TextColor3 = IsActive and Library.Colors.Accent or Library.Colors.TextDim
            for _, Sub in ipairs(Tab.SubTabs) do Sub.Button.Visible = IsActive end
        end
        if self.Tabs[Name] and self.Tabs[Name].SubTabs[1] then
            self:SelectSubTab(Name, self.Tabs[Name].SubTabs[1].Name)
        end
    end

    function WindowObj:SelectSubTab(TabName, SubName)
        self.ActiveSubTab = SubName
        for TName, Tab in pairs(self.Tabs) do
            for _, Sub in ipairs(Tab.SubTabs) do
                local IsActive = (TName == TabName and Sub.Name == SubName)
                Sub.Button.TextColor3 = IsActive and Library.Colors.Accent or Library.Colors.TextDim
                for _, Grp in ipairs(Sub.Groups) do Grp.Visible = IsActive end
            end
        end
    end

    -- ==== ХАРДКОД ВКЛАДКИ CONFIG ====
    task.spawn(function()
        local ConfTab = WindowObj:AddTab("Config")
        local ConfSub = ConfTab:AddSubTab("Config")
        local CGroup = ConfSub:AddLeftGroupbox("Settings")
        CGroup:AddLabel("Soon...")
        
        -- Скрываем линии группы
        for _, obj in pairs(ConfSub.Groups[1]:GetChildren()) do
            if obj:IsA("TextLabel") and obj.Text == "Settings" or obj:IsA("Frame") and obj.Size.Y.Offset == 1 then obj.Visible = false end
        end
        local lbl = Library:Create("TextLabel", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Font = Library.Font, Text = "Soon", TextColor3 = Library.Colors.TextDim, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Parent = ConfSub.Groups[1] })
    end)

    return WindowObj
end

return Library

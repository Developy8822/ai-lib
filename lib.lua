--[[
    Stealth.xyz UI Library (Luau) — FIXED
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local gethui = gethui or function() return CoreGui end
local ProtectGui = protectgui or (syn and syn.protect_gui) or function(gui) gui.Parent = gethui() end

getgenv().Options = getgenv().Options or {}
getgenv().Toggles = getgenv().Toggles or {}

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

function Library:SafeCallback(Func, ...)
    if Func then pcall(Func, ...) end
end

-- ФИКС: Центральная функция закрытия всех попапов (Dropdown/ColorPicker)
function Library:CloseAllPopups(Except)
    for Popup, _ in pairs(self.OpenedPopups) do
        if Popup ~= Except then
            Popup.Visible = false
            self.OpenedPopups[Popup] = nil
        end
    end
end

function Library:IsMouseOver(Frame)
    local pos, size = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= pos.X and Mouse.X <= pos.X + size.X
       and Mouse.Y >= pos.Y and Mouse.Y <= pos.Y + size.Y
end

-- ==== WATERMARK ====
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
        WMOuter.Visible = State
    end

    function Library:UpdateWatermark(Text)
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

    -- Контейнер для попапов (Dropdown/ColorPicker), рендерится поверх всего
    local PopupContainer = self:Create("Folder", { Name = "Popups", Parent = GUI })
    self.PopupContainer = PopupContainer

    local Outer = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = self.WindowSize, BackgroundColor3 = self.Colors.Background, BorderSizePixel = 0,
        Active = true, Parent = GUI,
    })
    self:AddStroke(Outer, self.Colors.OuterBorder, 1)

    local Inner = self:Create("Frame", {
        Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6),
        BackgroundColor3 = self.Colors.Background, BorderSizePixel = 0, Parent = Outer,
    })
    self:AddStroke(Inner, self.Colors.InnerBorder, 1)

    local dragging, dragStart, startPos
    local Header = self:Create("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Active = true, Parent = Inner })

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
    self:Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 40), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabBar })

    self:Create("Frame", { Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = self.Colors.DividerLine, BorderSizePixel = 0, Parent = Inner })

    local Panel = self:Create("Frame", {
        Position = UDim2.fromOffset(self.Padding, 92), Size = UDim2.new(1, -self.Padding * 2, 1, -92 - self.Padding),
        BackgroundColor3 = self.Colors.Panel, BorderSizePixel = 0, ClipsDescendants = true, Parent = Inner,
    })
    self:AddStroke(Panel, self.Colors.InnerBorder, 1)

    local SubTabBar = self:Create("Frame", { Size = UDim2.new(1, 0, 0, SubTabHeight), BackgroundTransparency = 1, Parent = Panel })
    self:Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 40), SortOrder = Enum.SortOrder.LayoutOrder, Parent = SubTabBar })

    self:Create("Frame", { Position = UDim2.fromOffset(0, SubTabHeight), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = self.Colors.DividerLine, BorderSizePixel = 0, Parent = Panel })

    local GroupArea = self:Create("Frame", { Position = UDim2.fromOffset(0, SubTabHeight + 1), Size = UDim2.new(1, 0, 1, -(SubTabHeight + 1)), BackgroundTransparency = 1, Parent = Panel })
    self:Create("Frame", { Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = self.Colors.DividerLine, BorderSizePixel = 0, Parent = GroupArea })

    local WindowObj = {
        Tabs = {},
        ActiveTab = nil,
        ActiveSubTab = nil,
        TabCounter = 0,
    }

    -- ФИКС: добавлен параметр IsInternal — чтобы хардкодный Config
    -- не ломал порядок и не перехватывал ActiveTab
    function WindowObj:AddTab(Name, IsInternal)
        local TabObj = { SubTabs = {}, Name = Name }

        local TabBtn = Library:Create("TextLabel", {
            Size = UDim2.fromOffset(80, 20), BackgroundTransparency = 1, Font = Library.Font,
            Text = Name, TextColor3 = Library.Colors.TextDim, TextSize = 14,
            Active = true, Parent = TabBar,
        })

        if IsInternal then
            TabBtn.LayoutOrder = 9999 -- ФИКС: всегда последний визуально
        else
            self.TabCounter = self.TabCounter + 1
            TabBtn.LayoutOrder = self.TabCounter
        end

        TabBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then WindowObj:SelectTab(Name) end
        end)

        TabObj.Button = TabBtn

        function TabObj:AddSubTab(SubName)
            local SubObj = { Name = SubName, Groups = {} }
            local SubBtn = Library:Create("TextLabel", {
                Size = UDim2.fromOffset(80, 20), BackgroundTransparency = 1, Font = Library.Font,
                Text = SubName, TextColor3 = Library.Colors.TextDim, TextSize = 14,
                Visible = false, Active = true, Parent = SubTabBar,
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
                GroupObj.Instance = Container

                local TitleLabel = Library:Create("TextLabel", {
                    Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
                    Font = Library.Font, Text = GroupName, TextColor3 = Library.Colors.TextGroup, TextSize = 13, Parent = Container
                })
                local DividerLine = Library:Create("Frame", {
                    Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Library.Colors.DividerLine, BorderSizePixel = 0, Parent = Container
                })
                GroupObj.TitleLabel = TitleLabel
                GroupObj.Divider = DividerLine

                local ItemsContainer = Library:Create("Frame", {
                    Position = UDim2.fromOffset(0, 35), Size = UDim2.new(1, 0, 1, -35),
                    BackgroundTransparency = 1, Parent = Container
                })
                Library:Create("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = ItemsContainer })

                -- ============ TOGGLE ============
                function GroupObj:AddToggle(Idx, Info)
                    local Toggle = { Value = Info.Default or false, Type = "Toggle" }

                    local Holder = Library:Create("Frame", {
                        Size = UDim2.new(1, -20, 0, 14), BackgroundTransparency = 1,
                        Active = true, Parent = ItemsContainer, -- ФИКС: Active=true обязателен
                    })

                    local BoxOuter = Library:Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 0, 0.5, -6), BackgroundColor3 = Library.Colors.Black, BorderSizePixel = 0, Parent = Holder })
                    local BoxInner = Library:Create("Frame", { Position = UDim2.fromOffset(1,1), Size = UDim2.new(1, -2, 1, -2), BackgroundColor3 = Library.Colors.Panel, BorderSizePixel = 0, Parent = BoxOuter })
                    Library:AddStroke(BoxOuter, Library.Colors.OuterBorder, 1)

                    Library:Create("TextLabel", { Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, Font = Library.Font, Text = Info.Text, TextColor3 = Library.Colors.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })

                    local AddonArea = Library:Create("Frame", { Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -100, 0, 0), BackgroundTransparency = 1, Parent = Holder })
                    Library:Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = AddonArea })

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

                    -- ============ INLINE KEYPICKER (ФИКС: реально работает) ============
                    function Toggle:AddKeyPicker(KIdx, KInfo)
                        local KeyObj = {
                            Value = KInfo.Default or "None",
                            Mode = KInfo.Mode or "Toggle", -- Toggle / Hold
                            Picking = false,
                        }

                        local KBtn = Library:Create("TextLabel", {
                            Size = UDim2.fromOffset(34, 14), BackgroundColor3 = Library.Colors.Panel,
                            Font = Library.Font, Text = KeyObj.Value, TextColor3 = Library.Colors.TextDim,
                            TextSize = 12, Active = true, Parent = AddonArea, -- ФИКС: Active=true
                        })
                        Library:AddStroke(KBtn, Library.Colors.InnerBorder, 1)

                        local function Refresh()
                            if KeyObj.Picking then
                                KBtn.Text = "..."
                                KBtn.TextColor3 = Library.Colors.Accent
                                return
                            end
                            KBtn.Text = KeyObj.Value
                            KBtn.TextColor3 = (KeyObj.Value ~= "None") and Library.Colors.Text or Library.Colors.TextDim
                        end

                        KBtn.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 and not KeyObj.Picking then
                                KeyObj.Picking = true
                                Refresh()
                                local conn
                                conn = UserInputService.InputBegan:Connect(function(input2)
                                    local NewKey
                                    if input2.UserInputType == Enum.UserInputType.Keyboard then
                                        NewKey = input2.KeyCode.Name
                                    elseif input2.UserInputType == Enum.UserInputType.MouseButton1 then
                                        NewKey = "MB1"
                                    elseif input2.UserInputType == Enum.UserInputType.MouseButton2 then
                                        NewKey = "MB2"
                                    end

                                    if NewKey then
                                        if NewKey == "Escape" then
                                            NewKey = "None" -- Escape сбрасывает бинд
                                        end
                                        KeyObj.Value = NewKey
                                        KeyObj.Picking = false
                                        Refresh()
                                        getgenv().Options[KIdx] = KeyObj
                                        Library:SafeCallback(KInfo.Callback, NewKey)
                                        conn:Disconnect()
                                    end
                                end)
                            end
                        end)

                        -- ФИКС: реальная привязка — клавиша реально переключает Toggle
                        UserInputService.InputBegan:Connect(function(input)
                            if KeyObj.Picking or KeyObj.Value == "None" then return end

                            local Pressed = false
                            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == KeyObj.Value then
                                Pressed = true
                            elseif input.UserInputType == Enum.UserInputType.MouseButton1 and KeyObj.Value == "MB1" then
                                Pressed = true
                            elseif input.UserInputType == Enum.UserInputType.MouseButton2 and KeyObj.Value == "MB2" then
                                Pressed = true
                            end

                            if Pressed then
                                if KeyObj.Mode == "Toggle" then
                                    Toggle.Value = not Toggle.Value
                                    Update()
                                elseif KeyObj.Mode == "Hold" then
                                    Toggle.Value = true
                                    Update()
                                end
                            end
                        end)

                        if KeyObj.Mode == "Hold" then
                            UserInputService.InputEnded:Connect(function(input)
                                local Released = false
                                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == KeyObj.Value then Released = true
                                elseif input.UserInputType == Enum.UserInputType.MouseButton1 and KeyObj.Value == "MB1" then Released = true
                                elseif input.UserInputType == Enum.UserInputType.MouseButton2 and KeyObj.Value == "MB2" then Released = true end
                                if Released then
                                    Toggle.Value = false
                                    Update()
                                end
                            end)
                        end

                        Refresh()
                        getgenv().Options[KIdx] = KeyObj
                        return self
                    end

                    -- ============ INLINE COLORPICKER (ФИКС: полноценный попап) ============
                    function Toggle:AddColorPicker(CIdx, CInfo)
                        local ColorPicker = { Value = CInfo.Default or Color3.fromRGB(255,255,255) }
                        local Hue, Sat, Vib = Color3.toHSV(ColorPicker.Value)
                        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Hue, Sat, Vib

                        local CBtn = Library:Create("Frame", {
                            Size = UDim2.fromOffset(18, 14), BackgroundColor3 = ColorPicker.Value,
                            Active = true, Parent = AddonArea, -- ФИКС: Active=true
                        })
                        Library:AddStroke(CBtn, Library.Colors.InnerBorder, 1)

                        local Popup = Library:Create("Frame", {
                            Size = UDim2.fromOffset(200, 180), BackgroundColor3 = Library.Colors.Panel,
                            BorderSizePixel = 0, Visible = false, ZIndex = 50, Active = true,
                            Parent = Library.PopupContainer,
                        })
                        Library:AddStroke(Popup, Library.Colors.InnerBorder, 1)

                        local SatVibMap = Library:Create("ImageLabel", {
                            Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(160, 160),
                            Image = "rbxassetid://4155801252", BackgroundColor3 = ColorPicker.Value,
                            ZIndex = 51, Active = true, Parent = Popup,
                        })

                        local Cursor = Library:Create("Frame", {
                            Size = UDim2.fromOffset(4,4), AnchorPoint = Vector2.new(0.5,0.5),
                            BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
                            ZIndex = 52, Parent = SatVibMap,
                        })

                        local HueBar = Library:Create("Frame", {
                            Position = UDim2.fromOffset(180, 10), Size = UDim2.fromOffset(10, 160),
                            ZIndex = 51, Active = true, Parent = Popup,
                        })
                        local Sequence = {}
                        for i = 0, 1, 0.1 do table.insert(Sequence, ColorSequenceKeypoint.new(i, Color3.fromHSV(i,1,1))) end
                        Library:Create("UIGradient", { Color = ColorSequence.new(Sequence), Rotation = 90, Parent = HueBar })

                        local HueCursor = Library:Create("Frame", {
                            Size = UDim2.new(1,0,0,2), BorderSizePixel = 0,
                            BackgroundColor3 = Color3.new(1,1,1), ZIndex = 52, Parent = HueBar,
                        })

                        local function UpdateDisplay()
                            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
                            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
                            CBtn.BackgroundColor3 = ColorPicker.Value
                            Cursor.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
                            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)
                            getgenv().Options[CIdx] = ColorPicker
                            Library:SafeCallback(CInfo.Callback, ColorPicker.Value)
                        end

                        SatVibMap.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                local conn
                                conn = RunService.RenderStepped:Connect(function()
                                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                                        local relX = math.clamp((Mouse.X - SatVibMap.AbsolutePosition.X)/SatVibMap.AbsoluteSize.X,0,1)
                                        local relY = math.clamp((Mouse.Y - SatVibMap.AbsolutePosition.Y)/SatVibMap.AbsoluteSize.Y,0,1)
                                        ColorPicker.Sat = relX
                                        ColorPicker.Vib = 1 - relY
                                        UpdateDisplay()
                                    else
                                        conn:Disconnect()
                                    end
                                end)
                            end
                        end)

                        HueBar.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                local conn
                                conn = RunService.RenderStepped:Connect(function()
                                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                                        local relY = math.clamp((Mouse.Y - HueBar.AbsolutePosition.Y)/HueBar.AbsoluteSize.Y,0,1)
                                        ColorPicker.Hue = relY
                                        UpdateDisplay()
                                    else
                                        conn:Disconnect()
                                    end
                                end)
                            end
                        end)

                        CBtn.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                local State = not Popup.Visible
                                Library:CloseAllPopups(Popup)
                                Popup.Visible = State
                                if State then
                                    Popup.Position = UDim2.fromOffset(CBtn.AbsolutePosition.X - 180, CBtn.AbsolutePosition.Y + 16)
                                    Library.OpenedPopups[Popup] = true
                                else
                                    Library.OpenedPopups[Popup] = nil
                                end
                            end
                        end)

                        UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 and Popup.Visible then
                                if not Library:IsMouseOver(Popup) and not Library:IsMouseOver(CBtn) then
                                    Popup.Visible = false
                                    Library.OpenedPopups[Popup] = nil
                                end
                            end
                        end)

                        UpdateDisplay()
                        getgenv().Options[CIdx] = ColorPicker
                        return self
                    end

                    return Toggle
                end

                -- ============ SLIDER ============
                function GroupObj:AddSlider(Idx, Info)
                    assert(Info.Min and Info.Max, "AddSlider: Min и Max обязательны")
                    local Slider = { Value = Info.Default or Info.Min }

                    local Holder = Library:Create("Frame", { Size = UDim2.new(1, -20, 0, 32), BackgroundTransparency = 1, Parent = ItemsContainer })

                    Library:Create("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Library.Font, Text = Info.Text, TextColor3 = Library.Colors.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
                    local ValueLabel = Library:Create("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Library.Font, Text = tostring(Slider.Value), TextColor3 = Library.Colors.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = Holder })

                    local Bar = Library:Create("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 0, 18), BackgroundColor3 = Library.Colors.PanelInner, BorderSizePixel = 0, Active = true, Parent = Holder })
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
                            local conn
                            conn = RunService.RenderStepped:Connect(function()
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

                -- ============ DROPDOWN (ФИКС: добавлен) ============
                function GroupObj:AddDropdown(Idx, Info)
                    assert(Info.Values, "AddDropdown: Values обязателен")
                    local Dropdown = { Values = Info.Values, Value = Info.Multi and {} or Info.Default, Multi = Info.Multi }

                    local Holder = Library:Create("Frame", { Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1, Parent = ItemsContainer })

                    Library:Create("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Library.Font,
                        Text = Info.Text or "Dropdown", TextColor3 = Library.Colors.Text, TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder
                    })

                    local Box = Library:Create("Frame", {
                        Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0,0,0,18),
                        BackgroundColor3 = Library.Colors.PanelInner, BorderSizePixel = 0,
                        Active = true, Parent = Holder,
                    })
                    Library:AddStroke(Box, Library.Colors.OuterBorder, 1)

                    local DisplayLabel = Library:Create("TextLabel", {
                        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(6,0),
                        BackgroundTransparency = 1, Font = Library.Font, Text = "--",
                        TextColor3 = Library.Colors.TextDim, TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left, Parent = Box
                    })

                    Library:Create("TextLabel", {
                        Size = UDim2.fromOffset(16,18), Position = UDim2.new(1,-18,0,0),
                        BackgroundTransparency = 1, Font = Library.Font, Text = "v",
                        TextColor3 = Library.Colors.TextDim, TextSize = 10, Parent = Box
                    })

                    local Popup = Library:Create("Frame", {
                        BackgroundColor3 = Library.Colors.Panel, BorderSizePixel = 0,
                        Visible = false, ZIndex = 50, Active = true, Parent = Library.PopupContainer,
                    })
                    Library:AddStroke(Popup, Library.Colors.InnerBorder, 1)
                    Library:Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Popup })

                    local function RefreshDisplay()
                        if Dropdown.Multi then
                            local names = {}
                            for k, v in pairs(Dropdown.Value) do if v then table.insert(names, k) end end
                            DisplayLabel.Text = (#names > 0) and table.concat(names, ", ") or "--"
                        else
                            DisplayLabel.Text = Dropdown.Value or "--"
                        end
                    end

                    local OptionButtons = {}
                    local function BuildList()
                        for _, c in pairs(Popup:GetChildren()) do
                            if c:IsA("TextLabel") then c:Destroy() end
                        end
                        table.clear(OptionButtons)

                        for i, val in ipairs(Dropdown.Values) do
                            local Selected = Dropdown.Multi and Dropdown.Value[val] or (Dropdown.Value == val)
                            local OptBtn = Library:Create("TextLabel", {
                                Size = UDim2.new(1,0,0,18), BackgroundColor3 = Library.Colors.Panel,
                                Font = Library.Font, Text = val, TextSize = 12, LayoutOrder = i,
                                TextColor3 = Selected and Library.Colors.Accent or Library.Colors.TextDim,
                                Active = true, ZIndex = 51, Parent = Popup,
                            })
                            OptBtn.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    if Dropdown.Multi then
                                        Dropdown.Value[val] = not Dropdown.Value[val]
                                        OptBtn.TextColor3 = Dropdown.Value[val] and Library.Colors.Accent or Library.Colors.TextDim
                                    else
                                        Dropdown.Value = val
                                        for _, b in pairs(OptionButtons) do b.TextColor3 = Library.Colors.TextDim end
                                        OptBtn.TextColor3 = Library.Colors.Accent
                                        Popup.Visible = false
                                        Library.OpenedPopups[Popup] = nil
                                    end
                                    RefreshDisplay()
                                    getgenv().Options[Idx] = Dropdown
                                    Library:SafeCallback(Info.Callback, Dropdown.Value)
                                end
                            end)
                            OptionButtons[val] = OptBtn
                        end
                        Popup.Size = UDim2.fromOffset(Box.AbsoluteSize.X, #Dropdown.Values * 18)
                    end

                    Box.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            local State = not Popup.Visible
                            Library:CloseAllPopups(Popup)
                            Popup.Visible = State
                            if State then
                                Popup.Position = UDim2.fromOffset(Box.AbsolutePosition.X, Box.AbsolutePosition.Y + Box.AbsoluteSize.Y + 1)
                                Library.OpenedPopups[Popup] = true
                            else
                                Library.OpenedPopups[Popup] = nil
                            end
                        end
                    end)

                    UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 and Popup.Visible then
                            if not Library:IsMouseOver(Popup) and not Library:IsMouseOver(Box) then
                                Popup.Visible = false
                                Library.OpenedPopups[Popup] = nil
                            end
                        end
                    end)

                    BuildList()
                    RefreshDisplay()
                    getgenv().Options[Idx] = Dropdown
                    return Dropdown
                end

                function GroupObj:AddLabel(Text)
                    return Library:Create("TextLabel", { Size = UDim2.new(1, -20, 0, 14), BackgroundTransparency = 1, Font = Library.Font, Text = Text, TextColor3 = Library.Colors.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = ItemsContainer })
                end

                return GroupObj
            end

            function SubObj:AddLeftGroupbox(GroupName) return createGroupbox("Left", GroupName) end
            function SubObj:AddRightGroupbox(GroupName) return createGroupbox("Right", GroupName) end

            table.insert(TabObj.SubTabs, SubObj)

            if #TabObj.SubTabs == 1 then
                -- показываем подтаб только если это активный таб
                if WindowObj.ActiveTab == Name then
                    WindowObj:SelectSubTab(Name, SubName)
                end
            end
            return SubObj
        end

        self.Tabs[Name] = TabObj

        -- ФИКС: Config (IsInternal) никогда не становится активным табом по умолчанию
        if not IsInternal and not self.ActiveTab then
            self:SelectTab(Name)
        end

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

    -- ==== ХАРДКОД ВКЛАДКИ CONFIG (ФИКС: создается синхронно, но не ломает порядок/активность) ====
    local ConfTab = WindowObj:AddTab("Config", true)
    local ConfSub = ConfTab:AddSubTab("Config")
    local LeftGrp = ConfSub:AddLeftGroupbox("Soon")
    local RightGrp = ConfSub:AddRightGroupbox("Soon")

    for _, Grp in ipairs({ LeftGrp, RightGrp }) do
        Grp.TitleLabel.Visible = false
        Grp.Divider.Visible = false
        Library:Create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Library.Font,
            Text = "Soon", TextColor3 = Library.Colors.TextDim, TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
            Parent = Grp.Instance,
        })
    end

    return WindowObj
end

return Library

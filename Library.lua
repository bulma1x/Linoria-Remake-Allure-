-- Основные сервисы
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Локальные переменные
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RenderStepped = RunService.RenderStepped

-- Защита GUI
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

-- Создаем основной ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)
ScreenGui.Name = "AllureUILibrary"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

-- Основные таблицы
local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

-- Класс Вкладки
local Tab = {}
Tab.__index = Tab

function Tab:AddLeftGroupbox(name)
    return self:AddGroupbox(name, true)
end

function Tab:AddRightGroupbox(name)
    return self:AddGroupbox(name, false)
end

function Tab:AddGroupbox(name, isLeft)
    local groupbox = {
        Name = name,
        Type = "Groupbox",
        Options = {},
        Left = isLeft,
        Parent = self,
        Content = nil,  -- Будет добавлен UI
        Layout = nil,
        Frame = nil
    }
    
    -- Создаем UI для групбокса
    groupbox.Frame = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),  -- Авто-размер
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Background,
        Parent = isLeft and self.LeftColumn or self.RightColumn
    })
    
    local groupTitle = self.Parent.Parent.Library:Create("TextLabel", {
        Text = name,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Outline,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        Parent = groupbox.Frame
    })
    
    groupbox.Content = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = groupbox.Frame
    })
    
    groupbox.Layout = self.Parent.Parent.Library:Create("UIListLayout", {
        Parent = groupbox.Content,
        Padding = UDim.new(0, 5)
    })
    
    -- Авто-размер групбокса
    groupbox.Layout.Changed:Connect(function(prop)
        if prop == "AbsoluteContentSize" then
            groupbox.Frame.Size = UDim2.new(1, 0, 0, groupbox.Layout.AbsoluteContentSize.Y + 25)
        end
    end)
    
    -- Регистрируем цвета
    self.Parent.Parent.Library:AddToRegistry(groupbox.Frame, { BackgroundColor3 = "Background" })
    self.Parent.Parent.Library:AddToRegistry(groupTitle, { BackgroundColor3 = "Outline", TextColor3 = "Font" })
    
    setmetatable(groupbox, {
        __index = function(self, key)
            local method = Tab.GroupboxMethods[key]
            if method then
                return function(self, ...)
                    return method(groupbox, ...)
                end
            end
            return nil
        end
    })
    
    table.insert(self.Groupboxes, groupbox)
    return groupbox
end

-- Методы групбокса
Tab.GroupboxMethods = {}

Tab.GroupboxMethods.AddLabel = function(self, text, wrap)
    local label = { 
        Type = "Label", 
        Text = text, 
        Wrap = wrap or false,
        Parent = self,
        Instance = nil,
        TextInstance = nil,
        ColorPicker = nil,
        KeyPicker = nil
    }
    
    -- Создаем UI для label
    local labelFrame = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    
    label.TextInstance = self.Parent.Parent.Library:Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        TextWrapped = wrap,
        Parent = labelFrame
    })
    
    label.Instance = labelFrame
    
    -- Регистрируем цвета
    self.Parent.Parent.Library:AddToRegistry(label.TextInstance, { TextColor3 = "Font" })
    
    function label:SetText(newText)
        self.Text = newText
        self.TextInstance.Text = newText
    end
    
    function label:AddColorPicker(options)
        options = options or {}
        local colorpicker = {
            Type = "ColorPicker",
            Parent = self,
            Options = options,
            Value = options.Default or Color3.fromRGB(255, 255, 255),
            Callback = options.Callback,
            Flag = options.Flag
        }
        
        -- Простой UI для colorpicker (кнопка с цветом)
        local cpButton = self.Parent.Parent.Library:Create("Frame", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -20, 0, 0),
            BackgroundColor3 = colorpicker.Value,
            Parent = label.Instance
        })
        
        self.Parent.Parent.Library:AddToRegistry(cpButton, { BackgroundColor3 = "Accent" })  -- Пример, обновлять при смене
        
        -- Клик для выбора цвета (заглушка, можно расширить)
        cpButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                -- Здесь можно открыть палитру, но для простоты печатаем
                print("ColorPicker activated")
                if colorpicker.Callback then
                    pcall(colorpicker.Callback, colorpicker.Value)
                end
            end
        end)
        
        if colorpicker.Flag then 
            Options[colorpicker.Flag] = colorpicker 
        end
        
        self.ColorPicker = colorpicker
        return colorpicker
    end
    
    function label:AddKeyPicker(options)
        options = options or {}
        local keypicker = {
            Type = "KeyPicker",
            Parent = self,
            Options = options,
            Value = options.Default or Enum.KeyCode.Unknown,
            Callback = options.Callback,
            Flag = options.Flag
        }
        
        -- Простой UI для keypicker
        local kpButton = self.Parent.Parent.Library:Create("TextButton", {
            Size = UDim2.new(0, 50, 0, 20),
            Position = UDim2.new(1, -50, 0, 0),
            Text = tostring(keypicker.Value.Name),
            BackgroundColor3 = self.Parent.Parent.Library.Colors.Outline,
            Parent = label.Instance
        })
        
        self.Parent.Parent.Library:AddToRegistry(kpButton, { BackgroundColor3 = "Outline" })
        
        -- Захват клавиши
        kpButton.MouseButton1Click:Connect(function()
            kpButton.Text = "..."
            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    keypicker.Value = input.KeyCode
                    kpButton.Text = input.KeyCode.Name
                    connection:Disconnect()
                    if keypicker.Callback then
                        pcall(keypicker.Callback, keypicker.Value)
                    end
                end
            end)
        end)
        
        if keypicker.Flag then 
            Options[keypicker.Flag] = keypicker 
        end
        
        self.KeyPicker = keypicker
        return keypicker
    end
    
    table.insert(self.Options, label)
    return label
end

Tab.GroupboxMethods.AddToggle = function(self, name, options)
    options = options or {}
    local toggle = {
        Type = "Toggle",
        Name = name,
        Value = options.Default or false,
        Callback = options.Callback,
        Flag = options.Flag,
        Text = options.Text or name,
        Tooltip = options.Tooltip,
        Parent = self,
        Instance = nil
    }
    
    -- Создаем UI для toggle
    local toggleFrame = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    
    local toggleLabel = self.Parent.Parent.Library:Create("TextLabel", {
        Text = toggle.Text,
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        Parent = toggleFrame
    })
    
    local toggleButton = self.Parent.Parent.Library:Create("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = toggle.Value and self.Parent.Parent.Library.Colors.Accent or self.Parent.Parent.Library.Colors.Outline,
        Text = "",
        Parent = toggleFrame
    })
    
    -- Регистрируем цвета
    self.Parent.Parent.Library:AddToRegistry(toggleLabel, { TextColor3 = "Font" })
    self.Parent.Parent.Library:AddToRegistry(toggleButton, { BackgroundColor3 = toggle.Value and "Accent" or "Outline" })
    
    toggleButton.MouseButton1Click:Connect(function()
        toggle:SetValue(not toggle.Value)
    end)
    
    toggle.Instance = toggleButton
    
    table.insert(self.Options, toggle)
    if toggle.Flag then 
        Toggles[toggle.Flag] = toggle 
        getgenv().Toggles = Toggles
    end
    
    local oldSet = toggle.SetValue or function() end
    function toggle:SetValue(value)
        self.Value = value
        self.Instance.BackgroundColor3 = value and self.Parent.Parent.Library.Colors.Accent or self.Parent.Parent.Library.Colors.Outline
        if self.Callback then 
            pcall(self.Callback, value) 
        end
        if self.Flag then 
            Toggles[self.Flag].Value = value 
        end
    end
    
    function toggle:GetValue()
        return self.Value
    end
    
    function toggle:OnChanged(callback)
        self.Callback = callback
    end
    
    return toggle
end

Tab.GroupboxMethods.AddButton = function(self, options)
    options = options or {}
    local button = {
        Type = "Button",
        Text = options.Text or "Button",
        Func = options.Func or function() end,
        DoubleClick = options.DoubleClick or false,
        Tooltip = options.Tooltip,
        Parent = self,
        SubButton = nil,
        Instance = nil
    }
    
    -- Создаем UI для button
    local buttonInstance = self.Parent.Parent.Library:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Accent,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        Text = button.Text,
        Parent = self.Content
    })
    
    self.Parent.Parent.Library:AddToRegistry(buttonInstance, { BackgroundColor3 = "Accent", TextColor3 = "Font" })
    
    buttonInstance.MouseButton1Click:Connect(function()
        pcall(button.Func)
    end)
    
    button.Instance = buttonInstance
    
    function button:AddButton(subOptions)
        subOptions = subOptions or {}
        local subButton = {
            Type = "SubButton",
            Text = subOptions.Text or "Sub Button",
            Func = subOptions.Func or function() end,
            DoubleClick = subOptions.DoubleClick or false,
            Tooltip = subOptions.Tooltip,
            Parent = self,
            Instance = nil
        }
        
        -- UI для subbutton (рядом или под)
        local subButtonInstance = self.Parent.Parent.Library:Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundColor3 = self.Parent.Parent.Library.Colors.Accent,
            TextColor3 = self.Parent.Parent.Library.Colors.Font,
            Text = subButton.Text,
            Parent = self.Content
        })
        
        self.Parent.Parent.Library:AddToRegistry(subButtonInstance, { BackgroundColor3 = "Accent", TextColor3 = "Font" })
        
        subButtonInstance.MouseButton1Click:Connect(function()
            pcall(subButton.Func)
        end)
        
        subButton.Instance = subButtonInstance
        
        self.SubButton = subButton
        return subButton
    end
    
    table.insert(self.Options, button)
    return button
end

Tab.GroupboxMethods.AddSlider = function(self, name, options)
    options = options or {}
    local slider = {
        Type = "Slider",
        Name = name,
        Value = options.Default or options.Min or 0,
        Min = options.Min or 0,
        Max = options.Max or 100,
        Rounding = options.Rounding or 0,
        Suffix = options.Suffix or "",
        Compact = options.Compact or false,
        HideMax = options.HideMax or false,
        Callback = options.Callback,
        Flag = options.Flag,
        Text = options.Text or name,
        Tooltip = options.Tooltip,
        Parent = self,
        Instance = nil,
        Fill = nil,
        Label = nil
    }
    
    -- Создаем UI для slider
    local sliderFrame = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    
    local sliderLabel = self.Parent.Parent.Library:Create("TextLabel", {
        Text = slider.Text,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        Parent = sliderFrame
    })
    
    local sliderBar = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Outline,
        Parent = sliderFrame
    })
    
    local sliderFill = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Accent,
        Parent = sliderBar
    })
    
    local sliderValue = self.Parent.Parent.Library:Create("TextLabel", {
        Text = tostring(slider.Value) .. slider.Suffix,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        Parent = sliderBar
    })
    
    self.Parent.Parent.Library:AddToRegistry(sliderLabel, { TextColor3 = "Font" })
    self.Parent.Parent.Library:AddToRegistry(sliderBar, { BackgroundColor3 = "Outline" })
    self.Parent.Parent.Library:AddToRegistry(sliderFill, { BackgroundColor3 = "Accent" })
    self.Parent.Parent.Library:AddToRegistry(sliderValue, { TextColor3 = "Font" })
    
    local function updateSlider(pos)
        local percent = math.clamp((pos - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        local value = math.floor((slider.Min + (slider.Max - slider.Min) * percent) / (10 ^ -slider.Rounding)) * (10 ^ -slider.Rounding)
        slider:SetValue(value)
    end
    
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(Mouse.X)
            local conn = RunService.RenderStepped:Connect(function()
                updateSlider(Mouse.X)
            end)
            local upConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    conn:Disconnect()
                    upConn:Disconnect()
                end
            end)
        end
    end)
    
    slider.Instance = sliderBar
    slider.Fill = sliderFill
    slider.Label = sliderValue
    
    table.insert(self.Options, slider)
    if slider.Flag then 
        Options[slider.Flag] = slider 
        getgenv().Options = Options
    end
    
    function slider:SetValue(value)
        local clamped = math.clamp(value, self.Min, self.Max)
        local rounded = self.Rounding > 0 and 
            math.floor((clamped * 10^self.Rounding) + 0.5) / (10^self.Rounding) or
            math.floor(clamped + 0.5)
        self.Value = rounded
        local percent = (rounded - self.Min) / (self.Max - self.Min)
        self.Fill.Size = UDim2.new(percent, 0, 1, 0)
        self.Label.Text = tostring(rounded) .. self.Suffix
        if self.Callback then 
            pcall(self.Callback, rounded) 
        end
        if self.Flag then 
            Options[self.Flag].Value = rounded 
        end
    end
    
    slider:SetValue(slider.Value)  -- Инициализация
    
    function slider:GetValue()
        return self.Value
    end
    
    function slider:OnChanged(callback)
        self.Callback = callback
    end
    
    return slider
end

Tab.GroupboxMethods.AddDropdown = function(self, name, options)
    options = options or {}
    local dropdown = {
        Type = "Dropdown",
        Name = name,
        Value = options.Default,
        Options = options.Values or options.Options or {},
        Multi = options.Multi or false,
        Callback = options.Callback,
        Flag = options.Flag,
        Text = options.Text or name,
        Tooltip = options.Tooltip,
        SpecialType = options.SpecialType,
        Parent = self,
        Instance = nil,
        List = nil
    }
    
    -- Создаем UI для dropdown
    local dropdownFrame = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    
    local dropdownButton = self.Parent.Parent.Library:Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Outline,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        Text = dropdown.Value or "Select",
        Parent = dropdownFrame
    })
    
    self.Parent.Parent.Library:AddToRegistry(dropdownButton, { BackgroundColor3 = "Outline", TextColor3 = "Font" })
    
    local dropdownList = self.Parent.Parent.Library:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 100),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Background,
        Visible = false,
        Parent = dropdownFrame
    })
    
    local listLayout = self.Parent.Parent.Library:Create("UIListLayout", { Parent = dropdownList })
    
    self.Parent.Parent.Library:AddToRegistry(dropdownList, { BackgroundColor3 = "Background" })
    
    local function updateList()
        for _, opt in ipairs(dropdown.Options) do
            local optButton = self.Parent.Parent.Library:Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 20),
                Text = opt,
                BackgroundColor3 = self.Parent.Parent.Library.Colors.Main,
                TextColor3 = self.Parent.Parent.Library.Colors.Font,
                Parent = dropdownList
            })
            
            self.Parent.Parent.Library:AddToRegistry(optButton, { BackgroundColor3 = "Main", TextColor3 = "Font" })
            
            optButton.MouseButton1Click:Connect(function()
                dropdown:SetValue(opt)
                dropdownList.Visible = false
            end)
        end
    end
    
    updateList()
    
    dropdownButton.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
    end)
    
    dropdown.Instance = dropdownButton
    dropdown.List = dropdownList
    
    table.insert(self.Options, dropdown)
    if dropdown.Flag then 
        Options[dropdown.Flag] = dropdown 
        getgenv().Options = Options
    end
    
    function dropdown:SetValue(value)
        self.Value = value
        self.Instance.Text = value
        if self.Callback then 
            pcall(self.Callback, value) 
        end
        if self.Flag then 
            Options[self.Flag].Value = value 
        end
    end
    
    function dropdown:AddOption(option)
        table.insert(self.Options, option)
        -- Обновить список
    end
    
    function dropdown:OnChanged(callback)
        self.Callback = callback
    end
    
    return dropdown
end

Tab.GroupboxMethods.AddInput = function(self, name, options)
    options = options or {}
    local input = {
        Type = "Input",
        Name = name,
        Value = options.Default or "",
        Placeholder = options.Placeholder or "",
        Numeric = options.Numeric or false,
        Finished = options.Finished or false,
        Callback = options.Callback,
        Flag = options.Flag,
        Text = options.Text or name,
        Tooltip = options.Tooltip,
        Parent = self,
        Instance = nil
    }
    
    -- Создаем UI для input
    local inputFrame = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    
    local inputLabel = self.Parent.Parent.Library:Create("TextLabel", {
        Text = input.Text,
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        Parent = inputFrame
    })
    
    local inputBox = self.Parent.Parent.Library:Create("TextBox", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Outline,
        TextColor3 = self.Parent.Parent.Library.Colors.Font,
        PlaceholderText = input.Placeholder,
        Text = input.Value,
        Parent = inputFrame
    })
    
    self.Parent.Parent.Library:AddToRegistry(inputLabel, { TextColor3 = "Font" })
    self.Parent.Parent.Library:AddToRegistry(inputBox, { BackgroundColor3 = "Outline", TextColor3 = "Font" })
    
    inputBox.FocusLost:Connect(function(enter)
        if enter or not input.Finished then
            input:SetValue(inputBox.Text)
        end
    end)
    
    input.Instance = inputBox
    
    table.insert(self.Options, input)
    if input.Flag then 
        Options[input.Flag] = input 
        getgenv().Options = Options
    end
    
    function input:SetValue(value)
        self.Value = value
        self.Instance.Text = value
        if self.Callback then 
            pcall(self.Callback, value) 
        end
        if self.Flag then 
            Options[self.Flag].Value = value 
        end
    end
    
    function input:OnChanged(callback)
        self.Callback = callback
    end
    
    return input
end

Tab.GroupboxMethods.AddDivider = function(self)
    local divider = {
        Type = "Divider",
        Parent = self,
        Instance = nil
    }
    
    divider.Instance = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = self.Parent.Parent.Library.Colors.Outline,
        Parent = self.Content
    })
    
    self.Parent.Parent.Library:AddToRegistry(divider.Instance, { BackgroundColor3 = "Outline" })
    
    table.insert(self.Options, divider)
    return divider
end

Tab.GroupboxMethods.AddDependencyBox = function(self)
    local depbox = {
        Type = "DependencyBox",
        Dependencies = {},
        Options = {},
        Parent = self,
        Frame = nil,
        Content = nil,
        Layout = nil
    }
    
    -- UI для depbox (подфрейм)
    depbox.Frame = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    
    depbox.Layout = self.Parent.Parent.Library:Create("UIListLayout", {
        Parent = depbox.Frame,
        Padding = UDim.new(0, 5)
    })
    
    depbox.Layout.Changed:Connect(function(prop)
        if prop == "AbsoluteContentSize" then
            depbox.Frame.Size = UDim2.new(1, 0, 0, depbox.Layout.AbsoluteContentSize.Y)
        end
    end)
    
    table.insert(self.Options, depbox)
    
    -- Добавляем методы
    for name, method in pairs(Tab.GroupboxMethods) do
        if name ~= "AddDependencyBox" then
            depbox[name] = function(_, ...)
                return method(depbox, ...)
            end
        end
    end
    
    function depbox:SetupDependencies(dependencies)
        self.Dependencies = dependencies or {}
        -- Здесь можно добавить логику проверки зависимостей и установки Visible
        -- Для простоты пропустим детальную реализацию,假设 всегда visible
        self.Frame.Visible = true
    end
    
    return depbox
end

Tab.GroupboxMethods.AddRightTabbox = function(self)
    return self:AddTabbox(false)
end

Tab.GroupboxMethods.AddLeftTabbox = function(self)
    return self:AddTabbox(true)
end

Tab.GroupboxMethods.AddTabbox = function(self, isLeft)
    local tabbox = {
        Type = "Tabbox",
        Tabs = {},
        Left = isLeft,
        Parent = self,
        Frame = nil
    }
    
    -- UI для tabbox
    tabbox.Frame = self.Parent.Parent.Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 200),  -- Фиксированный, можно авто
        BackgroundTransparency = 1,
        Parent = self.Content
    })
    
    table.insert(self.Options, tabbox)
    
    function tabbox:AddTab(name)
        local tab = {
            Name = name,
            Type = "Tab",
            Options = {},
            Parent = self,
            Groupboxes = {}
        }
        
        setmetatable(tab, { __index = Tab })
        tab.Groupboxes = {}
        
        -- UI для вложенной вкладки (заглушка, можно расширить)
        tab.Frame = self.Parent.Parent.Library:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Parent = tabbox.Frame
        })
        
        table.insert(self.Tabs, tab)
        return tab
    end
    
    return tabbox
end

-- Основная библиотека
local Library = {
    Registry = {},
    RegistryMap = {},
    HudRegistry = {},
    Colors = {
        Font = Color3.fromRGB(255, 255, 255),
        Main = Color3.fromRGB(28, 28, 28),
        Background = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(0, 85, 255),
        Outline = Color3.fromRGB(50, 50, 50),
        Risk = Color3.fromRGB(255, 50, 50),
        Black = Color3.new(0, 0, 0),
        Success = Color3.fromRGB(0, 200, 0)
    },
    Font = Enum.Font.Code,
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    ScreenGui = ScreenGui,
    CurrentRainbowHue = 0,
    CurrentRainbowColor = Color3.fromHSV(0, 0.8, 1),
    Watermark = {
        Visible = false,
        Instance = nil,
        Text = "Allure UI",
        Position = UDim2.new(0.5, 0, 0, 10)
    },
    OpenFrames = {},
    KeybindCaptured = false,
    Tab = Tab  -- Экспортируем класс Tab
}

function Library:CreateWindow(config)
    config = config or {}
    
    local window = {
        Tabs = {},
        Groupboxes = {},
        IsVisible = config.AutoShow or false,
        Title = config.Title or "Allure UI",
        Parent = self,
        Library = self,
        Holder = nil,
        TabContainer = nil,
        Content = nil
    }
    
    -- Создаем holder для окна
    window.Holder = self:Create("Frame", {
        Name = "Window",
        BackgroundColor3 = self.Colors.Black,
        BorderSizePixel = 0,
        Position = config.Center and UDim2.fromScale(0.5, 0.5) or config.Position or UDim2.fromOffset(100, 100),
        Size = config.Size or UDim2.fromOffset(600, 500),
        AnchorPoint = config.Center and Vector2.new(0.5, 0.5) or Vector2.new(0, 0),
        Visible = window.IsVisible,
        Parent = self.ScreenGui
    })
    
    self:AddToRegistry(window.Holder, { BackgroundColor3 = "Black" })
    
    -- Titlebar
    local titlebar = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Colors.Main,
        Parent = window.Holder
    })
    
    local title = self:Create("TextLabel", {
        Text = window.Title,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Colors.Font,
        Font = self.Font,
        Parent = titlebar
    })
    
    self:AddToRegistry(titlebar, { BackgroundColor3 = "Main" })
    self:AddToRegistry(title, { TextColor3 = "Font" })
    
    -- Tab container
    window.TabContainer = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = self.Colors.Outline,
        Parent = window.Holder
    })
    
    local tabLayout = self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Parent = window.TabContainer
    })
    
    self:AddToRegistry(window.TabContainer, { BackgroundColor3 = "Outline" })
    
    -- Content
    window.Content = self:Create("Frame", {
        Size = UDim2.new(1, 0, 1, -60),
        Position = UDim2.new(0, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = window.Holder
    })
    
    -- Функция добавления вкладки
    function window:AddTab(name)
        local tab = {
            Name = name,
            Groupboxes = {},
            Parent = window,
            Type = "Tab",
            Frame = nil,
            LeftColumn = nil,
            RightColumn = nil,
            LeftLayout = nil,
            RightLayout = nil,
            Button = nil
        }
        
        setmetatable(tab, { __index = Tab })
        tab.Groupboxes = {}
        
        tab.Frame = self.Library:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = window.Content
        })
        
        tab.LeftColumn = self.Library:Create("Frame", {
            Size = UDim2.new(0.5, -5, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Parent = tab.Frame
        })
        
        tab.RightColumn = self.Library:Create("Frame", {
            Size = UDim2.new(0.5, -5, 1, 0),
            Position = UDim2.new(0.5, 5, 0, 0),
            BackgroundTransparency = 1,
            Parent = tab.Frame
        })
        
        tab.LeftLayout = self.Library:Create("UIListLayout", { Parent = tab.LeftColumn, Padding = UDim.new(0, 5) })
        tab.RightLayout = self.Library:Create("UIListLayout", { Parent = tab.RightColumn, Padding = UDim.new(0, 5) })
        
        -- Tab button
        tab.Button = self.Library:Create("TextButton", {
            Text = name,
            Size = UDim2.new(0, 100, 1, 0),
            BackgroundColor3 = self.Library.Colors.Background,
            TextColor3 = self.Library.Colors.Font,
            Parent = window.TabContainer
        })
        
        self.Library:AddToRegistry(tab.Button, { BackgroundColor3 = "Background", TextColor3 = "Font" })
        
        tab.Button.MouseButton1Click:Connect(function()
            for _, t in ipairs(window.Tabs) do
                t.Frame.Visible = false
            end
            tab.Frame.Visible = true
        end)
        
        if #window.Tabs == 0 then
            tab.Frame.Visible = true
        end
        
        table.insert(window.Tabs, tab)
        return tab
    end
    
    -- Функции управления окном
    function window:Toggle()
        window.IsVisible = not window.IsVisible
        window.Holder.Visible = window.IsVisible
    end
    
    function window:Hide()
        window.IsVisible = false
        window.Holder.Visible = false
    end
    
    function window:Show()
        window.IsVisible = true
        window.Holder.Visible = true
    end
    
    return window
end

function Library:Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    return instance
end

function Library:CreateWatermark()
    if self.Watermark.Instance and self.Watermark.Instance.Parent then
        return self.Watermark.Instance
    end
    
    local watermark = Instance.new("Frame")
    watermark.Name = "Watermark"
    watermark.BackgroundColor3 = self.Colors.Main
    watermark.BorderSizePixel = 0
    watermark.Size = UDim2.new(0, 200, 0, 30)
    watermark.Position = self.Watermark.Position
    watermark.AnchorPoint = Vector2.new(0.5, 0)
    watermark.Visible = self.Watermark.Visible
    watermark.ZIndex = 999
    watermark.Parent = self.ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = watermark
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Colors.Outline
    stroke.Thickness = 1
    stroke.Parent = watermark
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = self.Watermark.Text
    label.Font = self.Font
    label.TextColor3 = self.Colors.Font
    label.TextSize = 14
    label.TextStrokeTransparency = 0.5
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = watermark.ZIndex + 1
    label.Parent = watermark
    
    self:AddToRegistry(watermark, { BackgroundColor3 = "Main" })
    self:AddToRegistry(stroke, { Color = "Outline" })
    self:AddToRegistry(label, { TextColor3 = "Font" })
    
    self.Watermark.Instance = watermark
    return watermark
end

function Library:UpdateWatermark(text)
    if not text then return end
    
    self.Watermark.Text = text
    
    if self.Watermark.Instance then
        local label = self.Watermark.Instance:FindFirstChild("Label")
        if label then
            label.Text = text
            local textWidth = self:GetTextBounds(text, self.Font, 14)
            if textWidth > 0 then
                self.Watermark.Instance.Size = UDim2.new(0, textWidth + 20, 0, 30)
            end
        end
    end
end

function Library:SetWatermarkVisibility(visible)
    self.Watermark.Visible = visible
    if visible and not self.Watermark.Instance then
        self:CreateWatermark()
    end
    if self.Watermark.Instance then
        self.Watermark.Instance.Visible = visible
    end
end

function Library:SetWatermark(text)
    if not text then return end

    self.Watermark.Text = text

    -- Создаём, если нужно и включено
    if self.Watermark.Visible and not self.Watermark.Instance then
        self:CreateWatermark()
    end

    -- Если инстанса всё ещё нет — выходим
    if not self.Watermark.Instance then return end

    local label = self.Watermark.Instance:FindFirstChild("Label")
    if not label then return end

    label.Text = text

    -- Вот здесь главное исправление:
    local textSize = self:GetTextBounds(text, self.Font, 14) or Vector2.new(100, 20)
    local width = textSize.X   -- ← берём .X !

    -- Минимальная ширина, чтобы не сжимался до нуля
    width = math.max(width, 80)

    self.Watermark.Instance.Size = UDim2.new(0, width + 24, 0, 30)
end

function Library:GetTextBounds(text, font, size, resolution)
    resolution = resolution or Vector2.new(1920, 1080)
    return TextService:GetTextSize(tostring(text), size, font, resolution)
end

function Library:AddToRegistry(instance, properties, isHud)
    local data = {
        Instance = instance,
        Properties = properties,
        Index = #self.Registry + 1
    }
    
    table.insert(self.Registry, data)
    self.RegistryMap[instance] = data
    
    if isHud then
        table.insert(self.HudRegistry, data)
    end
end

function Library:Notify(message, duration)
    duration = duration or 5
    -- Простое уведомление через print, можно расширить на UI
    print("[Allure] " .. message)
end

function Library:GiveSignal(signal)
    table.insert(self.Signals, signal)
end

function Library:OnUnload(callback)
    self.OnUnload = callback
end

function Library:Unload()
    for _, signal in ipairs(self.Signals) do
        signal:Disconnect()
    end
    
    if self.OnUnload then
        self.OnUnload()
    end
    
    self.ScreenGui:Destroy()
end

-- ThemeManager и SaveManager в одном объекте (как подмодули)
Library.ThemeManager = {}
Library.SaveManager = {}

-- ThemeManager
Library.ThemeManager.Themes = {
    Default = Library.Colors,
    Dark = {
        Font = Color3.fromRGB(255, 255, 255),
        Main = Color3.fromRGB(15, 15, 15),
        Background = Color3.fromRGB(10, 10, 10),
        Accent = Color3.fromRGB(0, 100, 200),
        Outline = Color3.fromRGB(30, 30, 30),
        Risk = Color3.fromRGB(200, 50, 50),
        Black = Color3.new(0, 0, 0),
        Success = Color3.fromRGB(0, 150, 0)
    }
    -- Можно добавить больше тем
}

function Library.ThemeManager.ApplyTheme(themeName)
    local theme = Library.ThemeManager.Themes[themeName] or Library.ThemeManager.Themes.Default
    Library.Colors = theme
    
    for _, data in ipairs(Library.Registry) do
        for prop, colorKey in pairs(data.Properties) do
            data.Instance[prop] = Library.Colors[colorKey]
        end
    end
end

-- SaveManager
function Library.SaveManager.GetConfig()
    local config = {}
    for flag, toggle in pairs(Toggles) do
        config[flag] = toggle.Value
    end
    for flag, option in pairs(Options) do
        config[flag] = option.Value
    end
    return HttpService:JSONEncode(config)
end

function Library.SaveManager.SetConfig(json)
    local config = HttpService:JSONDecode(json)
    for flag, value in pairs(config) do
        if Toggles[flag] then
            Toggles[flag]:SetValue(value)
        elseif Options[flag] then
            Options[flag]:SetValue(value)
        end
    end
end

function Library.SaveManager.Save(name)
    if not writefile then
        warn("writefile not available")
        return
    end
    local folder = "allure_configs/"
    if not isfolder(folder) then
        makefolder(folder)
    end
    local file = folder .. name .. ".json"
    writefile(file, Library.SaveManager.GetConfig())
end

function Library.SaveManager.Load(name)
    if not readfile then
        warn("readfile not available")
        return
    end
    local folder = "allure_configs/"
    local file = folder .. name .. ".json"
    if isfile(file) then
        local json = readfile(file)
        Library.SaveManager.SetConfig(json)
    end
end

-- Возвращаем библиотеку
getgenv().AllureLibrary = Library
return Library

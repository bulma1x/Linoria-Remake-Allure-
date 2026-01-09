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
        Parent = self
    }
    
    setmetatable(groupbox, {
        __index = function(self, key)
            -- Если вызываем метод как функцию
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
        Parent = self 
    }
    table.insert(self.Options, label)
    
    function label:SetText(newText)
        self.Text = newText
    end
    
    function label:AddColorPicker(options)
        local colorpicker = {
            Type = "ColorPicker",
            Parent = self,
            Options = options or {}
        }
        self.ColorPicker = colorpicker
        return colorpicker
    end
    
    function label:AddKeyPicker(options)
        local keypicker = {
            Type = "KeyPicker",
            Parent = self,
            Options = options or {}
        }
        self.KeyPicker = keypicker
        return keypicker
    end
    
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
        Parent = self
    }
    
    table.insert(self.Options, toggle)
    if toggle.Flag then 
        Toggles[toggle.Flag] = toggle 
        getgenv().Toggles = Toggles
    end
    
    function toggle:SetValue(value)
        self.Value = value
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
        Parent = self
    }
    
    table.insert(self.Options, button)
    
    function button:AddButton(subOptions)
        subOptions = subOptions or {}
        local subButton = {
            Type = "SubButton",
            Text = subOptions.Text or "Sub Button",
            Func = subOptions.Func or function() end,
            DoubleClick = subOptions.DoubleClick or false,
            Tooltip = subOptions.Tooltip,
            Parent = self
        }
        self.SubButton = subButton
        return subButton
    end
    
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
        Parent = self
    }
    
    table.insert(self.Options, slider)
    if slider.Flag then 
        Options[slider.Flag] = slider 
        getgenv().Options = Options
    end
    
    function slider:SetValue(value)
        local rounded = self.Rounding > 0 and 
            math.floor((math.clamp(value, self.Min, self.Max) * 10^self.Rounding) + 0.5) / (10^self.Rounding) or
            math.floor(math.clamp(value, self.Min, self.Max) + 0.5)
        self.Value = rounded
        if self.Callback then 
            pcall(self.Callback, rounded) 
        end
        if self.Flag then 
            Options[self.Flag].Value = rounded 
        end
    end
    
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
        Parent = self
    }
    
    table.insert(self.Options, dropdown)
    if dropdown.Flag then 
        Options[dropdown.Flag] = dropdown 
        getgenv().Options = Options
    end
    
    function dropdown:SetValue(value)
        self.Value = value
        if self.Callback then 
            pcall(self.Callback, value) 
        end
        if self.Flag then 
            Options[self.Flag].Value = value 
        end
    end
    
    function dropdown:AddOption(option)
        table.insert(self.Options, option)
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
        Parent = self
    }
    
    table.insert(self.Options, input)
    if input.Flag then 
        Options[input.Flag] = input 
        getgenv().Options = Options
    end
    
    function input:SetValue(value)
        self.Value = value
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
        Parent = self
    }
    table.insert(self.Options, divider)
    return divider
end

Tab.GroupboxMethods.AddDependencyBox = function(self)
    local depbox = {
        Type = "DependencyBox",
        Dependencies = {},
        Options = {},
        Parent = self
    }
    
    table.insert(self.Options, depbox)
    
    -- Добавляем те же методы что и у групбокса
    for name, method in pairs(Tab.GroupboxMethods) do
        if name ~= "AddDependencyBox" then
            depbox[name] = function(self, ...)
                return method(depbox, ...)
            end
        end
    end
    
    function depbox:SetupDependencies(dependencies)
        self.Dependencies = dependencies or {}
    end
    
    function depbox:AddDependencyBox()
        return Tab.GroupboxMethods.AddDependencyBox(self)
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
        Parent = self
    }
    
    table.insert(self.Options, tabbox)
    
    function tabbox:AddTab(name)
        local tab = {
            Name = name,
            Type = "Tab",
            Options = {},
            Parent = self
        }
        
        setmetatable(tab, { __index = Tab })
        tab.Groupboxes = {}
        
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
        Title = config.Title or "Allure UI"
    }
    
    -- Создаем holder для окна
    local holder = self:Create("Frame", {
        Name = "Window",
        BackgroundColor3 = self.Colors.Black,
        BorderSizePixel = 0,
        Position = config.Center and UDim2.fromScale(0.5, 0.5) or config.Position or UDim2.fromOffset(100, 100),
        Size = config.Size or UDim2.fromOffset(600, 500),
        AnchorPoint = config.Center and Vector2.new(0.5, 0.5) or Vector2.new(0, 0),
        Visible = window.IsVisible,
        Parent = self.ScreenGui
    })
    
    window.Holder = holder
    
    -- Функция добавления вкладки
    function window:AddTab(name)
        local tab = {
            Name = name,
            Groupboxes = {},
            Parent = self,
            Type = "Tab"
        }
        
        -- Устанавливаем метатаблицу для доступа к методам
        setmetatable(tab, { __index = Tab })
        
        -- Инициализируем Groupboxes как таблицу
        tab.Groupboxes = {}
        
        table.insert(self.Tabs, tab)
        return tab
    end
    
    -- Функции управления окном
    function window:Toggle()
        window.IsVisible = not window.IsVisible
        holder.Visible = window.IsVisible
    end
    
    function window:Hide()
        window.IsVisible = false
        holder.Visible = false
    end
    
    function window:Show()
        window.IsVisible = true
        holder.Visible = true
    end
    
    return window
end

-- Остальные методы библиотеки (Create, MakeDraggable, Notify и т.д.)
-- ... (вставьте сюда остальные методы из предыдущих версий)

function Library:Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        if instance[property] ~= nil then
            instance[property] = value
        end
    end
    return instance
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
    self.Watermark.Text = text
    if self.Watermark.Instance then
        local label = self.Watermark.Instance:FindFirstChild("Label")
        if label then
            label.Text = text
        end
    end
end

function Library:Notify(message, duration)
    duration = duration or 5
    print("[Allure] " .. message)  -- Временная заглушка
    -- Здесь будет реализация уведомлений
end

function Library:GiveSignal(signal)
    table.insert(self.Signals, signal)
end

function Library:OnUnload(callback)
    self.OnUnload = callback
end

function Library:Unload()
    for _, signal in ipairs(self.Signals) do
        pcall(function() signal:Disconnect() end)
    end
    
    if self.OnUnload then
        pcall(self.OnUnload)
    end
    
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- Возвращаем библиотеку
getgenv().AllureLibrary = Library
return Library

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
    KeybindCaptured = false
}

-- Утилиты
function Library:GetDarkerColor(color)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, v / 1.5)
end

function Library:GetTextBounds(text, font, size)
    if not text or not font or not size then return 0, 0 end
    local success, bounds = pcall(function()
        return TextService:GetTextSize(tostring(text), size, font, Vector2.new(10000, 10000))
    end)
    return success and bounds.X or #text * (size/2), success and bounds.Y or size
end

function Library:Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        if instance[property] ~= nil then
            instance[property] = value
        end
    end
    return instance
end

function Library:AddToRegistry(instance, properties, isHud)
    if not instance then return end
    local data = { Instance = instance, Properties = properties or {} }
    table.insert(self.Registry, data)
    self.RegistryMap[instance] = data
    if isHud then table.insert(self.HudRegistry, data) end
    return data
end

-- Водяной знак
function Library:CreateWatermark()
    if self.Watermark.Instance then return end
    
    local watermark = self:Create("Frame", {
        Name = "Watermark",
        BackgroundColor3 = self.Colors.Main,
        BorderColor3 = self.Colors.Outline,
        BorderSizePixel = 1,
        Size = UDim2.new(0, 200, 0, 30),
        Position = self.Watermark.Position,
        AnchorPoint = Vector2.new(0.5, 0),
        Visible = self.Watermark.Visible,
        ZIndex = 999,
        Parent = self.ScreenGui
    })
    
    self:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = watermark })
    
    local label = self:Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Text = self.Watermark.Text,
        Font = self.Font,
        TextColor3 = self.Colors.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1000,
        Parent = watermark
    })
    
    self.Watermark.Instance = watermark
    return watermark
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
            local width = self:GetTextBounds(text, self.Font, 14)
            self.Watermark.Instance.Size = UDim2.new(0, width + 20, 0, 30)
        end
    end
end

-- Класс вкладки
function Library.Tab:AddLeftGroupbox(name)
    return self:AddGroupbox(name, true)
end

function Library.Tab:AddRightGroupbox(name)
    return self:AddGroupbox(name, false)
end

function Library.Tab:AddGroupbox(name, isLeft)
    local groupbox = {
        Name = name,
        Type = "Groupbox",
        Options = {},
        Left = isLeft,
        Parent = self
    }
    
    table.insert(self.Groupboxes, groupbox)
    
    -- Функции групбокса
    function groupbox:AddLabel(text)
        local label = { Type = "Label", Text = text, Parent = self }
        table.insert(self.Options, label)
        
        function label:SetText(newText)
            self.Text = newText
            -- Обновление UI
        end
        
        return label
    end
    
    function groupbox:AddButton(name, callback)
        local button = { 
            Type = "Button", 
            Name = name, 
            Callback = callback,
            Parent = self 
        }
        table.insert(self.Options, button)
        
        function button:SetCallback(newCallback)
            self.Callback = newCallback
        end
        
        return button
    end
    
    function groupbox:AddToggle(name, options)
        options = options or {}
        local toggle = {
            Type = "Toggle",
            Name = name,
            Value = options.Default or false,
            Callback = options.Callback,
            Flag = options.Flag,
            Parent = self
        }
        
        table.insert(self.Options, toggle)
        if toggle.Flag then Toggles[toggle.Flag] = toggle end
        
        function toggle:SetValue(value)
            self.Value = value
            if self.Callback then self.Callback(value) end
            if self.Flag then Toggles[self.Flag].Value = value end
        end
        
        function toggle:GetValue()
            return self.Value
        end
        
        return toggle
    end
    
    function groupbox:AddSlider(name, options)
        options = options or {}
        local slider = {
            Type = "Slider",
            Name = name,
            Value = options.Default or options.Min or 0,
            Min = options.Min or 0,
            Max = options.Max or 100,
            Rounding = options.Rounding or 0,
            Callback = options.Callback,
            Flag = options.Flag,
            Parent = self
        }
        
        table.insert(self.Options, slider)
        if slider.Flag then Options[slider.Flag] = slider end
        
        function slider:SetValue(value)
            self.Value = math.clamp(value, self.Min, self.Max)
            if self.Callback then self.Callback(self.Value) end
        end
        
        function slider:GetValue()
            return self.Value
        end
        
        return slider
    end
    
    function groupbox:AddDropdown(name, options)
        options = options or {}
        local dropdown = {
            Type = "Dropdown",
            Name = name,
            Value = options.Default,
            Options = options.Options or {},
            Multi = options.Multi or false,
            Callback = options.Callback,
            Flag = options.Flag,
            Parent = self
        }
        
        table.insert(self.Options, dropdown)
        if dropdown.Flag then Options[dropdown.Flag] = dropdown end
        
        function dropdown:SetValue(value)
            self.Value = value
            if self.Callback then self.Callback(value) end
        end
        
        function dropdown:AddOption(option)
            table.insert(self.Options, option)
        end
        
        function dropdown:RemoveOption(option)
            for i, v in ipairs(self.Options) do
                if v == option then
                    table.remove(self.Options, i)
                    break
                end
            end
        end
        
        return dropdown
    end
    
    function groupbox:AddColorPicker(name, options)
        options = options or {}
        local colorpicker = {
            Type = "ColorPicker",
            Name = name,
            Value = options.Default or Color3.new(1, 1, 1),
            Callback = options.Callback,
            Flag = options.Flag,
            Parent = self
        }
        
        table.insert(self.Options, colorpicker)
        if colorpicker.Flag then Options[colorpicker.Flag] = colorpicker end
        
        function colorpicker:SetValue(value)
            self.Value = value
            if self.Callback then self.Callback(value) end
        end
        
        return colorpicker
    end
    
    function groupbox:AddKeyPicker(name, options)
        options = options or {}
        local keypicker = {
            Type = "KeyPicker",
            Name = name,
            Value = options.Default or "RightControl",
            Mode = options.Mode or "Toggle",
            Callback = options.Callback,
            Flag = options.Flag,
            Parent = self
        }
        
        table.insert(self.Options, keypicker)
        if keypicker.Flag then Options[keypicker.Flag] = keypicker end
        
        function keypicker:SetValue(value)
            self.Value = value
            if self.Callback then self.Callback(value) end
        end
        
        return keypicker
    end
    
    function groupbox:AddInput(name, options)
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
            Parent = self
        }
        
        table.insert(self.Options, input)
        if input.Flag then Options[input.Flag] = input end
        
        function input:SetValue(value)
            self.Value = value
            if self.Callback then self.Callback(value) end
        end
        
        return input
    end
    
    return groupbox
end

-- Создание окна
function Library:CreateWindow(config)
    config = config or {}
    
    local window = {
        Tabs = {},
        Groupboxes = {},
        IsVisible = config.AutoShow or false,
        Title = config.Title or "Allure UI"
    }
    
    -- Создание UI элементов окна
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
    
    local inner = self:Create("Frame", {
        BackgroundColor3 = self.Colors.Main,
        BorderColor3 = self.Colors.Accent,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        Parent = holder
    })
    
    window.Holder = holder
    window.Inner = inner
    
    -- Добавление вкладки
    function window:AddTab(name)
        local tab = {
            Name = name,
            Groupboxes = {},
            Parent = self
        }
        
        setmetatable(tab, { __index = Library.Tab })
        table.insert(self.Tabs, tab)
        return tab
    end
    
    -- Переключение видимости
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
    
    -- Перетаскивание
    self:MakeDraggable(holder, 25)
    
    return window
end

-- Перетаскивание
function Library:MakeDraggable(frame, cutoff)
    if not frame then return end
    frame.Active = true
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local offset = Vector2.new(
                Mouse.X - frame.AbsolutePosition.X,
                Mouse.Y - frame.AbsolutePosition.Y
            )
            
            if cutoff and offset.Y > cutoff then return end
            
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                frame.Position = UDim2.new(
                    0, Mouse.X - offset.X,
                    0, Mouse.Y - offset.Y
                )
                task.wait()
            end
        end
    end)
end

-- Нотификации
function Library:Notify(message, duration)
    duration = duration or 5
    
    local notification = self:Create("Frame", {
        BackgroundColor3 = self.Colors.Main,
        BorderColor3 = self.Colors.Outline,
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 0, 0, 40),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = self.ScreenGui
    })
    
    local label = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 1, -10),
        Position = UDim2.new(0, 10, 0, 5),
        Text = message,
        Font = self.Font,
        TextColor3 = self.Colors.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    local width = self:GetTextBounds(message, self.Font, 14)
    
    -- Анимация
    local showTween = TweenService:Create(notification, TweenInfo.new(0.3), {
        Size = UDim2.new(0, width + 30, 0, 40),
        Position = UDim2.new(1, -width - 40, 0, 10)
    })
    
    showTween:Play()
    
    task.delay(duration, function()
        local hideTween = TweenService:Create(notification, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 0, 0, 40),
            Position = UDim2.new(1, -10, 0, 10)
        })
        hideTween:Play()
        hideTween.Completed:Wait()
        notification:Destroy()
    end)
end

-- Управление библиотекой
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

-- Радужный эффект
task.spawn(function()
    while task.wait() do
        Library.CurrentRainbowHue = Library.CurrentRainbowHue + 0.01
        if Library.CurrentRainbowHue > 1 then
            Library.CurrentRainbowHue = 0
        end
        Library.CurrentRainbowColor = Color3.fromHSV(Library.CurrentRainbowHue, 0.8, 1)
    end
end)

-- Возвращаем библиотеку
getgenv().AllureLibrary = Library
return Library

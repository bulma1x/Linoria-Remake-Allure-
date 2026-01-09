-- Основные сервисы
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Локальные переменные
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RenderStepped = RunService.RenderStepped

-- Защита GUI (поддержка разных эксплойтов)
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

-- Создаем основной ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)
ScreenGui.Name = "AllureUILibrary"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

-- Основные таблицы для хранения элементов
local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

-- Основная библиотека
local Library = {
    Registry = {},         -- Реестр всех элементов
    RegistryMap = {},      -- Быстрый поиск по экземпляру
    HudRegistry = {},      -- Элементы HUD
    
    -- Цветовая схема
    Colors = {
        Font = Color3.fromRGB(255, 255, 255),
        Main = Color3.fromRGB(28, 28, 28),
        Background = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(0, 85, 255),
        Outline = Color3.fromRGB(50, 50, 50),
        Risk = Color3.fromRGB(255, 50, 50),
        Black = Color3.new(0, 0, 0)
    },
    
    Font = Enum.Font.Code,
    OpenedFrames = {},     -- Открытые окна
    DependencyBoxes = {},  -- Зависимые блоки
    Signals = {},          -- Подключения
    ScreenGui = ScreenGui, -- Основной GUI
    CurrentRainbowHue = 0,
    CurrentRainbowColor = Color3.fromHSV(0, 0.8, 1),
    
    -- Водяной знак
    Watermark = {
        Visible = false,
        Instance = nil,
        Text = "Allure UI",
        Position = UDim2.new(0.5, 0, 0, 10),
        Color = Color3.fromRGB(255, 255, 255),
        BackgroundColor = Color3.fromRGB(28, 28, 28),
        OutlineColor = Color3.fromRGB(50, 50, 50)
    }
}

-- Утилиты для работы с цветом
function Library:GetDarkerColor(color)
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, v / 1.5)
end

-- Глобальный радужный эффект
local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(deltaTime)
    RainbowStep = RainbowStep + deltaTime
    
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0
        Hue = Hue + (1 / 400)
        
        if Hue > 1 then
            Hue = 0
        end
        
        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

-- Водяной знак методы
function Library:CreateWatermark()
    if self.Watermark.Instance and self.Watermark.Instance.Parent then
        return self.Watermark.Instance
    end
    
    local watermark = Instance.new("Frame")
    watermark.Name = "Watermark"
    watermark.BackgroundColor3 = self.Watermark.BackgroundColor
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
    stroke.Color = self.Watermark.OutlineColor
    stroke.Thickness = 1
    stroke.Parent = watermark
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = self.Watermark.Text
    label.Font = self.Font
    label.TextColor3 = self.Watermark.Color
    label.TextSize = 14
    label.TextStrokeTransparency = 0.5
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = watermark.ZIndex + 1
    label.Parent = watermark
    
    self.Watermark.Instance = watermark
    return watermark
end

function Library:SetWatermark(text)
    if not text then return end
    
    self.Watermark.Text = text
    
    if self.Watermark.Instance then
        local label = self.Watermark.Instance:FindFirstChild("Label")
        if label then
            label.Text = text
            
            -- Автоматический размер
            local textWidth = self:GetTextBounds(text, self.Font, 14)
            if textWidth > 0 then
                self.Watermark.Instance.Size = UDim2.new(0, textWidth + 20, 0, 30)
            end
        end
    end
end

function Library:SetWatermarkVisibility(visible)
    if type(visible) ~= "boolean" then return end
    
    self.Watermark.Visible = visible
    
    -- Создаем водяной знак если он еще не существует
    if visible and not self.Watermark.Instance then
        self:CreateWatermark()
    end
    
    if self.Watermark.Instance then
        self.Watermark.Instance.Visible = visible
    end
end

function Library:UpdateWatermark(text)
    self:SetWatermark(text)
end

-- Вспомогательные функции
function Library:Create(className, properties)
    local instance = Instance.new(className)
    
    for property, value in pairs(properties) do
        if instance[property] ~= nil then
            instance[property] = value
        else
            warn("Свойство " .. property .. " не существует для " .. className)
        end
    end
    
    return instance
end

function Library:CreateLabel(properties, isHud)
    local label = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = self.Font,
        TextColor3 = self.Colors.Font,
        TextSize = 16,
        TextStrokeTransparency = 0
    })
    
    -- Добавляем обводку
    self:Create("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = label
    })
    
    -- Регистрируем цвет
    self:AddToRegistry(label, {
        TextColor3 = "Colors.Font"
    }, isHud)
    
    -- Применяем дополнительные свойства
    for property, value in pairs(properties) do
        if label[property] ~= nil then
            label[property] = value
        end
    end
    
    return label
end

-- Создание перетаскиваемого окна
function Library:MakeDraggable(frame, cutoff)
    if not frame then return end
    
    frame.Active = true
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local offset = Vector2.new(
                Mouse.X - frame.AbsolutePosition.X,
                Mouse.Y - frame.AbsolutePosition.Y
            )
            
            -- Проверяем, находится ли клик в верхней части
            if cutoff and offset.Y > cutoff then
                return
            end
            
            -- Перетаскивание
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local newX = Mouse.X - offset.X + (frame.Size.X.Offset * (frame.AnchorPoint.X or 0))
                local newY = Mouse.Y - offset.Y + (frame.Size.Y.Offset * (frame.AnchorPoint.Y or 0))
                
                frame.Position = UDim2.new(
                    0,
                    math.clamp(newX, 0, ScreenGui.AbsoluteSize.X - frame.AbsoluteSize.X),
                    0,
                    math.clamp(newY, 0, ScreenGui.AbsoluteSize.Y - frame.AbsoluteSize.Y)
                )
                
                RenderStepped:Wait()
            end
        end
    end)
end

-- Создание тултипа
function Library:AddToolTip(text, hoverInstance)
    if not text or not hoverInstance then return end
    
    local textWidth, textHeight = self:GetTextBounds(text, self.Font, 14)
    if not textWidth or not textHeight then return end
    
    local tooltip = self:Create("Frame", {
        Name = "Tooltip",
        BackgroundColor3 = self.Colors.Main,
        BorderColor3 = self.Colors.Outline,
        Size = UDim2.fromOffset(textWidth + 5, textHeight + 4),
        ZIndex = 100,
        Parent = self.ScreenGui,
        Visible = false
    })
    
    local label = self:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(textWidth, textHeight),
        TextSize = 14,
        Text = text,
        TextColor3 = self.Colors.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = tooltip.ZIndex + 1,
        Parent = tooltip
    })
    
    -- Регистрируем цвета
    self:AddToRegistry(tooltip, {
        BackgroundColor3 = "Colors.Main",
        BorderColor3 = "Colors.Outline"
    })
    
    self:AddToRegistry(label, {
        TextColor3 = "Colors.Font"
    })
    
    -- Отслеживание наведения мыши
    local isHovering = false
    
    hoverInstance.MouseEnter:Connect(function()
        if self:MouseIsOverOpenedFrame() then
            return
        end
        
        isHovering = true
        tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        tooltip.Visible = true
        
        while isHovering do
            RunService.Heartbeat:Wait()
            tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    
    hoverInstance.MouseLeave:Connect(function()
        isHovering = false
        tooltip.Visible = false
    end)
end

-- Регистрация элементов для динамического обновления цвета
function Library:AddToRegistry(instance, properties, isHud)
    if not instance then return end
    
    local index = #self.Registry + 1
    local data = {
        Instance = instance,
        Properties = properties or {},
        Index = index
    }
    
    table.insert(self.Registry, data)
    self.RegistryMap[instance] = data
    
    if isHud then
        table.insert(self.HudRegistry, data)
    end
    
    return data
end

function Library:RemoveFromRegistry(instance)
    if not instance then return end
    
    local data = self.RegistryMap[instance]
    
    if data then
        for i = #self.Registry, 1, -1 do
            if self.Registry[i] == data then
                table.remove(self.Registry, i)
            end
        end
        
        for i = #self.HudRegistry, 1, -1 do
            if self.HudRegistry[i] == data then
                table.remove(self.HudRegistry, i)
            end
        end
        
        self.RegistryMap[instance] = nil
    end
end

-- Создание главного окна
function Library:CreateWindow(config)
    config = config or {}
    
    -- Настройки по умолчанию
    local settings = {
        Title = config.Title or "Allure UI",
        Position = config.Position or UDim2.fromOffset(100, 100),
        Size = config.Size or UDim2.fromOffset(600, 500),
        Center = config.Center or false,
        TabPadding = config.TabPadding or 5,
        MenuFadeTime = config.MenuFadeTime or 0.2,
        AutoShow = config.AutoShow or false
    }
    
    if settings.Center then
        settings.Position = UDim2.fromScale(0.5, 0.5)
        settings.AnchorPoint = Vector2.new(0.5, 0.5)
    else
        settings.AnchorPoint = Vector2.new(0, 0)
    end
    
    -- Создаем окно
    local window = {
        Tabs = {},
        IsVisible = false
    }
    
    -- Внешний контейнер
    local outerFrame = self:Create("Frame", {
        Name = "Window",
        AnchorPoint = settings.AnchorPoint,
        BackgroundColor3 = self.Colors.Black,
        BorderSizePixel = 0,
        Position = settings.Position,
        Size = settings.Size,
        Visible = false,
        ZIndex = 1,
        Parent = self.ScreenGui
    })
    
    -- Делаем окно перетаскиваемым
    self:MakeDraggable(outerFrame, 25)
    
    -- Внутренний контейнер
    local innerFrame = self:Create("Frame", {
        BackgroundColor3 = self.Colors.Main,
        BorderColor3 = self.Colors.Accent,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 1,
        Parent = outerFrame
    })
    
    -- Заголовок окна
    local titleLabel = self:CreateLabel({
        Position = UDim2.new(0, 7, 0, 0),
        Size = UDim2.new(0, 0, 0, 25),
        Text = settings.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1,
        Parent = innerFrame
    })
    
    -- Основная секция
    local mainSection = self:Create("Frame", {
        BackgroundColor3 = self.Colors.Background,
        BorderColor3 = self.Colors.Outline,
        Position = UDim2.new(0, 8, 0, 25),
        Size = UDim2.new(1, -16, 1, -33),
        ZIndex = 1,
        Parent = innerFrame
    })
    
    -- Вкладки
    local tabArea = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 25),
        ZIndex = 1,
        Parent = mainSection
    })
    
    -- Контейнер для контента вкладок
    local tabContainer = self:Create("Frame", {
        BackgroundColor3 = self.Colors.Main,
        BorderColor3 = self.Colors.Outline,
        Position = UDim2.new(0, 8, 0, 35),
        Size = UDim2.new(1, -16, 1, -43),
        ZIndex = 2,
        Parent = mainSection
    })
    
    -- Функции окна
    function window:SetTitle(title)
        if titleLabel then
            titleLabel.Text = title
        end
    end
    
    function window:AddTab(name)
        local tab = {
            Name = name,
            Groupboxes = {},
            Content = {}
        }
        
        table.insert(window.Tabs, tab)
        return tab
    end
    
    -- Сохраняем ссылки
    window.Holder = outerFrame
    window.MainSection = mainSection
    window.TabContainer = tabContainer
    
    -- Регистрируем цвета
    self:AddToRegistry(innerFrame, {
        BackgroundColor3 = "Colors.Main",
        BorderColor3 = "Colors.Accent"
    })
    
    self:AddToRegistry(mainSection, {
        BackgroundColor3 = "Colors.Background",
        BorderColor3 = "Colors.Outline"
    })
    
    self:AddToRegistry(tabContainer, {
        BackgroundColor3 = "Colors.Main",
        BorderColor3 = "Colors.Outline"
    })
    
    return window
end

-- Нотификации
function Library:Notify(message, duration)
    if not message then return end
    
    duration = duration or 5
    
    local textWidth, textHeight = self:GetTextBounds(message, self.Font, 14)
    if not textWidth or not textHeight then return end
    
    local padding = 10
    local notificationHeight = textHeight + padding
    
    -- Создаем уведомление
    local notification = self:Create("Frame", {
        BackgroundColor3 = self.Colors.Main,
        BorderColor3 = self.Colors.Outline,
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 0, 0, notificationHeight),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = self.ScreenGui
    })
    
    -- Текст уведомления
    local label = self:CreateLabel({
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -20, 1, -10),
        Text = message,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    -- Анимация появления
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local showTween = TweenService:Create(notification, tweenInfo, {
        Size = UDim2.new(0, textWidth + 20, 0, notificationHeight),
        Position = UDim2.new(1, -textWidth - 30, 0, 10)
    })
    
    showTween:Play()
    
    -- Автоматическое скрытие
    task.delay(duration, function()
        if notification and notification.Parent then
            local hideTween = TweenService:Create(notification, tweenInfo, {
                Size = UDim2.new(0, 0, 0, notificationHeight),
                Position = UDim2.new(1, -10, 0, 10)
            })
            
            hideTween:Play()
            
            hideTween.Completed:Wait()
            if notification and notification.Parent then
                notification:Destroy()
            end
        end
    end)
end

-- Безопасный вызов функций
function Library:SafeCallback(func, ...)
    if type(func) ~= "function" then
        return nil
    end
    
    local success, result = pcall(func, ...)
    
    if not success then
        if self.NotifyOnError then
            self:Notify("Ошибка: " .. tostring(result), 3)
        else
            warn("Callback ошибка:", result)
        end
        return nil
    end
    
    return result
end

-- Получение размеров текста (исправленная)
function Library:GetTextBounds(text, font, size, resolution)
    if not text or not font or not size then
        return 0, 0
    end
    
    -- Безопасный вызов GetTextSize
    local success, bounds = pcall(function()
        return TextService:GetTextSize(
            tostring(text), 
            tonumber(size) or 14, 
            font, 
            resolution or Vector2.new(1920, 1080)
        )
    end)
    
    if success and bounds then
        return math.max(10, bounds.X), math.max(10, bounds.Y)
    else
        -- Fallback значения
        return #text * (size / 2), size
    end
end

-- Проверка, находится ли мышь над открытым окном
function Library:MouseIsOverOpenedFrame()
    for frame in pairs(self.OpenedFrames) do
        if frame and frame:IsA("GuiObject") then
            local pos = frame.AbsolutePosition
            local size = frame.AbsoluteSize
            
            if Mouse.X >= pos.X and Mouse.X <= pos.X + size.X and
               Mouse.Y >= pos.Y and Mouse.Y <= pos.Y + size.Y then
                return true
            end
        end
    end
    
    return false
end

-- Вспомогательная функция для подключения сигналов
function Library:GiveSignal(signal)
    if signal and type(signal.Disconnect) == "function" then
        table.insert(self.Signals, signal)
    end
end

-- Очистка библиотеки
function Library:Unload()
    -- Отключаем все сигналы
    for i = #self.Signals, 1, -1 do
        local connection = table.remove(self.Signals, i)
        if connection and type(connection.Disconnect) == "function" then
            pcall(function() connection:Disconnect() end)
        end
    end
    
    -- Вызываем пользовательский коллбек
    if self.OnUnload then
        self:SafeCallback(self.OnUnload)
    end
    
    -- Очищаем реестры
    self.Registry = {}
    self.RegistryMap = {}
    self.HudRegistry = {}
    self.OpenedFrames = {}
    
    -- Удаляем GUI
    if self.ScreenGui and self.ScreenGui.Parent then
        self.ScreenGui:Destroy()
    end
end

-- Коллбек при выгрузке
function Library:OnUnload(callback)
    if type(callback) == "function" then
        self.OnUnload = callback
    end
end

-- Возвращаем библиотеку
getgenv().AllureLibrary = Library
return Library

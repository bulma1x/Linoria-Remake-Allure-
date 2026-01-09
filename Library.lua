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
    CurrentRainbowColor = Color3.fromHSV(0, 0.8, 1)
}

-- Утилиты для работы с цветом
function Library:GetDarkerColor(color)
    local h, s, v = Color3.toHSV(color)
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

-- Вспомогательные функции
function Library:Create(className, properties)
    local instance = Instance.new(className)
    
    for property, value in pairs(properties) do
        instance[property] = value
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
    return self:Create(label, properties)
end

-- Создание перетаскиваемого окна
function Library:MakeDraggable(frame, cutoff)
    frame.Active = true
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local offset = Vector2.new(
                Mouse.X - frame.AbsolutePosition.X,
                Mouse.Y - frame.AbsolutePosition.Y
            )
            
            -- Проверяем, находится ли клик в верхней части
            if offset.Y > (cutoff or 40) then
                return
            end
            
            -- Перетаскивание
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                frame.Position = UDim2.new(
                    0,
                    Mouse.X - offset.X + (frame.Size.X.Offset * frame.AnchorPoint.X),
                    0,
                    Mouse.Y - offset.Y + (frame.Size.Y.Offset * frame.AnchorPoint.Y)
                )
                
                RenderStepped:Wait()
            end
        end
    end)
end

-- Создание тултипа
function Library:AddToolTip(text, hoverInstance)
    local textWidth, textHeight = self:GetTextBounds(text, self.Font, 14)
    local tooltip = self:Create("Frame", {
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
    local index = #self.Registry + 1
    local data = {
        Instance = instance,
        Properties = properties,
        Index = index
    }
    
    table.insert(self.Registry, data)
    self.RegistryMap[instance] = data
    
    if isHud then
        table.insert(self.HudRegistry, data)
    end
end

function Library:RemoveFromRegistry(instance)
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
        titleLabel.Text = title
    end
    
    function window:AddTab(name)
        -- Здесь будет реализация добавления вкладки
        -- Возвращаем объект вкладки с методами для добавления элементов
        local tab = {
            Name = name,
            Groupboxes = {},
            Content = {}
        }
        
        -- Добавляем вкладку в окно
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
    duration = duration or 5
    
    local textWidth, textHeight = self:GetTextBounds(message, self.Font, 14)
    local padding = 10
    local notificationHeight = textHeight + padding
    
    -- Создаем уведомление
    local notification = self:Create("Frame", {
        BackgroundColor3 = self.Colors.Main,
        BorderColor3 = self.Colors.Outline,
        Position = UDim2.new(1, -textWidth - 20, 0, 10),
        Size = UDim2.new(0, 0, 0, notificationHeight),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = self.ScreenGui
    })
    
    -- Анимация появления
    self:Create("Tween", {
        Instance = notification,
        Properties = { Size = UDim2.new(0, textWidth + 20, 0, notificationHeight) },
        Duration = 0.3
    })
    
    -- Текст уведомления
    self:CreateLabel({
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -20, 1, -10),
        Text = message,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    -- Автоматическое скрытие
    task.delay(duration, function()
        if notification then
            self:Create("Tween", {
                Instance = notification,
                Properties = { Size = UDim2.new(0, 0, 0, notificationHeight) },
                Duration = 0.3
            })
            
            task.wait(0.3)
            notification:Destroy()
        end
    end)
end

-- Безопасный вызов функций
function Library:SafeCallback(func, ...)
    if type(func) ~= "function" then
        return
    end
    
    local success, result = pcall(func, ...)
    
    if not success and self.NotifyOnError then
        self:Notify(result, 3)
    end
    
    return result
end

-- Получение размеров текста
function Library:GetTextBounds(text, font, size, resolution)
    resolution = resolution or Vector2.new(1920, 1080)
    local bounds = TextService:GetTextSize(text, size, font, resolution)
    return bounds.X, bounds.Y
end

-- Проверка, находится ли мышь над открытым окном
function Library:MouseIsOverOpenedFrame()
    for frame in pairs(self.OpenedFrames) do
        local pos = frame.AbsolutePosition
        local size = frame.AbsoluteSize
        
        if Mouse.X >= pos.X and Mouse.X <= pos.X + size.X and
           Mouse.Y >= pos.Y and Mouse.Y <= pos.Y + size.Y then
            return true
        end
    end
    
    return false
end

-- Очистка библиотеки
function Library:Unload()
    -- Отключаем все сигналы
    for i = #self.Signals, 1, -1 do
        local connection = table.remove(self.Signals, i)
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Вызываем пользовательский коллбек
    if self.OnUnload then
        self:SafeCallback(self.OnUnload)
    end
    
    -- Удаляем GUI
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- Коллбек при выгрузке
function Library:OnUnload(callback)
    self.OnUnload = callback
end

-- Автоматическая очистка реестра при удалении элементов
self:AddToRegistry(ScreenGui, {})

-- Возвращаем библиотеку
getgenv().AllureLibrary = Library
return Library

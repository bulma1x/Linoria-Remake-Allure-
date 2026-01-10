local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')

local Library = {
    Settings = {
        Theme = {
            Accent = Color3.fromRGB(152, 181, 255),
            Background = Color3.fromRGB(12, 13, 15),
            SectionIdx = Color3.fromRGB(18, 20, 26),
            Component = Color3.fromRGB(25, 27, 34),
            Text = Color3.fromRGB(240, 240, 240),
            TextDark = Color3.fromRGB(150, 150, 150)
        }
    }
}

-- Utility: Draggable
local function MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function Library.new(title)
    local self = setmetatable({}, {__index = Library})
    local March = Instance.new('ScreenGui', CoreGui)
    March.Name = "March_v2"
    self.GUI = March

    local Main = Instance.new('Frame', March)
    Main.Size = UDim2.fromOffset(580, 420); Main.Position = UDim2.fromScale(0.5, 0.5); Main.AnchorPoint = Vector2.new(0.5, 0.5); Main.BackgroundColor3 = Library.Settings.Theme.Background; Main.BorderSizePixel = 0
    MakeDraggable(Main); Instance.new('UICorner', Main).CornerRadius = UDim.new(0, 8)

    local Sidebar = Instance.new('Frame', Main); Sidebar.Size = UDim2.new(0, 150, 1, 0); Sidebar.BackgroundTransparency = 1
    local Title = Instance.new('TextLabel', Sidebar); Title.Size = UDim2.new(1, 0, 0, 50); Title.Text = title or "MARCH LIB"; Title.TextColor3 = Library.Settings.Theme.Accent; Title.Font = Enum.Font.GothamBold; Title.TextSize = 18; Title.BackgroundTransparency = 1

    local TabScroll = Instance.new('ScrollingFrame', Sidebar); TabScroll.Size = UDim2.new(1, 0, 1, -60); TabScroll.Position = UDim2.new(0, 0, 0, 50); TabScroll.BackgroundTransparency = 1; TabScroll.ScrollBarThickness = 0
    Instance.new('UIListLayout', TabScroll).Padding = UDim.new(0, 5)

    local ContentArea = Instance.new('Frame', Main); ContentArea.Position = UDim2.new(0, 160, 0, 10); ContentArea.Size = UDim2.new(1, -170, 1, -20); ContentArea.BackgroundTransparency = 1
    self.Main = Main; self.TabScroll = TabScroll; self.ContentArea = ContentArea
    return self
end

function Library:AddWatermark(text)
    local WaterFrame = Instance.new('Frame', self.GUI); WaterFrame.Position = UDim2.new(0, 20, 0, 20); WaterFrame.AutomaticSize = Enum.AutomaticSize.XY; WaterFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Instance.new('UIStroke', WaterFrame).Color = self.Settings.Theme.Accent; Instance.new('UICorner', WaterFrame).CornerRadius = UDim.new(0, 4)
    local Label = Instance.new('TextLabel', WaterFrame); Label.Size = UDim2.fromOffset(0, 24); Label.AutomaticSize = Enum.AutomaticSize.X; Label.Font = Enum.Font.Gotham; Label.TextSize = 13; Label.TextColor3 = Color3.new(1,1,1); Label.Text = " " .. text .. " "
    RunService.RenderStepped:Connect(function() Label.Text = string.format(" %s | %d FPS ", text, math.floor(1/RunService.RenderStepped:Wait())) end)
end

function Library:CreateTab(name)
    local TabBtn = Instance.new('TextButton', self.TabScroll); TabBtn.Size = UDim2.new(1, -10, 0, 32); TabBtn.BackgroundColor3 = Library.Settings.Theme.SectionIdx; TabBtn.Text = name; TabBtn.TextColor3 = Library.Settings.Theme.TextDark; TabBtn.Font = Enum.Font.Gotham; TabBtn.TextSize = 13; Instance.new('UICorner', TabBtn).CornerRadius = UDim.new(0, 6)
    local TabPage = Instance.new('ScrollingFrame', self.ContentArea); TabPage.Size = UDim2.new(1, 0, 1, 0); TabPage.Visible = false; TabPage.BackgroundTransparency = 1; TabPage.ScrollBarThickness = 0
    Instance.new('UIListLayout', TabPage).Padding = UDim.new(0, 10)

    TabBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(self.ContentArea:GetChildren()) do v.Visible = false end
        for _, v in pairs(self.TabScroll:GetChildren()) do if v:IsA("TextButton") then v.TextColor3 = Library.Settings.Theme.TextDark end end
        TabPage.Visible = true; TabBtn.TextColor3 = Library.Settings.Theme.Accent
    end)

    local TabManager = {}
    function TabManager:AddSection(text)
        local SectionFrame = Instance.new('Frame', TabPage); SectionFrame.Size = UDim2.new(1, -5, 0, 0); SectionFrame.AutomaticSize = Enum.AutomaticSize.Y; SectionFrame.BackgroundColor3 = Library.Settings.Theme.SectionIdx; Instance.new('UICorner', SectionFrame).CornerRadius = UDim.new(0, 6)
        local Title = Instance.new('TextLabel', SectionFrame); Title.Size = UDim2.new(1, 0, 0, 28); Title.Position = UDim2.new(0, 10, 0, 0); Title.Text = text:upper(); Title.TextColor3 = Library.Settings.Theme.Accent; Title.Font = Enum.Font.GothamBold; Title.TextSize = 11; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.BackgroundTransparency = 1
        local Container = Instance.new('Frame', SectionFrame); Container.Position = UDim2.new(0, 0, 0, 28); Container.Size = UDim2.new(1, 0, 0, 0); Container.AutomaticSize = Enum.AutomaticSize.Y; Container.BackgroundTransparency = 1
        Instance.new('UIListLayout', Container).Padding = UDim.new(0, 4); Instance.new('UIListLayout', Container).HorizontalAlignment = Enum.HorizontalAlignment.Center

        local SecManager = {}

        -- Label (Updating)
        function SecManager:AddLabel(text)
            local Label = Instance.new('TextLabel', Container)
            Label.Size = UDim2.new(0.94, 0, 0, 20); Label.BackgroundTransparency = 1
            Label.Text = "  " .. text; Label.TextColor3 = Library.Settings.Theme.TextDark
            Label.Font = Enum.Font.Gotham; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left
            
            return {
                SetText = function(new) Label.Text = "  " .. new end
            }
        end

        -- Input
        function SecManager:AddInput(text, placeholder, callback)
            local InpFrame = Instance.new('Frame', Container); InpFrame.Size = UDim2.new(0.94, 0, 0, 32); InpFrame.BackgroundTransparency = 1
            local Lbl = Instance.new('TextLabel', InpFrame); Lbl.Text = "  " .. text; Lbl.Size = UDim2.new(0.4, 0, 1, 0); Lbl.TextColor3 = Library.Settings.Theme.Text; Lbl.Font = Enum.Font.Gotham; Lbl.TextSize = 12; Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.BackgroundTransparency = 1
            local Box = Instance.new('TextBox', InpFrame); Box.Size = UDim2.new(0.5, 0, 0, 24); Box.Position = UDim2.new(1, -5, 0.5, -12); Box.AnchorPoint = Vector2.new(1, 0.5); Box.BackgroundColor3 = Library.Settings.Theme.Component; Box.Text = ""; Box.PlaceholderText = placeholder or "..."; Box.TextColor3 = Color3.new(1,1,1); Box.Font = Enum.Font.Gotham; Box.TextSize = 11; Instance.new('UICorner', Box).CornerRadius = UDim.new(0, 4)
            Box.FocusLost:Connect(function() callback(Box.Text) end)
        end

        function SecManager:AddDivider()
            local Div = Instance.new('Frame', Container); Div.Size = UDim2.new(1, 0, 0, 10); Div.BackgroundTransparency = 1
            local Line = Instance.new('Frame', Div); Line.Size = UDim2.new(0.9, 0, 0, 1); Line.Position = UDim2.new(0.5, 0, 0.5, 0); Line.AnchorPoint = Vector2.new(0.5, 0.5); Line.BackgroundColor3 = Color3.fromRGB(45, 45, 50); Line.BorderSizePixel = 0
        end

        function SecManager:AddButton(text, callback)
            local Btn = Instance.new('TextButton', Container); Btn.Size = UDim2.new(0.94, 0, 0, 28); Btn.BackgroundColor3 = Library.Settings.Theme.Component; Btn.Text = text; Btn.Font = Enum.Font.Gotham; Btn.TextColor3 = Library.Settings.Theme.Text; Btn.TextSize = 12; Instance.new('UICorner', Btn).CornerRadius = UDim.new(0, 4); Btn.MouseButton1Click:Connect(callback)
        end

        function SecManager:AddToggle(text, default, callback)
            local state = default or false
            local Tgl = Instance.new('TextButton', Container); Tgl.Size = UDim2.new(0.94, 0, 0, 30); Tgl.BackgroundTransparency = 1; Tgl.Text = "  " .. text; Tgl.Font = Enum.Font.Gotham; Tgl.TextColor3 = Library.Settings.Theme.Text; Tgl.TextSize = 12; Tgl.TextXAlignment = Enum.TextXAlignment.Left
            local Box = Instance.new('Frame', Tgl); Box.Size = UDim2.fromOffset(34, 18); Box.Position = UDim2.new(1, -40, 0.5, -9); Box.BackgroundColor3 = state and Library.Settings.Theme.Accent or Color3.fromRGB(40,40,40); Instance.new('UICorner', Box).CornerRadius = UDim.new(1, 0)
            local Dot = Instance.new('Frame', Box); Dot.Size = UDim2.fromOffset(14, 14); Dot.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7); Dot.BackgroundColor3 = Color3.new(1,1,1); Instance.new('UICorner', Dot).CornerRadius = UDim.new(1, 0)
            Tgl.MouseButton1Click:Connect(function()
                state = not state
                TweenService:Create(Box, TweenInfo.new(0.2), {BackgroundColor3 = state and Library.Settings.Theme.Accent or Color3.fromRGB(40,40,40)}):Play()
                TweenService:Create(Dot, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
                callback(state)
            end)
        end

        function SecManager:AddDropdown(text, options, multi, callback)
            local is_players = options == "players"
            local current_options = is_players and {} or options
            local isOpen = false
            local DropFrame = Instance.new('Frame', Container); DropFrame.Size = UDim2.new(0.94, 0, 0, 30); DropFrame.BackgroundColor3 = Library.Settings.Theme.Component; DropFrame.AutomaticSize = Enum.AutomaticSize.Y; Instance.new('UICorner', DropFrame).CornerRadius = UDim.new(0, 4)
            local MainBtn = Instance.new('TextButton', DropFrame); MainBtn.Size = UDim2.new(1, 0, 0, 30); MainBtn.BackgroundTransparency = 1; MainBtn.Text = "  " .. text .. " : ..."; MainBtn.TextColor3 = Library.Settings.Theme.Text; MainBtn.Font = Enum.Font.Gotham; MainBtn.TextSize = 12; MainBtn.TextXAlignment = Enum.TextXAlignment.Left
            local ItemHolder = Instance.new('Frame', DropFrame); ItemHolder.Position = UDim2.new(0, 0, 0, 30); ItemHolder.Size = UDim2.new(1, 0, 0, 0); ItemHolder.Visible = false; ItemHolder.BackgroundTransparency = 1; ItemHolder.AutomaticSize = Enum.AutomaticSize.Y
            Instance.new('UIListLayout', ItemHolder).Padding = UDim.new(0, 2)
            MainBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    for _, v in pairs(ItemHolder:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                    local list = is_players and (function() local p = {} for _, pl in pairs(Players:GetPlayers()) do table.insert(p, pl.Name) end return p end)() or current_options
                    for _, opt in pairs(list) do
                        local Item = Instance.new('TextButton', ItemHolder); Item.Size = UDim2.new(1, 0, 0, 25); Item.BackgroundTransparency = 0.95; Item.Text = opt; Item.TextColor3 = Library.Settings.Theme.TextDark; Item.Font = Enum.Font.Gotham; Item.TextSize = 11
                        Item.MouseButton1Click:Connect(function() MainBtn.Text = "  " .. text .. " : " .. opt; if not multi then isOpen = false; ItemHolder.Visible = false end; callback(opt) end)
                    end
                end
                ItemHolder.Visible = isOpen
            end)
        end

        return SecManager
    end
    return TabManager
end

return Library

-- ThemeManager.lua
local httpService = game:GetService('HttpService')

local ThemeManager = {}

do
    ThemeManager.Folder = 'AllureUISettings'
    
    ThemeManager.Library = nil
    
    -- Встроенные темы (добавлено много новых)
    ThemeManager.BuiltInThemes = {
        -- Основные темы
        ['Default'] = { 
            1, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') 
        },
        
        -- Темные темы
        ['Midnight'] = { 
            2, 
            httpService:JSONDecode('{"FontColor":"e0e0e0","MainColor":"0d0d0d","AccentColor":"8a2be2","BackgroundColor":"0a0a0a","OutlineColor":"1a1a1a"}') 
        },
        ['Dark Carbon'] = { 
            3, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"121212","AccentColor":"00bcd4","BackgroundColor":"0a0a0a","OutlineColor":"2a2a2a"}') 
        },
        ['Obsidian'] = { 
            4, 
            httpService:JSONDecode('{"FontColor":"cccccc","MainColor":"1a1a1a","AccentColor":"ff6b35","BackgroundColor":"101010","OutlineColor":"303030"}') 
        },
        
        -- Игровые темы
        ['Fortnite'] = { 
            5, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"2a2a3e","AccentColor":"00ccff","BackgroundColor":"1e1e2e","OutlineColor":"3a3a5e"}') 
        },
        ['Valorant'] = { 
            6, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0f1923","AccentColor":"ff4655","BackgroundColor":"0a141e","OutlineColor":"1e2a3a"}') 
        },
        ['CS2'] = { 
            7, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"f0b132","BackgroundColor":"141414","OutlineColor":"323232"}') 
        },
        ['Minecraft'] = { 
            8, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"2d2d2d","AccentColor":"55ff55","BackgroundColor":"1a1a1a","OutlineColor":"404040"}') 
        },
        
        -- Элегантные темы
        ['Royal Purple'] = { 
            9, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a1033","AccentColor":"9b59b6","BackgroundColor":"0f081f","OutlineColor":"2d2150"}') 
        },
        ['Emerald'] = { 
            10, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0d2b1e","AccentColor":"2ecc71","BackgroundColor":"081a12","OutlineColor":"1e4732"}') 
        },
        ['Sapphire'] = { 
            11, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0d1a33","AccentColor":"3498db","BackgroundColor":"081425","OutlineColor":"1e2d47"}') 
        },
        
        -- Неоновые темы
        ['Neon Pink'] = { 
            12, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a0d1a","AccentColor":"ff00ff","BackgroundColor":"0f080f","OutlineColor":"331a33"}') 
        },
        ['Cyberpunk'] = { 
            13, 
            httpService:JSONDecode('{"FontColor":"00ffff","MainColor":"1a1a2e","AccentColor":"ff00ff","BackgroundColor":"0f0f1f","OutlineColor":"2d2d4a"}') 
        },
        ['Synthwave'] = { 
            14, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a0d33","AccentColor":"ff0080","BackgroundColor":"0f081f","OutlineColor":"331a66"}') 
        },
        
        -- Природные темы
        ['Forest'] = { 
            15, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a331a","AccentColor":"4caf50","BackgroundColor":"0f1f0f","OutlineColor":"2d4a2d"}') 
        },
        ['Ocean'] = { 
            16, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0d3333","AccentColor":"00bcd4","BackgroundColor":"081f1f","OutlineColor":"1a4a4a"}') 
        },
        ['Sunset'] = { 
            17, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"33220d","AccentColor":"ff5722","BackgroundColor":"1f1508","OutlineColor":"4a331a"}') 
        },
        
        -- Специальные темы
        ['Rainbow'] = { 
            18, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') 
        },
        ['Matrix'] = { 
            19, 
            httpService:JSONDecode('{"FontColor":"00ff00","MainColor":"0a0a0a","AccentColor":"00ff00","BackgroundColor":"050505","OutlineColor":"1a1a1a"}') 
        },
        ['Halloween'] = { 
            20, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a0d0d","AccentColor":"ff9900","BackgroundColor":"0f0808","OutlineColor":"331a1a"}') 
        },
        
        -- Минималистичные темы
        ['Minimal White'] = { 
            21, 
            httpService:JSONDecode('{"FontColor":"333333","MainColor":"f0f0f0","AccentColor":"007acc","BackgroundColor":"e0e0e0","OutlineColor":"cccccc"}') 
        },
        ['Minimal Dark'] = { 
            22, 
            httpService:JSONDecode('{"FontColor":"e0e0e0","MainColor":"202020","AccentColor":"007acc","BackgroundColor":"181818","OutlineColor":"404040"}') 
        },
        
        -- Градиентные темы
        ['Purple Gradient'] = { 
            23, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1a0d33","AccentColor":"9c27b0","BackgroundColor":"0f081f","OutlineColor":"331a66"}') 
        },
        ['Blue Gradient'] = { 
            24, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0d1a33","AccentColor":"2196f3","BackgroundColor":"081425","OutlineColor":"1e2d47"}') 
        },
        
        -- Популярные бренды
        ['Discord'] = { 
            25, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"36393f","AccentColor":"7289da","BackgroundColor":"2f3136","OutlineColor":"40444b"}') 
        },
        ['Spotify'] = { 
            26, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"121212","AccentColor":"1db954","BackgroundColor":"0a0a0a","OutlineColor":"2a2a2a"}') 
        },
        ['YouTube'] = { 
            27, 
            httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"0f0f0f","AccentColor":"ff0000","BackgroundColor":"0a0a0a","OutlineColor":"2a2a2a"}') 
        },
    }

    -- Применение темы
    function ThemeManager:ApplyTheme(themeName)
        local customThemeData = self:GetCustomTheme(themeName)
        local data = customThemeData or self.BuiltInThemes[themeName]

        if not data then
            self.Library:Notify(string.format('Тема "%s" не найдена', themeName), 3)
            return
        end

        local scheme = customThemeData or data[2]
        
        -- Особые обработки для специальных тем
        if themeName == 'Rainbow' then
            self:SetupRainbowTheme()
            return
        end
        
        if themeName == 'Matrix' then
            self:SetupMatrixTheme()
            return
        end

        -- Применяем цвета из схемы
        for colorName, hexColor in pairs(scheme) do
            if colorName ~= 'RainbowEnabled' and colorName ~= 'MatrixEnabled' then
                self.Library[colorName] = Color3.fromHex(hexColor)
                
                if Options[colorName] then
                    Options[colorName]:SetValueRGB(Color3.fromHex(hexColor))
                end
            end
        end

        self:ThemeUpdate()
        self.Library:Notify(string.format('Тема "%s" применена', themeName))
    end

    -- Настройка радужной темы
    function ThemeManager:SetupRainbowTheme()
        if not self.RainbowConnection then
            self.RainbowConnection = self.Library.Signals[#self.Library.Signals]
            
            local function UpdateRainbowColors()
                self.Library.AccentColor = self.Library.CurrentRainbowColor
                self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
                self:ThemeUpdate()
            end
            
            -- Сохраняем оригинальные цвета для восстановления
            self.OriginalColors = {
                AccentColor = self.Library.AccentColor,
                AccentColorDark = self.Library.AccentColorDark
            }
            
            -- Обновляем цвета каждый кадр
            self.RainbowUpdate = RunService.RenderStepped:Connect(UpdateRainbowColors)
            table.insert(self.Library.Signals, self.RainbowUpdate)
            
            self.Library:Notify('Радужная тема включена!')
        end
    end

    -- Настройка Matrix темы
    function ThemeManager:SetupMatrixTheme()
        if not self.MatrixEffect then
            self.OriginalFont = self.Library.FontColor
            
            -- Анимация мерцания текста
            self.MatrixEffect = RunService.Heartbeat:Connect(function()
                local flicker = math.random(70, 100) / 100
                self.Library.FontColor = Color3.fromRGB(
                    math.floor(255 * flicker),
                    math.floor(255 * flicker),
                    math.floor(255 * flicker)
                )
                self:ThemeUpdate()
            end)
            
            table.insert(self.Library.Signals, self.MatrixEffect)
            self.Library:Notify('Matrix тема включена!')
        end
    end

    -- Отключение специальных эффектов
    function ThemeManager:DisableSpecialEffects()
        if self.RainbowUpdate then
            self.RainbowUpdate:Disconnect()
            self.RainbowUpdate = nil
            
            -- Восстанавливаем оригинальные цвета
            if self.OriginalColors then
                self.Library.AccentColor = self.OriginalColors.AccentColor
                self.Library.AccentColorDark = self.OriginalColors.AccentColorDark
            end
        end
        
        if self.MatrixEffect then
            self.MatrixEffect:Disconnect()
            self.MatrixEffect = nil
            
            -- Восстанавливаем оригинальный цвет шрифта
            if self.OriginalFont then
                self.Library.FontColor = self.OriginalFont
            end
        end
        
        self:ThemeUpdate()
    end

    -- Обновление темы
    function ThemeManager:ThemeUpdate()
        local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        
        for _, field in ipairs(options) do
            if Options and Options[field] then
                self.Library[field] = Options[field].Value
            end
        end

        self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
        self.Library:UpdateColorsUsingRegistry()
    end

    -- Загрузка темы по умолчанию
    function ThemeManager:LoadDefault()
        local theme = 'Default'
        
        if isfile(self.Folder .. '/themes/default.txt') then
            local content = readfile(self.Folder .. '/themes/default.txt')
            
            if self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme = content
            end
        end

        Options.ThemeManager_ThemeList:SetValue(theme)
        self:ApplyTheme(theme)
    end

    -- Сохранение темы по умолчанию
    function ThemeManager:SaveDefault(themeName)
        writefile(self.Folder .. '/themes/default.txt', themeName)
        self.Library:Notify(string.format('Тема "%s" установлена по умолчанию', themeName))
    end

    -- Создание менеджера тем
    function ThemeManager:CreateThemeManager(groupbox)
        -- Раздел основных цветов
        groupbox:AddLabel('Основные цвета'):AddColorPicker('BackgroundColor', { 
            Default = self.Library.BackgroundColor,
            Title = 'Цвет фона'
        })
        
        groupbox:AddLabel(''):AddColorPicker('MainColor', { 
            Default = self.Library.MainColor,
            Title = 'Основной цвет'
        })
        
        groupbox:AddLabel(''):AddColorPicker('AccentColor', { 
            Default = self.Library.AccentColor,
            Title = 'Акцентный цвет'
        })
        
        groupbox:AddLabel(''):AddColorPicker('OutlineColor', { 
            Default = self.Library.OutlineColor,
            Title = 'Цвет обводки'
        })
        
        groupbox:AddLabel(''):AddColorPicker('FontColor', { 
            Default = self.Library.FontColor,
            Title = 'Цвет текста'
        })

        groupbox:AddDivider()
        
        -- Раздел встроенных тем
        groupbox:AddLabel('Встроенные темы')
        
        local themesArray = {}
        for themeName, themeData in pairs(self.BuiltInThemes) do
            table.insert(themesArray, themeName)
        end
        
        table.sort(themesArray, function(a, b) 
            return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] 
        end)

        local themeDropdown = groupbox:AddDropdown('ThemeManager_ThemeList', {
            Text = 'Выбор темы',
            Values = themesArray,
            Default = 1,
            Tooltip = 'Выберите одну из встроенных тем'
        })

        groupbox:AddButton('Применить тему', function()
            self:DisableSpecialEffects()
            self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
        end)

        groupbox:AddButton('Установить как тему по умолчанию', function()
            self:SaveDefault(Options.ThemeManager_ThemeList.Value)
        end)

        groupbox:AddDivider()
        
        -- Раздел кастомных тем
        groupbox:AddLabel('Пользовательские темы')
        
        groupbox:AddInput('ThemeManager_CustomThemeName', {
            Text = 'Название темы',
            Placeholder = 'Введите название...',
            Tooltip = 'Название для сохранения текущей темы'
        })
        
        local customThemeDropdown = groupbox:AddDropdown('ThemeManager_CustomThemeList', {
            Text = 'Сохраненные темы',
            Values = self:ReloadCustomThemes(),
            AllowNull = true,
            Tooltip = 'Выберите сохраненную пользовательскую тему'
        })
        
        groupbox:AddDivider()
        
        -- Кнопки управления кастомными темами
        local buttonRow = groupbox:AddButton({
            Text = 'Сохранить тему',
            Func = function()
                local themeName = Options.ThemeManager_CustomThemeName.Value
                if themeName and themeName ~= '' then
                    self:SaveCustomTheme(themeName)
                    customThemeDropdown:SetValues(self:ReloadCustomThemes())
                    Options.ThemeManager_CustomThemeName:SetValue('')
                else
                    self.Library:Notify('Введите название темы!', 3)
                end
            end,
            Tooltip = 'Сохранить текущие цвета как пользовательскую тему'
        })
        
        buttonRow:AddButton({
            Text = 'Загрузить тему',
            Func = function()
                if Options.ThemeManager_CustomThemeList.Value then
                    self:DisableSpecialEffects()
                    self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value)
                end
            end,
            Tooltip = 'Загрузить выбранную пользовательскую тему'
        })
        
        buttonRow:AddButton({
            Text = 'Удалить тему',
            Func = function()
                if Options.ThemeManager_CustomThemeList.Value then
                    self:DeleteCustomTheme(Options.ThemeManager_CustomThemeList.Value)
                    customThemeDropdown:SetValues(self:ReloadCustomThemes())
                    customThemeDropdown:SetValue(nil)
                end
            end,
            Tooltip = 'Удалить выбранную пользовательскую тему'
        })

        groupbox:AddDivider()
        
        -- Специальные темы
        groupbox:AddLabel('Специальные темы')
        
        local specialThemesButton = groupbox:AddButton({
            Text = '🌈 Радужная тема',
            Func = function()
                self:DisableSpecialEffects()
                self:ApplyTheme('Rainbow')
            end,
            Tooltip = 'Включить динамическую радужную тему'
        })
        
        specialThemesButton:AddButton({
            Text = '💾 Сохранить текущую',
            Func = function()
                self:DisableSpecialEffects()
                self:SaveCustomTheme('Rainbow_Saved')
                customThemeDropdown:SetValues(self:ReloadCustomThemes())
            end,
            Tooltip = 'Сохранить текущую радужную тему'
        })
        
        groupbox:AddButton({
            Text = '📟 Matrix тема',
            Func = function()
                self:DisableSpecialEffects()
                self:ApplyTheme('Matrix')
            end,
            Tooltip = 'Включить Matrix-стиль'
        })

        groupbox:AddDivider()
        
        -- Кнопки сброса
        groupbox:AddButton({
            Text = '🔄 Обновить список',
            Func = function()
                customThemeDropdown:SetValues(self:ReloadCustomThemes())
            end,
            Tooltip = 'Обновить список пользовательских тем'
        })
        
        groupbox:AddButton({
            Text = '⚡ Сбросить эффекты',
            Func = function()
                self:DisableSpecialEffects()
                self:ThemeUpdate()
                self.Library:Notify('Специальные эффекты отключены')
            end,
            Tooltip = 'Отключить все специальные эффекты'
        })
        
        groupbox:AddButton({
            Text = '💾 Сброс к Default',
            Func = function()
                self:DisableSpecialEffects()
                self:ApplyTheme('Default')
            end,
            Tooltip = 'Вернуться к теме по умолчанию'
        })

        -- События изменения цветов
        local function UpdateTheme()
            self:DisableSpecialEffects()
            self:ThemeUpdate()
        end

        Options.BackgroundColor:OnChanged(UpdateTheme)
        Options.MainColor:OnChanged(UpdateTheme)
        Options.AccentColor:OnChanged(UpdateTheme)
        Options.OutlineColor:OnChanged(UpdateTheme)
        Options.FontColor:OnChanged(UpdateTheme)
        
        -- Загрузка темы по умолчанию
        self:LoadDefault()
    end

    -- Получение кастомной темы
    function ThemeManager:GetCustomTheme(fileName)
        local path = self.Folder .. '/themes/' .. fileName .. '.json'
        
        if not isfile(path) then
            return nil
        end

        local data = readfile(path)
        local success, decoded = pcall(httpService.JSONDecode, httpService, data)
        
        if not success then
            self.Library:Notify('Ошибка загрузки темы: ' .. fileName, 3)
            return nil
        end

        return decoded
    end

    -- Сохранение кастомной темы
    function ThemeManager:SaveCustomTheme(fileName)
        if fileName:gsub(' ', '') == '' then
            self.Library:Notify('Некорректное название темы', 3)
            return
        end

        local theme = {}
        local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

        for _, field in ipairs(fields) do
            theme[field] = Options[field].Value:ToHex()
        end

        local filePath = self.Folder .. '/themes/' .. fileName .. '.json'
        writefile(filePath, httpService:JSONEncode(theme))
        
        self.Library:Notify(string.format('Тема "%s" сохранена', fileName))
    end

    -- Удаление кастомной темы
    function ThemeManager:DeleteCustomTheme(fileName)
        local path = self.Folder .. '/themes/' .. fileName .. '.json'
        
        if isfile(path) then
            delfile(path)
            self.Library:Notify(string.format('Тема "%s" удалена', fileName))
        end
    end

    -- Обновление списка кастомных тем
    function ThemeManager:ReloadCustomThemes()
        if not isfolder(self.Folder .. '/themes') then
            return {}
        end

        local themesList = listfiles(self.Folder .. '/themes')
        local customThemes = {}

        for _, filePath in ipairs(themesList) do
            if filePath:sub(-5) == '.json' then
                local fileName = filePath:match("([^/\\]+)%.json$")
                if fileName then
                    table.insert(customThemes, fileName)
                end
            end
        end

        table.sort(customThemes)
        return customThemes
    end

    -- Установка библиотеки
    function ThemeManager:SetLibrary(lib)
        self.Library = lib
    end

    -- Создание структуры папок
    function ThemeManager:BuildFolderTree()
        local folders = {
            self.Folder,
            self.Folder .. '/themes',
            self.Folder .. '/settings',
            self.Folder .. '/configs'
        }

        for _, folder in ipairs(folders) do
            if not isfolder(folder) then
                makefolder(folder)
            end
        end
    end

    -- Применение к вкладке
    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, 'Сначала установите ThemeManager.Library!')
        
        local groupbox = tab:AddLeftGroupbox('🎨 Настройки тем')
        groupbox:AddLabel('Настройте внешний вид интерфейса', true)
        groupbox:AddDivider()
        
        self:CreateThemeManager(groupbox)
    end

    -- Применение к группе
    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, 'Сначала установите ThemeManager.Library!')
        self:CreateThemeManager(groupbox)
    end

    -- Установка папки
    function ThemeManager:SetFolder(folderName)
        self.Folder = folderName
        self:BuildFolderTree()
    end

    -- Инициализация
    ThemeManager:BuildFolderTree()
end

return ThemeManager
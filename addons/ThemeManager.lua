-- ThemeManager.lua
local RunService = game:GetService('RunService')
local httpService = game:GetService('HttpService')

local ThemeManager = {}

do
    ThemeManager.Folder = 'AllureUISettings'
    ThemeManager.Library = nil
    
    -- Встроенные темы
    ThemeManager.BuiltInThemes = {
        ['Default'] = {
            FontColor = Color3.fromHex('ffffff'),
            MainColor = Color3.fromHex('1c1c1c'),
            AccentColor = Color3.fromHex('0055ff'),
            BackgroundColor = Color3.fromHex('141414'),
            OutlineColor = Color3.fromHex('323232')
        },
        ['Midnight'] = {
            FontColor = Color3.fromHex('e0e0e0'),
            MainColor = Color3.fromHex('0d0d0d'),
            AccentColor = Color3.fromHex('8a2be2'),
            BackgroundColor = Color3.fromHex('0a0a0a'),
            OutlineColor = Color3.fromHex('1a1a1a')
        },
        ['Dark Carbon'] = {
            FontColor = Color3.fromHex('ffffff'),
            MainColor = Color3.fromHex('121212'),
            AccentColor = Color3.fromHex('00bcd4'),
            BackgroundColor = Color3.fromHex('0a0a0a'),
            OutlineColor = Color3.fromHex('2a2a2a')
        },
        ['Obsidian'] = {
            FontColor = Color3.fromHex('cccccc'),
            MainColor = Color3.fromHex('1a1a1a'),
            AccentColor = Color3.fromHex('ff6b35'),
            BackgroundColor = Color3.fromHex('101010'),
            OutlineColor = Color3.fromHex('303030')
        }
    }

    -- Безопасный метод для установки события изменения
    local function SafeOnChanged(option, callback)
        if option and option.OnChanged and type(option.OnChanged) == "function" then
            option:OnChanged(callback)
            return true
        elseif option and option.Callback then
            local originalCallback = option.Callback
            option.Callback = function(value)
                if originalCallback then
                    originalCallback(value)
                end
                callback(value)
            end
            return true
        elseif option then
            -- Если ничего не работает, просто сохраняем callback
            option._onChangedCallback = callback
            return true
        end
        return false
    end

    -- Применение темы
    function ThemeManager:ApplyTheme(themeName)
        local customThemeData = self:GetCustomTheme(themeName)
        local builtInTheme = self.BuiltInThemes[themeName]

        if not customThemeData and not builtInTheme then
            if self.Library and self.Library.Notify then
                self.Library:Notify(string.format('Тема "%s" не найдена', themeName), 3)
            end
            return
        end

        local scheme = customThemeData or builtInTheme
        
        -- Применяем цвета из схемы
        for colorName, colorValue in pairs(scheme) do
            if colorName == "FontColor" or colorName == "MainColor" or 
               colorName == "AccentColor" or colorName == "BackgroundColor" or 
               colorName == "OutlineColor" then
                
                if self.Library then
                    self.Library[colorName] = colorValue
                end
                
                if Options and Options[colorName] then
                    if Options[colorName].SetValue then
                        Options[colorName]:SetValue(colorValue)
                    elseif Options[colorName].SetValueRGB then
                        Options[colorName]:SetValueRGB(colorValue)
                    elseif Options[colorName].Value ~= nil then
                        Options[colorName].Value = colorValue
                    end
                end
            end
        end

        self:ThemeUpdate()
        if self.Library and self.Library.Notify then
            self.Library:Notify(string.format('Тема "%s" применена', themeName))
        end
    end

    -- Обновление темы
    function ThemeManager:ThemeUpdate()
        if not self.Library then return end
        
        local colorFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        
        for _, field in ipairs(colorFields) do
            if Options and Options[field] and Options[field].Value then
                self.Library[field] = Options[field].Value
            end
        end

        -- Обновляем более темный акцентный цвет
        if self.Library.GetDarkerColor and self.Library.AccentColor then
            self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
        end
        
        -- Обновляем цвета через реестр если есть такой метод
        if self.Library.UpdateColorsUsingRegistry then
            self.Library:UpdateColorsUsingRegistry()
        end
    end

    -- Загрузка темы по умолчанию
    function ThemeManager:LoadDefault()
        local theme = 'Default'
        
        if isfile and isfile(self.Folder .. '/themes/default.txt') then
            local content = readfile(self.Folder .. '/themes/default.txt')
            
            if self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme = content
            end
        end

        if Options and Options.ThemeManager_ThemeList and Options.ThemeManager_ThemeList.SetValue then
            Options.ThemeManager_ThemeList:SetValue(theme)
        end
        self:ApplyTheme(theme)
    end

    -- Сохранение темы по умолчанию
    function ThemeManager:SaveDefault(themeName)
        if writefile then
            writefile(self.Folder .. '/themes/default.txt', themeName)
            if self.Library and self.Library.Notify then
                self.Library:Notify(string.format('Тема "%s" установлена по умолчанию', themeName))
            end
        end
    end

    -- Создание менеджера тем
    function ThemeManager:CreateThemeManager(groupbox)
        -- Раздел основных цветов
        local bgLabel = groupbox:AddLabel('Цвет фона')
        local bgColorPicker = bgLabel:AddColorPicker('BackgroundColor', { 
            Default = self.Library and self.Library.BackgroundColor or Color3.fromRGB(20, 20, 20),
            Title = 'Цвет фона'
        })
        
        local mainLabel = groupbox:AddLabel('Основной цвет')
        local mainColorPicker = mainLabel:AddColorPicker('MainColor', { 
            Default = self.Library and self.Library.MainColor or Color3.fromRGB(28, 28, 28),
            Title = 'Основной цвет'
        })
        
        local accentLabel = groupbox:AddLabel('Акцентный цвет')
        local accentColorPicker = accentLabel:AddColorPicker('AccentColor', { 
            Default = self.Library and self.Library.AccentColor or Color3.fromRGB(0, 85, 255),
            Title = 'Акцентный цвет'
        })
        
        local outlineLabel = groupbox:AddLabel('Цвет обводки')
        local outlineColorPicker = outlineLabel:AddColorPicker('OutlineColor', { 
            Default = self.Library and self.Library.OutlineColor or Color3.fromRGB(50, 50, 50),
            Title = 'Цвет обводки'
        })
        
        local fontLabel = groupbox:AddLabel('Цвет текста')
        local fontColorPicker = fontLabel:AddColorPicker('FontColor', { 
            Default = self.Library and self.Library.FontColor or Color3.fromRGB(255, 255, 255),
            Title = 'Цвет текста'
        })

        groupbox:AddDivider()
        
        -- Раздел встроенных тем
        groupbox:AddLabel('Встроенные темы')
        
        local themesArray = {}
        for themeName, _ in pairs(self.BuiltInThemes) do
            table.insert(themesArray, themeName)
        end
        
        table.sort(themesArray)

        local themeDropdown = groupbox:AddDropdown('ThemeManager_ThemeList', {
            Text = 'Выбор темы',
            Values = themesArray,
            Default = 1,
            Tooltip = 'Выберите одну из встроенных тем'
        })

        groupbox:AddButton('Применить тему', function()
            if Options and Options.ThemeManager_ThemeList and Options.ThemeManager_ThemeList.Value then
                self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
            end
        })

        groupbox:AddButton('Установить как тему по умолчанию', function()
            if Options and Options.ThemeManager_ThemeList and Options.ThemeManager_ThemeList.Value then
                self:SaveDefault(Options.ThemeManager_ThemeList.Value)
            end
        })

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
                if Options and Options.ThemeManager_CustomThemeName and Options.ThemeManager_CustomThemeName.Value then
                    local themeName = Options.ThemeManager_CustomThemeName.Value
                    if themeName and themeName ~= '' then
                        self:SaveCustomTheme(themeName)
                        if customThemeDropdown and customThemeDropdown.SetValues then
                            customThemeDropdown:SetValues(self:ReloadCustomThemes())
                        end
                        if Options.ThemeManager_CustomThemeName and Options.ThemeManager_CustomThemeName.SetValue then
                            Options.ThemeManager_CustomThemeName:SetValue('')
                        end
                    else
                        if self.Library and self.Library.Notify then
                            self.Library:Notify('Введите название темы!', 3)
                        end
                    end
                end
            end,
            Tooltip = 'Сохранить текущие цвета как пользовательскую тему'
        })
        
        buttonRow:AddButton({
            Text = 'Загрузить тему',
            Func = function()
                if Options and Options.ThemeManager_CustomThemeList and Options.ThemeManager_CustomThemeList.Value then
                    self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value)
                end
            end,
            Tooltip = 'Загрузить выбранную пользовательскую тему'
        })
        
        buttonRow:AddButton({
            Text = 'Удалить тему',
            Func = function()
                if Options and Options.ThemeManager_CustomThemeList and Options.ThemeManager_CustomThemeList.Value then
                    self:DeleteCustomTheme(Options.ThemeManager_CustomThemeList.Value)
                    if customThemeDropdown and customThemeDropdown.SetValues then
                        customThemeDropdown:SetValues(self:ReloadCustomThemes())
                    end
                    if customThemeDropdown and customThemeDropdown.SetValue then
                        customThemeDropdown:SetValue(nil)
                    end
                end
            end,
            Tooltip = 'Удалить выбранную пользовательскую тему'
        })

        groupbox:AddDivider()
        
        -- Сброс
        groupbox:AddButton({
            Text = '🔄 Обновить список',
            Func = function()
                if customThemeDropdown and customThemeDropdown.SetValues then
                    customThemeDropdown:SetValues(self:ReloadCustomThemes())
                end
            end,
            Tooltip = 'Обновить список пользовательских тем'
        })
        
        groupbox:AddButton({
            Text = '💾 Сброс к Default',
            Func = function()
                self:ApplyTheme('Default')
            end,
            Tooltip = 'Вернуться к теме по умолчанию'
        })

        -- События изменения цветов с безопасной проверкой
        local function UpdateTheme()
            self:ThemeUpdate()
        end

        -- Безопасное подключение событий
        if Options then
            SafeOnChanged(Options.BackgroundColor, UpdateTheme)
            SafeOnChanged(Options.MainColor, UpdateTheme)
            SafeOnChanged(Options.AccentColor, UpdateTheme)
            SafeOnChanged(Options.OutlineColor, UpdateTheme)
            SafeOnChanged(Options.FontColor, UpdateTheme)
        end
        
        -- Загрузка темы по умолчанию
        self:LoadDefault()
    end

    -- Получение кастомной темы
    function ThemeManager:GetCustomTheme(fileName)
        if not isfile then return nil end
        
        local path = self.Folder .. '/themes/' .. fileName .. '.json'
        
        if not isfile(path) then
            return nil
        end

        local data = readfile(path)
        local success, decoded = pcall(httpService.JSONDecode, httpService, data)
        
        if not success then
            if self.Library and self.Library.Notify then
                self.Library:Notify('Ошибка загрузки темы: ' .. fileName, 3)
            end
            return nil
        end

        -- Конвертируем hex в Color3
        local theme = {}
        local colorFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        
        for _, field in ipairs(colorFields) do
            if decoded[field] then
                theme[field] = Color3.fromHex(decoded[field])
            end
        end

        return theme
    end

    -- Сохранение кастомной темы
    function ThemeManager:SaveCustomTheme(fileName)
        if fileName:gsub(' ', '') == '' then
            if self.Library and self.Library.Notify then
                self.Library:Notify('Некорректное название темы', 3)
            end
            return
        end

        if not Options or not writefile then return end

        local theme = {}
        local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

        for _, field in ipairs(fields) do
            if Options[field] and Options[field].Value and Options[field].Value.ToHex then
                theme[field] = Options[field].Value:ToHex()
            end
        end

        local filePath = self.Folder .. '/themes/' .. fileName .. '.json'
        writefile(filePath, httpService:JSONEncode(theme))
        
        if self.Library and self.Library.Notify then
            self.Library:Notify(string.format('Тема "%s" сохранена', fileName))
        end
    end

    -- Удаление кастомной темы
    function ThemeManager:DeleteCustomTheme(fileName)
        if not isfile or not delfile then return end
        
        local path = self.Folder .. '/themes/' .. fileName .. '.json'
        
        if isfile(path) then
            delfile(path)
            if self.Library and self.Library.Notify then
                self.Library:Notify(string.format('Тема "%s" удалена', fileName))
            end
        end
    end

    -- Обновление списка кастомных тем
    function ThemeManager:ReloadCustomThemes()
        if not isfolder then return {} end
        
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
        if not makefolder or not isfolder then return end
        
        local folders = {
            self.Folder,
            self.Folder .. '/themes'
        }

        for _, folder in ipairs(folders) do
            if not isfolder(folder) then
                makefolder(folder)
            end
        end
    end

    -- Применение к вкладке
    function ThemeManager:ApplyToTab(tab)
        if not self.Library then
            warn('ThemeManager: Сначала установите ThemeManager.Library!')
            return
        end
        
        if not tab or not tab.AddLeftGroupbox then
            warn('ThemeManager: Некорректная вкладка!')
            return
        end
        
        local groupbox = tab:AddLeftGroupbox('🎨 Настройки тем')
        groupbox:AddLabel('Настройте внешний вид интерфейса', true)
        groupbox:AddDivider()
        
        self:CreateThemeManager(groupbox)
    end

    -- Применение к группе
    function ThemeManager:ApplyToGroupbox(groupbox)
        if not self.Library then
            warn('ThemeManager: Сначала установите ThemeManager.Library!')
            return
        end
        self:CreateThemeManager(groupbox)
    end

    -- Установка папки
    function ThemeManager:SetFolder(folderName)
        self.Folder = folderName
        self:BuildFolderTree()
    end

    -- Игнорирование настроек тем в SaveManager
    function ThemeManager:IgnoreThemeSettings()
        -- Пустая функция для совместимости с SaveManager
    end

    -- Инициализация
    ThemeManager:BuildFolderTree()
end

return ThemeManager

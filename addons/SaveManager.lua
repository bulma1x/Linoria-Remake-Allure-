-- SaveManager.lua
local httpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')

local SaveManager = {}

do
    SaveManager.Folder = 'AllureUISettings'
    SaveManager.Ignore = {}
    SaveManager.BackupsFolder = 'backups'
    SaveManager.MaxBackups = 5
    
    -- Расширенный парсер для всех типов элементов
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object)
                return {
                    type = 'Toggle',
                    idx = idx,
                    value = object.Value,
                    risky = object.Risky or false
                }
            end,
            Load = function(idx, data)
                if Toggles and Toggles[idx] then
                    if Toggles[idx].SetValue then
                        Toggles[idx]:SetValue(data.value)
                    elseif Toggles[idx].Value ~= nil then
                        Toggles[idx].Value = data.value
                    end
                    if data.risky ~= nil then
                        -- Можно сохранить состояние risky, если нужно
                    end
                end
            end,
        },
        
        Slider = {
            Save = function(idx, object)
                return {
                    type = 'Slider',
                    idx = idx,
                    value = object.Value,
                    min = object.Min,
                    max = object.Max,
                    rounding = object.Rounding,
                    suffix = object.Suffix or ''
                }
            end,
            Load = function(idx, data)
                if Options and Options[idx] then
                    if Options[idx].SetValue then
                        Options[idx]:SetValue(data.value)
                    elseif Options[idx].Value ~= nil then
                        Options[idx].Value = data.value
                    end
                end
            end,
        },
        
        Dropdown = {
            Save = function(idx, object)
                local value
                if object.Multi then
                    value = {}
                    for k, v in pairs(object.Value) do
                        if v then
                            table.insert(value, k)
                        end
                    end
                else
                    value = object.Value
                end
                
                return {
                    type = 'Dropdown',
                    idx = idx,
                    value = value,
                    multi = object.Multi,
                    specialType = object.SpecialType
                }
            end,
            Load = function(idx, data)
                if Options and Options[idx] then
                    if Options[idx].SetValue then
                        if data.multi then
                            local multiValue = {}
                            for _, item in ipairs(data.value) do
                                multiValue[item] = true
                            end
                            Options[idx]:SetValue(multiValue)
                        else
                            Options[idx]:SetValue(data.value)
                        end
                    elseif Options[idx].Value ~= nil then
                        Options[idx].Value = data.value
                    end
                end
            end,
        },
        
        ColorPicker = {
            Save = function(idx, object)
                local hexValue = "FFFFFF"
                if object.Value and object.Value.ToHex then
                    local success, result = pcall(function()
                        return object.Value:ToHex()
                    end)
                    if success then
                        hexValue = result
                    end
                end
                
                return {
                    type = 'ColorPicker',
                    idx = idx,
                    value = hexValue,
                    transparency = object.Transparency or 0
                }
            end,
            Load = function(idx, data)
                if Options and Options[idx] then
                    local color = Color3.fromHex(data.value)
                    if Options[idx].SetValueRGB then
                        Options[idx]:SetValueRGB(color, data.transparency or 0)
                    elseif Options[idx].SetValue then
                        Options[idx]:SetValue(color)
                    elseif Options[idx].Value ~= nil then
                        Options[idx].Value = color
                        Options[idx].Transparency = data.transparency or 0
                    end
                end
            end,
        },
        
        KeyPicker = {
            Save = function(idx, object)
                return {
                    type = 'KeyPicker',
                    idx = idx,
                    key = object.Value or "RightControl",
                    mode = object.Mode or "Toggle",
                    syncToggle = object.SyncToggleState or false
                }
            end,
            Load = function(idx, data)
                if Options and Options[idx] then
                    if Options[idx].SetValue then
                        Options[idx]:SetValue({data.key, data.mode})
                    elseif Options[idx].Value ~= nil then
                        Options[idx].Value = data.key
                        Options[idx].Mode = data.mode
                    end
                end
            end,
        },
        
        Input = {
            Save = function(idx, object)
                return {
                    type = 'Input',
                    idx = idx,
                    value = object.Value or "",
                    numeric = object.Numeric or false
                }
            end,
            Load = function(idx, data)
                if Options and Options[idx] then
                    if Options[idx].SetValue then
                        Options[idx]:SetValue(data.value)
                    elseif Options[idx].Value ~= nil then
                        Options[idx].Value = data.value
                    end
                end
            end,
        },
    }
    
    -- Игнорирование определенных индексов
    function SaveManager:SetIgnoreIndexes(list)
        self.Ignore = {}
        for _, key in ipairs(list) do
            self.Ignore[key] = true
        end
    end
    
    -- Установка папки для сохранения
    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end
    
    -- Создание резервной копии
    function SaveManager:CreateBackup(configName)
        if not configName then return false end
        
        local configPath = self.Folder .. '/settings/' .. configName .. '.json'
        if not isfile or not isfile(configPath) then return false end
        
        local backupPath = self.Folder .. '/backups/' .. configName .. '_' .. os.time() .. '.json'
        
        local content = readfile(configPath)
        writefile(backupPath, content)
        
        -- Ограничиваем количество резервных копий
        self:CleanupBackups(configName)
        
        return true
    end
    
    -- Очистка старых резервных копий
    function SaveManager:CleanupBackups(configName)
        if not listfiles then return end
        
        local backups = self:GetBackupList(configName)
        
        while #backups > self.MaxBackups do
            local oldest = table.remove(backups, 1)
            if delfile then
                delfile(self.Folder .. '/backups/' .. oldest)
            end
        end
    end
    
    -- Получение списка резервных копий
    function SaveManager:GetBackupList(configName)
        if not listfiles then return {} end
        
        local list = listfiles(self.Folder .. '/backups')
        local backups = {}
        
        for _, file in ipairs(list) do
            if file:match(configName .. '_.+%.json$') then
                table.insert(backups, file:match('([^/\\]+)$'))
            end
        end
        
        table.sort(backups)
        return backups
    end
    
    -- Сохранение конфигурации
    function SaveManager:Save(configName, createBackup)
        if not configName or configName:gsub(' ', '') == '' then
            return false, 'Имя конфигурации не может быть пустым'
        end
        
        -- Проверяем доступность файловых функций
        if not writefile or not isfile then
            return false, 'Файловые функции не доступны'
        end
        
        local fullPath = self.Folder .. '/settings/' .. configName .. '.json'
        
        -- Создаем резервную копию если требуется
        if createBackup and isfile(fullPath) then
            self:CreateBackup(configName)
        end
        
        local data = {
            objects = {},
            metadata = {
                created = os.time(),
                version = '1.0',
                game = game.PlaceId,
                script = 'Allure UI'
            }
        }
        
        -- Сохраняем тогглы
        if Toggles then
            for idx, toggle in pairs(Toggles) do
                if self.Ignore[idx] then continue end
                if toggle.Type and self.Parser[toggle.Type] then
                    local success, result = pcall(function()
                        return self.Parser[toggle.Type].Save(idx, toggle)
                    end)
                    if success then
                        table.insert(data.objects, result)
                    end
                end
            end
        end
        
        -- Сохраняем опции
        if Options then
            for idx, option in pairs(Options) do
                if not option.Type then continue end
                if not self.Parser[option.Type] then continue end
                if self.Ignore[idx] then continue end
                
                local success, result = pcall(function()
                    return self.Parser[option.Type].Save(idx, option)
                end)
                if success then
                    table.insert(data.objects, result)
                end
            end
        end
        
        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then
            return false, 'Ошибка кодирования данных'
        end
        
        writefile(fullPath, encoded)
        return true, 'Конфигурация сохранена'
    end
    
    -- Загрузка конфигурации
    function SaveManager:Load(configName)
        if not configName then
            return false, 'Не выбрана конфигурация'
        end
        
        if not isfile then
            return false, 'Файловые функции не доступны'
        end
        
        local filePath = self.Folder .. '/settings/' .. configName .. '.json'
        if not isfile(filePath) then
            return false, 'Файл конфигурации не найден'
        end
        
        local content = readfile(filePath)
        local success, decoded = pcall(httpService.JSONDecode, httpService, content)
        
        if not success then
            return false, 'Ошибка декодирования JSON'
        end
        
        if not decoded.objects then
            return false, 'Неверный формат конфигурации'
        end
        
        -- Загружаем настройки
        for _, optionData in ipairs(decoded.objects) do
            if self.Parser[optionData.type] then
                task.spawn(function()
                    self.Parser[optionData.type].Load(optionData.idx, optionData)
                end)
            end
        end
        
        return true, 'Конфигурация загружена'
    end
    
    -- Автосохранение текущих настроек
    function SaveManager:AutoSave()
        local success, message = self:Save('autosave', true)
        if success then
            print('[AutoSave] Успешно сохранено')
        else
            warn('[AutoSave] Ошибка:', message)
        end
    end
    
    -- Загрузка автосохранения
    function SaveManager:LoadAutoSave()
        return self:Load('autosave')
    end
    
    -- Игнорирование настроек тем
    function SaveManager:IgnoreThemeSettings()
        self:SetIgnoreIndexes({
            "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
            "ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
            'SaveManager_ConfigList', 'SaveManager_ConfigName',
            'SaveManager_BackupList', 'SaveManager_AutoSaveToggle',
            'MenuKeybind'
        })
    end
    
    -- Создание структуры папок
    function SaveManager:BuildFolderTree()
        if not makefolder or not isfolder then
            return
        end
        
        local paths = {
            self.Folder,
            self.Folder .. '/themes',
            self.Folder .. '/settings',
            self.Folder .. '/backups',
            self.Folder .. '/configs',
            self.Folder .. '/exports'
        }
        
        for _, path in ipairs(paths) do
            if not isfolder(path) then
                makefolder(path)
            end
        end
    end
    
    -- Обновление списка конфигураций
    function SaveManager:RefreshConfigList()
        if not listfiles or not isfolder then
            return {}
        end
        
        if not isfolder(self.Folder .. '/settings') then
            return {}
        end
        
        local files = listfiles(self.Folder .. '/settings')
        local configs = {}
        
        for _, filePath in ipairs(files) do
            if filePath:sub(-5) == '.json' then
                local fileName = filePath:match("([^/\\]+)%.json$")
                if fileName then
                    table.insert(configs, fileName)
                end
            end
        end
        
        table.sort(configs)
        return configs
    end
    
    -- Установка библиотеки
    function SaveManager:SetLibrary(library)
        self.Library = library
    end
    
    -- Автозагрузка конфигурации
    function SaveManager:LoadAutoloadConfig()
        if not isfile then return end
        
        local autoloadPath = self.Folder .. '/settings/autoload.txt'
        
        if isfile(autoloadPath) then
            local configName = readfile(autoloadPath)
            
            if configName and configName ~= '' then
                local success, message = self:Load(configName)
                
                if success and self.Library and self.Library.Notify then
                    self.Library:Notify(string.format('Autoload: %s', configName))
                elseif not success then
                    warn('Error autoload:', message)
                end
            end
        end
    end
    
    -- Безопасный метод для установки события изменения
    local function SafeOnChanged(toggle, callback)
        if toggle and toggle.OnChanged and type(toggle.OnChanged) == "function" then
            toggle:OnChanged(callback)
        elseif toggle and toggle.Callback then
            local originalCallback = toggle.Callback
            toggle.Callback = function(value)
                if originalCallback then
                    originalCallback(value)
                end
                callback(value)
            end
        elseif toggle then
            -- Если ничего не работает, просто сохраняем callback
            toggle._onChangedCallback = callback
        end
    end
    
    -- Создание раздела управления конфигурациями
    function SaveManager:BuildConfigSection(tab)
        if not self.Library then
            warn('SaveManager: Сначала установите SaveManager.Library!')
            return
        end
        
        local section = tab:AddLeftGroupbox('⚙️ Управление конфигурациями')
        section:AddLabel('Save and load settings', true)
        section:AddDivider()
        
        -- Поле ввода имени конфигурации
        section:AddInput('SaveManager_ConfigName', {
            Text = 'Name config',
            Placeholder = 'write a name',
            Tooltip = 'Name for save config'
        })
        
        -- Список существующих конфигураций
        local configList = section:AddDropdown('SaveManager_ConfigList', {
            Text = 'Lists config',
            Values = self:RefreshConfigList(),
            AllowNull = true,
            Tooltip = 'Select config for load'
        })
        
        section:AddDivider()
        
        -- Основные кнопки управления
        local manageButtons = section:AddButton({
            Text = 'Save',
            Func = function()
                local configName = Options and Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.Value or ""
                if configName and configName ~= '' then
                    local success, message = self:Save(configName, true)
                    if success then
                        if self.Library and self.Library.Notify then
                            self.Library:Notify('Config saved: ' .. configName)
                        end
                        if configList and configList.SetValues then
                            configList:SetValues(self:RefreshConfigList())
                        end
                        if Options and Options.SaveManager_ConfigName and Options.SaveManager_ConfigName.SetValue then
                            Options.SaveManager_ConfigName:SetValue('')
                        end
                    else
                        if self.Library and self.Library.Notify then
                            self.Library:Notify('Error: ' .. message, 3)
                        end
                    end
                else
                    if self.Library and self.Library.Notify then
                        self.Library:Notify('Write name config!', 2)
                    end
                end
            end,
            Tooltip = 'Сохранить текущие настройки'
        })
        
        manageButtons:AddButton({
            Text = 'Load',
            Func = function()
                if Options and Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value then
                    local success, message = self:Load(Options.SaveManager_ConfigList.Value)
                    if success then
                        if self.Library and self.Library.Notify then
                            self.Library:Notify('Config loaded')
                        end
                    else
                        if self.Library and self.Library.Notify then
                            self.Library:Notify('Error: ' .. message, 3)
                        end
                    end
                end
            end,
            Tooltip = 'Load selected config'
        })
        
        manageButtons:AddButton({
            Text = 'Delete',
            Func = function()
                if Options and Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value then
                    local configPath = self.Folder .. '/settings/' .. Options.SaveManager_ConfigList.Value .. '.json'
                    if isfile and isfile(configPath) then
                        if delfile then
                            delfile(configPath)
                        end
                        if self.Library and self.Library.Notify then
                            self.Library:Notify('Config deleted')
                        end
                        if configList and configList.SetValues then
                            configList:SetValues(self:RefreshConfigList())
                        end
                        if configList and configList.SetValue then
                            configList:SetValue(nil)
                        end
                    end
                end
            end,
            Tooltip = 'Delete selected config'
        })
        
        section:AddDivider()
        
        -- Дополнительные функции
        section:AddButton({
            Text = 'Update lists',
            Func = function()
                if configList and configList.SetValues then
                    configList:SetValues(self:RefreshConfigList())
                end
                if self.Library and self.Library.Notify then
                    self.Library:Notify('List updated')
                end
            end,
            Tooltip = 'Update lists config'
        })
        
        section:AddDivider()
        
        -- Настройки автозагрузки
        local autoloadLabel = section:AddLabel('Autoload: not installed', true)
        
        section:AddButton({
            Text = 'Install autoload',
            Func = function()
                if Options and Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value and writefile then
                    local autoloadPath = self.Folder .. '/settings/autoload.txt'
                    writefile(autoloadPath, Options.SaveManager_ConfigList.Value)
                    autoloadLabel:SetText('Autoload: ' .. Options.SaveManager_ConfigList.Value)
                    if self.Library and self.Library.Notify then
                        self.Library:Notify('Autoload installed')
                    end
                end
            end,
            Tooltip = 'Установить автозагрузку выбранной конфигурации'
        })
        
        section:AddButton({
            Text = 'Off autoload',
            Func = function()
                local autoloadPath = self.Folder .. '/settings/autoload.txt'
                if isfile and isfile(autoloadPath) and delfile then
                    delfile(autoloadPath)
                    autoloadLabel:SetText('Автозагрузка: отключена')
                    if self.Library and self.Library.Notify then
                        self.Library:Notify('Автозагрузка отключена')
                    end
                end
            end,
            Tooltip = 'Отключить автозагрузку'
        })
        
        -- Загрузка текущей автозагрузки
        local autoloadPath = self.Folder .. '/settings/autoload.txt'
        if isfile and isfile(autoloadPath) then
            local configName = readfile(autoloadPath)
            autoloadLabel:SetText('Автозагрузка: ' .. configName)
        end
        
        section:AddDivider()
        
        -- Автосохранение
        local autoSaveToggle = section:AddToggle('SaveManager_AutoSaveToggle', {
            Text = 'Автосохранение каждые 5 минут',
            Default = false,
            Tooltip = 'Автоматически сохранять настройки каждые 5 минут'
        })
        
        -- Безопасная настройка автосохранения
        if autoSaveToggle then
            local autoSaveInterval
            
            local function handleAutoSave(state)
                if autoSaveInterval then
                    autoSaveInterval:Disconnect()
                    autoSaveInterval = nil
                end
                
                if state then
                    autoSaveInterval = RunService.Heartbeat:Connect(function()
                        -- Проверяем каждые 5 минут (300 секунд)
                        if tick() % 300 < 0.1 then -- Небольшая погрешность
                            self:AutoSave()
                        end
                    end)
                    if self.Library and self.Library.Notify then
                        self.Library:Notify('Автосохранение включено')
                    end
                else
                    if self.Library and self.Library.Notify then
                        self.Library:Notify('Автосохранение отключено')
                    end
                end
            end
            
            -- Безопасное подключение события
            SafeOnChanged(autoSaveToggle, handleAutoSave)
            
            -- Также настраиваем callback напрямую
            if autoSaveToggle.Callback then
                local originalCallback = autoSaveToggle.Callback
                autoSaveToggle.Callback = function(value)
                    if originalCallback then
                        originalCallback(value)
                    end
                    handleAutoSave(value)
                end
            else
                autoSaveToggle.Callback = handleAutoSave
            end
        end
        
        section:AddButton({
            Text = '🔁 Загрузить автосохранение',
            Func = function()
                local success, message = self:LoadAutoSave()
                if success then
                    if self.Library and self.Library.Notify then
                        self.Library:Notify('Автосохранение загружено')
                    end
                else
                    if self.Library and self.Library.Notify then
                        self.Library:Notify('Автосохранение не найдено', 2)
                    end
                end
            end,
            Tooltip = 'Загрузить последнее автосохранение'
        })
        
        -- Игнорируем собственные элементы UI
        self:SetIgnoreIndexes({
            'SaveManager_ConfigList', 
            'SaveManager_ConfigName',
            'SaveManager_BackupList',
            'SaveManager_AutoSaveToggle'
        })
    end
    
    -- Инициализация
    SaveManager:BuildFolderTree()
end

return SaveManager

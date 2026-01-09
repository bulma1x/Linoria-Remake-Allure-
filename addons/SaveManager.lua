-- SaveManager.lua
local httpService = game:GetService('HttpService')

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
                if Toggles[idx] then
                    Toggles[idx]:SetValue(data.value)
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
                if Options[idx] then
                    Options[idx]:SetValue(data.value)
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
                if Options[idx] then
                    if data.multi then
                        local multiValue = {}
                        for _, item in ipairs(data.value) do
                            multiValue[item] = true
                        end
                        Options[idx]:SetValue(multiValue)
                    else
                        Options[idx]:SetValue(data.value)
                    end
                end
            end,
        },
        
        ColorPicker = {
            Save = function(idx, object)
                return {
                    type = 'ColorPicker',
                    idx = idx,
                    value = object.Value:ToHex(),
                    transparency = object.Transparency,
                    hue = object.Hue,
                    sat = object.Sat,
                    vib = object.Vib
                }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    local color = Color3.fromHex(data.value)
                    if data.hue and data.sat and data.vib then
                        Options[idx]:SetValue({data.hue, data.sat, data.vib}, data.transparency)
                    else
                        Options[idx]:SetValueRGB(color, data.transparency)
                    end
                end
            end,
        },
        
        KeyPicker = {
            Save = function(idx, object)
                return {
                    type = 'KeyPicker',
                    idx = idx,
                    key = object.Value,
                    mode = object.Mode,
                    syncToggle = object.SyncToggleState or false
                }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    Options[idx]:SetValue({data.key, data.mode})
                end
            end,
        },
        
        Input = {
            Save = function(idx, object)
                return {
                    type = 'Input',
                    idx = idx,
                    value = object.Value,
                    numeric = object.Numeric or false
                }
            end,
            Load = function(idx, data)
                if Options[idx] then
                    Options[idx]:SetValue(data.value)
                end
            end,
        },
    }
    
    -- Игнорирование определенных индексов
    function SaveManager:SetIgnoreIndexes(list)
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
        if not isfile(configPath) then return false end
        
        local backupPath = self.Folder .. '/backups/' .. configName .. '_' .. os.time() .. '.json'
        
        local content = readfile(configPath)
        writefile(backupPath, content)
        
        -- Ограничиваем количество резервных копий
        self:CleanupBackups(configName)
        
        return true
    end
    
    -- Очистка старых резервных копий
    function SaveManager:CleanupBackups(configName)
        local backups = self:GetBackupList(configName)
        
        while #backups > self.MaxBackups do
            local oldest = table.remove(backups, 1)
            delfile(self.Folder .. '/backups/' .. oldest)
        end
    end
    
    -- Получение списка резервных копий
    function SaveManager:GetBackupList(configName)
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
    
    -- Восстановление из резервной копии
    function SaveManager:RestoreFromBackup(backupName)
        local backupPath = self.Folder .. '/backups/' .. backupName
        if not isfile(backupPath) then return false end
        
        local content = readfile(backupPath)
        local configName = backupName:match('(.+)_%d+%.json$')
        
        if configName then
            local configPath = self.Folder .. '/settings/' .. configName .. '.json'
            writefile(configPath, content)
            return true
        end
        
        return false
    end
    
    -- Сохранение конфигурации
    function SaveManager:Save(configName, createBackup)
        if not configName or configName:gsub(' ', '') == '' then
            return false, 'Имя конфигурации не может быть пустым'
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
                script = script and script.Name or 'Unknown'
            }
        }
        
        -- Сохраняем тогглы
        for idx, toggle in pairs(Toggles) do
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
        end
        
        -- Сохраняем опции
        for idx, option in pairs(Options) do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
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
        
        -- Создаем резервную копию текущих настроек
        self:CreateBackup('current_before_load')
        
        -- Загружаем настройки
        for _, optionData in ipairs(decoded.objects) do
            if self.Parser[optionData.type] then
                task.spawn(function()
                    self.Parser[optionData.type].Load(optionData.idx, optionData)
                end)
            end
        end
        
        -- Обновляем UI после загрузки
        if self.Library then
            self.Library:UpdateDependencyBoxes()
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
            -- Настройки тем
            "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
            "ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
            
            -- Настройки менеджера конфигураций
            'SaveManager_ConfigList', 'SaveManager_ConfigName',
            'SaveManager_BackupList', 'SaveManager_AutoSaveToggle',
            
            -- Клавиша меню
            'MenuKeybind'
        })
    end
    
    -- Создание структуры папок
    function SaveManager:BuildFolderTree()
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
        local autoloadPath = self.Folder .. '/settings/autoload.txt'
        
        if isfile(autoloadPath) then
            local configName = readfile(autoloadPath)
            
            if configName and configName ~= '' then
                local success, message = self:Load(configName)
                
                if success then
                    if self.Library then
                        self.Library:Notify(string.format('Autoload: %s', configName))
                    end
                else
                    warn('Error autoload:', message)
                end
            end
        end
    end
    
    -- Экспорт конфигурации
    function SaveManager:ExportConfig(configName)
        if not configName then return false end
        
        local configPath = self.Folder .. '/settings/' .. configName .. '.json'
        if not isfile(configPath) then return false end
        
        local content = readfile(configPath)
        local exportPath = self.Folder .. '/exports/' .. configName .. '_export.json'
        
        writefile(exportPath, content)
        return true
    end
    
    -- Импорт конфигурации
    function SaveManager:ImportConfig(filePath)
        if not isfile(filePath) then return false end
        
        local content = readfile(filePath)
        local success, decoded = pcall(httpService.JSONDecode, httpService, content)
        
        if not success then return false end
        
        -- Извлекаем имя конфигурации
        local configName = filePath:match("([^/\\]+)%.json$")
        if not configName then return false end
        
        -- Сохраняем в папке настроек
        local savePath = self.Folder .. '/settings/' .. configName .. '.json'
        writefile(savePath, content)
        
        return true, configName
    end
    
    -- Создание раздела управления конфигурациями
    function SaveManager:BuildConfigSection(tab)
        assert(self.Library, 'Сначала установите SaveManager.Library!')
        
        local section = tab:AddRightGroupbox('⚙️ Управление конфигурациями')
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
                local configName = Options.SaveManager_ConfigName.Value
                if configName and configName ~= '' then
                    local success, message = self:Save(configName, true)
                    if success then
                        self.Library:Notify('Config saved: ' .. configName)
                        configList:SetValues(self:RefreshConfigList())
                        Options.SaveManager_ConfigName:SetValue('')
                    else
                        self.Library:Notify('Error: ' .. message, 3)
                    end
                else
                    self.Library:Notify('Write name config!', 2)
                end
            end,
            Tooltip = 'Сохранить текущие настройки'
        })
        
        manageButtons:AddButton({
            Text = 'Load',
            Func = function()
                if Options.SaveManager_ConfigList.Value then
                    local success, message = self:Load(Options.SaveManager_ConfigList.Value)
                    if success then
                        self.Library:Notify('Config loaded')
                    else
                        self.Library:Notify('Error: ' .. message, 3)
                    end
                end
            end,
            Tooltip = 'Load selected config'
        })
        
        manageButtons:AddButton({
            Text = 'Delete',
            Func = function()
                if Options.SaveManager_ConfigList.Value then
                    local configPath = self.Folder .. '/settings/' .. Options.SaveManager_ConfigList.Value .. '.json'
                    if isfile(configPath) then
                        delfile(configPath)
                        self.Library:Notify('Config deleted')
                        configList:SetValues(self:RefreshConfigList())
                        configList:SetValue(nil)
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
                configList:SetValues(self:RefreshConfigList())
                self.Library:Notify('List updated')
            end,
            Tooltip = 'Update lists config'
        })
        
        section:AddButton({
            Text = 'Export',
            Func = function()
                if Options.SaveManager_ConfigList.Value then
                    local success = self:ExportConfig(Options.SaveManager_ConfigList.Value)
                    if success then
                        self.Library:Notify('Config exported')
                    else
                        self.Library:Notify('Error export!', 2)
                    end
                end
            end,
            Tooltip = 'Exporting config'
        })
        
        section:AddDivider()
        
        -- Настройки автозагрузки
        local autoloadLabel = section:AddLabel('Autoload: not installed', true)
        
        section:AddButton({
            Text = 'Install autoload',
            Func = function()
                if Options.SaveManager_ConfigList.Value then
                    local autoloadPath = self.Folder .. '/settings/autoload.txt'
                    writefile(autoloadPath, Options.SaveManager_ConfigList.Value)
                    autoloadLabel:SetText('Autoload: ' .. Options.SaveManager_ConfigList.Value)
                    self.Library:Notify('Autoload installed')
                end
            end,
            Tooltip = 'Установить автозагрузку выбранной конфигурации'
        })
        
        section:AddButton({
            Text = 'Off autoload',
            Func = function()
                local autoloadPath = self.Folder .. '/settings/autoload.txt'
                if isfile(autoloadPath) then
                    delfile(autoloadPath)
                    autoloadLabel:SetText('Автозагрузка: отключена')
                    self.Library:Notify('Автозагрузка отключена')
                end
            end,
            Tooltip = 'Отключить автозагрузку'
        })
        
        -- Загрузка текущей автозагрузки
        local autoloadPath = self.Folder .. '/settings/autoload.txt'
        if isfile(autoloadPath) then
            local configName = readfile(autoloadPath)
            autoloadLabel:SetText('Автозагрузка: ' .. configName)
        end
        
        section:AddDivider()
        
        -- Резервные копии
        section:AddLabel('Резервные копии', true)
        
        section:AddButton({
            Text = '💾 Создать резервную копию',
            Func = function()
                if Options.SaveManager_ConfigList.Value then
                    local success = self:CreateBackup(Options.SaveManager_ConfigList.Value)
                    if success then
                        self.Library:Notify('Резервная копия создана')
                    else
                        self.Library:Notify('Ошибка создания резервной копии', 2)
                    end
                end
            end,
            Tooltip = 'Создать резервную копию конфигурации'
        })
        
        section:AddDivider()
        
        -- Автосохранение
        local autoSaveToggle = section:AddToggle('SaveManager_AutoSaveToggle', {
            Text = 'Автосохранение каждые 5 минут',
            Default = false,
            Tooltip = 'Автоматически сохранять настройки каждые 5 минут'
        })
        
        local autoSaveInterval
        Toggles.SaveManager_AutoSaveToggle:OnChanged(function(state)
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
                self.Library:Notify('Автосохранение включено')
            else
                self.Library:Notify('Автосохранение отключено')
            end
        end)
        
        section:AddButton({
            Text = '🔁 Загрузить автосохранение',
            Func = function()
                local success, message = self:LoadAutoSave()
                if success then
                    self.Library:Notify('Автосохранение загружено')
                else
                    self.Library:Notify('Автосохранение не найдено', 2)
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
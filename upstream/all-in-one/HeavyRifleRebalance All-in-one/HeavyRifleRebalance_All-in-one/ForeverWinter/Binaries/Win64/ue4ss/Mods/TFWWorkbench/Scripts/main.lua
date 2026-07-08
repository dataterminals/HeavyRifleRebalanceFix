local json = require("json")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")
local Settings = require("Settings")
local ItemDetailsData = require("ItemDetailsData")
local Items = require("Items")
local ItemTags = require("ItemTags")
local TagToRowHandle = require("TagToRowHandle")
local ValueHandler = require("Value")
local ManufacturingGroups = require("ManufacturingGroups")
local ManufacturingRecipes = require("ManufacturingRecipes")
local ManufacturingTags = require("ManufacturingTags")
local CraftingRecipe = require("CraftingRecipe")
local VendorData = require("VendorData")
local WeaponConfigSetup = require("WeaponConfigSetup")
local WeaponsDetailsData = require("WeaponsDetailsData")
local WeaponPartStatsData = require("WeaponPartStatsData")


-- NOTE Required to parse RecipyCraftTime of ManufactoringRecipies
RegisterCustomProperty({
    ["Name"] = "RecipyCraftTime",
    ["Type"] = PropertyTypes.Int64Property,
    ["BelongsToClass"] = "/Script/FWHubWorld.ManufactoringRecipies",
    ["OffsetInternal"] = 0x68
})

local DataTableClasses = {
    ItemDetailsData = ItemDetailsData,
    ItemTags = ItemTags,
    TagToRowHandle = TagToRowHandle,
    ValueHandler = ValueHandler,
    ManufacturingGroups = ManufacturingGroups,
    ManufacturingRecipes = ManufacturingRecipes,
    ManufacturingTags = ManufacturingTags,
    VendorData = VendorData,
    WeaponConfigSetup = WeaponConfigSetup,
    WeaponsDetailsData = WeaponsDetailsData,
    WeaponPartStatsData = WeaponPartStatsData,
}

local DataTableHandlers = {
    ItemDetailsData = {},
    ItemTags = {},
    ManufacturingGroups = {},
    ManufacturingRecipes = {},
    ManufacturingTags = {},
    TagToRowHandle = {},
    ValueHandler = {},
    VendorData = {},
    WeaponConfigSetup = {},
    WeaponsDetailsData = {},
    WeaponPartStatsData = {},
}


local DataCollections = {
    Item = {},
    ItemValue = {},
    CraftingRecipe = {},
    CraftingGroup = {},
    VendorData = {},
    WeaponConfigSetup = {},
    WeaponsDetailsData = {},
    WeaponPartStatsData = {},
}

local function Log(message, funcName)
    Utils.Log(message, "main", funcName)
end

local function GetModDir()
    local dirs = IterateGameDirectories()
    return dirs.Game.Content.Paks.Mods.TFWWorkbench
end

local function FindOrCreateModDir()
    local dirs = IterateGameDirectories()
    local modDir = GetModDir()

    if modDir then
        return modDir
    else
        Utils.Log(string.format("No such directory %s/TFWWorkbench\n", dirs.Game.Content.Paks.Mods.__absolute_path),
            "main")
        Utils.Log(string.format("Creating directory %s/TFWWorkbench\n", dirs.Game.Content.Paks.Mods.__absolute_path),
            "main")
        local success, result, code = os.execute(string.format("mkdir \"%s\\TFWWorkbench\"",
            dirs.Game.Content.Paks.Mods.__absolute_path))
        if not success then
            Utils.Log(string.format("Failed to create directory: %s - %d\n", result, code))
            return nil
        else
            return GetModDir()
        end
    end
end

local function CreateModChildDirs(modDir)
    local modDirPath = modDir.__absolute_path

    for parent, children in pairs(Settings.ModChildDirs) do
        local parentDirPath = string.format("%s/%s", modDirPath, parent)
        if not modDir[parent] then
            Log(string.format("Creating directory %s\n", parentDirPath), "CreateModChildDirs")

            local success, result, code = os.execute(string.format("mkdir \"%s\"", parentDirPath))
            if not success then
                Log(string.format("Failed to create directory: %s - %d\n", result, code), "CreateModChildDirs")
                parentDirPath = ""
            end
        end

        if parentDirPath then
            for _, child in ipairs(children) do
                local childDirPath = string.format("%s/%s", parentDirPath, child)
                local failed, result, code = os.execute(
                    string.format("if exist \"%s\" (true)", childDirPath))
                if failed then
                    Log(string.format("Creating directory %s\n", childDirPath), "CreateModChildDirs")
                    local success, result, code = os.execute(string.format("mkdir \"%s\"", childDirPath))
                    if not success then
                        Log(string.format("Failed to create directory: %s - %d\n", result, code), "CreateModChildDirs")
                    end
                end
            end
        end
    end
end

local function CollectData(dir)
    Utils.Log(string.format("Collecting data from %s\n", dir.__absolute_path), "main", "CollectData")

    local collection = {
        Add = {},
        AddTo = {},
        ModifyIn = {},
        Replace = {},
        Remove = {},
        RemoveFrom = {}
    }

    for _, file in pairs(dir.__files) do
        local fp = io.open(file.__absolute_path, "r")
        local success, content = pcall(function() return fp:read("a") end)
        if not success then
            Utils.Log(string.format("Failed to read %s\n", file.__absolute_path))
            fp:close()
        else
            fp:close()
            local success, elementList = pcall(function() return json.decode(content) end)
            if not success then
                Utils.Log(string.format("Failed to parse contents of %s\n", file.__absolute_path), "main", "CollectData")
            else
                for _, element in pairs(elementList) do
                    if element["Action"] == "Add" then
                        Utils.Log(
                            string.format("Add %s - Name: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "main",
                            "CollectData")
                        table.insert(collection.Add, { Name = element["Name"], Data = element["Data"] })
                    elseif element["Action"] == "Replace" then
                        Utils.Log(
                            string.format("Replace %s - Name: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "main", "CollectData")
                        table.insert(collection.Replace, { Name = element["Name"], Data = element["Data"] })
                    elseif element["Action"] == "Remove" then
                        Utils.Log(
                            string.format("Remove %s - Name: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "main", "CollectData")
                        table.insert(collection.Remove, { Name = element["Name"], Data = element["Data"] })
                    elseif element["Action"] == "AddTo" then
                        Log(
                            string.format("AddTo (Property) %s - Name: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "CollectData")
                        table.insert(collection.AddTo, { Name = element["Name"], Data = element["Data"] })
                    elseif element["Action"] == "ModifyIn" then
                        Log(
                            string.format("ModifyIn (Property) %s - Name: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "CollectData")
                        table.insert(collection.ModifyIn, { Name = element["Name"], Data = element["Data"] })
                    elseif element["Action"] == "RemoveFrom" then
                        Log(
                            string.format("RemoveFrom (Property) %s - Name: %s\tFile: %s\n", dir.__name, element["Name"], file.__name),
                            "CollectData")
                        table.insert(collection.RemoveFrom, { Name = element["Name"], Data = element["Data"] })
                    end
                end
            end
        end
    end

    return collection
end

local function IsDataTableValid(dataTable)
    return dataTable and dataTable:IsValid()
end

-- Some data tables aren't loaded when the game launches. But only via in-game
-- triggers.
-- Tables the need to be loaded on mod startup:
-- - DT_ManufactoringGroups
local function LoadDataTableAssets()
    local assetRegistryHelpers = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    if not assetRegistryHelpers:IsValid() then
        Utils.Log("AssetRegistryHelpers is not valid\n", "main", "LoadDataTableAssets")
    end

    local assetRegistry = nil
    if assetRegistryHelpers then
        assetRegistry = assetRegistryHelpers:GetAssetRegistry()
        if not assetRegistry:IsValid() then
            assetRegistry = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryImpl")
        end
    end

    if not assetRegistry or not assetRegistry:IsValid() then
        Utils.Log("AssetRegistry is not valid. Can't load data table assets!\n", "main", "LoadDataTableAssets")
        return
    end

    -- Table of DataTables that need to be loaded at the beginning of the game
    local assetData = {
        ManufacturingGroups = {
            ["PackageName"] = UEHelpers.FindOrAddFName("/Game/FW/UI/Manufactoring/Data/DT_ManufactoringGroups"),
            ["AssetName"] = UEHelpers.FindOrAddFName("DT_ManufactoringGroups")
        }
    }

    for tableName, data in pairs(assetData) do
        local obj = StaticFindObject(Settings.DataTableClassNames.ManufacturingGroups)
        if obj and obj:IsValid() then
            Utils.Log(string.format("Asset already loaded, skipping: %s\n", Utils.PrintTable(data)), "main",
                "LoadDataTableAssets")
        else
            Utils.Log(string.format("Loading data table asset for %s\n", tableName), "main", "LoadDataTableAssets")
            local assetClass = assetRegistryHelpers:GetAsset(data)
            if not assetClass:IsValid() then
                Utils.Log(string.format("Failed to load data table asset for %s\n", tableName), "main",
                    "LoadDataTableAssets")
            else
                Utils.Log(
                    string.format("Successfully loaded data table asset for %s: %s\n", tableName,
                        assetClass:GetFullName()),
                    "main",
                    "LoadDataTableAssets")
                -- Adding to the GameInstance's ReferencedObjects so it doesn't get gargabe colllected
                local gameInstance = UEHelpers.GetGameInstance()
                local numRefObjects = gameInstance.ReferencedObjects:GetArrayNum()
                gameInstance.ReferencedObjects[numRefObjects + 1] = assetClass
            end
        end
    end
end

-- Providing the DLL part of the mod with the required data table data
local function InitDataTables()
    for tableName, details in pairs(Settings.DataTables) do
        ConfigureDataTables(tableName, details.Path)
    end
end

RegisterConsoleCommandHandler("DumpDataTables", function(fullCmd, params, outputDevice)
    Utils.Log("Handle console command 'DumpDataTables'\n", "main")
    Utils.Log(string.format("Full command: %s\n", fullCmd), "main")

    outputDevice:Log("Dumping data tables")

    --NOTE: Using async calls here to don't lock up the game thread
    for name, handler in pairs(DataTableHandlers) do
        if name ~= "ValueHandler" then
            ExecuteAsync(function() handler:DumpDataTable() end)
        end
    end

    for _, handler in pairs(DataTableHandlers.ValueHandler or {}) do
        if IsDataTableValid(handler.__table) then
            ExecuteAsync(function() handler:DumpDataTable() end)
        end
    end

    return true
end)

ExecuteInGameThread(function()
    -- Create mod dir and mod child dirs if not present and collect data from mod child dirs
    local modDir = FindOrCreateModDir()
    CreateModChildDirs(modDir)
    for dirName, dir in pairs(modDir.DataTable or {}) do
        if not (dirName == "Dumps") then
            DataCollections[dirName] = CollectData(dir)
        end
    end

    LoadDataTableAssets()
    InitDataTables()

    -- Initialize data table handlers
    for name, class in pairs(DataTableClasses) do
        if name ~= "ValueHandler" then
            local dataTable = StaticFindObject(Settings.DataTableClassNames[name])
            if IsDataTableValid(dataTable) then
                DataTableHandlers[name] = class.new(dataTable)
            end
        end
    end

    for _, path in ipairs(Settings.ValueTables) do
        local dataTable = StaticFindObject(path)
        if IsDataTableValid(dataTable) then
            local dataTableName = Utils.GetDataTableName(dataTable)
            DataTableHandlers.ValueHandler[dataTableName] = ValueHandler.new(dataTable)
        end
    end

    -- NOTE: These Add/Replace/Remove function calls could potentially also be called asynchronously
    -- if there are ever any "performance" concerns. Though it's more a user experience thing.
    -- As a large amount of items could cause the game thread to be locked up. Meaning the game would
    -- take a bit longer to load into the main menu.

    -- InventoryItemDetailsData
    ExecuteWithDelay(100, function()
        Items.AddItems(
            (DataCollections.Item or {}).Add or {},
            DataTableHandlers.ItemDetailsData,
            DataTableHandlers.ItemTags,
            DataTableHandlers.TagToRowHandle)
    end)

    ExecuteWithDelay(100, function()
        for _, itemData in ipairs((DataCollections.Item or {}).Replace or {}) do
            DataTableHandlers.ItemDetailsData:ReplaceRow(itemData["Name"], itemData["Data"])
        end
    end)

    ExecuteWithDelay(100, function()
        Items.RemoveItems(
            (DataCollections.Item or {}).Remove or {},
            DataTableHandlers.ItemDetailsData,
            DataTableHandlers.ItemTags,
            DataTableHandlers.TagToRowHandle)
    end)

    ExecuteWithDelay(100, function()
        for _, item in ipairs((DataCollections.Item or {}).AddTo or {}) do
            for propertyName, value in pairs(item["Data"]) do
                DataTableHandlers.ItemDetailsData.RowData:AddTo(item["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, item in ipairs((DataCollections.Item or {}).ModifyIn or {}) do
            for propertyName, value in pairs(item["Data"]) do
                DataTableHandlers.ItemDetailsData.RowData:ModifyIn(item["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, item in ipairs((DataCollections.Item or {}).RemoveFrom or {}) do
            for propertyName, value in pairs(item["Data"]) do
                DataTableHandlers.ItemDetailsData.RowData:RemoveFrom(item["Name"], propertyName, value)
            end
        end
    end)

    -- WeaponPartStatsData
    -- No need to support AddTo, ModifyIn, or RemoveFrom. As the row data is flat and only consists
    -- of basic data types. Meaning Replace is sufficient.
    ExecuteWithDelay(100, function()
        for _, weaponPartStats in ipairs((DataCollections.WeaponPartStatsData or {}).Add or {}) do
            DataTableHandlers.WeaponPartStatsData:AddRow(weaponPartStats["Name"], weaponPartStats["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponPartStats in ipairs((DataCollections.WeaponPartStatsData or {}).Replace or {}) do
            DataTableHandlers.WeaponPartStatsData:ReplaceRow(weaponPartStats["Name"], weaponPartStats["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponPartStats in ipairs((DataCollections.WeaponPartStatsData or {}).Remove or {}) do
            DataTableHandlers.WeaponPartStatsData:RemoveRow(weaponPartStats["Name"])
        end
    end)

    -- WeaponsDetailsData
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponsDetailsData or {}).Add or {}) do
            DataTableHandlers.WeaponsDetailsData:AddRow(weaponDetails["Name"], weaponDetails["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponsDetailsData or {}).Replace or {}) do
            DataTableHandlers.WeaponsDetailsData:ReplaceRow(weaponDetails["Name"], weaponDetails["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponsDetailsData or {}).Remove or {}) do
            DataTableHandlers.WeaponsDetailsData:RemoveRow(weaponDetails["Name"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponsDetailsData or {}).RemoveFrom or {}) do
            for propertyName, value in pairs(weaponDetails["Data"]) do
                DataTableHandlers.WeaponsDetailsData.RowData:RemoveFrom(weaponDetails["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponsDetailsData or {}).AddTo or {}) do
            for propertyName, value in pairs(weaponDetails["Data"]) do
                DataTableHandlers.WeaponsDetailsData.RowData:AddTo(weaponDetails["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponsDetailsData or {}).ModifyIn or {}) do
            for propertyName, value in pairs(weaponDetails["Data"]) do
                DataTableHandlers.WeaponsDetailsData.RowData:ModifyIn(weaponDetails["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponsDetailsData or {}).RemoveFrom or {}) do
            for propertyName, value in pairs(weaponDetails["Data"]) do
                DataTableHandlers.WeaponsDetailsData.RowData:RemoveFrom(weaponDetails["Name"], propertyName, value)
            end
        end
    end)

    -- WeaponConfigSetup
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponConfigSetup or {}).Add or {}) do
            DataTableHandlers.WeaponConfigSetup:AddRow(weaponDetails["Name"], weaponDetails["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponConfigSetup or {}).Replace or {}) do
            DataTableHandlers.WeaponConfigSetup:ReplaceRow(weaponDetails["Name"], weaponDetails["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponConfigSetup or {}).Remove or {}) do
            DataTableHandlers.WeaponConfigSetup:RemoveRow(weaponDetails["Name"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponConfigSetup or {}).RemoveFrom or {}) do
            for propertyName, value in pairs(weaponDetails["Data"]) do
                DataTableHandlers.WeaponConfigSetup.RowData:RemoveFrom(weaponDetails["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponConfigSetup or {}).AddTo or {}) do
            for propertyName, value in pairs(weaponDetails["Data"]) do
                DataTableHandlers.WeaponConfigSetup.RowData:AddTo(weaponDetails["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponConfigSetup or {}).ModifyIn or {}) do
            for propertyName, value in pairs(weaponDetails["Data"]) do
                DataTableHandlers.WeaponConfigSetup.RowData:ModifyIn(weaponDetails["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, weaponDetails in ipairs((DataCollections.WeaponConfigSetup or {}).RemoveFrom or {}) do
            for propertyName, value in pairs(weaponDetails["Data"]) do
                DataTableHandlers.WeaponConfigSetup.RowData:RemoveFrom(weaponDetails["Name"], propertyName, value)
            end
        end
    end)

    -- ValueData
    -- No need to support AddTo, ModifyIn, or RemoveFrom. As the row data is flat and only consists
    -- of basic data types. Meaning Replace is sufficient.
    ExecuteWithDelay(100, function()
        for _, valueData in ipairs((DataCollections.ItemValue or {}).Add or {}) do
            local dataTableName = Utils.GetDataTableName(valueData["Data"]["DataTable"])
            local handler = DataTableHandlers.ValueHandler[dataTableName]
            if handler then
                handler:AddRow(valueData["Name"], valueData["Data"])
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, valueData in ipairs((DataCollections.ItemValue or {}).Replace or {}) do
            local dataTableName = Utils.GetDataTableName(valueData["Data"]["DataTable"])
            local handler = DataTableHandlers.ValueHandler[dataTableName]
            if handler then
                handler:ReplaceRow(valueData["Name"], valueData["Data"])
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, valueData in ipairs((DataCollections.ItemValue or {}).Remove or {}) do
            local dataTableName = Utils.GetDataTableName(valueData["Data"]["DataTable"])
            local handler = DataTableHandlers.ValueHandler[dataTableName]
            if handler then
                handler:RemoveRow(valueData["Name"])
            end
        end
    end)

    -- ManufacturingRecipes
    ExecuteWithDelay(100, function()
        CraftingRecipe.AddRecipes(
            (DataCollections.CraftingRecipe or {}).Add or {},
            DataTableHandlers.ManufacturingRecipes,
            DataTableHandlers.ManufacturingTags)
    end)
    ExecuteWithDelay(100, function()
        for _, recipe in ipairs((DataCollections.CraftingRecipe or {}).Remove or {}) do
            DataTableHandlers.ManufacturingRecipes:RemoveRow(recipe["Name"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, recipe in ipairs((DataCollections.CraftingRecipe or {}).Replace or {}) do
            DataTableHandlers.ManufacturingRecipes:ReplaceRow(recipe["Name"], recipe["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, recipe in ipairs((DataCollections.CraftingRecipe or {}).AddTo or {}) do
            for propertyName, value in pairs(recipe["Data"]) do
                DataTableHandlers.ManufacturingRecipes.RowData:AddTo(recipe["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, recipe in ipairs((DataCollections.CraftingRecipe or {}).ModifyIn or {}) do
            for propertyName, value in pairs(recipe["Data"]) do
                DataTableHandlers.ManufacturingRecipes.RowData:ModifyIn(recipe["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, recipe in ipairs((DataCollections.CraftingRecipe or {}).RemoveFrom or {}) do
            for propertyName, value in pairs(recipe["Data"]) do
                DataTableHandlers.ManufacturingRecipes.RowData:RemoveFrom(recipe["Name"], propertyName, value)
            end
        end
    end)

    -- ManufacturingGroups
    ExecuteWithDelay(100, function()
        for _, group in ipairs((DataCollections.CraftingGroup or {}).Add or {}) do
            DataTableHandlers.ManufacturingGroups:AddRow(group["Name"], group["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, group in ipairs((DataCollections.CraftingGroup or {}).Replace or {}) do
            DataTableHandlers.ManufacturingGroups:ReplaceRow(group["Name"], group["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, group in ipairs((DataCollections.CraftingGroup or {}).Remove or {}) do
            DataTableHandlers.ManufacturingGroups:RemoveRow(group["Name"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, group in ipairs((DataCollections.CraftingGroup or {}).AddTo or {}) do
            for propertyName, value in pairs(group["Data"]) do
                DataTableHandlers.ManufacturingGroups.RowData:AddTo(group["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, group in ipairs((DataCollections.CraftingGroup or {}).ModifyIn or {}) do
            for propertyName, value in pairs(group["Data"]) do
                DataTableHandlers.ManufacturingGroups.RowData:ModifyIn(group["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, group in ipairs((DataCollections.CraftingGroup or {}).RemoveFrom or {}) do
            for propertyName, value in pairs(group["Data"]) do
                DataTableHandlers.ManufacturingGroups.RowData:RemoveFrom(group["Name"], propertyName, value)
            end
        end
    end)

    -- VendorData
    --NOTE: Adding does work as well but doesn't make any sense yet. Once support for
    -- VendorDetailsDatatable was added it makes sense to call AddRow for VendorData as well.
    ExecuteWithDelay(100, function()
        for _, vendorData in ipairs((DataCollections.VendorData or {}).Replace or {}) do
            DataTableHandlers.VendorData:ReplaceRow(vendorData["Name"], vendorData["Data"])
        end
    end)
    ExecuteWithDelay(100, function()
        for _, vendorData in ipairs((DataCollections.VendorData or {}).AddTo or {}) do
            for propertyName, value in pairs(vendorData["Data"]) do
                DataTableHandlers.VendorData.RowData:AddTo(vendorData["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, vendorData in ipairs((DataCollections.VendorData or {}).ModifyIn or {}) do
            for propertyName, value in pairs(vendorData["Data"]) do
                DataTableHandlers.VendorData.RowData:ModifyIn(vendorData["Name"], propertyName, value)
            end
        end
    end)
    ExecuteWithDelay(100, function()
        for _, vendorData in ipairs((DataCollections.VendorData or {}).RemoveFrom or {}) do
            for propertyName, value in pairs(vendorData["Data"]) do
                DataTableHandlers.VendorData.RowData:RemoveFrom(vendorData["Name"], propertyName, value)
            end
        end
    end)
end)

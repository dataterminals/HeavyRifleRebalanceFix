local Utils = require("utils")
local DataTable = require("DataTable")
local Parser = require("DataTableParser")


local function Log(message, funcName)
    Utils.Log(message, "ItemDetailsData", funcName)
end

local ItemDetailsData = setmetatable({}, {__index = DataTable})
ItemDetailsData.__index = ItemDetailsData

function ItemDetailsData.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, ItemDetailsData)
    return self
end

local function ToJsonItemMeshTransform(itemMeshTransform)
    local result = {
        Rotation = {},
        Translation = {},
        Scale3D = {}
    }

    for key, value in pairs(result) do
        itemMeshTransform[key]:ForEachProperty(function(property)
            local propertyName = property:GetFName():ToString()
            value[propertyName] = itemMeshTransform[key][propertyName]
        end)
    end

    Log(string.format("Rotation: %s\n", Utils.PrintTable(result.Rotation)), "ToJsonItemMeshTransform")
    Log(string.format("Translation: %s\n", Utils.PrintTable(result.Translation)), "ToJsonItemMeshTransform")
    Log(string.format("Scale3D: %s\n", Utils.PrintTable(result.Scale3D)), "ToJsonItemMeshTransform")

    return result
end

---@param data FInventoryItemDetails
function ItemDetailsData:ParseRowData(data)
    if not data then
        return {}
    end

    local kismetLib = self.__kismetlib
    return {
        Category = Parser.ToJson(data.Category, kismetLib),
        ItemName = Parser.ToJson(data.ItemName, kismetLib),
        ItemDescription = Parser.ToJson(data.ItemDescription, kismetLib),
        ItemMesh = Parser.ToJson(data.ItemMesh, kismetLib),
        ItemMeshTransform = ToJsonItemMeshTransform(data.ItemMeshTransform),
        -- We don't care about these two properties as they're always nil
        --ExtraMeshs = nil,
        --ExtraMeshTransform = nil,
        ItemLootRadius = Parser.ToJson(data.ItemLootRadius, kismetLib),
        ItemIconRadius = Parser.ToJson(data.ItemIconRadius, kismetLib),
        ItemIcon = Parser.ToJson(data.ItemIcon, kismetLib),
        ItemType = Parser.ToJsonEItemCategory(data.ItemType),
        ItemSubtype = Parser.ToJson(data.ItemSubtype, kismetLib),
        ExtraDetailsRowName = Parser.ToJson(data.ExtraDetailsRowName, kismetLib),
        LootSound = Parser.ToJson(data.LootSound, kismetLib),
        DropSound = Parser.ToJson(data.DropSound, kismetLib),
        ItemSize = Parser.ToJson(data.ItemSize, kismetLib),
        Volume = Parser.ToJson(data.Volume, kismetLib),
        Weight = Parser.ToJson(data.Weight, kismetLib),
        ValueRow = Parser.ToJson(data.ValueRow, kismetLib),
        -- Ignoring them because they are always 0
        --Value = ToJson(data.Value),
        --WaterValue = ToJson(data.WaterValue),
        DropOnDeath = Parser.ToJson(data.DropOnDeath, kismetLib),
        MaxStack = Parser.ToJson(data.MaxStack, kismetLib),
        ExtraTagData = Parser.ToJson(data.ExtraTagData, kismetLib),
        StartingStack = Parser.ToJson(data.StartingStack, kismetLib),
        ConsumableAbility = Parser.ToJson(data.ConsumableAbility, kismetLib),
        BattlepointsRowHandle = Parser.ToJson(data.BattlepointsRowHandle, kismetLib),
        TacCamHighlight = Parser.ToJsonTacCamHighlight(data.TacCamHighlight),
        RareLootCategory = Parser.ToJson(data.RareLootCategory, kismetLib),
        RareLootLocations = Parser.ToJson(data.RareLootLocations, kismetLib)
    }
end

function ItemDetailsData:AddRow(name, data)
    ---@class FInventoryItemDetails
    local rowData = {
        Category = data["Category"],
        ItemName = data["ItemName"],
        ItemDescription = data["ItemDescription"],
        ItemMesh = data["ItemMesh"],
        ItemMeshTransform = data["ItemMeshTransform"],
        ExtraMeshs = {},
        ExtraMeshTransform = {},
        ItemLootRadius = data["ItemLootRadius"],
        ItemIconRadius = data["ItemIconRadius"],
        ItemIcon = data["ItemIcon"],
        ItemType = Parser.EItemCategory[data["ItemType"]],
        ItemSubtype = data["ItemSubtype"],
        ExtraDetailsRowName = "None",
        LootSound = data["LootSound"],
        DropSound = data["DropSound"],
        ItemSize = data["ItemSize"],
        Volume = data["Volume"],
        Weight = data["Weight"],
        ValueRow = data["ValueRow"],
        Value = 0,
        WaterValue = 0,
        DropOnDeath = data["DropOnDeath"],
        MaxStack = data["MaxStack"],
        ExtraTagData = data["ExtraTagData"],
        StartingStack = data["StartingStack"],
        ConsumableAbility = data["ConsumableAbility"],
        BattlepointsRowHandle = data["BattlepointsRowHandle"],
        TacCamHighlight = Parser.TacCamColours[data["TacCamHighlight"]],
        RareLootCategory = data["RareLootCategory"],
        RareLootLocations = data["RareLootLocations"]
    }

    -- Need to use custom function that's implemented in the C++ part of this mod.
    AddDataTableRow("InventoryItemDetails", name, rowData)

    Log(string.format("Added row %s\n", name), "AddRow")
end

function ItemDetailsData:ReplaceRow(name, data)
    local row = self.__table:FindRow(name)
    if not row then
        Log(string.format("Row with name %s not found\n", name), "ReplaceRow")
        return
    end

    local parsedRow = self:ParseRowData(row)
    for field, value in pairs(data) do
        if field == "ItemType" then
            parsedRow[field] = Parser.EItemCategory[value]
        elseif field == "TacCamHighlight" then
            parsedRow[field] = Parser.TacCamColours[value]
        else
            parsedRow[field] = value
        end
    end

    Log(string.format("Replaced row %s by calling AddRow\n", name), "ReplaceRow")
    self:AddRow(name, parsedRow)
end

return ItemDetailsData

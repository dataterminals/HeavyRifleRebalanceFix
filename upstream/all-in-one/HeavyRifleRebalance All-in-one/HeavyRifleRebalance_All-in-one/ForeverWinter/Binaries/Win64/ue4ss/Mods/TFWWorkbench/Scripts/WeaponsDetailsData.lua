local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "WeaponsDetailsData", funcName)
end

local WeaponsDetailsData = setmetatable({}, {__index = DataTable})
WeaponsDetailsData.__index = WeaponsDetailsData

function WeaponsDetailsData.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, WeaponsDetailsData)
    return self
end

---@param data FInventoryDangly
function WeaponsDetailsData:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        DanglyName = Parser.ToJson(data.DanglyName, lib),
        DanglyDescription = Parser.ToJson(data.DanglyDescription, lib),
        ExtraTooltip = Parser.ToJson(data.ExtraTooltip, lib),
        --GachaRow not being used by the game
        DanglyClass = Parser.ToJson(data.DanglyClass, lib),
        CanBeLoose = Parser.ToJson(data.CanBeLoose, lib),
        MustBeLoose = Parser.ToJson(data.MustBeLoose, lib),
        AttachRelativeToRig = Parser.ToJson(data.AttachRelativeToRig, lib),
        Weight = Parser.ToJson(data.Weight, lib),
        --Durability not being used by the game
        --LootTime not being used by the game
        ValueRowName = Parser.ToJson(data.ValueRowName, lib),
        ValueRow = Parser.ToJson(data.ValueRow, lib),
        --Value not being used by the game, uses a value table instead
        --WaterValue not being used by the game
        Icon = Parser.ToJson(data.Icon, lib),
        DanglyTypeTag = Parser.ToJson(data.DanglyTypeTag, lib),
        DataAsset = Parser.ToJson(data.DataAsset, lib),
        HUDIcon = Parser.ToJson(data.HUDIcon, lib),
        --ActivateableAbility not being used by the game
        --LootSound not being used by the game
        --DropSound not being used by the game
        TacCamHighlight = Parser.ToJsonTacCamHighlight(data.TacCamHighlight),
        AllowTags = Parser.ToJson(data.AllowTags, lib),
        RequiredGameplayTags = Parser.ToJson(data.RequiredGameplayTags, lib),
        LevelScopeTag = Parser.ToJson(data.LevelScopeTag, lib),
        LevelPartUnlockTable = Parser.ToJson(data.LevelPartUnlockTable, lib)
    }
end

function WeaponsDetailsData:AddRow(name, data)
    ---@class FInventoryDangly
    local rowData = {
        DanglyName = data["DanglyName"],
        DanglyDescription = data["DanglyDescription"],
        ExtraTooltip = data["ExtraTooltip"],
        GachaRow = { DataTable = nil, RowName = "None" },  -- Default value
        DanglyClass = data["DanglyClass"],
        CanBeLoose = data["CanBeLoose"],
        MustBeLoose = data["MustBeLoose"],
        AttachRelativeToRig = data["AttachRelativeToRig"],
        Weight = data["Weight"],
        Durability = 0,  -- Default value
        ValueRowName = data["ValueRowName"],
        ValueRow = data["ValueRow"],
        Value = 0, -- Default value
        WaterValue = 0, -- Default value
        Icon = data["Icon"],
        DanglyTypeTag = data["DanglyTypeTag"],
        DataAsset = data["DataAsset"],
        HUDIcon = data["HUDIcon"],
        ActivateableAbility = "",  -- Default value
        LootSound = "",  -- Default value
        DropSound = "",  -- Default value
        TacCamHighlight = Parser.TacCamColours[data.TacCamHighlight],
        AllowTags = data["AllowTags"],
        RequiredGameplayTags = data["RequiredGameplayTags"],
        LevelScopeTag = data["LevelScopeTag"],
        LevelPartUnlockTable = data["LevelPartUnlockTable"]
    }

    local success = pcall(function() AddDataTableRow("WeaponsDetailsData", name, rowData) end)
    if not success then
        Log(string.format("Failed to add row %s\n", name), "AddRow")
    else
        Log(string.format("Added row %s\n", name), "AddRow")
    end
end

return WeaponsDetailsData
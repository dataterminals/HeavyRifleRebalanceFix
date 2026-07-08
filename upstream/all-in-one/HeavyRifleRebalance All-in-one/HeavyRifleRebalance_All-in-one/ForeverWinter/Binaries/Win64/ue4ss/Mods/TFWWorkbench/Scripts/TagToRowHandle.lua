--[[
A module to manage rows in the `DT_TagToRowHandle` data table
]]
local DataTable = require("DataTable")
local DataTableParser = require("DataTableParser")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")

local function Log(message, funcName)
    Utils.Log(message, "TagToRowHandle", funcName)
end

local TagToRowHandle = setmetatable({}, {__index = DataTable})
TagToRowHandle.__index = TagToRowHandle

function TagToRowHandle.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, TagToRowHandle)
    return self
end

local EStoreCategory = {
    Item = 0,
    QuestItem = 1,
    Weapon = 2,
    Container = 3,
    Rig = 4,
    Dangly = 5,
    Frame = 6,
    Buddy = 7
}

local function ToJsonEStoreCategory(storeCategory)
    local categories = {
        [0] = "Item",
        [1] = "QuestItem",
        [2] = "Weapon",
        [3] = "Container",
        [4] = "Rig",
        [5] = "Dangly",
        [6] = "Frame",
        [7] = "Buddy"
    }
    Log(string.format("EStoreCategroy: %s - %d\n", categories[storeCategory], storeCategory), "ToJsonEStoreCategory")
    return categories[storeCategory]
end

---Parse FWItemType to table that can be json encoded.
---@param data FFWItemType
---@return table
local function ParseFWItemType(data)
    local kismetLib = DataTable.__kismetlib
    return {
        DataRow = DataTableParser.ToJson(data.DataRow, kismetLib),
        DataType = ToJsonEStoreCategory(data.DataType)
    }
end

function TagToRowHandle:AddRow(itemTag, data)
    local fwItemType = {
        DataType = EStoreCategory[data["DataType"]],
        DataRow = {
            RowName = UEHelpers.FindOrAddFName(data["Name"]),
            DataTable = StaticFindObject(data["DataTable"])
        }
    }
    self.__table:AddRow(itemTag, fwItemType)
    Log(string.format("Added row %s\n", itemTag), "AddRow")
end

function TagToRowHandle:ReplaceRow(itemTag, data)
    local fwItemType = {
        DataType = EStoreCategory[data["DataType"]],
        DataRow = {
            RowName = UEHelpers.FindOrAddFName(data["DataRow"]["RowName"]),
            DataTable = StaticFindObject(data["DataRow"]["DataTable"])
        }
    }
    self.__table:AddRow(itemTag, fwItemType)
    Log(string.format("Replaced row %s - %s\n", itemTag, Utils.PrintTable(data)), "ReplaceRow")
end

return TagToRowHandle

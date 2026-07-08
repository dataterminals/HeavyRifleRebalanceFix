local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local UEHelpers = require("UEHelpers")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "ManufacturingTags", funcName)
end

local ManufacturingTags = setmetatable({}, {__index = DataTable})
ManufacturingTags.__index = ManufacturingTags

function ManufacturingTags.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, ManufacturingTags)
    return self
end

---@param data FGameplayTagTableRow
function ManufacturingTags:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        Tag = Parser.ToJson(data.Tag, lib),
        DevComment = Parser.ToJson(data.DevComment, lib)
    }
end

function ManufacturingTags:AddRow(name, data)
    ---@class FGameplayTagTableRow
    local rowData = {
        Tag = UEHelpers.FindOrAddFName(data["Tag"]),
        DevComment = data["DevComment"]
    }

    self.__table:AddRow(name, rowData)
    Log(string.format("Added row %s\n", name), "AddRow")
end

function ManufacturingTags:ReplaceRow(name, data)
    self:AddRow(name, data)
    Log(string.format("Replaced row %s\n", name), "ReplaceRow")
end

return ManufacturingTags
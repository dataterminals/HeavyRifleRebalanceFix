local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "ManufacturingGroups", funcName)
end

local ManufacturingGroups = setmetatable({}, {__index = DataTable})
ManufacturingGroups.__index = ManufacturingGroups

function ManufacturingGroups.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, ManufacturingGroups)
    return self
end

---@param data FManufactoringGroups
function ManufacturingGroups:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        ManufactoringGroupName = Parser.ToJson(data.ManufactoringGroupName, lib),
        ManufactoringGroupSubtext = Parser.ToJson(data.ManufactoringGroupSubtext, lib),
        ManufactoringGroupIcon = Parser.ToJson(data.ManufactoringGroupIcon, lib),
        ManufactoringGroupDetailsText = Parser.ToJson(data.ManufactoringGroupDetailsText, lib),
        ManufactoringDetailsGroupIcon = Parser.ToJson(data.ManufactoringDetailsGroupIcon, lib),
        ManufactoringRecipies = Parser.ToJson(data.ManufactoringRecipies, lib),
        FilterTag = Parser.ToJson(data.FilterTag, lib)
    }
end

function ManufacturingGroups:AddRow(name, data)
    ---@class FManufactoringGroups
    local rowData = {
        ManufactoringGroupName = data["ManufactoringGroupName"],
        ManufactoringGroupSubtext = data["ManufactoringGroupSubtext"],
        ManufactoringGroupIcon = data["ManufactoringGroupIcon"],
        ManufactoringGroupDetailsText = data["ManufactoringGroupDetailsText"],
        ManufactoringDetailsGroupIcon = data["ManufactoringDetailsGroupIcon"],
        ManufactoringRecipies = data["ManufactoringRecipies"],
        FilterTag = data["FilterTag"]
    }

    local success = pcall(function() AddDataTableRow("ManufacturingGroups", name, rowData) end)
    if not success then
        Log(string.format("Failed to add row %s\n", name), "AddRow")
    else
        Log(string.format("Added row %s\n", name), "AddRow")
    end
end

return ManufacturingGroups
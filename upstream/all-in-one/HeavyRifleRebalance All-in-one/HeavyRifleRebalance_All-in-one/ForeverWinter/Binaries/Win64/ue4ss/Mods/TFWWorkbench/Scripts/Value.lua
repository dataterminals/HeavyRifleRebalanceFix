--[[
This module implements a different interface to support multiple distinct
instances of a "handler". For each individual value data table.
It's probably better to refactor all the other data table modules to follow
the abstraction that this modules implements.
]]
local DataTable = require("DataTable")
local json = require("json")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "Value", funcName)
end

local Value = setmetatable({}, {__index = DataTable})
Value.__index = Value

function Value.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, Value)
    return self
end

---@param data FValueOverride
function Value:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        ValueType = Parser.ToJson(data.ValueType, lib),
        Value = Parser.ToJson(data.Value, lib),
        ExtractionExperienceValue = Parser.ToJson(data.ExtractionExperienceValue, lib)
    }
end

function Value:ToFValueOverride(data)
    return {
        ValueType = data["ValueType"],
        Value = data["Value"],
        ExtractionExperienceValue = data["ExtractionExperienceValue"]
    }
end

function Value:AddRow(name, data)
    self.__table:AddRow(name, self:ToFValueOverride(data))

    Log(string.format("Added row %s\n", name), "AddRow")
end

return Value

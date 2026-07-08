local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "ManufacturingRecipes", funcName)
end

local ManufacturingRecipes = setmetatable({}, {__index = DataTable})
ManufacturingRecipes.__index = ManufacturingRecipes

function ManufacturingRecipes.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, ManufacturingRecipes)
    return self
end

---@param data FManufactoringRecipies
function ManufacturingRecipes:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        UsedComponents = Parser.ToJson(data.UsedComponents, lib),
        CreatedItems = Parser.ToJson(data.CreatedItems, lib),
        RecipyName = Parser.ToJson(data.RecipyName, lib),
        RecipyTag = Parser.ToJson(data.RecipyTag, lib),
        RecipyGroupTag = Parser.ToJson(data.RecipyGroupTag, lib),
        RequiredTags = Parser.ToJson(data.RequiredTags, lib),
        RecipyCraftTime = Parser.ToJson(data.RecipyCraftTime, lib)
    }
end

function ManufacturingRecipes:AddRow(name, data)
    ---@class FManufactoringRecipies
    local rowData = {
        UsedComponents = data["UsedComponents"],
        CreatedItems = data["CreatedItems"],
        RecipyName = data["RecipyName"],
        RecipyTag = data["RecipyTag"],
        RecipyGroupTag = data["RecipyGroupTag"],
        RequiredTags = data["RequiredTags"],
        -- Row needs to be first added to the table. After that we can modify it.
        -- Timespan is fairly tricky and attempts to add it via c++ can lead to
        -- the game crashing when reading that recipe.
        --RecipyCraftTime = data["RecipyCraftTime"]
    }

    AddDataTableRow("ManufacturingRecipes", name, rowData)
    local row = self.__table:FindRow(name)
    if row and data["RecipyCraftTime"] then
        row.RecipyCraftTime = data["RecipyCraftTime"]
    end

    Log(string.format("Added row %s\n", name), "AddRow")
end

return ManufacturingRecipes
--[[
A module to manage rows in the `DT_ItemTags` data table
]]
local DataTable = require("DataTable")
local DataTableParser = require("DataTableParser")
local Utils = require("utils")

local function Log(message, funcName)
    Utils.Log(message, "ItemTags", funcName)
end

local ItemTags = setmetatable({}, {__index = DataTable})
ItemTags.__index = ItemTags

function ItemTags.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, ItemTags)
    return self
end

---@param data FGameplayTagTableRow
---@return table
function ItemTags:ParseRowData(data)
    local kismetLib = DataTable.__kismetlib
    return {
        Tag = DataTableParser.ToJson(data.Tag, kismetLib),
        DevComment = DataTableParser.ToJson(data.DevComment, kismetLib)
    }
end

function ItemTags:AddRow(itemTag)
    self.__table:AddRow(itemTag, { Tag = FName(itemTag, EFindName.FNAME_Add), DevComment = "" })
    Log(string.format("Added row %s\n", itemTag), "AddRow")
end

--NOTE: Not sure if we should really have that. I guess it could come in handy eventually. To redirect
--the game to another item instead of the original.
function ItemTags:ReplaceRow(itemTag, tagData)
    self.__table:AddRow(
        itemTag,
        { Tag = FName(tagData.Tag, EFindName.FNAME_Add), DevComment = tagData.DevComment })
    Log(string.format("Modifed row %s - %s\n", itemTag, Utils.PrintTable(tagData)), "ReplaceRow")
end

function ItemTags:RemoveRow(itemTag)
    self.__table:RemoveRow(itemTag)
    Log(string.format("Removed row %s\n", itemTag), "RemoveRow")
end


return ItemTags

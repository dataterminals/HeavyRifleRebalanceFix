--[[
A module that manages the concept of an in-game item. Meaning it adds it to
the `ItemDetailsData` data table. As well as `DT_ItemTags` and `DT_TagToRowHandle`.
In order to make the item available to other game systems. Like Vendors and Crafting.
]]
local Settings = require("Settings")
local Utils = require("utils")

local function GetParentTag(itemData)
    local parentTag = itemData["ItemSubtype"]["ParentTags"][1]["TagName"]
    if type(parentTag) == "string" then
        return parentTag
    else
        --Handling the case where itemData isn't already parsed for json encoding
        local success, result = pcall(function() return parentTag:ToString() end)
        if success and result then
            return result
        end
    end
end

local function MakeItemTag(itemRowName, itemData)
    return string.format("Inventory.%s.%s", GetParentTag(itemData), itemRowName)
end

local function AddItems(items, itemDetailsDataHandler, itemTagsHandler, tagToRowHandleHandler)
    for _, item in ipairs(items) do
        Utils.Log(string.format("Adding item: %s\n", item["Name"]), "Items", "AddItems")
        itemDetailsDataHandler:AddRow(item["Name"], item["Data"])

        local itemTag = MakeItemTag(item["Name"], item["Data"])
        itemTagsHandler:AddRow(itemTag)

        local itemType = {
            Name = item["Name"],
            DataType = GetParentTag(item["Data"]),
            DataTable = Settings.DataTableClassNames.ItemDetailsData
        }
        tagToRowHandleHandler:AddRow(itemTag, itemType)
    end
end

local function RemoveItems(items, itemDetailsDataHandler, itemTagsHandler, tagToRowHandleHandler)
    for _, item in ipairs(items) do
        local itemData = itemDetailsDataHandler.__table:FindRow(item["Name"])
        if itemData then
            Utils.Log(string.format("Removing item: %s\n", item["Name"]), "Items", "RemoveItems")

            local itemTag = MakeItemTag(item["Name"], itemData)
            itemDetailsDataHandler:RemoveRow(item["Name"])
            itemTagsHandler:RemoveRow(itemTag)
            tagToRowHandleHandler:RemoveRow(itemTag)
        end
    end
end

return {
    --    Add = Add,
    AddItems = AddItems,
    RemoveItems = RemoveItems
}

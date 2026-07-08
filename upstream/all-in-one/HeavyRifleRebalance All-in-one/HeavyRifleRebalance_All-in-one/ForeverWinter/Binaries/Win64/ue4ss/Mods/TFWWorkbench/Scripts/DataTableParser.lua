local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "DataTableParser", funcName)
end

local EItemCategory = {
    Loot = 0,
    Weapon = 1,
    Ammo = 2,
    MedicalSupplies = 3,
    General = 4,
    Dangle = 5,
    EItemCategory_MAX = 6,
}

local function ToJsonEItemCategory(itemCategory)
    local categories = {
        [0] = "Loot",
        [1] = "Weapon",
        [2] = "Ammo",
        [3] = "MedicalSupplies",
        [4] = "General",
        [5] = "Dangle",
        [6] = "EItemCategory_Max"
    }
    Log(string.format("ItemType: %s - %d\n", categories[itemCategory], itemCategory), "ToJsonEItemCategory")
    return categories[itemCategory]
end

local TacCamColours = {
    Default = 0,
    Green = 1,
    Red = 2,
    Yellow = 3,
    TacCamColours_MAX = 4
}

local function ToJsonTacCamHighlight(tacCamColor)
    local colors = {
        [0] = "Default",
        [1] = "Green",
        [2] = "Red",
        [3] = "Yellow",
        [4] = "TacCamColours_Max"
    }
    Log(string.format("TacCamHighlight: %s - %d\n", colors[tacCamColor], tacCamColor), "ToJsonTacCamHighlight")
    return colors[tacCamColor]
end

local function ToJson(value, kismetLib)
    -- That needs to be refactored, because this ToJson function will be pulled out into
    -- a dedicated modules for common parsing functionality
    if value == nil then
        Log("value == nil", "ToJson")
        return nil
    end

    local valueType = type(value)

    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        Log(string.format("non-custom type: %s\n", valueType), "ToJson")
        return value
    elseif valueType == "userdata" then
        local str = tostring(value)
        Log(string.format("userdata type: %s\n", str), "ToJson")

        if str:match("TSoftClassPtr") then
            local success, result = pcall(function()
                return kismetLib:Conv_SoftClassReferenceToString(value)
            end)
            if success then
                Log(string.format("TSoftClassPtr: %s\n", result:ToString()), "ToJson")
            end
        elseif str:match("TSoftObjectPtr") then
            local success, result = pcall(function()
                return kismetLib:Conv_SoftObjectReferenceToString(value)
            end)
            if success then
                Log(string.format("TSoftObjectPtr: %s\n", result:ToString()), "ToJson")
                return result:ToString()
            end
        elseif str:match("UScriptStruct") then
            local result = {}
            value:ForEachProperty(function(property)
                local propertyName = property:GetFName():ToString()
                Log(string.format("UScriptStruct Property: %s\n", propertyName), "ToJson")
                result[propertyName] = ToJson(value[propertyName], kismetLib)
            end)
            return result
        elseif str:match("TArray") then
            local result = {}
            value:ForEach(function(index, element)
                result[index] = ToJson(element:get(), kismetLib)
                Log(string.format("TArray: %d - %s\n", index, tostring(result[index])), "ToJson")
            end)
            return result
        elseif str:match("TMap") then
            local result = {}
            value:ForEach(function(key, value)
                local k = key:get():ToString()
                result[k] = ToJson(value:get(), kismetLib)
                Log(string.format("TMap: %s - %s\n", k, value:get()))
            end)
            return result
        elseif str:match("UDataTable") then
            Log(string.format("UDataTable: %s\n", string.match(value:GetFullName(), "^DataTable%s+(.*)")), "ToJson")
            return string.match(value:GetFullName(), "^DataTable%s+(.*)")
        end

        --- Try ToString method for FName, FText, and FString
        local success, result = pcall(function() return value:ToString() end)
        if success and result then
            Log(string.format("ToString(): %s\n", result), "ToJson")
            return result
        end
    end
end

return {
    EItemCategory = EItemCategory,
    TacCamColours = TacCamColours,
    ToJson = ToJson,
    ToJsonEItemCategory = ToJsonEItemCategory,
    ToJsonTacCamHighlight = ToJsonTacCamHighlight
}
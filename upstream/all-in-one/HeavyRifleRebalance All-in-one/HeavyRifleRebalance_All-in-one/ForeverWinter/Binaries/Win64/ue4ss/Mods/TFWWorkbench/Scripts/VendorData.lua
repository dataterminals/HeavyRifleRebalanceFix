local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "VendorData", funcName)
end

local VendorData = setmetatable({}, {__index = DataTable})
VendorData.__index = VendorData

function VendorData.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, VendorData)
    return self
end

---@param data FFWVendorData
function VendorData:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        VendorDetails = Parser.ToJson(data.VendorDetails, lib),
        ResaleMultiplier = Parser.ToJson(data.ResaleMultiplier, lib),
        CurrenciesUsed = Parser.ToJson(data.CurrenciesUsed, lib),
        MapedItemsSold = Parser.ToJson(data.MapedItemsSold, lib),
        MapedWeaponsSold = Parser.ToJson(data.MapedWeaponsSold, lib),
        MapedRigsSold = Parser.ToJson(data.MapedRigsSold, lib),
        MapedContainersSold = Parser.ToJson(data.MapedContainersSold, lib),
        MapedFramesSold = Parser.ToJson(data.MapedFramesSold, lib),
        MapedDangliesSold = Parser.ToJson(data.MapedDangliesSold, lib),
        MapedBuddiesSold = Parser.ToJson(data.MapedBuddiesSold, lib),
        DevaultVendorCategory = Parser.ToJson(data.DevaultVendorCategory, lib),
        DefaultVendorSubfilter = Parser.ToJson(data.DefaultVendorSubfilter, lib),
        DefaultPlayerCategory = Parser.ToJson(data.DefaultPlayerCategory, lib),
        DefaultPlayerSubfilter = Parser.ToJson(data.DefaultPlayerSubfilter, lib)
    }
end

function VendorData:AddRow(name, data)
    ---@class FWWVendorData
    local rowData = {
        VendorDetails = data["VendorDetails"],
        ResaleMultiplier = data["ResaleMultiplier"],
        CurrenciesUsed = data["CurrenciesUsed"],
        MapedItemsSold = data["MapedItemsSold"],
        MapedWeaponsSold = data["MapedWeaponsSold"],
        MapedRigsSold = data["MapedRigsSold"],
        MapedContainersSold = data["MapedContainersSold"],
        MapedFramesSold = data["MapedFramesSold"],
        MapedDangliesSold = data["MapedDangliesSold"],
        MapedBuddiesSold = data["MapedBuddiesSold"],
        DevaultVendorCategory = data["DevaultVendorCategory"],
        DefaultVendorSubfilter = data["DefaultVendorSubfilter"],
        DefaultPlayerCategory = data["DefaultPlayerCategory"],
        DefaultPlayerSubfilter = data["DefaultPlayerSubfilter"]
    }

    local success = pcall(function() AddDataTableRow("VendorData", name, rowData) end)
    if not success then
        Log(string.format("Failed to add row %s\n", name), "AddRow")
    else
        Log(string.format("Added row %s\n", name), "AddRow")
    end
end

return VendorData
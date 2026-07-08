local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "WeaponPartStatsData", funcName)
end

local WeaponPartStatsData = setmetatable({}, {__index = DataTable})
WeaponPartStatsData.__index = WeaponPartStatsData

function WeaponPartStatsData.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, WeaponPartStatsData)
    return self
end

---@param data FFWModifiedStatsPart
function WeaponPartStatsData:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        MagazineCapacity = Parser.ToJson(data.MagazineCapacity, lib),
        IsSuppressed = Parser.ToJson(data.IsSuppressed, lib),
        SuppressorVallue = Parser.ToJson(data.SuppressorVallue, lib),
        IsScoped = Parser.ToJson(data.IsScoped, lib),
        IsSight = Parser.ToJson(data.IsSight, lib),
        FOV = Parser.ToJson(data.FOV, lib),
        FireRate = Parser.ToJson(data.FireRate, lib),
        Stability = Parser.ToJson(data.Stability, lib),
        Accuracy = Parser.ToJson(data.Accuracy, lib),
        RecoilWristRelBuff = Parser.ToJson(data.RecoilWristRelBuff, lib),
        RecoilArmRelBuff = Parser.ToJson(data.RecoilArmRelBuff, lib),
        StabilizeTimeRelBuff = Parser.ToJson(data.StabilizeTimeRelBuff, lib),
        StabilizeScalarRelBuff = Parser.ToJson(data.StabilizeScalarRelBuff, lib),
        ReloadSpeed = Parser.ToJson(data.ReloadSpeed, lib),
        ADSSpeed = Parser.ToJson(data.ADSSpeed, lib),
        Damage = Parser.ToJson(data.Damage, lib),
        SightPartName = Parser.ToJson(data.SightPartName, lib),
        RCVAsSkelMesh = Parser.ToJson(data.RCVAsSkelMesh, lib)
    }
end

function WeaponPartStatsData:AddRow(name, data)
    local success = pcall(function() self.__table:AddRow(name, data) end)
    if not success then
        Log(string.format("Failed to add row %s\n", name), "AddRow")
    else
        Log(string.format("Added row %s\n", name), "AddRow")
    end
end

return WeaponPartStatsData
local DataTable = require("DataTable")
local Parser = require("DataTableParser")
local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "WeaponConfigSetup", funcName)
end

local WeaponConfigSetup = setmetatable({}, { __index = DataTable })
WeaponConfigSetup.__index = WeaponConfigSetup

function WeaponConfigSetup.new(dataTable)
    local self = DataTable.new(dataTable)
    setmetatable(self, WeaponConfigSetup)
    return self
end

local EWPNCaliber = {
    MD1_919 = 0,
    MD1_45 = 1,
    MD1_357 = 2,
    MD1_5AE = 3,
    MD1_57 = 4,
    MD2_12G = 5,
    MD3_545 = 6,
    MD3_556 = 7,
    MD3_762 = 8,
    MD4_308 = 9,
    MD4_306 = 10,
    MD4_54R = 11,
    MD5_57M = 12,
    MD5_50 = 13,
    _40m = 14,
    _473 = 15,
    MD5_130 = 16,
    MD4_300 = 17
}

local function ToJsonEWPNCaliber(wpnCaliber)
    local wpnCalibers = {
        [0] = "MD1_919",
        [1] = "MD1_45",
        [2] = "MD1_357",
        [3] = "MD1_5AE",
        [4] = "MD1_57",
        [5] = "MD2_12G",
        [6] = "MD3_545",
        [7] = "MD3_556",
        [8] = "MD3_762",
        [9] = "MD4_308",
        [10] = "MD4_306",
        [11] = "MD4_54R",
        [12] = "MD5_57M",
        [13] = "MD5_50",
        [14] = "_40m",
        [15] = "_473",
        [16] = "MD5_130",
        [17] = "MD4_300",
    }
    Log(string.format("WPNCaliber: %s - %d\n", wpnCalibers[wpnCaliber], wpnCaliber), "ToJsonEWPNCaliber")
    return wpnCalibers[wpnCaliber]
end

---@param data FFWWPNConfigSetup
function WeaponConfigSetup:ParseRowData(data)
    local lib = self.__kismetlib
    return {
        NotesRemarks = Parser.ToJson(data.NotesRemarks, lib),
        Caliber = ToJsonEWPNCaliber(data.Caliber),
        SKMesh = Parser.ToJson(data.SKMesh, lib),
        RCV = Parser.ToJson(data.RCV, lib),
        AMO = Parser.ToJson(data.AMO, lib),
        BCG = Parser.ToJson(data.BCG, lib),
        BLR = Parser.ToJson(data.BLR, lib),
        BLT = Parser.ToJson(data.BLT, lib),
        BPD = Parser.ToJson(data.BPD, lib),
        BPDFLD = Parser.ToJson(data.BPDFLD, lib),
        BRL = Parser.ToJson(data.BRL, lib),
        BYT = Parser.ToJson(data.BYT, lib),
        CAR = Parser.ToJson(data.CAR, lib),
        CHG = Parser.ToJson(data.CHG, lib),
        CHGEND = Parser.ToJson(data.CHGEND, lib),
        FMS = Parser.ToJson(data.FMS, lib),
        FRS = Parser.ToJson(data.FRS, lib),
        GAS = Parser.ToJson(data.GAS, lib),
        HDL = Parser.ToJson(data.HDL, lib),
        HGD = Parser.ToJson(data.HGD, lib),
        HGDCHG = Parser.ToJson(data.HGDCHG, lib),
        HMR = Parser.ToJson(data.HMR, lib),
        MAG = Parser.ToJson(data.MAG, lib),
        PGR = Parser.ToJson(data.PGR, lib),
        res = Parser.ToJson(data.res, lib),
        RLS = Parser.ToJson(data.RLS, lib),
        ROD = Parser.ToJson(data.ROD, lib),
        SLR = Parser.ToJson(data.SLR, lib),
        STK = Parser.ToJson(data.STK, lib),
        STKExtractable = Parser.ToJson(data.STKExtractable, lib),
        STKFoldable = Parser.ToJson(data.STKFoldable, lib),
        STKEND = Parser.ToJson(data.STKEND, lib),
        STKFLD = Parser.ToJson(data.STKFLD, lib),
        TRG = Parser.ToJson(data.TRG, lib),
        UPP = Parser.ToJson(data.UPP, lib),
        UPPEPC = Parser.ToJson(data.UPPEPC, lib),
        UPPLENS = Parser.ToJson(data.UPPLENS, lib),
    }
end

function WeaponConfigSetup:AddRow(name, data)
    ---@class FFWWPNConfigSetup
    local rowData = {
        NotesRemarks = data["NotesRemarks"],
        Caliber = EWPNCaliber[data["Caliber"]],
        SKMesh = data["SKMesh"],
        RCV = data["RCV"],
        AMO = data["AMO"],
        BCG = data["BCG"],
        BLR = data["BLR"],
        BLT = data["BLT"],
        BPD = data["BPD"],
        BPDFLD = data["BPDFLD"],
        BRL = data["BRL"],
        BYT = data["BYT"],
        CAR = data["CAR"],
        CHG = data["CHG"],
        CHGEND = data["CHGEND"],
        FMS = data["FMS"],
        FRS = data["FRS"],
        GAS = data["GAS"],
        HDL = data["HDL"],
        HGD = data["HGD"],
        HGDCHG = data["HGDCHG"],
        HMR = data["HMR"],
        MAG = data["MAG"],
        PGR = data["PGR"],
        res = data["res"],
        RLS = data["RLS"],
        ROD = data["ROD"],
        SLR = data["SLR"],
        STK = data["STK"],
        STKExtractable = data["STKExtractable"],
        STKFoldable = data["STKFoldable"],
        STKEND = data["STKEND"],
        STKFLD = data["STKFLD"],
        TRG = data["TRG"],
        UPP = data["UPP"],
        UPPEPC = data["UPPEPC"],
        UPPLENS = data["UPPLENS"],
    }

    local success = pcall(function() AddDataTableRow("WeaponConfigSetup", name, rowData) end)
    if not success then
        Log(string.format("Failed to add row %s\n", name), "AddRow")
    else
        Log(string.format("Added row %s\n", name), "AddRow")
    end
end

return WeaponConfigSetup

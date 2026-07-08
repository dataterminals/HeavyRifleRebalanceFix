--- Global settings and configuration for TFWData mod
--- This module provides centralized configuration for debug flags and data table paths
--- 
--- TODO: See if it makes sense to remove the duplicated data table names/paths

local Settings = {}

-- Data table class names/paths
Settings.DataTableClassNames = {
    ItemDetailsData = "/Game/Blueprints/Data/ItemDetailsData.ItemDetailsData",
    ItemTags = "/Game/Blueprints/Data/DataReference/DT_ItemTags.DT_ItemTags",
    ManufacturingGroups = "/Game/FW/UI/Manufactoring/Data/DT_ManufactoringGroups.DT_ManufactoringGroups",
    ManufacturingRecipes = "/Game/FW/UI/Manufactoring/Data/DT_ManufactoringRecipies.DT_ManufactoringRecipies",
    ManufacturingTags = "/Game/FW/UI/Manufactoring/Data/DT_ManufactoringTags.DT_ManufactoringTags",
    TagToRowHandle = "/Game/Blueprints/Data/DataReference/DT_TagToRowHandle.DT_TagToRowHandle",
    VendorData = "/Game/Blueprints/Data/VendorDataTable.VendorDataTable",
    WeaponConfigSetup = "/Game/WPN_Weapons/WPN_ConfigTool/Setup/WPN/DT_WPN_Config_Setup.DT_WPN_Config_Setup",
    WeaponsDetailsData = "/Game/Blueprints/Data/WeaponsDetailsData.WeaponsDetailsData",
    WeaponPartStatsData = "/Game/FW/Weapons/Customizer/WeaponPartStatsData.WeaponPartStatsData"
}
Settings.ValueTables = {
    "/Game/Blueprints/Data/Value/LEGACY_ItemValueOverrideData.LEGACY_ItemValueOverrideData",
    "/Game/Blueprints/Data/Value/ValueV2_AMMO.ValueV2_AMMO",
    "/Game/Blueprints/Data/Value/ValueV2_Ingredients.ValueV2_Ingredients",
    "/Game/Blueprints/Data/Value/ValueV2_Junk.ValueV2_Junk",
    "/Game/Blueprints/Data/Value/ValueV2_RareLoot.ValueV2_RareLoot",
    "/Game/Blueprints/Data/Value/ValueV2_RIGEQUIPMENT.ValueV2_RIGEQUIPMENT",
    "/Game/Blueprints/Data/Value/ValueV2_RIGS.ValueV2_RIGS",
    "/Game/Blueprints/Data/Value/ValueV2_WEAPONS_DROPPED.ValueV2_WEAPONS_DROPPED",
    "/Game/Blueprints/Data/Value/ValueV2_WEAPONS_PARTS.ValueV2_WEAPONS_PARTS",
    "/Game/Blueprints/Data/Value/ValueV2_WEAPONS.ValueV2_WEAPONS"
}

-- Required data of data tables who need to call the AddDataTableRow of the mod's DLL
Settings.DataTables = {
    InventoryItemDetails = {
        Path = "/Game/Blueprints/Data/ItemDetailsData.ItemDetailsData"
    },
    ManufacturingGroups = {
        Path = "/Game/FW/UI/Manufactoring/Data/DT_ManufactoringGroups.DT_ManufactoringGroups"
    },
    ManufacturingRecipes = {
        Path = "/Game/FW/UI/Manufactoring/Data/DT_ManufactoringRecipies.DT_ManufactoringRecipies"
    },
    VendorData = {
        Path = "/Game/Blueprints/Data/VendorDataTable.VendorDataTable"
    },
    WeaponsDetailsData = {
        Path = "/Game/Blueprints/Data/WeaponsDetailsData.WeaponsDetailsData"
    },
    WeaponConfigSetup = {
        Path = "/Game/WPN_Weapons/WPN_ConfigTool/Setup/WPN/DT_WPN_Config_Setup.DT_WPN_Config_Setup"
    }
}

Settings.ModChildDirs = {
    DataTable = {
        "Item",
        "ItemValue",
        "CraftingRecipe",
        "CraftingGroup",
        "VendorData",
        "WeaponsDetailsData",
        "WeaponPartStatsData",
        "Dumps"
    }
}

return Settings

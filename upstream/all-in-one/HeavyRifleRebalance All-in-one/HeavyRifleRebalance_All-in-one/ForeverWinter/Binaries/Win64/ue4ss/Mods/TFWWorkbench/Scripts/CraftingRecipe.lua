local Utils = require("utils")


local function Log(message, funcName)
    Utils.Log(message, "CraftingRecipe", funcName)
end

local function AddRecipes(recipes, recipesHandler, tagHandler)
    for _, recipe in ipairs(recipes) do
        Log(string.format("Adding recipe: %s\n", recipe["Name"]), "AddRecipes")

        recipesHandler:AddRow(recipe["Name"], recipe["Data"])
        tagHandler:AddRow(
            recipe["Data"]["RecipyTag"]["TagName"],
            { Tag = recipe["Data"]["RecipyTag"]["TagName"], DevComment = "" })
    end
end

return {
    AddRecipes = AddRecipes
}
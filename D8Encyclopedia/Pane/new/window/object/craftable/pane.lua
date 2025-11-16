require "/D8Encyclopedia/Pane/new/window/base.lua"

local recipeTimer = 0
function update(dt)
    if recipeTimer > 0 then 
        recipeTimer = recipeTimer - dt
    else
        recipeTimer = 0.25
        updateRecipe()
    end
end

function updateRecipe()
    local recipe = config.getParameter("recipe")
    local recipeTemp = config.getParameter("recipePart", {})
    if recipe then
        if type(recipe) == "string" then recipe = root.assetJson(recipe) end
        local drawable = prepareItemList(recipe, recipe.matchInputParameters, true)
        --sb.logInfo("drawable %s", drawable)
        widget.removeAllChildren("labelLayout.recipeScrollArea.layout")
        for i, d in pairs(drawable or {}) do 
            local newPart = copy(recipeTemp)
            --[[
                {
                    itemName d.text = nil,
                    itemIcon d.iconDrawable = nil,
                    itemBack d.backImage = nil,
                    itemRarity d.rarity = nil,
                    count d.count = nil
                }
            --]]
            if type(d.iconDrawable) == "string" then
                newPart.children.itemIcon.file = d.iconDrawable
            else
                newPart.children.itemIcon.drawables = d.iconDrawable
            end

            if d.backImage then
                if type(d.backImage) == "string" then
                    newPart.children.itemBack.file = d.backImage
                else
                    newPart.children.itemBack.drawable = d.backImage
                end
            end
            newPart.children.itemRarity.file = d.rarity
            newPart.children.itemName.value = d.text
            if d.count ~= "" then
                newPart.children.count.value = d.count
            end
            
            newPart.rect[2] = newPart.rect[2] + (21 * (#drawable - (i)))
            newPart.rect[4] = newPart.rect[4] + (21 * (#drawable - (i)))
            widget.addChild("labelLayout.recipeScrollArea.layout", newPart, i)
            local prevSize = widget.getSize("labelLayout.recipeScrollArea.layout")
            widget.setSize("labelLayout.recipeScrollArea.layout", {prevSize[1], 21 * #drawable})
        end
    else
        widget.setVisible("labelLayout.recipeScrollArea", false)
    end
end
--
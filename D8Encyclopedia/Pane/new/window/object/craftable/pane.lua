require "/D8Encyclopedia/Pane/new/window/base.lua"
local _update = update
local recipeStorage = false
local recipeTimer = 0
function update(dt)
    _update(dt)
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
    if not recipeStorage then
        if type(recipe) == "string" then
            if string.find(recipe, "[.]recipe") then
                recipe = root.assetJson(recipe)
            elseif string.find(recipe, "[:]") then
                -- item:arcana_crafting_main_1:upgradeStages.1.interactData.upgradeMaterials
                local segments = segmentPath(recipe)
                local type = segments[1]
                local itemName = segments[2]
                local path = {} 
                for i=3, #segments do
                    table.insert(path, segments[i])
                end
                local itemCfg = (root.itemConfig(itemName) or {}).config
                if not itemCfg then return end
                local itemList = pathUp(itemCfg, path)
                recipe = {
                    input = itemList
                }
            else
                recipe = root.assetJson(recipe)
            end
        end
    else
        recipe = copy(recipeStorage)
    end
    if recipe then
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
        if not recipeStorage then recipeStorage = copy(recipe) end
    else
        widget.setVisible("labelLayout.recipeScrollArea", false)
        recipeStorage = false
    end
end
--

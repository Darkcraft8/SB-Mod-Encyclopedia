require "/scripts/util.lua"
require "/scripts/vec2.lua"

close = function()
    pane.dismiss()
end

prepareItemList = function(items, matchInputParameters, recipeTooltip)
    local template = {
        text = nil,
        iconDrawable = nil,
        backImage = nil,
        rarity = nil,
        count = nil
    }
    local itemListChild = {}
    local currencyInputs = {}
    local itemName = function(itemDescriptor)
        if type(itemDescriptor) == "string" then return itemDescriptor end
        return itemDescriptor.item or itemDescriptor.name or itemDescriptor.itemName or itemDescriptor[1]
    end

    if items.input then
        if not currenciesConfig then currenciesConfig = root.assetJson("/currencies.config") end
        currencyInputs = copy(items.currencyInputs or {})
        items = copy(items.input or {})
        for currency, amount in pairs(currencyInputs) do 
            local representativeItem = currenciesConfig[currency]["representativeItem"]
            local added = false
            for index, descriptor in pairs(items or {}) do
                if itemName(descriptor) == representativeItem then
                    added = true
                    items[index] = {
                        name = itemName(descriptor),
                        count = (descriptor.count or descriptor[2]) + amount,
                        parameters = descriptor.parameters or descriptor[3]
                    }
                    break
                end
            end
            if not added then
                table.insert(items, {
                    name = currency,
                    count = amount,
                    priority = 1
                })
            end
        end
        table.sort(items, function(a, b)
            return (a.priority or 0) > (b.priority or 0)
        end)
    end

    for index, descriptor in pairs(items or {}) do
        if itemName(descriptor) then
            local newItem = copy(template)
            local cfg = root.itemConfig(descriptor)
            local configParameter = function(paramName, defaultValue)
                return cfg.parameters[paramName] or cfg.config[paramName] or defaultValue
            end
            local itemCount = 1
            local inventoryIcon = configParameter("inventoryIcon") or configParameter("codexIcon")
            if type(descriptor) == "table" then
                local itemName = itemName(descriptor)
                if not itemName then sb.logInfo("itemName not found for %s", descriptor) end
                itemCount = descriptor.count or descriptor[2] or 1
            end
            
            newItem.text = configParameter("shortdescription")
            newItem.rarity = string.format("/interface/inventory/itemborder%s.png", string.lower(cfg.parameters.rarity or cfg.config.rarity))
            newItem.iconDrawable = configParameter("inventoryIcon") or configParameter("codexIcon")
            local colorOptions = configParameter("colorOptions")
            local colorDirective = ""
            if colorOptions then
                colorDirective = "?replace"
                for a, b in pairs(colorOptions[configParameter("colorIndex", 1)]) do 
                    colorDirective = colorDirective .. "=" .. a .. ";" .. b
                end
            end

            if type(inventoryIcon) == "table" then
                local temp = copy(inventoryIcon)
                for index, icon in pairs(temp or {}) do 
                    if (string.find(icon["image"], "/") == 1) then
                        temp[index]["image"] = icon["image"]
                    else -- isn't absolute
                        temp[index]["image"] = cfg.directory .. icon["image"]
                    end
                    if colorOptions then
                        temp[index]["image"] = temp[index]["image"] .. colorDirective
                    end
                end
                newItem.iconDrawable = temp
            else
                if (string.find(inventoryIcon, "/") == 1) then
                    newItem.iconDrawable = inventoryIcon
                else -- isn't absolute
                    newItem.iconDrawable = cfg.directory .. inventoryIcon
                end
                
                if colorOptions then
                    newItem.iconDrawable = newItem.iconDrawable .. colorDirective
                end
            end
            
            if itemCount > 0 then
                if recipeTooltip then
                    local itemPlayerCount = 0
                    if type(descriptor) == "table" then
                        itemPlayerCount = player.hasCountOfItem({
                            name = itemName(descriptor),
                            count = 1,
                            parameters = cfg.parameters
                        }, matchInputParameters)
                    else
                        itemPlayerCount = player.hasCountOfItem(descriptor, matchInputParameters)  
                    end
                    if itemPlayerCount >= itemCount then
                        newItem.count = "^green;" .. itemPlayerCount .. "/" .. itemCount
                    else
                        newItem.count = "^red;" .. itemPlayerCount .. "/" .. itemCount
                    end
                else
                    newItem.count = tostring(itemCount)
                end
            else
                newItem.count = ""
            end
            table.insert(itemListChild, newItem)
        end
    end

    return itemListChild
end

-- I really should put this in d8:shared instead of copy/pasting it
function segmentPath(path)
    local pathSegment = {}
    if string.find(path, "[.:]") then
      while string.find(path, "[.:]") do
        local dotNumber = string.find(path, "[.:]")
        if dotNumber then
            local segment = string.sub(path, 1, dotNumber - 1)
            if not string.find(segment, "[a-z]") then
                segment = tonumber(segment)
            end
            table.insert(pathSegment, segment)
            path = string.sub(path, dotNumber + 1, string.len(path))
        end
      end
    end
    table.insert(pathSegment, path)
    return pathSegment
end

function pathUp(_table, _segmentedPath)
    local currentResult = nil
    for _, string in ipairs(_segmentedPath) do
        if not currentResult then 
            currentResult = _table[string]
        else
            currentResult = currentResult[string]
        end
    end
    if currentResult ~= nil then
        return currentResult
    else
        return defaultValue
    end
end
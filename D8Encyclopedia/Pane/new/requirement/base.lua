jsonHasParameter = function(jsonPathOrTable, ParameterName)
    local jsonCfg = jsonPathOrTable
    if type(jsonCfg) == "string" then jsonCfg = root.assetJson(jsonCfg) end
    if jsonCfg then
        return jsonCfg[ParameterName]
    else
        return false
    end
end

requirement["hasCollected"] = function(args)
    local collectionTable = {}
    for i, collectable in pairs(args or {}) do
        local unlocked = false
        if not collectionTable[collectable[1]] then collectionTable[collectable[1]] = player.collectables(collectable[1]) or {} end
        for _, collectableName in pairs(collectionTable[collectable[1]]) do 
            local inverse = collectable[3]
            if collectableName == collectable[2] then unlocked = not (inverse or false) end
        end
        if not unlocked then return false end
    end
    return true
end

requirement["hasCollectedAny"] = function(args)
    local collectionTable = {}
    for i, collectable in pairs(args or {}) do
        local unlocked = false
        if not collectionTable[collectable[1]] then collectionTable[collectable[1]] = player.collectables(collectable[1]) or {} end
        for _, collectableName in pairs(collectionTable[collectable[1]]) do 
            local inverse = collectable[3]
            if collectableName == collectable[2] then unlocked = not (inverse or false) end
        end
        if unlocked then return true end
    end
    return false
end

requirement["hasCollectablesIn"] = function(args)
    for _, collectableName in ipairs(player.collectables(args) or {}) do
        return not (args.inverse or false)
    end
    return (args.inverse or false)
end
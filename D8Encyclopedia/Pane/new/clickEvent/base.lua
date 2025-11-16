clickEventType["scriptpane"] = function(scriptpane, closeAfterward)
    local paneCfg = scriptpane
    if type(paneCfg) == "string" then
        paneCfg = root.assetJson(paneCfg)
    end

    if type(paneCfg) == "table" then
        player.interact("scriptpane", paneCfg)
    end
    if closeAfterward then pane.dismiss() end
end

clickEventType["prefab"] = function(prefabName, override)
    local prefabList = root.assetJson("/D8Encyclopedia/Pane/new/window/prefabList.json")
    local paneCfg = prefabList[prefabName]
    if not paneCfg then return end
    local _override = override
    if type(paneCfg) == "string" then
        paneCfg = root.assetJson(paneCfg)
    end
    if type(_override) == "string" then
        _override = root.assetJson(_override)
    end
    paneCfg = sb.jsonMerge(paneCfg, _override or {})
    player.interact("scriptpane", paneCfg)
end

clickEventType["quest"] = function(questTemplateName)
    if player.canStartQuest(questTemplateName) then
        player.startQuest(questTemplateName)
    end
end

clickEventType["function"] = function(funcNameOrPath, ...)
    local callback = findCallback(funcNameOrPath)
    if callback then
        pcall(callback, ...)
    end
end

clickEventType["moveCamPos"] = function(_vec2)
    canvasStorage.nextCamPos = vec2.sub(canvasStorage.nextCamPos, _vec2) -- the camera system of the pane use the camPos for the position of the widget
end

clickEventType["setCamPos"] = function(_vec2)
    canvasStorage.nextCamPos = vec2.mul(_vec2, -1)
end

clickEventType["setCategory"] = function(indexOrPath)
    setCategory(indexOrPath)
end

clickEventType["setMusic"] = function(musicPool, transitionSpeed)
    --sb.logInfo("player.id %s, message %s, musicPool %s, transitionSpeed %s", player.id(), "playAltMusic", musicPool or {}, transitionSpeed or 0.25)
    world.sendEntityMessage(player.id(), "playAltMusic", musicPool or {}, transitionSpeed or 0.25)
end

clickEventType["resetMusic"] = function(transitionSpeed)
    world.sendEntityMessage(player.id(), "stopAltMusic", transitionSpeed or 0.25)
end

clickEventType["addCollectable"] = function(collectionName, collectableName)
    if not (collectionName and collectableName) then return end
    world.sendEntityMessage(player.id(), "addCollectable", collectionName, collectableName)
end

clickEventType["testCollectable"] = function(collectionName, collectableName)
    if not (collectionName and collectableName) then return end
    local playerCfg = root.assetJson("/player.config")
    local message = playerCfg.collectableUnlock
    local collection = root.collection(collectionName)
    if not collection then return end
    local collectables = root.collectables(collectionName)
    for _, collectable in pairs(collectables or {}) do 
        if collectable.name == collectableName then
            message = string.gsub(message, "<collectable>", collectable.title)
        end
    end
    message = string.gsub(message, "<collection>", collection.title)
    sb.logInfo("collection message would be : %s", message)
    if not interface.queueMessage then return end
    interface.queueMessage(message)
end
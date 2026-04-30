require "/shared/darkcraft8/canvas/keyboard.lua"
require "/shared/darkcraft8/canvas/logic.lua"
require "/shared/darkcraft8/d8ToolTipUtil/tooltips.lua"

-- Local
	--[[
		The Zoom System Is Very Experimental, there currently misallignement between background elements and btn causing problems
	--]]
    local zoomLinearProgression = function(camSpeed)
        if canvasStorage.camZoom and canvasStorage.nextCamZoom then
            local dist = canvasStorage.camZoom - canvasStorage.nextCamZoom 
            dist = dist * ((camSpeed or 1) * script.updateDt())
            local new = canvasStorage.camZoom - dist
            if (math.abs(dist) < 0.00001) then
                new = canvasStorage.nextCamZoom
            end
            canvasStorage.camZoom = new
        end
    end
    local zoomClickTimer = 0
    local zoomDrag = function()
        local dt = script.updateDt()
        if canvasStorage.dragZoom then
            local center = vec2.mag(vec2.mul(canvas:size(), 0.5))
            if not canvasStorage.dragZoomStartPos then
                zoomClickTimer = 0
                canvasStorage.dragZoomStartPos = canvas:mousePosition()
            end
            local dist = center - vec2.mag(canvas:mousePosition())
            logString["zoomCenterAndMousePos"] = "center : " .. sb.printJson(center or 1) .." mouse : ".. sb.printJson(vec2.mag(canvas:mousePosition()) or 1)
            logString["zoomDist"] = "dist : " .. sb.printJson(dist or 1)
            
            if dist > 0.005 then
                canvasStorage.nextCamZoom = canvasStorage.nextCamZoom + ((dt * math.abs(vec2.mag(canvasStorage.dragZoomStartPos) - vec2.mag(canvas:mousePosition())) ) /5 )
            else
                --canvasStorage.nextCamZoom = math.max(canvasStorage.nextCamZoom - ((dt * math.abs(vec2.mag(canvasStorage.dragZoomStartPos) - vec2.mag(canvas:mousePosition())) ) /5 ), 0)
                canvasStorage.nextCamZoom = canvasStorage.nextCamZoom - ((dt * math.abs(vec2.mag(canvasStorage.dragZoomStartPos) - vec2.mag(canvas:mousePosition())) ) /5 )
            end
            zoomClickTimer = zoomClickTimer + dt
        elseif zoomClickTimer < 0.25 then
            canvasStorage.nextCamZoom = 0
        end
        if not canvasStorage.dragZoom then
            canvasStorage.dragZoomStartPos = nil
            logString["zoomCenterAndMousePos"] = nil
            logString["zoomDist"] = nil
        end
    end
    
    local logString = {}
	local btnTemplate = {
        name = "setIndex",
        callback = "buttonEvent",
        image = {
            base = "/assetmissing.png",
            hover = "/assetmissing.png",
            press = "/assetmissing.png"
        },
        sounds = {
            base = {},
            hover = {},
            press = {}
        },
        position = {0, 0},
        anchor = "center",
        detectArea = {
            -16, 4,
            28, 12
        },

        scale = 1,
        parallax = 0
    }
    local category_background_offset = {-1, -22}
    local categoryHide_offset = {-28, 0}
    local catHideTimer = 0
    local frames = 0
    
    local paneActionTimerDefault = 0.1
    local consLogString = {}
    local emissionTimer = {}
    uptime = 0
    local roundVect = function(_vec2)
        return {util.round(_vec2[1]), util.round(_vec2[2])}
    end
    local requirementCheckTimer = 0
    local requirementCheck = {}
-- Global
    subScript = subScript or {}
    storage = storage or {}
    requirement = requirement or {}
    clickEventType = clickEventType or {}
    renderType = renderType or {} -- handle the rendering of the different background element type... why din't i implemented this earlier ?
    updateFunc = updateFunc or {}
    sizeOffset = nil -- used to move the explorable area of a category
    function init()
        local eS = root.assetJson("/D8Encyclopedia/Pane/new/extraScript.json")
        lang = root.assetJson("/D8Encyclopedia/Pane/new/lang.json")
        for _, scriptPath in pairs(eS) do 
            require(scriptPath)
        end
        D8Tooltip:init()
        storage.canvasTooltip = {}

        canvasStorage.clickCallbacks = {
            "clickEvent"
        }
        canvasStorage.keyCallbacks["zoomIn"] = _ENV["zoom"]
        canvasStorage.keyCallbacks["zoomOut"] = _ENV["zoom"]
        canvasStorage.camZoom = 0
        canvasStorage.nextCamZoom = 0
        canvasStorage.debug = config.getParameter("canvasCfg", {})["debug"]or config.getParameter("debug", false)-- or true
        
        widget.setSliderRange("zoomSlider", 0, 100)
        canvas:bindCanvas("screenCanvas")
        keyboard:updateCurrentBinds()

        loadCategory()
        canvas:clear()
        populateCategoryList()

        canvasPos = widget.getPosition("screenCanvas")
        canvasSize = widget.getSize("screenCanvas")
        categoryPos = widget.getPosition("categoryLayout.category")

        categoryHide_offset[1] = -(widget.getSize("categoryLayout.category")[1] - 9)
        widget.setPosition("categoryLayout.category", vec2.add({categoryPos[1] + categoryHide_offset[1], categoryPos[2] + categoryHide_offset[2]}, category_background_offset))
        widget.setPosition("categoryLayout.category_background", vec2.add({categoryPos[1] + categoryHide_offset[1], categoryPos[2] + categoryHide_offset[2]}, category_background_offset))
        updateCanvasSize()

        updateCategoryPos(script.updateDt(), true, 1.5)
    end

    function update(dt)
        uptime = uptime + dt
        if (paneActionTimer or 0) > 0 then paneActionTimer = (paneActionTimer or 0) - script.updateDt() end
        local show = string.find(widget.getChildAt(storage.mousePosition or {0, 0}) or "null", "category")
        updateCategoryPos(dt, show)
        for funcName, funcData in pairs(updateFunc or {}) do
            if type(funcData) == "function" then
                funcData(dt)
            end
        end
        D8Tooltip:update(dt)
        logString = {}
        render()
        if (storage.btnResetTimer or 0) <= 0 then
            canvasStorage.overredBtn = nil
            canvasStorage.pressedButton = nil
            storage.mousePosition = {0, 0}
            storage.btnResetTimer = 0.1
        else
            storage.btnResetTimer = storage.btnResetTimer - dt
        end
        
        canvas:buttonUpd(dt, false, canvasStorage.camZoom)
        canvas:drawParticles()

        canvas:cameraDrag()
        
        widget.setText("zoomSliderLbl", lang.zoom .. tostring(canvasStorage.nextCamZoom))
        canvas:linearTransitionToNextCamPos(5 - canvasStorage.camZoom)
        zoomLinearProgression()
        --zoomDrag() -- handling zooming in and out using the mouse

        local target = {0, 0}
        --logString["getChildAt"] = "getChildAt : " .. (widget.getChildAt(storage.mousePosition or {0, 0}) or "null")
        local getRelativeCursorPos = function()
            local cursorPos = copy(canvas:mousePosition() or {0, 0})
            local canvasCenter = canvas:anchor("center")

            cursorPos = vec2.sub(cursorPos, canvasCenter)
            cursorPos = vec2.add(cursorPos, vec2.mul(canvasStorage.camPos or {0, 0}, -1))
            
            return cursorPos
        end
        local relativeCursorPos = getRelativeCursorPos()
        logString["cursorPosition"] = lang.camRelativePos .. sb.printJson({util.round(relativeCursorPos[1]), util.round(relativeCursorPos[2])})
        
        if subScript then if subScript["update"] then pcall(subScript["update"], dt) end else subScript = {} end

        storage.mousePosition = {0, 0}

        if requirementCheckTimer <= 0 then
            requirementCheck = {}
            requirementCheckTimer = 2
            populateCategoryList()
        else
            requirementCheckTimer = requirementCheckTimer - dt
        end

        if storage.curCategory then
            local effsize = copy(storage.curCategory.size)
            if not effsize then 
                effsize = {2^16, 2^16}
            end
            if effsize then
                local canvasSize = canvas:size()
                local canvasCenter = canvas:anchor("center")
                logString["canvasSize"] = "canvasSize : " .. sb.printJson(canvasSize)
                logString["canvasCenter"] = "canvasCenter : " .. sb.printJson(canvasCenter)
                if #effsize == 2 then
                    effsize = {
                        -math.abs(effsize[1]),
                        -math.abs(effsize[2]),
                         math.abs(effsize[1]),
                         math.abs(effsize[2])
                    }
                end
                
                if sizeOffset then
                    logString["sizeOffset"] = "size offset : ".. sb.printJson(sizeOffset or {})
                    effsize[1] = effsize[1] + sizeOffset[1]
                    effsize[2] = effsize[2] + sizeOffset[2]
                    effsize[3] = effsize[3] + sizeOffset[1]
                    effsize[4] = effsize[4] + sizeOffset[2]
                end

                local min, max = vec2.mul({effsize[1], effsize[2]}, 0.5), vec2.mul({effsize[3], effsize[4]}, 0.5)
                local minDist, maxDist = {min[1] - (-canvasCenter[1]), min[2] - (-canvasCenter[2])}, {max[1] - canvasCenter[1], max[2] - canvasCenter[2]}

                if minDist[1] == -canvasCenter[1] then minDist[1] = 0 end
                if minDist[2] == -canvasCenter[2] then minDist[2] = 0 end
                if maxDist[1] == canvasCenter[1] then maxDist[1] = 0 end
                if maxDist[2] == canvasCenter[2] then maxDist[2] = 0 end
                

                min, max = vec2.add(min, minDist), vec2.add(max, maxDist)

                canvasStorage.nextCamPos = {
                    util.clamp(canvasStorage.nextCamPos[1], -max[1], -min[1]),
                    util.clamp(canvasStorage.nextCamPos[2], -max[2], -min[2])
                }
                local canvLeftSmaller, canvBottomSmaller, canvRightSmaller, canvTopSmaller = (effsize[1] >= -canvasCenter[1]), (effsize[2] >= -canvasCenter[2]), (effsize[3] <= canvasCenter[1]), (effsize[4] <= canvasCenter[1])
                logString["canvaswindowsizebool"] = "canvas window size bool : " .. string.format("left %s, bottom %s, right %s, top %s", canvLeftSmaller, canvBottomSmaller, canvRightSmaller, canvTopSmaller)
                if canvLeftSmaller and canvRightSmaller then
                    canvasStorage.nextCamPos[1] = (sizeOffset or {})[1] or 0
                    min[1] = 0
                    max[1] = 0
                end
                if canvBottomSmaller and canvTopSmaller then
                    canvasStorage.nextCamPos[2] = (sizeOffset or {})[2] or 0
                    min[2] = 0
                    max[2] = 0
                end
                
                if storage.curCategory.size then
                    logString["mincameraposition"] = "min camera position : "..sb.printJson(min)
                    logString["maxcameraposition"] = "max camera position : "..sb.printJson(max)
                end
            end
        end
        if (canvasStorage.debug or (storage.curCategory or {}).debug) then displayLog() end
    end

    function updateCategoryPos(dt, show, uptime)
		local dt = dt or script.updateDt()
        if show then
            target = vec2.add(categoryPos, category_background_offset)
            catHideTimer = uptime or 0.25
        elseif catHideTimer <= 0 then
            target = vec2.add({categoryPos[1] + categoryHide_offset[1], categoryPos[2] + categoryHide_offset[2]}, category_background_offset)
        else
            catHideTimer = catHideTimer - dt
        end
        if not vec2.eq(widget.getPosition("categoryLayout.category"), target) then
            widget.setPosition("categoryLayout.category", vec2.approach(widget.getPosition("categoryLayout.category"), target, dt * (60 * 4)))
            widget.setPosition("categoryLayout.category_background", vec2.approach(widget.getPosition("categoryLayout.category_background"), target, dt * (60 * 4)))
            if config.getParameter("moveCanvas", true) then updateCanvasSize() end
        end
    end

    function updateCanvasSize()
        if widget.active("categoryLayout") then
            local data = widget.getData("categoryLayout") or {}
            local pos, size = widget.getPosition("categoryLayout.category_background"), vec2.add(widget.getSize("categoryLayout"), (data.scaleOffset or {0,0}))
            local offset = vec2.add(pos, size)
            offset[2] =  0
            widget.setPosition("screenCanvas", vec2.add(canvasPos, offset))
            widget.setSize("screenCanvas", vec2.sub(canvasSize, offset))
        else
            widget.setPosition("screenCanvas", canvasPos)
            widget.setSize("screenCanvas", canvasSize)
        end
    end

    function displayLog()
        logString["camPos"] = "camPos : " .. sb.printJson({util.round(canvasStorage.camPos[1] * -1), util.round(canvasStorage.camPos[2] * -1)}) .. ", nextCamPos : " .. sb.printJson(vec2.mul(canvasStorage.nextCamPos, -1))
        logString["zoom"] =  lang.nextZoom .. sb.printJson(canvasStorage.nextCamZoom or 1) ..", " .. lang.zoom .. sb.printJson((canvasStorage.camZoom or 1))
        local logList = {}
        
        for _, logString in pairs(consLogString or {}) do 
            table.insert(logList, logString)
        end
        for _, logString in pairs(logString or {}) do 
            table.insert(logList, logString)
        end

        table.sort(logList, function(a, b)
            return a < b
        end)
        
        local index = 0
        for _, logString in ipairs(logList or {}) do 
            local offset = vec2.mul({canvas:size()[1] - 6, 5.25}, {1, index})
            offset = vec2.add(offset, {0, 8})
            local textPositioning = {
                position = vec2.sub(canvas:size(), offset),--{0, canvas:size()[2] - 5},
                horizontalAnchor = "left", -- left, mid, right
                verticalAnchor = "top", -- top, mid, bottom
                wrapWidth = nil -- wrap width in pixels or nil
            }
            canvas:drawText(logString, textPositioning, 7, {255, 161, 0})
            index = index + 1
        end
    end

    function uninit()
        if storage.curCategory then
            for _, event in pairs(storage.curCategory.unloadEvent or {}) do 
                local callback = findCallback(event.call)
                if callback then
                    local pR, pM = pcall(callback, table.unpack(event.args))
                    if not pR then
                        sb.logInfo("%s, %s", pR, pM)
                    end
                else
                    sb.logError("Callback %s Couldn't Be Found !", event.call)
                end
            end
        end

        D8Tooltip:uninit()
        widget.setPosition("categoryLayout.category", categoryPos)
        widget.setPosition("screenCanvas", canvasPos)
        widget.setSize("screenCanvas", canvasSize)
    end

    function clickEvent(position, mouseButton, isButtonDown)
        if mouseButton == 0 then -- left
            if subScript.close and isButtonDown then subScript.close() end
            if not widget.active("subPaneRect") then
                if isButtonDown then
                    canvasStorage.dragCam = true
                else
                    canvasStorage.dragCam = false
                end
            end
        elseif mouseButton == 1 then -- middle
            setCategory(1)
        elseif mouseButton == 2 then -- right
            if isButtonDown then
                canvasStorage.dragZoom = true
            else
                canvasStorage.dragZoom = false
            end
        elseif mouseButton == 3 then -- mouse prevPage
        elseif mouseButton == 4 then -- mouse nextPage
        else
            --sb.logInfo("mouseButton == %s", mouseButton)
        end
    end

    function zoom(keyIndex, isDown, bind)
        local dt = script.updateDt()
        if bind == "zoomIn" then
            canvasStorage.nextCamZoom = canvasStorage.nextCamZoom + dt
        elseif bind == "zoomOut" then
            canvasStorage.nextCamZoom = math.max(canvasStorage.nextCamZoom - dt, 0)
        end
    end

    function render()
        canvas:clear()
        frames = frames + (script.updateDt() * 12) % 100000
        if storage.curCategory then
            local cfg = storage.curCategory
            if type(cfg) == "string" then cfg = root.assetJson(cfg) end
            
            local curFrame = math.floor(util.round(frames))
            if cfg.background then
                local backgroundImages = {}
                for backgroundIndex, background in pairs(cfg.background) do
                    if type(backgroundIndex) == "string" and (not background.name) then background.name = backgroundIndex end
                    if background.requires then
                        if shouldShow(background.requires or {}) then
                            table.insert(backgroundImages, background)
                        end
                    else
                        table.insert(backgroundImages, background)
                    end
                    
                end
                table.sort(backgroundImages, function(a, b)
                    local _a, _b = a.parallax or 0, b.parallax or 0
                    if a.zLevel then _a = -a.zLevel end
                    if b.zLevel then _b = -b.zLevel end
                    return _a > _b
                end)
                for backgroundIndex, background in pairs(backgroundImages) do
                    if renderType[string.lower(background.type or "null")] then
                        renderType[string.lower(background.type or "null")](cfg, curFrame, copy(background), backgroundIndex)
                    elseif (not background.type) or string.lower(background.type) == "image" then
                        renderType["image"](cfg, curFrame, copy(background), backgroundIndex)
                        --[[local image = background.image or "/assetmissing.png"
                        image = string.gsub(image, "<frame>", 1 + curFrame % (background.frame or 1))
                        image = string.gsub(image, "<frameIndex>", curFrame % (background.frame or 1))
                        local parallax = background.parallax or 1
                        local offset = background.position
                        if background.anchor then
                            local anchor = canvas:anchor(background.anchor)
                            offset = vec2.add(offset, anchor)
                        end
                        local scale = (background.scale or 1)
                        local color = background.color or {255,255,255}
                        if not background.positionLocked then 
                            offset = canvas:translateFromCamera(offset, canvasStorage.camZoom, parallax)
                            scale = math.max(0, scale + (canvasStorage.camZoom * scale))
                        end
                        local index = "background_" .. backgroundIndex
                        if background.name then index = background.name end
                        if background.tiled then
                            local screenCoords = {
                                    0, 0,
                                    canvas:size()[1], canvas:size()[2]
                            }
                            if canvasStorage.debug_bgImage then logString[index] = string.format("%s, %s, %s, %s, %s", index, sb.printJson(roundVect(offset)), sb.printJson(roundVect(screenCoords)), scale, sb.printJson(color)) end
                            canvas:drawTiledImage(image, offset, screenCoords, scale, color)
                        elseif canvas:isVisible(image, offset, background.centered) then
                            if canvasStorage.debug_bgImage then logString[index] = string.format("%s, %s, %s, %s, %s", index, sb.printJson(roundVect(offset)), scale, sb.printJson(color), background.centered) end
                            canvas:drawImage(image, offset, scale, color, background.centered)
                        end]]
                    end
                end
            end
            if cfg.particleSource then
                local activeParticles = {}
                
                for id, cfg in pairs(cfg.particleSource) do
                    local add = true
                    if cfg.requires then
                        add = not shouldShow(cfg.requires or {})
                    end

                    if add then
                        for _, particles in pairs(cfg.particles or {}) do 
                            if (emissionTimer[id] or 0) <= 0 then
                                emissionTimer[id] = 1 / (cfg.emissionRate or 60)
                                table.insert(activeParticles, particles)
                            else
                                emissionTimer[id] = (emissionTimer[id] or 0) - script.updateDt()
                            end
                        end
                    end

                    local index = "particle_" .. id
                    if canvasStorage.debug_particlesSources then logString[index] = string.format("%s, %s", index, util.round(emissionTimer[id])) end
                end
                canvas:addParticles(activeParticles)
            end
            canvasStorage.btn = canvasStorage.btn or {}
            canvasStorage.btn.btnTable = {}
            storage.canvasTooltip = {}
            local btnList = {}
            for _, btn in pairs(cfg.btn or {}) do
                table.insert(btnList, btn)
            end
            table.sort(btnList, function(a,b)
                return (a.priority or 0) < (b.priority or 0)
            end)
            for _, btn in pairs(btnList or {}) do
                local new = copy(btnTemplate)
                local btn = copy(btn)
                local visible = function(btn) 
                    local image, pos, show
                    local btn = copy(btn)
                    local backImage = (btn.backImage or {}).base
                    local baseImage = btn.base or (btn.image or {}).base
                    if (baseImage and backImage) then
                        if (root.imageSize(baseImage)[1] > root.imageSize(backImage)[1]) or (root.imageSize(baseImage)[2] > root.imageSize(backImage)[2]) then
                            image = baseImage or "/assetmissing.png"
                        else
                            image = backImage or "/assetmissing.png"
                        end
                    else
                        image = baseImage or "/assetmissing.png"
                    end
                    
                    image = string.gsub(image, "<frame>", 1 + curFrame % (btn.frame or 1))
                    image = string.gsub(image, "<frameIndex>", curFrame % (btn.frame or 1))

                    pos = vec2.add(btn.position, canvas:anchor(btn.anchor))
                    pos = canvas:translateFromCamera(pos, (btn.zoom or canvasStorage.camZoom), btn.parallax or 0)

                    show = canvas:isVisible(image, pos, btn.centered)
                    
                    if canvasStorage.debug_btnState then
                        if show and (not btn.positionLocked) then
                            logString[btn.name] = lang.btnInBound .. btn.name .. " at " .. sb.printJson(roundVect(pos)) 
                        elseif (not show) and (not btn.positionLocked) then 
                            logString[btn.name] = lang.outOfBound .. btn.name .. " at " .. sb.printJson(roundVect(pos)) 
                        elseif btn.positionLocked then 
                            logString[btn.name] = lang.disabled .. btn.name .. " at " .. sb.printJson(roundVect(pos)) 
                        end 
                    end
                    return show or btn.positionLocked
                end

                if visible(btn) then
                    local showResult = shouldShow(btn.requires or {})
                    local show = true
                    local backImages = (btn.backImage or {})
                    btn.disabled = not showResult

                    if btn.hideWhenDisabled then
                        if btn.disabled then
                            show = false
                        end
                    end
                    
                    if show then
                        if btn.callback then new.callback = btn.callback end
                        if type(_) == "string" then
                            new.name = _
                        else
                            if btn.name then new.name = btn.name end
                        end
                        if btn.backImage then new.backImage = btn.backImage end
                        if btn.image then
                            new.image = btn.image
                        else
                            if btn.base then new.image.base = btn.base end
                            if btn.hover then new.image.hover = btn.hover end
                            if btn.press then new.image.press = btn.press end
                        end
                        for a, _ in pairs(new.image) do 
                            new.image[a] = string.gsub(new.image[a], "<frame>", 1 + curFrame % (btn.frame or 1))
                            new.image[a] = string.gsub(new.image[a], "<frameIndex>", curFrame % (btn.frame or 1))
                        end
        
                        if canvasStorage.debug_btnState then  if not btn.positionLocked then logString["btn : " .. btn.name] = btn.name .. " Shown" end end
                        if btn.sounds then new.sounds = btn.sounds end

                        if btn.position then new.position = btn.position end
                        if btn.detectArea then 
                            new.detectArea = btn.detectArea
                        else
                            local imageSize = root.imageSize(btn.intBox or backImages.base or new.image.base)
                            if not btn.intBox then
                                if btn.hover then
                                    local iS = root.imageSize(backImages.hover or btn.hover)
                                    if imageSize[1] < iS[1] then imageSize[1] = iS[1] end
                                    if imageSize[2] < iS[2] then imageSize[2] = iS[2] end
                                end
                                if btn.press then
                                    local iS = root.imageSize(backImages.press or btn.press)
                                    if imageSize[1] < iS[1] then imageSize[1] = iS[1] end
                                    if imageSize[2] < iS[2] then imageSize[2] = iS[2] end
                                end
                            end
                            
                            new.detectArea = {
                                0, 0,
                                (imageSize[1]), (imageSize[2])
                            }
                        end
                        if btn.centered then new.centered = btn.centered end
                        if btn.scale then new.scale = btn.scale end
                        if btn.parallax then new.parallax = btn.parallax end

                        

                        new.positionLocked = btn.positionLocked
                        if not new.positionLocked then 
                            new.position = canvas:translateFromCamera(new.position, (btn.zoom or canvasStorage.camZoom), new.parallax)
                            new.scale = new.scale * (1 + (btn.zoom or canvasStorage.camZoom))
                        end
                            
                        new.clickEventType = btn.clickEventType
                        new.clickEvent = btn.clickEvent

                        new.disabledEventType = btn.disabledEventType
                        new.disabledEvent = btn.disabledEvent
                        new.args = btn.args

                        new.disabled = not showResult
                        if btn.disabled ~= nil then
                            new.disabled = btn.disabled
                        end
                        new.anchor = btn.anchor
                        new.zoom = btn.zoom or canvasStorage.camZoom

                        table.insert(canvasStorage.btn.btnTable, new)
                        storage.canvasTooltip[btn.name] = btn.tooltipCfg
                    end
                end
            end
        end
    end

    function buttonEvent(btnName, position, mouseButton, isButtonDown)
        if canvasStorage.overredBtn.disabled then
            if ((paneActionTimer or 0) <= 0) then
                paneActionTimer = copy(paneActionTimerDefault)
                if clickEventType[canvasStorage.overredBtn.disabledEventType] then
                    if type(canvasStorage.overredBtn.disabledEventType) == "string" then
                        clickEventType[canvasStorage.overredBtn.disabledEventType](table.unpack(canvasStorage.overredBtn.disabledArgs))
                    end
                end
                for _, event in pairs(canvasStorage.overredBtn.disabledEvent or {}) do 
                    local callback = findCallback(event.call)
                    if callback then
                        local pR, pM = pcall(callback, table.unpack(event.args))
                        if not pR then
                            sb.logInfo("%s, %s", pR, pM)
                        end
                    else
                        sb.logError("Callback %s Couldn't Be Found !", event.call)
                    end
                end
            end

        else
            if ((paneActionTimer or 0) <= 0) then
                paneActionTimer = copy(paneActionTimerDefault)
                if clickEventType[canvasStorage.overredBtn.clickEventType] then
                    if type(canvasStorage.overredBtn.clickEventType) == "string" then
                        clickEventType[canvasStorage.overredBtn.clickEventType](table.unpack(canvasStorage.overredBtn.args))
                    else

                    end
                end
                for _, event in pairs(canvasStorage.overredBtn.clickEvent or {}) do 
                    local callback = findCallback(event.call)
                    if callback then
                        local pR, pM = pcall(callback, table.unpack(event.args))
                        if not pR then
                            sb.logInfo("%s, %s", pR, pM)
                        end
                    else
                        sb.logError("Callback %s Couldn't Be Found !", event.call)
                    end
                end
            end
        end
        
    end

    function populateCategoryList()
        widget.clearListItems("categoryLayout.category.list")
        widgetList = {}
        for index, category in pairs(storage.category) do
            local cfg = category
            if type(cfg) == "string" then cfg = root.assetJson(cfg) end
            
            local show = shouldShow(cfg.requires or {})
            if (not show) and cfg.hideWhenDisabled then else
                local id = widget.addListItem("categoryLayout.category.list")
                local data = {
                    index = index,
                    tooltipCfg = cfg.tooltip or cfg.title .. "\n" .. cfg.subTitle,
                    disabledTooltipCfg = cfg.disabledTooltip,
                    disabled = (not show)
                }
                if cfg.icon then 
                    if show then
                        widget.setImage("categoryLayout.category.list.".. id ..".icon", cfg.icon) 
                    else
                        widget.setImage("categoryLayout.category.list.".. id ..".icon", cfg.disabledIcon or (cfg.icon .. "?brightness=-50?saturation=-50")) 
                    end
                end
                widget.setData("categoryLayout.category.list.".. id, data)
                table.insert(widgetList, "categoryLayout.category.list.".. id)
            end
        end
        if ((#storage.category < 2) or config.getParameter("hideCategories", false)) and not config.getParameter("forceShowCategories", false) then
            widget.setVisible("categoryLayout", false)
        else
            widget.setVisible("categoryLayout", true)
        end
    end

    function catSelected()
        local selected = widget.getListSelected("categoryLayout.category.list")

        if selected then 
            local data = widget.getData("categoryLayout.category.list."..selected)
            if data then
                --sb.logInfo("category = %s : %s", data.tooltipCfg, data)
                if data.index and (not data.disabled) then setCategory(data.index) end
            end
        end
    end

    function setCategory(index)
        local loaded = false
        sizeOffset = nil
        if storage.curCategory then
            for _, event in pairs(storage.curCategory.unloadEvent or {}) do 
                local callback = findCallback(event.call)
                if callback then
                    local pR, pM = pcall(callback, table.unpack(event.args))
                    if not pR then
                        sb.logInfo("%s, %s", pR, pM)
                    end
                else
                    sb.logError("Callback %s Couldn't Be Found !", event.call)
                end
            end
        end
        if type(index) == "string" then
            if string.find(index, "/") then
                storage.curCategory = copy(index)
                canvasStorage.nextCamPos = {0, 0}
                local cfg = storage.curCategory
                if type(cfg) == "string" then
                    storage.curCategory = root.assetJson(cfg)
                    cfg = root.assetJson(cfg)
                end
                
                for btnIndex, btnCfg in pairs(storage.curCategory.btn or {}) do 
                    if btnCfg.path then
                        local temp = root.assetJson(btnCfg.path)
                        temp = util.mergeTable(temp, btnCfg)
                        temp.path = nil
                        storage.curCategory.btn[btnIndex] = temp
                    end
                end

                storage.canvasTooltip = {}
                for _, btn in pairs(cfg.btn or {}) do
                    if type(_) == "string" then
                        storage.canvasTooltip[_] = btn.tooltipCfg
                    else
                        storage.canvasTooltip[btn.name] = btn.tooltipCfg
                    end
                end
                widget.setText("categoryTitleLbl", "^shadow;^set;".. (cfg.title or ""))
                if cfg.zoom then
                    canvasStorage.nextCamZoom = math.max(cfg.zoom, -0.95)
                else
                    canvasStorage.nextCamZoom = 0
                end
                loaded = true
            else
                for _index, category in pairs(storage.category or {}) do
                    local cfg = category
                    if type(cfg) == "string" then cfg = root.assetJson(category) end
                    if (index == _index) or (index == (cfg.name or cfg.id or cfg.title)) then
                        index = _index
                        break
                    end
                end
            end
        end

        if storage.category[index] and not loaded then
            storage.curCategory = copy(storage.category[index])
            canvasStorage.nextCamPos = {0, 0}
            local cfg = storage.curCategory
            if type(cfg) == "string" then
                storage.curCategory = root.assetJson(cfg)
                cfg = root.assetJson(cfg)
            end
            for btnIndex, btnCfg in pairs(storage.curCategory.btn or {}) do 
                if btnCfg.path then
                    local temp = root.assetJson(btnCfg.path)
                    temp = util.mergeTable(temp, btnCfg)
                    temp.path = nil
                    storage.curCategory.btn[btnIndex] = temp
                end
            end
            storage.canvasTooltip = {}
            for _, btn in pairs(cfg.btn or {}) do
                if type(_) == "string" then
                    storage.canvasTooltip[_] = btn.tooltipCfg
                else
                    storage.canvasTooltip[btn.name] = btn.tooltipCfg
                end
            end
            widget.setText("categoryTitleLbl", "^shadow;^set;".. (cfg.title or ""))
            if cfg.zoom then
                canvasStorage.nextCamZoom = math.max(cfg.zoom, -0.95)
            else
                canvasStorage.nextCamZoom = 0
            end

            loaded = true
        end
        populateCategoryList()
        if storage.curCategory then
            for _, event in pairs(storage.curCategory.loadEvent or {}) do 
                local callback = findCallback(event.call)
                if callback then
                    local pR, pM = pcall(callback, table.unpack(event.args))
                    if not pR then
                        sb.logInfo("%s, %s", pR, pM)
                    end
                else
                    sb.logError("Callback %s Couldn't Be Found !", event.call)
                end
            end
        end
    end

    function loadCategory(categoryListPath, categoryName)
        consLogString = {}
        storage.category = {}
        local categoryList = categoryListPath or config.getParameter("categoryList", "/D8Encyclopedia/Category/list.json")
        if type(categoryList) == "string" then categoryList = root.assetJson(categoryList) end
        for _, category in pairs(categoryList or {}) do 
            local cfg = copy(category)
            if type(cfg) == "string" then cfg = root.assetJson(cfg) end
            
            local index = "cat_" .. _
            consLogString[index] = string.format("%s, %s, %s, %s", index, cfg.name or cfg.title, cfg.hideWhenDisabled or false, show)
            
            table.insert(storage.category, cfg)
        end
        table.sort(storage.category, function(a,b)
            local A_cfg = a
            if type(A_cfg) == "string" then A_cfg = root.assetJson(A_cfg) end

            local B_cfg = b
            if type(B_cfg) == "string" then B_cfg = root.assetJson(B_cfg) end

            return (A_cfg.priority or 0) > (B_cfg.priority or 0)
        end)

        if storage.category[1] then
            setCategory(categoryName or 1)
            if categoryListPath then updateCategoryPos(script.updateDt(), true, 1.5) end
        end
    end
    
    local _cursorOverride = cursorOverride
    function cursorOverride(mousePosition) -- give the mouse position in the entire window
        local override
        storage.mousePosition = mousePosition
        if _cursorOverride then override = _cursorOverride(mousePosition) end
        return override
    end
    
    function createTooltip(mousePosition) -- do note that for some reason oSB change this func to be called on update even if you don't move the cursor -- forked from the previous/legacy encyclopedia version
        local tooltipCfg
        local atCursorWidget = widget.getChildAt(mousePosition)
        if atCursorWidget then
            local path = "gui" .. atCursorWidget .. ".tooltip"
            if config.getParameter(path) then
                tooltipCfg = config.getParameter(path)
            end
        end
        if not tooltipCfg then
            for index, path in ipairs(widgetList or {}) do
                if widget.inMember(path, mousePosition) then
                    local data = widget.getData(path)
                    if data.disabled then
                        tooltipCfg = data.disabledTooltipCfg
                    else
                        tooltipCfg = data.tooltipCfg
                    end
                end
                if tooltipCfg then break end
            end
            if not tooltipCfg then
                if canvasStorage.overredBtn then
                    local btnName = canvasStorage.overredBtn.name
                    tooltipCfg = storage.canvasTooltip[btnName]
                end
            end
        end
        if tooltipCfg == nil then D8Tooltip:scriptTipClosed() return end
        local tooltip = nil
        if type(tooltipCfg) == "string" then
            tooltip = D8Tooltip:text(tooltipCfg)
            D8Tooltip:scriptTipClosed()
        elseif type(tooltipCfg) == "table" then 
            if tooltipCfg.background then -- This is a prepared vanilla tooltip no need to do anything if it done correctly
                tooltip = tooltipCfg
                D8Tooltip:scriptTipClosed()
            elseif tooltipCfg.type == "itemList" then
                if type(tooltipCfg.items) == "string" then
                    tooltipCfg.items = root.assetJson(tooltipCfg.items)["input"]
                end
                tooltip = D8Tooltip:itemList(tooltipCfg.items, tooltipCfg.override)
                --tooltip = D8Tooltip:scriptedItemList(tooltipCfg.items, mousePosition, tooltipCfg.override)
            end
            player.setProperty("d8TooltipUtilCursorPos", mousePosition)
        end
        return tooltip
    end
    
    function close()
        pane.dismiss()
    end

    function shouldShow(requirementTable)
        if canvasStorage.debug then return true end
        local rT = requirementTable
        if type(rT) == "string" then rT = root.assetJson(rT) end
        if not (requirementCheck[sb.printJson(requirementTable)] == nil) then return requirementCheck[sb.printJson(requirementTable)] end
        for _, a in pairs(rT or {}) do 
            if a.type == "function" then
                local callback = findCallback(a.call)
                if callback then
                    local pR, pM = pcall(callback, table.unpack(a.args))
                    if not pR then
                        sb.logInfo("%s, %s", pR, pM)
                    else
                        local result = callback(table.unpack(a.args))
                        if a.invert then
                            if result then 
                                if (requirementCheck[sb.printJson(requirementTable)] == nil) then requirementCheck[sb.printJson(requirementTable)] = false end
                                return false 
                            end
                        elseif not result then
                            if (requirementCheck[sb.printJson(requirementTable)] == nil) then requirementCheck[sb.printJson(requirementTable)] = false end
                            return false
                        end
                    end
                else
                    sb.logError("Callback %s Couldn't Be Found !", a.call)
                    if (requirementCheck[sb.printJson(requirementTable)] == nil) then requirementCheck[sb.printJson(requirementTable)] = false end
                    return false
                end
            elseif a.type == "questCompleted" then 
                
            end
        end

        if (requirementCheck[sb.printJson(requirementTable)] == nil) then requirementCheck[sb.printJson(requirementTable)] = true end
        return true
    end

    function basicUsageInfo()
        clickEventType["prefab"]("popup", config.getParameter("basicUsageInfo", {}))
    end

    function findCallback(path)
        local pathSegment = {}
        if string.find(path, "[.:]") then
            while string.find(path, "[.:]") do
                local dotNumber = string.find(path, "[.:]")
                if dotNumber then
                    table.insert(pathSegment, string.sub(path, 1, dotNumber - 1))
                    path = string.sub(path, dotNumber + 1, string.len(path))
                end
            end
        end
        table.insert(pathSegment, path)
        local currentResult = nil
        for _, string in ipairs(pathSegment) do
            if not currentResult then 
                currentResult = _ENV[string]
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
--
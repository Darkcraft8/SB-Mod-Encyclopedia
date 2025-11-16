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
        
        if canvasStorage.debug then displayLog() end

        if subScript then if subScript["update"] then pcall(subScript["update"], dt) end else subScript = {} end

        storage.mousePosition = {0, 0}

        if requirementCheckTimer <= 0 then
            requirementCheck = {}
            requirementCheckTimer = 2
            populateCategoryList()
        else
            requirementCheckTimer = requirementCheckTimer - dt
        end
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
        local pos, size = widget.getPosition("categoryLayout.category_background"), widget.getSize("categoryLayout")
        local offset = vec2.add(pos, size)
        offset[2] =  0
        widget.setPosition("screenCanvas", vec2.add(canvasPos, offset))
        widget.setSize("screenCanvas", vec2.sub(canvasSize, offset))
    end

    function displayLog()
        logString["camPos"] = "camPos : " .. sb.printJson({util.round(canvasStorage.camPos[1]), util.round(canvasStorage.camPos[2])}) .. ", nextCamPos : " .. sb.printJson(canvasStorage.nextCamPos)
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
                    if renderType[string.lower(background.type or "null") ] then
                        renderType[string.lower(background.type or "null")](cfg, curFrame, copy(background), backgroundIndex)
                    elseif (not background.type) or string.lower(background.type) == "image" then
                        local image = background.image or "/assetmissing.png"
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
                        end
                    elseif string.lower(background.type) == "line" then
                        local startPos, endPos = background.startPos, background.endPos
                        if startPos and endPos then
                            local lineWidth = copy(background.lineWidth or 1)
                            local color = copy(background.color or {255,255,255})
                            local parallax = copy(background.parallax or 1)
                            if background.anchor then
                                local anchor = canvas:anchor(background.anchor)
                                startPos = vec2.add(startPos, anchor)
                                endPos = vec2.add(endPos, anchor)
                            end
                            if not background.positionLocked then 
                                startPos = canvas:translateFromCamera(startPos, canvasStorage.camZoom, parallax)
                                endPos = canvas:translateFromCamera(endPos, canvasStorage.camZoom, parallax)
                                lineWidth = math.max(0, lineWidth + (canvasStorage.camZoom * lineWidth))
                            end
                            
                            local shouldDrawLine = true
                            if background.encyclopedia then
                                if background.encyclopedia.wave then -- Inspired by thaumcraft thaumoninomicon research trail
                                    shouldDrawLine = false
                                    local posOffsetStart, posOffsetEnd = vec2.sub(startPos, background.startPos), vec2.sub(endPos, background.endPos)
                                    local absDist = vec2.mag(vec2.sub(background.startPos, background.endPos))
                                    local segmentCount = background.encyclopedia.wave.segmentCount or math.ceil(12 * (absDist / 120))
                                    local speed, range = (background.encyclopedia.wave.speed or (segmentCount * 0.5)), (background.encyclopedia.wave.range or (segmentCount * 0.15))
                                    speed = speed / segmentCount
                                    --range = range * (speed / segmentCount)
                                    
                                    for i = 1, segmentCount do
                                        local uptime = 1 + (copy(uptime)) -- adding 1 to jump start the effect
                                        local isLastSegment = (i == segmentCount)
                                        local startPos, endPos = copy(background.startPos), copy(background.endPos)
                                        local distance = vec2.sub(startPos, endPos)
                                        local segColor = copy(color)
                                        local startOffset = {0, ( math.sin((uptime + (i - 1)) * (speed)) )}
                                        local wiggle = {0, ( math.sin((uptime + i) * (speed)) )}
                                        local index = "line_" .. backgroundIndex .. "sine"
                                        if canvasStorage.debug_bgLine then logString[index] = string.format(index .. ": " .. util.round(startOffset[2]) .. ": " .. util.round(wiggle[2])) end

                                        startOffset[2] = startOffset[2] + (startOffset[2] / 2)
                                        wiggle[2] = wiggle[2] + (wiggle[2] / 2)
                                        -- range
                                            startOffset[2] = startOffset[2] * range
                                            wiggle[2] = wiggle[2] * range
                                        --
                                        local rotation = math.atan(distance[2] / distance[1])
                                        wiggle = vec2.rotate(wiggle, rotation)
                                        startOffset = vec2.rotate(startOffset, rotation)

                                        startPos = vec2.sub(startPos, vec2.mul(vec2.div(distance, segmentCount), (i - 1)))
                                        if (not isLastSegment) then
                                            endPos = vec2.sub(startPos, vec2.div(distance, segmentCount))
                                            endPos = vec2.add(endPos, wiggle)
                                        elseif (not background.encyclopedia.wave.lockEnd) then
                                            endPos = vec2.sub(startPos, vec2.div(distance, segmentCount))
                                            endPos = vec2.add(endPos, vec2.mul(wiggle, 1 - (background.encyclopedia.wave.endStrength or 0)))
                                        end
                                        if i ~= 1 then startPos = vec2.add(startPos, startOffset) elseif not background.encyclopedia.wave.lockStart then
                                            startPos = vec2.add(startPos, vec2.mul(startOffset, 1 - (background.encyclopedia.wave.startStrength or 0)))
                                        end
                                        local _startPos, _endPos = vec2.add(posOffsetStart, startPos), vec2.add(posOffsetEnd, endPos)
                                        --local index = "line_" .. backgroundIndex .. "_seg_" .. i
                                        --logString[index] = string.format("%s, %s, %s, %s, %s, %s", index, sb.printJson(roundVect(_startPos)), sb.printJson(roundVect(_endPos)), sb.printJson(color), lineWidth, background.positionLocked)
                                        if background.encyclopedia.wave.endColor then
                                            local progress = 1 + (i / segmentCount)
                                            local endColor = copy(background.encyclopedia.wave.endColor)
                                            if not color[4] then color[4] = 255 end
                                            if not endColor[4] then endColor[4] = 255 end
                                            segColor = {
                                                color[1] + (endColor[1] - color[1]) * progress,
                                                color[2] + (endColor[2] - color[2]) * progress,
                                                color[3] + (endColor[3] - color[3]) * progress,
                                                color[4] + (endColor[4] - color[4]) * progress
                                            }
                                        end
                                        canvas:drawLine(_startPos, _endPos, segColor, lineWidth)
                                        --[[
                                        local textPositioning = {
                                            position = vec2.add(_startPos, {0, -4}),--{0, canvas:size()[2] - 5},
                                            horizontalAnchor = "left", -- left, mid, right
                                            verticalAnchor = "top", -- top, mid, bottom
                                            wrapWidth = nil -- wrap width in pixels or nil
                                        }
                                        if i == 1 then canvas:drawText(i.." : cos : "..math.sin(uptime), textPositioning, 7, {255, 161, 0}) end

                                        local textPositioning = {
                                            position = vec2.add(_startPos, {0, 0}),--{0, canvas:size()[2] - 5},
                                            horizontalAnchor = "left", -- left, mid, right
                                            verticalAnchor = "top", -- top, mid, bottom
                                            wrapWidth = nil -- wrap width in pixels or nil
                                        }
                                        canvas:drawText(i.." : start at : "..sb.printJson(startPos), textPositioning, 7, {255, 161, 0})
                                        local textPositioning = {
                                            position = vec2.add(_endPos, {0, 4}),--{0, canvas:size()[2] - 5},
                                            horizontalAnchor = "left", -- left, mid, right
                                            verticalAnchor = "top", -- top, mid, bottom
                                            wrapWidth = nil -- wrap width in pixels or nil
                                        }
                                        canvas:drawText(i.." : end at : "..sb.printJson(endPos), textPositioning, 7, {255, 161, 0})
                                        ]]
                                    end
                                end
                            end
                            local index = "line_" .. backgroundIndex
                            if canvasStorage.debug_bgLine then logString[index] = string.format("%s, %s, %s, %s, %s, %s", index, sb.printJson(roundVect(startPos)), sb.printJson(roundVect(endPos)), sb.printJson(color), lineWidth, background.positionLocked) end

                            if shouldDrawLine then
                                canvas:drawLine(startPos, endPos, color, lineWidth) 
                                local textPositioning = {
                                    position = vec2.add(startPos, {0, 0}),--{0, canvas:size()[2] - 5},
                                    horizontalAnchor = "left", -- left, mid, right
                                    verticalAnchor = "top", -- top, mid, bottom
                                    wrapWidth = nil -- wrap width in pixels or nil
                                }
                                canvas:drawText("startPos : "..sb.printJson(background.startPos), textPositioning, 7, {255, 161, 0})
                                local textPositioning = {
                                    position = vec2.add(endPos, {0, 4}),--{0, canvas:size()[2] - 5},
                                    horizontalAnchor = "left", -- left, mid, right
                                    verticalAnchor = "top", -- top, mid, bottom
                                    wrapWidth = nil -- wrap width in pixels or nil
                                }
                                canvas:drawText("endPos : "..sb.printJson(background.endPos), textPositioning, 7, {255, 161, 0})
                                
                            end
                        end
                
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
                    image = btn.base or (btn.image or {}).base or "/assetmissing.png"
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
                            local imageSize = root.imageSize(btn.intBox or new.image.base)
                            if not btn.intBox then
                                if btn.hover then
                                    local iS = root.imageSize(btn.hover)
                                    if imageSize[1] < iS[1] then imageSize[1] = iS[1] end
                                    if imageSize[2] < iS[2] then imageSize[2] = iS[2] end
                                end
                                if btn.press then
                                    local iS = root.imageSize(btn.press)
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
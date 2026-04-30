--[[
    Render Type are function used to render background elements
--]]
renderType = renderType or {}
renderType.image = function(cfg, curFrame, background, backgroundIndex)
    if background.visible == false then return end
    local image = background.image or "/assetmissing.png"
    local effFrame = math.floor(util.round(curFrame * (background.frameCycle or background.animationCycle or 1)))
    image = string.gsub(image, "<frame>", 1 + curFrame % (background.frame or 1))
    image = string.gsub(image, "<frameIndex>", curFrame % (background.frame or 1))
    if background.frame then
        --logString["starFrame"] = image
    end
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
end

renderType.line = function(cfg, curFrame, background, backgroundIndex)
    if background.visible == false then return end
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
        local segmentCount = background.encyclopedia.wave.segmentCount or math.max(math.ceil(12 * (absDist / 120)), 12)
        local speed, range = (background.encyclopedia.wave.speed or (segmentCount * 0.5)), (background.encyclopedia.wave.range or (segmentCount * 0.1))
        speed = speed / segmentCount
        
            
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
            canvas:drawText("start at : "..sb.printJson(background.startPos), textPositioning, 7, {255, 161, 0})
            local textPositioning = {
        position = vec2.add(endPos, {0, 4}),--{0, canvas:size()[2] - 5},
        horizontalAnchor = "left", -- left, mid, right
        verticalAnchor = "top", -- top, mid, bottom
        wrapWidth = nil -- wrap width in pixels or nil
            }
            canvas:drawText("end at : "..sb.printJson(background.endPos), textPositioning, 7, {255, 161, 0})                
        end
    end
end

renderType.text = function(cfg, curFrame, background, backgroundIndex)
    if background.visible == false then return end
    local index = "background_" .. backgroundIndex
    local parallax = copy(background.parallax or 1)
    local offset = background.position
    local scale = (background.scale or 1)
    local color = background.color or {255,255,255}

    if background.anchor then
        local anchor = canvas:anchor(background.anchor)
        offset = vec2.add(offset, anchor)
    end

    if not background.positionLocked then 
        offset = canvas:translateFromCamera(offset, canvasStorage.camZoom, parallax)
        scale = math.max(0, scale + (canvasStorage.camZoom * scale))
    end
    if background.name then index = background.name end

    local textPositioning = {
        position = offset,
        horizontalAnchor = background.horizontalTextAnchor or background.hTextAnchor or "left", -- left, mid, right
        verticalAnchor = background.verticalTextAnchor or background.vTextAnchor or "top", -- top, mid, bottom
        wrapWidth = background.wrapWidth -- wrap width in pixels or nil
    }
    canvas:drawText(background.string, textPositioning, 7 * scale, color)
end
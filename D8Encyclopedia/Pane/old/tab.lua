--Function for Tab List and Selection, yes it a copy of modList's function
tabBtnList = {}
local tabListOffset = 0
local currenttab = ""

local buttonTemplate = {
    type = "button",
    base = "/interface/scrollarea/varrow-backward.png",
    hover = "/interface/scrollarea/varrow-backwardhover.png",
    position = {3, 23},
    callback = "tabSelectBtn"
}
-- Init Config
local tabBtnCount = 0
local tabListCfg = {}
tabCatCfg = {}

function populatetab()
    tabListUninit()

    local positionOffset = tabListCfg["offset"] or {0, 20}
    local startPos = tabListCfg["startPos"]
    local addedOffset = false
    local tabBtnCountEffective = tabBtnCount
    if tabCatCfg then
        if not addedOffset and not (tabListOffset > 0) then
            addedOffset = true
            startPos = vec2.sub(startPos, tabListCfg["offset"] or {0, 20})
        else
            tabBtnCountEffective = tabBtnCount - 1
        end
        if ((#tabCatCfg - tabListOffset) >= (tabBtnCountEffective + 1)) then
            tabBtnCountEffective = tabBtnCountEffective - 1
        end

        local allowed = {}
        requirementCheck(allowed, tabBtnCountEffective, tabCatCfg, tabListOffset, debugMode)

        for i = 1, tabBtnCountEffective do -- i should change the effectif number to be calculated by the size of the button image
            local tabEncy = allowed[i + tabListOffset]
            if not tabEncy and not debugMode then break end
            if tabEncy then
                if tabListOffset > 0 then
                    widget.setVisible("tabListPrev", true)
                end
                if (#allowed - tabListOffset) > tabBtnCountEffective then
                    widget.setVisible("tabListNext", true)
                end
                
                local name = tabEncy["tooltipText"] .. "_" .. i
                local btnCfg = copy(buttonTemplate)
                btnCfg["base"] = (tabEncy["icon"] or "/interface/inventory/empty.png?crop;1;1;17;17")
                btnCfg["hover"] = (tabEncy["icon"] or "/interface/inventory/empty.png?crop;1;1;17;17") .. "?brightness=25"
                btnCfg["position"] = startPos
                btnCfg["position"] = {
                    btnCfg["position"][1] + (positionOffset[1] * i),
                    btnCfg["position"][2] + (positionOffset[2] * i)
                }
                btnCfg["tooltip"] = tabEncy["tooltipText"]
                widget.addChild("tabButtonLayout", btnCfg, name)
                widget.setData("tabButtonLayout." .. name , {
                    index = i + tabListOffset
                })
                table.insert(tabBtnList, name)
                
                config.setParameter("gui" .. ".tabButtonLayout.children." .. name, btnCfg)
            end
            if debugMode and not tabEncy then
                local name = "debug_" .. i
                local btnCfg = copy(buttonTemplate)
                btnCfg["base"] = ("/interface/inventory/empty.png?crop;1;1;17;17")
                btnCfg["hover"] = ("/interface/inventory/empty.png?crop;1;1;17;17") .. "?brightness=25"
                btnCfg["position"] = tabListCfg["startPos"]
                btnCfg["position"] = {
                    btnCfg["position"][1] + (positionOffset[1] * i),
                    btnCfg["position"][2] + (positionOffset[2] * i)
                }

                widget.addChild("tabButtonLayout", btnCfg, name)
                table.insert(tabBtnList, name)

                config.setParameter("gui" .. ".tabButtonLayout.children." .. name, btnCfg)
            end
        end
    end
end

function tabListBtn(buttonName)
    local update = false
    if buttonName == "tabListPrev" then
        tabListOffset = tabListOffset - 1
        if not ((tabListOffset - 1) > 0) then tabListOffset = tabListOffset - 1 end 
        if tabListOffset < 0 then tabListOffset = 0 end
        update = true
    elseif buttonName == "tabListNext" then
        if #tabBtnList > 1 then
            if tabListOffset < 1 then tabListOffset = tabListOffset + 1 end
            tabListOffset = tabListOffset + 1
        end
        update = true
    end

    if update then populatetab() end
end

function tabListInit()
    tabListCfg = config.getParameter("tabList")
    tabBtnCount = tabListCfg["btnNumOverride"] or util.round(math.abs(((tabListCfg["startPos"][tonumber(tabListCfg["DirectionIndex"])] - tabListCfg["endPos"][tonumber(tabListCfg["DirectionIndex"])]) / 18)))
    tabCatCfg = {}
end

function tabListUninit()
    for id, name in ipairs(tabBtnList) do 
        widget.removeChild("tabButtonLayout", name)
    end
    tabBtnList = {}
    if not debugMode then
        widget.setVisible("tabListPrev", false)
        widget.setVisible("tabListNext", false)
    end
    pageClear() 
end

-- Page Handling Functions
local pageCfg = {}
local updatePageTarget = {}
currentPageChildList = {}
local currentPage = 1
local currentCatIndex = 1

function tabSelectBtn(buttonName)
    currentCatIndex = widget.getData("tabButtonLayout." .. buttonName)["index"]
    if currentCatIndex then
        currentPage = 1
        pageCfg = tabCatCfg[currentCatIndex]["pages"][currentPage]
        pageOpen()
    end
end
function pageClear()    
    for id, name in ipairs(currentPageChildList) do 
        widget.removeChild("pageLayout", name)
    end
    currentPageChildList = {}
    updatePageTarget = {}
    
    if not debugMode then
        widget.setVisible("page_Prev", false)
        widget.setVisible("page_Next", false)
    end
end

function pageOpen()
    pageClear()
    if currentPage > 1 then
        widget.setVisible("page_Prev", true)
    end
    if tabCatCfg[currentCatIndex]["pages"][currentPage + 1] then
        widget.setVisible("page_Next", true)
    end
    for index, param in pairs(pageCfg or {}) do 
        if param["type"] == "text" then
            local cfg = {
                type = "label",
                position = param["position"],
                hAnchor = param["hAnchor"],
                vAnchor = param["vAnchor"],
                tooltip = param["tooltip"],
                zLevel = -1
            }
            if config.getParameter("textCfg.wrapWidth") then
                cfg.wrapWidth = math.max(0, config.getParameter("textCfg.wrapWidth", 0) - param["position"][1])
            end
            if param["pageAnchor"] then
                local pageCorners = config.getParameter("gui.pageLayout.rect", {0,0,1,1})
                if param["pageAnchor"] == "topLeft" then
                    cfg.position = {0, (pageCorners[4] - 28)}
                elseif param["pageAnchor"] == "topRight" then
                    cfg.position = {pageCorners[3], (pageCorners[4] - 28)}
                elseif param["pageAnchor"] == "bottomLeft" then
                    cfg.position = {0, 0}
                elseif param["pageAnchor"] == "bottomRight" then
                    cfg.position = {pageCorners[3], 0}
                elseif param["pageAnchor"] == "centerLeft" then
                    cfg.position = {0, (pageCorners[4] - 28) / 2}
                elseif param["pageAnchor"] == "centerRight" then
                    cfg.position = {pageCorners[3], (pageCorners[4] - 28) / 2}
                elseif param["pageAnchor"] == "center" then
                    cfg.position = {pageCorners[3] / 2, (pageCorners[4] - 28) / 2}
                elseif param["pageAnchor"] == "topCenter" then
                    cfg.position = {pageCorners[3] / 2, (pageCorners[4] - 28)}
                elseif param["pageAnchor"] == "bottomCenter" then
                    cfg.position = {pageCorners[3] / 2, 0}
                end
                cfg.position = vec2.add(cfg.position, param["position"])
            end
            if type(param["string"]) == "table" then
                cfg["value"] = buildStringFromTable(param["string"])
            elseif type(param["string"]) == "string"  then
                cfg["value"] = param["string"]
            end
            local name = index
            widget.addChild("pageLayout", cfg, name)
            config.setParameter("gui" .. ".pageLayout.children." .. name, cfg)
            table.insert(currentPageChildList, name)
        elseif param["type"] == "image" then
            for i, paramCfg in ipairs(param["list"]) do
                local cfg = {
                    type = "image",
                    position = paramCfg["position"],
                    file = string.gsub(paramCfg["file"], "<frame>", math.floor(frame) % (paramCfg["frame"] or 1)),
                    tooltip = paramCfg["tooltip"],
                    zLevel = 1
                }
                local name = index .. "_".. i
                if paramCfg["pageAnchor"] then
                    local pageCorners = config.getParameter("gui.pageLayout.rect", {0,0,1,1})
                    if paramCfg["pageAnchor"] == "topLeft" then
                        cfg.position = {0, (pageCorners[4] - 28)}
                    elseif paramCfg["pageAnchor"] == "topRight" then
                        cfg.position = {pageCorners[3], (pageCorners[4] - 28)}
                    elseif paramCfg["pageAnchor"] == "bottomLeft" then
                        cfg.position = {0, 0}
                    elseif paramCfg["pageAnchor"] == "bottomRight" then
                        cfg.position = {pageCorners[3], 0}
                    elseif paramCfg["pageAnchor"] == "centerLeft" then
                        cfg.position = {0, (pageCorners[4] - 28) / 2}
                    elseif paramCfg["pageAnchor"] == "centerRight" then
                        cfg.position = {pageCorners[3], (pageCorners[4] - 28) / 2}
                    elseif paramCfg["pageAnchor"] == "center" then
                        cfg.position = {pageCorners[3] / 2, (pageCorners[4] - 28) / 2}
                    elseif paramCfg["pageAnchor"] == "topCenter" then
                        cfg.position = {pageCorners[3] / 2, (pageCorners[4] - 28)}
                    elseif paramCfg["pageAnchor"] == "bottomCenter" then
                        cfg.position = {pageCorners[3] / 2, 0}
                    end
                    cfg.position = vec2.add(cfg.position, paramCfg["position"])
                end
                widget.addChild("pageLayout", cfg, name)
                config.setParameter("gui" .. ".pageLayout.children." .. name, cfg)
                
                table.insert(currentPageChildList, name)
                if paramCfg["frame"] or string.find(paramCfg["file"], "<frame>") then
                    table.insert(updatePageTarget, {name = name, imagePath = paramCfg["file"], frame = paramCfg["frame"]})
                end
            end
        end
    end
end

function pageChange(buttonName)
    if buttonName == "page_Prev" then
        currentPage = currentPage - 1
        if currentPage < 0 then currentPage = 0 end

    elseif buttonName == "page_Next" then
        currentPage = currentPage + 1
        if currentPage > #tabBtnList then currentPage = #tabBtnList end
    end

    pageCfg = tabCatCfg[currentCatIndex]["pages"][currentPage]
    pageOpen()
end

function buildStringFromTable(stringTable)
    local newString = ""

    for index, stringValue in ipairs(stringTable) do
        if index > 1 then
            newString = newString .. "\n" .. stringValue
        else
            newString = newString .. stringValue
        end
    end

    return newString
end

function updatePage()
    for index, param in ipairs(updatePageTarget or {}) do
        local image = string.gsub(param["imagePath"], "<frame>", math.floor(frame) % (param["frame"] or 1))
        widget.setImage("pageLayout."..param["name"], image)
    end
end
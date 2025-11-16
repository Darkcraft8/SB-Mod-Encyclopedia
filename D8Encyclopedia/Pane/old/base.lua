require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/D8Encyclopedia/Pane/old/mod.lua"
require "/D8Encyclopedia/Pane/old/tab.lua"
require "/D8Encyclopedia/Pane/old/requirement.lua"

require "/shared/darkcraft8/d8ToolTipUtil/tooltips.lua"

debugMode = false
function init()
    D8Tooltip:init()
    debugMode = config.getParameter("debugMode")
    widget.setVisible("modListPrev", false)
    widget.setVisible("modListNext", false)
    widget.setVisible("tabListPrev", false)
    widget.setVisible("tabListNext", false)
    addRequirementCheck()
    configInit()
    modListInit()
    tabListInit()
    --sb.logInfo("printJson %s", sb.printJson(config.getParameter(''), 1))
    
    if debugMode then
        if not widget.active("modListNext") then
            widget.setVisible("modListNext", true)
            widget.setButtonEnabled("modListNext", false)
        end
        if not widget.active("modListPrev") then
            widget.setVisible("modListPrev", true)
            widget.setButtonEnabled("modListPrev", false)
        end

        if not widget.active("tabListNext") then
            widget.setVisible("tabListNext", true)
            widget.setButtonEnabled("tabListNext", false)
        end
        if not widget.active("tabListPrev") then
            widget.setVisible("tabListPrev", true)
            widget.setButtonEnabled("tabListPrev", false)
        end

        if not widget.active("page_Prev") then
            widget.setVisible("page_Prev", true)
            widget.setButtonEnabled("page_Prev", false)
        end
        if not widget.active("page_Next") then
            widget.setVisible("page_Next", true)
            widget.setButtonEnabled("page_Next", false)
        end
    end
    
end

frame = 0

function update(dt)
    frame = (frame + (dt * 6)) % 9999
    updatePage(dt)
    D8Tooltip:update(dt)
end

function uninit()
    modListUninit()
    tabListUninit()
    D8Tooltip:uninit()
end

-- Tooltip
function createTooltip(mousePosition) -- do note that for some reason oSB change this func to be spammed even if you don't move the cursor
    local tooltipCfg
    local atCursorWidget = widget.getChildAt(mousePosition)
    if atCursorWidget then
        local path = "gui" .. atCursorWidget .. ".tooltip"
        if config.getParameter(path) then
            tooltipCfg = config.getParameter(path)
        end
    end
    if not tooltipCfg then
        local widgetList, widgetFullPath = buildWidgetList()
        for index, path in ipairs(widgetList) do
            if widget.inMember(path, mousePosition) then
                if config.getParameter(widgetFullPath[index] .. ".tooltip") then
                    tooltipCfg = config.getParameter(widgetFullPath[index] .. ".tooltip")
                end
            end
            if tooltipCfg then break end
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

-- getParameters Replacement
function configInit()
    customConfig = {}
    customConfig.param = config.getParameter('', {})
    customConfig.rootParameter = config.getParameter
    customConfig.getParameter = function(path, defaultValue)
        if path == "" then return config.param end -- lua asked for all the parameters data
        local pathSegment = segmentPath(path)
        local currentResult = nil
        for _, string in ipairs(pathSegment) do
          if not currentResult then 
            if config.param[string] then
                currentResult = config.param[string]
            else
                return defaultValue
            end
          else
            if currentResult[string] then
                currentResult = currentResult[string]
            else
                return defaultValue
            end
          end
        end
    
        if currentResult ~= nil then
            return currentResult
        else
            return defaultValue
        end
    end
    customConfig.setParameter = function(path, Value)
        local pathSegment = segmentPath(path)
        local currentResult = nil
        for _, string in ipairs(pathSegment) do
          if not currentResult then 
    
            if not config.param[string] and pathSegment[_ + 1] then -- Din't finished going down the path and there no bridge for the gap
                config.param[string] = {}
                currentResult = config.param[string]
            elseif not pathSegment[_ + 1] then -- Finished going down the path so we set the value here
                currentResult[string] = Value
            else -- Din't finished going down the path
                currentResult = config.param[string]
            end
    
          else
    
            if not currentResult[string] and pathSegment[_ + 1] then -- Din't finished going down the path and there no bridge for the gap
                currentResult[string] = {}
                currentResult = currentResult[string]
            elseif not pathSegment[_ + 1] then -- Finished going down the path so we set the value here
                currentResult[string] = Value
            else -- Din't finished going down the path
                currentResult = currentResult[string]
            end
    
          end
    
        end
    end

    config = customConfig
    --sb.logInfo("Config Override Initialisation Done\nconfig.rootParameter | Vanilla getParameter\nconfig.getParameter  | getParameter from a list that can get updated using setParameter\nconfig.setParameter  | set parameter in the list to the wanted value, will also recursively create array when/if needed")

end

function segmentPath(path)
    local pathSegment = {}
    if string.find(path, "[.]") then
    while string.find(path, "[.]") do
        local dotNumber = string.find(path, "[.]")
        if dotNumber then
        table.insert(pathSegment, string.sub(path, 1, dotNumber - 1))
        path = string.sub(path, dotNumber + 1, string.len(path))
        end
    end
    end
    table.insert(pathSegment, path)
    return pathSegment
end

-- widgetListMaker because getChildAt only try to get the first widget it find
function buildWidgetList() -- Create and Return Two list, the first is the widget name for inMember and the second is the parameters path for getParameters
    local widgetList = {}
    local widgetFullPath = {}

    for index, name in ipairs(modBtnList or {}) do
        local widgetPath = "modButtonLayout" .. "." .. name
        table.insert(widgetList, widgetPath)
        local widgetPath = "gui" .. ".modButtonLayout" .. ".children." .. name
        table.insert(widgetFullPath, widgetPath)
    end
    for index, name in ipairs(tabBtnList or {}) do
        local widgetPath = "tabButtonLayout" .. "." .. name
        table.insert(widgetList, widgetPath)
        local widgetPath = "gui" .. ".tabButtonLayout" .. ".children." .. name
        table.insert(widgetFullPath, widgetPath)
    end
    for index, name in ipairs(currentPageChildList or {}) do
        local widgetPath = "pageLayout" .. "." .. name
        table.insert(widgetList, widgetPath)
        local widgetPath = "gui" .. ".pageLayout" .. ".children." .. name
        table.insert(widgetFullPath, widgetPath)
    end
    
    return widgetList, widgetFullPath
end

local _cursorOverride = cursorOverride
function cursorOverride(mousePosition)
    local override
    if _cursorOverride then override = _cursorOverride(mousePosition) end
    return override
end
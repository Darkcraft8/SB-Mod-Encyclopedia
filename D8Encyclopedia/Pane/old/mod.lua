--Function for Mod List and Selection
modBtnList = {}
local modListOffset = 0
local currentMod = ""

local buttonTemplate = {
    type = "button",
    base = "/interface/scrollarea/varrow-backward.png",
    hover = "/interface/scrollarea/varrow-backwardhover.png",
    position = {3, 23},
    callback = "modSelectBtn"
}
-- Init Config
local modBtnCount = 0
local modListCfg = {}
local modListJsonPath

function populateMod()
    modListUninit()

    local positionOffset = modListCfg["offset"] or {0, 20}
    local startPos = modListCfg["startPos"]
    local addedOffset = false
    local modBtnCountEffective = modBtnCount
    local allowed = {}

    if not addedOffset and not (modListOffset > 0) then -- shift button if at the start
        addedOffset = true
        startPos = vec2.sub(startPos, modListCfg["offset"] or {0, 20})
    else
        modBtnCountEffective = modBtnCount - 1
    end
    if ((#modListJsonPath - modListOffset) >= (modBtnCountEffective + 1)) then -- shift button if there is no more button after
        modBtnCountEffective = modBtnCountEffective - 1
    end

    requirementCheck(allowed, modBtnCountEffective, modListJsonPath, modListOffset, debugMode)
    --sb.logInfo("allowed %s", allowed)

    for i = 1, modBtnCountEffective do -- i should change the effectif number to be calculated by the size of the button image
        local modEncy = allowed[i]
        if not modEncy and not debugMode then break end
        if modEncy then
            local cfg = root.assetJson(modEncy)
            if modListOffset > 0 then
                widget.setVisible("modListPrev", true)
            end
            if (#modListJsonPath - modListOffset) > modBtnCountEffective then
                widget.setVisible("modListNext", true)
            end
            local name = cfg["name"] or string.gsub(modEncy, ".config", '')
            local btnCfg = copy(buttonTemplate)
            btnCfg["base"] = (cfg["icon"] or "/interface/inventory/empty.png?crop;1;1;17;17")
            btnCfg["hover"] = (cfg["icon"] or "/interface/inventory/empty.png?crop;1;1;17;17") .. "?brightness=25"
            btnCfg["position"] = startPos
            btnCfg["position"] = {
                btnCfg["position"][1] + (positionOffset[1] * i),
                btnCfg["position"][2] + (positionOffset[2] * i)
            }
            btnCfg["tooltip"] = cfg["tooltip"]
            btnCfg["path"] = modEncy

            widget.addChild("modButtonLayout", btnCfg, name)
            table.insert(modBtnList, name)

            config.setParameter("gui" .. ".modButtonLayout.children." .. name, btnCfg)
        end
        if not modEncy and debugMode then
            local name = "debug_" .. i
            local btnCfg = copy(buttonTemplate)
            btnCfg["base"] = ("/interface/inventory/empty.png?crop;1;1;17;17")
            btnCfg["hover"] = ("/interface/inventory/empty.png?crop;1;1;17;17") .. "?brightness=25"
            btnCfg["position"] = modListCfg["startPos"]
            btnCfg["position"] = {
                btnCfg["position"][1] + (positionOffset[1] * i),
                btnCfg["position"][2] + (positionOffset[2] * i)
            }

            widget.addChild("modButtonLayout", btnCfg, name)
            table.insert(modBtnList, name)

            config.setParameter("gui" .. ".modButtonLayout.children." .. name, btnCfg)
        end
    end
end

function modListBtn(buttonName)
    if buttonName == "modListPrev" then
        modListOffset = modListOffset - 1
        if not ((modListOffset - 1) > 0) then modListOffset = modListOffset - 1 end 
        if modListOffset < 0 then modListOffset = 0 end
    elseif buttonName == "modListNext" then
        if #modBtnList > 1 then
            if modListOffset < 1 then modListOffset = modListOffset + 1 end
            modListOffset = modListOffset + 1
        end
    end
    populateMod()
end

function modSelectBtn(buttonName)
    if config.getParameter("gui" .. ".modButtonLayout.children." .. buttonName .. ".path") then
        tabCatCfg = root.assetJson(config.getParameter("gui" .. ".modButtonLayout.children." .. buttonName .. ".path"))["category"]
        tabListOffset = 0
        populatetab()
    end
end


function modListInit()
    modListCfg = config.getParameter("modList")
    modBtnCount = modListCfg["btnNumOverride"] or util.round(math.abs(((modListCfg["startPos"][tonumber(modListCfg["DirectionIndex"])] - modListCfg["endPos"][tonumber(modListCfg["DirectionIndex"])]) / 18)))
    modListJsonPath = root.assetJson("/D8Encyclopedia/Mod/list.json")
    populateMod()
    pageClear()
end

function modListUninit()
    for id, name in ipairs(modBtnList) do 
        widget.removeChild("modButtonLayout", name)
    end
    modBtnList = {}
    if not debugMode then
        widget.setVisible("modListPrev", false)
        widget.setVisible("modListNext", false)
    end
end


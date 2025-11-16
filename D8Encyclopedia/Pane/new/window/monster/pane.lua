--[[
  - drop pools aren't given when using monsterParameters if they aren't modified by custom parameters
  - spawn location need to be given too
--]]
local monsterType, monsterPortrait, monsterParameters
local dropPools = {{}}
function init()
    monsterType = config.getParameter("monsterType")
    monsterPortrait = root.monsterPortrait(monsterType, config.getParameter("monsterParameters"))
    monsterParameters = root.monsterParameters(monsterType, config.getParameter("monsterParameters"))
    
    sb.logInfo("%s, %s", ipairs({1, 2, 3}))
    dropPools = monsterParameters.dropPools or config.getParameter("dropPools" or {{}})
    sb.logInfo("monsterType %s", monsterType)
    sb.logInfo("monsterParameters %s", sb.printJson(monsterParameters, 1))
    sb.logInfo("dropPools %s", dropPools)
end

--
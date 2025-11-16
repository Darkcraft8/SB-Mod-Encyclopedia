-- to add a requirement type just create a func thats ins't in a table to the script
local _addRequirementCheck = addRequirementCheck
local requirementCheckList = requirementCheckList or {}
function addRequirementCheck() -- or override this func while only changing the part after the if statement
    if _addRequirementCheck then _addRequirementCheck() end
    -- create a func or give the name of a func that isn't in a table
    -- and add it to the array with the wanted name
    requirementCheckList["isAdmin"] = function() return player.isAdmin() end
    requirementCheckList["hasCollected"] = function(args)
        for i, collectable in ipairs(args or {}) do
            local unlocked = false
            for _, collectableName in ipairs(player.collectables(collectable[1]) or {}) do 
                local inverse = collectable[3]
                if collectableName == collectable[2] then unlocked = not (inverse or false) end
            end
            if not unlocked then return false end
        end
        return true
    end
    requirementCheckList["hasCollectablesIn"] = function(args)
        for _, collectableName in ipairs(player.collectables(args) or {}) do
            return not (args.inverse or false)
        end
        return (args.inverse or false)
    end
    
end

function requirementCheck(allowed, btnCountEffective, listJsonPath, listOffset, debugMode)
    for i = 1, btnCountEffective do -- filter allowed list from not allowed
        local ency = listJsonPath[i + listOffset]
        --if not ency and not debugMode then break end
        if ency then
            local cfg = ency
            if type(ency) == "string" then
                cfg = root.assetJson(ency)
            end
            local add = true
            for i, r in ipairs(cfg["require"] or {}) do
                if type(r) == "string" then
                    if _ENV[r] then
                        add = _ENV[r]()
                    elseif requirementCheckList[r] then
                        add = requirementCheckList[r]()
                    else
                        add = false
                    end
                elseif type(r) == "table" then
                    if _ENV[r.check] then 
                        add = _ENV[r.check](r.args)
                    elseif requirementCheckList[r.check] then
                        add = requirementCheckList[r.check](r.args)
                    else
                        add = false
                    end
                else
                    add = false
                end
            end
            if add then
                table.insert(allowed, ency)
            end
        end
    end
end
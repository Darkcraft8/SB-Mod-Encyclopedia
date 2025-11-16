local fileList = assets.byExtension("d8Ency")
local listPath = "/D8Encyclopedia/Mod/list.json"
local list = assets.json(listPath)
local count = 0
local registered = {}

for i = 1, #fileList do --Search for encyclopedia category file and add them to the list if they aren't already there
    local d8EncyCategory = fileList[i]
    local alreadyExist = false
    for i = 1, #list do
        if list[i] == d8EncyCategory then alreadyExist = true end
    end
    if not alreadyExist then
        table.insert(registered, d8EncyCategory)
        count = count + 1
    end
end

if count > 0 then
    local path = listPath .. ".patch"
    assets.add(path, registered)
    assets.patch(listPath, path)

    sb.logInfo("[d8Encyclopedia | Category Fetching Postload] Registered %s missing category for the legacy pane", count)
end

local fileList = assets.byExtension("d8Encyclopedia")
local listPath = "/D8Encyclopedia/Category/list.json"
local list = assets.json(listPath)
local count = 0
local registered = {}

for i = 1, #fileList do --Search for encyclopedia category file and add them to the list if they aren't already there
    local d8EncyCategory = fileList[i]
    local alreadyExist = false
    for i = 1, #list do
        if list[i] == d8EncyCategory then alreadyExist = true end
    end
    if not alreadyExist then
        table.insert(registered, d8EncyCategory)
        count = count + 1
    end
end

if count > 0 then
    local path = listPath .. ".patch"
    assets.add(path, registered)
    assets.patch(listPath, path)

    sb.logInfo("[d8Encyclopedia | Category Fetching Postload] Registered %s missing category", count)
end
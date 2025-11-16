local d8EncyclopediaBtn = {
    type = "button",
    base = "/D8Encyclopedia/Pane/old/icon.png",
    hover = "/D8Encyclopedia/Pane/old/icon.png?brightness=25?hueshift=25",
    pressed = "/D8Encyclopedia/Pane/old/icon.png?brightness=-25?hueshift=-25"
}


function patch(config)
    local gui = config.gui
    d8EncyclopediaBtn.position = {gui.close.position[1] - 25, gui.close.position[2]}
    gui.d8EncyclopediaBtn = d8EncyclopediaBtn
    sb.logInfo("[d8Encyclopedia] Patching collection pane to add button for the encyclopedia %s, %s", gui.d8EncyclopediaBtn.position[1], gui.close.position[1])

    table.insert(config.scripts, "/interface/scripted/collections/open_d8Encyclopedia.lua")
    table.insert(config.scriptWidgetCallbacks, "d8EncyclopediaBtn")
    return config
end
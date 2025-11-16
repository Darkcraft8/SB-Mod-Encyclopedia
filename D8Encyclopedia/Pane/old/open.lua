function init()
    theme((player.getProperty("D8Encyclopedia") or {theme = "vanilla"})["theme"])
end

function theme(themeName)
    local path = "/D8Encyclopedia/Pane/old/theme/" .. themeName .. "/pane.config"
    local cfg = root.assetJson(path)
    for param, value in pairs(config.getParameter("overrides")) do 
        cfg[param] = value
    end
    player.interact("scriptPane", cfg)
    pane.dismiss()
end
function d8EncyclopediaBtn(name)
    --sb.logInfo("getPosition %s", widget.getPosition(name))
    player.interact("ScriptPane", "/D8Encyclopedia/Pane/new/pane.config")
    pane.dismiss() -- dismiss collection pane
end
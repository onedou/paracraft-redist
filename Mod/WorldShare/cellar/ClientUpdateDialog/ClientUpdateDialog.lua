--[[
Title: Client Update Dialog
Author(s): big
Date: 2021.1.25
City: Foshan
use the lib:
------------------------------------------------------------
local ClientUpdateDialog = NPL.load('(gl)Mod/WorldShare/cellar/ClientUpdateDialog/ClientUpdateDialog.lua')
------------------------------------------------------------
]]

local ClientUpdateDialog = NPL.export()

function ClientUpdateDialog:Show(callback)
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url = format("script/apps/Aries/Creator/Game/Login/ClientUpdateDialog.html?latestVersion=%s&curVersion=%s&curGame=%s", updater:getLatestVersion(), updater:getCurVersion(), gamename), 
        name = "ClientUpdateDialog", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 1,
        allowDrag = false,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -210,
            y = -100,
            width = 420,
            height = 250,
    });
end

--[[
Title: GameOver
Author(s):  big
Date: 2019.01.24
Place: Foshan
use the lib:
------------------------------------------------------------
local GameOver = NPL.load("(gl)Mod/ExplorerApp/components/GameProcess/GameOver/GameOver.lua")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/ExplorerApp/main.lua")
local ExplorerApp = commonlib.gettable("Mod.ExplorerApp")

local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MainPage = NPL.load("(gl)Mod/ExplorerApp/components/MainPage.lua")

local GameOver = NPL.export()

GameOver.mode = 1

function GameOver:ShowPage(mode)
    if mode and type(mode) == 'number' then
        self.mode = mode
    end

    if ExplorerApp.curTask then
        ExplorerApp.curTask:Run()
        ExplorerApp.curTask:EnableAutoCamera(false)
    end

    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/GameProcess/GameOver/GameOver.html", "Mod.ExplorerApp.GameProcess.GameOver", 0, 0, "_fi", false)
end

function GameOver:SetPage()
    Store:Set("page/GameOver", document:GetPageCtrl())
end

function GameOver:ClosePage()
    if ExplorerApp.curTask then
        ExplorerApp.curTask:EnableAutoCamera(true)
        ExplorerApp.curTask:SetFinished()
    end

    local GameOverPage = Store:Get('page/GameOver')

    if (GameOverPage) then
        GameOverPage:CloseWindow()
    end
end

function GameOver:Confirm()

end

function GameOver:Replay()
    MainPage:SelectProject(MainPage.curProjectIndex)
end

function GameOver:Goback()
    self:ClosePage()
    MainPage:ShowPage()
end
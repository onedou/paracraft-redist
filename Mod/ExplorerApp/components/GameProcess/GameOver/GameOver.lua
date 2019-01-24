--[[
Title: UpdatePassword
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local Password = NPL.load("(gl)Mod/ExplorerApp/components/Password/UpdatePassword/UpdatePassword.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local GameOver = NPL.export()

function GameOver:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/Password/UpdatePassword/UpdatePassword.html", "Mod.ExplorerApp.Password.UpdatePassword", 0, 0, "_fi", false)
end

function GameOver:SetPage()
    Store:Set("page/UpdatePassword", document:GetPageCtrl())
end

function GameOver:ClosePage()
    local GameOverPage = Store:Get('page/GameOver')

    if (GameOverPage) then
        GameOverPage:CloseWindow()
    end
end

function GameOver:Confirm()

end
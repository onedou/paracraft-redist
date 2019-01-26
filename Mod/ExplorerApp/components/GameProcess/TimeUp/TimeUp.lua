--[[
Title: TimeUp
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local Password = NPL.load("(gl)Mod/ExplorerApp/components/GameProcess/TimeUp/TimeUp.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')

local TimeUp = NPL.export()

function TimeUp:ShowPage()
    self.playerBalance = Wallet:GetPlayerBalance()
    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/GameProcess/TimeUp/TimeUp.html", "Mod.ExplorerApp.GameProcess.TimeUp", 0, 0, "_fi", false)
end

function TimeUp:SetPage()
    Store:Set("page/TimeUp", document:GetPageCtrl())
end

function TimeUp:ClosePage()
    local TimeUpPage = Store:Get('page/TimeUp')

    if (TimeUpPage) then
        TimeUpPage:CloseWindow()
    end
end

function TimeUp:Confirm()

end
--[[
Title: Password
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local Password = NPL.load("(gl)Mod/ExplorerApp/components/Password/Password.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local SetCoins = NPl.load("../SetCoins/SetCoins.lua")

local Password = NPL.export()

function Password:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/Password/Password.html", "Mod.ExplorerApp.Password", 0, 0, "_fi", false)
end

function Password:SetPage()
    Store:Set("page/Password", document:GetPageCtrl())
end

function Password:ClosePage()
    local PasswordPage = Store:Get('page/Password')

    if (PasswordPage) then
        PasswordPage:CloseWindow()
    end
end

function Password:Confirm()

end
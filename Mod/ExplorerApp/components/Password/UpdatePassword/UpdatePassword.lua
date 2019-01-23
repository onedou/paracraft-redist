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

local UpdatePassword = NPL.export()

function UpdatePassword:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/Password/UpdatePassword/UpdatePassword.html", "Mod.ExplorerApp.Password.UpdatePassword", 0, 0, "_fi", false)
end

function UpdatePassword:SetPage()
    Store:Set("page/UpdatePassword", document:GetPageCtrl())
end

function UpdatePassword:ClosePage()
    local UpdatePasswordPage = Store:Get('page/UpdatePassword')

    if (UpdatePasswordPage) then
        UpdatePasswordPage:CloseWindow()
    end
end

function UpdatePassword:Confirm()

end
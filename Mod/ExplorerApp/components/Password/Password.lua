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
local SetCoins = NPL.load("../SetCoins/SetCoins.lua")

local Password = NPL.export()

Password.password = ''

function Password:ShowPage()
    Password.password = ''

    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/Password/Password.html", "Mod.ExplorerApp.Password", 0, 0, "_fi", false)

    local PasswordPage = Store:Get('page/Password')

    if PasswordPage then
        self:FocusPassword()
    end
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

function Password:Refresh(time)
    local PasswordPage = Store:Get('page/Password')

    if (PasswordPage) then
        PasswordPage:Refresh(time or 0.01)
    end
end

function Password:FocusPassword()
    local PasswordPage = Store:Get('page/Password')

    if not PasswordPage then
        return false
    end

    PasswordPage:FindControl('password'):Focus()
end

function Password:Confirm()
    self:ClosePage()

    SetCoins:ShowPage()
end

function Password:UpdateViewPassword()
    local PasswordPage = Store:Get('page/Password')

    if not PasswordPage then
        return false
    end

    local password = PasswordPage:GetValue('password')

    if not password then
        return false
    end

    if #password > 4 then
        PasswordPage:SetValue('password', Password.password)
        return false
    end

    Password.password = password
    PasswordPage:SetValue('password', password)

    self:Refresh(0)
    self:FocusPassword()
end
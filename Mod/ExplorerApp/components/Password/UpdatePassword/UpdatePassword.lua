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
local ParacraftDevices = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/ParacraftDevices.lua')
local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')

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
    local UpdatePasswordPage = Store:Get('page/UpdatePassword')

    if not UpdatePasswordPage then
        return false
    end

    local systemPassword = UpdatePasswordPage:GetValue('system_password')
    local password = UpdatePasswordPage:GetValue('password')
    local cfm_password = UpdatePasswordPage:GetValue('cfm_password')

    if not systemPassword or #systemPassword < 4 or
       not password or #password ~= 4 or
       not cfm_password or #cfm_password ~= 4 then
        _guihelper.MessageBox(L'密码格式错误')
        return false
    end

    if password ~= cfm_password then
        _guihelper.MessageBox(L'两次输入密码不一致')
        return false
    end

    ParacraftDevices:PwdVerfify(systemPassword, function(data, err)
        if data == 'true' then
            Wallet:SetUserPassword(cfm_password)
            self:ClosePage()
            _guihelper.MessageBox(L"更新密码成功")
        else
            _guihelper.MessageBox(L'系统密码错误')
        end
    end)
end
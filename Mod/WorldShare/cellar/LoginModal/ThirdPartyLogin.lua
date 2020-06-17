--[[
Title: third party login
Author(s):  big
Date: 2020.06.01
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local ThirdPartyLogin = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/ThirdPartyLogin.lua")
ThirdPartyLogin:Init(type)
------------------------------------------------------------
]]

local ThirdPartyLogin = NPL.export()

function ThirdPartyLogin:Init(type)
    if System.os.GetPlatform() ~= 'win32' and System.os.GetPlatform() ~= 'mac' then
        _guihelper.MessageBox(L"操作不支持此系统")
        return false
    end

    self.type = type

    local params = Mod.WorldShare.Utils.ShowWindow(400, 450, "Mod/WorldShare/cellar/LoginModal/ThirdPartyLogin.html", "ThirdPartyLogin", nil, nil, nil, nil)

    params._page:CallMethod("nplbrowser_instance", "SetVisible", true)
    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/ThirdPartyLogin')
        params._page:CallMethod("nplbrowser_instance", "SetVisible", false)
    end
end

function ThirdPartyLogin:GetUrl()
    if self.type == 'WECHAT' then
        return "https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=101403344&redirect_uri=https%3A%2F%2Fkeepwork.com&state=123456"
    end

    if self.type == "QQ" then
        return "https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=101403344&redirect_uri=https%3A%2F%2Fkeepwork.com&state=123456"
    end

    return ""
end



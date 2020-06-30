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

local Config = NPL.load("(gl)Mod/WorldShare/config/Config.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

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
        Mod.WorldShare.Store:Unsubscribe("user/SetThirdPartyLoginAuthinfo")
    end

    Mod.WorldShare.Store:Subscribe("user/SetThirdPartyLoginAuthinfo", function()
        local authType = Mod.WorldShare.Store:Get("user/authType")
        local authCode = Mod.WorldShare.Store:Get("user/authCode")

        echo("from user set third party login authinfo", true)
        echo(authType, true)
        echo(authCode, true)
    end)
end

function ThirdPartyLogin:GetUrl()
    local redirect_uri = Mod.WorldShare.Utils.EncodeURIComponent(KeepworkService:GetKeepworkUrl() .. '/p/third-login/')

    if self.type == 'WECHAT' then
        local clientId = Config.QQ[KeepworkService:GetEnv()].clientId

        return "https://open.weixin.qq.com/connect/qrconnect?appid=" .. clientId .. "&redirect_uri=" .. redirect_uri .. "&response_type=code&scope=SCOPE&state=STATE#wechat_redirect"
    end

    if self.type == "QQ" then
        local clientId = Config.QQ[KeepworkService:GetEnv()].clientId

        echo("https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=" .. clientId .. "&redirect_uri=" .. redirect_uri .. "&state=123456", true)

        return "https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=" .. clientId .. "&redirect_uri=" .. redirect_uri .. "&state=123456"
    end

    return ""
end



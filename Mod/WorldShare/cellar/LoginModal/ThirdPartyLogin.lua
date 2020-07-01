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

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

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

        KeepworkServiceSession:CheckOauthUserExisted(authType, authCode, function(bExisted, data)
            if bExisted then

            else
                Mod.WorldShare.MsgBox:Dialog(
                    "NoThirdPartyAccountNotice",
                    L"检测到该第三方账号还未绑定到账号，请绑定到已有账号或者新建账号进行绑定",
                    {
                        Title = L"补充账号信息",
                        Yes = L"绑定到已有账号",
                        No = L"新建账号并绑定"
                    },
                    function(res)
                        if res and res == _guihelper.DialogResult.Yes then
                            
                        end

                        if res and res == _guihelper.DialogResult.No then
                           
                        end
                    end,
                    _guihelper.MessageBoxButtons.YesNo,
                    {
                        Yes = {
                            marginLeft = "40px",
                            width = "120px"
                        },
                        No = {
                            width = "120px"
                        }
                    }
                )

                return false
            end
        end)

        params._page:CloseWindow()
    end)
end

function ThirdPartyLogin:GetUrl()
    local redirect_uri = Mod.WorldShare.Utils.EncodeURIComponent(KeepworkService:GetKeepworkUrl() .. '/p/third-login/')
    local sysTag = ''

    if System.os.GetPlatform() == 'win32' then
        sysTag = "WIN32"
    elseif System.os.GetPlatform() == 'mac' then
        sysTag = "MAC"
    end

    if self.type == 'WECHAT' then
        local clientId = KeepworkServiceSession:GetOauthClientId("WECHAT")
        local state = "WECHAT|" .. sysTag .. "|8099|" .. System.Encoding.guid.uuid()

        return
            format(
                "https://open.weixin.qq.com/connect/qrconnect?appid=%s&redirect_uri=%s&response_type=code&scope=snsapi_login&state=%s#wechat_redirect",
                clientId,
                redirect_uri,
                state
            )
    end

    if self.type == "QQ" then
        local clientId = KeepworkServiceSession:GetOauthClientId("QQ")
        local state = "QQ|" .. sysTag .. "|8099|" .. System.Encoding.guid.uuid()

        return 
            format(
                "https://graph.qq.com/oauth2.0/authorize?response_type=code&client_id=%s&redirect_uri=%s&state=%s",
                clientId,
                redirect_uri,
                state
            )
    end

    return ""
end


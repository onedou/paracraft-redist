--[[
Title: register modal
Author(s):  big
Date: 2019.9.20
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local RegisterModal = NPL.load("(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua")
RegisterModal:ShowPage()
------------------------------------------------------------
]]

local Validated = NPL.load("(gl)Mod/WorldShare/helper/Validated.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

local RegisterModal = NPL.export()

RegisterModal.m_mode = "account"
RegisterModal.account = ""
RegisterModal.password = ""
RegisterModal.phonenumber = ""
RegisterModal.phonepassword = ""
RegisterModal.phonecaptcha = ""
RegisterModal.bindphone = nil

function RegisterModal:ShowPage(callback)
    local LoginModalPage = Mod.WorldShare.Store:Get("page/LoginModal")

    if LoginModalPage then
        LoginModalPage:CloseWindow()
    end

    self.callback = callback
    self.m_mode = "account"
    self.account = ""
    self.password = ""
    self.phonenumber = ""
    self.phonepassword = ""
    self.phonecaptcha = ""
    self.bindphone = nil

    Mod.WorldShare.Utils.ShowWindow(360, 360, "Mod/WorldShare/cellar/RegisterModal/RegisterModal.html", "RegisterModal")
end

function RegisterModal:ShowUserAgreementPage()
    Mod.WorldShare.Utils.ShowWindow(400, 580, "Mod/WorldShare/cellar/RegisterModal/UserAgreement.html", "UserAgreement")
end

function RegisterModal:ShowBindingPage()
    Mod.WorldShare.Utils.ShowWindow(360, 480, "Mod/WorldShare/cellar/RegisterModal/Binding.html", "Binding")
end

function RegisterModal:ShowClassificationPage()
    Mod.WorldShare.Utils.ShowWindow(
        370,
        280,
        "Mod/WorldShare/cellar/RegisterModal/BindPhoneInAccountRegister.html",
        "RegisterModal/BindPhoneInAccountRegister",
        nil,
        nil,
        nil,
        nil,
        10
    )
end

function RegisterModal:GetServerList()
    local serverList = KeepworkService:GetServerList()

    if self.registerServer then
        for key, item in ipairs(serverList) do
            item.selected = nil
            if item.value == self.registerServer then
                item.selected = true
            end
        end
    end

    return serverList
end

function RegisterModal:Register(page)
    local loginServer = KeepworkService:GetEnv()

    if not self.account or self.account == "" then
        return false
    end

    if #self.password < 6 then
        return false
    end

    if #self.phonenumber == 0 and (not self.captcha or self.captcha == "") then
        return false
    end

    if #self.phonenumber > 0 and not Validated:Phone(self.phonenumber) then
        return false
    end

    if #self.phonenumber > 0 and #self.phonecaptcha == 0 then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"正在注册，请稍后...", 10000, L"链接超时", 500, 120)

    KeepworkServiceSession:Register(self.account, self.password, self.captcha, self.phonenumber, self.phonecaptcha, self.bindphone, function(state, err)
        Mod.WorldShare.MsgBox:Close()

        if err == 422 then
            GameLogic.AddBBS(nil, L"未知错误", 5000, "0 255 0")
            return false
        end

        if state and state.id then
            if state.code then
                GameLogic.AddBBS(nil, state.message, 5000, "0 0 255")
            else
                if self.m_mode == "account" then
                    self:ShowClassificationPage()

                    GameLogic.AddBBS(nil, L"注册成功", 5000, "0 255 0")
                end
            end

            if page then
                page:CloseWindow()
            end

            if type(self.callback) == 'function' then
                self.callback()
            end

            return true
        end

        GameLogic.AddBBS(nil, format("%s%s(%d)", L"注册失败，错误信息：", state.message or "", state.code or ""), 5000, "255 0 0")
        Mod.WorldShare.MsgBox:Close()
    end)
end

function RegisterModal:Classification(phonenumber, captcha, callback)
    KeepworkServiceSession:ClassificationPhone(phonenumber, captcha, function(data, err)
        if data.data then
            GameLogic.AddBBS(nil, L"实名认证成功", 5000, "0 255 0")

            if type(callback) == "function" then
                callback()
            end
            return true
        end

        GameLogic.AddBBS(nil, format("%s%s(%d)", L"认证失败，错误信息：", data.message, data.code), 5000, "255 0 0")
    end)
end

function RegisterModal:ClassificationAndBind(phonenumber, captcha, callback)
    KeepworkServiceSession:ClassificationAndBindPhone(phonenumber, captcha, function(data, err)
        if data.data then
            GameLogic.AddBBS(nil, L"实名认证成功，手机号绑定成功", 5000, "0 255 0")

            if type(callback) == "function" then
                callback()
            end
            return true
        end

        GameLogic.AddBBS(nil, format("%s%s(%d)", L"认证失败，错误信息：", data.message, data.code), 5000, "255 0 0")
    end)
end

function RegisterModal:Bind(method, ...)
    if method == 'bindphone' then
        local phonenumber, phonecaptcha, callback = ...;

        if not Validated:Phone(phonenumber) then
            GameLogic.AddBBS(nil, L"手机号码格式错误", 3000, "255 0 0")
            return false
        end

        if phonecaptcha == '' then
            GameLogic.AddBBS(nil, L"手机验证码不能为空", 3000, "255 0 0")
            return false
        end

        Mod.WorldShare.MsgBox:Show(L"请稍后...")
        KeepworkServiceSession:BindPhone(phonenumber, phonecaptcha, function(data, err)
            Mod.WorldShare.MsgBox:Close()

            if err == 200 and data.data then
                GameLogic.AddBBS(nil, L"绑定成功", 3000, "0 255 0")
                if type(callback) == "function" then
                    callback()
                end
                return true
            end

            GameLogic.AddBBS(nil, format("%s%s(%d)", L"绑定失败，错误信息：", data.message, data.code), 5000, "255 0 0")
        end)

        return true
    end

    if method == 'bindemail' then
        local email, emailcaptcha, callback = ...;

        if not Validated:Email(email) then
            GameLogic.AddBBS(nil, L"EMAIL格式错误", 3000, "255 0 0")
            return false
        end

        if emailcaptcha == '' then
            GameLogic.AddBBS(nil, L"EMAIL验证码不能为空", 3000, "255 0 0")
            return false
        end

        Mod.WorldShare.MsgBox:Show(L"请稍后...")
        KeepworkServiceSession:BindEmail(email, emailcaptcha, function(data, err)
            Mod.WorldShare.MsgBox:Close()

            if err == 409 then
                GameLogic.AddBBS(nil, L"邮箱已被绑定", 3000, "255 0 0")
                return false
            end

            if err == 200 and data.data then
                GameLogic.AddBBS(nil, L"绑定成功", 3000, "0 255 0")
                if type(callback) == "function" then
                    callback()
                end
                return true
            end

            GameLogic.AddBBS(nil, format("%s%s(%d)", L"绑定失败，错误信息：", data.message, data.code), 5000, "255 0 0")
        end)

        return true
    end
end
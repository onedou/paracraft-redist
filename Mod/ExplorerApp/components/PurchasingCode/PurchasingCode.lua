--[[
Title: Purchasing Code
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local PurchasingCode = NPL.load("(gl)Mod/ExplorerApp/components/PurchasingCode/PurchasingCode.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Notice = NPL.load("./Notice/Notice.lua")
local Result = NPL.load("./Result/Result.lua")
local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')
local ParacraftDevices = NPL.load('(gl)Mod/ExplorerApp/service/KeepworkService/ParacraftDevices.lua')

local PurchasingCode = NPL.export()

PurchasingCode.balance = 0

function PurchasingCode:ShowPage()
    self.balance = Wallet:GetUserBalance()

    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/PurchasingCode/PurchasingCode.html", "Mod.ExplorerApp.PurchasingCode", 0, 0, "_fi", false)
end

function PurchasingCode:SetPage()
    Store:Set("page/PurchasingCode", document:GetPageCtrl())
end

function PurchasingCode:ClosePage()
    local PurchasingCodePage = Store:Get('page/PurchasingCode')

    if (PurchasingCodePage) then
        PurchasingCodePage:CloseWindow()
    end
end

function PurchasingCode:GetNotice()
    self:ClosePage()
    Notice:ShowPage()
end

function PurchasingCode:Confirm()
    local PurchasingCodePage = Store:Get('page/PurchasingCode')

    if not PurchasingCodePage then
        return false
    end

    local code = PurchasingCodePage:GetValue('code')

    if not code or #code == 0 then
        return false
    end

    ParacraftDevices:Recharge(code, function(data, err)
        self.balance = self.balance + tonumber(data)
        Wallet:SetUserBalance(self.balance)
        self:ClosePage()
        Result:ShowPage(data)
    end)

end
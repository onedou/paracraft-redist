--[[
Title: Result
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local Result = NPL.load("(gl)Mod/ExplorerApp/components/PurchasingCode/Result/Result.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')
local PurchasingCode = NPL.load("(gl)Mod/ExplorerApp/components/PurchasingCode/PurchasingCode.lua")
local SetCoins = NPL.load('../../SetCoins/SetCoins.lua')

local Result = NPL.export()

Result.getCoins = ''

function Result:ShowPage(coins)
    self.balance = Wallet:GetUserBalance()
    self.getCoins = coins

    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/components/PurchasingCode/Result/Result.html", "Mod.ExplorerApp.PurchasingCode.Result", 0, 0, "_fi", false, 3)
end

function Result:SetPage()
    Store:Set("page/Result", document:GetPageCtrl())
end

function Result:ClosePage()
    local ResultPage = Store:Get('page/Result')

    if (ResultPage) then
        SetCoins:ShowPage()
        ResultPage:CloseWindow()
    end
end

function Result:PurchasingCode()
    self:ClosePage()
    PurchasingCode:ShowPage()
end
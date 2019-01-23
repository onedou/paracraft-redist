--[[
Title: Set Coins
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local SetCoins = NPL.load("(gl)Mod/ExplorerApp/components/SetCoins/SetCoins.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local UpdatePassword = NPL.load("../Password/UpdatePassword/UpdatePassword.lua")
local PurchasingCode = NPL.load("../PurchasingCode/PurchasingCode.lua")

local SetCoins = NPL.export()

function SetCoins:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/SetCoins/SetCoins.html", "Mod.ExplorerApp.SetCoins", 0, 0, "_fi", false)
end

function SetCoins:SetPage()
    Store:Set("page/SetCoins", document:GetPageCtrl())
end

function SetCoins:ClosePage()
    local SetCoinsPage = Store:Get('page/SetCoins')

    if (SetCoinsPage) then
        SetCoinsPage:CloseWindow()
    end
end

function SetCoins:UpdatePassword()
    self:ClosePage()
    UpdatePassword:ShowPage()
end

function SetCoins:PurchasingCode()
    self:ClosePage()
    PurchasingCode:ShowPage()
end
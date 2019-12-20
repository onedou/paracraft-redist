--[[
Title: Notice
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local Notice = NPL.load("(gl)Mod/ExplorerApp/components/Notice/Notice.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local Notice = NPL.export()

function Notice:ShowPage()
    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/ExplorerApp/components/PurchasingCode/Notice/Notice.html", "Mod.ExplorerApp.PurchasingCode.Notice", 0, 0, "_fi", false, 3)
end

function Notice:SetPage()
    Store:Set("page/Notice", document:GetPageCtrl())
end

function Notice:ClosePage()
    local NoticePage = Store:Get('page/Notice')

    if (NoticePage) then
        NoticePage:CloseWindow()
    end
end
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

local Result = NPL.export()

function Result:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/PurchasingCode/Result/Result.html", "Mod.ExplorerApp.PurchasingCode.Result", 0, 0, "_fi", false)
end

function Result:SetPage()
    Store:Set("page/Result", document:GetPageCtrl())
end

function Result:ClosePage()
    local ResultPage = Store:Get('page/Result')

    if (ResultPage) then
        ResultPage:CloseWindow()
    end
end
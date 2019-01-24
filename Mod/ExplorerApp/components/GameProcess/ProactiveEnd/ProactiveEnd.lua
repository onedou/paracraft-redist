--[[
Title: ProactiveEnd
Author(s):  big
Date: 2019.01.23
Place: Foshan
use the lib:
------------------------------------------------------------
local ProactiveEnd = NPL.load("(gl)Mod/ExplorerApp/components/GameProcess/ProactiveEnd/ProactiveEnd.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local ProactiveEnd = NPL.export()

function ProactiveEnd:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/GameProcess/ProactiveEnd/ProactiveEnd.html", "Mod.ExplorerApp.GameProcess.ProactiveEnd", 0, 0, "_fi", false)
end

function ProactiveEnd:SetPage()
    Store:Set("page/ProactiveEnd", document:GetPageCtrl())
end

function ProactiveEnd:ClosePage()
    local ProactiveEndPage = Store:Get('page/ProactiveEnd')

    if (ProactiveEndPage) then
        ProactiveEndPage:CloseWindow()
    end
end

function ProactiveEnd:Confirm()

end
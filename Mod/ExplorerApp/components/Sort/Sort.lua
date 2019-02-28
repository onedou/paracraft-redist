--[[
Title: Sort Component
Author(s):  big
Date: 2019.01.25
Place: Foshan
use the lib:
------------------------------------------------------------
local Sort = NPL.load("(gl)Mod/ExplorerApp/components/Sort/Sort.lua")
------------------------------------------------------------
]]
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local MainPage = NPL.load("../MainPage.lua")

local Sort = NPL.export()

Sort.position = {
    x = 0,
    y = 0
}

function Sort:ShowPage(x, y)
    self.position.x = x
    self.position.y = y

    local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/Sort/Sort.html", "Mod.ExplorerApp.Sort", 0, 0, "_fi", false, 3)
end

function Sort:SetPage()
    Store:Set("page/Sort", document:GetPageCtrl())
end

function Sort:ClosePage()
    local SortPage = Store:Get('page/Sort')

    if SortPage then
        SortPage:CloseWindow()
    end
end

function Sort:GetSortIndex()
    return Store:Get('explorer/selectSortIndex')
end

function Sort:GetSortList()
    return Store:Get('explorer/sortList')
end

function Sort:SetSortIndex(index)
    MainPage.curPage = 1
    Store:Set('explorer/selectSortIndex', index)
    self:ClosePage()
    MainPage:UpdateSort()
end
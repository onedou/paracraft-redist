--[[
Title: Explorer App Page
Author(s):  big
Date: 2019.01.21
Place: Foshan
use the lib:
------------------------------------------------------------
local MainPage = NPL.load("(gl)Mod/ExplorerApp/components/MainPage.lua")
------------------------------------------------------------
]]
local Screen = commonlib.gettable("System.Windows.Screen")

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

local MainPage = NPL.export()

MainPage.categoryTree = {
    {key = 0, value = L'精选'},
    {key = 1, value = L'单人'},
    {key = 2, value = L'双人'},
    {key = 3, value = L'对战'},
    {key = 4, value = L'动画'},
    {key = 5, value = L'收藏'}
}

function MainPage:ShowPage()
	local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/MainPage.html", "Mod.ExplorerApp.MainPage", 0, 0, "_fi", false)

    local MainPagePage = Store:Get('page/MainPage')

    if MainPagePage then
        MainPagePage:GetNode('categoryTree'):SetAttribute('DataSource', self.categoryTree)
        MainPagePage:GetNode('worksTree'):SetAttribute('DataSource', {
            {
                projectId = 656
            }
        })
    end

	Screen:Connect("sizeChanged", MainPage, MainPage.OnScreenSizeChange, "UniqueConnection")
    MainPage.OnScreenSizeChange()
end

function MainPage:SetPage()
	Store:Set("page/MainPage", document:GetPageCtrl())
end

function MainPage:Refresh(times)
    local MainPagePage = Store:Get('page/MainPage')

    if MainPagePage then
        MainPagePage:Refresh(times or 0.01)
    end
end

function MainPage:Close()
    local MainPagePage = Store:Get('page/MainPage')

    if MainPagePage then
        MainPagePage:CloseWindow()
    end
end

function MainPage.OnScreenSizeChange()
	local MainPage = Store:Get('page/MainPage')

    if (not MainPage) then
        return false
    end

    local height = math.floor(Screen:GetHeight())
    local width = math.floor(Screen:GetWidth())

    local areaNode = MainPage:GetNode("area")
    areaNode:SetCssStyle('height', height)
    areaNode:SetCssStyle('width', width)
    
    local stripNode = MainPage:GetNode("strip")
    stripNode:SetCssStyle('margin-left', (width - 960) / 2)

    local areaContentNode = MainPage:GetNode("area_content")
    areaContentNode:SetCssStyle('height', (height - 45))
    areaContentNode:SetCssStyle('margin-left', (width - 960) / 2)

    -- local marginLeft = math.floor(Screen:GetWidth())

    -- areaNode:SetCssStyle('margin-left', marginLeft)

    -- local areaContentNode = HistoryManagerPage:GetNode("area_content")


    -- areaContentNode:SetCssStyle('height', height - 47)
    -- areaContentNode:SetCssStyle('margin-left', marginLeft)

    -- local splitNode = HistoryManagerPage:GetNode("area_split")

    -- splitNode:SetCssStyle("height", height - 47)

    MainPage:Refresh(0)
end

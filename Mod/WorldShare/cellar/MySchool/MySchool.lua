--[[
Title: my school page
Author(s):  big
Date: 2019.09.11
Desc: 
use the lib:
------------------------------------------------------------
local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
------------------------------------------------------------
]]

local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer")

local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

local MySchool = NPL.export()

function MySchool:Show()
    local params = Mod.WorldShare.Utils.ShowWindow(800, 400, "Mod/WorldShare/cellar/MySchool/MySchool.html", "MySchool")
end

function MySchool:SetPage()
    Mod.WorldShare.Store:Set('page/MySchoolPage', document:GetPageCtrl())
end

function MySchool:Close()
    local MySchoolPage = Mod.WorldShare.Store:Get('page/MySchoolPage')

    if MySchoolPage then
        MySchoolPage:CloseWindow()
    end
end
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
    local params = Mod.WorldShare.Utils.ShowWindow(600, 300, "Mod/WorldShare/cellar/MySchool/MySchool.html", "MySchool")
end

function MySchool:ShowJoinSchool()
    local params = Mod.WorldShare.Utils.ShowWindow(600, 330, "Mod/WorldShare/cellar/MySchool/JoinSchool.html", "JoinSchool")
end

function MySchool:ShowJoinInstitute()
    local params = Mod.WorldShare.Utils.ShowWindow(600, 200, "Mod/WorldShare/cellar/MySchool/JoinInstitute.html", "JoinInstitute")
end

function MySchool:ShowRecordSchool()
    local params = Mod.WorldShare.Utils.ShowWindow(600, 300, "Mod/WorldShare/cellar/MySchool/RecordSchool.html", "RecordSchool")
end

function MySchool:GetProvinces()

end
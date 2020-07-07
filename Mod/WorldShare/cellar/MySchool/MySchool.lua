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

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceLesson = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Lesson.lua")

local MySchool = NPL.export()

function MySchool:Show()
    Mod.WorldShare.MsgBox:Show(L"请稍后...", nil, nil, nil, nil, 6)

    local params = Mod.WorldShare.Utils.ShowWindow(600, 300, "Mod/WorldShare/cellar/MySchool/MySchool.html", "MySchool")

    self:GetMyAllOrgsAndSchool(function(data)
        Mod.WorldShare.MsgBox:Close()
        echo('from get my all orgs and school!!!!!', true)
        echo(data, true)
    end)
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

function MySchool:GetMyAllOrgsAndSchool(callback)
    KeepworkServiceLesson:GetUserAllOrgs(function()
        
    end)
end

function MySchool:GetProvinces()

end
--[[
Title: KeepworkService Lesson
Author(s):  big
Date:  2019.09.22
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceLesson = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Lesson.lua")
------------------------------------------------------------
]]

-- api
local LessonOrganizationsApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/LessonOrganizations.lua")

local KeepworkServiceLesson = NPL.export()

function KeepworkServiceLesson:GetUserAllOrgs(callback)
    if type(callback) ~= "function" then
        return false
    end

    LessonOrganizationsApi:GetUserAllOrgs(
        function(data, err)
            if err == 200 then
                if data and data.data and type(data.data.allOrgs) == 'table' then
                    callback(data.data.allOrgs, true)
                end
            end
        end
    )
end

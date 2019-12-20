--[[
Title: Keepwork Projects Service
Author(s):  big
Date:  2019.01.25
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceProject = NPL.load("(gl)Mod/ExplorerApp/service/KeepworkService/Project.lua")
------------------------------------------------------------
]]
local WorldShareKeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Projects.lua')
local KeepworkSystemTagApi = NPL.load('(gl)Mod/ExplorerApp/api/Keepwork/SystemTag.lua')

local KeepworkServiceProject = NPL.export()

-- url: /projects/search
-- method: POST
-- param: x-page number
-- param: x-per-page number
-- param: classifyTags-like string
-- return object
function KeepworkServiceProject:GetProjectByIds(mainId, projectIds, pages, callback)
    KeepworkProjectsApi:SearchForParacraft(
        pages and pages.perPage and pages.perPage or 10,
        pages and pages.page and pages.page or 1,
        { tagIds = { mainId }, projectIds = projectIds },
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            if err ~= 200 or not data then
                callback()
                return false
            end

            callback(data, err)
        end
    )
end

-- redirect to keepwork get project
-- url:/systemTags/search?classify=1
-- method: POST
-- param: x-page number
-- param: x-per-page number
-- param: classifyTags-like string
-- return object
function KeepworkServiceProject:GetProjectDetailById(kpProjectId, callback, noTryStatus)
    WorldShareKeepworkServiceProject:GetProject(kpProjectId, callback, noTryStatus)
end

function KeepworkServiceProject:GetAllTags(callback)
    KeepworkSystemTagApi:Search(callback)
end

-- get recommend works
function KeepworkServiceProject:GetRecommandProjects(tagId, mainId, pages, callback)
    if type(tagId) ~= 'number' or type(mainId) ~= 'number' then
        return false
    end

    KeepworkProjectsApi:SearchForParacraft(
        pages and pages.perPage and pages.perPage or 10,
        pages and pages.page and pages.page or 1,
        { tagIds = { tagId, mainId }, sortTag = tagId },
        callback
    )
end
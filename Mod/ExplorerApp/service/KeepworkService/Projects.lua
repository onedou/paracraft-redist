--[[
Title: Keepwork Projects Service
Author(s):  big
Date:  2019.01.25
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceProjects = NPL.load("(gl)Mod/ExplorerApp/service/KeepworkService/Projects.lua")
------------------------------------------------------------
]]
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkProjectsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Projects.lua')

local Projects = NPL.export()

-- url: /projects/search
-- method: POST
-- param: x-page number
-- param: x-per-page number
-- param: classifyTags-like string
-- return object
function Projects:GetProjectsByFilter(filter, sort, pages, callback)
    local headers = KeepworkService:GetHeaders()
    local params = {
        ["x-page"] = pages and pages.page and pages.page or 1,
        ["x-per-page"] = pages and pages.perPage and pages.perPage or 10
    }

    if type(filter) == 'string' then
        params["classifyTags-like"] = format("%%%s%%", filter)
    end

    if type(filter) == 'table' then
        local allFilters = commonlib.Array:new()

        for key, item in ipairs(filter) do
            local curFilter = { classifyTags = { ["$like"] = '' } }

            curFilter.classifyTags['$like'] = format("%%%s%%", item)

            allFilters:push_back(curFilter)
        end

        params["$and"] = allFilters
    end

    if type(sort) == 'string' then
        params['x-order'] = sort
    end

    KeepworkService:Request(
        format("/projects/search", filterUrl),
        "POST",
        params,
        headers,
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

-- url: /projects/search
-- method: POST
-- param: x-page number
-- param: x-per-page number
-- param: classifyTags-like string
-- return object
function Projects:GetProjectById(projectIds, sort, pages, callback)
    local headers = KeepworkService:GetHeaders()
    local params = {
        ["$and"] = {
            { classifyTags = { ["$like"] = '%paracraft专用%' } },
            { id = { ["$in"] = projectIds } },
        },
        ["x-page"] = pages and pages.page and pages.page or 1,
        ["x-per-page"] = pages and pages.perPage and pages.perPage or 10
    }

    if type(sort) == 'string' then
        params['x-order'] = sort
    end

    KeepworkService:Request(
        format("/projects/search", filterUrl),
        "POST",
        params,
        headers,
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
function Projects:GetProjectDetailById(projectId, callback, noTryStatus)
    KeepworkService:GetProject(projectId, callback, noTryStatus)
end

function Projects:GetAllTags(callback)
    local headers = KeepworkService:GetHeaders()

    KeepworkService:Request(
        "/systemTags/search?classify=1&x-order=extra.sn-asc",
        "POST",
        {},
        headers,
        function(data, err)
            if type(callback) == 'function' then
                callback(data, err)
            end
        end
    )
end

-- get recommend works
function Projects:GetRecommandProjects(tagId, mainId, pages, callback)
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
--[[
Title: Keepwork Service Projects
Author(s):  big
Date:  2019.01.25
Place: Foshan
use the lib:
------------------------------------------------------------
local Projects = NPL.load("(gl)Mod/ExplorerApp/service/KeepworkService/Projects.lua")
------------------------------------------------------------
]]
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')

local Projects = NPL.export()

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

function Projects:GetProjectById(projectIds, sort, callback)
    local headers = KeepworkService:GetHeaders()
    local params = {
        ["$and"] = {
            { classifyTags = { ["$like"] = '%paracraft专用%' } },
            { id = { ["$in"] = projectIds } },
        }
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

function Projects:GetProjectDetailById(projectId, callback)
    KeepworkService:GetProject(projectId, callback)
end

function Projects:GetAllTags(callback)
    local headers = KeepworkService:GetHeaders()

    KeepworkService:Request(
        "/systemTags/search",
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
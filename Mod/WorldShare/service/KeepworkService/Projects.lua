--[[
Title: KeepworkService
Author(s):  big
Date:  2018.06.21
Place: Foshan
use the lib:
------------------------------------------------------------
local Projects = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Projects.lua")
------------------------------------------------------------
]]
local KeepworkService = NPL.load('../KeepworkService.lua')

local Projects = NPL.export()

function Projects:GetProjects(filter, callback)
    local headers = KeepworkService:GetHeaders()
    local filterUrl = ''

    if type(filter) == 'string' then
        filterUrl = format("classifyTags-like=%%|%s|%%", filter or '')
    end

    KeepworkService:Request(
        format("/projects/search", filterUrl),
        "POST",
        nil,
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
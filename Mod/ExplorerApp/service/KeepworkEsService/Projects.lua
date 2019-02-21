--[[
Title: Keepwork Es Service Projects
Author(s):  big
Date:  2019.02.21
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkEsServiceProjects = NPL.load("(gl)Mod/ExplorerApp/service/KeepworkEsService/Projects.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

local KeepworkEsService = NPL.load("(gl)Mod/WorldShare/service/KeepworkEsService.lua")

local Projects = NPL.export()

function Projects:GetEsProjectsByFilter(filter, sort, pages, callback)
    local sysTags = Utils:UrlEncode(Utils:Implode("|", filter))

    params = {
        ['sys_tags'] = sysTags,
        page = pages and pages.page and pages.page or 1,
        ["per-page"] = pages and pages.perPage and pages.perPage or 10,
        sort = sort
    }

    KeepworkEsService:Request("/projects", "GET", params, KeepworkEsService:GetHeaders(), callback)
end
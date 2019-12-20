--[[
Title: Keepwork Es Service Projects
Author(s):  big
Date:  2019.02.21
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkEsServiceProject = NPL.load("(gl)Mod/ExplorerApp/service/KeepworkEsService/Project.lua")
------------------------------------------------------------
]]
local EsProjectsApi = NPL.load('(gl)Mod/ExplorerApp/api/Es/Projects.lua')

local KeepworkEsServiceProject = NPL.export()

function KeepworkEsServiceProject:GetEsProjectsByFilter(filter, sort, pages, callback)
    local sysTags = Mod.WorldShare.Utils.UrlEncode(Mod.WorldShare.Utils.Implode("|", filter))

    local params = {
        ['sys_tags'] = sysTags,
        page = pages and pages.page and pages.page or 1,
        ["per-page"] = pages and pages.perPage and pages.perPage or 10,
        sort = sort
    }

    EsProjectsApi:Projects(params, callback)
end
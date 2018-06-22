--[[
Title: GitService
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/store/Global.lua")

local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")

local GitService = commonlib.inherit(nil, commonlib.gettable("Mod.WorldShare.service.GitService"))

function GitService:ctor()
    self.dataSourceInfo = GlobalStore.get("dataSourceInfo")
    self.dataSourceType = self.dataSourceInfo.dataSourceType
end

function GitService:create(foldername, callback)
    if (self.dataSourceType == "github") then
        GithubService:new():create(foldername, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():create(foldername, callback)
    end
end

function GitService:getContent(foldername, path, projectId, callback)
    if (self.dataSourceType == "github") then
        GithubService:new():getContent(foldername, path, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():getContent(path, projectId, callback)
    end
end

function GitService:getContentWithRaw()
    if (self.dataSourceType == "github") then
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():getContentWithRaw(path, callback, projectId)
    end
end

function GitService:upload(projectId, foldername, filename, content, callback)
    if (self.dataSourceType == "github") then
        GithubService:new():upload(foldername, filename, content, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():upload(projectId, filename, content, callback)
    end
end

function GitService:update(projectId, foldername, filename, content, sha, callback)
    if (self.dataSourceType == "github") then
        GithubService:new():update(foldername, filename, content, sha, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():update(projectId, filename, content, callback)
    end
end

function GitService:deleteFile(projectId, foldername, path, sha, callback)
    if (self.dataSourceType == "github") then
        GithubService:new():deleteFile(foldername, path, sha, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():deleteFile(projectId, path, callback)
    end
end

function GitService:getTree(projectId, foldername, commitId, callback)
    if (self.dataSourceType == "github") then
        GithubService:new():getTree(foldername, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():getTree(projectId, commitId, callback)
    end
end

function GitService:getCommits(foldername, callback, projectId)
    if (loginMain.dataSourceType == "github") then
        GithubService:new():getCommits(foldername, callback)
    elseif (loginMain.dataSourceType == "gitlab") then
        GitlabService:new():getCommits(callback, projectId, foldername)
    end
end

function GitService:getWorldRevision(foldername, callback)
    if (self.dataSourceType == "github") then
        GithubService:new():getWorldRevision(foldername, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():getWorldRevision(foldername, callback)
    end
end

function GitService.getProjectId()
    if (self.dataSourceType == "github") then
    elseif (self.dataSourceType == "gitlab") then
        return GitlabService.projectId
    end
end

function GitService.setProjectId(projectId)
    if (self.dataSourceType == "github") then
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():setProjectId(foldername)
    end
end

function GitService:getProjectIdByName(name, callback)
    GitlabService:new():getProjectIdByName(name, callback)
end

function GitService:deleteResp(projectId, foldername, callback)
    if (self.dataSourceType == "github") then
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:new():deleteResp(projectId, callback)
    end
end

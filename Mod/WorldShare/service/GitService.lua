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

local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")

local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")

function GitService:ctor()
    self.dataSourceInfo = GlobalStore.get("dataSourceInfo")
    self.dataSourceType = self.dataSourceInfo.dataSourceType
end

function GitService:create(foldername, callback)
    if (self.dataSourceType == "github") then
        GithubService:create(foldername, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:create(foldername, callback)
    end
end

function GitService:getContent(foldername, path, projectId, callback)
    if (self.dataSourceType == "github") then
        GithubService:getContent(foldername, path, callback)
    elseif (self.dataSourceType == "gitlab") then
        echo(123123213)
        GitlabService:getContent(path, projectId, callback)
    end
end

function GitService:getContentWithRaw()
    if (self.dataSourceType == "github") then
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:getContentWithRaw(path, callback, projectId)
    end
end

function GitService:upload(foldername, filename, file_content_t, callback, projectId)
    if (self.dataSourceType == "github") then
        GithubService:upload(foldername, filename, file_content_t, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:writeFile(filename, file_content_t, callback, projectId, foldername)
    end
end

function GitService:update(foldername, filename, file_content_t, sha, callback, projectId)
    if (self.dataSourceType == "github") then
        GithubService:update(foldername, filename, file_content_t, sha, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:update(filename, file_content_t, sha, callback, projectId, foldername)
    end
end

function GitService:deleteFile(foldername, path, sha, callback, projectId)
    if (self.dataSourceType == "github") then
        GithubService:deleteFile(foldername, path, sha, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:deleteFile(path, sha, callback, projectId, foldername)
    end
end

function GitService:getTree(foldername, callback, commitId, projectId)
    if (self.dataSourceType == "github") then
        GithubService:getTree(foldername, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:getTree(callback, commitId, projectId, foldername)
    end
end

function GitService:getCommits(foldername, callback, projectId)
    if (loginMain.dataSourceType == "github") then
        GithubService:getCommits(foldername, callback)
    elseif (loginMain.dataSourceType == "gitlab") then
        GitlabService:getCommits(callback, projectId, foldername)
    end
end

-- function GitService:getUrl(url, callback)
--     if(loginMain.dataSourceType == "github") then

--     elseif(loginMain.dataSourceType == "gitlab") then
--         GitlabService:apiGet(url, callback);
--     end
-- end

function GitService:getWorldRevison(foldername, callback)
    if (self.dataSourceType == "github") then
        GithubService:getWorldRevison(foldername, callback)
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:getWorldRevison(foldername, callback)
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
        GitlabService:setProjectId(foldername)
    end
end

function GitService:getProjectIdByName(datasource, callback)
    GitlabService:getProjectIdByName(datasource, callback)
end

function GitService:deleteResp(foldername, callback)
    if (self.dataSourceType == "github") then
    elseif (self.dataSourceType == "gitlab") then
        GitlabService:deleteResp(foldername, callback)
    end
end

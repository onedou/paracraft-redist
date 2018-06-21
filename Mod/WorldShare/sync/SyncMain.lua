--[[
Title: SyncMain
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");
local SyncMain  = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua")
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua")
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
NPL.load("(gl)Mod/WorldShare/main.lua")
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncToDataSource.lua")

local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld")
local SyncGUI = commonlib.gettable("Mod.WorldShare.sync.SyncGUI")
local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local SyncToDataSource = commonlib.gettable("Mod.WorldShare.sync.SyncToDataSource")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")

SyncMain.SyncPage = nil
SyncMain.DeletePage = nil
SyncMain.BeyondPage = nil
SyncMain.finish = true
SyncMain.worldDir = {}
SyncMain.foldername = {}

function SyncMain:ctor()
end

function SyncMain:init()
    SyncMain.worldName = nil

    -- 没有登陆则直接使用离线模式
    if (loginMain.IsSignedIn()) then
        SyncCompare:syncCompare()
    end
end

function SyncMain.GetWorldFolder()
    return LocalLoadWorld.GetWorldFolder()
end

function SyncMain.GetWorldFolderFullPath()
    return LocalLoadWorld.GetWorldFolderFullPath()
end

function SyncMain.setSyncPage()
    SyncMain.SyncPage = document:GetPageCtrl()
end

function SyncMain.setDeletePage()
    SyncMain.DeletePage = document:GetPageCtrl()
end

function SyncMain.setBeyondPage()
    SyncMain.BeyondPage = document:GetPageCtrl()
end

function SyncMain.closeDeletePage()
    SyncMain.DeletePage:CloseWindow()
end

function SyncMain.closeSyncPage()
    SyncMain.isStart = false

    if (SyncMain.SyncPage) then
        SyncMain.SyncPage:CloseWindow()
    end
end

function SyncMain.closeBeyondPage()
    SyncMain.BeyondPage:CloseWindow()
end

function SyncMain:StartSyncPage()
    SyncMain.isStart = true
    SyncMain.syncType = "sync"

    SyncMain:showDialog("Mod/WorldShare/sync/StartSync.html", "StartSync")
end

function SyncMain:useLocalGUI()
    SyncMain:showDialog("Mod/WorldShare/sync/StartSyncUseLocal.html", "StartSyncUseLocal")
end

function SyncMain:useDataSourceGUI()
    SyncMain:showDialog("Mod/WorldShare/sync/StartSyncUseDataSource.html", "StartSyncUseDataSource")
end

function SyncMain:showBeyondVolume()
    SyncMain:showDialog("Mod/WorldShare/sync/BeyondVolume.html", "BeyondVolume")
end

function SyncMain.deleteWorld()
    SyncMain:showDialog("Mod/WorldShare/sync/DeleteWorld.html", "DeleteWorld")
end

function SyncMain.deleteWorldGithubLogin()
    SyncMain:showDialog("Mod/WorldShare/sync/DeleteWorldGithub.html", DeleteWorldGithub)
end

function SyncMain:showDialog(url, name)
    System.App.Commands.Call(
        "File.MCMLWindowFrame",
        {
            url = url,
            name = name,
            isShowTitleBar = false,
            DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 0,
            allowDrag = true,
            bShow = bShow,
            directPosition = true,
            align = "_ct",
            x = -500 / 2,
            y = -270 / 2,
            width = 500,
            height = 270,
            cancelShowAnimation = true
        }
    )
end

function SyncMain:backupWorld()
    local world_revision = WorldRevision:new():init(SyncMain.worldDir.default)
    world_revision:Backup()
end

function SyncMain:syncToLocal(callback)
end

function SyncMain:syncToDataSource()
    SyncToDataSource:init()
end

function SyncMain.GetCurrentRevision()
    return tonumber(GlobalStore.get('currentRevision'))
end

function SyncMain.GetRemoteRevision()
    return tonumber(GlobalStore.get('remoteRevision'))
end

function SyncMain:refreshRemoteWorldLists(syncGUI, callback)
    echo(SyncMain.foldername, true)

    SyncMain:getCommits(
        SyncMain.foldername.base32,
        function(data, err)
            if (data and data[1]) then
                local lastCommits = data[1]
                local lastCommitFile = lastCommits.title:gsub("keepwork commit: ", "")
                local lastCommitSha = lastCommits.id

                if (lastCommitFile ~= "revision.xml") then
                    _guihelper.MessageBox(L "上一次同步到数据源同步失败，请重新同步世界到数据源")
                    return
                end

                local modDateTable = {}
                local readme = ""

                if (SyncMain.selectedWorldInfor and SyncMain.selectedWorldInfor.tooltip) then
                    for modDateEle in string.gmatch(SyncMain.selectedWorldInfor.tooltip, "[^:]+") do
                        modDateTable[#modDateTable + 1] = modDateEle
                    end

                    modDateTable = modDateTable[1]
                else
                    modDateTable = os.date("%Y-%m-%d-%H-%M-%S")
                end

                local hasPreview = false

                for key, value in ipairs(SyncMain.localFiles) do
                    if (value.filename == "preview.jpg") then
                        hasPreview = true
                    end
                end

                for key, value in ipairs(SyncMain.localFiles) do
                    if (value.filename == "README.md") then
                        readme = LocalService:getFileContent(SyncMain.worldDir.default .. "README.md")
                    end
                end

                local preview =
                    loginMain.rawBaseUrl ..
                    "/" ..
                        loginMain.dataSourceUsername ..
                            "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/raw/master/preview.jpg"

                local filesTotals = 0
                if (SyncMain.selectedWorldInfor) then
                    filesTotals = SyncMain.selectedWorldInfor.size
                end

                local worldTag = LocalService:GetTag(SyncMain.foldername.default)

                self.worldInfo = {}
                self.worldInfo.modDate = modDateTable
                self.worldInfo.worldsName = SyncMain.foldername.utf8
                self.worldInfo.revision = SyncMain.currentRevison
                self.worldInfo.hasPreview = hasPreview
                self.worldInfo.dataSourceType = loginMain.dataSourceType
                self.worldInfo.gitlabProjectId = GitService.getProjectId()
                self.worldInfo.readme = readme
                self.worldInfo.preview = preview
                self.worldInfo.filesTotals = filesTotals
                self.worldInfo.commitId = lastCommitSha
                self.worldInfo.name = worldTag.name
                self.worldInfo.download =
                    format(
                    "%s/%s/%s/repository/archive.zip?ref=%s",
                    loginMain.rawBaseUrl,
                    loginMain.dataSourceUsername,
                    GitEncoding.base32(SyncMain.foldername.utf8),
                    self.worldInfo.commitId
                )

                loginMain.refreshing = true
                loginMain.refreshPage()

                HttpRequest:GetUrl(
                    {
                        url = loginMain.site .. "/api/mod/worldshare/models/worlds/refresh",
                        json = true,
                        form = self.worldInfo,
                        headers = {
                            Authorization = "Bearer " .. loginMain.token,
                            ["content-type"] = "application/json"
                        }
                    },
                    function(response, err)
                        if (err == 200) then
                            if (type(response) == "table" and response.error.id == 0) then
                                self.worldInfo.opusId = response.data.opusId
                            else
                                _guihelper.MessageBox(L "更新服务器列表失败")
                                return
                            end

                            local function refresh()
                                SyncMain.finish = true

                                if (syncGUI) then
                                    syncGUI:refresh()
                                end

                                loginMain.RefreshCurrentServerList(
                                    function()
                                        if (type(callback) == "function") then
                                            callback()
                                        end
                                    end
                                )
                            end

                            SyncMain:genWorldMD(refresh)
                        end
                    end
                )

                if (SyncMain.firstCreate) then
                    SyncMain.firstCreate = false
                end
            else
                _guihelper.MessageBox(L "获取Commit列表失败")
            end

            GitService.setProjectId(nil)
        end
    )
end

function SyncMain:checkWorldSize()
    local worldDir = GlobalStore.get("worldDir")
    local userType = GlobalStore.get("userType")

    local filesTotal = LocalService:GetWorldSize(worldDir.default)
    local maxSize = 0

    if (userType == "vip") then
        maxSize = 50 * 1024 * 1024
    else
        maxSize = 25 * 1024 * 1024
    end

    if (filesTotal > maxSize) then
        SyncMain:showBeyondVolume()

        return true
    else
        return false
    end
end

function SyncMain.deleteServerWorld()
    local zipPath = SyncMain.selectedWorldInfor.localpath

    if (ParaIO.DeleteFile(zipPath)) then
        loginMain.RefreshCurrentServerList()
    else
        _guihelper.MessageBox(L "无法删除可能您没有足够的权限")
    end

    SyncMain.DeletePage:CloseWindow()
end

function SyncMain.deleteWorldLocal(callback)
    local foldername = SyncMain.selectedWorldInfor.foldername

    if (not SyncMain.selectedWorldInfor) then
        _guihelper.MessageBox(L "请先选择世界")
        return
    end

    local function deleteNow()
        if (SyncMain.selectedWorldInfor.RemoveLocalFile and SyncMain.selectedWorldInfor:RemoveLocalFile()) then
            InternetLoadWorld.RefreshAll()
        elseif (SyncMain.selectedWorldInfor.remotefile) then
            local targetDir = SyncMain.selectedWorldInfor.remotefile:gsub("^local://", "") -- local world, delete all files in folder and the folder itself.

            if (SyncMain.selectedWorldInfor.is_zip) then
                if (ParaIO.DeleteFile(targetDir)) then
                    if (type(callback) == "function") then
                        callback()
                    end
                else
                    _guihelper.MessageBox(L "无法删除可能您没有足够的权限")
                end
            else
                if (GameLogic.RemoveWorldFileWatcher) then
                    GameLogic.RemoveWorldFileWatcher() -- file watcher may make folder deletion of current world directory not working.
                end

                if (commonlib.Files.DeleteFolder(targetDir)) then
                    if (type(callback) == "function") then
                        callback(foldername)
                    end
                else
                    _guihelper.MessageBox(L "无法删除可能您没有足够的权限")
                end
            end

            SyncMain.DeletePage:CloseWindow()
            loginMain.RefreshCurrentServerList()
        end
    end

    if (SyncMain.selectedWorldInfor.status == nil or SyncMain.selectedWorldInfor.status == 1) then
        deleteNow()
    else
        _guihelper.MessageBox(
            format(L "确定删除本地世界:%s?", SyncMain.selectedWorldInfor.text or ""),
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) then
                    deleteNow()
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )
    end
end

function SyncMain.deleteWorldGitlab()
    local foldername = SyncMain.selectedWorldInfor.foldername

    GitService:setGitlabProjectId(foldername)

    _guihelper.MessageBox(
        format(L "确定删除Gitlab远程世界:%s?", foldername or ""),
        function(res)
            SyncMain.DeletePage:CloseWindow()

            loginMain.refreshing = true
            loginMain.LoginPage:Refresh(0.01)

            if (res and res == 6) then
                GitService:deleteResp(
                    foldername,
                    function(data, err)
                        if (err == 202) then
                            SyncMain.deleteKeepworkWorldsRecord()
                        else
                            _guihelper.MessageBox(L "远程仓库不存在，记录将直接被删除")
                            SyncMain.deleteKeepworkWorldsRecord()
                        end
                    end
                )
            end
        end
    )
end

function SyncMain.deleteKeepworkWorldsRecord()
    local foldername = SyncMain.selectedWorldInfor.foldername
    local url = loginMain.site .. "/api/mod/worldshare/models/worlds"

    LOG.std(nil, "debug", "deleteKeepworkWorldsRecord", url)

    HttpRequest:GetUrl(
        {
            method = "DELETE",
            url = url,
            form = {
                worldsName = foldername
            },
            json = true,
            headers = {
                Authorization = "Bearer " .. loginMain.token
            }
        },
        function(data, err)
            LOG.std(nil, "debug", "deleteKeepworkWorldsRecord", data)
            LOG.std(nil, "debug", "deleteKeepworkWorldsRecord", err)

            if (err == 204 or err == 200) then
                SyncMain:deleteWorldMD(
                    foldername,
                    function()
                        loginMain.RefreshCurrentServerList()
                    end
                )
            end
        end
    )
end

function SyncMain.deleteWorldRemote()
    if (loginMain.dataSourceType == "github") then
        SyncMain.deleteWorldGithubLogin()
    elseif (loginMain.dataSourceType == "gitlab") then
        SyncMain.deleteWorldGitlab()
    end
end

function SyncMain.deleteWorldAll()
    SyncMain.deleteWorldLocal(
        function()
            SyncMain.deleteWorldRemote()
        end
    )
end

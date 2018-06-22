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
SyncMain.BeyondPage = nil
SyncMain.finish = true

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

function SyncMain.setBeyondPage()
    SyncMain.BeyondPage = document:GetPageCtrl()
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
    local worldDir = GlobalStore.get('worldDir')

    local world_revision = WorldRevision:new():init(worldDir.default)
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
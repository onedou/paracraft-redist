--[[
Title: SyncCompare
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua")
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")

local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")

SyncCompare.compareFinish = false
SyncCompare.LoginStatus = nil

function SyncCompare:syncCompare(LoginStatus)
    self:setLoginStatus(LoginStatus)

    self:compareRevision(
        function(result)
            if (LoginStatus) then
                if (result == "justLocal") then
                    SyncMain.syncToDataSource()
                else
                    SyncMain:StartSyncPage()
                end
            else
                if (result == "remoteBigger") then
                    SyncMain:StartSyncPage()
                elseif (result == "tryAgain") then
                    commonlib.TimerManager.SetTimeout(
                        function()
                            SyncMain.syncCompare()
                        end,
                        1000
                    )
                end
            end
        end
    )
end

function SyncCompare:IsCompareFinish()
    return SyncCompare.compareFinish == true
end

function SyncCompare:setLoginStatus(LoginStatus)
    SyncCompare.LoginStatus = LoginStatus
end

function SyncCompare:compareRevision(callback)
    if (LoginUserInfo.IsSignedIn()) then
        if (not SyncCompare.LoginStatus) then
            local worldDir = {}
            worldDir.default = GameLogic.GetWorldDirectory():gsub("\\", "/")
            worldDir.utf8 = Encoding.DefaultToUtf8(worldDir.default)

            local foldername = {}
            foldername.default = SyncMain.worldDir.default:match("([^/]*)/$")
            foldername.utf8 = SyncMain.worldDir.utf8:match("([^/]*)/$")

            GlobalStore.set("tagInfo", WorldCommon.GetWorldInfo())
            GlobalStore.set("worldDir", worldDir)
            GlobalStore.set("foldername", foldername)

            if (loginMain.LoginPage or loginMain.ModalPage) then
                loginMain.RefreshCurrentServerList(self.comparePrepare)
            else
                self:comparePrepare()
            end
        else
            self:compare(callback)
        end
    else
        loginMain.LoginWithTokenApi(
            function()
                self:compareRevision(LoginStatus, callback)
            end
        )
    end
end

function SyncCompare:compare(callback)
    local foldername = GlobalStore.get("foldername")
    foldername.base32 = GitEncoding.base32(foldername.utf8)

    local worldDir = GlobalStore.get("worldDir")
    local remoteWorldsList = GlobalStore.get("remoteWorldsList")
    local remoteRevision = 0
    local currentRevision = WorldRevision:new():init(worldDir.default):Checkout()
    local localFiles = LocalService:new():LoadFiles(worldDir.default)
    local hasRevision = false

    GlobalStore.set("localFiles", localFiles)

    for key, value in ipairs(localFiles) do
        if (string.lower(value.filename) == "revision.xml") then
            hasRevision = true
            break
        end
    end
    
    if (hasRevision and currentRevision ~= 0 and currentRevision ~= 1) then
        local function handleRevision(data, err)
            if (err == 0 or err == 502) then
                _guihelper.MessageBox(L "网络错误")
                return false
            end

            currentRevision = tonumber(currentRevision) or 0
            remoteRevision = tonumber(data)

            GlobalStore.set("currentRevision", currentRevision)
            GlobalStore.set("remoteRevision", remoteRevision)

            local result

            if (currentRevision < remoteRevision) then
                result = "remoteBigger"
            elseif (remoteRevision == 0) then
                result = "justLocal"
            elseif (currentRevision > remoteRevision) then
                result = "localBigger"
            elseif (currentRevision == remoteRevision) then
                result = "equal"
            end
            
            if (remoteRevision ~= 0) then
                local isWorldInRemoteLists = false

                for _, valueDistance in ipairs(remoteWorldsList) do
                    if (valueDistance["worldsName"] == foldername.utf8) then
                        isWorldInRemoteLists = true
                    end
                end

                if (not isWorldInRemoteLists) then
                    SyncMain:refreshRemoteWorldLists(
                        nil,
                        function()
                            SyncCompare.compareFinish = true

                            if (type(callback) == "function") then
                                callback("tryAgain")
                            end
                        end
                    )

                    return
                end
            end

            SyncCompare.compareFinish = true

            if (type(callback) == "function") then
                callback(result)
            end
        end

        GitService:new():getWorldRevision(foldername, handleRevision)
    else
        if (not LoginStatus) then
            CommandManager:RunCommand("/save")

            SyncCompare.compareFinish = true

            if (type(callback) == "function") then
                callback("tryAgain")
            end
        else
            _guihelper.MessageBox(L "本地世界沒有版本信息")
            SyncCompare.compareFinish = true
            return
        end
    end
end

function SyncCompare:comparePrepare()
    local foldername = GlobalStore.get("foldername")

    if (GameLogic.IsReadOnly()) then
        if (type(callback) == "function") then
            callback("zip")
        end

        return
    end

    -- local dataSource = InternetLoadWorld.GetCurrentServerPage().ds

    -- if (dataSource) then
    --     for _, value in ipairs(dataSource) do
    --         if (value.foldername == foldername.utf8) then
    --             SyncMain.selectedWorldInfor = value
    --         end
    --     end
    -- end

    self:compare()
end

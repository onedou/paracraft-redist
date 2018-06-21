--[[
Title: SyncCompare
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua");
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/store/global.lua")

local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local store = commonlib.gettable("Mod.WorldShare.store.global")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

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

function SyncCompare:setLoginStatus(LoginStatus)
    SyncCompare.LoginStatus = LoginStatus
end

function SyncCompare:compareRevision(callback)
    if (loginMain.IsSignedIn()) then
        if (not SyncCompare.LoginStatus) then
            local worldDir = {}
            worldDir.default = GameLogic.GetWorldDirectory():gsub("\\", "/")
            worldDir.utf8 = Encoding.DefaultToUtf8(worldDir.default)

            local foldername = {}
            foldername.default = SyncMain.worldDir.default:match("([^/]*)/$")
            foldername.utf8 = SyncMain.worldDir.utf8:match("([^/]*)/$")

            store.set("tagInfo", WorldCommon.GetWorldInfo())
            store.set("worldDir", worldDir)
            store.set("foldername", foldername)

            if (loginMain.LoginPage or loginMain.ModalPage) then
                loginMain.RefreshCurrentServerList(SyncCompare.comparePrepare)
            else
                self:comparePrepare()
            end
        else
            self:compare()
        end
    else
        loginMain.LoginWithTokenApi(
            function()
                self:compareRevision(LoginStatus, callback)
            end
        )
    end
end

function SyncCompare:compare()
    local foldername = store.get("foldername")
    foldername.base32 = GitEncoding.base32(foldername.utf8)

    local worldDir = store.get("worldDir")
    local remoteWorldsList = store.get("remoteWorldsList")
    local currentRevison = WorldRevision:new():init(worldDir.default):Checkout()
    local localFiles = LocalService:new():LoadFiles(worldDir.default)
    local hasRevision = false

    store.set("currentRevison", currentRevison)
    store.set("localFiles", localFiles)

    for key, value in ipairs(localFiles) do
        if (string.lower(value.filename) == "revision.xml") then
            hasRevision = true
            break
        end
    end

    if (hasRevision and currentRevison ~= 0 and currentRevison ~= 1) then
        local remoteRevison = 0

        GitService:getWorldRevison(
            function(data, err)
                if (err == 0 or err == 502) then
                    _guihelper.MessageBox(L "网络错误")

                    if (type(callback) == "function") then
                        callback(false)
                    end

                    return
                end

                currentRevison = tonumber(currentRevison) or 0
                remoteRevison = tonumber(data)

                local result

                if (currentRevison < remoteRevison) then
                    result = "remoteBigger"
                elseif (remoteRevison == 0) then
                    result = "justLocal"
                elseif (currentRevison > remoteRevison) then
                    result = "localBigger"
                elseif (currentRevison == remoteRevison) then
                    result = "equal"
                end

                if (remoteRevison ~= 0) then
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
        )
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
    local foldername = store.get("foldername")

    if (GameLogic.IsReadOnly()) then
        if (type(callback) == "function") then
            callback("zip")
        end

        return
    end

    local dataSource = InternetLoadWorld.GetCurrentServerPage().ds

    if (dataSource) then
        for _, value in ipairs(dataSource) do
            if (value.foldername == foldername.utf8) then
                SyncMain.selectedWorldInfor = value
            end
        end
    end

    SyncCompare:compare()
end

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
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")
NPL.load("(gl)script/ide/Encoding.lua")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")
local Encoding = commonlib.gettable("commonlib.Encoding")

local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")

SyncCompare.compareFinish = false

function SyncCompare:syncCompare()
    local IsEnterWorld = GlobalStore.get("IsEnterWorld")

    self:compareRevision(
        function(result)
            if (IsEnterWorld) then
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
                            SyncCompare.syncCompare()
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

function SyncCompare:compareRevision(callback)
    local IsEnterWorld = GlobalStore.get("IsEnterWorld")

    if (LoginUserInfo.IsSignedIn()) then
        if (IsEnterWorld) then
            local worldDir = {}

            worldDir.default = GameLogic.GetWorldDirectory():gsub("\\", "/")
            worldDir.utf8 = Encoding.DefaultToUtf8(worldDir.default)

            local foldername = {}
            foldername.default = SyncMain.worldDir.default:match("([^/]*)/$")
            foldername.utf8 = SyncMain.worldDir.utf8:match("([^/]*)/$")

            GlobalStore.set("tagInfo", WorldCommon.GetWorldInfo())
            GlobalStore.set("worldDir", worldDir)
            GlobalStore.set("foldername", foldername)

            if (LoginMain.LoginPage or LoginMain.ModalPage) then
                LoginMain.RefreshCurrentServerList(self.comparePrepare)
            else
                self:comparePrepare()
            end
        else
            local selectWorld = GlobalStore.get('selectWorld')

            if (selectWorld.is_zip) then
                _guihelper.MessageBox(L "不能同步ZIP文件")
                return
            end
    
            local foldername = {}
    
            foldername.utf8 = selectWorld.foldername
            foldername.default = Encoding.Utf8ToDefault(foldername.utf8)
    
            local worldDir = {}
    
            worldDir.utf8 = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.utf8)
            worldDir.default = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.default)
    
            GlobalStore.set("foldername", foldername)
            GlobalStore.set("worldDir", worldDir)

            self:compare(callback)
        end
    else
        LoginMain.LoginWithTokenApi(
            function()
                self:compareRevision(callback)
            end
        )
    end
end

function SyncCompare:compare(callback)
    local IsEnterWorld = GlobalStore.get("IsEnterWorld")
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
                    LoginMain.showMessageInfo("请稍后...")

                    SyncMain:RefreshKeepworkList(
                        function()
                            LoginWorldList.RefreshCurrentServerList(
                                function()
                                    SyncCompare.compareFinish = true
                                    LoginMain.closeMessageInfo()

                                    if (type(callback) == "function") then
                                        callback("tryAgain")
                                    end
                                end
                            )
                        end
                    )

                    return false
                end
            end

            SyncCompare.compareFinish = true

            if (type(callback) == "function") then
                callback(result)
            end
        end

        GitService:new():getWorldRevision(foldername, handleRevision)
    else
        if (not IsEnterWorld) then
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

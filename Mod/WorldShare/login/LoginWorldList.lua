--[[
Title: LoginWorldList
Author(s):  big
Date: 2018.06.21
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua")
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua")
NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")

local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local Encoding = commonlib.gettable("commonlib.Encoding")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")
local LoginUserInfo = commonlib.gettable("Mod.WorldShare.login.LoginUserInfo")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local KeepworkService = commonlib.gettable("Mod.WorldShare.service.KeepworkService")

local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")

function LoginWorldList.CreateNewWorld()
    LoginMain.LoginPage:CloseWindow()
    CreateNewWorld.ShowPage()
end

function LoginWorldList.GetCurWorldInfo(info_type, world_index)
    --local cur_world = InternetLoadWorld:GetCurrentWorld();

    local index = tonumber(world_index)
    local selected_world = InternetLoadWorld.cur_ds[world_index]

    if (selected_world) then
        if (info_type == "mode") then
            local mode = selected_world["world_mode"]

            if (mode == "edit") then
                return L "创作"
            else
                return L "参观"
            end
        else
            return selected_world[info_type]
        end
    end
end

function LoginWorldList.updateWorldInfo(worldIndex, callback)
    local selectWorld = LocalLoadWorld.BuildLocalWorldList(true)[worldIndex]

    if (type(selectWorld) == "table") then
        local filesize = LocalService:GetWorldSize(selectWorld.worldpath)
        local worldTag = LocalService:GetTag(Encoding.Utf8ToDefault(selectWorld.foldername))

        worldTag.size = filesize

        LocalService:SetTag(selectWorld.worldpath, worldTag)

        InternetLoadWorld.GetCurrentServerPage().ds[worldIndex].size = filesize
    end

    if (type(callback) == "function") then
        callback()
    end
end

function LoginWorldList.RefreshCurrentServerList(callback)
    if (LoginMain.LoginPage) then
        LoginMain.setPageRefreshing(true)

        if (not LoginUserInfo.IsSignedIn()) then
            LoginWorldList.getLocalWorldList(
                function()
                    LoginWorldList.changeRevision(
                        function()
                            LoginMain.setPageRefreshing(false)

                            if (type(callback) == "function") then
                                callback()
                            end
                        end
                    )
                end
            )
        end

        if (LoginUserInfo.IsSignedIn()) then
            LoginWorldList.getLocalWorldList(
                function()
                    LoginWorldList.changeRevision(
                        function()
                            LoginWorldList.syncWorldsList(
                                function()
                                    LoginMain.setPageRefreshing(false)

                                    if (type(callback) == "function") then
                                        callback()
                                    end
                                end
                            )
                        end
                    )
                end
            )
        end

        LoginMain.refreshPage()
    end

    if (LoginMain.ModalPage) then
        LoginWorldList.getLocalWorldList(
            function()
                LoginWorldList.changeRevision(
                    function()
                        LoginWorldList.syncWorldsList(
                            function()
                                LoginMain.setPageRefreshing(false)

                                if (type(callback) == "function") then
                                    callback()
                                end
                            end
                        )
                    end
                )
            end
        )
    end
end

function LoginWorldList.getLocalWorldList(callback)
    local ServerPage = InternetLoadWorld.GetCurrentServerPage()

    RemoteServerList:new():Init(
        "local",
        "localworld",
        function(bSucceed, serverlist)
            if (not serverlist:IsValid()) then
                BroadcastHelper.PushLabel(
                    {
                        id = "userworlddownload",
                        label = L "无法下载服务器列表, 请检查网络连接",
                        max_duration = 10000,
                        color = "255 0 0",
                        scaling = 1.1,
                        bold = true,
                        shadow = true
                    }
                )
            end

            ServerPage.ds = serverlist.worlds or {}
            InternetLoadWorld.OnChangeServerPage()

            if (callback) then
                callback()
            end
        end
    )
end

function LoginWorldList.changeRevision(callback)
    local localWorlds = InternetLoadWorld.GetCurrentServerPage().ds

    if (localWorlds) then
        for key, value in ipairs(localWorlds) do
            if (not value.is_zip) then
                value.modifyTime = value.revision

                local foldername = {}
                foldername.utf8 = value.foldername
                foldername.default = Encoding.Utf8ToDefault(value.foldername)

                local WorldRevisionCheckOut =
                    WorldRevision:new():init(SyncMain.GetWorldFolderFullPath() .. "/" .. foldername.default .. "/")
                value.revision = WorldRevisionCheckOut:GetDiskRevision()

                local tag = LocalService:GetTag(foldername.default)

                if (tag.size) then
                    value.size = tag.size
                else
                    value.size = 0
                end
            else
                value.modifyTime = value.revision

                local zipWorldDir = {}
                zipWorldDir.default = value.remotefile:gsub("local://", "")
                zipWorldDir.utf8 = Encoding.Utf8ToDefault(zipWorldDir.default)

                local zipFoldername = {}
                zipFoldername.default = zipWorldDir.default:match("([^/\\]+)/[^/]*$")
                zipFoldername.utf8 = Encoding.Utf8ToDefault(zipFoldername.default)

                --LOG.std(nil,"debug","zipWorldDir.default",zipWorldDir.default);

                value.revision = LocalService:GetZipRevision(zipWorldDir.default)
                value.size = LocalService:GetZipWorldSize(zipWorldDir.default)
            end
        end

        if (LoginMain.LoginPage) then
            LoginMain.LoginPage:Refresh()
        end

        if (callback) then
            callback()
        end

        return
    else
        LoginMain.changeRevision()
    end
end

function LoginWorldList.selectVersion()
    _guihelper.MessageBox("Hello World!!!")
end

--[[
status代码含义:
1:仅本地
2:仅网络
3:本地网络一致
4:网络更新
5:本地更新
]]
function LoginWorldList.syncWorldsList(callback)
    local function handleWorldList(response, err)
        local localWorlds = InternetLoadWorld.cur_ds or {}
        local remoteWorldsList = response.data
    
        store.set("remoteWorldsList", remoteWorldsList)
        store.set("localWorlds", localWorlds)

        -- 处理本地网络同时存在 本地不存在 网络存在 的世界
        if (type(remoteWorldsList) ~= "table") then
            _guihelper.MessageBox(L "获取服务器世界列表错误")
            return
        end

        for keyDistance, valueDistance in ipairs(remoteWorldsList) do
            local isExist = false

            for keyLocal, valueLocal in ipairs(localWorlds) do
                if (valueDistance["worldsName"] == valueLocal["foldername"]) then
                    if (localWorlds[keyLocal].server) then
                        if (tonumber(valueLocal["revision"]) == tonumber(valueDistance["revision"])) then
                            localWorlds[keyLocal].status = 3 --本地网络一致
                        elseif (tonumber(valueLocal["revision"]) > tonumber(valueDistance["revision"])) then
                            localWorlds[keyLocal].status = 4 --网络更新
                        elseif (tonumber(valueLocal["revision"]) < tonumber(valueDistance["revision"])) then
                            localWorlds[keyLocal].status = 5 --本地更新
                        end
                    end

                    --localWorlds[kl].revision = vd["revision"];
                    isExist = true
                    break
                end
            end

            if (not isExist) then
                localWorlds[#localWorlds + 1] = {
                    text = valueDistance["worldsName"],
                    foldername = valueDistance["worldsName"],
                    revision = valueDistance["revision"],
                    size = valueDistance["filesTotals"],
                    modifyTime = valueDistance["modDate"],
                    status = 2 --仅网络
                }
            end
        end

        -- 处理 本地存在 网络不存在 的世界
        for keyLocal, valueLocal in ipairs(localWorlds) do
            local isExist = false

            for keyDistance, valueDistance in ipairs(remoteWorldsList) do
                if (valueLocal["foldername"] == valueDistance["worldsName"]) then
                    isExist = true
                    break
                end
            end

            if (not isExist) then
                localWorlds[keyLocal].status = 1 --仅本地
            end
        end

        if (localWorlds) then
            local tmp = 0

            for i = 1, #localWorlds - 1 do
                for j = 1, #localWorlds - i do
                    if
                        LoginMain:formatDate(localWorlds[j].modifyTime) <
                            LoginMain:formatDate(localWorlds[j + 1].modifyTime)
                        then
                        tmp = localWorlds[j]
                        localWorlds[j] = localWorlds[j + 1]
                        localWorlds[j + 1] = tmp
                    end
                end
            end
        end

        LoginMain.refreshPage()

        if (type(callback) == "function") then
            callback()
        end
    end

    KeepworkService.getWorldsList(handleWorldList)
end

function LoginWorldList:formatDate(modDate)
    local function strRepeat(num, str)
        local strRepeat = ""

        for i = 1, num do
            strRepeat = strRepeat .. str
        end

        return strRepeat
    end

    local modDateTable = {}

    for modDateEle in string.gmatch(modDate, "[^%-]+") do
        modDateTable[#modDateTable + 1] = modDateEle
    end

    local newModDate = ""

    if (modDateTable[1] and #modDateTable[1] ~= 4) then
        local num = 4 - #modDateTable[1]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[1]
    elseif (modDateTable[1] and #modDateTable[1] == 4) then
        newModDate = newModDate .. modDateTable[1]
    end

    if (modDateTable[2] and #modDateTable[2] ~= 2) then
        local num = 2 - #modDateTable[2]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[2]
    elseif (modDateTable[2] and #modDateTable[2] == 2) then
        newModDate = newModDate .. modDateTable[2]
    end

    if (modDateTable[3] and #modDateTable[3] ~= 2) then
        local num = 2 - #modDateTable[3]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[3]
    elseif (modDateTable[3] and #modDateTable[3] == 2) then
        newModDate = newModDate .. modDateTable[3]
    end

    if (modDateTable[4] and #modDateTable[4] ~= 2) then
        local num = 2 - #modDateTable[4]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[4]
    elseif (modDateTable[4] and #modDateTable[4] == 2) then
        newModDate = newModDate .. modDateTable[4]
    end

    if (modDateTable[5] and #modDateTable[5] ~= 2) then
        local num = 2 - #modDateTable[5]
        newModDate = newModDate .. strRepeat(num, "0") .. modDateTable[5]
    elseif (modDateTable[5] and modDateTable[5] and #modDateTable[5] == 2) then
        newModDate = newModDate .. modDateTable[5]
    end

    return tonumber(newModDate)
end

function LoginWorldList.syncNow(index)
    if (LoginMain.IsSignedIn() and not LoginMain.isVerified) then
        _guihelper.MessageBox(
            L "您需要到keepwork官网进行实名认证，认证成功后需重启paracraft即可正常操作，是否现在认证？",
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) then
                    ParaGlobal.ShellExecute("open", format("%s/wiki/user_center", LoginMain.site), "", "", 1)
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )

        return
    end

    local index = tonumber(index)

    SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[index]

    if (LoginMain.IsSignedIn()) then
        if (SyncMain.selectedWorldInfor.status ~= nil and SyncMain.selectedWorldInfor.status ~= 2) then
            if (SyncMain.selectedWorldInfor.is_zip) then
                _guihelper.MessageBox(L "不能同步ZIP文件")
                return
            end

            SyncMain.foldername.utf8 = SyncMain.selectedWorldInfor.foldername
            SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8)

            SyncMain.worldDir.utf8 = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.utf8 .. "/"
            SyncMain.worldDir.default = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.default .. "/"

            SyncMain.syncCompare(true)
        else
            LoginMain.downloadWorld()
        end
    else
        _guihelper.MessageBox(L "登陆后才能同步")
    end
end

function LoginWorldList.deleteWorld(index)
    local index = tonumber(index)

    SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[index]

    if (SyncMain.tagInfor) then
        if (SyncMain.tagInfor.name == SyncMain.selectedWorldInfor.foldername) then
            _guihelper.MessageBox(L "不能刪除正在编辑的世界")
            return
        end
    end

    SyncMain.deleteWorld()
end

function LoginWorldList.GetWorldType()
    return InternetLoadWorld.type_ds
end

function LoginWorldList.OnSwitchWorld(index)
    InternetLoadWorld.OnSwitchWorld(index)
    LoginWorldList.updateWorldInfo(index, LoginMain.refreshPage)
end

function LoginWorldList.GetDesForWorld()
    local str = ""
    return str
end

function LoginWorldList.enterWorld(index)
    local index = tonumber(index)
    SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[index]

    if (SyncMain.selectedWorldInfor.status == 2) then
        LoginMain.downloadWorld()
    else
        InternetLoadWorld.EnterWorld(index)
    end
end

function LoginWorldList.downloadWorld()
    SyncMain.foldername.utf8 = SyncMain.selectedWorldInfor.foldername
    SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8)

    SyncMain.worldDir.utf8 = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.utf8 .. "/"
    SyncMain.worldDir.default = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.default .. "/"

    SyncMain.commitId = SyncMain:getGitlabCommitId(SyncMain.foldername.utf8)

    ParaIO.CreateDirectory(SyncMain.worldDir.default)

    SyncMain:syncToLocal(
        function(success, params)
            if (success) then
                SyncMain.selectedWorldInfor.status = 3
                SyncMain.selectedWorldInfor.server = "local"
                SyncMain.selectedWorldInfor.is_zip = false
                SyncMain.selectedWorldInfor.icon = "Texture/blocks/items/1013_Carrot.png"
                SyncMain.selectedWorldInfor.revision = params.revison
                SyncMain.selectedWorldInfor.filesTotals = params.filesTotals
                SyncMain.selectedWorldInfor.text = SyncMain.foldername.utf8
                SyncMain.selectedWorldInfor.world_mode = "edit"
                SyncMain.selectedWorldInfor.gs_nid = ""
                SyncMain.selectedWorldInfor.force_nid = 0
                SyncMain.selectedWorldInfor.ws_id = ""
                SyncMain.selectedWorldInfor.author = ""
                SyncMain.selectedWorldInfor.remotefile =
                    "local://" .. SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.default

                LoginMain.LoginPage:Refresh()
            end
        end
    )
end

function LoginWorldList.sharePersonPage()
    local url = LoginMain.personPageUrl --LoginMain.site .. "/wiki/mod/worldshare/share/#?type=person&userid=" .. login.userid;
    ParaGlobal.ShellExecute("open", url, "", "", 1)
end

function LoginWorldList.GetWorldSize(size, unit)
    local s
    size = tonumber(size)

    function GetPreciseDecimal(nNum, n)
        if type(nNum) ~= "number" then
            return nNum
        end

        n = n or 0
        n = math.floor(n)
        local fmt = "%." .. n .. "f"
        local nRet = tonumber(string.format(fmt, nNum))

        return nRet
    end

    if (size and size ~= "") then
        if (not unit) then
            s = GetPreciseDecimal(size / 1024 / 1024, 2) .. "M"
        elseif (unit == "KB") then
            s = GetPreciseDecimal(size / 1024, 2) .. "KB"
        end
    else
        s = nil
    end

    return s or "0"
end

function LoginWorldList.formatStatus(_status)
    --LOG.std(nil, "debug", "_status", _status);
    if (_status == 1) then
        return L "仅本地"
    elseif (_status == 2) then
        return L "仅网络"
    elseif (_status == 3) then
        return L "本地版本与远程数据源一致"
    elseif (_status == 4) then
        return L "本地版本更加新"
    elseif (_status == 5) then
        return L "远程版本更加新"
    else
        return L "获取状态中"
    end
end

function LoginWorldList.formatDatetime(datetime)
    if (datetime) then
        local n = 1
        local formatDatetime = ""
        for value in string.gmatch(datetime, "[^%-]+") do
            if (n == 3) then
                formatDatetime = formatDatetime .. value .. " "
            elseif (n < 3) then
                formatDatetime = formatDatetime .. value .. "-"
            elseif (n == 5) then
                formatDatetime = formatDatetime .. value
            elseif (n < 5) then
                formatDatetime = formatDatetime .. value .. ":"
            end

            n = n + 1
        end
        return formatDatetime
    end

    return datetime
end

--[[ TODO: this makes paracraft NOT able to run when network is down.
local OnClickCreateWorld = CreateNewWorld.OnClickCreateWorld;

CreateNewWorld.OnClickCreateWorld = function()
    LoginMain:sensitiveCheck(function(hasSensitive)
        if(hasSensitive) then
            _guihelper.MessageBox(L"世界名字中含有敏感词汇，请重新输入");
        else
            OnClickCreateWorld();
        end
    end)
end
]]
function LoginWorldList:sensitiveCheck(callback)
    local new_world_name = CreateNewWorld.page:GetValue("new_world_name")

    if (new_world_name) then
        HttpRequest:GetUrl(
            {
                url = LoginMain.site .. "/api/wiki/models/sensitive_words/query",
                form = {
                    query = {
                        name = new_world_name
                    }
                },
                json = true
            },
            function(data, err)
                if (data and type(data) == "table") then
                    if (data.data.total ~= 0) then
                        if (callback and type(callback) == "function") then
                            callback(true)
                        end
                    else
                        if (callback and type(callback) == "function") then
                            callback(false)
                        end
                    end
                end
            end
        )
    end
end

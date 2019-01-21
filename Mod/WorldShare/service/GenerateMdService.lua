--[[
Title: GenerateMdPage
Author(s): big
Date: 2018.6.20
City: Foshan
use the lib:
------------------------------------------------------------
local GenerateMdPage = NPL.load("(gl)Mod/WorldShare/cellar/Common/GenerateMdPage.lua")
------------------------------------------------------------
]]
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local KeepworkGen = NPL.load("(gl)Mod/WorldShare/helper/KeepworkGen.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")

local GenerateMdPage = NPL.export()

function GenerateMdPage:GetSetting()
    local dataSourceInfo = Store:Get("user/dataSourceInfo")
    local userinfo = Store:Get("user/userinfo")

    return dataSourceInfo, userinfo
end

function GenerateMdPage:GenIndexMD(callback)
    local dataSourceInfo, userinfo = GenerateMdPage:getSetting()

    if (not dataSourceInfo or not userinfo) then
        return false
    end

    local path = format("%s/paracraft/index.md", userinfo.username)
    local worldList = KeepworkGen:setCommand("WorldList", {userid = userinfo._id})
    local content = KeepworkGen:SetAutoGenContent("", worldList)

    local function update()
        GitService:update(
            dataSourceInfo.keepWorkDataSourceId,
            nil,
            path,
            content,
            nil,
            function(data, err)
                if (type(callback) == "function") then
                    callback()
                end
            end
        )
    end

    local function upload()
        GitService:upload(
            dataSourceInfo.keepWorkDataSourceId,
            nil,
            path,
            content,
            function(data, err)
                if (type(callback) == "function") then
                    callback()
                end
            end
        )
    end

    GitService:getContent(
        dataSourceInfo.keepWorkDataSourceId,
        nil,
        path,
        function(data, size, err)
            if (err == 200) then
                update()
            else
                upload()
            end
        end
    )
end

function GenerateMdPage:GenWorldMD(worldInfo, callback)
    local dataSourceInfo, userinfo = GenerateMdPage:getSetting()

    local worldFilePath = format("%s/paracraft/%s.md", userinfo.username, worldInfo.worldsName)

    local KPParacraftMod = {
        worldName = worldInfo.name,
        download = worldInfo.download,
        preview = worldInfo.preview,
        link_desc = "",
        author = userinfo.username,
        updateTime = worldInfo.modDate,
        version = worldInfo.revision,
        link_opus_id = worldInfo.opusId,
        size = worldInfo.filesTotals
    }

    local KPParacraftCMD = KeepworkGen:getParacraftCommand(KPParacraftMod)

    local worldFile = KeepworkGen:SetAutoGenContent(worldInfo.readme, KPParacraftCMD)

    local function upload()
        GitService:upload(
            dataSourceInfo.keepWorkDataSourceId,
            nil,
            worldFilePath,
            worldFile,
            function(data, err)
                if (type(callback) == "function") then
                    callback()
                end
            end
        )
    end

    local function update()
        GitService:update(
            dataSourceInfo.keepWorkDataSourceId,
            nil,
            worldFilePath,
            worldFile,
            nil,
            function(isSuccess, path)
                if (type(callback) == "function") then
                    callback()
                end
            end
        )
    end

    GitService:getContent(
        dataSourceInfo.keepWorkDataSourceId,
        nil,
        worldFilePath,
        function(data, size, err)
            if (err == 200) then
                update()
            else
                upload()
            end
        end
    )
end

function GenerateMdPage:DeleteWorldMD(path, callback)
    local function DeleteFile(keepworkId)
        local path = UserConsole.username .. "/paracraft/world_" .. _path .. ".md"
        GitService:deleteFileService(
            UserConsole.keepWorkDataSource,
            path,
            "",
            function(data, err)
                if (type(callback) == "function") then
                    callback()
                end
            end,
            keepworkId
        )
    end
    if (UserConsole.dataSourceType == "github") then
        DeleteFile()
    elseif (UserConsole.dataSourceType == "gitlab") then
        GitService:GetProjectIdByName(
            UserConsole.keepWorkDataSource,
            function(keepworkId)
                DeleteFile(keepworkId)
            end
        )
    end
end

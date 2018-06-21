--[[
Title: GenerateMdPage
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/GenerateMdPage.lua");
local GenerateMdPage = commonlib.gettable("Mod.WorldShare.sync.GenerateMdPage");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/helper/KeepworkGen.lua")
NPL.load("(gl)Mod/WorldShare/service/GitService.lua");

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local KeepworkGen = commonlib.gettable("Mod.WorldShare.helper.KeepworkGen")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")

local GenerateMdPage = commonlib.gettable("Mod.WorldShare.sync.GenerateMdPage")

function GenerateMdPage:genIndexMD(callback)
    local dataSourceInfo = GlobalStore.get("dataSourceInfo")
    local userinfo = GlobalStore.get("userinfo")

    GitService:getContent(
        nil,
        format("%s/paracraft/index.md", userinfo.username),
        dataSourceInfo.keepWorkDataSourceId,
        function(data, err)
            echo(data, true)
            echo(err, true)
            if (err == 404) then
                local indexPath = loginMain.username .. "/paracraft/index.md"

                local worldList = KeepworkGen:setCommand("worldList", {userid = loginMain.userId})
                SyncMain.indexFile = KeepworkGen:SetAutoGenContent("", worldList)

                GitService:upload(
                    loginMain.keepWorkDataSource,
                    indexPath,
                    SyncMain.indexFile,
                    function(data, err)
                        if (type(callback) == "function") then
                            callback()
                        end
                    end,
                    loginMain.keepWorkDataSourceId
                )
            end
        end
    )
end

function GenerateMdPage:genThemeMD(callback)
    local contentUrl =
        "projects/" ..
        loginMain.keepWorkDataSourceId ..
            "/repository/files/" .. loginMain.username .. "/paracraft/_theme.md?ref=master"

    self:getUrl(
        contentUrl,
        function(data, err)
            if (err == 404) then
                local themePath = loginMain.username .. "/paracraft/_theme.md"

                SyncMain:uploadService(
                    loginMain.keepWorkDataSource,
                    themePath,
                    KeepworkGen.paracraftContainer,
                    function(data, err)
                        if (type(callback) == "function") then
                            callback()
                        end
                    end,
                    loginMain.keepWorkDataSourceId
                )
            end
        end
    )
end

function GenerateMdPage:genWorldMD(callback)
    local contentUrl =
        format(
        "projects/%s/repository/files/%s/paracraft/world_%s.md?ref=master",
        loginMain.keepWorkDataSourceId,
        loginMain.username,
        self.worldInfo.worldsName
    )

    local worldFilePath = format("%s/paracraft/world_%s.md", loginMain.username, self.worldInfo.worldsName)

    local paracraftParams = {
        link_world_name = self.worldInfo.name,
        link_world_url = self.worldInfo.download,
        media_logo = self.worldInfo.preview,
        link_desc = "",
        link_username = loginMain.username,
        link_update_date = self.worldInfo.modDate,
        link_version = self.worldInfo.revision,
        link_opus_id = self.worldInfo.opusId,
        link_files_totals = self.worldInfo.filesTotals
    }

    local paracraftCommand = KeepworkGen:setCommand("paracraft", paracraftParams)

    self:getUrl(
        contentUrl,
        function(data, err)
            if (err == 404) then
                if (not self.worldInfo.readme) then
                    self.worldInfo.readme = ""
                end

                SyncMain.worldFile = KeepworkGen:SetAutoGenContent(self.worldInfo.readme, paracraftCommand)
                SyncMain.worldFile = SyncMain.worldFile .. "\r\n" .. KeepworkGen:setCommand("comment")

                SyncMain:uploadService(
                    loginMain.keepWorkDataSource,
                    worldFilePath,
                    SyncMain.worldFile,
                    function(data, err)
                        if (type(callback) == "function") then
                            callback()
                        end
                    end,
                    loginMain.keepWorkDataSourceId
                )
            elseif (err == 200 or err == 304) then
                data = Encoding.unbase64(data.content)

                SyncMain.worldFile = KeepworkGen:SetAutoGenContent(data, paracraftCommand)

                GitService:updateService(
                    loginMain.keepWorkDataSource,
                    worldFilePath,
                    SyncMain.worldFile,
                    "",
                    function(isSuccess, path)
                        if (type(callback) == "function") then
                            callback()
                        end
                    end,
                    loginMain.keepWorkDataSourceId
                )
            end
        end
    )
end

function GenerateMdPage:deleteWorldMD(_path, callback)
    local function deleteFile(keepworkId)
        local path = loginMain.username .. "/paracraft/world_" .. _path .. ".md"

        GitService:deleteFileService(
            loginMain.keepWorkDataSource,
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

    if (loginMain.dataSourceType == "github") then
        deleteFile()
    elseif (loginMain.dataSourceType == "gitlab") then
        GitService:getProjectIdByName(
            loginMain.keepWorkDataSource,
            function(keepworkId)
                deleteFile(keepworkId)
            end
        )
    end
end

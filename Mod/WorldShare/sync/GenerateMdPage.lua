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

function GenerateMdPage:getSetting()
    local dataSourceInfo = GlobalStore.get("dataSourceInfo")
    local userinfo = GlobalStore.get("userinfo")

    return dataSourceInfo, userinfo
end

function GenerateMdPage:genIndexMD(callback)
    local dataSourceInfo, userinfo = GenerateMdPage:getSetting()

    local path = format("%s/paracraft/index.md", userinfo.username)
    local worldList = KeepworkGen:setCommand("WorldList", {userid = userinfo._id})
    local content = KeepworkGen:SetAutoGenContent("", worldList)

    GitService:new():upload(
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

function GenerateMdPage:genThemeMD(callback)
    local dataSourceInfo, userinfo = GenerateMdPage:getSetting()

    -- local contentUrl =
    --     "projects/" ..
    --     loginMain.keepWorkDataSourceId ..
    --         "/repository/files/" .. loginMain.username .. "/paracraft/_theme.md?ref=master"

    -- self:getUrl(
    --     contentUrl,
    --     function(data, err)
    --         if (err == 404) then
    --             local themePath = loginMain.username .. "/paracraft/_theme.md"

    --             SyncMain:uploadService(
    --                 loginMain.keepWorkDataSource,
    --                 themePath,
    --                 KeepworkGen.paracraftContainer,
    --                 function(data, err)
    --                     if (type(callback) == "function") then
    --                         callback()
    --                     end
    --                 end,
    --                 loginMain.keepWorkDataSourceId
    --             )
    --         end
    --     end
    -- )
end

function GenerateMdPage:genWorldMD(callback)
    -- local contentUrl =
    --     format(
    --     "projects/%s/repository/files/%s/paracraft/world_%s.md?ref=master",
    --     loginMain.keepWorkDataSourceId,
    --     loginMain.username,
    --     self.worldInfo.worldsName
    -- )

    -- local worldFilePath = format("%s/paracraft/world_%s.md", loginMain.username, self.worldInfo.worldsName)

    -- local paracraftParams = {
    --     link_world_name = self.worldInfo.name,
    --     link_world_url = self.worldInfo.download,
    --     media_logo = self.worldInfo.preview,
    --     link_desc = "",
    --     link_username = loginMain.username,
    --     link_update_date = self.worldInfo.modDate,
    --     link_version = self.worldInfo.revision,
    --     link_opus_id = self.worldInfo.opusId,
    --     link_files_totals = self.worldInfo.filesTotals
    -- }

    -- local paracraftCommand = KeepworkGen:setCommand("paracraft", paracraftParams)

    -- self:getUrl(
    --     contentUrl,
    --     function(data, err)
    --         if (err == 404) then
    --             if (not self.worldInfo.readme) then
    --                 self.worldInfo.readme = ""
    --             end

    --             SyncMain.worldFile = KeepworkGen:SetAutoGenContent(self.worldInfo.readme, paracraftCommand)
    --             SyncMain.worldFile = SyncMain.worldFile .. "\r\n" .. KeepworkGen:setCommand("comment")

    --             SyncMain:uploadService(
    --                 loginMain.keepWorkDataSource,
    --                 worldFilePath,
    --                 SyncMain.worldFile,
    --                 function(data, err)
    --                     if (type(callback) == "function") then
    --                         callback()
    --                     end
    --                 end,
    --                 loginMain.keepWorkDataSourceId
    --             )
    --         elseif (err == 200 or err == 304) then
    --             data = Encoding.unbase64(data.content)

    --             SyncMain.worldFile = KeepworkGen:SetAutoGenContent(data, paracraftCommand)

    --             GitService:updateService(
    --                 loginMain.keepWorkDataSource,
    --                 worldFilePath,
    --                 SyncMain.worldFile,
    --                 "",
    --                 function(isSuccess, path)
    --                     if (type(callback) == "function") then
    --                         callback()
    --                     end
    --                 end,
    --                 loginMain.keepWorkDataSourceId
    --             )
    --         end
    --     end
    -- )
end

function GenerateMdPage:deleteWorldMD(_path, callback)
    -- local function deleteFile(keepworkId)
    --     local path = loginMain.username .. "/paracraft/world_" .. _path .. ".md"

    --     GitService:deleteFileService(
    --         loginMain.keepWorkDataSource,
    --         path,
    --         "",
    --         function(data, err)
    --             if (type(callback) == "function") then
    --                 callback()
    --             end
    --         end,
    --         keepworkId
    --     )
    -- end

    -- if (loginMain.dataSourceType == "github") then
    --     deleteFile()
    -- elseif (loginMain.dataSourceType == "gitlab") then
    --     GitService:getProjectIdByName(
    --         loginMain.keepWorkDataSource,
    --         function(keepworkId)
    --             deleteFile(keepworkId)
    --         end
    --     )
    -- end
end

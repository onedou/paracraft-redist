--[[
Title: SyncToLocal
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncToLocal.lua");
local SyncToLocal = commonlib.gettable("Mod.WorldShare.sync.SyncToLocal");
------------------------------------------------------------
]]
local SyncToLocal = commonlib.gettable("Mod.WorldShare.sync.SyncToLocal")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")

SyncToLocal.localSync = {}
SyncMain.finish = false

-- 加载进度UI界面
local syncToLocalGUI = SyncGUI:new()

if (loginMain.dataSourceType == "gitlab") then
    GitService:setGitlabProjectId(SyncMain.foldername.utf8)
end

if (SyncMain.worldDir.default == "") then
    _guihelper.MessageBox(L "下载失败，原因：下载目录为空")
    return
else
    SyncMain.curUpdateIndex = 1
    SyncMain.curDownloadIndex = 1
    SyncMain.totalLocalIndex = nil
    SyncMain.totalDataSourceIndex = nil
    SyncMain.dataSourceFiles = {}

    local syncGUItotal = 0
    local syncGUIIndex = 0
    local syncGUIFiles = ""

    SyncMain.finish = false

    syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, L "获取文件sha列表")

    -- 获取数据源仓文件
    GitService:getFileShaListService(
        SyncMain.foldername.utf8,
        function(data, err)
            if (err ~= 404) then
                if (err == 409) then
                    _guihelper.MessageBox(L "数据源上暂无数据")
                    syncToLocalGUI.finish()
                    return
                end

                SyncMain.localFiles = LocalService:new():LoadFiles(SyncMain.worldDir.default)
                SyncMain.dataSourceFiles = data

                SyncMain.totalLocalIndex = #SyncMain.localFiles
                SyncMain.totalDataSourceIndex = #SyncMain.dataSourceFiles

                for key, value in ipairs(SyncMain.dataSourceFiles) do
                    value.needChange = true

                    if (value.type == "blob") then
                        syncGUItotal = syncGUItotal + 1
                    end
                end

                syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, L "开始同步")

                if (SyncMain.totalLocalIndex ~= 0) then
                    SyncMain.localSync.updateOne()
                else
                    --downloadOne();
                    --如果文档文件夹为空，则直接开始下载
                    LocalService:downloadZip(
                        SyncMain.foldername.utf8,
                        SyncMain.commitId,
                        function(bSuccess, remoteRevison)
                            if (bSuccess) then
                                SyncMain.remoteRevison = remoteRevison
                                syncGUIIndex = syncGUItotal
                                SyncMain.localSync.finish()
                                loginMain.RefreshCurrentServerList()
                            else
                                _guihelper.MessageBox(L "下载失败，请稍后再试")
                            end
                        end
                    )
                end
            else
                _guihelper.MessageBox(L "获取数据源文件失败，请稍后再试！")
                syncToLocalGUI.finish()
            end
        end,
        SyncMain.commitId
    )
end


function SyncMain.localSync.finish()
    syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, L "同步完成")
    local localWorlds = InternetLoadWorld.cur_ds

    for key, value in ipairs(localWorlds) do
        if (SyncMain.foldername.utf8 == value["foldername"]) then
            --LOG.std(nil,"debug","SyncMain.foldername",SyncMain.foldername.utf8);
            localWorlds[key].status = 3
            localWorlds[key].revision = SyncMain.remoteRevison
            loginMain.refreshPage()
        end
    end

    --成功是返回信息给login
    if (type(callback) == "function") then
        local params = {}
        params.revison = SyncMain.remoteRevison

        callback(true, params)
    end

    SyncMain.finish = true
end

-- 下载新文件
function SyncMain.localSync.downloadOne()
    LOG.std(
        "SyncMain",
        "debug",
        "NumbersToLCDL",
        "totals : %s , current : %s",
        SyncMain.totalDataSourceIndex,
        SyncMain.curDownloadIndex
    )

    if (SyncMain.finish) then
        LOG.std("SyncMain", "debug", "强制中断")
        return
    end

    if (SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].needChange) then
        if (SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].type == "blob") then
            -- LOG.std(nil,"debug","githubFiles.tree[SyncMain.curDownloadIndex].type",githubFiles.tree[SyncMain.curDownloadIndex].type);

            SyncMain.isFetching = true
            LocalService:download(
                SyncMain.foldername.utf8,
                SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].path,
                function(bIsDownload, response)
                    if (bIsDownload) then
                        syncGUIIndex = syncGUIIndex + 1
                        syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, response.filename)

                        if (response.filename == "revision.xml") then
                            SyncMain.remoteRevison = response.content
                        end

                        if (SyncMain.curDownloadIndex == SyncMain.totalDataSourceIndex) then
                            SyncMain.localSync.finish()
                        else
                            SyncMain.curDownloadIndex = SyncMain.curDownloadIndex + 1
                            SyncMain.localSync.downloadOne()
                        end
                    else
                        --syncToLocalGUI.finish();
                        --SyncMain.finish = true;
                        _guihelper.MessageBox(L "下载失败，请稍后再试")
                    end

                    SyncMain.isFetching = false
                end
            )
        end
    else
        if (SyncMain.curDownloadIndex == SyncMain.totalDataSourceIndex) then
            SyncMain.localSync.finish()
        else
            SyncMain.curDownloadIndex = SyncMain.curDownloadIndex + 1
            SyncMain.localSync.downloadOne()
        end
    end
end

-- 删除文件
function SyncMain.localSync.deleteOne()
    if (SyncMain.finish) then
        LOG.std("SyncMain", "debug", "强制中断")
        return
    end

    LocalService:delete(
        SyncMain.foldername.utf8,
        SyncMain.localFiles[SyncMain.curUpdateIndex].filename,
        function(data, err)
            if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
                SyncMain.localSync.downloadOne()
            else
                SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1
                SyncMain.localSync.updateOne()
            end
        end
    )
end

-- 更新本地文件
function SyncMain.localSync.updateOne()
    LOG.std(
        "SyncMain",
        "debug",
        "NumbersToLCUD",
        "totals : %s , current : %s",
        SyncMain.totalLocalIndex,
        SyncMain.curUpdateIndex
    )

    if (SyncMain.finish) then
        LOG.std("SyncMain", "debug", "强制中断")
        return
    end

    local bIsExisted = false
    local dataSourceIndex = nil

    -- 用数据源的文件和本地的文件对比
    for key, value in ipairs(SyncMain.dataSourceFiles) do
        if (value.path == SyncMain.localFiles[SyncMain.curUpdateIndex].filename) then
            --LOG.std(nil,"debug","value.path",value.path);
            bIsExisted = true
            dataSourceIndex = key
            break
        end
    end

    -- 本地是否存在数据源上的文件
    if (bIsExisted) then
        SyncMain.dataSourceFiles[dataSourceIndex].needChange = false
        LOG.std(
            "SyncMain",
            "debug",
            "FilesShaToLCUP",
            "File : %s, DSSha : %s , LCSha : %s",
            SyncMain.dataSourceFiles[dataSourceIndex].path,
            SyncMain.dataSourceFiles[dataSourceIndex].sha,
            SyncMain.localFiles[SyncMain.curUpdateIndex].sha1
        )

        if (SyncMain.localFiles[SyncMain.curUpdateIndex].sha1 ~= SyncMain.dataSourceFiles[dataSourceIndex].sha) then
            -- 更新已存在的文件

            SyncMain.isFetching = true
            LocalService:update(
                SyncMain.foldername.utf8,
                SyncMain.dataSourceFiles[dataSourceIndex].path,
                function(bIsUpdate, response)
                    if (bIsUpdate) then
                        if (response.filename == "revision.xml") then
                            SyncMain.remoteRevison = response.content
                        end

                        syncGUIIndex = syncGUIIndex + 1
                        syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, response.filename)

                        if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
                            SyncMain.localSync.downloadOne()
                        else
                            SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1
                            SyncMain.localSync.updateOne()
                        end
                    else
                        --syncToLocalGUI.finish();
                        --SyncMain.finish = true;
                        _guihelper.MessageBox(L "更新失败,请稍后再试")
                    end

                    SyncMain.isFetching = false
                end
            )
        else
            syncGUIIndex = syncGUIIndex + 1
            syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.dataSourceFiles[dataSourceIndex].path)

            if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
                SyncMain.localSync.downloadOne()
            else
                SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1
                SyncMain.localSync.updateOne()
            end
        end
    else
        -- 如果数据源不存在，则删除本地的文件
        SyncMain.localSync.deleteOne()
    end
end

--[[
Title: SyncToDataSource
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncToDataSource.lua");
local SyncToDataSource = commonlib.gettable("Mod.WorldShare.sync.SyncToDataSource");
------------------------------------------------------------
]]
local SyncToDataSource = commonlib.gettable("Mod.WorldShare.sync.SyncToDataSource")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")

SyncToDataSource.remoteSync = {}

function SyncToDataSource:init()
    if (SyncMain:checkWorldSize()) then
        return false
    end

    -- 加载进度UI界面
    self.syncToDataSourceGUI = SyncGUI:new()
    self.syncToDataSourceGUI:refresh()
    self.finish = false

    if (SyncMain.remoteRevison == 0) then
        --"首次同步"
        GitService:create(
            SyncMain.foldername.base32,
            function(data, status)
                if (data == true) then
                    self:syncToDataSource()
                else
                    _guihelper.MessageBox(L "数据源创建失败")
                    self.syncToDataSourceGUI.finish()
                    return
                end
            end
        )
    else
        --"非首次同步"
        GitService:setProjectId(self.foldername.utf8, self.remoteWorldsList)
        self:syncToDataSource()
    end
end

function SyncToDataSource:syncToDataSource()
    if (SyncMain.worldDir.default == "") then
        _guihelper.MessageBox(L "上传失败，将使用离线模式，原因：上传目录为空")
        return
    else
        self.curUpdateIndex = 1
        self.curUploadIndex = 1
        self.totalLocalIndex = nil
        self.totalDataSourceIndex = nil
        self.dataSourceFiles = {}

        self.revisionUpload = false
        self.revisionUpdate = false

        local syncGUItotal = 0
        local syncGUIIndex = 0
        local syncGUIFiles = ""

        syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L "获取文件sha列表")

        -- 获取数据源仓文件
        SyncMain:getFileShaListService(
            SyncMain.foldername.base32,
            function(data, err)
                SyncMain.localFiles = LocalService:new():LoadFiles(SyncMain.worldDir.default) --再次获取本地文件，保证上传的内容为最新

                local hasReadme = false

                for key, value in ipairs(SyncMain.localFiles) do
                    if (string.upper(value.filename) == "README.MD") then
                        if (value.filename == "README.md") then
                            hasReadme = true
                        else
                            LocalService:delete(SyncMain.foldername.utf8, value.filename)
                            hasReadme = false
                        end
                    end
                end

                if (not hasReadme) then
                    local filePath = SyncMain.worldDir.default .. "README.md"
                    local file = ParaIO.open(filePath, "w")
                    local content = KeepworkGen.readmeDefault

                    file:write(content, #content)
                    file:close()

                    local readMeFiles = {
                        filename = "README.md",
                        file_path = filePath,
                        file_content_t = content
                    }

                    local otherFile = commonlib.copy(SyncMain.localFiles[#SyncMain.localFiles])
                    SyncMain.localFiles[#SyncMain.localFiles] = readMeFiles
                    SyncMain.localFiles[#SyncMain.localFiles + 1] = otherFile
                end

                self.totalLocalIndex = #SyncMain.localFiles
                syncGUItotal = #SyncMain.localFiles

                for i = 1, #SyncMain.localFiles do
                    SyncMain.localFiles[i].needChange = true
                    i = i + 1
                end

                if (err ~= 409 and err ~= 404) then --409代表已经创建过此仓
                    self.dataSourceFiles = data
                    self.totalDataSourceIndex = #self.dataSourceFiles

                    if (self.totalDataSourceIndex ~= 0) then
                        SyncMain.remoteSync.updateOne()
                    end
                else
                    SyncMain.remoteSync.uploadOne()
                end
            end
        )
    end
end

function SyncToDataSource:revision(callback)
    if (self.revisionUpload) then
        SyncMain:uploadService(
            SyncMain.foldername.base32,
            "revision.xml",
            SyncMain.revisionContent,
            function(bIsUpload, filename)
                if (bIsUpload) then
                    syncGUIIndex = syncGUIIndex + 1
                    syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L "同步完成，正在更新世界信息，请稍后...")

                    if (type(callback) == "function") then
                        callback()
                    end
                else
                    _guihelper.MessageBox(L "revision上传失败")
                    syncGUIIndex = syncGUIIndex + 1
                    syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename)
                end
            end
        )
    end

    if (self.revisionUpdate) then
        GitService:updateService(
            SyncMain.foldername.base32,
            "revision.xml",
            SyncMain.revisionContent,
            SyncMain.revisionSha1,
            function(bIsUpdate, filename)
                if (bIsUpdate) then
                    syncGUIIndex = syncGUIIndex + 1
                    syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L "同步完成，正在更新世界信息，请稍后...")

                    if (type(callback) == "function") then
                        callback()
                    end
                else
                    _guihelper.MessageBox(L "revision更新失败")
                    syncGUIIndex = syncGUIIndex + 1
                    syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename)
                end
            end
        )
    end
end

function SyncToDataSource:finish()
    SyncMain.remoteSync.revision(
        function()
            if (syncGUIIndex > syncGUItotal) then
                _guihelper.MessageBox(L "更新失败，请重试再试")
                syncToDataSourceGUI.closeWindow()
                return
            end

            SyncMain:refreshRemoteWorldLists(syncToDataSourceGUI)
        end
    )
end

-- 上传新文件
function SyncToDataSource:uploadOne()
    LOG.std(
        "SyncMain",
        "debug",
        "NumbersToDSUD",
        "totals : %s , current : %s, file : %s",
        self.totalLocalIndex,
        self.curUploadIndex,
        SyncMain.localFiles[self.curUploadIndex].filename
    )

    if (self.finish) then
        LOG.std("SyncMain", "debug", "强制中断")
        return
    end

    if
        (string.lower(SyncMain.localFiles[self.curUploadIndex].filename) == "revision.xml" and
            SyncMain.localFiles[self.curUploadIndex].needChange)
     then
        self.revisionUpload = true
        self.revisionContent = SyncMain.localFiles[self.curUploadIndex].file_content_t

        if (self.curUploadIndex == self.totalLocalIndex) then
            SyncMain.remoteSync.finish()
        else
            self.curUploadIndex = self.curUploadIndex + 1
            SyncMain.remoteSync.uploadOne() --继续递归上传
        end

        return
    end

    if (SyncMain.localFiles[self.curUploadIndex].needChange) then
        SyncMain.localFiles[self.curUploadIndex].needChange = false
        SyncMain.isFetching = true

        LOG.std(
            "SyncMain",
            "debug",
            "FilesShaToDSUD",
            "File : %s, 上传中",
            SyncMain.localFiles[self.curUploadIndex].filename
        )
        syncGUIIndex = syncGUIIndex + 1
        syncToDataSourceGUI:updateDataBar(
            syncGUIIndex,
            syncGUItotal,
            format(
                L "%s （%s） 上传中",
                SyncMain.localFiles[self.curUploadIndex].filename,
                loginMain.GetWorldSize(SyncMain.localFiles[self.curUploadIndex].filesize, "KB")
            )
        )

        SyncMain:uploadService(
            SyncMain.foldername.base32,
            SyncMain.localFiles[self.curUploadIndex].filename,
            SyncMain.localFiles[self.curUploadIndex].file_content_t,
            function(bIsUpload, filename)
                SyncMain.isFetching = false

                if (bIsUpload) then
                    LOG.std(
                        "SyncMain",
                        "debug",
                        "FilesShaToDSUD",
                        "File : %s, 上传完成",
                        SyncMain.localFiles[self.curUploadIndex].filename
                    )
                    syncToDataSourceGUI:updateDataBar(
                        syncGUIIndex,
                        syncGUItotal,
                        format(
                            L "%s（%s）上传完成",
                            filename,
                            loginMain.GetWorldSize(SyncMain.localFiles[self.curUploadIndex].filesize, "KB")
                        )
                    )

                    if (self.curUploadIndex == self.totalLocalIndex) then
                        SyncMain.remoteSync.finish()
                    else
                        self.curUploadIndex = self.curUploadIndex + 1
                        SyncMain.remoteSync.uploadOne() --继续递归上传
                    end
                else
                    --syncToDataSourceGUI.finish();
                    --SyncMain.finish = true;
                    _guihelper.MessageBox(format("%s上传失败", SyncMain.localFiles[self.curUploadIndex].filename))
                    LOG.std(
                        "SyncMain",
                        "debug",
                        "FilesShaToDSUD",
                        "File : %s, 上传失败",
                        SyncMain.localFiles[self.curUploadIndex].filename
                    )

                    syncGUIIndex = syncGUIIndex + 1
                    syncToDataSourceGUI:updateDataBar(
                        syncGUIIndex,
                        syncGUItotal,
                        format(L "%s上传失败", SyncMain.localFiles[self.curUploadIndex].filename)
                    )
                end
            end
        )
    else
        LOG.std(
            "SyncMain",
            "debug",
            "FilesShaToDSUD",
            "File : %s, 已更新，跳过",
            SyncMain.localFiles[self.curUploadIndex].filename
        )

        if (self.curUploadIndex == self.totalLocalIndex) then
            SyncMain.remoteSync.finish()
        else
            self.curUploadIndex = self.curUploadIndex + 1
            SyncMain.remoteSync.uploadOne() --继续递归上传
        end
    end
end

-- 删除数据源文件
function SyncToDataSource:deleteOne()
    if (self.finish) then
        LOG.std("SyncMain", "debug", "强制中断")
        return
    end

    if (self.dataSourceFiles[self.curUpdateIndex].type == "blob") then
        SyncMain.isFetching = true

        GitService:deleteFileService(
            SyncMain.foldername.base32,
            self.dataSourceFiles[self.curUpdateIndex].path,
            self.dataSourceFiles[self.curUpdateIndex].sha,
            function(bIsDelete)
                if (bIsDelete) then
                    self.curUpdateIndex = self.curUpdateIndex + 1

                    if (self.curUpdateIndex == self.totalDataSourceIndex) then
                        SyncMain.remoteSync.uploadOne()
                    else
                        SyncMain.remoteSync.updateOne()
                    end
                else
                    --syncToDataSourceGUI.finish();
                    --SyncMain.finish = true;
                    _guihelper.MessageBox(L "删除失败")
                end

                SyncMain.isFetching = false
            end
        )
    else
        if (self.curUpdateIndex == self.totalDataSourceIndex) then
            SyncMain.remoteSync.uploadOne()
        else
            self.curUpdateIndex = self.curUpdateIndex + 1
            SyncMain.remoteSync.updateOne()
        end
    end
end

-- 更新数据源文件
function SyncToDataSource:updateOne()
    LOG.std(
        "SyncMain",
        "debug",
        "NumbersToDSUP",
        "totals : %s , current : %s",
        self.totalDataSourceIndex,
        self.curUpdateIndex
    )

    if (self.finish) then
        LOG.std("SyncMain", "debug", "强制中断")
        return
    end

    local bIsExisted = false
    local LocalIndex = nil
    local curGitFiles = self.dataSourceFiles[self.curUpdateIndex]

    -- 用数据源的文件和本地的文件对比
    for key, value in ipairs(SyncMain.localFiles) do
        if (value.filename == curGitFiles.path) then
            bIsExisted = true
            LocalIndex = key
            break
        end
    end

    if (bIsExisted and string.lower(SyncMain.localFiles[LocalIndex].filename) == "revision.xml") then
        self.revisionUpdate = true
        SyncMain.revisionContent = SyncMain.localFiles[LocalIndex].file_content_t
        SyncMain.revisionSha1 = SyncMain.localFiles[LocalIndex].sha1

        SyncMain.localFiles[LocalIndex].needChange = false

        if (self.curUpdateIndex == self.totalDataSourceIndex) then
            SyncMain.remoteSync.uploadOne()
        else
            self.curUpdateIndex = self.curUpdateIndex + 1 -- 如果不等最大计数则更新
            SyncMain.remoteSync.updateOne()
        end

        return
    end

    if (bIsExisted) then
        syncGUIIndex = syncGUIIndex + 1
        syncToDataSourceGUI:updateDataBar(
            syncGUIIndex,
            syncGUItotal,
            format(L "%s比对中", SyncMain.localFiles[LocalIndex].filename)
        )

        SyncMain.localFiles[LocalIndex].needChange = false
        SyncMain.isFetching = true

        LOG.std(
            "SyncMain",
            "debug",
            "FilesShaToDSUP",
            "File : %s, DSSha : %s , LCSha : %s",
            curGitFiles.path,
            curGitFiles.sha,
            SyncMain.localFiles[LocalIndex].sha1
        )

        if (curGitFiles.sha ~= SyncMain.localFiles[LocalIndex].sha1) then
            syncToDataSourceGUI:updateDataBar(
                syncGUIIndex,
                syncGUItotal,
                format(L "%s更新中", SyncMain.localFiles[LocalIndex].filename)
            )

            -- 更新已存在的文件
            GitService:updateService(
                SyncMain.foldername.base32,
                SyncMain.localFiles[LocalIndex].filename,
                SyncMain.localFiles[LocalIndex].file_content_t,
                curGitFiles.sha,
                function(bIsUpdate, filename)
                    if (bIsUpdate) then
                        syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, format(L "%s更新完成", filename))

                        if (self.curUpdateIndex == self.totalDataSourceIndex) then
                            SyncMain.remoteSync.uploadOne()
                        else
                            self.curUpdateIndex = self.curUpdateIndex + 1 -- 如果不等最大计数则更新
                            SyncMain.remoteSync.updateOne()
                        end
                    else
                        _guihelper.MessageBox(L "更新失败")
                        syncGUIIndex = syncGUIIndex + 1
                        syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename)
                    end

                    SyncMain.isFetching = false
                end
            )
        else
            syncToDataSourceGUI:updateDataBar(
                syncGUIIndex,
                syncGUItotal,
                format(L "%s版本一致，跳过", SyncMain.localFiles[LocalIndex].filename)
            )

            if (self.curUpdateIndex == self.totalDataSourceIndex) then
                SyncMain.remoteSync.uploadOne()
            else
                self.curUpdateIndex = self.curUpdateIndex + 1
                SyncMain.remoteSync.updateOne()
            end
        end
    else
        -- 如果本地不删除存在，则删除数据源的文件
        SyncMain.remoteSync.deleteOne()
    end
end

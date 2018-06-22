--[[
Title: SyncToDataSource
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncToDataSource.lua")
local SyncToDataSource = commonlib.gettable("Mod.WorldShare.sync.SyncToDataSource")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

local SyncGUI = commonlib.gettable("Mod.WorldShare.sync.SyncGUI")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")

local SyncToDataSource = commonlib.gettable("Mod.WorldShare.sync.SyncToDataSource")

local UPDATE = "UPDATE"
local UPLOAD = "UPLOAD"
local DELETE = "DELETE"

function SyncToDataSource:init()
    local foldername = GlobalStore.get("foldername")

    if (SyncMain:checkWorldSize()) then
        return false
    end

    -- 加载进度UI界面
    self.syncToDataSourceGUI = SyncGUI:new()
    self.syncToDataSourceGUI:refresh()
    self.finish = false

    GitService:new():create(
        foldername.base32,
        function(projectId)
            if (projectId) then
                self.projectId = projectId
                self:syncToDataSource()
            else
                _guihelper.MessageBox(L "数据源创建失败")
                self.syncToDataSourceGUI.finish()
                return false
            end
        end
    )
end

function SyncToDataSource:syncToDataSource()
    self.worldDir = GlobalStore.get("worldDir")
    self.foldername = GlobalStore.get("foldername")

    if (not self.worldDir or not self.worldDir.default or self.worldDir.default == "") then
        _guihelper.MessageBox(L "上传失败，将使用离线模式，原因：上传目录为空")
        return false
    end

    self.compareListIndex = 1
    self.compareListTotal = 0

    self.syncToDataSourceGUI:updateDataBar(self.compareListIndex, self.compareListTotal, L "获取文件sha列表")

    local function handleSyncToDataSource(data, err)
        self.dataSourceFiles = data
        self.localFiles = LocalService:new():LoadFiles(self.worldDir.default) --再次获取本地文件，保证上传的内容为最新

        self:CheckReadmeFile()
        self:GetCompareList()
        self:HandleCompareList()
        -- self.totalLocalIndex = #self.localFiles
        -- self.totalDataSourceIndex = #self.dataSourceFiles
        -- self.syncGUItotal = self.totalLocalIndex

        -- echo(self.dataSourceFiles, true)
        -- echo(self.localFiles, true)

        -- if (self.totalDataSourceIndex ~= 0) then
        --     self:updateOne()
        -- else
        --     self:uploadOne()
        -- end
    end

    GitService:new():getTree(
        self.projectId, --projectId
        self.foldername.base32,
        nil, --commitId
        handleSyncToDataSource
    )
end

function SyncToDataSource:revision(callback)
    if (self.revisionUpload) then
        GitService:new():upload(
            self.foldername.base32,
            "revision.xml",
            self.revisionContent,
            function(bIsUpload, filename)
                if (bIsUpload) then
                    self.syncGUIIndex = self.syncGUIIndex + 1
                    self.syncToDataSourceGUI:updateDataBar(
                        self.syncGUIIndex,
                        self.syncGUItotal,
                        L "同步完成，正在更新世界信息，请稍后..."
                    )

                    if (type(callback) == "function") then
                        callback()
                    end
                else
                    _guihelper.MessageBox(L "revision上传失败")
                    self.syncGUIIndex = self.syncGUIIndex + 1
                    self.syncToDataSourceGUI:updateDataBar(self.syncGUIIndex, self.syncGUItotal, filename)
                end
            end
        )
    end

    if (self.revisionUpdate) then
        GitService:new():update(
            self.foldername.base32,
            "revision.xml",
            self.revisionContent,
            self.revisionSha1,
            function(bIsUpdate, filename)
                if (bIsUpdate) then
                    self.syncGUIIndex = self.syncGUIIndex + 1
                    self.syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L "同步完成，正在更新世界信息，请稍后...")

                    if (type(callback) == "function") then
                        callback()
                    end
                else
                    _guihelper.MessageBox(L "revision更新失败")
                    self.syncGUIIndex = self.syncGUIIndex + 1
                    self.syncToDataSourceGUI:updateDataBar(self.syncGUIIndex, self.syncGUItotal, filename)
                end
            end
        )
    end
end

function SyncToDataSource:CheckReadmeFile()
    if (not self.localFiles) then
        return false
    end

    local hasReadme = false

    for key, value in ipairs(self.localFiles) do
        if (string.upper(value.filename) == "README.MD") then
            if (value.filename == "README.md") then
                hasReadme = true
            else
                LocalService:new():delete(self.foldername, value.filename)
                hasReadme = false
            end
        end
    end

    if (not hasReadme) then
        local filePath = format("%sREADME.md", self.worldDir.default)
        local file = ParaIO.open(filePath, "w")
        local content = KeepworkGen.readmeDefault

        file:write(content, #content)
        file:close()

        local readMeFiles = {
            filename = "README.md",
            file_path = filePath,
            file_content_t = content
        }

        local otherFile = commonlib.copy(self.localFiles[#self.localFiles])

        self.localFiles[#self.localFiles] = readMeFiles
        self.localFiles[#self.localFiles + 1] = otherFile
    end
end

function SyncToDataSource:GetCompareList()
    self.compareList = commonlib.vector:new()

    for LKey, LItem in ipairs(self.localFiles) do
        local bIsExisted = false

        for IKey, IItem in ipairs(self.dataSourceFiles) do
            if (LItem.filename == IItem.path) then
                bIsExisted = true
                break
            end
        end

        local currentItem = {
            file = LItem.filename,
            status = bIsExisted and UPDATE or UPLOAD
        }

        self.compareList:push_back(currentItem)
    end

    for IKey, IItem in ipairs(self.dataSourceFiles) do
        local bIsExisted = false

        for LKey, LItem in ipairs(self.localFiles) do
            if (IItem.path == LItem.filename) then
                bIsExisted = true
                break
            end
        end

        if (not bIsExisted) then
            local currentItem = {
                file = IItem.path,
                status = DELETE
            }

            self.compareList:push_back(currentItem)
        end
    end

    -- handle revision in last
    for CKey, CItem in ipairs(self.compareList) do
        if (string.lower(CItem.file) == "revision.xml") then
            self.compareList:push_back(CItem)
            self.compareList:remove(CKey)
        end
    end

    self.compareListTotal = #self.compareList
end

function SyncToDataSource:HandleCompareList()
    if (self.compareListTotal == self.compareListIndex) then
        -- sync finish
        self.compareListIndex = 1
        return false
    end

    if (self.finish) then
        LOG.std("SyncToDataSource", "debug", "强制中断")
        return false
    end

    local currentItem = self.compareList[self.compareListIndex]

    local function retry()
        self.syncToDataSourceGUI:updateDataBar(
            self.compareListIndex,
            self.compareListTotal,
            format(L "%s 处理完成", currentItem.file)
        )

        self.compareListIndex = self.compareListIndex + 1
        self:HandleCompareList()
    end

    if (currentItem.status == UPDATE) then
        self:updateOne(currentItem.file, retry)
    end

    if (currentItem.status == UPLOAD) then
        self:uploadOne(currentItem.file, retry)
    end

    if (currentItem.status == DELETE) then
        self:deleteOne(currentItem.file, retry)
    end
end

function SyncToDataSource:GetLocalFileByFilename(filename)
    for key, item in ipairs(self.localFiles) do
        if (item.filename == filename) then
            return item
        end
    end
end

function SyncToDataSource:finish()
    self.revision(
        function()
            if (self.syncGUIIndex > self.syncGUItotal) then
                _guihelper.MessageBox(L "更新失败，请重试再试")
                self.syncToDataSourceGUI:closeWindow()
                return
            end

            SyncMain:refreshRemoteWorldLists(self.syncToDataSourceGUI)
        end
    )
end

-- 上传新文件
function SyncToDataSource:uploadOne(file, callback)
    local currentItem = self:GetLocalFileByFilename(file)

    self.syncToDataSourceGUI:updateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L "%s （%s） 上传中", currentItem.filename, Utils.formatFileSize(currentItem.filesize, "KB"))
    )

    -- if (self.finish) then
    --     LOG.std("SyncMain", "debug", "强制中断")
    --     return false
    -- end

    -- if
    --     (string.lower(self.localFiles[self.curUploadIndex].filename) == "revision.xml" and
    --         self.localFiles[self.curUploadIndex].needChange)
    --  then
    --     self.revisionUpload = true
    --     self.revisionContent = self.localFiles[self.curUploadIndex].file_content_t

    --     if (self.curUploadIndex == self.totalLocalIndex) then
    --         self.finish()
    --     else
    --         self.curUploadIndex = self.curUploadIndex + 1
    --         self.uploadOne() --继续递归上传
    --     end

    --     return false
    -- end

    -- if (self.localFiles[self.curUploadIndex].needChange) then
    --     self.localFiles[self.curUploadIndex].needChange = false
    --     self.isFetching = true

    --     LOG.std("SyncMain", "debug", "FilesShaToDSUD", "File : %s, 上传中", self.localFiles[self.curUploadIndex].filename)

    --     self.syncGUIIndex = self.syncGUIIndex + 1
    --     self.syncToDataSourceGUI:updateDataBar(
    --         self.syncGUIIndex,
    --         self.syncGUItotal,
    --         format(
    --             L "%s （%s） 上传中",
    --             self.localFiles[self.curUploadIndex].filename,
    --             Utils.formatFileSize(self.localFiles[self.curUploadIndex].filesize, "KB")
    --         )
    --     )

    --     GitService:new():upload(
    --         self.foldername.base32,
    --         self.localFiles[self.curUploadIndex].filename,
    --         self.localFiles[self.curUploadIndex].file_content_t,
    --         function(bIsUpload, filename)
    --             self.isFetching = false

    --             if (bIsUpload) then
    --                 LOG.std(
    --                     "SyncMain",
    --                     "debug",
    --                     "FilesShaToDSUD",
    --                     "File : %s, 上传完成",
    --                     self.localFiles[self.curUploadIndex].filename
    --                 )
    --                 self.syncToDataSourceGUI:updateDataBar(
    --                     self.syncGUIIndex,
    --                     self.syncGUItotal,
    --                     format(
    --                         L "%s（%s）上传完成",
    --                         filename,
    --                         Utils.GetWorldSize(self.localFiles[self.curUploadIndex].filesize, "KB")
    --                     )
    --                 )

    --                 if (self.curUploadIndex == self.totalLocalIndex) then
    --                     self.finish()
    --                 else
    --                     self.curUploadIndex = self.curUploadIndex + 1
    --                     self.uploadOne() --继续递归上传
    --                 end
    --             else
    --                 --syncToDataSourceGUI.finish();
    --                 --SyncMain.finish = true;
    --                 _guihelper.MessageBox(format("%s上传失败", self.localFiles[self.curUploadIndex].filename))
    --                 LOG.std(
    --                     "SyncMain",
    --                     "debug",
    --                     "FilesShaToDSUD",
    --                     "File : %s, 上传失败",
    --                     self.localFiles[self.curUploadIndex].filename
    --                 )

    --                 self.syncGUIIndex = self.syncGUIIndex + 1
    --                 self.syncToDataSourceGUI:updateDataBar(
    --                     self.syncGUIIndex,
    --                     self.syncGUItotal,
    --                     format(L "%s上传失败", self.localFiles[self.curUploadIndex].filename)
    --                 )
    --             end
    --         end
    --     )
    -- else
    --     LOG.std(
    --         "SyncMain",
    --         "debug",
    --         "FilesShaToDSUD",
    --         "File : %s, 已更新，跳过",
    --         self.localFiles[self.curUploadIndex].filename
    --     )

    --     if (self.curUploadIndex == self.totalLocalIndex) then
    --         self.finish()
    --     else
    --         self.curUploadIndex = self.curUploadIndex + 1
    --         self.uploadOne() --继续递归上传
    --     end
    -- end
end

-- 更新数据源文件
function SyncToDataSource:updateOne(file, callback)
    local currentItem = self:GetLocalFileByFilename(file)

    self.syncToDataSourceGUI:updateDataBar(
        self.compareListIndex,
        self.compareListTotal,
        format(L "%s （%s） 更新中", currentItem.filename, Utils.formatFileSize(currentItem.filesize, "KB"))
    )

    -- LOG.std(
    --     "SyncMain",
    --     "debug",
    --     "NumbersToDSUP",
    --     "totals : %s , current : %s",
    --     self.totalDataSourceIndex,
    --     self.curUpdateIndex
    -- )

    -- if (self.finish) then
    --     LOG.std("SyncMain", "debug", "强制中断")
    --     return false
    -- end

    -- local bIsExisted = false
    -- local LocalIndex = nil
    -- local curGitFiles = self.dataSourceFiles[self.curUpdateIndex]

    -- -- 用数据源的文件和本地的文件对比
    -- for key, value in ipairs(self.localFiles) do
    --     if (value.filename == curGitFiles.path) then
    --         bIsExisted = true
    --         LocalIndex = key
    --         break
    --     end
    -- end

    -- if (bIsExisted and string.lower(self.localFiles[LocalIndex].filename) == "revision.xml") then
    --     self.revisionUpdate = true
    --     self.revisionContent = self.localFiles[LocalIndex].file_content_t
    --     self.revisionSha1 = self.localFiles[LocalIndex].sha1

    --     self.localFiles[LocalIndex].needChange = false

    --     if (self.curUpdateIndex == self.totalDataSourceIndex) then
    --         self:uploadOne()
    --     else
    --         self.curUpdateIndex = self.curUpdateIndex + 1 -- 如果不等最大计数则更新
    --         self:updateOne()
    --     end

    --     return
    -- end

    -- if (bIsExisted) then
    --     self.syncGUIIndex = self.syncGUIIndex + 1
    --     self.syncToDataSourceGUI:updateDataBar(
    --         self.syncGUIIndex,
    --         self.syncGUItotal,
    --         format(L "%s比对中", self.localFiles[LocalIndex].filename)
    --     )

    --     self.localFiles[LocalIndex].needChange = false
    --     self.isFetching = true

    --     LOG.std(
    --         "SyncMain",
    --         "debug",
    --         "FilesShaToDSUP",
    --         "File : %s, DSSha : %s , LCSha : %s",
    --         curGitFiles.path,
    --         curGitFiles.sha,
    --         self.localFiles[LocalIndex].sha1
    --     )

    --     if (curGitFiles.sha ~= self.localFiles[LocalIndex].sha1) then
    --         self.syncToDataSourceGUI:updateDataBar(
    --             self.syncGUIIndex,
    --             self.syncGUItotal,
    --             format(L "%s更新中", self.localFiles[LocalIndex].filename)
    --         )

    --         -- 更新已存在的文件
    --         GitService:updateService(
    --             SyncMain.foldername.base32,
    --             SyncMain.localFiles[LocalIndex].filename,
    --             SyncMain.localFiles[LocalIndex].file_content_t,
    --             curGitFiles.sha,
    --             function(bIsUpdate, filename)
    --                 if (bIsUpdate) then
    --                     self.syncToDataSourceGUI:updateDataBar(
    --                         self.syncGUIIndex,
    --                         self.syncGUItotal,
    --                         format(L "%s更新完成", filename)
    --                     )

    --                     if (self.curUpdateIndex == self.totalDataSourceIndex) then
    --                         self.uploadOne()
    --                     else
    --                         self.curUpdateIndex = self.curUpdateIndex + 1 -- 如果不等最大计数则更新
    --                         self.updateOne()
    --                     end
    --                 else
    --                     _guihelper.MessageBox(L "更新失败")
    --                     self.syncGUIIndex = self.syncGUIIndex + 1
    --                     self.syncToDataSourceGUI:updateDataBar(self.syncGUIIndex, self.syncGUItotal, filename)
    --                 end

    --                 self.isFetching = false
    --             end
    --         )
    --     else
    --         self.syncToDataSourceGUI:updateDataBar(
    --             self.syncGUIIndex,
    --             self.syncGUItotal,
    --             format(L "%s版本一致，跳过", self.localFiles[LocalIndex].filename)
    --         )

    --         if (self.curUpdateIndex == self.totalDataSourceIndex) then
    --             self.uploadOne()
    --         else
    --             self.curUpdateIndex = self.curUpdateIndex + 1
    --             self.updateOne()
    --         end
    --     end
    -- else
    --     -- 如果本地不删除存在，则删除数据源的文件
    --     self.deleteOne()
    -- end
end

-- 删除数据源文件
function SyncToDataSource:deleteOne()
    if (self.finish) then
        LOG.std("SyncMain", "debug", "强制中断")
        return
    end

    if (self.dataSourceFiles[self.curUpdateIndex].type == "blob") then
        self.isFetching = true

        GitService:new():deleteFileService(
            self.foldername.base32,
            self.dataSourceFiles[self.curUpdateIndex].path,
            self.dataSourceFiles[self.curUpdateIndex].sha,
            function(bIsDelete)
                if (bIsDelete) then
                    self.curUpdateIndex = self.curUpdateIndex + 1

                    if (self.curUpdateIndex == self.totalDataSourceIndex) then
                        self.uploadOne()
                    else
                        self.updateOne()
                    end
                else
                    --syncToDataSourceGUI.finish();
                    --SyncMain.finish = true;
                    _guihelper.MessageBox(L "删除失败")
                end

                self.isFetching = false
            end
        )
    else
        if (self.curUpdateIndex == self.totalDataSourceIndex) then
            self.uploadOne()
        else
            self.curUpdateIndex = self.curUpdateIndex + 1
            self.updateOne()
        end
    end
end

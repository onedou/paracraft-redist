--[[
Title: VersionChange
Author(s):  big
Date: 2018.06.25
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/VersionChange.lua")
local VersionChange = commonlib.gettable("Mod.WorldShare.login.VersionChange")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")
NPL.load("(gl)Mod/WorldShare/login/DeleteWorld.lua")

local DeleteWorld = commonlib.gettable("Mod.WorldShare.login.DeleteWorld")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")

local VersionChange = commonlib.gettable("Mod.WorldShare.login.VersionChange")

function VersionChange:init()
    self.foldername = GlobalStore.get("foldername")

    LoginMain.showMessageInfo(L "请稍后...")
    self:GetVersionSource(
        function()
            echo(self.allRevision, true)
            LoginMain.closeMessageInfo()
            self:ShowPage()
        end
    )
end

function VersionChange:SetPage()
    VersionChange.VersionPage = document:GetPageCtrl()
end

function VersionChange:ClosePage()
    if (VersionChange.VersionPage) then
        VersionChange.VersionPage:CloseWindow()
    end
end

function VersionChange:ShowPage()
    Utils:ShowWindow(300, 400, "Mod/WorldShare/login/VersionChange.html", "VersionChange")
end

function VersionChange:GetVersionSource(callback)
    self.allRevision = commonlib.vector:new()

    local function GetAllRevision(projectId)
        GitService:new():getCommits(
            projectId,
            nil,
            true,
            function(data, err)
                for key, item in ipairs(data) do
                    local path = item.title:gsub("keepwork commit: ", "")

                    if (path == "revision.xml") then
                        local currentRevision = {
                            path = path,
                            commitId = item.id
                        }

                        self.allRevision:push_back(currentRevision)
                    end
                end

                self:GetRevisionContent(callback)
            end
        )
    end

    GitService:new():getProjectIdByName(
        self.foldername.base32,
        function(projectId)
            if (not projectId) then
                return false
            end

            GetAllRevision(projectId)
        end
    )
end

local index = 1
function VersionChange:GetRevisionContent(callback)
    if (index > #self.allRevision) then
        index = 1

        if (type(callback) == "function") then
            callback()
        end
        -- self:FilterSameVersion(callback)
        return false
    end

    local currentItem = self.allRevision[index]

    GitService:new():getContentWithRaw(
        self.foldername.base32,
        currentItem.path,
        currentItem.commitId,
        function(content)
            if (not content) then
                return false
            end

            currentItem.revision = content
            index = index + 1
            self:GetRevisionContent(callback)
        end
    )
end

function VersionChange:GetAllRevision()
    return self.allRevision
end

function VersionChange:SelectVersion(index)
    GlobalStore.set("commitId", self.allRevision[index]["commitId"])
    self:ClosePage()
    DeleteWorld.DeleteLocal(
        function()
            SyncMain:syncToLocal()
        end
    )
end

-- function VersionChange:FilterSameVersion(callback)
--     echo(self.allRevision, true)
-- end

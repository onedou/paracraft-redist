--[[
Title: KeepworkService World
Author(s):  big
Date:  2019.12.9
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
------------------------------------------------------------
]]

local KeepworkService = NPL.load('../KeepworkService.lua')
local KeepworkWorldsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Worlds.lua")
local KeepworkProjectsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Projects.lua")
local KeepworkWorldLocksApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/WorldLocks.lua")

local KeepworkServiceWorld = NPL.export()

KeepworkServiceWorld.lockHeartbeat = false

-- get world list
function KeepworkServiceWorld:GetWorldsList(callback)
    if not KeepworkService:IsSignedIn() then
        return false
    end

    KeepworkWorldsApi:GetWorldList(callback)
end

-- get world by worldname
function KeepworkServiceWorld:GetWorld(foldername, callback)
    if type(foldername) ~= 'string' or not KeepworkService:IsSignedIn() then
        return false
    end

    KeepworkWorldsApi:GetWorldByName(foldername, function(data, err)
        if type(callback) ~= 'function' or not data or not data[1] then
            return false
        end

        callback(data[1])
    end)
end

-- updat world info
function KeepworkServiceWorld:PushWorld(params, callback)
    if type(params) ~= 'table' or
       not params.worldName or
       not KeepworkService:IsSignedIn() then
        return false
    end

    self:GetWorld(
        params.worldName or '',
        function(world)
            local worldId = world and world.id or false

            if not worldId then
                return false
            end

            KeepworkWorldsApi:UpdateWorldinfo(worldId, params, callback)
        end
    )
end

-- get world by project id
function KeepworkServiceWorld:GetWorldByProjectId(kpProjectId, callback)
    if type(kpProjectId) ~= 'number' or kpProjectId == 0 then
        return false
    end

    KeepworkProjectsApi:GetProject(kpProjectId, function(data, err)
        if type(callback) ~= 'function' then
            return false
        end

        if err ~= 200 or not data or not data.world then
            callback(nil, err)
            return false
        end

        callback(data.world, err)
    end)
end

-- update project lock info
function KeepworkServiceWorld:UpdateLock(pid, mode, revision, callback)
    KeepworkWorldLocksApi:UpdateWorldLockRecord(
        pid,
        mode,
        revision,
        function(data, err)
            echo(data, true)
            if type(callback) == 'function' then
                callback(true)
            end
        end,
        function()
            if type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

function KeepworkServiceWorld:UpdateLockHeartbeatStart(pid, mode, revision)
    if self.lockHeartbeat then
        return false
    end

    self.lockHeartbeat = true

    local function Heartbeat()
        self:UpdateLock(pid, mode, revision)
        Mod.WorldShare.Utils.SetTimeOut(function()
            if self.lockHeartbeat then
                Heartbeat()
            end
        end, 120 * 1000)
    end

    Heartbeat()
end

function KeepworkServiceWorld:UpdateLockHeartbeatStop()
    self.lockHeartbeat = false
end

function KeepworkServiceWorld:MergeRemoteWorldList(localWorlds, callback)
    if type(callback) ~= 'function' then
        return false
    end

    localWorlds = localWorlds or {}

    self:GetWorldsList(function(data, err)
        if type(data) ~= "table" then
            return false
        end

        local remoteWorldsList = data
        local currentWorldList = commonlib.vector:new()
        local currentWorld

        -- handle both/network newest/local newest/network only worlds
        for DKey, DItem in ipairs(remoteWorldsList) do
            local isExist = false
            local worldpath = ""
            local localTagname = ""
            local remoteTagname = ""
            local revision = 0
            local commitId = ""
            local status

            for LKey, LItem in ipairs(localWorlds) do
                if DItem["worldName"] == LItem["foldername"] and not LItem.is_zip then
                    if tonumber(LItem["revision"] or 0) == tonumber(DItem["revision"] or 0) then
                        status = 3 -- both
                        revision = LItem['revision']
                    elseif tonumber(LItem["revision"] or 0) > tonumber(DItem["revision"] or 0) then
                        status = 4 -- network newest
                        revision = DItem['revision'] -- use remote revision beacause remote is newest
                    elseif tonumber(LItem["revision"] or 0) < tonumber(DItem["revision"] or 0) then
                        status = 5 -- local newest
                        revision = LItem['revision'] or 0
                    end

                    isExist = true
                    worldpath = LItem["worldpath"]

                    localTagname = LItem["local_tagname"] or LItem["foldername"]
                    remoteTagname = DItem["extra"] and DItem["extra"]["worldTagName"] or DItem["worldName"]

                    if tonumber(LItem["kpProjectId"]) ~= tonumber(DItem["projectId"]) then
                        local tag = SaveWorldHandler:new():Init(worldpath):LoadWorldInfo()

                        tag.kpProjectId = DItem['projectId']
                        LocalService:SetTag(worldpath, tag)
                    end

                    break
                end
            end

            local text = DItem["worldName"] or ""

            if not isExist then
                --network only
                status = 2
                revision = DItem['revision']
                remoteTagname = DItem['extra'] and DItem['extra']['worldTagName'] or text

                if remoteTagname ~= "" and text ~= remoteTagname then
                    text = remoteTagname .. '(' .. text .. ')'
                end
            end

            currentWorld = {
                text = text,
                foldername = DItem["worldName"],
                revision = revision,
                size = DItem["fileSize"],
                modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(DItem["updatedAt"]),
                lastCommitId = DItem["commitId"], 
                worldpath = worldpath,
                status = status,
                project = DItem["project"] or {},
                user = DItem["user"] or {},
                kpProjectId = DItem["projectId"],
                local_tagname = localTagname,
                remote_tagname = remoteTagname,
                is_zip = false,
            }

            currentWorldList:push_back(currentWorld)
        end

        -- handle local only world
        for LKey, LItem in ipairs(localWorlds) do
            local isExist = false

            for DKey, DItem in ipairs(remoteWorldsList) do
                if LItem["foldername"] == DItem["worldName"] and not LItem.is_zip then
                    isExist = true
                    break
                end
            end

            if not isExist then
                currentWorld = LItem
                currentWorld.modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(currentWorld.writedate)
                currentWorld.text = currentWorld.foldername
                currentWorld.local_tagname = LItem['local_tagname']
                currentWorld.status = 1 --local only
                currentWorld.is_zip = LItem['is_zip'] or false

                currentWorldList:push_back(currentWorld)
            end
        end

        callback(currentWorldList)
    end)
end
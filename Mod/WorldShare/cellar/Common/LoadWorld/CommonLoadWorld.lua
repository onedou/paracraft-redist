--[[
Title: Common Load World
Author(s): big
Date: 2021.1.20
City: Foshan
use the lib:
------------------------------------------------------------
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')
------------------------------------------------------------
]]

-- libs
local DownloadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.DownloadWorld')
local RemoteWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteWorld')
local InternetLoadWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.InternetLoadWorld')

-- service
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')

-- databse
local CacheProjectId = NPL.load('(gl)Mod/WorldShare/database/CacheProjectId.lua')

local CommonLoadWorld = NPL.export()

function CommonLoadWorld:EnterWorldById(pid, refreshMode, failed)
    if not pid then
        return false
    end

    pid = tonumber(pid)

    local world
    local overtimeEnter = false
    local fetchSuccess = false

    local function HandleLoadWorld(url, worldInfo, offlineMode)
        if not url then
            return false
        end
        
        if overtimeEnter and Mod.WorldShare.Store:Get('world/isEnterWorld') then
            return false
        end

        local function LoadWorld(world, refreshMode)
            if world then
                if refreshMode == 'never' then
                    if not LocalService:IsFileExistInZip(world:GetLocalFileName(), ":worldconfig.txt") then
                        refreshMode = 'force'
                    end
                end

                local url = world:GetLocalFileName()
                DownloadWorld.ShowPage(url)
                local mytimer = commonlib.Timer:new(
                    {
                        callbackFunc = function(timer)
                            InternetLoadWorld.LoadWorld(
                                world,
                                nil,
                                refreshMode or "auto",
                                function(bSucceed, localWorldPath)
                                    DownloadWorld.Close()
                                end
                            )
                        end
                    }
                );

                -- prevent recursive calls.
                mytimer:Change(1,nil);
            else
                _guihelper.MessageBox(L"无效的世界文件");
            end
        end

        if url:match("^https?://") then
            world = RemoteWorld.LoadFromHref(url, "self")
            world:SetProjectId(pid)
            local token = Mod.WorldShare.Store:Get("user/token")
            if token then
                world:SetHttpHeaders({Authorization = format("Bearer %s", token)})
            end

            local fileUrl = world:GetLocalFileName()

            -- set remote world value here bacause local path
            Mod.WorldShare.Store:Set('world/currentRemoteWorld', world)

            if ParaIO.DoesFileExist(fileUrl) then
                if offlineMode then
                    LoadWorld(world, "never")
                    return false
                end

                Mod.WorldShare.MsgBox:Show(L"请稍候...")
                GitService:GetWorldRevision(pid, false, function(data, err)
                    local localRevision = tonumber(LocalService:GetZipRevision(fileUrl)) or 0
                    local remoteRevision = tonumber(data) or 0

                    Mod.WorldShare.MsgBox:Close()

                    if localRevision == 0 then
                        LoadWorld(world, "auto")

                        return false
                    end

                    if localRevision == remoteRevision then
                        LoadWorld(world, "never")

                        return false
                    end

					if refreshMode == "force" then
						LoadWorld(world, refreshMode);
						return false;
					end

                    local worldName = ''

                    if worldInfo and worldInfo.extra and worldInfo.extra.worldTagName then
                        worldName = worldInfo.extra.worldTagName
                    else
                        worldName = worldInfo.worldName
                    end

                    local params = Mod.WorldShare.Utils.ShowWindow(
                        0,
                        0,
                        "Mod/WorldShare/cellar/UserConsole/ProjectIdEnter.html?project_id=" 
                            .. pid
                            .. "&remote_revision=" .. remoteRevision
                            .. "&local_revision=" .. localRevision
                            .. "&world_name=" .. worldName,
                        "ProjectIdEnter",
                        0,
                        0,
                        "_fi",
                        false
                    )

                    params._page.callback = function(data)
                        if data == 'local' then
                            LoadWorld(world, "never")
                        elseif data == 'remote' then
                            LoadWorld(world, "force")
                        end
                    end
                end)
            else
                LoadWorld(world, "auto")
            end
        end
	end

    -- show view over 5 seconds
    Mod.WorldShare.Utils.SetTimeOut(function()
        if fetchSuccess then
            return false
        end

        Mod.WorldShare.Store:Set('world/openKpProjectId', pid)

        local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

        if not cacheWorldInfo or not cacheWorldInfo.worldInfo or not cacheWorldInfo.worldInfo.archiveUrl then
            return false
        end

        local worldInfo = cacheWorldInfo.worldInfo
        local url = cacheWorldInfo.worldInfo.archiveUrl
        local world = RemoteWorld.LoadFromHref(url, "self")
        world:SetProjectId(pid)
        local fileUrl = world:GetLocalFileName()   
        local localRevision = tonumber(LocalService:GetZipRevision(fileUrl)) or 0
        
        -- set remote world value here bacause local path
        Mod.WorldShare.Store:Set('world/currentRemoteWorld', world)

        local worldName = ''

        if worldInfo and worldInfo.extra and worldInfo.extra.worldTagName then
            worldName = worldInfo.extra.worldTagName
        else
            worldName = worldInfo.worldName
        end

        local function LoadWorld(world, refreshMode)
            if world then
                local url = world:GetLocalFileName()
                DownloadWorld.ShowPage(url)

                local mytimer = commonlib.Timer:new(
                    {
                        callbackFunc = function(timer)
                            InternetLoadWorld.LoadWorld(
                                world,
                                nil,
                                refreshMode or "auto",
                                function(bSucceed, localWorldPath)
                                    DownloadWorld.Close()
                                    return true
                                end
                            )
                        end
                    }
                );

                -- prevent recursive calls.
                mytimer:Change(1,nil);
            else
                _guihelper.MessageBox(L"无效的世界文件")
            end
        end

        local params = Mod.WorldShare.Utils.ShowWindow(
            0,
            0,
            "Mod/WorldShare/cellar/UserConsole/ProjectIdEnter.html?project_id=" 
                .. pid
                .. "&remote_revision=" .. 0
                .. "&local_revision=" .. localRevision
                .. "&world_name=" .. worldName,
            "ProjectIdEnter",
            0,
            0,
            "_fi",
            false
        )

        params._page.callback = function(data)
            if data == 'local' then
                overtimeEnter = true
                LoadWorld(world, "never")
            end
        end
    end, 5000)

    Mod.WorldShare.MsgBox:Show(L"请稍候...", 20000)
    KeepworkServiceProject:GetProject(
        pid,
        function(data, err)
            Mod.WorldShare.MsgBox:Close()
            fetchSuccess = true

            if err == 0 then
                local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

                if not cacheWorldInfo or not cacheWorldInfo.worldInfo then
                    GameLogic.AddBBS(nil, L"网络环境差，或离线中，请联网后再试", 3000, "255 0 0")
                    return false
                end

                Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                HandleLoadWorld(cacheWorldInfo.worldInfo.archiveUrl, cacheWorldInfo.worldInfo, true)

                return false
            end

            if err == 404 then
                GameLogic.AddBBS(nil, L"未找到对应内容", 3000, "255 0 0")

                if failed then
                    _guihelper.MessageBox(
                        L'未能成功进入该地图，将帮您传送到【创意空间】。 ',
                        function()
                            local mainWorldProjectId = LocalServiceWorld:GetMainWorldProjectId()
                            self:EnterWorldById(mainWorldProjectId, true)
                        end,
                        _guihelper.MessageBoxButtons.OK_CustomLabel
                    )
                end
                return false
            end

            if err ~= 200 then
                GameLogic.AddBBS(nil, L"服务器维护中...", 3000, "255 0 0")
                return
            end

            if data and data.visibility == 1 then
                if not KeepworkService:IsSignedIn() then
                    LoginModal:CheckSignedIn(L"该项目需要登录后访问", function(bIsSuccessed)
                        if bIsSuccessed then
                            self:EnterWorldById(pid, refreshMode)
                        end
                    end)
                    return false
                else
                    KeepworkServiceProject:GetMembers(pid, function(members, err)
                        if type(members) ~= 'table' then
                            return false
                        end

                        local username = Mod.WorldShare.Store:Get("user/username")
                        
                        for key, item in ipairs(members) do
                            if item and item.username and item.username == username then
                                if not data.world or not data.world.archiveUrl then
                                    return false
                                end

                                Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                                HandleLoadWorld(data.world.archiveUrl .. "&private=true", data.world)
                                return true
                            end
                        end

                        GameLogic.AddBBS(nil, L"您未获得该项目的访问权限", 3000, "255 0 0")
                        return false
                    end)
                end
            else
                -- vip enter
                if data and data.extra and data.extra.vipEnabled == 1 or data.extra.institudeEnabled == 1 then
                    if not KeepworkService:IsSignedIn() then
                        LoginModal:CheckSignedIn(L"该项目需要登录后访问", function(bIsSuccessed)
                            if bIsSuccessed then
                                self:EnterWorldById(pid, refreshMode)
                            end
                        end)
                        return false
                    end
    
                    local userType = Mod.WorldShare.Store:Get("user/userType")
                    local username = Mod.WorldShare.Store:Get("user/username")
                    local isVip = Mod.WorldShare.Store:Get("user/isVip")

                    local canEnter = false

                    if data.username and data.username == username then
                        canEnter = true
                    end

                    if data.extra.vipEnabled == 1 then
                        if isVip then
                            canEnter = true
                        end
                    end

                    if data.extra.institudeEnabled == 1 then
                        if userType.student then
                            canEnter = true
                        end
                    end

                    if not canEnter then
                        _guihelper.MessageBox(L"你没有权限进入此世界")
                        return false
                    end
                end

                if data.world and data.world.archiveUrl and #data.world.archiveUrl > 0 then
                    Mod.WorldShare.Store:Set('world/openKpProjectId', pid)
                    HandleLoadWorld(data.world.archiveUrl, data.world)
                    CacheProjectId:SetProjectIdInfo(pid, data.world)
                else
                    GameLogic.AddBBS(nil, L"未找到对应内容", 3000, "255 0 0")
                    
                    if failed then
                        _guihelper.MessageBox(
                            L'未能成功进入该地图，将帮您传送到【创意空间】。 ',
                            function()
                                local mainWorldProjectId = LocalServiceWorld:GetMainWorldProjectId()
                                self:EnterWorldById(mainWorldProjectId, true)
                            end,
                            _guihelper.MessageBoxButtons.OK_CustomLabel
                        )
                    end
                end
            end
        end
    )
end
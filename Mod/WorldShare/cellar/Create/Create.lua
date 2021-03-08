--[[
Title: Create Page
Author(s):  Big
Date: 2020.9.1
Desc: 
use the lib:
------------------------------------------------------------
local Create = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/Create/Create.lua')
------------------------------------------------------------
]]

-- libs
local InternetLoadWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.InternetLoadWorld')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local VipTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/VipTypeWorld.lua')
local ShareTypeWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/ShareTypeWorld.lua')
local SyncMain = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Main.lua')

-- service
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local Create = NPL.export()

Create.currentMenuSelectIndex = 1

function Create:Show()
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if CreatePage then
        self:GetWorldList()
        return true
    end

    Create.currentMenuSelectIndex = 1

    Mod.WorldShare.Utils.ShowWindow(920, 530, '(ws)Create/Create.html', 'Mod.WorldShare.Create')

    self:GetWorldList()
end

function Create:Close()
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if not CreatePage then
        return
    end

    CreatePage:CloseWindow()
end 

function Create:OnSwitchWorld(index)
    if not index then
        return false
    end

    InternetLoadWorld.OnSwitchWorld(index)
    self:UpdateWorldInfo(index)
end

function Create:UpdateWorldInfo(worldIndex)
    local currentSelectedWorld = Compare:GetSelectedWorld(worldIndex)

    if not currentSelectedWorld  then
        return false
    end

    if currentSelectedWorld.status ~= 2 then
        local compareWorldList = Mod.WorldShare.Store:Get('world/compareWorldList')
    
        if not currentSelectedWorld.is_zip then
            local filesize = LocalService:GetWorldSize(currentSelectedWorld.worldpath)
            local worldTag = LocalService:GetTag(currentSelectedWorld.worldpath)
    
            worldTag.size = filesize
            LocalService:SetTag(currentSelectedWorld.worldpath, worldTag)
    
            compareWorldList[worldIndex].size = filesize
        else
            compareWorldList[worldIndex].revision = LocalService:GetZipRevision(currentSelectedWorld.worldpath)
            compareWorldList[worldIndex].size = LocalService:GetZipWorldSize(currentSelectedWorld.worldpath)
        end

        Mod.WorldShare.Store:Set('world/compareWorldList', compareWorldList)
    end

    Mod.WorldShare.Store:Set('world/currentWorld', currentSelectedWorld)

    self.worldIndex = worldIndex

    self:Refresh(0.01)
end

function Create:Refresh()
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if not CreatePage then
        return false
    end

    CreatePage:Refresh(0.01)
end

function Create:IsRefreshing()
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if CreatePage and CreatePage.refreshing then
        return true
    else
        return false
    end
end

function Create:SetRefreshing(status)
    local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

    if not CreatePage then
        return false
    end

    CreatePage.refreshing = status and true or false
    CreatePage:Refresh(0.01)
end

function Create:Sync()
    if not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"请稍候...")

    Compare:Init(function(result)
        Mod.WorldShare.MsgBox:Close()

        if not result then
            GameLogic.AddBBS(nil, L"版本号对比失败", 3000, "255 0 0")
            return false
        end

        if result == Compare.JUSTLOCAL then
            SyncMain:SyncToDataSource(function()
                self:GetWorldList()
            end)
        end

        if result == Compare.JUSTREMOTE then
            SyncMain:SyncToLocal(function()
                self:GetWorldList()
            end)
        end

        if result == Compare.REMOTEBIGGER or
           result == Compare.LOCALBIGGER or
           result == Compare.EQUAL then
            SyncMain:ShowStartSyncPage(nil, function()
                self:GetWorldList()
            end)
        end

        Mod.WorldShare.MsgBox:Close()
    end)
end

function Create:GetWorldList(statusFilter, callback)
    self:SetRefreshing(true)

    Compare:RefreshWorldList(function(currentWorldList)
        self:SetRefreshing(false)

        local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

        if CreatePage then
            CreatePage:GetNode('gw_world_ds'):SetAttribute('DataSource', currentWorldList or {})
            self:OnSwitchWorld(1)

            if callback and type(callback) == 'function' then
                callback()
            end
        end
    end, statusFilter)
end

function Create:EnterWorld(index, allowOffline)
    local currentSelectedWorld = Compare:GetSelectedWorld(index)

    if not currentSelectedWorld or type(currentSelectedWorld) ~= 'table' then
        return
    end

    -- check world
    if currentSelectedWorld.status ~= 2 then
        if not LocalServiceWorld:CheckWorldIsCorrect(currentSelectedWorld) then
            _guihelper.MessageBox(L'文件损坏，请再试一次。如果还是出现问题，请联系作者或者管理员。')
            return
        end
    end

    -- vip world step
    if VipTypeWorld:IsVipWorld(currentSelectedWorld) then
        local isSignedIn = LoginModal:CheckSignedIn(L'此世界为VIP世界，需要登陆后才能继续', function(bIsSuccessed)
            if bIsSuccessed then
                self:GetWorldList(nil, function()
                    local index = Compare:GetWorldIndexByFoldername(
                        currentSelectedWorld.foldername,
                        currentSelectedWorld.shared,
                        currentSelectedWorld.is_zip
                    )
                    self:EnterWorld(index)
                end)
            end
        end)

        if not isSignedIn then
            return
        else
            if not VipTypeWorld:CheckVipWorld(currentSelectedWorld) then
                return
            end
        end
    end

    -- share world step
    if ShareTypeWorld:IsSharedWorld(currentSelectedWorld) and not allowOffline then
        if not LoginModal:CheckSignedIn(L'此世界为多人世界，请先登录', function(bIsSuccessed)
            if bIsSuccessed then
                self:GetWorldList(nil, function()
                    local index = Compare:GetWorldIndexByFoldername(
                        currentSelectedWorld.foldername,
                        currentSelectedWorld.shared,
                        currentSelectedWorld.is_zip
                    )
                    self:EnterWorld(index)
                end)
            else
                Mod.WorldShare.MsgBox:Dialog(
                    'MultiPlayerWorldLogin',
                    L'此世界为多人世界，请登录后再打开世界，或者以只读模式打开世界',
                    {
                        Title = L'多人世界',
                        Yes = L'知道了',
                        No = L'只读模式打开'
                    },
                    function(res)
                        if res and res == _guihelper.DialogResult.No then
                            self:EnterWorld(index, true)
                        end
                    end,
                    _guihelper.MessageBoxButtons.YesNo
                )
            end
        end) then
            return
        end
    end

    -- uploaded step
    if currentSelectedWorld.kpProjectId and
       not KeepworkServiceSession:IsSignedIn() and
       not allowOffline then
        if not LoginModal:CheckSignedIn(L'请先登录', function(result)
            if result then
                if result == 'THIRD' then
                    return function()
                        self:GetWorldList(nil, function()
                            local index = Compare:GetWorldIndexByFoldername(
                                currentSelectedWorld.foldername,
                                currentSelectedWorld.shared,
                                currentSelectedWorld.is_zip
                            )
                            self:EnterWorld(index)
                        end)
                    end
                end

                -- refresh world list after login
                self:GetWorldList(nil, function()
                    local index = Compare:GetWorldIndexByFoldername(
                        currentSelectedWorld.foldername,
                        currentSelectedWorld.shared,
                        currentSelectedWorld.is_zip
                    )
                    self:EnterWorld(index)
                end)
            else
                self:EnterWorld(index, true)
            end
        end) then
            return
        end
    end

    -- set current world
    self:OnSwitchWorld(index)
    self:Close()

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if currentWorld.status == 2 then
        Mod.WorldShare.MsgBox:Show(L"请稍候...")

        Compare:Init(function(result)
            Mod.WorldShare.MsgBox:Close()

            if result ~= Compare.JUSTREMOTE then
                return false
            end

            SyncToLocal:Init(function(result, option)
                if not result then
                    if type(option) == 'string' then
                        if option == 'NEWWORLD' then
                            GameLogic.AddBBS(nil, L'服务器未找到您的世界数据，请新建', 3000, "255 255 0")

                            self:Close()
                            CreateWorld:CreateNewWorld(currentWorld.foldername)
                        end

                        return
                    end

                    if type(option) == 'table' then
                        if option.method == 'UPDATE-PROGRESS-FINISH' then
                            if not LocalServiceWorld:CheckWorldIsCorrect(world) then
                                _guihelper.MessageBox(L'文件损坏，请再试一次。如果还是出现问题，请联系作者或者管理员。')
                                return false
                            end

                            if ShareTypeWorld:IsSharedWorld(currentWorld) then
                                ShareTypeWorld:Lock(currentWorld, function()
                                    InternetLoadWorld.EnterWorld()
                                end)
                            else
                                InternetLoadWorld.EnterWorld()
                            end
                        end
                    end
                end
            end)
        end)
    else
        if currentWorld.status == 1 then
            InternetLoadWorld.EnterWorld()
            return
        end

        Mod.WorldShare.MsgBox:Show(L'请稍候...')
        Compare:Init(function(result)
            Mod.WorldShare.MsgBox:Close()

            if ShareTypeWorld:IsSharedWorld(currentWorld) then
                ShareTypeWorld:CompareVersion(result, function(result)
                    if result == 'SYNC' then
                        SyncMain:BackupWorld()

                        Mod.WorldShare.MsgBox:Show(L'请稍候...')

                        SyncMain:SyncToLocalSingle(function(result, option)
                            Mod.WorldShare.MsgBox:Close()

                            if result == true then
                                InternetLoadWorld.EnterWorld()	
                            end
                        end)
                    else
                        InternetLoadWorld.EnterWorld()	
                    end
                end)
            else
                if result == Compare.REMOTEBIGGER then
                    SyncMain:ShowStartSyncPage(true)
                else
                    InternetLoadWorld.EnterWorld()	
                end
            end
        end)
    end
end

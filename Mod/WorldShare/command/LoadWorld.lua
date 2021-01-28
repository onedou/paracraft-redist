--[[
Title: load world command
Author(s): big
Date: 2020.10.9
Desc: 
use the lib:
------------------------------------------------------------
local LoadWorldCommand = NPL.load('(gl)Mod/WorldShare/command/LoadWorld.lua')
-------------------------------------------------------
]]

-- bottles
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')

-- service
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')

-- libs
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')

-- command
local WorldShareCommand = NPL.load('(gl)Mod/WorldShare/command/Command.lua')

local LoadWorldCommand = NPL.export()

function LoadWorldCommand:Init()
    -- cmd load world
    GameLogic.GetFilters():add_filter(
        "cmd_loadworld", 
        function(cmd_text, options)
            if options and options.fork then
                self:Fork(cmd_text, options)
                return false
            end

            if options and not options.s then
                if cmd_text:match("^https?://") then
                    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                    if currentEnterWorld then
                        _guihelper.MessageBox(
                            format(L"即将离开【%s】", currentEnterWorld.text),
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    local optionsStr = ''
        
                                    for key, item in pairs(options) do
                                        if key ~= 's' then
                                            optionsStr = optionsStr .. '-' .. key .. ' '
                                        end
                                    end
        
                                    CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                                end
                            end,
                            _guihelper.MessageBoxButtons.YesNo
                        )
                    else
                        local optionsStr = ''
        
                        for key, item in pairs(options) do
                            if key ~= 's' then
                                optionsStr = optionsStr .. '-' .. key .. ' '
                            end
                        end

                        CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                    end

                    return false
                end

                if cmd_text == 'home' then
                    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                    if currentEnterWorld then
                        _guihelper.MessageBox(
                            format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, L'家园'),
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    local optionsStr = ''
        
                                    for key, item in pairs(options) do
                                        if key ~= 's' then
                                            optionsStr = optionsStr .. '-' .. key .. ' '
                                        end
                                    end
        
                                    CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                                end
                            end,
                            _guihelper.MessageBoxButtons.YesNo
                        )
                    else
                        CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                    end

                    return false
                end

                local pid = string.match(cmd_text, '(%d+)')
                if pid then
                    Mod.WorldShare.MsgBox:Show(L"请稍候...")
                    KeepworkServiceProject:GetProject(pid, function(data, err)
                        Mod.WorldShare.MsgBox:Close()
                        if err ~= 200 or not data or type(data) ~='table' or not data.name then
                            GameLogic.AddBBS(nil, L"加载世界失败，无法在服务器找到该资源", 3000, '255 0 0')
                            return
                        end

                        local optionsStr = ''

                        for key, item in pairs(options) do
                            if key ~= 's' then
                                optionsStr = optionsStr .. '-' .. key .. ' '
                            end
                        end

                        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                        if currentEnterWorld then
                            _guihelper.MessageBox(
                                format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, data.name),
                                function(res)
                                    if res and res == _guihelper.DialogResult.Yes then
                                        CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                                    end
                                end,
                                _guihelper.MessageBoxButtons.YesNo
                            )
                        else
                            CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                        end
                    end)
                end

                return false
            end

            if cmd_text == 'home' then
                return cmd_text
            end

            if cmd_text:match("^https?://") then
                return cmd_text
            end

            if options and options.personal then
                CommandManager:RunCommand("/loadpersonalworld " .. cmd_text)
                return false
            end

            local pid = string.match(cmd_text, '(%d+)')

            if not pid then
                return false
            end

            if options and options.inplace then
                local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                local command = string.match(cmd_text, "|[ ]+(%/[%w]+)[ ]+")
                if command == '/sendevent' then
                    local execCommand = string.match(cmd_text, "|[ ]+(%/[%w]+[ ]+[ {}=_\",%w]+)$")
                    local event = string.match(cmd_text, "|[ ]+%/[%w]+[ ]+([%w]+)")

                    if currentEnterWorld and
                       type(currentEnterWorld) == 'table' and
                       currentEnterWorld.kpProjectId and
                       tonumber(pid) == tonumber(currentEnterWorld.kpProjectId) then
                        if string.match(event, '^global') then
                            GameLogic.RunCommand(execCommand or '')
                        end
                    else
                        if string.match(event, '^global') then
                            WorldShareCommand:PushAfterLoadWorldCommand(execCommand or '')
                        end

                        if options and options.force then
                            CommandManager:RunCommand('/loadworld -s -force ' .. pid)
                        else
                            CommandManager:RunCommand('/loadworld -s ' .. pid)
                        end
                    end
                end
                return false
            end

            local refreshMode = nil
            local failed = nil

            if options and options.force then
                refreshMode = 'force'
            end

            if options and options.failed then
                failed = true
            end

            -- enter read only world
            CommonLoadWorld:EnterWorldById(pid, refreshMode, failed)

            return false
        end
    )
end

function LoadWorldCommand:Fork(cmdText, options)
    local projectId, worldName = string.match(cmdText, "^(%w+)[ ]+(.+)$")

    if not projectId or not worldName or type(tonumber(projectId)) ~= 'number' then
        return
    end

    projectId = tonumber(projectId)

    local worldPath = 'worlds/DesignHouse/' .. commonlib.Encoding.Utf8ToDefault(worldName)
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if ParaIO.DoesFileExist(worldPath .. '/tag.xml', false) then
        local tag = LocalService:GetTag(worldPath)

        if not tag or type(tag) ~= 'table' or not tag.name then
            return
        end

        if options.s then
            WorldCommon.OpenWorld(worldPath, true)
        else
            _guihelper.MessageBox(
                format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, tag.name),
                function(res)
                    if res and res == _guihelper.DialogResult.Yes then
                        WorldCommon.OpenWorld(worldPath, true)
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
        end

        return
    end

    Mod.WorldShare.MsgBox:Show(L"请稍候...")

    KeepworkServiceProject:GetProject(projectId, function(data, err)
        if not data or
           type(data) ~= 'table' or
           not data.name or
           not data.username or
           not data.world or
           not data.world.commitId then
            return
        end

        GitService:DownloadZIP(
            data.name,
            data.username,
            data.world.commitId,
            function(bSuccess, downloadPath)
                LocalService:MoveZipToFolder(worldPath, downloadPath)

                local tag = LocalService:GetTag(worldPath)
                
                if not tag and type(tag) ~= 'table' then
                    return
                end

                tag.fromProjects = tag.kpProjectId
                tag.kpProjectId = nil

                LocalService:SetTag(worldPath, tag)

                Mod.WorldShare.MsgBox:Close()

                if options.s then
                    WorldCommon.OpenWorld(worldPath, true)
                else
                    _guihelper.MessageBox(
                        format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, data.name),
                        function(res)
                            if res and res == _guihelper.DialogResult.Yes then
                                WorldCommon.OpenWorld(worldPath, true)
                            end
                        end,
                        _guihelper.MessageBoxButtons.YesNo
                    )
                end
            end
        )
    end)
end

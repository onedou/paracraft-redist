--[[
Title: Explorer App
Author(s):  Big
Date: 2019.01.18
Desc: This is explorer app
Place: Foshan
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ExplorerApp/main.lua")
local ExplorerApp = commonlib.gettable("Mod.ExplorerApp")
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Task.lua")
NPL.load("(gl)Mod/ExplorerApp/store/ExplorerStore.lua")
NPL.load("(gl)Mod/ExplorerApp/tasks/ExplorerTask.lua")
NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua")
NPL.load("(gl)script/ide/System/Core/UniString.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Translation.lua")

-- task
local ExplorerTask = commonlib.gettable("Mod.ExplorerApp.tasks.ExplorerTask")

-- store
local ExplorerStore = commonlib.gettable('Mod.ExplorerApp.store.Explorer')

-- components
local MainPage = NPL.load("(gl)Mod/ExplorerApp/components/MainPage.lua")
local GameOver = NPL.load("(gl)Mod/ExplorerApp/components/GameProcess/GameOver/GameOver.lua")

-- utils
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

-- filters
local Filters = NPL.load('(gl)Mod/ExplorerApp/filters/Filters.lua')

local ExplorerApp = commonlib.inherit(commonlib.gettable("Mod.ModBase"), commonlib.gettable("Mod.ExplorerApp"))

ExplorerApp:Property({"Name", "ExplorerApp", "GetName", "SetName", { auto = true }})
ExplorerApp:Property({"Desc", "This is explorer app", "GetDesc", "SetDesc", { auto = true }})
ExplorerApp.version = '0.0.5'

LOG.std(nil, "info", "ExplorerApp", "explorer app version %s", ExplorerApp.version)

function ExplorerApp:init()
    Filters:Init()
end

function ExplorerApp:Init(callback)
    if not Mod or not Mod.WorldShare then
        _guihelper.MessageBox(L"ExplorerApp 依赖 WorldShare Mod")
        return false
    end

    -- register explorer store to store list
    Mod.WorldShare.Store.storeList.explorer = ExplorerStore

    MainPage:ShowPage(callback)
end

function ExplorerApp:OnWorldLoad()
    local mode = Mod.WorldShare.Store:Get('explorer/mode')

    if not mode or mode ~= 'recommend' then
        return false
    end

    GameLogic.GetCodeGlobal():RegisterTextEvent("dead", function()
        GameOver:ShowPage()
    end)

    self.curTask = ExplorerTask:new()

    MainPage:OnWorldLoad()
end

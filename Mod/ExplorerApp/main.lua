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
NPL.load("(gl)Mod/ExplorerStore/store/ExplorerStore.lua")
NPL.load("(gl)Mod/ExplorerApp/tasks/ExplorerTask.lua")

local ExplorerTask = commonlib.gettable("Mod.ExplorerApp.tasks.ExplorerTask")
local ExplorerStore = commonlib.gettable('Mod.ExplorerApp.store.Explorer')

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MainPage = NPL.load("(gl)Mod/ExplorerApp/components/MainPage.lua")
local GameOver = NPL.load("(gl)Mod/ExplorerApp/components/GameProcess/GameOver/GameOver.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local ProactiveEnd = NPL.load("(gl)Mod/ExplorerApp/components/GameProcess/ProactiveEnd/ProactiveEnd.lua")

local ExplorerApp = commonlib.inherit(commonlib.gettable("Mod.ModBase"), commonlib.gettable("Mod.ExplorerApp"))


function ExplorerApp:GetName()
	return "ExplorerApp"
end

function ExplorerApp:GetDesc()
	return "This is explorer app"
end

function ExplorerApp:Init()
    Store.storeList.explorer = ExplorerStore

    MainPage:ShowPage()

    GameLogic.GetFilters():add_filter(
        "HanldeEscapeKey",
        function()
            ProactiveEnd:Toggle()
            return true
        end
    )
end

function ExplorerApp:OnLogin()
end

function ExplorerApp:OnWorldLoad()
    GameLogic.GetCodeGlobal():RegisterTextEvent("dead", function()
        GameOver:ShowPage()
    end)

    self.curTask = ExplorerTask:new()
end

function ExplorerApp:OnLeaveWorld()
end

function ExplorerApp:OnDestroy()
end

function ExplorerApp:handleKeyEvent(event)
end

function ExplorerApp:OnInitDesktop()
end

function ExplorerApp:OnActivateDesktop(mode)
end

function ExplorerApp:OnClickExitApp()
end

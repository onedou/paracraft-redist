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
NPL.load("(gl)Mod/ExplorerStore/store/ExplorerStore.lua")

local ExplorerStore = commonlib.gettable('Mod.ExplorerApp.store.Explorer')

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MainPage = NPL.load("(gl)Mod/ExplorerApp/components/MainPage.lua")

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
end

function ExplorerApp:OnLogin()
end

function ExplorerApp:OnWorldLoad()
end

function ExplorerApp:OnLeaveWorld()
end

function ExplorerApp:OnDestroy()
end

ExplorerApp.handleKeyEvent = ExplorerApp.HandleKeyEvent
function ExplorerApp:HandleKeyEvent(event)
end

function ExplorerApp:OnInitDesktop()
end

function ExplorerApp:OnActivateDesktop(mode)
end

function ExplorerApp:OnClickExitApp()
end

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
NPL.load("(gl)Mod/Test/DemoCommand.lua")
NPL.load("(gl)Mod/Test/DemoEntity.lua")
NPL.load("(gl)Mod/Test/DemoGUI.lua")
NPL.load("(gl)Mod/Test/DemoItem.lua")
NPL.load("(gl)Mod/Test/DemoSceneContext.lua")

local ExplorerApp = commonlib.inherit(commonlib.gettable("Mod.ModBase"), commonlib.gettable("Mod.ExplorerApp"))

function ExplorerApp:ctor()
end

function ExplorerApp:GetName()
	return "ExplorerApp"
end

function ExplorerApp:GetDesc()
	return "This is explorer app"
end

function ExplorerApp:init()
end

function ExplorerApp:OnLogin()
end

function ExplorerApp:OnWorldLoad()
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
	-- we will toggle our own UI here
	local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop")
	if (Desktop.mode) then
		GameLogic.AddBBS("test", "Test进入编辑模式", 4000, "0 255 0")
	else
		GameLogic.AddBBS("test", "Test进入游戏模式", 4000, "255 255 0")
	end
	-- return true to suppress default desktop interface.
	return true
end

function ExplorerApp:OnClickExitApp()
	_guihelper.MessageBox(
		"wanna exit?",
		function()
			ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true)
			ParaGlobal.ExitApp()
		end
	)
	return true
end

--[[
Title: Explorer Task
Author(s):  big
Date:  201
Place: Foshan
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ExplorerApp/tasks/ExplorerTask.lua")
local ExplorerTask = commonlib.gettable("Mod.ExplorerApp.tasks.ExplorerTask")
------------------------------------------------------------
]]
local ExplorerTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("Mod.ExplorerApp.tasks.ExplorerTask"))

-- handling key/mouse event
-- see: RedirectContext.lua for all key/mouse overridable events
function ExplorerTask:keyPressEvent(event)
	if(event:isAccepted()) then
		return
	end
	event:accept();
end

function ExplorerTask:HandleGlobalKey(event)
	if(event:isAccepted()) then
		return
	end
	event:accept()
end

function ExplorerTask:Run()
	self:LoadSceneContext();
	ExplorerTask._super.Run(self);
end

-- invoke task
-- local task = MyTask:new();
-- task:Run();
-- task:SetFinished();
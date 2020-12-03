--[[
Title: Beginner
Author(s):  big
Date: 2020.11.27
Desc: 
use the lib:
------------------------------------------------------------
local Beginner = NPL.load("(gl)Mod/WorldShare/cellar/Beginner/Beginner.lua")
------------------------------------------------------------
]]

-- libs
local KeepWorkItemManager = NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua')
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local Beginner = NPL.export()

Beginner.inited = false

function Beginner:Show(callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    if not self.inited and not KeepWorkItemManager.HasGSItem(60000) then
        _guihelper.MessageBox(
            L"是否进入新手教学？",
            function(res)
                if res and res == _guihelper.DialogResult.OK then
                    CommandManager:RunCommand('/loadworld -s 29477')
                    self.inited = true
                end

                if res and res == _guihelper.DialogResult.Cancel then
                    if callback and type(callback) == 'function' then
                        callback()
                    end
                end

                KeepWorkItemManager.DoExtendedCost(40000)
            end,
            _guihelper.MessageBoxButtons.OKCancel_CustomLabel
        )
    end
end

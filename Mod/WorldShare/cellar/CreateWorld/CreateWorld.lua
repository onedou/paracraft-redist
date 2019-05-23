--[[
Title: CreateWorld
Author(s):  big
Date: 2018.08.1
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
------------------------------------------------------------
]]
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")

local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local CreateWorld = NPL.export()

function CreateWorld:CreateNewWorld(foldername)
    if type(foldername) == 'string' then
        CreateNewWorld.LastWorldName = foldername
    end

    CreateNewWorld.ShowPage()
end

function CreateWorld.OnClickCreateWorld()
    Store:Remove("world/currentWorld")
end

function CreateWorld:CheckRevision(callback)
    if GameLogic.IsReadOnly() then
        return false
    end

    function Handle()
        if (not Compare:HasRevision()) then
            MsgBox:Show(L"正在初始化世界...")

            Utils.SetTimeOut(
                function()
                    self:CreateRevisionXml()

                    MsgBox:Close()

                    if (type(callback) == "function") then
                        callback()
                    end
                end,
                1000
            )

            MsgBox:Close()
        else

            if (type(callback) == "function") then
                callback()
            end
        end
    end

    SyncMain:GetCurrentWorldInfo(Handle)
end

function CreateWorld:CreateRevisionXml()
    local path = ParaWorld.GetWorldDirectory()
    local revisionPath = format("%srevision.xml", path)

    local exist = ParaIO.DoesFileExist(revisionPath)

    if not exist then
        local file = ParaIO.open(revisionPath, "w");
        file:WriteString("1")
        file:close();
    end
end
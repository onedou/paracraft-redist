--[[
Title: Socket API
Author(s):  big
Date:  2020.05.26
Place: Foshan
use the lib:
------------------------------------------------------------
local SocketApi = NPL.load("(gl)Mod/WorldShare/api/Socket/Socket.lua")
------------------------------------------------------------
]]

local SocketBaseApi = NPL.load("(gl)Mod/WorldShare/api/Socket/BaseApi.lua")

local SocketIOClient = NPL.load("(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua")

local SocketApi = NPL.export()

SocketApi.client = commonlib.gettable('Mod.WorldShare.api.Socket.SocketApi.client')


function SocketApi:Connect()
    if self.client.connection then
        return self.client.connection
    end

    self.client.connection = SocketIOClient:new();
    self.client.connection:Connect(SocketBaseApi:GetApi())

    if self.client.connection then
        return self.client.connection
    end
end

function SocketApi:SendMsg(url, params)
    if not self.client.connection or not self.client.connection.Send then
        return false
    end

    self.client.connection:Send(url, params)
end

function SocketApi:GetConnection()
    return self.client.connection
end
--[[
Title: Keepwork Service Paracraft Services
Author(s):  big
Date:  2018.06.21
Place: Foshan
use the lib:
------------------------------------------------------------
local ParacraftDevices = NPL.load("(gl)Mod/ExplorerApp/service/KeepworkService/ParacraftDevices.lua")
------------------------------------------------------------
]]
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')

local ParacraftDevices = NPL.export()

function ParacraftDevices:PwdVerfify(password, callback)
    if not password then
        return false
    end

    local params = {
        deviceId = ParaEngine.GetAttributeObject():GetField("MaxMacAddress",""),
        password = password
    }

    KeepworkService:Request(
        "/paracraftDevices/pwdVerify",
        "GET",
        params,
        headers,
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            if err ~= 200 or not data then
                callback()
                return false
            end

            callback(data, err)
        end
    )
end

function ParacraftDevices:Recharge(code, callback)
    if not code then
        return false
    end

    local params = {
        key = code
    }

    KeepworkService:Request(
        "/paracraftGameCoinKeys/active",
        "POST",
        params,
        headers,
        function(data, err)
            if type(callback) ~= 'function' then
                return false
            end

            callback(data, err)
        end,
        400
    )
end
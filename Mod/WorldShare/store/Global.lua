--[[
Title: Global
Author(s):  big
Date:  2018.6.20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
------------------------------------------------------------
]]
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")

function GlobalStore.set(key, value)
    GlobalStore[key] = value
end

function GlobalStore.get(key)
    return GlobalStore[key]
end

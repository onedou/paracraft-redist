--[[
Title: third party login
Author(s):  big
Date: 2020.06.01
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local ThirdPartyLogin = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/ThirdPartyLogin.lua")
ThirdPartyLogin:Init(url)
------------------------------------------------------------
]]



local ThirdPartyLogin = NPL.export()

function ThirdPartyLogin:Init(url)
    Mod.WorldShare.Utils.ShowWindow(380, 440, "Mod/WorldShare/cellar/LoginModal/ThirdPartyLogin.html", "ThirdPartyLogin", nil, nil, nil, nil)
end



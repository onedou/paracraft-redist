--[[
Title: Keepwork User API
Author(s):  big
Date:  2020.7.7
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkUserApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/User.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkUserApi = NPL.export()

-- url: /user/school
-- desc: get user school list
-- method: GET
-- headers: 
--[[
    Authorization string necessary
]]
-- return:
--[[
    id number not necessary
    name string not necessary
    regionId number not necessary
    region object not necessary
        country string not necessary
        state string not necessary
        city string not necessary
        county string not necessary	
    type string not necessary
    orgId number not necessary
]]
function KeepworkUserApi:School(success, error)
    KeepworkBaseApi:Get('/user/school', nil, nil, success, error)
end
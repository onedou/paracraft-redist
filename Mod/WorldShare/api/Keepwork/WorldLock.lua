--[[
Title: World Lock API
Author(s):  big
Date:  2020.2.10
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Users.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkWorldLockApi = NPL.export()

-- url: /worldlock
-- method: POST
-- params:
--[[
  pid	integer	necessary project id	
  mode string necessary edit mode(share,exclusive)
  server string not necessary server address
  password string not necessary server password
  revision integer not necessary revision number when server opened
]]
-- return: object
function KeepworkWorldLockApi:UpdateWorldLockRecord(pid, mode, success, error)
  local parmas = {
    pid = pid,
    mode = mode
  }

  KeepworkBaseApi:Post("/worldlock", params, nil, success, error)
end

-- url: /worldlock
-- method: DELETE
-- params:
--[[
  pid	integer	necessary
]]
-- return: object
function KeepworkWorldLockApi:RemoveWorldLockRecord(pid, success, error)
  KeepworkBaseApi:Delete("/worldlock", { pid = pid }, nil, success, error)
end
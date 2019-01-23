--[[
Title: Wallet
Author(s):  big
Date: 2019.01.23
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Wallet = NPL.load("(gl)Mod/WorldShare/database/Wallet.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local Wallet = NPL.export()

function Wallet:GetAllData()
  local playerController = Store:Getter("user/GetPlayerController")

  if not playerController then
      playerController = GameLogic.GetPlayerController()
      local SetPlayerController = Store:Action("user/SetPlayerController")

      SetPlayerController(playerController)
  end

  local wallet = playerController:LoadLocalData("wallet", nil, true)

  if type(wallet) ~= "table" then
      return {}
  end

  return wallet
end
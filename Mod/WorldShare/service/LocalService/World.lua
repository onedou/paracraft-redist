--[[
Title: LocalService World
Author(s):  big
Date:  2020.2.12
Place: Foshan
use the lib:
------------------------------------------------------------
local LocalServiceWorld = NPL.load("(gl)Mod/WorldShare/service/LocalService/World.lua")
------------------------------------------------------------
]]
local LocalService = NPL.load("../LocalService")

local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision")
local SaveWorldHandler = commonlib.gettable("MyCompany.Aries.Game.SaveWorldHandler")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList")

local LocalServiceWorld = NPL.export()

function LocalServiceWorld:GetWorldList()
    local localWorlds = LocalLoadWorld.BuildLocalWorldList(true)

    for key, value in ipairs(localWorlds) do
        if value.IsFolder then
            value.worldpath = value.worldpath .. '/'

            local worldRevision = WorldRevision:new():init(value.worldpath)
            value.revision = worldRevision:GetDiskRevision()

            local tag = SaveWorldHandler:new():Init(value.worldpath):LoadWorldInfo()

            if type(tag) ~= 'table' then
                return false
            end

            if tag.kpProjectId then
                value.kpProjectId = tag.kpProjectId
            end

            if tag.size then
                value.size = tag.size
            else
                value.size = 0
            end

            value.local_tagname = tag.name
            value.is_zip = false
        else
            value.foldername = value.Title
            value.text = value.Title
            value.is_zip = true
            value.remotefile = format("local://%s", value.worldpath)
        end

        value.modifyTime = Mod.WorldShare.Utils:UnifiedTimestampFormat(value.writedate)
    end

    return localWorlds
end

function LocalServiceWorld:GetInternetLocalWorldList()
  local ServerPage = InternetLoadWorld.GetCurrentServerPage()

  RemoteServerList:new():Init(
      "local",
      "localworld",
      function(bSucceed, serverlist)
          if not serverlist:IsValid() then
              return false
          end

          ServerPage.ds = serverlist.worlds or {}
          InternetLoadWorld.OnChangeServerPage()
      end
  )

  return ServerPage.ds or {}
end

function LocalServiceWorld:MergeInternetLocalWorldList(currentWorldList)
    for CKey, CItem in ipairs(currentWorldList) do
        for IKey, IItem in ipairs(self:GetInternetLocalWorldList()) do
            if IItem.foldername == CItem.foldername then
                if IItem.is_zip == CItem.is_zip then 
                    for key, value in pairs(IItem) do
                        if(key ~= "revision") then
                            CItem[key] = value
                        end
                    end
                    break
                end
            end
        end
    end

    InternetLoadWorld.cur_ds = currentWorldList
    
    return currentWorldList
end
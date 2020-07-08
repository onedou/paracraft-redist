--[[
Title: my school page
Author(s):  big
Date: 2019.09.11
Desc: 
use the lib:
------------------------------------------------------------
local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
------------------------------------------------------------
]]

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
local KeepworkSchoolsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Schools.lua")

local MySchool = NPL.export()

function MySchool:Show()
    Mod.WorldShare.MsgBox:Show(L"请稍后...", nil, nil, nil, nil, 6)

    local params = Mod.WorldShare.Utils.ShowWindow(600, 300, "Mod/WorldShare/cellar/MySchool/MySchool.html", "MySchool")

    KeepworkServiceSchoolAndOrg:GetMyAllOrgsAndSchools(function(schoolData, orgData)
        Mod.WorldShare.MsgBox:Close()

        echo(schoolData, true)
        echo(orgData, true)
    end)
end

function MySchool:ShowJoinSchool()
    self.provinces = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.cities = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.areas = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.kinds = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        },
        {
            text = L"小学",
            value = L"小学"
        },
        {
            text = L"中学",
            value = L"中学"
        },
        {
            text = L"大学",
            value = L"大学",
        }
    }

    local params = Mod.WorldShare.Utils.ShowWindow(600, 330, "Mod/WorldShare/cellar/MySchool/JoinSchool.html", "JoinSchool")

    self:GetProvinces(function(data)
        if type(data) ~= "table" then
            return false
        end

        self.provinces = data

        params._page:Refresh(0.01)
    end)
end

function MySchool:ShowJoinInstitute()
    local params = Mod.WorldShare.Utils.ShowWindow(600, 200, "Mod/WorldShare/cellar/MySchool/JoinInstitute.html", "JoinInstitute")
end

function MySchool:ShowRecordSchool()
    local params = Mod.WorldShare.Utils.ShowWindow(600, 300, "Mod/WorldShare/cellar/MySchool/RecordSchool.html", "RecordSchool")
end

function MySchool:GetProvinces(callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion("province", nil, function(data)
        if type(data) ~= "table" then
            return false
        end

        if type(callback) == "function" then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L"请选择",
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetCities(id, callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion("city", id, function(data)
        if type(data) ~= "table" then
            return false
        end

        if type(callback) == "function" then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L"请选择",
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetAreas(id, callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion('area', id, function(data)
        if type(data) ~= "table" then
            return false
        end

        if type(callback) == "function" then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L"请选择",
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetSearchSchoolResult(id, type)
    KeepworkSchoolsApi:GetList(nil, id, type, function(data, err)
        echo("from get search school result!!!!!", true)
        echo(data, true)
    end)
end
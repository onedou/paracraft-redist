﻿--[[
Title: LocalService
Author(s):  big
Date:  2016.12.11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService")
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Files.lua")
NPL.load("(gl)script/ide/Encoding.lua")
NPL.load("(gl)script/ide/System/Encoding/base64.lua")
NPL.load("(gl)script/ide/System/Encoding/sha1.lua")
NPL.load("(gl)Mod/WorldShare/service/GithubService.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua")
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua")
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")
NPL.load("(gl)Mod/WorldShare/service/FileDownloader/FileDownloader.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")

local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService")
local GithubService = commonlib.gettable("Mod.WorldShare.service.GithubService")
local EncodingC = commonlib.gettable("commonlib.Encoding")
local EncodingS = commonlib.gettable("System.Encoding")
local Files = commonlib.gettable("commonlib.Files")
local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")

local LocalService = commonlib.inherit(nil, commonlib.gettable("Mod.WorldShare.service.LocalService"))

function LocalService:ctor()
    self.filter = "*.*"
    self.nMaxFileLevels = 0
    self.nMaxFilesNum = 500
    self.output = {}
end

function LocalService:LoadFiles(worldDir)
    if (string.sub(worldDir, -1, -1) == "/") then
        self.worldDir = string.sub(worldDir, 1, -2)
    end

    local result = Files.Find({}, self.worldDir, self.nMaxFileLevels, self.nMaxFilesNum, self.filter)

    self:filesFind(result, self.worldDir)

    for _, item in ipairs(self.output) do
        item.filename = EncodingC.DefaultToUtf8(item.filename)
    end

    GlobalStore.set('localFiles', self.output)

    return self.output
end

function LocalService:filesFind(result, path, subPath)
    local curResult = commonlib.copy(result)
    local curPath = commonlib.copy(path)
    local curSubPath = commonlib.copy(subPath)

    if (type(curResult) == "table") then
        local convertLineEnding = {[".xml"] = true, [".bmax"] = true, [".txt"] = true, [".md"] = true, [".lua"] = true}
        local zipFile = {[".xml"] = true, [".bmax"] = true}

        for key, item in ipairs(curResult) do
            if (item.filesize ~= 0) then
                item.file_path = curPath .. "/" .. item.filename

                if (curSubPath) then
                    item.filename = curSubPath .. "/" .. item.filename
                end

                local sExt = item.filename:match("%.[^&.]+$")

                if (sExt == ".bak") then
                    item = false
                else
                    local bConvert = false

                    if (convertLineEnding[sExt] and zipFile[sExt]) then
                        bConvert = not self:isZip(item.file_path)
                    elseif (convertLineEnding[sExt]) then
                        bConvert = true
                    end

                    if (bConvert) then
                        item.file_content_t = self:getFileContent(item.file_path):gsub("\r\n", "\n")
                        item.filesize = #item.file_content_t
                        item.sha1 = EncodingS.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex")
                    else
                        item.file_content_t = self:getFileContent(item.file_path)
                        item.sha1 = EncodingS.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex")
                    end

                    item.needChange = true

                    self.output[#self.output + 1] = item
                end
            else
                local newPath = curPath .. "/" .. item.filename
                local newResult = Files.Find({}, newPath, self.nMaxFileLevels, self.nMaxFilesNum, self.filter)
                local newSubPath = nil

                if (curSubPath) then
                    newSubPath = curSubPath .. "/" .. item.filename
                else
                    newSubPath = item.filename
                end

                self:filesFind(newResult, newPath, newSubPath)
            end
        end
    end
end

function LocalService:getFileContent(filePath)
    local file = ParaIO.open(filePath, "r")
    if (file:IsValid()) then
        local fileContent = file:GetText(0, -1)
        file:close()
        return fileContent
    end
end

function LocalService:write(foldername, path, content)
    local writePath = format("%s/%s/%s", SyncMain.GetWorldFolderFullPath(), foldername, path)
    local write = ParaIO.open(writePath, "w")

    write:write(content, #content)
    write:close()
end

function LocalService:delete(foldername, filename)
    local deletePath = format("%s/%s/%s", SyncMain.GetWorldFolderFullPath(), foldername, filename)

    ParaIO.DeleteFile(deletePath)
end

function LocalService:isZip(path)
    local file = ParaIO.open(path, "r")
    local fileType = nil

    if (file:IsValid()) then
        local o = {}

        file:ReadBytes(2, o)

        if (o[1] and o[2]) then
            fileType = o[1] .. o[2]
        end

        file:close()
    end

    if (fileType and fileType == "8075") then
        return true
    else
        return false
    end
end

function LocalService:MoveZipToFolder(path)
    if (not ParaAsset.OpenArchive(path, true)) then
        return false
    end

    local foldername = GlobalStore.get("foldername")

    local parentDir = path:gsub("[^/\\]+$", "")

    local filesOut = {}
    commonlib.Files.Find(filesOut, "", 0, 10000, ":.", path) -- ":.", any regular expression after : is supported. `.` match to all strings.

    local bashPath = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.default)

    local folderCreate = ""
    local rootFolder = filesOut[1] and filesOut[1].filename

    for _, item in ipairs(filesOut) do
        if (item.filesize > 0) then
            local file = ParaIO.open(format("%s%s", parentDir, item.filename), "r")

            if (file:IsValid()) then
                local binData = file:GetText(0, -1)
                local pathArray = {}
                local path = commonlib.copy(item.filename)

                path = path:sub(#rootFolder, #path)

                if (path == "/revision.xml") then
                    GlobalStore.set('remoteRevision', binData)
                end

                for segmentation in string.gmatch(path, "[^/]+") do
                    if (segmentation ~= rootFolder) then
                        pathArray[#pathArray + 1] = segmentation
                    end
                end

                folderCreate = commonlib.copy(bashPath)

                for i = 1, #pathArray - 1, 1 do
                    folderCreate = folderCreate .. pathArray[i] .. "/"
                    ParaIO.CreateDirectory(folderCreate)
                end

                local writeFile = ParaIO.open(format("%s%s", bashPath, path), "w")

                writeFile:write(binData, #binData)
                writeFile:close()

                file:close()
            end
        else
            -- this is a folder
        end
    end

    ParaAsset.CloseArchive(path)
end

function LocalService:FileDownloader(_foldername, _path, _callback)
    local foldername = GitEncoding.base32(SyncMain.foldername.utf8)

    local url = ""
    local downloadDir = ""

    if (loginMain.dataSourceType == "github") then
    elseif (loginMain.dataSourceType == "gitlab") then
        url =
            loginMain.rawBaseUrl ..
            "/" .. loginMain.dataSourceUsername .. "/" .. foldername .. "/raw/" .. SyncMain.commitId .. "/" .. _path
        downloadDir = SyncMain.worldDir.default .. _path
    end

    local Files =
        FileDownloader:new():Init(
        _path,
        url,
        downloadDir,
        function(bSuccess, downloadPath)
            --LOG.std(nil,"debug","FileDownloader-downloadPath",downloadPath);

            local content = LocalService:getFileContent(downloadPath)

            if (bSuccess) then
                local returnData = {filename = _path, content = content}
                return _callback(bSuccess, returnData)
            else
                return _callback(bSuccess, nil)
            end
        end,
        "access plus 5 mins",
        true
    )
end

function LocalService:GetWorldSize(WorldDir)
    local files =
        commonlib.Files.Find(
        {},
        WorldDir,
        5,
        5000,
        function(item)
            return true
        end
    )

    local filesTotal = 0
    for key, value in ipairs(files) do
        filesTotal = filesTotal + tonumber(value.filesize)
    end

    return filesTotal
end

function LocalService:GetZipWorldSize(zipWorldDir)
    return ParaIO.GetFileSize(zipWorldDir)
end

function LocalService:GetZipRevision(zipWorldDir)
    local zipParentDir = zipWorldDir:gsub("[^/\\]+$", "")

    ParaAsset.OpenArchive(zipWorldDir, true)
    local output = {}

    Files.Find(output, "", 0, 500, ":revision.xml", zipWorldDir)

    if (#output ~= 0) then
        local file = ParaIO.open(zipParentDir .. output[1].filename, "r")
        local binData

        if (file:IsValid()) then
            binData = file:GetText(0, -1)
            --LOG.std(nil,"debug","binData",binData);
            file:close()
        end

        ParaAsset.CloseArchive(zipWorldDir)
        return binData
    else
        return 0
    end
end

function LocalService:SetTag(worldDir, newTag)
    if (type(worldDir) == "string" and type(newTag) == "table") then
        local tagTable = {
            {
                attr = newTag,
                name = "pe:world"
            },
            name = "pe:mcml"
        }

        local xmlString = commonlib.Lua2XmlString(tagTable, true, true)

        local filePath = worldDir .. "/tag.xml"

        local file = ParaIO.open(filePath, "w")

        file:write(xmlString, #xmlString)
        file:close()
    end
end

function LocalService:GetTag(foldername)
    if (not foldername) then
        return {}
    end
    local filePath = SyncMain.GetWorldFolderFullPath() .. "/" .. foldername .. "/tag.xml"

    local tag = ParaXML.LuaXML_ParseFile(filePath)

    if (type(tag) == "table" and type(tag[1]) == "table" and type(tag[1][1]) == "table") then
        return tag[1][1]["attr"]
    else
        return {}
    end
end
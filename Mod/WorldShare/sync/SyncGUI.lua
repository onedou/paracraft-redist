﻿--[[
Title: SyncGUI
Author(s):  big
Date: 	2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua")
local SyncGUI = commonlib.gettable("Mod.WorldShare.sync.SyncGUI")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");

local SyncMain   = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
local SyncGUI    = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.sync.SyncGUI"));
local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld");

local SyncPage;

SyncGUI.current = 0;
SyncGUI.total   = 0;
SyncGUI.files   = "";

function SyncGUI:ctor()
    SyncGUI.current = 0;
    SyncGUI.total   = 0;
    SyncGUI.files   = L"同步中，请稍后...";

    SyncMain.curUpdateIndex        = 1;
    SyncMain.curUploadIndex        = 1;
    SyncMain.totalLocalIndex       = nil;
    SyncMain.totalDataSourceIndex  = nil;
    SyncMain.dataSourceFiles       = {};

    SyncMain.curDownloadIndex      = 1;
    SyncMain.dataSourceIndex       = 0;

    System.App.Commands.Call("File.MCMLWindowFrame", {
        url  = "Mod/WorldShare/sync/SyncGUI.html", 
        name = "SyncWorldShare", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 0,
        isTopLevel = true,
        allowDrag = false,
        bShow = bShow,
        directPosition = true,
        align = "_ct",
        x = -550/2,
        y = -320/2,
        width = 550,
        height = 320,
        cancelShowAnimation = true,
    });
end

function SyncGUI:OnInit()
    SyncPage = document:GetPageCtrl();
    SyncGUI.progressbar = SyncPage:GetNode("progressbar");
end

function SyncGUI:refresh(delayTimeMs)
    if(SyncPage) then
        SyncPage:Refresh(delayTimeMs or 0.01);
    end
end

function SyncGUI.closeWindow()
    SyncPage:CloseWindow();
end

function SyncGUI.finish(callback)
    SyncMain.finish = true;

    SyncGUI.files = L"正在等待上次同步完成，请稍后...";
    SyncGUI:refresh(0.01);

    log(SyncGUI.total);
    log(SyncGUI.current);
    log(SyncMain.finish);

    local function checkFinish()
        commonlib.TimerManager.SetTimeout(function()
            if(SyncMain.isFetching) then
                checkFinish();
            else
                SyncPage:CloseWindow();
                if(type(callback) == "function") then
                    callback();
                end
            end
        end, 100);
    end

    checkFinish();
end

function SyncGUI:retry()
    SyncGUI.finish(function()
        if(SyncMain.syncType == "sync") then
            SyncMain.syncCompare(true);
        elseif(SyncMain.syncType == "share") then
            ShareWorld.shareCompare();
        else
            SyncMain.syncCompare(true);
        end

        SyncMain.syncType = nil;
    end);
end

function SyncGUI:updateDataBar(current, total, files)
    local databar = SyncPage:GetNode("databar");
    
    SyncGUI.current  = current;
    SyncGUI.total    = total;

    if(files)then
        SyncGUI.files = files;
    else
        SyncGUI.files = L"同步中，请稍后...";
    end

    LOG.std("SyncGUI", "debug", "NumbersGUI", "Totals : %s , Current : %s, Status : %s", SyncGUI.total , SyncGUI.current, SyncGUI.files);

    SyncGUI.progressbar:SetAttribute("Maximum", SyncGUI.total);
    SyncGUI.progressbar:SetAttribute("Value", SyncGUI.current);

    SyncPage:Refresh(0.01);
end

function SyncGUI.copy()
    ParaMisc.CopyTextToClipboard(ShareWorld.getWorldUrl(true));
end


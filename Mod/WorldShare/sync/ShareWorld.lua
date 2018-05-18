﻿--[[
Title: share world to datasource
Author(s): big
Date: 2017.5.12
Desc:  It can take snapshot for the current world. It can quick save or full save the world to datasource. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld");
ShareWorld.ShowPage()
-------------------------------------------------------
]]

NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");

local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
local SyncMain       = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
local loginMain      = commonlib.gettable("Mod.WorldShare.login.loginMain");
local WorldCommon    = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local ShareWorld     = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.sync.ShareWorld"));

ShareWorld.SharePage = nil

function ShareWorld:ctor()
end

function ShareWorld.ShowPage()
    if(loginMain.isVerified ~= "noLogin" and not loginMain.isVerified) then
        _guihelper.MessageBox(L"您需要到keepwork官网进行实名认证，认证成功后需重启paracraft即可正常操作，是否现在认证？", function(res)
            if(res and res == _guihelper.DialogResult.Yes) then
                ParaGlobal.ShellExecute("open", "http://keepwork.com/wiki/user_center", "", "", 1);
            end
        end, _guihelper.MessageBoxButtons.YesNo);

        return;
    end

    SyncMain.syncType = "share";

    if(not loginMain.IsSignedIn()) then
        loginMain.showLoginModalImp(function()
            ShareWorldPage.ShowPage();
        end);
    else
        loginMain.showMessageInfo(L"正在获取，请稍后...");
        ShareWorld.shareCompare();
    end
end

function ShareWorld.ShowPageImp()
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url            = "Mod/WorldShare/sync/ShareWorld.html",
        name           = "SaveWorldPage.ShowSharePage",
        isShowTitleBar = false,
        DestroyOnClose = true,
        style          = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag      = true,
        isTopLevel     = true,
        directPosition = true,
        align          = "_ct",
        x              = -640/2,
        y              = -415/2,
        width          = 640,
        height         = 415,
    });
end

function ShareWorld:init()
    local filepath = SyncMain.worldDir.default .. "preview.jpg";

    if(ParaIO.DoesFileExist(filepath)) then
        ShareWorld.SharePage:SetNodeValue("ShareWorldImage", filepath);
    end

    ShareWorld.SharePage:Refresh();
end

function ShareWorld.setSharePage()
    ShareWorld.SharePage = document:GetPageCtrl();
end

function ShareWorld.closeSharePage()
    ShareWorld.SharePage:CloseWindow();
end

function ShareWorld.getWorldSize()
    SyncMain.tagInfor = WorldCommon.GetWorldInfo();

    return SyncMain.tagInfor.size;
end

function ShareWorld.shareCompare()
    SyncMain:compareRevision(nil, function(result)
        if(result and result == "tryAgain") then
            ShareWorld.shareCompare();
        elseif(result == "zip") then
            _guihelper.MessageBox(L"不能同步ZIP文件");
            loginMain.closeMessageInfo();
        elseif(result) then
            ShareWorld.ShowPageImp();
            ShareWorld.CompareResult = result;
            ShareWorld.SharePage:Refresh();
            ShareWorld:init();
            loginMain.closeMessageInfo();
        else
            if(ShareWorld.SharePage) then
                ShareWorld.SharePage:CloseWindow();
            end
        end
    end);
end

function ShareWorld.shareNow()
    ShareWorld.SharePage:CloseWindow();

    if(ShareWorld.CompareResult == "remoteBigger") then
        _guihelper.MessageBox(L"当前本地版本小于远程版本，是否继续上传？", function(res)
            if(res and res == 6) then
                SyncMain:syncToDataSource();
            end
        end);
    elseif(ShareWorld.CompareResult == "localBigger" or ShareWorld.CompareResult == "justLocal" or ShareWorld.CompareResult == "equal") then
        SyncMain:syncToDataSource();
    end
end

function ShareWorld.snapshot()
    ShareWorldPage.TakeSharePageImage();
    ShareWorld.UpdateImage(true)

    if(SyncMain.remoteRevison == SyncMain.currentRevison)then
        CommandManager:RunCommand("/save");
        ShareWorld.SharePage:CloseWindow();
        ShareWorld.ShowPage();
    end
end

function ShareWorld.UpdateImage(bRefreshAsset)
    if(ShareWorld.SharePage) then
        local filepath = ShareWorldPage.GetPreviewImagePath();
        ShareWorld.SharePage:SetUIValue("ShareWorldImage", filepath);
        if(bRefreshAsset) then
            ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
        end
    end
end

function ShareWorld.getWorldUrl(bEncode)
    if(loginMain.login_type == 1) then
        return "";
    end

    local foldername;

    if(bEncode) then
        foldername = commonlib.Encoding.url_encode("world_" .. SyncMain.foldername.utf8);
    else
        foldername = "world_" .. SyncMain.foldername.utf8;
    end

    local url = loginMain.site .. "/" .. loginMain.username .. "/paracraft/" .. foldername;
    return url;
end

function ShareWorld.openWorldWebPage()
    local url = ShareWorld.getWorldUrl(true);
    ParaGlobal.ShellExecute("open", url, "", "", 1);
end


--[[
Title: Explorer App Page
Author(s):  big
Date: 2019.01.21
Place: Foshan
use the lib:
------------------------------------------------------------
local MainPage = NPL.load("(gl)Mod/ExplorerApp/components/MainPage.lua")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/service/FileDownloader/FileDownloader.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua")

local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld")
local Wallet = NPL.load("(gl)Mod/ExplorerApp/database/Wallet.lua")
local Screen = commonlib.gettable("System.Windows.Screen")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceProjects = NPL.load("../service/KeepworkService/Projects.lua")
local KeepworkEsServiceProjects = NPL.load("../service/KeepworkEsService/Projects.lua")
local Password = NPL.load("./Password/Password.lua")
local GameOver = NPL.load("./GameProcess/GameOver/GameOver.lua")
local TimeUp = NPL.load("./GameProcess/TimeUp/TimeUp.lua")
local ProactiveEnd = NPL.load("./GameProcess/ProactiveEnd/ProactiveEnd.lua")
local Wallet = NPL.load("../database/Wallet.lua")
local ProjectsDatabase = NPL.load("../database/Projects.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local Toast = NPL.load("./Toast/Toast.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local HttpRequest = NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")

local MainPage = NPL.export()

MainPage.categorySelected = L"收藏"
MainPage.categoryTree = {
    {value = L"收藏"}
}
MainPage.worksTree = {}
MainPage.downloadedGame = "all"
MainPage.curPage = 1

function MainPage:ShowPage(callback)
    if type(callback) then
        self.CloseCallback = callback
    end

    self.balance = Wallet:GetUserBalance()
    self.playerBalance = Wallet:GetPlayerBalance()

    Store:Set("explorer/selectSortIndex", 1)
    Store:Set("explorer/sortList", {{value = L"综合"}, {value = L"最新"}, {value = L"热门"}})

    local params =
        Utils:ShowWindow(
        0,
        0,
        "Mod/ExplorerApp/components/MainPage.html",
        "Mod.ExplorerApp.MainPage",
        0,
        0,
        "_fi",
        false,
        2
    )

    local MainPagePage = Store:Get("page/MainPage")

    if MainPagePage then
        self:SetCategoryTree()
    end

    Screen:Connect("sizeChanged", MainPage, MainPage.OnScreenSizeChange, "UniqueConnection")
    MainPage.OnScreenSizeChange()
end

function MainPage:SetPage()
    Store:Set("page/MainPage", document:GetPageCtrl())
end

function MainPage:Refresh(times)
    local MainPagePage = Store:Get("page/MainPage")

    if MainPagePage then
        MainPagePage:Refresh(times or 0.01)
    end
end

function MainPage:Close()
    local MainPagePage = Store:Get("page/MainPage")

    if MainPagePage then
        if type(self.CloseCallback) == 'function' then
            self.CloseCallback()
        end

        MainPagePage:CloseWindow()
    end
end

function MainPage.OnScreenSizeChange()
    local MainPage = Store:Get("page/MainPage")

    if (not MainPage) then
        return false
    end

    local height = math.floor(Screen:GetHeight())
    local width = math.floor(Screen:GetWidth())

    local areaNode = MainPage:GetNode("area")
    areaNode:SetCssStyle("height", height)
    areaNode:SetCssStyle("width", width)

    local stripNode = MainPage:GetNode("strip")
    stripNode:SetCssStyle("margin-left", (width - 960) / 2)

    local areaContentNode = MainPage:GetNode("area_content")
    areaContentNode:SetCssStyle("height", (height - 45))
    areaContentNode:SetCssStyle("margin-left", (width - 960) / 2)

    MainPage:Refresh(0)
end

function MainPage:UpdateCoins()
    self.playerBalance = Wallet:GetPlayerBalance()
    self:Refresh()
end

function MainPage:UpdateSort()
    local sort

    if Store:Get("explorer/selectSortIndex") == 2 then
        sort = "updated_at"
    end

    if Store:Get("explorer/selectSortIndex") == 3 then
        sort = "recent_view"
    end

    if self.categorySelected ~= 0 then
        self:SetWorksTree(self.categorySelected, sort)
    else
        self:Search(sort)
    end
end

function MainPage:SetCategoryTree()
    local MainPagePage = Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    MainPagePage:GetNode("categoryTree"):SetAttribute("DataSource", self.categoryTree)

    KeepworkServiceProjects:GetAllTags(
        function(data, err)
            if err ~= 200 or type(data) ~= "table" or not data.rows then
                self:SetWorksTree(L"收藏")
                return false
            end

            self.remoteCategoryTree = {}

            for key, item in ipairs(data.rows) do
                if item and item.tagname ~= "paracraft专用" then
                    local curItem = {value = item.tagname or ""}

                    if item and item.extra and item.extra.enTagname and self:IsEnglish() then
                        curItem.enValue = item.extra.enTagname
                    end

                    self.remoteCategoryTree[#self.remoteCategoryTree + 1] = curItem
                end
            end

            self.remoteCategoryTree[#self.remoteCategoryTree + 1] = {value = L"收藏"}

            MainPagePage:GetNode("categoryTree"):SetAttribute("DataSource", self.remoteCategoryTree)
            self:SetWorksTree(self.remoteCategoryTree[1].value)
        end
    )
end

function MainPage:SetWorksTree(value, sort)
    local MainPage = Store:Get("page/MainPage")

    if (not MainPage) then
        return false
    end

    if not value then
        value = L"精选"
    end

    if value == L"收藏" then
        local allFavoriteProjects = ProjectsDatabase:GetAllFavoriteProjects()

        KeepworkServiceProjects:GetProjectById(
            allFavoriteProjects,
            sort,
            function(data, err)
                if not data or not data.rows then
                    return false
                end

                -- map to es data format
                for key, item in ipairs(data.rows) do
                    if item.extra and item.extra.imageUrl then
                        item.cover = item.extra.imageUrl
                    end

                    if item.user and item.user.username then
                        item.username = item.user.username
                    end
                end

                local rows = {}

                if self.downloadedGame == "all" then
                    rows = data.rows
                elseif self.downloadedGame == "local" then
                    for key, item in ipairs(data.rows) do
                        if ProjectsDatabase:IsProjectDownloaded(item.id) then
                            rows[#rows + 1] = item
                        end
                    end
                else
                    return false
                end

                self.categorySelected = value
                self.worksTree = self:HandleWorldsTree(rows)
                MainPage:GetNode("worksTree"):SetAttribute("DataSource", rows)
                self:Refresh()
            end
        )
        return true
    end

    local filter = {"paracraft专用", value}

    KeepworkEsServiceProjects:GetEsProjectsByFilter(
        filter,
        sort,
        {page = self.curPage},
        function(data, err)
            if not data or err ~= 200 then
                return false
            end

            self.categorySelected = value

            local rows = {}

            if self.downloadedGame == "all" then
                rows = data.hits
            elseif self.downloadedGame == "local" then
                for key, item in ipairs(data.hits) do
                    if ProjectsDatabase:IsProjectDownloaded(item.id) then
                        rows[#rows + 1] = item
                    end
                end
            else
                return false
            end

            if self.curPage ~= 1 then
                rows = self:HandleWorldsTree(rows)

                for key, item in ipairs(rows) do
                    self.worksTree[#self.worksTree + 1] = item
                end
            else
                self.worksTree = self:HandleWorldsTree(rows)
            end

            MainPage:GetNode("worksTree"):SetAttribute("DataSource", self.worksTree)
            self:Refresh()
        end
    )
end

function MainPage:Search(sort)
    local MainPage = Store:Get("page/MainPage")

    if (not MainPage) then
        return false
    end

    local projectId = tonumber(MainPage:GetValue("project_id"))

    if not projectId or projectId == 0 then
        return false
    end

    KeepworkServiceProjects:GetProjectById(
        {projectId},
        sort,
        function(data, err)
            if not data or not data.rows then
                return false
            end

            -- map to es data format
            for key, item in ipairs(data.rows) do
                if item.extra and item.extra.imageUrl then
                    item.cover = item.extra.imageUrl
                end

                if item.user and item.user.username then
                    item.username = item.user.username
                end
            end

            self.categorySelected = 0
            self.worksTree = self:HandleWorldsTree(data.rows)
            MainPage:GetNode("worksTree"):SetAttribute("DataSource", data.rows)
            self:Refresh()
        end
    )
end

function MainPage:HandleWorldsTree(rows)
    if not rows or type(rows) ~= "table" then
        return false
    end

    for key, item in ipairs(rows) do
        if ProjectsDatabase:IsProjectDownloaded(item.id) then
            item.downloaded = true
        else
            item.downloaded = false
        end

        if ProjectsDatabase:IsFavoriteProject(item.id) then
            item.favorite = true
        else
            item.favorite = false
        end
    end

    return rows
end

function MainPage:DownloadWorld(index)
    Toast:ShowPage(L"开始下载")
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    KeepworkServiceProjects:GetProjectDetailById(
        curItem.id,
        function(data, err)
            if not data or not data.world or not data.world.archiveUrl or err ~= 200 then
                Toast:ShowPage(L"网络不太稳定")
                return false
            end

            local archiveUrl = data.world.archiveUrl

            DownloadWorld.ShowPage(
                format("【%s%d】 %s %s%s", L"项目ID:", curItem.id, curItem.name, L"作者：", curItem.username)
            )
            FileDownloader:new():Init(
                "official_texture_package",
                archiveUrl,
                format(
                    "/worlds/DesignHouse/userworlds/%s_r.zip",
                    string.match(archiveUrl, "(.+)%.zip%?ref.+$"):gsub("[%W%s]+", "_")
                ),
                function(bSuccess, downloadPath)
                    if bSuccess then
                        Toast:ShowPage(L"下载成功")
                        ProjectsDatabase:SetDownloadedProject(data)
                        -- self:HandleWorldsTree(self.worksTree)
                        -- self:Refresh()
                        self:SelectProject(index)
                    end

                    DownloadWorld.Close()
                end,
                "access plus 5 mins",
                true
            )
        end,
        0
    )
end

function MainPage:SetFavorite(index)
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    if not ProjectsDatabase:IsFavoriteProject(curItem.id) then
        Toast:ShowPage(L"收藏成功")
        ProjectsDatabase:SetFavoriteProject(curItem.id)
    else
        Toast:ShowPage(L"取消收藏")
        ProjectsDatabase:RemoveFavoriteProject(curItem.id)
    end

    self:HandleWorldsTree(self.worksTree)
    self:Refresh()
end

function MainPage:SetCoins()
    Password:ShowPage()
end

function MainPage:CheckoutNewVersion(worldInfo, callback)
    if not worldInfo or
       not worldInfo.archiveUrl or
       not worldInfo.revision or
       not worldInfo.projectId then
        return false
    end

    local function Handle(data)
        if not data or not data.world or not data.world.revision then
            return false
        end

        if type(callback) ~= 'function' then
            return false
        end

        local remoteRevision = tonumber(data.world.revision)
        local localRevision = tonumber(worldInfo.revision)

        if remoteRevision > localRevision then
            callback(true)
        else
            callback(false)
        end
    end

    KeepworkServiceProjects:GetProjectDetailById(worldInfo.projectId, Handle)
end

function MainPage:SelectProject(index)
    self.curProjectIndex = index

    if self.playerBalance <= 0 and not Store:Get("world/personalMode") then
        GameOver:ShowPage(3)
        return false
    end

    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    if not ProjectsDatabase:IsProjectDownloaded(curItem.id) then
        self:DownloadWorld(index)
        return false
    end

    local projectInfo = ProjectsDatabase:GetDownloadedProject(curItem.id)

    if not projectInfo or not projectInfo.world then
        return false
    end

    local function Handle(result)
        if result then
            _guihelper.MessageBox(L"发现新版本，重新下载世界")
            self:DownloadWorld(index)
            return false
        end

        local world = RemoteWorld.LoadFromHref(projectInfo.world.archiveUrl, "self")
        world:GetLocalFileName()

        local mytimer =
            commonlib.Timer:new(
            {
                callbackFunc = function(timer)
                    InternetLoadWorld.LoadWorld(
                        world,
                        nil,
                        "never",
                        function(bSucceed, localWorldPath)
                            if bSucceed then
                                if not Store:Get("world/personalMode") then
                                    self.playerBalance = self.playerBalance - 1
                                    self.balance = self.balance - 1
                                    Wallet:SetPlayerBalance(self.playerBalance)
                                    Wallet:SetUserBalance(self.balance)
                                    Store:Remove("explorer/reduceRemainingTime")
                                    Store:Remove("explorer/warnReduceRemainingTime")
                                    self:HandleGameProcess()
                                end

                                MainPage:Close()
                            end
                        end
                    )
                end
            }
        )

        -- prevent recursive calls.
        mytimer:Change(2, nil)
        Store:Set("explorer/mode", "recommend")
    end

    self:CheckoutNewVersion(projectInfo.world, Handle)
end

function MainPage:HandleGameProcess()
    if not Store:Get("explorer/warnReduceRemainingTime") then
        Store:Set("explorer/warnReduceRemainingTime", (1000 * 60 * 10) - (60 * 1000))
    end

    if not Store:Get("explorer/reduceRemainingTime") then
        Store:Set("explorer/reduceRemainingTime", 1000 * 60 * 10)
    end

    Utils.SetTimeOut(
        function()
            local reduceRemainingTime = Store:Get("explorer/reduceRemainingTime")
            local warnReduceRemainingTime = Store:Get("explorer/warnReduceRemainingTime")

            if warnReduceRemainingTime == 1000 then
                if self.playerBalance > 0 then
                    Toast:ShowPage(L"即将消耗一个金币")
                end

                Store:Set("explorer/warnReduceRemainingTime", warnReduceRemainingTime - 1000)
            elseif warnReduceRemainingTime > 0 then
                Store:Set("explorer/warnReduceRemainingTime", warnReduceRemainingTime - 1000)
            end

            if reduceRemainingTime == 1000 then
                if self.playerBalance > 0 then
                    Toast:ShowPage(L"消耗一个金币")
                    self.playerBalance = self.playerBalance - 1
                    self.balance = self.balance - 1
                    Wallet:SetPlayerBalance(self.playerBalance)
                    Wallet:SetUserBalance(self.balance)

                    Store:Set("explorer/reduceRemainingTime", reduceRemainingTime - 1000)
                    Store:Remove("explorer/reduceRemainingTime")
                    Store:Remove("explorer/warnReduceRemainingTime")
                    self:HandleGameProcess()
                else
                    TimeUp:ShowPage()
                end
            elseif reduceRemainingTime > 0 then
                Store:Set("explorer/reduceRemainingTime", reduceRemainingTime - 1000)
                self:HandleGameProcess()
            end
        end,
        1000
    )
end

function MainPage:SelectDownloadedCategory(value)
    local MainPagePage = Store:Get("page/MainPage")

    if not MainPagePage or not value then
        return false
    end

    self.curPage = 1
    self.downloadedGame = value
    self:SetWorksTree(self.categorySelected)
end

function MainPage:GetSortIndex()
    return Store:Get("explorer/selectSortIndex")
end

function MainPage:GetSortList()
    return Store:Get("explorer/sortList")
end

function MainPage:OnWorldLoad()
    local personalMode = Store:Get("world/personalMode")

    if not personalMode then
        Utils.SetTimeOut(
            function()
                Toast:ShowPage(L"消耗一个金币")
            end,
            1000
        )
    end
end

function MainPage:CanGoBack()
    local canGoBack = Store:Get("explorer/canGoBack")

    if canGoBack == false then
        return false
    end

    MainPage:Close()
end

function MainPage:OpenProject(id)
    if type(id) ~= "number" then
        return false
    end

    ParaGlobal.ShellExecute("open", format("%s/pbl/project/%d/", KeepworkService:GetKeepworkUrl(), id), "", "", 1)
end

function MainPage:GetPage()
    return Store:Get("page/MainPage")
end

function MainPage:IsEnglish()
    if Translation.GetCurrentLanguage() == 'enUS' then
        return true
    else
        return false
    end
end
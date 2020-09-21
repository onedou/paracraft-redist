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

-- pkg libs
NPL.load("(gl)Mod/WorldShare/service/FileDownloader/FileDownloader.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/DownloadWorld.lua")

local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")
local DownloadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.DownloadWorld")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld")
local Screen = commonlib.gettable("System.Windows.Screen")
local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
local Translation = commonlib.gettable("MyCompany.Aries.Game.Common.Translation")

-- databse
local Wallet = NPL.load("(gl)Mod/ExplorerApp/database/Wallet.lua")
local ProjectsDatabase = NPL.load("../database/Projects.lua")

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceProject = NPL.load("../service/KeepworkService/Project.lua")
local KeepworkEsServiceProject = NPL.load("../service/KeepworkEsService/Project.lua")

-- UI
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local Toast = NPL.load("./Toast/Toast.lua")
local Password = NPL.load("./Password/Password.lua")
local GameOver = NPL.load("./GameProcess/GameOver/GameOver.lua")
local TimeUp = NPL.load("./GameProcess/TimeUp/TimeUp.lua")
local ProactiveEnd = NPL.load("./GameProcess/ProactiveEnd/ProactiveEnd.lua")

local MainPage = NPL.export()

MainPage.categorySelected = {
    -- value = L"收藏"
}
MainPage.categoryTree = {
    -- {value = L"收藏"}
}
MainPage.worksTree = {}
MainPage.downloadedGame = "all"
MainPage.curPage = 1
MainPage.mainId = 0

function MainPage:ShowPage(callback)
    if type(callback) then
        self.CloseCallback = callback
    end

    self.balance = Wallet:GetUserBalance()
    self.playerBalance = Wallet:GetPlayerBalance()

    Mod.WorldShare.Store:Set("explorer/selectSortIndex", 3)
    Mod.WorldShare.Store:Set(
        "explorer/sortList",
        {
            {value = L"推荐", key="recommend"},
            {value = L"综合", key="synthesize"},
            {value = L"最新", key="updated_at"},
            {value = L"热门", key="recent_view"}
        }
    )

    -- local worldsharebeat = ParaEngine.GetAppCommandLineByParam("worldsharebeat", nil)
    -- local params

    -- if worldsharebeat and worldsharebeat == 'true' then
    --     params = Mod.WorldShare.Utils.ShowWindow(
    --         1100,
    --         650,
    --         "Mod/ExplorerApp/components/Theme/MainPage.html",
    --         "Mod.ExplorerApp.MainPage"
    --     )
    -- else
    --     params = Mod.WorldShare.Utils.ShowWindow(
    --         0,
    --         0,
    --         "Mod/ExplorerApp/components/MainPage.html",
    --         "Mod.ExplorerApp.MainPage",
    --         0,
    --         0,
    --         "_fi",
    --         false,
    --         2
    --     )

    --     Screen:Connect("sizeChanged", MainPage, MainPage.OnScreenSizeChange, "UniqueConnection")
    --     MainPage.OnScreenSizeChange()
    -- end

    local params = Mod.WorldShare.Utils.ShowWindow(
        1100,
        650,
        "Mod/ExplorerApp/components/Theme/MainPage.html",
        "Mod.ExplorerApp.MainPage"
    )

    params._page.OnClose = function()
        self.worksTree = {}
        self.downloadedGame = "all"
        self.curPage = 1
        self.mainId = 0
    end

    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if MainPagePage then
        self:SetCategoryTree()
    end
end

function MainPage:SetPage()
    Mod.WorldShare.Store:Set("page/MainPage", document:GetPageCtrl())
end

function MainPage:Refresh(times)
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if MainPagePage then
        MainPagePage:Refresh(times or 0.01)
    end
end

function MainPage:Close()
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if MainPagePage then
        if type(self.CloseCallback) == 'function' then
            self.CloseCallback()
        end

        MainPagePage:CloseWindow()
    end
end

function MainPage.OnScreenSizeChange()
    local MainPage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPage then
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
    self:SetWorksTree(self.categorySelected, Mod.WorldShare.Store:Getter('explorer/GetSortKey'))
end

function MainPage:SetCategoryTree()
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    MainPagePage:GetNode("categoryTree"):SetAttribute("DataSource", self.categoryTree)

    KeepworkServiceProject:GetAllTags(
        function(data, err)
            if err ~= 200 or type(data) ~= "table" or not data.rows then
                self:SetWorksTree(MainPage.categoryTree[1], Mod.WorldShare.Store:Getter('explorer/GetSortKey'))
                return false
            end

            self.remoteCategoryTree = {}

            for key, item in ipairs(data.rows) do
                if item and item.tagname ~= "paracraft专用" then
                    local curItem = { value = item.tagname or "", id = item.id }

                    if item and item.extra and item.extra.enTagname and self:IsEnglish() then
                        curItem.enValue = item.extra.enTagname
                    end

                    self.remoteCategoryTree[#self.remoteCategoryTree + 1] = curItem
                else
                    self.mainId = item.id
                end
            end

            -- self.remoteCategoryTree[#self.remoteCategoryTree + 1] = { value = L"收藏", id = -1 }

            MainPagePage:GetNode("categoryTree"):SetAttribute("DataSource", self.remoteCategoryTree)
            self:SetWorksTree({ value = 'all' }, Mod.WorldShare.Store:Getter('explorer/GetSortKey'))
        end
    )
end

function MainPage:SetWorksTree(categoryItem, sort)
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    if not categoryItem or type(categoryItem) ~= 'table' or not categoryItem.value then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L"请稍后...", nil, nil, nil, nil, 10)
    
    self.isSearching = false
    MainPagePage:SetValue("search_value", "")

    if categoryItem.value == L"收藏" then
        local allFavoriteProjects = ProjectsDatabase:GetAllFavoriteProjects()

        KeepworkServiceProject:GetProjectByIds(
            self.mainId,
            allFavoriteProjects,
            { page = self.curPage },
            function(data, err)
                Mod.WorldShare.MsgBox:Close()

                if not data or not data.rows then
                    return false
                end

                self.categorySelected = categoryItem

                local mapData = {}

                -- map data struct
                for key, item in ipairs(data.rows) do
                    mapData[#mapData + 1] = {
                        id = item.id,
                        name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or "",
                        cover = item.extra and type(item.extra.imageUrl) == 'string' and item.extra.imageUrl or "",
                        username = item.user and type(item.user.username) == 'string' and item.user.username or ""
                    }
                end

                local rows = {}

                if self.downloadedGame == "all" then
                    rows = mapData
                elseif self.downloadedGame == "local" then
                    for key, item in ipairs(mapData) do
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

                MainPagePage:GetNode("worksTree"):SetAttribute("DataSource", self.worksTree)
                self:Refresh()
            end
        )

        return true
    end

    if not sort then
        return false
    end

    if sort == 'recommend' then
        KeepworkServiceProject:GetRecommandProjects(
            categoryItem.id,
            self.mainId,
            { page = self.curPage },
            function(data, err)
                Mod.WorldShare.MsgBox:Close()

                if not data or err ~= 200 then
                    return false
                end

                self.categorySelected = categoryItem

                local mapData = {}

                -- map data struct
                for key, item in ipairs(data.rows) do
                    mapData[#mapData + 1] = {
                        id = item.id,
                        name = item.extra and type(item.extra.worldTagName) == 'string' and item.extra.worldTagName or item.name or "",
                        cover = item.extra and type(item.extra.imageUrl) == 'string' and item.extra.imageUrl or "",
                        username = item.user and type(item.user.username) == 'string' and item.user.username or "",
                        updated_at = item.updatedAt and type(item.updatedAt) == 'string' and item.updatedAt or ""
                    }
                end

                local rows = {}

                if self.downloadedGame == "all" then
                    rows = mapData
                elseif self.downloadedGame == "local" then
                    for key, item in ipairs(mapData) do
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

                MainPagePage:GetNode("worksTree"):SetAttribute("DataSource", self.worksTree)

                self:Refresh()
            end
        )
        return true
    end

    if sort == 'synthesize' then
        sort = nil
    end

    local filter = { "paracraft专用" }

    if categoryItem.value ~= 'all' then
        filter[#filter + 1] = categoryItem.value
    end

    KeepworkEsServiceProject:GetEsProjectsByFilter(
        filter,
        sort,
        { page = self.curPage },
        function(data, err)
            Mod.WorldShare.MsgBox:Close()

            if type(data) ~= 'table' or type(data.hits) ~= 'table' or err ~= 200 then
                return false
            end

            self.categorySelected = categoryItem

            for key, item in pairs(data.hits) do
                if item and item.world_tag_name then
                    item.name = item.world_tag_name
                end
            end

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

            MainPagePage:GetNode("worksTree"):SetAttribute("DataSource", self.worksTree)
            self:Refresh()
        end
    )
end

function MainPage:Search()
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage then
        return false
    end

    if not self.isSearching then
        self.isSearching = true
        self.searchValue = MainPagePage:GetValue("search_value")
    end

    local searchValue = self.searchValue

    if not searchValue or (type(searchValue) ~= 'string' and type(searchValue) ~= 'number') then
        return false
    end

    KeepworkEsServiceProject:Search(searchValue, { page = self.curPage }, function(data, err)
        if not data or not data.hits then
            return false
        end

        Mod.WorldShare.Store:Set('explorer/selectSortIndex', 1)
        self.categorySelected = {}
        -- self.worksTree = self:HandleWorldsTree(data.hits)
        
        if self.curPage ~= 1 then
            local rows = {}
            rows = self:HandleWorldsTree(data.hits)

            for key, item in ipairs(rows) do
                self.worksTree[#self.worksTree + 1] = item
            end
        else
            self.worksTree = self:HandleWorldsTree(data.hits)
        end

        MainPagePage:GetNode("worksTree"):SetAttribute("DataSource", self.worksTree)
        MainPagePage:SetValue("search_value", searchValue)

        self:Refresh()
    end)
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

    KeepworkServiceProject:GetProjectDetailById(
        curItem.id,
        function(data, err)
            if not data or not data.world or not data.world.archiveUrl or err ~= 200 then
                Toast:ShowPage(L"网络不太稳定")
                return false
            end

            local archiveUrl = data.world.archiveUrl
            local downloadFileName = string.match(archiveUrl, "(.+)%.zip")

            if type(downloadFileName) ~= 'string' then
                Toast:ShowPage(L"数据错误")
                return false
            end

            downloadFileName = format(LocalLoadWorld.GetWorldFolder() .. "/userworlds/%s_r.zip", downloadFileName:gsub("[%W%s]+", "_"))

            DownloadWorld.ShowPage(
                format("【%s%d】 %s %s%s", L"项目ID:", curItem.id, curItem.name, L"作者：", curItem.username)
            )
            FileDownloader:new():Init(
                "official_texture_package",
                archiveUrl,
                downloadFileName,
                function(bSuccess, downloadPath)
                    if bSuccess then
                        Toast:ShowPage(L"下载成功")
                        ProjectsDatabase:SetDownloadedProject(data)
                        -- self:HandleWorldsTree(self.worksTree)
                        -- self:Refresh()
                        self:SelectProject(index)
                    else
                        Toast:ShowPage(L"文件下载失败，请确认世界是否存在")
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

    KeepworkServiceProject:GetProjectDetailById(worldInfo.projectId, Handle)
end

function MainPage:SelectProject(index)
    self.curProjectIndex = index

    if self.playerBalance <= 0 and not Mod.WorldShare.Store:Get("world/personalMode") then
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
                                if not Mod.WorldShare.Store:Get("world/personalMode") then
                                    self.playerBalance = self.playerBalance - 1
                                    self.balance = self.balance - 1
                                    Wallet:SetPlayerBalance(self.playerBalance)
                                    Wallet:SetUserBalance(self.balance)
                                    Mod.WorldShare.Store:Remove("explorer/reduceRemainingTime")
                                    Mod.WorldShare.Store:Remove("explorer/warnReduceRemainingTime")
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
        Mod.WorldShare.Store:Set("explorer/mode", "recommend")
    end

    self:CheckoutNewVersion(projectInfo.world, Handle)
end

function MainPage:HandleGameProcess()
    if not Mod.WorldShare.Store:Get("explorer/warnReduceRemainingTime") then
        Mod.WorldShare.Store:Set("explorer/warnReduceRemainingTime", (1000 * 60 * 10) - (60 * 1000))
    end

    if not Mod.WorldShare.Store:Get("explorer/reduceRemainingTime") then
        Mod.WorldShare.Store:Set("explorer/reduceRemainingTime", 1000 * 60 * 10)
    end

    Mod.WorldShare.Utils.SetTimeOut(
        function()
            local reduceRemainingTime = Mod.WorldShare.Store:Get("explorer/reduceRemainingTime")
            local warnReduceRemainingTime = Mod.WorldShare.Store:Get("explorer/warnReduceRemainingTime")

            if warnReduceRemainingTime == 1000 then
                if self.playerBalance > 0 then
                    Toast:ShowPage(L"即将消耗一个金币")
                end

                Mod.WorldShare.Store:Set("explorer/warnReduceRemainingTime", warnReduceRemainingTime - 1000)
            elseif warnReduceRemainingTime > 0 then
                Mod.WorldShare.Store:Set("explorer/warnReduceRemainingTime", warnReduceRemainingTime - 1000)
            end

            if reduceRemainingTime == 1000 then
                if self.playerBalance > 0 then
                    Toast:ShowPage(L"消耗一个金币")
                    self.playerBalance = self.playerBalance - 1
                    self.balance = self.balance - 1
                    Wallet:SetPlayerBalance(self.playerBalance)
                    Wallet:SetUserBalance(self.balance)

                    Mod.WorldShare.Store:Set("explorer/reduceRemainingTime", reduceRemainingTime - 1000)
                    Mod.WorldShare.Store:Remove("explorer/reduceRemainingTime")
                    Mod.WorldShare.Store:Remove("explorer/warnReduceRemainingTime")
                    self:HandleGameProcess()
                else
                    TimeUp:ShowPage()
                end
            elseif reduceRemainingTime > 0 then
                Mod.WorldShare.Store:Set("explorer/reduceRemainingTime", reduceRemainingTime - 1000)
                self:HandleGameProcess()
            end
        end,
        1000
    )
end

function MainPage:SelectDownloadedCategory(value)
    local MainPagePage = Mod.WorldShare.Store:Get("page/MainPage")

    if not MainPagePage or not value then
        return false
    end

    self.curPage = 1
    self.downloadedGame = value
    self:SetWorksTree(self.categorySelected, Mod.WorldShare.Store:Getter('explorer/GetSortKey'))
end

function MainPage:GetSortIndex()
    return Mod.WorldShare.Store:Get("explorer/selectSortIndex")
end

function MainPage:GetSortList()
    return Mod.WorldShare.Store:Get("explorer/sortList")
end

function MainPage:OnWorldLoad()
    local personalMode = Mod.WorldShare.Store:Get("world/personalMode")

    if not personalMode then
        Mod.WorldShare.Utils.SetTimeOut(
            function()
                Toast:ShowPage(L"消耗一个金币")
            end,
            1000
        )
    end
end

function MainPage:CanGoBack()
    local canGoBack = Mod.WorldShare.Store:Get("explorer/canGoBack")

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
    return Mod.WorldShare.Store:Get("page/MainPage")
end

function MainPage:IsEnglish()
    if Translation.GetCurrentLanguage() == 'enUS' then
        return true
    else
        return false
    end
end
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

local FileDownloader = commonlib.gettable("Mod.WorldShare.service.FileDownloader.FileDownloader")
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld")
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld")
local Wallet = NPL.load('(gl)Mod/ExplorerApp/database/Wallet.lua')

local Screen = commonlib.gettable("System.Windows.Screen")

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Projects = NPL.load("../service/KeepworkService/Projects.lua")
local Password = NPL.load("./Password/Password.lua")
local GameOver = NPL.load("./GameProcess/GameOver/GameOver.lua")
local TimeUp = NPL.load('./GameProcess/TimeUp/TimeUp.lua')
local ProactiveEnd = NPL.load('./GameProcess/ProactiveEnd/ProactiveEnd.lua')
local Wallet = NPL.load('../database/Wallet.lua')
local ProjectsDatabase = NPL.load('../database/Projects.lua')
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")

local MainPage = NPL.export()

MainPage.categorySelected = 1
MainPage.categoryTree = {
    {value = L'精选'},
    {value = L'单人'},
    {value = L'双人'},
    {value = L'对战'},
    {value = L'动画'},
    {value = L'收藏'}
}
MainPage.worksTree = {}

function MainPage:ShowPage()
    self.playerBalance = Wallet:GetPlayerBalance()

    Store:Set('explorer/selectSortIndex', 1)
    Store:Set('explorer/sortList', { { value = L"综合" }, { value = L"最新" }, { value = L"热门" } })

	local params = Utils:ShowWindow(0, 0, "Mod/ExplorerApp/components/MainPage.html", "Mod.ExplorerApp.MainPage", 0, 0, "_fi", false)

    local MainPagePage = Store:Get('page/MainPage')

    if MainPagePage then
        MainPagePage:GetNode('categoryTree'):SetAttribute('DataSource', self.categoryTree)
        MainPage:SetWorkdsTree()
    end

	Screen:Connect("sizeChanged", MainPage, MainPage.OnScreenSizeChange, "UniqueConnection")
    MainPage.OnScreenSizeChange()
end

function MainPage:SetPage()
	Store:Set("page/MainPage", document:GetPageCtrl())
end

function MainPage:Refresh(times)
    local MainPagePage = Store:Get('page/MainPage')

    if MainPagePage then
        MainPagePage:Refresh(times or 0.01)
    end
end

function MainPage:Close()
    local MainPagePage = Store:Get('page/MainPage')

    if MainPagePage then
        MainPagePage:CloseWindow()
    end
end

function MainPage.OnScreenSizeChange()
	local MainPage = Store:Get('page/MainPage')

    if (not MainPage) then
        return false
    end

    local height = math.floor(Screen:GetHeight())
    local width = math.floor(Screen:GetWidth())

    local areaNode = MainPage:GetNode("area")
    areaNode:SetCssStyle('height', height)
    areaNode:SetCssStyle('width', width)
    
    local stripNode = MainPage:GetNode("strip")
    stripNode:SetCssStyle('margin-left', (width - 960) / 2)

    local areaContentNode = MainPage:GetNode("area_content")
    areaContentNode:SetCssStyle('height', (height - 45))
    areaContentNode:SetCssStyle('margin-left', (width - 960) / 2)

    MainPage:Refresh(0)
end

function MainPage:UpdateCoins()
    self.playerBalance = Wallet:GetPlayerBalance()
    self:Refresh()
end

function MainPage:UpdateSort()
    local sort

    if Store:Get('explorer/selectSortIndex') == 2 then
        sort = 'hotNo-desc'
    end

    if Store:Get('explorer/selectSortIndex') == 3 then
        sort = 'createdAt-desc'
    end

    if self.categorySelected ~= 0 then
        self:SetWorkdsTree(self.categorySelected, sort)
    else
        self:Search(sort)
    end
end

function MainPage:SetWorkdsTree(index, sort)
    local MainPage = Store:Get('page/MainPage')

    if (not MainPage) then
        return false
    end

    if not index then
        index = 1
    end

    local filter = {"paracraft专属", self.categoryTree[index].value}

    Projects:GetProjectsByFilter(filter, sort, function(data, err)
        if not data or not data.rows then
            return false
        end

        self.categorySelected = index
        self.worksTree = self:HandleWorldsTree(data.rows)
        MainPage:GetNode('worksTree'):SetAttribute('DataSource', data.rows)
        self:Refresh()
    end)
end

function MainPage:Search(sort)
    local MainPage = Store:Get('page/MainPage')

    if (not MainPage) then
        return false
    end

    local projectId = tonumber(MainPage:GetValue('project_id'))

    if not projectId or projectId == 0 then
        return false
    end

    Projects:GetProjectById(
        projectId,
        sort,
        function(data, err)
            if not data or not data.rows then
                return false
            end

            self.categorySelected = 0
            self.worksTree = self:HandleWorldsTree(data.rows)
            MainPage:GetNode('worksTree'):SetAttribute('DataSource', data.rows)
            self:Refresh()
        end
    )
end

function MainPage:HandleWorldsTree(rows)
    if not rows or type(rows) ~= 'table' then
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
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    if not ProjectsDatabase:IsProjectDownloaded(curItem.id) then
        Projects:GetProjectDetailById(curItem.id, function(data, err)
            if not data or not data.world or not data.world.archiveUrl or err ~= 200 then
                return false
            end

            local archiveUrl = data.world.archiveUrl

            FileDownloader:new():Init(
                nil,
                archiveUrl,
                format("/worlds/DesignHouse/userworlds/%s_r.zip", string.match(archiveUrl, "(.+)%.zip%?ref.+$"):gsub("[%W%s]+", "_")),
                function(bSuccess, downloadPath)
                    if bSuccess then
                        ProjectsDatabase:SetDownloadedProject(data)
                        self:HandleWorldsTree(self.worksTree)
                        self:Refresh()
                    end
                end,
                "access plus 5 mins",
                true
            )
        end)
    end
end

function MainPage:SetFavorite(index)
    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    if not ProjectsDatabase:IsFavoriteProject(curItem.id) then
        ProjectsDatabase:SetFavoriteProject(curItem.id)
    else
        ProjectsDatabase:RemoveFavoriteProject(curItem.id)
    end

    self:HandleWorldsTree(self.worksTree)
    self:Refresh()
end

function MainPage:SetCoins()
    Password:ShowPage()
end

function MainPage:SelectProject(index)
    if self.playerBalance <= 0 then
        GameOver:ShowPage(3)
        return false
    end

    local curItem = self.worksTree[index]

    if not curItem or not curItem.id then
        return false
    end

    if not ProjectsDatabase:IsProjectDownloaded(curItem.id) then
        return false
    end

    local projectInfo = ProjectsDatabase:GetDownloadedProject(curItem.id)

    if not projectInfo or not projectInfo.world then
        return false
    end

    world = RemoteWorld.LoadFromHref(projectInfo.world.archiveUrl, "self")
    world:GetLocalFileName()

    local mytimer = commonlib.Timer:new(
        {
            callbackFunc = function(timer)
                InternetLoadWorld.LoadWorld(
                    world,
                    nil,
                    "never",
                    function(bSucceed, localWorldPath)
                        if bSucceed then
                            self.playerBalance = self.playerBalance - 1
                            Wallet:SetPlayerBalance(self.playerBalance)
                            MainPage:Close()

                            Utils.SetTimeOut(
                                function()
                                    TimeUp:ShowPage()
                                end,
                                5000
                            )
                        end
                    end
                );
            end
        }
    );

    -- prevent recursive calls.
    mytimer:Change(1,nil);
end

function MainPage:GetSortIndex()
    return Store:Get('explorer/selectSortIndex')
end

function MainPage:GetSortList()
    return Store:Get('explorer/sortList')
end
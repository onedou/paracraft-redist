--[[
Title: Toast Component
Author(s):  big
Date: 2019.01.26
Place: Foshan
use the lib:
------------------------------------------------------------
local Toast = NPL.load("(gl)Mod/ExplorerApp/components/Toast/Toast.lua")
------------------------------------------------------------
]]
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

local Toast = NPL.export()

Toast.msg = ''
Toast.allPreviousMsg = {}

function Toast:ShowPage(msg)
    local index = #self.allPreviousMsg + 1
    local ToastPage = Store:Get("page/Toast")

    if ToastPage then
        self:ClosePage()

        if #self.allPreviousMsg > 0 then
            self.allPreviousMsg[#self.allPreviousMsg] = false
        end
    end

    self.allPreviousMsg[index] = true
    self.msg = msg

    local params = Utils:ShowWindow(180, 32, "Mod/ExplorerApp/components/Toast/Toast.html", "Mod.ExplorerApp.Toast", nil, nil, "_ct", false, 3)

    Utils.SetTimeOut(
        function()
            if self.allPreviousMsg[index] then
                self:ClosePage()
                self.allPreviousMsg = {}
            end
        end,
        3000
    )
end

function Toast:SetPage()
    Store:Set("page/Toast", document:GetPageCtrl())
end

function Toast:ClosePage()
    local ToastPage = Store:Get("page/Toast")

    if ToastPage then
        ToastPage:CloseWindow()
        Store:Remove("page/Toast")
    end
end
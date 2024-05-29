-- Copyright (c) 2024 Metatable Games
-- License: MIT

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local InventorySave = DataStoreService:GetDataStore("InventorySave")

local Tools: Folder = ServerStorage:WaitForChild("Tools")
local DuplicatesAllowed: boolean = false

function save(Player: Player): boolean
    local loadSuc: boolean, data: {}? = pcall(function()
        return InventorySave:SetAsync(Player.UserId)
    end)

    if not loadSuc or loadSuc and data == nil then
        data = {}
    end

    if data[Player.Team.Name] == nil then
        data[Player.Team.Name] = {}
    end

    for _, v: Instance? in pairs(Player.Backpack:GetChildren()) do
        if not v:IsA("Tool") or CollectionService:HasTag(v, "DO_NOT_SAVE") then
            continue
        end

        if table.find(data[Player.Team.Name], v.Name) then
            continue
        end

        table.insert(data[Player.Team.Name], v.Name)
    end

    local saveSuc: boolean, saveErr: string | nil = pcall(function()
        InventorySave:SetAsync(Player.UserId, data)
    end)

    if not saveSuc then
        warn(("An error occured while attempting to save to DB 'InventorySave' with Key '%d' due to: %s"):format(Player.UserId, saveErr))
        return false
    end

    return true
end

function load(Player: Player): nil
    local loadSuc: boolean, data: {}? = pcall(function()
        return InventorySave:SetAsync(Player.UserId)
    end)

    if not loadSuc or loadSuc and data == nil then
        return
    end

    if data[Player.Team.Name] == nil then
        return
    end

    for _, ToolName: string in pairs(data[Player.Team.Name]) do
        local Tool = Tools:FindFirstChild(ToolName)

        if not Tool or (Tool and not Tool:IsA("Tool")) or (Tool and not DuplicatesAllowed and Player.Backpack:FindFirstChild(ToolName)) then
            continue
        end

        Tool:Clone().Parent = Player.Backpack
    end
end

Players.PlayerAdded:Connect(function(Player: Player)
    Player.Chatted:Connect(function(message: string)
        if message == "/clearsave" then
            pcall(function()
                InventorySave:SetAsync(Player.UserId, {})
            end)
        end

        if message == "/save" then
            save(Player)
        end
    end)

    Player.CharacterAdded:Connect(function()
        local _ = Player.Character or Player.CharacterAdded:Wait()
        load(Player)
    end)
end)

local EggHub = getgenv().EggHub or {}
local config = {
    autoskip      = EggHub.autoskip,
    SellAllTower  = EggHub.SellAllTower,
    AtWave        = EggHub.AtWave,
    autoCommander = EggHub.autoCommander,
    macroURL      = EggHub.MarcoUrl,
    replay        = EggHub.replay
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Players           = game:GetService("Players")
local player            = Players.LocalPlayer

local remoteFunction    = ReplicatedStorage:WaitForChild("RemoteFunction")
local remoteEvent       = ReplicatedStorage:WaitForChild("RemoteEvent")
local towerFolder       = workspace:WaitForChild("Towers")

local vu = game:GetService("VirtualUser")
player.Idled:Connect(function()
    vu:Button2Down(Vector2.new(), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
end)

local skipVotingFlag = false
local function skipVoting()
    task.spawn(function()
        while skipVotingFlag do
            pcall(function() remoteFunction:InvokeServer("Voting","Skip") end)
            task.wait(1)
        end
    end)
end

local function firstskip()
    skipVotingFlag = true
    skipVoting()
    task.spawn(function()
        task.wait(5)
        skipVotingFlag = false
    end)
end

local gui       = player.PlayerGui

local hotbar    = gui:WaitForChild("ReactUniversalHotbar")
local hotbarFrame = hotbar.Frame
local hotbarValues = hotbarFrame:WaitForChild("values")
local cashLabel = hotbarValues:WaitForChild("cash"):WaitForChild("amount")

local topDisplay = gui:WaitForChild("ReactGameTopGameDisplay")
local topFrame   = topDisplay:WaitForChild("Frame")
local wave       = topFrame:WaitForChild("wave")
local waveContainer = wave:WaitForChild("container")

local rewardsGui   = gui:WaitForChild("ReactGameNewRewards")
local rewardsFrame = rewardsGui:WaitForChild("Frame")
local gameOverGui  = rewardsFrame:WaitForChild("gameOver")

local function getCash()
    local t = cashLabel.Text or ""
    return tonumber(t:gsub("[^%d%-]",""))
end

local function waitForCash(amount)
    while getCash() < amount do task.wait(1) end
end

local function safeInvoke(args, cost)
    waitForCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(0.5)
end

local function isSamePos(a, b, eps)
    eps = eps or 0.05
    return math.abs(a.X-b.X)<=eps and math.abs(a.Y-b.Y)<=eps and math.abs(a.Z-b.Z)<=eps
end

function place(x, y, z, name, cost)
    safeInvoke({"Troops","Pl\208\176ce",{Rotation=CFrame.new(), Position=Vector3.new(x,y,z)}, name}, cost)
end

function upgrade(x, y, z, cost)
    local pos = Vector3.new(x,y,z)
    for _, t in ipairs(towerFolder:GetChildren()) do
        local tPos = (t.PrimaryPart and t.PrimaryPart.Position) or t.Position
        if isSamePos(tPos, pos) then
            safeInvoke({"Troops","Upgrade","Set",{Troop=t}}, cost)
            break
        end
    end
end

local function GetTowerPosition(tower)
    for _, v in ipairs(tower:GetDescendants()) do
        if v:IsA("BasePart") then return v.Position end
    end
end

local function SetTarget(x, y, z, mode)
    local pos = Vector3.new(x,y,z)
    mode = mode or "Random"
    local towers = towerFolder:GetChildren()
    local closest, dist = nil, math.huge

    for _, tower in ipairs(towers) do
        local tPos = GetTowerPosition(tower)
        if tPos then
            local d = (tPos - pos).Magnitude
            if d < dist then
                dist = d
                closest = tower
            end
        end
    end

    if closest then
        remoteFunction:InvokeServer("Troops","Target","Set",{Target=mode, Troop=closest})
    end
end

local function DJChange(color)
    pcall(function()
        remoteFunction:InvokeServer("Troops","Option","Set",{
            Value = color,
            Name  = "Track",
            Troop = workspace.Towers.Default
        })
    end)
end

function sell(x, y, z)
    local pos = Vector3.new(x,y,z)
    for _, t in ipairs(towerFolder:GetChildren()) do
        local tPos = (t.PrimaryPart and t.PrimaryPart.Position) or t.Position
        if isSamePos(tPos, pos) then
            pcall(function()
                remoteFunction:InvokeServer("Troops","Se\108\108",{Troop=t})
            end)
            break
        end
    end
end

function sellAllTowers()
    for _, t in ipairs(towerFolder:GetChildren()) do
        pcall(function()
            remoteFunction:InvokeServer("Troops","Se\108\108",{Troop=t})
        end)
        task.wait(0.1)
    end
end

local function getWave()
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            local n = tonumber(label.Text:match("^(%d+)"))
            if n then return n end
        end
    end
end

local function loadMacro(url)
    local code = game:HttpGet(url)
    local f    = loadstring(code)
    if f then pcall(f) end
end

local macroLoaded = false
for _, label in ipairs(waveContainer:GetDescendants()) do
    if label:IsA("TextLabel") then
        label:GetPropertyChangedSignal("Text"):Connect(function()
            local wave = getWave()
            if wave == 1 and not macroLoaded then
                macroLoaded = true
                task.spawn(function()
                    loadMacro(config.macroURL)
                end)
            end
            if wave == config.AtWave and config.SellAllTower then
                sellAllTowers()
            end
        end)
    end
end

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        macroLoaded = false
        if config.replay then
            task.wait(2)
            firstskip()
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if config.autoskip then
            pcall(function() remoteFunction:InvokeServer("Voting","Skip") end)
        end
    end
end)

task.spawn(function()
    local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    while task.wait(10) do
        if config.autoCommander and ok and vim and vim.SendKeyEvent then
            pcall(function()
                vim:SendKeyEvent(true, Enum.KeyCode.F,false,game)
                task.wait()
                vim:SendKeyEvent(false, Enum.KeyCode.F,false,game)
            end)
        end
    end
end)

local waveValueLabel = waveContainer:FindFirstChild("value") or waveContainer:FindFirstChild("Value")
if waveValueLabel then
    local teleported = false
    local targetWaves = {["25/25"]=true, ["30/30"]=true, ["35/35"]=true}

    local function checkValue()
        if teleported then return end
        local s = (waveValueLabel.Text or ""):gsub("%s+","")
        if targetWaves[s] then
            teleported = true
            TeleportService:Teleport(3260590327, player)
        end
    end

    waveValueLabel:GetPropertyChangedSignal("Text"):Connect(checkValue)
end

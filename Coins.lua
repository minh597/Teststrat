repeat task.wait() until game:IsLoaded()
local config = {
    autoskip = true,
    SellAllTower = true,
    AtWave = 15,
    autoCommander = true,
    replay = true
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
if workspace:FindFirstChild("Elevators") then
    local args = {
        [1] = "Multiplayer",
        [2] = "v2:start",
        [3] = {
            ["count"] = 1,
            ["mode"] = "halloween"
        }
    }
    remoteFunction:InvokeServer(unpack(args))
else
    remoteFunction:InvokeServer("Voting", "Skip")
    task.wait(1)
end


local towerFolder = workspace:WaitForChild("Towers")

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
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
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

local gui = player.PlayerGui
local hotbar = gui:WaitForChild("ReactUniversalHotbar")
local hotbarFrame = hotbar.Frame
local hotbarValues = hotbarFrame:WaitForChild("values")
local cashLabel = hotbarValues:WaitForChild("cash"):WaitForChild("amount")

local topDisplay = gui:WaitForChild("ReactGameTopGameDisplay")
local topFrame = topDisplay:WaitForChild("Frame")
local wave = topFrame:WaitForChild("wave")
local waveContainer = wave:WaitForChild("container")

local rewardsGui = gui:WaitForChild("ReactGameNewRewards")
local rewardsFrame = rewardsGui:WaitForChild("Frame")
local gameOverGui = rewardsFrame:WaitForChild("gameOver")

local function getCash()
    local t = cashLabel.Text
    if not t then return 0 end

    t = t:gsub(",", ""):upper()

    local num = tonumber(t:match("[%d%.]+"))
    if not num then return 0 end

    if t:find("K") then
        num *= 1e3
    elseif t:find("M") then
        num *= 1e6
    elseif t:find("B") then
        num *= 1e9
    end

    return math.floor(num)
end
local function waitForCash(amount)
    while getCash() < amount do
        task.wait(1)
    end
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
    return math.abs(a.X - b.X) <= eps and math.abs(a.Y - b.Y) <= eps and math.abs(a.Z - b.Z) <= eps
end

function place(x, y, z, name, cost)
    safeInvoke({ "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(x, y, z) }, name }, cost)
end

function upgrade(x, y, z, cost)
    local pos = Vector3.new(x, y, z)
    for _, t in ipairs(towerFolder:GetChildren()) do
        local tPos = (t.PrimaryPart and t.PrimaryPart.Position) or t.Position
        if isSamePos(tPos, pos) then
            safeInvoke({ "Troops", "Upgrade", "Set", { Troop = t } }, cost)
            break
        end
    end
end

local function GetTowerPosition(tower)
    for _, v in ipairs(tower:GetDescendants()) do
        if v:IsA("BasePart") then
            return v.Position
        end
    end
end

function SetTarget(x, y, z, mode)
    local pos = Vector3.new(x, y, z)
    local closest, dist = nil, math.huge
    for _, tower in ipairs(towerFolder:GetChildren()) do
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
        remoteFunction:InvokeServer("Troops", "Target", "Set", { Target = mode or "Random", Troop = closest })
    end
end

function sellAllTowers()
    for _, t in ipairs(towerFolder:GetChildren()) do
        pcall(function()
            remoteFunction:InvokeServer("Troops", "Se\108\108", { Troop = t })
        end)
        task.wait(0.1)
    end
end

local function getWave()
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            local n = tonumber(label.Text:match("^(%d+)"))
            if n then
                return n
            end
        end
    end
end

local macroLoaded = false

local function loadMacro()
    place(4.210, 1.037, -33.838, "Shotgunner", 300)
place(-1.109, 1.037, -33.280, "Shotgunner", 300)
place(4.533, 1.037, -35.858, "Shotgunner", 300)
place(-1.045, 1.037, -35.605, "Shotgunner", 300)
place(4.417, 1.037, -31.801, "Shotgunner", 300)
place(-0.808, 1.037, -30.965, "Shotgunner", 300)
place(6.924, 1.037, -32.344, "Trapper", 500)
place(7.266, 1.037, -35.451, "Trapper", 500)
upgrade(4.533, 2.387, -35.858, 150)
upgrade(4.210, 2.387, -33.838, 150)
upgrade(4.417, 2.387, -31.801, 150)
upgrade(-0.808, 2.387, -30.965, 150)
upgrade(-1.109, 2.387, -33.280, 150)
upgrade(-1.045, 2.387, -35.605, 150)
place(8.881, 1.037, -29.715, "Trapper", 500)
place(7.613, 1.037, -24.157, "Trapper", 500)
upgrade(-1.109, 2.387, -33.280, 950)
upgrade(7.613, 2.387, -24.157, 500)
place(4.346, 1.037, -24.632, "Trapper", 500)
place(1.168, 1.037, -25.220, "Trapper", 500)
place(7.758, 1.037, -20.911, "Trapper", 500)
upgrade(4.210, 2.387, -33.838, 950)
upgrade(4.533, 2.387, -35.858, 950)
upgrade(4.417, 2.387, -31.801, 950)
upgrade(1.168, 2.387, -25.220, 500)
place(-0.523, 1.037, -28.646, "Shotgunner", 300)
upgrade(-0.523, 2.387, -28.646, 150)
upgrade(-0.523, 2.387, -28.646, 950)
upgrade(8.881, 2.387, -29.715, 500)
upgrade(6.924, 2.387, -32.344, 500)
upgrade(7.266, 2.387, -35.451, 500)
upgrade(4.346, 2.387, -24.632, 500)
upgrade(4.346, 2.387, -24.632, 1500)
upgrade(-0.808, 2.387, -30.965, 950)
end

for _, label in ipairs(waveContainer:GetDescendants()) do
    if label:IsA("TextLabel") then
        label:GetPropertyChangedSignal("Text"):Connect(function()
            local w = getWave()
            if w == 1 and not macroLoaded then
                macroLoaded = true
                task.spawn(loadMacro)
            end
            if w == config.AtWave and config.SellAllTower then
                sellAllTowers()
            end
        end)
    end
end

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        TeleportService:Teleport(3260590327, player)
        if config.replay then
            task.wait(2)
            firstskip()
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if config.autoskip then
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
        end
    end
end)

task.spawn(function()
    local ok, vim = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    while task.wait(10) do
        if config.autoCommander and ok and vim and vim.SendKeyEvent then
            vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait()
            vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end
    end
end)

local waveValueLabel = waveContainer:FindFirstChild("value") or waveContainer:FindFirstChild("Value")
if waveValueLabel then
    local teleported = false
    local targetWaves = { ["25/25"] = true, ["30/30"] = true, ["35/35"] = true }
    local function checkValue()
        if teleported then
            return
        end
        local s = (waveValueLabel.Text or ""):gsub("%s+", "")
        if targetWaves[s] then
            teleported = true
            TeleportService:Teleport(3260590327, player)
        end
    end
    waveValueLabel:GetPropertyChangedSignal("Text"):Connect(checkValue)
end

local EggHub = getgenv().EggHub or {}
local config = {
    autoskip = EggHub.autoskip,
    SellAllTower = EggHub.SellAllTower,
    AtWave = EggHub.AtWave,
    autoCommander = EggHub.autoCommander,
    difficulty = EggHub.Difficulty,
    map = EggHub.Map,
    replay = EggHub.Replay,
    macroURL = EggHub.MacroUrl
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local vu = game:GetService("VirtualUser")

player.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
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
    skipVotingFlag=true
    skipVoting()
    task.spawn(function() task.wait(5) skipVotingFlag=false end)
end

task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    if workspace:FindFirstChild("Elevators") then
        remoteFunction:InvokeServer("Multiplayer","v2:start",{count=1, mode="survival", difficulty=config.difficulty})
    else
        task.wait(10)
        remoteFunction:InvokeServer("LobbyVoting","Override",config.map)
        remoteEvent:FireServer("LobbyVoting","Vote",config.map,Vector3.new(14.947,9.6,55.556))
        remoteEvent:FireServer("LobbyVoting","Ready")
        task.wait(7)
        remoteFunction:InvokeServer("Voting","Skip")
        task.wait(1)
    end
end)

local towerFolder = workspace:WaitForChild("Towers")
local cashLabel = player.PlayerGui:WaitForChild("ReactUniversalHotbar"):WaitForChild("Frame"):WaitForChild("values"):WaitForChild("cash"):WaitForChild("amount")
local waveContainer = player.PlayerGui:WaitForChild("ReactGameTopGameDisplay"):WaitForChild("Frame"):WaitForChild("wave"):WaitForChild("container")
local gameOverGui = player.PlayerGui:WaitForChild("ReactGameNewRewards"):WaitForChild("Frame"):WaitForChild("gameOver")

local function getCash()
    local text = cashLabel.Text or ""
    local cleanText = text:gsub("[^%d]", "")
    local num = tonumber(cleanText)
    return num or 0
end

local function waitForCash(amount)
    while getCash() < amount do
        task.wait(0.5)
    end
end

local function isSamePos(a,b,eps)
    eps=eps or 0.05
    return (a-b).Magnitude<=eps
end

local function findTowerAtPosition(x,y,z)
    local pos = Vector3.new(x,y,z)
    for _,t in ipairs(towerFolder:GetChildren()) do
        local tPos = (t.PrimaryPart and t.PrimaryPart.Position) or t.Position
        if isSamePos(tPos,pos) then return t end
    end
    return nil
end

local function place(x,y,z,name,cost)
    waitForCash(cost)
    local args = {"Troops","Place",{Rotation=CFrame.new(),Position=Vector3.new(x,y,z)},name}
    pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
    task.wait(0.5)
end

local function upgrade(x,y,z,path,cost)
    waitForCash(cost)
    local t=findTowerAtPosition(x,y,z)
    if t then
        local args={"Troops","Upgrade","Set",{Troop=t,Path=path}}
        pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
        task.wait(0.5)
    end
end

local function sell(x,y,z)
    local t=findTowerAtPosition(x,y,z)
    if t then
        pcall(function() remoteFunction:InvokeServer("Troops","Sell",{Troop=t}) end)
    end
end

local function SetTower(x,y,z,value,name)
    local t=findTowerAtPosition(x,y,z)
    if t then
        pcall(function() remoteFunction:InvokeServer("Troops","Option","Set",{Value=value,Name=name,Troop=t}) end)
    end
end

local function SetTarget(x,y,z,targetMode)
    targetMode=targetMode or "Random"
    local t=findTowerAtPosition(x,y,z)
    if t then
        pcall(function() remoteFunction:InvokeServer("Troops","Target","Set",{Target=targetMode,Troop=t}) end)
    end
end

local function ability(x,y,z,name)
    local t=findTowerAtPosition(x,y,z)
    if t then
        pcall(function() remoteFunction:InvokeServer("Troops","Abilities","Activate",{Troop=t,Data={},Name=name}) end)
    end
end

local function Ability1(x,y,z,pathName,dirX,dirY,dirZ,pointToEnd,name)
    local t=findTowerAtPosition(x,y,z)
    if t then
        local pos = Vector3.new(x,y,z)
        local dirVec = Vector3.new(dirX,dirY,dirZ)
        local dirCFrame=CFrame.new(pos,dirVec)
        pcall(function()
            remoteFunction:InvokeServer("Troops","Abilities","Activate",{
                Troop=t,
                Data={
                    directionCFrame=dirCFrame,
                    pathName=pathName,
                    pointToEnd=pointToEnd
                },
                Name=name
            })
        end)
    end
end

local function Ability2(x,y,z,tx,ty,tz,name)
    local t=findTowerAtPosition(x,y,z)
    if t then
        pcall(function()
            remoteFunction:InvokeServer("Troops","Abilities","Activate",{
                Troop=t,
                Data={position=Vector3.new(tx,ty,tz)},
                Name=name
            })
        end)
    end
end

local function Ability3(x,y,z,tx,ty,tz,rx,ry,rz,name)
    local t=findTowerAtPosition(x,y,z)
    local tClone=findTowerAtPosition(tx,ty,tz)
    if t and tClone then
        pcall(function()
            remoteFunction:InvokeServer("Troops","Abilities","Activate",{
                Troop=t,
                Data={
                    towerToClone=tClone,
                    towerPosition=Vector3.new(rx,ry,rz)
                },
                Name=name
            })
        end)
    end
end

getgenv().place = place
getgenv().upgrade = upgrade
getgenv().sell = sell
getgenv().SetTower = SetTower
getgenv().SetTarget = SetTarget
getgenv().ability = ability
getgenv().Ability1 = Ability1
getgenv().Ability2 = Ability2
getgenv().Ability3 = Ability3

local function sellAllTowers()
    for _,t in ipairs(towerFolder:GetChildren()) do
        pcall(function() remoteFunction:InvokeServer("Troops","Sell",{Troop=t}) end)
        task.wait(0.1)
    end
end

local function getWave()
    for _,label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            local n=tonumber(label.Text:match("^(%d+)"))
            if n then return n end
        end
    end
    return nil
end

local function loadMacro(url)
    if not url or url == "" then 
        warn("Macro URL invalid")
        return 
    end
    
    local success, code = pcall(function() 
        return game:HttpGet(url, true) 
    end)
    
    if not success then 
        warn("Cannot load macro from URL:", code)
        return 
    end
    
    if not code or code == "" then
        warn("Macro URL returned empty content")
        return
    end
    
    local func, err = loadstring(code)
    if not func then 
        warn("Error loading macro:", err)
        return 
    end
    
    local runSuccess, runErr = pcall(func)
    if not runSuccess then
        warn("Error running macro:", runErr)
    else
        print("Macro loaded and running successfully!")
    end
end

local macroLoaded = false
local waveConnection

local function setupWaveListener()
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            waveConnection = label:GetPropertyChangedSignal("Text"):Connect(function()
                local wave = getWave()
                
                if wave == 1 and not macroLoaded and config.macroURL then
                    macroLoaded = true
                    print("Wave 1 detected, loading macro...")
                    loadMacro(config.macroURL) 
                end
                
                if wave == config.AtWave and config.SellAllTower and config.AtWave > 0 then
                    print("Reached wave", config.AtWave, "- Selling all towers...")
                    sellAllTowers()
                end
            end)
            break
        end
    end
end

setupWaveListener()

if not waveConnection then
    waveContainer.ChildAdded:Connect(function()
        task.wait(0.5)
        if not waveConnection then
            setupWaveListener()
        end
    end)
end

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        macroLoaded=false
        if config.replay then
            task.wait(2)
            firstskip()
        else
            task.wait(3)
            TeleportService:Teleport(game.PlaceId,player)
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
    local success,vim=pcall(function() return game:GetService("VirtualInputManager") end)
    while task.wait(10) do
        if config.autoCommander and success and vim and vim.SendKeyEvent then
            pcall(function()
                vim:SendKeyEvent(true,Enum.KeyCode.F,false,game)
                task.wait(0.00001)
                vim:SendKeyEvent(false,Enum.KeyCode.F,false,game)
            end)
        end
    end
end)

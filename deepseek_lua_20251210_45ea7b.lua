-- KAITUN AUTO-FARM BOT - NO BUTTONS, JUST EXECUTE
-- Auto teleport to arena and start farming immediately

repeat task.wait() until game:IsLoaded()
task.wait(2)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

print("🚀 KAITUN AUTO-FARM STARTING...")

-- Simple anti-kick
pcall(function()
    local oldnc = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == Player then
            return nil
        end
        return oldnc(self, ...)
    end)
end)

-- Auto-teleport to arena
print("🔍 Searching for arena teleport...")
local function TeleportToArena()
    -- Try exact path first
    local importantParts = Workspace:FindFirstChild("ImportantParts")
    if importantParts then
        local arenaPart = importantParts:FindFirstChild("ArenaTeleportPart")
        if arenaPart then
            local touchInterest = arenaPart:FindFirstChild("TouchInterest")
            if touchInterest then
                print("🎯 Found ArenaTeleportPart! Teleporting...")
                
                local char = Player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    
                    -- Move to the teleport part
                    hrp.CFrame = arenaPart.CFrame + Vector3.new(0, 5, 0)
                    task.wait(0.5)
                    
                    -- Activate touch interest
                    pcall(function()
                        if touchInterest:IsA("TouchTransmitter") then
                            -- Just need to touch the part
                            hrp.CFrame = arenaPart.CFrame
                        else
                            touchInterest:Fire()
                        end
                    end)
                    
                    print("✅ Successfully teleported to arena!")
                    return true
                end
            end
        end
    end
    
    -- Alternative search
    print("⚠️ Searching alternative paths...")
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("arena") and obj:IsA("BasePart") then
            print("🎯 Found arena part: " .. obj.Name)
            
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                hrp.CFrame = obj.CFrame + Vector3.new(0, 5, 0)
                task.wait(1)
                print("✅ Moved to arena area")
                return true
            end
        end
    end
    
    print("❌ Could not find arena, will farm from current location")
    return false
end

-- Find attack remotes
local AttackRemotes = {}
local function SetupAttacks()
    print("📡 Setting up attack system...")
    
    -- Search for combat remotes
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            local name = obj.Name:lower()
            if name:find("hit") or name:find("damage") or name:find("attack") then
                table.insert(AttackRemotes, obj)
            end
        end
    end
    
    print("✅ Found " .. #AttackRemotes .. " attack remotes")
end

-- Simple status GUI
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "KaitunAutoFarm"
sg.ResetOnSpawn = false

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 300, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(15,15,25)
frame.BackgroundTransparency = 0.2
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Text = "🤖 KAITUN AUTO-FARM"
title.Size = UDim2.new(1,0,0,40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0,255,150)
title.TextScaled = true
title.Font = Enum.Font.GothamBold

local status = Instance.new("TextLabel", frame)
status.Text = "STARTING..."
status.Position = UDim2.new(0,0,0,45)
status.Size = UDim2.new(1,0,0,25)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(255,255,100)
status.TextScaled = true

local kills = Instance.new("TextLabel", frame)
kills.Text = "KILLS: 0"
kills.Position = UDim2.new(0,0,0,75)
kills.Size = UDim2.new(1,0,0,20)
kills.BackgroundTransparency = 1
kills.TextColor3 = Color3.fromRGB(100,200,255)
kills.TextScaled = true

-- Variables
local TotalKills = 0
local Farming = true
local Weapon = nil

-- Update GUI
local function UpdateGUI()
    status.Text = "FARMING..."
    kills.Text = "KILLS: " .. TotalKills
end

-- Auto farm function
local function StartAutoFarm()
    print("⚡ Auto-farming started!")
    
    while Farming do
        task.wait(0.1)
        
        -- Get character
        local char = Player.Character
        if not char then
            task.wait(1)
            continue
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        
        if not hrp or not humanoid or humanoid.Health <= 0 then
            task.wait(2)
            continue
        end
        
        -- Auto equip weapon
        if not Weapon or not Weapon.Parent then
            -- Check character
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    Weapon = tool
                    break
                end
            end
            
            -- Check backpack
            if not Weapon then
                for _, tool in pairs(Player.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = char
                        Weapon = tool
                        break
                    end
                end
            end
        end
        
        -- Find closest target
        local closestTarget = nil
        local closestDist = 9999
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and player.Character then
                local targetChar = player.Character
                local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                
                if targetHrp and targetHumanoid and targetHumanoid.Health > 0 then
                    local dist = (hrp.Position - targetHrp.Position).Magnitude
                    if dist < closestDist and dist < 200 then
                        closestDist = dist
                        closestTarget = player
                    end
                end
            end
        end
        
        -- Attack if target found
        if closestTarget and closestTarget.Character and Weapon then
            local targetChar = closestTarget.Character
            local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
            
            if targetHrp then
                -- Move closer
                if closestDist > 10 then
                    local direction = (targetHrp.Position - hrp.Position).Unit
                    hrp.CFrame = hrp.CFrame + (direction * 2)
                end
                
                -- Face target
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(
                    targetHrp.Position.X, 
                    hrp.Position.Y, 
                    targetHrp.Position.Z
                ))
                
                -- Attack when close
                if closestDist < 20 then
                    -- Use tool
                    pcall(function()
                        if Weapon:FindFirstChild("Activated") then
                            Weapon.Activated:Fire()
                        end
                    end)
                    
                    -- Use remotes
                    for _, remote in pairs(AttackRemotes) do
                        pcall(function()
                            if remote:IsA("RemoteEvent") then
                                remote:FireServer(targetChar)
                            end
                        end)
                    end
                    
                    -- Check if killed
                    local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                    if targetHumanoid and targetHumanoid.Health <= 0 then
                        TotalKills = TotalKills + 1
                        print("💀 Kill #" .. TotalKills)
                        UpdateGUI()
                    end
                end
            end
        else
            -- Wait if no targets
            task.wait(0.5)
        end
    end
end

-- Server hop every 5 minutes
spawn(function()
    while true do
        task.wait(300) -- 5 minutes
        
        print("🔄 Server hopping...")
        
        -- Find new server
        pcall(function()
            local servers = {}
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
                ))
            end)
            
            if success and result.data then
                for _, server in pairs(result.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server.id)
                    end
                end
                
                if #servers > 0 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)])
                else
                    TeleportService:Teleport(game.PlaceId)
                end
            end
        end)
    end
end)

-- Auto-rejoin on kick
spawn(function()
    Players.PlayerRemoving:Connect(function(plr)
        if plr == Player then
            print("⚠️ Player removed, rejoining...")
            task.wait(5)
            TeleportService:Teleport(game.PlaceId)
        end
    end)
    
    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            task.wait(3)
            TeleportService:Teleport(game.PlaceId)
        end
    end)
end)

-- MAIN EXECUTION FLOW
spawn(function()
    -- Step 1: Teleport to arena
    TeleportToArena()
    
    -- Step 2: Setup attacks
    task.wait(2)
    SetupAttacks()
    
    -- Step 3: Start farming
    task.wait(1)
    UpdateGUI()
    StartAutoFarm()
end)

print("="..string.rep("=", 60))
print("🤖 KAITUN AUTO-FARM BOT EXECUTED")
print("AUTO-TELEPORT TO ARENA: DONE")
print("AUTO-FARMING: STARTED")
print("SERVER HOP EVERY 5 MIN: ENABLED")
print("AUTO-REJOIN: ENABLED")
print("="..string.rep("=", 60))
print("✅ SCRIPT IS NOW RUNNING - NO BUTTONS NEEDED")
print("✅ FARMING AUTOMATICALLY")
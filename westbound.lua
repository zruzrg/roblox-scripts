--[[
    WESTBOUND FINAL EDITION (2025)
    Optimization: 100% (Event-Based Caching)
    Design: Glassmorphism / Transparent
    Features: Instant TP, Ghost Mode, Mobile Support
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local StatsService = game:GetService("Stats")

-- // SYSTEM VARIABLES //
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

local BagState = LocalPlayer:WaitForChild("States"):WaitForChild("Bag")
local BagLevel = LocalPlayer:WaitForChild("Stats"):WaitForChild("BagSizeLevel"):WaitForChild("CurrentAmount")
local RobEvent = ReplicatedStorage:WaitForChild("GeneralEvents"):WaitForChild("Rob")
local CashStat = LocalPlayer:WaitForChild("leaderstats"):WaitForChild("$$")

local InitialCash = CashStat.Value
local StartTime = tick()
local SellCFrame = CFrame.new(1636.6, 104.3, -1736.2)

-- // SETTINGS & STATE //
local State = {
    Active = false,
    Selling = false,
    Character = nil,
    Root = nil
}

-- // CLEANUP OLD UI //
if getgenv().WB_Final then getgenv().WB_Final:Destroy() end

-- // UI CONSTRUCTION (TRANSPARENT & MODERN) //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WestboundFinalUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
getgenv().WB_Final = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(350, 220)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
-- ŞEFFAF TASARIM (TRANSPARENT)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.BackgroundTransparency = 0.25 
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 16)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Thickness = 1.2
UIStroke.Color = Color3.fromRGB(255, 170, 0) -- Gold Accent
UIStroke.Transparency = 0.3

-- Blur Effect (For Glass Look)
local Blur = Instance.new("ImageLabel", MainFrame)
Blur.Size = UDim2.new(1, 0, 1, 0)
Blur.BackgroundTransparency = 1
Blur.Image = "rbxassetid://8992230677" -- Blur texture overlay
Blur.ImageTransparency = 0.8
Blur.ZIndex = 0
local BlurCorner = Instance.new("UICorner", Blur)
BlurCorner.CornerRadius = UDim.new(0, 16)

-- Dragging Logic (Mobile Optimized)
local dragging, dragStart, startPos
local function UpdateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateDrag(input)
    end
end)

-- UI Elements
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -30, 0, 40)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "WESTBOUND"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", MainFrame)
SubTitle.Size = UDim2.new(1, -30, 0, 40)
SubTitle.Position = UDim2.new(0, 0, 0, 5)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "ULTIMATE"
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 14
SubTitle.TextColor3 = Color3.fromRGB(255, 170, 0)
SubTitle.TextXAlignment = Enum.TextXAlignment.Right
SubTitle.Parent = MainFrame

local Divider = Instance.new("Frame", MainFrame)
Divider.Size = UDim2.new(1, 0, 0, 1)
Divider.Position = UDim2.new(0, 0, 0, 45)
Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Divider.BackgroundTransparency = 0.85
Divider.BorderSizePixel = 0

-- Stats Grid
local StatsFrame = Instance.new("Frame", MainFrame)
StatsFrame.Size = UDim2.new(1, -30, 0, 100)
StatsFrame.Position = UDim2.new(0, 15, 0, 55)
StatsFrame.BackgroundTransparency = 1

local function CreateInfo(text, pos)
    local l = Instance.new("TextLabel", StatsFrame)
    l.Size = UDim2.new(0.5, 0, 0, 25)
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 13
    l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local EarnedLbl = CreateInfo("Earned: $0", UDim2.new(0,0,0,0))
local TimeLbl = CreateInfo("Time: 00:00", UDim2.new(0,0,0,30))
local StatusLbl = CreateInfo("Status: Idle", UDim2.new(0,0,0,60))
local FPSLbl = CreateInfo("FPS: 60", UDim2.new(0.6,0,0,0))
local PingLbl = CreateInfo("Ping: 0ms", UDim2.new(0.6,0,0,30))

-- Button
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(1, -30, 0, 45)
ToggleBtn.Position = UDim2.new(0, 15, 1, -55)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
ToggleBtn.Text = "START FARMING"
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 16
ToggleBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
ToggleBtn.AutoButtonColor = true

local BtnCorner = Instance.new("UICorner", ToggleBtn)
BtnCorner.CornerRadius = UDim.new(0, 10)

-- // OPTIMIZATION: CACHE SYSTEM //
local Cache = {
    Registers = {},
    Safes = {}
}

local function AddToCache(obj)
    if obj:IsA("Model") then
        if obj.Name == "CashRegister" then
            table.insert(Cache.Registers, obj)
        elseif obj.Name == "Safe" then
            table.insert(Cache.Safes, obj)
        end
    end
end

local function RemoveFromCache(obj)
    if obj.Name == "CashRegister" then
        local idx = table.find(Cache.Registers, obj)
        if idx then table.remove(Cache.Registers, idx) end
    elseif obj.Name == "Safe" then
        local idx = table.find(Cache.Safes, obj)
        if idx then table.remove(Cache.Safes, idx) end
    end
end

-- Initialize Cache (Runs once)
for _, v in ipairs(Workspace:GetChildren()) do AddToCache(v) end

-- Event Listeners (No Loops!)
Workspace.ChildAdded:Connect(AddToCache)
Workspace.ChildRemoved:Connect(RemoveFromCache)

-- // LOGIC FUNCTIONS //

local function UpdateChar()
    local char = LocalPlayer.Character
    if char then
        State.Character = char
        State.Root = char:FindFirstChild("HumanoidRootPart")
        return true
    end
    return false
end

-- GHOST MODE (GOD MODE)
local function EnableGodMode()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        
        -- Clone Humanoid Trick
        local newHum = hum:Clone()
        newHum.Parent = char
        LocalPlayer.Character = nil 
        newHum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        newHum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:Destroy()
        LocalPlayer.Character = char
        
        Camera.CameraSubject = newHum
        newHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        local animate = char:FindFirstChild("Animate")
        if animate then animate.Disabled = true; task.wait(0.1); animate.Disabled = false end
    end)
end

local function InstantTP(cf)
    if State.Root then
        State.Root.Velocity = Vector3.zero -- Stop physics
        State.Root.CFrame = cf
    end
end

-- // MAIN FARM LOOP //
local function Farm()
    while State.Active do
        local success, err = pcall(function()
            if not UpdateChar() then return end
            
            -- 1. Check Bag
            if BagState.Value >= BagLevel.Value then
                State.Selling = true
                StatusLbl.Text = "Status: Selling..."
                StatusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                
                InstantTP(SellCFrame)
                -- Auto Interact
                VirtualUser:ClickButton1(Vector2.new(0,0))
                task.wait(0.3)
                return
            end
            
            State.Selling = false
            StatusLbl.Text = "Status: Hunting..."
            StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            -- 2. Find Nearest (Optimized Math)
            local myPos = State.Root.Position
            local target = nil
            local minSq = 99999999
            
            -- Scan Registers from Cache
            for _, reg in ipairs(Cache.Registers) do
                if reg.Parent and reg:FindFirstChild("Open") then
                    local distSq = (myPos - reg.Open.Position).Magnitude -- Squared is faster but Magnitude is fine here
                    if distSq < minSq then
                        minSq = distSq
                        target = {Obj = reg, Type = "Reg", Part = reg.Open}
                    end
                end
            end
            
            -- Scan Safes from Cache
            for _, safe in ipairs(Cache.Safes) do
                if safe.Parent and safe:FindFirstChild("Safe") and safe:FindFirstChild("Amount") and safe.Amount.Value > 0 then
                    local distSq = (myPos - safe.Safe.Position).Magnitude
                    if distSq < minSq then
                        minSq = distSq
                        target = {Obj = safe, Type = "Safe", Part = safe.Safe}
                    end
                end
            end
            
            -- 3. Execute
            if target then
                InstantTP(target.Part.CFrame)
                
                if target.Type == "Reg" then
                    RobEvent:FireServer("Register", {
                        Part = target.Obj.Union,
                        OpenPart = target.Obj.Open,
                        ActiveValue = target.Obj.Active,
                        Active = true
                    })
                else
                    if target.Obj:FindFirstChild("Open") and target.Obj.Open.Value then
                        RobEvent:FireServer("Safe", target.Obj)
                    else
                        if target.Obj:FindFirstChild("OpenSafe") then
                            target.Obj.OpenSafe:FireServer("Completed")
                        end
                        RobEvent:FireServer("Safe", target.Obj)
                    end
                end
            end
        end)
        
        task.wait(0.01) -- MAX SPEED
    end
end

-- // CONTROLS //
ToggleBtn.MouseButton1Click:Connect(function()
    State.Active = not State.Active
    
    if State.Active then
        ToggleBtn.Text = "STOP FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
        
        -- Reset Stats
        StartTime = tick()
        InitialCash = CashStat.Value
        
        UpdateChar()
        EnableGodMode() -- Activate God Mode
        
        task.spawn(Farm)
    else
        ToggleBtn.Text = "START FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        ToggleBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
        StatusLbl.Text = "Status: Stopped"
        StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- // STAT TRACKING LOOP //
task.spawn(function()
    while true do
        task.wait(1)
        if State.Active then
            local gain = CashStat.Value - InitialCash
            EarnedLbl.Text = "Earned: $" .. tostring(gain):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
            
            local now = tick() - StartTime
            local m = math.floor(now / 60)
            local s = math.floor(now % 60)
            TimeLbl.Text = string.format("Time: %02d:%02d", m, s)
        end
        FPSLbl.Text = "FPS: " .. math.floor(1 / RunService.RenderStepped:Wait())
        
        pcall(function()
             PingLbl.Text = "Ping: " .. math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms"
        end)
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Auto Re-Godmode on Respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.Active then EnableGodMode() end
end)

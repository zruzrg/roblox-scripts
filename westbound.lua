--[[
    WESTBOUND ADVANCED AUTO-FARM (2025 EDITION)
    Platform: PC & Mobile (Android/iOS)
    Optimized, Modern UI, Smooth Tweening
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StatsService = game:GetService("Stats")

-- // CONFIGURATION & VARIABLES //
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local BagState = LocalPlayer:WaitForChild("States"):WaitForChild("Bag")
local BagLevel = LocalPlayer:WaitForChild("Stats"):WaitForChild("BagSizeLevel"):WaitForChild("CurrentAmount")
local RobEvent = ReplicatedStorage:WaitForChild("GeneralEvents"):WaitForChild("Rob")

local CashStat = LocalPlayer:WaitForChild("leaderstats"):WaitForChild("$$")
local InitialCash = CashStat.Value
local StartTime = tick()

local GeneralSettings = {
    TweenSpeed = 35, -- Studs per second (Lower is safer/smoother)
    SellPosition = CFrame.new(1636.6, 104.3, -1736.2), -- Bank Sell Spot
    LoopDelay = 0.1,
    Radius = 10 -- Interaction radius
}

local State = {
    IsFarming = false,
    IsSelling = false,
    Target = nil
}

-- // CLEANUP PREVIOUS INSTANCES //
if getgenv().WB_Instance then
    getgenv().WB_Instance:Destroy()
end

-- // UI CREATION (MODERN & MOBILE FRIENDLY) //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WestboundAdvancedUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
getgenv().WB_Instance = ScreenGui

-- Blur Effect for Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(360, 230) -- Compact size for mobile
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Thickness = 1.5
UIStroke.Color = Color3.fromRGB(255, 180, 50) -- Westbound Gold
UIStroke.Transparency = 0.4

-- Draggable Logic (Mobile & PC)
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        update(input)
    end
end)

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0.05, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "WESTBOUND"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size = UDim2.new(0.3, 0, 1, 0)
SubTitle.Position = UDim2.new(0.65, 0, 0, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "AUTO-FARM"
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 12
SubTitle.TextColor3 = Color3.fromRGB(255, 180, 50)
SubTitle.TextXAlignment = Enum.TextXAlignment.Right

local Divider = Instance.new("Frame", MainFrame)
Divider.Size = UDim2.new(1, 0, 0, 1)
Divider.Position = UDim2.new(0, 0, 0, 40)
Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Divider.BackgroundTransparency = 0.8
Divider.BorderSizePixel = 0

-- Stats Grid
local StatsContainer = Instance.new("Frame", MainFrame)
StatsContainer.Size = UDim2.new(1, -20, 0, 100)
StatsContainer.Position = UDim2.new(0, 10, 0, 50)
StatsContainer.BackgroundTransparency = 1

local UIGrid = Instance.new("UIGridLayout", StatsContainer)
UIGrid.CellSize = UDim2.new(0.48, 0, 0, 20)
UIGrid.CellPadding = UDim2.new(0.04, 0, 0, 5)

local function CreateStat(name, defaultVal)
    local Label = Instance.new("TextLabel", StatsContainer)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. defaultVal
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    return Label
end

local EarnedLbl = CreateStat("Earned", "$0")
local TimeLbl = CreateStat("Time", "00:00")
local RateLbl = CreateStat("Cash/Min", "$0")
local StatusLbl = CreateStat("Status", "Idle")
local FPSLbl = CreateStat("FPS", "60")
local PingLbl = CreateStat("Ping", "0ms")

-- Control Buttons
local ButtonContainer = Instance.new("Frame", MainFrame)
ButtonContainer.Size = UDim2.new(1, -20, 0, 45)
ButtonContainer.Position = UDim2.new(0, 10, 1, -55)
ButtonContainer.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", ButtonContainer)
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
ToggleBtn.Text = "START FARMING"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.AutoButtonColor = false -- Custom animation used

local BtnCorner = Instance.new("UICorner", ToggleBtn)
BtnCorner.CornerRadius = UDim.new(0, 8)

local BtnStroke = Instance.new("UIStroke", ToggleBtn)
BtnStroke.Thickness = 1
BtnStroke.Color = Color3.fromRGB(80, 80, 100)
BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Mobile Toggle (Mini Button)
local MiniBtn = Instance.new("TextButton", ScreenGui)
MiniBtn.Size = UDim2.fromOffset(40, 40)
MiniBtn.Position = UDim2.new(0.9, -10, 0.1, 0) -- Top Right
MiniBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MiniBtn.Text = "UI"
MiniBtn.Font = Enum.Font.GothamBlack
MiniBtn.TextColor3 = Color3.fromRGB(255, 180, 50)
MiniBtn.Parent = ScreenGui
local MiniCorner = Instance.new("UICorner", MiniBtn)
MiniCorner.CornerRadius = UDim.new(1, 0)
local MiniStroke = Instance.new("UIStroke", MiniBtn)
MiniStroke.Color = Color3.fromRGB(255, 180, 50)
MiniStroke.Thickness = 2

MiniBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- // HELPER FUNCTIONS //

local function FormatNumber(n)
    return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function GetTime(seconds)
    local min = math.floor(seconds / 60)
    local sec = seconds % 60
    return string.format("%02d:%02d", min, sec)
end

-- Efficient Object Caching
local Caches = { Registers = {}, Safes = {} }

local function UpdateCache()
    table.clear(Caches.Registers)
    table.clear(Caches.Safes)
    
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Model") then
            if v.Name == "CashRegister" and v:FindFirstChild("Open") then
                table.insert(Caches.Registers, v)
            elseif v.Name == "Safe" and v:FindFirstChild("Safe") then
                table.insert(Caches.Safes, v)
            end
        end
    end
end

UpdateCache()
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "CashRegister" then table.insert(Caches.Registers, child)
    elseif child.Name == "Safe" then table.insert(Caches.Safes, child) end
end)

-- Smooth Movement (Tween)
local CurrentTween
local function MoveTo(targetCFrame)
    if not Character or not RootPart then return end
    
    local distance = (RootPart.Position - targetCFrame.Position).Magnitude
    local time = distance / GeneralSettings.TweenSpeed
    
    local info = TweenInfo.new(time, Enum.EasingStyle.Linear)
    
    if CurrentTween then CurrentTween:Cancel() end
    CurrentTween = TweenService:Create(RootPart, info, {CFrame = targetCFrame})
    CurrentTween:Play()
    
    -- Anti-Stuck / Wait mechanism
    local arrived = false
    local conn
    conn = CurrentTween.Completed:Connect(function()
        arrived = true
        conn:Disconnect()
    end)
    
    -- Break if cancelled manually
    repeat task.wait(0.1) until arrived or not State.IsFarming
end

-- // FARMING LOGIC //

local function GetNearestRegister()
    local best, minDist = nil, math.huge
    for _, reg in ipairs(Caches.Registers) do
        if reg and reg.Parent and reg:FindFirstChild("Open") then
            local dist = (RootPart.Position - reg.Open.Position).Magnitude
            if dist < minDist then
                minDist = dist
                best = reg
            end
        end
    end
    return best
end

local function GetNearestSafe()
    local best, minDist = nil, math.huge
    for _, safe in ipairs(Caches.Safes) do
        if safe and safe.Parent and safe:FindFirstChild("Safe") and safe:FindFirstChild("Amount") and safe.Amount.Value > 0 then
            local dist = (RootPart.Position - safe.Safe.Position).Magnitude
            if dist < minDist then
                minDist = dist
                best = safe
            end
        end
    end
    return best
end

local function Farm()
    while State.IsFarming do
        Character = LocalPlayer.Character
        RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
        
        if not Character or not RootPart then
            StatusLbl.Text = "Status: Waiting for Char..."
            task.wait(1)
            continue
        end

        local BagVal = BagState.Value
        local MaxBag = BagLevel.Value

        if BagVal >= MaxBag then
            -- Selling Logic
            State.IsSelling = true
            StatusLbl.Text = "Status: Selling..."
            StatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            MoveTo(GeneralSettings.SellPosition)
            task.wait(1.5) -- Wait for sell interaction
            
            State.IsSelling = false
        else
            -- Robbing Logic
            State.IsSelling = false
            StatusLbl.Text = "Status: Robbing"
            StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)

            local TargetReg = GetNearestRegister()
            local TargetSafe = GetNearestSafe()
            
            -- Prioritize Safes if close, otherwise Registers
            local Target = TargetReg -- Default
            
            if TargetSafe and TargetReg then
                local dSafe = (RootPart.Position - TargetSafe.Safe.Position).Magnitude
                local dReg = (RootPart.Position - TargetReg.Open.Position).Magnitude
                if dSafe < dReg * 1.5 then -- Bias towards safes slightly
                    Target = TargetSafe
                end
            elseif TargetSafe then
                Target = TargetSafe
            end

            if Target then
                local targetPart = Target:FindFirstChild("Open") or Target:FindFirstChild("Safe")
                if targetPart then
                    MoveTo(targetPart.CFrame)
                    
                    -- Rob Action
                    if Target.Name == "CashRegister" then
                        RobEvent:FireServer("Register", {
                            Part = Target:FindFirstChild("Union"),
                            OpenPart = Target:FindFirstChild("Open"),
                            ActiveValue = Target:FindFirstChild("Active"),
                            Active = true
                        })
                    elseif Target.Name == "Safe" then
                        if Target:FindFirstChild("Open") and Target.Open.Value then
                             RobEvent:FireServer("Safe", Target)
                        else
                             if Target:FindFirstChild("OpenSafe") then
                                 Target.OpenSafe:FireServer("Completed")
                             end
                             RobEvent:FireServer("Safe", Target)
                        end
                    end
                end
            else
                StatusLbl.Text = "Status: Searching..."
                UpdateCache() -- Refresh if nothing found
            end
        end
        task.wait(GeneralSettings.LoopDelay)
    end
end

-- // UI INTERACTION //

ToggleBtn.MouseButton1Click:Connect(function()
    State.IsFarming = not State.IsFarming
    
    if State.IsFarming then
        ToggleBtn.Text = "STOP FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        StartTime = tick()
        InitialCash = CashStat.Value
        
        -- Start loop
        task.spawn(Farm)
    else
        ToggleBtn.Text = "START FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        if CurrentTween then CurrentTween:Cancel() end
        StatusLbl.Text = "Status: Idle"
        StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    -- Button Animation
    TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {TextSize = 16}):Play()
    task.wait(0.1)
    TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {TextSize = 14}):Play()
end)

-- // STATS UPDATER LOOP //
task.spawn(function()
    while true do
        if State.IsFarming then
            -- Time
            local elapsed = tick() - StartTime
            TimeLbl.Text = "Time: " .. GetTime(elapsed)
            
            -- Earned
            local current = CashStat.Value
            local gained = current - InitialCash
            EarnedLbl.Text = "Earned: $" .. FormatNumber(gained)
            
            -- Cash Per Minute
            if elapsed > 0 then
                local cpm = math.floor((gained / elapsed) * 60)
                RateLbl.Text = "Cash/Min: $" .. FormatNumber(cpm)
            end
        end
        
        -- System Stats
        FPSLbl.Text = "FPS: " .. math.floor(1 / RunService.RenderStepped:Wait())
        
        local ping = 0
        pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        PingLbl.Text = "Ping: " .. ping .. "ms"
        
        task.wait(0.5)
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

-- Notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Westbound Loaded";
    Text = "Script optimized for Mobile & PC.";
    Duration = 5;
})

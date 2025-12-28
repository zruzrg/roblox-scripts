--[[
    WESTBOUND ULTIMATE FARM (GHOST MODE EDITION)
    Platform: PC & Mobile
    Type: Instant TP + God Mode + Modern UI
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StatsService = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")

-- // CONFIGURATION //
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local BagState = LocalPlayer:WaitForChild("States"):WaitForChild("Bag")
local BagLevel = LocalPlayer:WaitForChild("Stats"):WaitForChild("BagSizeLevel"):WaitForChild("CurrentAmount")
local RobEvent = ReplicatedStorage:WaitForChild("GeneralEvents"):WaitForChild("Rob")
local CashStat = LocalPlayer:WaitForChild("leaderstats"):WaitForChild("$$")

local InitialCash = CashStat.Value
local StartTime = tick()
local SellPosition = CFrame.new(1636.6, 104.3, -1736.2) -- Banka Satış Noktası

local State = {
    IsFarming = false,
    Character = nil,
    RootPart = nil,
    Humanoid = nil
}

-- // CLEANUP //
if getgenv().WB_Ghost then getgenv().WB_Ghost:Destroy() end

-- // MODERN UI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WestboundGhostUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
getgenv().WB_Ghost = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(340, 200)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Thickness = 1.5
UIStroke.Color = Color3.fromRGB(210, 160, 50) -- Gold Theme

-- Drag Logic
local dragging, dragStart, startPos
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
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- UI Components
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -20, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "WESTBOUND"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", MainFrame)
SubTitle.Size = UDim2.new(1, -20, 0, 30)
SubTitle.Position = UDim2.new(0, 0, 0, 5)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "GHOST FARM"
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 12
SubTitle.TextColor3 = Color3.fromRGB(210, 160, 50)
SubTitle.TextXAlignment = Enum.TextXAlignment.Right
SubTitle.Parent = MainFrame

local StatsFrame = Instance.new("Frame", MainFrame)
StatsFrame.Size = UDim2.new(1, -20, 0, 80)
StatsFrame.Position = UDim2.new(0, 10, 0, 40)
StatsFrame.BackgroundTransparency = 1

local function CreateStat(txt, pos)
    local l = Instance.new("TextLabel", StatsFrame)
    l.Size = UDim2.new(0.5, 0, 0, 20)
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = txt
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextColor3 = Color3.fromRGB(180, 180, 180)
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local CashLbl = CreateStat("Earned: $0", UDim2.new(0, 0, 0, 0))
local TimeLbl = CreateStat("Time: 00:00", UDim2.new(0, 0, 0, 25))
local StatusLbl = CreateStat("Status: Idle", UDim2.new(0, 0, 0, 50))
local FPSLbl = CreateStat("FPS: 60", UDim2.new(0.5, 0, 0, 0))
local PingLbl = CreateStat("Ping: 0ms", UDim2.new(0.5, 0, 0, 25))

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(1, -20, 0, 40)
ToggleBtn.Position = UDim2.new(0, 10, 1, -50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(210, 160, 50)
ToggleBtn.Text = "START"
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 16
ToggleBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
ToggleBtn.AutoButtonColor = true
local BtnCorner = Instance.new("UICorner", ToggleBtn)
BtnCorner.CornerRadius = UDim.new(0, 6)

-- // CORE FUNCTIONS //

local function UpdateCharacter()
    State.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    State.Humanoid = State.Character:WaitForChild("Humanoid")
    State.RootPart = State.Character:WaitForChild("HumanoidRootPart")
end

-- GOD MODE (The "Special System" from V1)
local function EnableGhostMode()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        
        -- Clone and replace humanoid to detach from server damage logic
        local newHum = hum:Clone()
        newHum.Parent = char
        LocalPlayer.Character = nil 
        newHum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        newHum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:Destroy()
        LocalPlayer.Character = char
        
        Workspace.CurrentCamera.CameraSubject = newHum
        newHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        
        -- Reset references
        State.Humanoid = newHum
        State.RootPart = char:FindFirstChild("HumanoidRootPart")
    end)
end

-- INSTANT TP (No Tweening)
local function TeleportTo(cf)
    if State.RootPart then
        State.RootPart.Velocity = Vector3.new(0,0,0) -- Stop physics
        State.RootPart.CFrame = cf
    end
end

local function FormatNum(n)
    return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- // CACHING SYSTEM //
local Registers = {}
local Safes = {}

local function RefreshCache()
    table.clear(Registers)
    table.clear(Safes)
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") then
            if v.Name == "CashRegister" and v:FindFirstChild("Open") then
                table.insert(Registers, v)
            elseif v.Name == "Safe" and v:FindFirstChild("Safe") then
                table.insert(Safes, v)
            end
        end
    end
end
RefreshCache()

-- // FARM LOGIC //
local function FarmLoop()
    while State.IsFarming do
        local success, err = pcall(function()
            if not State.RootPart then UpdateCharacter() end
            
            -- Bag Full Check
            if BagState.Value >= BagLevel.Value then
                StatusLbl.Text = "Status: SELLING"
                StatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                
                TeleportTo(SellPosition)
                -- Spam interact just in case
                VirtualUser:ClickButton1(Vector2.new(0,0))
                task.wait(0.5) 
                return
            end

            StatusLbl.Text = "Status: ROBBING"
            StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)

            -- Find nearest Target
            local nearest = nil
            local minDst = 99999
            local pPos = State.RootPart.Position

            for _, r in ipairs(Registers) do
                if r.Parent and r:FindFirstChild("Open") then
                    local d = (pPos - r.Open.Position).Magnitude
                    if d < minDst then minDst = d; nearest = {Obj = r, Type = "Reg", Part = r.Open} end
                end
            end
            
            for _, s in ipairs(Safes) do
                if s.Parent and s:FindFirstChild("Safe") and s.Amount.Value > 0 then
                    local d = (pPos - s.Safe.Position).Magnitude
                    if d < minDst then minDst = d; nearest = {Obj = s, Type = "Safe", Part = s.Safe} end
                end
            end

            if nearest then
                TeleportTo(nearest.Part.CFrame)
                
                if nearest.Type == "Reg" then
                    RobEvent:FireServer("Register", {
                        Part = nearest.Obj.Union,
                        OpenPart = nearest.Obj.Open,
                        ActiveValue = nearest.Obj.Active,
                        Active = true
                    })
                elseif nearest.Type == "Safe" then
                    if nearest.Obj:FindFirstChild("Open") and nearest.Obj.Open.Value then
                        RobEvent:FireServer("Safe", nearest.Obj)
                    else
                        if nearest.Obj:FindFirstChild("OpenSafe") then
                            nearest.Obj.OpenSafe:FireServer("Completed")
                        end
                        RobEvent:FireServer("Safe", nearest.Obj)
                    end
                end
            else
                StatusLbl.Text = "Status: Searching..."
                RefreshCache()
            end
        end)
        
        if not success then warn(err) end
        task.wait(0.05) -- ULTRA FAST LOOP
    end
end

-- // BUTTON EVENTS //
ToggleBtn.MouseButton1Click:Connect(function()
    State.IsFarming = not State.IsFarming
    if State.IsFarming then
        ToggleBtn.Text = "STOP"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        UpdateCharacter()
        EnableGhostMode() -- ACTIVATE GOD MODE
        StartTime = tick()
        InitialCash = CashStat.Value
        task.spawn(FarmLoop)
    else
        ToggleBtn.Text = "START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(210, 160, 50)
        StatusLbl.Text = "Status: Idle"
        StatusLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        
        -- Respawn to fix character if needed
        if LocalPlayer.Character then LocalPlayer.Character.Humanoid.Health = 0 end
    end
end)

-- Stats Updater
task.spawn(function()
    while true do
        task.wait(1)
        if State.IsFarming then
            local diff = CashStat.Value - InitialCash
            CashLbl.Text = "Earned: $" .. FormatNum(diff)
            
            local now = tick() - StartTime
            local m = math.floor(now / 60)
            local s = math.floor(now % 60)
            TimeLbl.Text = string.format("Time: %02d:%02d", m, s)
        end
        FPSLbl.Text = "FPS: " .. math.floor(1 / RunService.RenderStepped:Wait())
        pcall(function() PingLbl.Text = "Ping: " .. math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms" end)
    end
end)

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(1)
    if State.IsFarming then
        UpdateCharacter()
        EnableGhostMode()
    end
end)

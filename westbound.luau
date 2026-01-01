ocal Players = game:GetService("Players")local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local StatsService = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local BagState = LocalPlayer:WaitForChild("States"):WaitForChild("Bag")
local BagLevel = LocalPlayer:WaitForChild("Stats"):WaitForChild("BagSizeLevel"):WaitForChild("CurrentAmount")
local RobEvent = ReplicatedStorage:WaitForChild("GeneralEvents"):WaitForChild("Rob")
local CashStat = LocalPlayer:WaitForChild("leaderstats"):WaitForChild("$$")

local InitialCash = CashStat.Value
local StartTime = tick()
local SellCFrame = CFrame.new(1636.6, 104.3, -1736.2)

local State = {
    Active = false,
    Selling = false
}

if getgenv().WB_Instant then getgenv().WB_Instant:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WestboundInstantUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
getgenv().WB_Instant = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(350, 220)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 14)

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Thickness = 1.6
UIStroke.Color = Color3.fromRGB(255, 0, 0) -- Red for Aggressive Mode
UIStroke.Transparency = 0.3

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

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -20, 0, 30)
Title.Position = UDim2.new(0, 15, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "WESTBOUND"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", MainFrame)
SubTitle.Size = UDim2.new(1, -20, 0, 30)
SubTitle.Position = UDim2.new(0, 0, 0, 10)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "INSTANT TP"
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 14
SubTitle.TextColor3 = Color3.fromRGB(255, 50, 50)
SubTitle.TextXAlignment = Enum.TextXAlignment.Right
SubTitle.Parent = MainFrame

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(1, -20, 0, 20)
StatusLbl.Position = UDim2.new(0, 15, 0, 50)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "Status: Idle"
StatusLbl.Font = Enum.Font.GothamBold
StatusLbl.TextSize = 14
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

local CashLbl = Instance.new("TextLabel", MainFrame)
CashLbl.Size = UDim2.new(1, -20, 0, 20)
CashLbl.Position = UDim2.new(0, 15, 0, 75)
CashLbl.BackgroundTransparency = 1
CashLbl.Text = "Earned: $0"
CashLbl.Font = Enum.Font.Gotham
CashLbl.TextSize = 14
CashLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
CashLbl.TextXAlignment = Enum.TextXAlignment.Left

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(1, -30, 0, 50)
ToggleBtn.Position = UDim2.new(0, 15, 1, -65)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ToggleBtn.Text = "START FARM"
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 18
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.AutoButtonColor = true

local BtnCorner = Instance.new("UICorner", ToggleBtn)
BtnCorner.CornerRadius = UDim.new(0, 10)

local Cache = {Registers = {}, Safes = {}}

local function AddToCache(obj)
    if obj:IsA("Model") then
        if obj.Name == "CashRegister" then table.insert(Cache.Registers, obj)
        elseif obj.Name == "Safe" then table.insert(Cache.Safes, obj) end
    end
end

local function RemoveFromCache(obj)
    if obj.Name == "CashRegister" then
        local i = table.find(Cache.Registers, obj)
        if i then table.remove(Cache.Registers, i) end
    elseif obj.Name == "Safe" then
        local i = table.find(Cache.Safes, obj)
        if i then table.remove(Cache.Safes, i) end
    end
end

for _, v in Workspace:GetChildren() do AddToCache(v) end
Workspace.ChildAdded:Connect(AddToCache)
Workspace.ChildRemoved:Connect(RemoveFromCache)

local function InstantTP(cf)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        
        root.Velocity = Vector3.zero 
        root.RotVelocity = Vector3.zero
        root.CFrame = cf
    end
end

RunService.Stepped:Connect(function()
    if State.Active and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

local function Farm()
    while State.Active do
        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            if BagState.Value >= BagLevel.Value then
                StatusLbl.Text = "Status: SELLING..."
                StatusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                
                InstantTP(SellCFrame)
                
                task.wait(0.2)
                VirtualUser:ClickButton1(Vector2.zero)
                
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and (v.Parent.Position - char.HumanoidRootPart.Position).Magnitude < 15 then
                        fireproximityprompt(v)
                    end
                end
                
                task.wait(0.5)
                return
            end
            
            StatusLbl.Text = "Status: HUNTING..."
            StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            local rootPos = char.HumanoidRootPart.Position
            local target = nil
            local minDst = math.huge
            
            for _, reg in Cache.Registers do
                if reg.Parent and reg:FindFirstChild("Open") then
                    local d = (rootPos - reg.Open.Position).Magnitude
                    if d < minDst then
                        minDst = d
                        target = {Obj = reg, Type = "Reg", Part = reg.Open}
                    end
                end
            end
            
            for _, safe in Cache.Safes do
                if safe.Parent and safe:FindFirstChild("Safe") and safe:FindFirstChild("Amount") and safe.Amount.Value > 0 then
                    local d = (rootPos - safe.Safe.Position).Magnitude
                    if d < minDst then
                        minDst = d
                        target = {Obj = safe, Type = "Safe", Part = safe.Safe}
                    end
                end
            end
            
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
        task.wait(0.05) 
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    State.Active = not State.Active
    if State.Active then
        ToggleBtn.Text = "STOP FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
        StartTime = tick()
        InitialCash = CashStat.Value
        task.spawn(Farm)
    else
        ToggleBtn.Text = "START FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        StatusLbl.Text = "Status: Stopped"
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if State.Active then
            local earned = CashStat.Value - InitialCash
            CashLbl.Text = "Earned: $" .. tostring(earned):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end)

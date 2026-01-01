--!native
--!optimize 2
--!nocheck

local Players: Players = game:GetService("Players")
local Workspace: Workspace = game:GetService("Workspace")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService: RunService = game:GetService("RunService")
local CoreGui: CoreGui = game:GetService("CoreGui")
local VirtualUser: VirtualUser = game:GetService("VirtualUser")
local StatsService: Stats = game:GetService("Stats")

local LocalPlayer: Player = Players.LocalPlayer
local Camera: Camera = Workspace.CurrentCamera

local BagState: NumberValue = LocalPlayer:WaitForChild("States"):WaitForChild("Bag")
local BagLevel: IntValue = LocalPlayer:WaitForChild("Stats"):WaitForChild("BagSizeLevel"):WaitForChild("CurrentAmount")
local RobEvent: RemoteEvent = ReplicatedStorage:WaitForChild("GeneralEvents"):WaitForChild("Rob")
local CashStat: IntValue = LocalPlayer:WaitForChild("leaderstats"):WaitForChild("$$")

local InitialCash: number = CashStat.Value
local StartTime: number = tick()
local SellCFrame: CFrame = CFrame.new(1636.6, 104.3, -1736.2)

type FarmState = {
    Active: boolean,
    Selling: boolean,
    Character: Model?,
    Root: BasePart?
}

local State: FarmState = {
    Active = false,
    Selling = false,
    Character = nil,
    Root = nil
}

if getgenv().WB_Final then getgenv().WB_Final:Destroy() end

local ScreenGui: ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WestboundFinalUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
getgenv().WB_Final = ScreenGui

local MainFrame: Frame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(350, 220)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.BackgroundTransparency = 0.25 
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner: UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 16)

local UIStroke: UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Thickness = 1.2
UIStroke.Color = Color3.fromRGB(255, 170, 0)
UIStroke.Transparency = 0.3

local Blur: ImageLabel = Instance.new("ImageLabel", MainFrame)
Blur.Size = UDim2.new(1, 0, 1, 0)
Blur.BackgroundTransparency = 1
Blur.Image = "rbxassetid://8992230677"
Blur.ImageTransparency = 0.8
Blur.ZIndex = 0
local BlurCorner: UICorner = Instance.new("UICorner", Blur)
BlurCorner.CornerRadius = UDim.new(0, 16)

local dragging: boolean, dragStart: Vector3, startPos: UDim2
local function UpdateDrag(input: InputObject)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input: InputObject)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateDrag(input)
    end
end)

local Title: TextLabel = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -30, 0, 40)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "WESTBOUND"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle: TextLabel = Instance.new("TextLabel", MainFrame)
SubTitle.Size = UDim2.new(1, -30, 0, 40)
SubTitle.Position = UDim2.new(0, 0, 0, 5)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "ULTIMATE"
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 14
SubTitle.TextColor3 = Color3.fromRGB(255, 170, 0)
SubTitle.TextXAlignment = Enum.TextXAlignment.Right
SubTitle.Parent = MainFrame

local Divider: Frame = Instance.new("Frame", MainFrame)
Divider.Size = UDim2.new(1, 0, 0, 1)
Divider.Position = UDim2.new(0, 0, 0, 45)
Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Divider.BackgroundTransparency = 0.85
Divider.BorderSizePixel = 0

local StatsFrame: Frame = Instance.new("Frame", MainFrame)
StatsFrame.Size = UDim2.new(1, -30, 0, 100)
StatsFrame.Position = UDim2.new(0, 15, 0, 55)
StatsFrame.BackgroundTransparency = 1

local function CreateInfo(text: string, pos: UDim2): TextLabel
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

local EarnedLbl: TextLabel = CreateInfo("Earned: $0", UDim2.new(0,0,0,0))
local TimeLbl: TextLabel = CreateInfo("Time: 00:00", UDim2.new(0,0,0,30))
local StatusLbl: TextLabel = CreateInfo("Status: Idle", UDim2.new(0,0,0,60))
local FPSLbl: TextLabel = CreateInfo("FPS: 60", UDim2.new(0.6,0,0,0))
local PingLbl: TextLabel = CreateInfo("Ping: 0ms", UDim2.new(0.6,0,0,30))

local ToggleBtn: TextButton = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(1, -30, 0, 45)
ToggleBtn.Position = UDim2.new(0, 15, 1, -55)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
ToggleBtn.Text = "START FARMING"
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 16
ToggleBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
ToggleBtn.AutoButtonColor = true

local BtnCorner: UICorner = Instance.new("UICorner", ToggleBtn)
BtnCorner.CornerRadius = UDim.new(0, 10)

type CacheType = {
    Registers: {Model},
    Safes: {Model}
}

local Cache: CacheType = {
    Registers = {},
    Safes = {}
}

local function AddToCache(obj: Instance)
    if obj:IsA("Model") then
        if obj.Name == "CashRegister" then
            table.insert(Cache.Registers, obj)
        elseif obj.Name == "Safe" then
            table.insert(Cache.Safes, obj)
        end
    end
end

local function RemoveFromCache(obj: Instance)
    if obj.Name == "CashRegister" then
        local idx = table.find(Cache.Registers, obj)
        if idx then table.remove(Cache.Registers, idx) end
    elseif obj.Name == "Safe" then
        local idx = table.find(Cache.Safes, obj)
        if idx then table.remove(Cache.Safes, idx) end
    end
end

for _, v in Workspace:GetChildren() do AddToCache(v) end

Workspace.ChildAdded:Connect(AddToCache)
Workspace.ChildRemoved:Connect(RemoveFromCache)

local function UpdateChar(): boolean
    local char = LocalPlayer.Character
    if char then
        State.Character = char
        State.Root = char:FindFirstChild("HumanoidRootPart")
        return true
    end
    return false
end

local function EnableGodMode()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        
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
        if animate then 
            animate.Disabled = true 
            task.wait(0.1) 
            animate.Disabled = false 
        end
    end)
end

local function InstantTP(cf: CFrame)
    if State.Root then
        State.Root.Velocity = Vector3.zero
        State.Root.CFrame = cf
    end
end

local function Farm()
    while State.Active do
        local success, err = pcall(function()
            if not UpdateChar() then return end
            
            if BagState.Value >= BagLevel.Value then
                State.Selling = true
                StatusLbl.Text = "Status: Selling..."
                StatusLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                
                InstantTP(SellCFrame)
                VirtualUser:ClickButton1(Vector2.zero)
                task.wait(0.3)
                return
            end
            
            State.Selling = false
            StatusLbl.Text = "Status: Hunting..."
            StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            local myPos = State.Root.Position
            local target = nil
            local minSq = 99999999
            
            for _, reg in Cache.Registers do
                if reg.Parent and reg:FindFirstChild("Open") then
                    local distSq = (myPos - reg.Open.Position).Magnitude
                    if distSq < minSq then
                        minSq = distSq
                        target = {Obj = reg, Type = "Reg", Part = reg.Open}
                    end
                end
            end
            
            for _, safe in Cache.Safes do
                if safe.Parent and safe:FindFirstChild("Safe") and safe:FindFirstChild("Amount") and safe.Amount.Value > 0 then
                    local distSq = (myPos - safe.Safe.Position).Magnitude
                    if distSq < minSq then
                        minSq = distSq
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
        
        task.wait(0.01)
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    State.Active = not State.Active
    
    if State.Active then
        ToggleBtn.Text = "STOP FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
        
        StartTime = tick()
        InitialCash = CashStat.Value
        
        UpdateChar()
        EnableGodMode()
        
        task.spawn(Farm)
    else
        ToggleBtn.Text = "START FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        ToggleBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
        StatusLbl.Text = "Status: Stopped"
        StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

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

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.Active then EnableGodMode() end
end)

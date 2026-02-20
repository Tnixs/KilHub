
-- [[ KilHub | Sniper Arena | V7.6 FINAL ]]
-- [[ Features: Full Aimbot, Triggerbot, Anti-Aim, Strafe, Working ESP ]]

--// Cache
local pcall = pcall
local next = next
local Vector2 = Vector2.new
local mathclamp = math.clamp
local mathfloor = math.floor
local mathcos = math.cos
local mathsin = math.sin
local mathrandom = math.random
local mathrad = math.rad
local mousemoverel = mousemoverel or (Input and Input.MouseMove)

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

--// Variables
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Typing = false

--// Configuration
local Config = {
    Aimbot = {
        Enabled = true,
        TeamCheck = false,
        AliveCheck = true,
        WallCheck = false,
        Sensitivity = 0, -- Animation length
        ThirdPerson = false,
        ThirdPersonSensitivity = 3,
        TriggerKey = "MouseButton2", -- Varsayılan sağ tık
        Toggle = false,
        LockPart = "Head",
        MaxDistance = 1000
    },
    FOV = {
        Enabled = true,
        Visible = true,
        Amount = 200, -- Biraz büyüttüm ki kaçırmasın
        Color = Color3.fromRGB(255, 255, 255),
        LockedColor = Color3.fromRGB(255, 70, 70),
        Transparency = 0.5,
        Sides = 60,
        Thickness = 1,
        Filled = false
    },
    Triggerbot = {
        Enabled = false,
        Delay = 0.05,
        TeamCheck = true
    },
    AntiAim = {
        Enabled = false,
        Mode = "Spin",
        Speed = 10
    },
    Strafe = {
        Enabled = false,
        Mode = "Circle",
        Speed = 16,
        Distance = 5
    },
    ESP = {
        Enabled = false,
        Boxes = false,
        Names = false,
        Health = false,
        Distance = false,
        Tracers = false,
        Color = Color3.fromRGB(255, 140, 0),
        TeamCheck = false,
        MaxDistance = 1500
    },
    Misc = {
        Fullbright = false
    }
}

--// Aimbot Variables
local Aimbot = {
    Locked = nil,
    Running = false,
    Animation = nil,
    RequiredDistance = 2000
}

--// FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false

--// ESP Drawings
local ESP_Drawings = {}

--// Anti-Aim Connection
local antiAimConnection = nil

--// Strafe Variables
local strafeAngle = 0
local strafeTime = 0

local DefaultLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd
}
local fullbrightApplied = false

--// UI Theme
local Theme = {
    Main = Color3.fromRGB(15, 15, 15),
    Secondary = Color3.fromRGB(22, 22, 22),
    Accent = Color3.fromRGB(255, 140, 0),
    Text = Color3.fromRGB(240, 240, 240)
}

--====================================================
--== UI CREATION ==--
--====================================================

local ExistingGui = (game:GetService("CoreGui"):FindFirstChild("KilHub_V7_6") or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("KilHub_V7_6"))
if ExistingGui then
    ExistingGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KilHub_V7_6"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- Menu Frame
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 420, 0, 580)
Main.Position = UDim2.new(0.5, -210, 0.5, -290)
Main.BackgroundColor3 = Theme.Main
Main.Visible = false
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MStroke = Instance.new("UIStroke", Main)
MStroke.Color = Theme.Accent
MStroke.Thickness = 1.5

-- Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 110, 1, 0)
Sidebar.BackgroundColor3 = Theme.Secondary
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -120, 1, -10)
Container.Position = UDim2.new(0, 115, 0, 5)
Container.BackgroundTransparency = 1

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", Container)
    Page.Name = name .. "Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 0
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local layout = Instance.new("UIListLayout", Page)
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    return Page
end

local CombatP = CreatePage("Combat")
local MovementP = CreatePage("Movement")
local VisualsP = CreatePage("Visuals")
local MiscP = CreatePage("Misc")

local function OpenPage(name)
    for _, v in pairs(Container:GetChildren()) do
        if v:IsA("ScrollingFrame") then
            v.Visible = false
        end
    end
    local page = Container:FindFirstChild(name .. "Page")
    if page then
        page.Visible = true
    end
end

local function CreateTab(name, order)
    local T = Instance.new("TextButton", Sidebar)
    T.Size = UDim2.new(1, -10, 0, 35)
    T.Position = UDim2.new(0, 5, 0, 10 + (order * 40))
    T.BackgroundColor3 = Theme.Main
    T.Text = name
    T.TextColor3 = Theme.Text
    T.Font = Enum.Font.GothamBold
    T.TextSize = 13
    Instance.new("UICorner", T).CornerRadius = UDim.new(0, 6)
    T.MouseButton1Click:Connect(function() 
        OpenPage(name) 
    end)
end

CreateTab("Combat", 0)
CreateTab("Movement", 1)
CreateTab("Visuals", 2)
CreateTab("Misc", 3)

local function AddToggle(parent, text, configTable, configKey, callback)
    local F = Instance.new("Frame", parent)
    F.Size = UDim2.new(1, 0, 0, 35)
    F.BackgroundColor3 = Theme.Secondary
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)
    
    local L = Instance.new("TextLabel", F)
    L.Text = text
    L.Size = UDim2.new(1, -45, 1, 0)
    L.Position = UDim2.new(0, 10, 0, 0)
    L.TextColor3 = Theme.Text
    L.Font = Enum.Font.GothamSemibold
    L.TextSize = 12
    L.BackgroundTransparency = 1
    L.TextXAlignment = Enum.TextXAlignment.Left
    
    local B = Instance.new("TextButton", F)
    B.Size = UDim2.new(0, 30, 0, 16)
    B.Position = UDim2.new(1, -40, 0.5, -8)
    B.BackgroundColor3 = configTable[configKey] and Theme.Accent or Color3.fromRGB(60,60,60)
    B.Text = ""
    Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
    
    B.MouseButton1Click:Connect(function()
        configTable[configKey] = not configTable[configKey]
        TweenService:Create(B, TweenInfo.new(0.2), {
            BackgroundColor3 = configTable[configKey] and Theme.Accent or Color3.fromRGB(60,60,60)
        }):Play()
        if callback then callback(configTable[configKey]) end
    end)
end

local function AddSlider(parent, text, configTable, configKey, min, max, suffix, callback)
    local F = Instance.new("Frame", parent)
    F.Size = UDim2.new(1, 0, 0, 45)
    F.BackgroundColor3 = Theme.Secondary
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)
    
    local L = Instance.new("TextLabel", F)
    L.Text = text
    L.Size = UDim2.new(1, -20, 0, 20)
    L.Position = UDim2.new(0, 10, 0, 5)
    L.TextColor3 = Theme.Text
    L.Font = Enum.Font.GothamSemibold
    L.TextSize = 12
    L.BackgroundTransparency = 1
    L.TextXAlignment = Enum.TextXAlignment.Left
    
    local Value = Instance.new("TextLabel", F)
    Value.Text = tostring(configTable[configKey]) .. (suffix or "")
    Value.Size = UDim2.new(0, 50, 0, 20)
    Value.Position = UDim2.new(1, -60, 0, 5)
    Value.TextColor3 = Theme.Accent
    Value.Font = Enum.Font.GothamBold
    Value.TextSize = 12
    Value.BackgroundTransparency = 1
    
    local Slider = Instance.new("Frame", F)
    Slider.Size = UDim2.new(1, -20, 0, 4)
    Slider.Position = UDim2.new(0, 10, 0, 30)
    Slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(1, 0)
    
    local Fill = Instance.new("Frame", Slider)
    Fill.Size = UDim2.new((configTable[configKey] - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    
    local Button = Instance.new("TextButton", F)
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    
    local dragging = false
    local dragConnection
    Button.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    dragConnection = RunService.RenderStepped:Connect(function()
        if not F.Parent then
            dragConnection:Disconnect()
            return
        end

        if dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local absPos = Slider.AbsolutePosition
            local size = Slider.AbsoluteSize.X
            local relative = mathclamp((mousePos.X - absPos.X) / size, 0, 1)
            local newValue = min + (relative * (max - min))
            configTable[configKey] = newValue
            Fill.Size = UDim2.new(relative, 0, 1, 0)
            Value.Text = mathfloor(newValue * 100) / 100 .. (suffix or "")
            if callback then callback(newValue) end
        end
    end)
end

local openDropdown

local function AddDropdown(parent, text, configTable, configKey, options)
    local F = Instance.new("Frame", parent)
    F.Size = UDim2.new(1, 0, 0, 45)
    F.BackgroundColor3 = Theme.Secondary
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)
    
    local L = Instance.new("TextLabel", F)
    L.Text = text
    L.Size = UDim2.new(1, -20, 0, 20)
    L.Position = UDim2.new(0, 10, 0, 5)
    L.TextColor3 = Theme.Text
    L.Font = Enum.Font.GothamSemibold
    L.TextSize = 12
    L.BackgroundTransparency = 1
    L.TextXAlignment = Enum.TextXAlignment.Left
    
    local Dropdown = Instance.new("TextButton", F)
    Dropdown.Size = UDim2.new(1, -20, 0, 20)
    Dropdown.Position = UDim2.new(0, 10, 0, 20)
    Dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Dropdown.Text = configTable[configKey]
    Dropdown.TextColor3 = Theme.Accent
    Dropdown.Font = Enum.Font.GothamSemibold
    Dropdown.TextSize = 12
    Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 4)
    
    local dropdownOpen = false
    local dropdownFrame
    
    Dropdown.MouseButton1Click:Connect(function()
        if dropdownOpen then
            if dropdownFrame then dropdownFrame:Destroy() end
            dropdownOpen = false
            openDropdown = nil
            return
        end

        if openDropdown and openDropdown ~= dropdownFrame then
            openDropdown:Destroy()
            openDropdown = nil
        end
        
        dropdownFrame = Instance.new("Frame", ScreenGui)
        dropdownFrame.Size = UDim2.new(0, 200, 0, #options * 30)
        dropdownFrame.Position = UDim2.new(0, Dropdown.AbsolutePosition.X, 0, Dropdown.AbsolutePosition.Y + 25)
        dropdownFrame.BackgroundColor3 = Theme.Secondary
        dropdownFrame.BorderSizePixel = 0
        Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 6)
        
        local layout = Instance.new("UIListLayout", dropdownFrame)
        layout.Padding = UDim.new(0, 2)
        
        for i, option in ipairs(options) do
            local btn = Instance.new("TextButton", dropdownFrame)
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.Text = option
            btn.TextColor3 = Theme.Text
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 12
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                configTable[configKey] = option
                Dropdown.Text = option
                dropdownFrame:Destroy()
                dropdownOpen = false
            end)
        end
        
        openDropdown = dropdownFrame
        dropdownOpen = true
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if openDropdown and openDropdown.Parent then
        local mousePos = UserInputService:GetMouseLocation()
        local pos = openDropdown.AbsolutePosition
        local size = openDropdown.AbsoluteSize

        local insideX = mousePos.X >= pos.X and mousePos.X <= (pos.X + size.X)
        local insideY = mousePos.Y >= pos.Y and mousePos.Y <= (pos.Y + size.Y)
        if insideX and insideY then
            return
        end

        openDropdown:Destroy()
        openDropdown = nil
    end
end)

-- Combat Tab Options
AddToggle(CombatP, "Enable Aimbot", Config.Aimbot, "Enabled")
AddToggle(CombatP, "Team Check", Config.Aimbot, "TeamCheck")
AddToggle(CombatP, "Wall Check", Config.Aimbot, "WallCheck")
AddSlider(CombatP, "Sensitivity", Config.Aimbot, "Sensitivity", 0, 1, "s")
AddToggle(CombatP, "Third Person", Config.Aimbot, "ThirdPerson")
AddSlider(CombatP, "Third Person Sens", Config.Aimbot, "ThirdPersonSensitivity", 0.1, 5, "")
AddDropdown(CombatP, "Trigger Key", Config.Aimbot, "TriggerKey", 
    {"MouseButton1", "MouseButton2", "MouseButton3", "LeftControl", "X", "C", "V", "LeftAlt", "LeftShift", "Q", "E", "R", "F"})
AddToggle(CombatP, "Toggle Mode", Config.Aimbot, "Toggle")
AddDropdown(CombatP, "Lock Part", Config.Aimbot, "LockPart", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"})
AddSlider(CombatP, "Max Target Distance", Config.Aimbot, "MaxDistance", 100, 3000, "")

AddToggle(CombatP, "Enable FOV", Config.FOV, "Enabled")
AddToggle(CombatP, "Show FOV", Config.FOV, "Visible")
AddSlider(CombatP, "FOV Amount", Config.FOV, "Amount", 30, 500, "")

AddToggle(CombatP, "Enable Triggerbot", Config.Triggerbot, "Enabled")
AddSlider(CombatP, "Trigger Delay", Config.Triggerbot, "Delay", 0, 200, "ms", function(v)
    Config.Triggerbot.Delay = v / 1000
end)
AddToggle(CombatP, "Trigger Team Check", Config.Triggerbot, "TeamCheck")

AddToggle(CombatP, "Enable Anti-Aim", Config.AntiAim, "Enabled")
AddDropdown(CombatP, "Anti-Aim Mode", Config.AntiAim, "Mode", {"Spin", "Jitter", "Random"})
AddSlider(CombatP, "Anti-Aim Speed", Config.AntiAim, "Speed", 1, 30, "")

-- Movement Tab
AddToggle(MovementP, "Enable Strafe", Config.Strafe, "Enabled")
AddDropdown(MovementP, "Strafe Mode", Config.Strafe, "Mode", {"Circle", "Random", "Figure8"})
AddSlider(MovementP, "Strafe Speed", Config.Strafe, "Speed", 5, 30, "")
AddSlider(MovementP, "Strafe Distance", Config.Strafe, "Distance", 2, 15, "")

-- Visuals Tab
AddToggle(VisualsP, "Enable ESP", Config.ESP, "Enabled")
AddToggle(VisualsP, "Box ESP", Config.ESP, "Boxes")
AddToggle(VisualsP, "Name ESP", Config.ESP, "Names")
AddToggle(VisualsP, "Health Bar", Config.ESP, "Health")
AddToggle(VisualsP, "Show Distance", Config.ESP, "Distance")
AddToggle(VisualsP, "Tracer Lines", Config.ESP, "Tracers")
AddToggle(VisualsP, "ESP Team Check", Config.ESP, "TeamCheck")
AddSlider(VisualsP, "ESP Max Distance", Config.ESP, "MaxDistance", 100, 5000, "")

-- Misc Tab
AddToggle(MiscP, "Fullbright", Config.Misc, "Fullbright")

-- Toggle Button
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(1, -65, 1, -65)
ToggleBtn.BackgroundColor3 = Theme.Secondary
ToggleBtn.Text = "K"
ToggleBtn.TextColor3 = Theme.Accent
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 25
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", ToggleBtn).Color = Theme.Accent

ToggleBtn.MouseButton1Click:Connect(function() 
    Main.Visible = not Main.Visible 
end)

UserInputService.InputBegan:Connect(function(i, p) 
    if not p and i.KeyCode == Enum.KeyCode.Insert then 
        Main.Visible = not Main.Visible 
    end 
end)

--====================================================
--== AIMBOT FUNCTIONS (Optimized) ==--
--====================================================

local function CancelLock()
    Aimbot.Locked = nil
    if Aimbot.Animation then 
        Aimbot.Animation:Cancel() 
        Aimbot.Animation = nil
    end
    FOVCircle.Color = Config.FOV.Color
end

local function GetTargetPart(character)
    if not character then return nil end

    local primary = character:FindFirstChild(Config.Aimbot.LockPart)
    if primary then return primary end

    return character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("LowerTorso")
end

local function IsVisibleFromCamera(targetPart, character)
    if not Config.Aimbot.WallCheck then return true end
    if not targetPart or not character then return false end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.IgnoreWater = true

    local direction = (targetPart.Position - Camera.CFrame.Position)
    local raycastResult = Workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
    return (not raycastResult) or character:IsAncestorOf(raycastResult.Instance)
end

local function IsTargetValid(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if Config.Aimbot.AliveCheck and humanoid.Health <= 0 then return false end
    
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
    if not rootPart then return false end
    
    if (rootPart.Position - Camera.CFrame.Position).Magnitude > Config.Aimbot.MaxDistance then return false end

    local targetPart = GetTargetPart(player.Character)
    if not targetPart then return false end

    -- Team check
    if Config.Aimbot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

local function GetClosestPlayer()
    if not Aimbot.Locked then
        Aimbot.RequiredDistance = (Config.FOV.Enabled and Config.FOV.Amount or 2000)
        local mousePos = Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        local closestPlayer = nil
        local closestDist = Aimbot.RequiredDistance

        for _, v in next, Players:GetPlayers() do
            if IsTargetValid(v) then
                local targetPart = GetTargetPart(v.Character)
                if not targetPart then continue end

                local Vector, OnScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if OnScreen then
                    local Distance = (mousePos - Vector2(Vector.X, Vector.Y)).Magnitude
                    
                    if not IsVisibleFromCamera(targetPart, v.Character) then
                        continue
                    end

                    if Distance < closestDist then
                        closestDist = Distance
                        closestPlayer = v
                    end
                end
            end
        end
        
        if closestPlayer then
            Aimbot.Locked = closestPlayer
            Aimbot.RequiredDistance = closestDist
        end
    elseif Aimbot.Locked and IsTargetValid(Aimbot.Locked) then
        local targetPart = GetTargetPart(Aimbot.Locked.Character)
        if not targetPart or not IsVisibleFromCamera(targetPart, Aimbot.Locked.Character) then
            CancelLock()
            return
        end

        local targetPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then
            CancelLock()
            return
        end

        local mousePos = Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        local currentDist = (mousePos - Vector2(targetPos.X, targetPos.Y)).Magnitude

        -- Eğer hedef FOV dışına çıkarsa kilidi bırak
        if currentDist > (Config.FOV.Enabled and Config.FOV.Amount or 2000) * 1.2 then
            CancelLock()
        end
    else
        CancelLock()
    end
end

--====================================================
--== ESP FUNCTIONS ==--
--====================================================

local function ClearPlayer(p)
    if ESP_Drawings[p] then
        for _, v in pairs(ESP_Drawings[p]) do
            pcall(function() 
                if v and v.Remove then v:Remove() end
            end)
        end
        ESP_Drawings[p] = nil
    end
end

local function InitPlayer(p)
    if p == LocalPlayer then return end
    ClearPlayer(p)
    
    ESP_Drawings[p] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Square"),
        HealthBg = Drawing.new("Square"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    
    -- Box ayarları
    ESP_Drawings[p].Box.Thickness = 1
    ESP_Drawings[p].Box.Filled = false
    ESP_Drawings[p].Box.Color = Config.ESP.Color
    
    -- Name ayarları
    ESP_Drawings[p].Name.Size = 14
    ESP_Drawings[p].Name.Center = true
    ESP_Drawings[p].Name.Outline = true
    ESP_Drawings[p].Name.Color = Config.ESP.Color
    ESP_Drawings[p].Name.Font = 2 -- Monospace
    
    -- Health bar ayarları
    ESP_Drawings[p].Health.Filled = true
    ESP_Drawings[p].HealthBg.Filled = true
    ESP_Drawings[p].HealthBg.Color = Color3.fromRGB(40, 40, 40)
    
    -- Distance ayarları
    ESP_Drawings[p].Distance.Size = 12
    ESP_Drawings[p].Distance.Center = true
    ESP_Drawings[p].Distance.Outline = true
    ESP_Drawings[p].Distance.Color = Color3.fromRGB(255, 255, 255)
    ESP_Drawings[p].Distance.Font = 2
    
    -- Tracer ayarları
    ESP_Drawings[p].Tracer.Thickness = 1
    ESP_Drawings[p].Tracer.Color = Config.ESP.Color
    ESP_Drawings[p].Tracer.Transparency = 0.5
end

-- Initialize all players
for _, p in pairs(Players:GetPlayers()) do
    task.spawn(function() InitPlayer(p) end)
end

Players.PlayerAdded:Connect(function(p)
    task.spawn(function() InitPlayer(p) end)
end)

Players.PlayerRemoving:Connect(function(p)
    ClearPlayer(p)
end)

--====================================================
--== ANTI-AIM FUNCTIONS ==--
--====================================================

local function StartAntiAim()
    if antiAimConnection then antiAimConnection:Disconnect() end
    
    antiAimConnection = RunService.Heartbeat:Connect(function()
        if not Config.AntiAim.Enabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        if Config.AntiAim.Mode == "Spin" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, mathrad(Config.AntiAim.Speed * 2), 0)
        elseif Config.AntiAim.Mode == "Jitter" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, mathrad(mathrandom(-Config.AntiAim.Speed, Config.AntiAim.Speed)), 0)
        elseif Config.AntiAim.Mode == "Random" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(
                mathrad(mathrandom(-5, 5)),
                mathrad(mathrandom(-Config.AntiAim.Speed, Config.AntiAim.Speed)),
                0
            )
        end
    end)
end

--====================================================
--== STRAFE FUNCTIONS ==--
--====================================================

local function DoStrafe()
    if not Config.Strafe.Enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    strafeTime = strafeTime + 0.03
    
    if Config.Strafe.Mode == "Circle" then
        strafeAngle = strafeAngle + (Config.Strafe.Speed * 0.05)
        local dx = mathcos(strafeAngle) * Config.Strafe.Distance
        local dz = mathsin(strafeAngle) * Config.Strafe.Distance
        
        local targetPos = hrp.Position + Vector3.new(dx, 0, dz)
        humanoid:MoveTo(targetPos)
        
    elseif Config.Strafe.Mode == "Random" then
        if strafeTime > 1 then
            strafeAngle = mathrandom() * math.pi * 2
            strafeTime = 0
        end
        
        local dx = mathcos(strafeAngle) * Config.Strafe.Distance
        local dz = mathsin(strafeAngle) * Config.Strafe.Distance
        
        local targetPos = hrp.Position + Vector3.new(dx, 0, dz)
        humanoid:MoveTo(targetPos)
        
    elseif Config.Strafe.Mode == "Figure8" then
        strafeAngle = strafeAngle + (Config.Strafe.Speed * 0.03)
        local dx = mathsin(strafeAngle) * Config.Strafe.Distance
        local dz = mathsin(strafeAngle * 2) * Config.Strafe.Distance * 0.5
        
        local targetPos = hrp.Position + Vector3.new(dx, 0, dz)
        humanoid:MoveTo(targetPos)
    end
end

--====================================================
--== MAIN LOOP ==--
--====================================================

-- Typing Check
UserInputService.TextBoxFocused:Connect(function()
    Typing = true
end)

UserInputService.TextBoxFocusReleased:Connect(function()
    Typing = false
end)

-- Input Handling
UserInputService.InputBegan:Connect(function(Input, gameProcessed)
    if gameProcessed then return end
    if not Typing and Config.Aimbot.Enabled then
        local keyMatches = false
        
        -- KeyCode kontrolü
        pcall(function()
            if Input.KeyCode == Enum.KeyCode[Config.Aimbot.TriggerKey] then
                keyMatches = true
            end
        end)
        
        -- UserInputType kontrolü
        pcall(function()
            if Input.UserInputType == Enum.UserInputType[Config.Aimbot.TriggerKey] then
                keyMatches = true
            end
        end)
        
        if keyMatches then
            if Config.Aimbot.Toggle then
                Aimbot.Running = not Aimbot.Running
                if not Aimbot.Running then CancelLock() end
            else
                Aimbot.Running = true
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input, gameProcessed)
    if gameProcessed then return end
    if not Typing and Config.Aimbot.Enabled and not Config.Aimbot.Toggle then
        local keyMatches = false
        
        pcall(function()
            if Input.KeyCode == Enum.KeyCode[Config.Aimbot.TriggerKey] then
                keyMatches = true
            end
        end)
        
        pcall(function()
            if Input.UserInputType == Enum.UserInputType[Config.Aimbot.TriggerKey] then
                keyMatches = true
            end
        end)
        
        if keyMatches then
            Aimbot.Running = false
            CancelLock()
        end
    end
end)

-- RenderStepped Loop
RunService.RenderStepped:Connect(function()
    -- Update Camera
    Camera = workspace.CurrentCamera
    if not Camera then return end
    
    -- FOV Circle
    if Config.FOV.Enabled and Config.Aimbot.Enabled then
        FOVCircle.Radius = Config.FOV.Amount
        FOVCircle.Thickness = Config.FOV.Thickness
        FOVCircle.Filled = Config.FOV.Filled
        FOVCircle.NumSides = Config.FOV.Sides
        FOVCircle.Color = Aimbot.Locked and Config.FOV.LockedColor or Config.FOV.Color
        FOVCircle.Transparency = Config.FOV.Transparency
        FOVCircle.Visible = Config.FOV.Visible
        FOVCircle.Position = Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    else
        FOVCircle.Visible = false
    end
    
    -- Aimbot
    if Aimbot.Running and Config.Aimbot.Enabled then
        GetClosestPlayer()
        
        if Aimbot.Locked and Aimbot.Locked.Character then
            local targetPart = GetTargetPart(Aimbot.Locked.Character)
            if not targetPart then
                CancelLock()
            elseif Config.Aimbot.ThirdPerson and mousemoverel then
                local Vector = Camera:WorldToViewportPoint(targetPart.Position)
                mousemoverel(
                    (Vector.X - UserInputService:GetMouseLocation().X) * Config.Aimbot.ThirdPersonSensitivity,
                    (Vector.Y - UserInputService:GetMouseLocation().Y) * Config.Aimbot.ThirdPersonSensitivity
                )
            else
                if Config.Aimbot.Sensitivity > 0 then
                    if Aimbot.Animation then Aimbot.Animation:Cancel() end
                    Aimbot.Animation = TweenService:Create(Camera,
                        TweenInfo.new(Config.Aimbot.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                        {CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)}
                    )
                    Aimbot.Animation:Play()
                else
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                end
            end
        end
    end
    
    -- Triggerbot
    if Config.Triggerbot.Enabled then
        local screenCenter = Vector2(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local unitRay = Camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        rayParams.IgnoreWater = true

        local raycastResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
        if raycastResult and raycastResult.Instance then
            local character = raycastResult.Instance:FindFirstAncestorOfClass("Model")
            if character and character:FindFirstChild("Humanoid") then
                local player = Players:GetPlayerFromCharacter(character)
                if player and player ~= LocalPlayer then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local canShoot = true

                        if Config.Triggerbot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                            canShoot = false
                        end

                        if canShoot then
                            VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 1)
                            task.wait(0.02)
                            VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 1)
                            task.wait(mathclamp(Config.Triggerbot.Delay, 0, 1))
                        end
                    end
                end
            end
        end
    end
    
    -- Strafe
    DoStrafe()
    
    -- ESP Drawing - DÜZELTİLDİ VE TEST EDİLDİ
    for player, drawings in pairs(ESP_Drawings) do
        if Config.ESP.Enabled and player and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
            local head = character:FindFirstChild("Head")
            
            if humanoid and rootPart and head then
                local sameTeam = player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
                local alive = humanoid.Health > 0
                local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude

                if (Config.ESP.TeamCheck and sameTeam) or distance > Config.ESP.MaxDistance then
                    drawings.Box.Visible = false
                    drawings.Name.Visible = false
                    drawings.Health.Visible = false
                    drawings.HealthBg.Visible = false
                    drawings.Distance.Visible = false
                    drawings.Tracer.Visible = false
                    continue
                end

                local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))

                -- Box boyutunu hesapla (mesafeye göre)
                local safeDistance = math.max(distance, 1)
                local boxHeight = mathclamp(5000 / safeDistance, 20, 200)
                local boxWidth = boxHeight * 0.6
                
                -- Box ESP
                if Config.ESP.Boxes and onScreen then
                    drawings.Box.Visible = true
                    drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
                    drawings.Box.Position = Vector2.new(pos.X - boxWidth/2, pos.Y - boxHeight/2)
                    drawings.Box.Color = humanoid.Health > 0 and Config.ESP.Color or Color3.fromRGB(100, 100, 100)
                else
                    drawings.Box.Visible = false
                end
                
                -- Name ESP
                if Config.ESP.Names and headOnScreen then
                    drawings.Name.Visible = true
                    drawings.Name.Text = player.Name .. (humanoid.Health <= 0 and " [DEAD]" or "")
                    drawings.Name.Position = Vector2.new(headPos.X, headPos.Y - 25)
                    drawings.Name.Color = humanoid.Health > 0 and Config.ESP.Color or Color3.fromRGB(150, 150, 150)
                else
                    drawings.Name.Visible = false
                end
                
                -- Health Bar - DÜZELTİLDİ
                if Config.ESP.Health and onScreen and humanoid.Health > 0 then
                    local healthPercent = mathclamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                    
                    -- Arkaplan
                    drawings.HealthBg.Visible = true
                    drawings.HealthBg.Size = Vector2.new(4, boxHeight)
                    drawings.HealthBg.Position = Vector2.new(pos.X - boxWidth/2 - 6, pos.Y - boxHeight/2)
                    
                    -- Can barı
                    drawings.Health.Visible = true
                    drawings.Health.Size = Vector2.new(4, boxHeight * healthPercent)
                    drawings.Health.Position = Vector2.new(pos.X - boxWidth/2 - 6, pos.Y + boxHeight/2 - (boxHeight * healthPercent))
                    
                    if healthPercent > 0.6 then
                        drawings.Health.Color = Color3.fromRGB(0, 255, 0)
                    elseif healthPercent > 0.3 then
                        drawings.Health.Color = Color3.fromRGB(255, 255, 0)
                    else
                        drawings.Health.Color = Color3.fromRGB(255, 0, 0)
                    end
                else
                    drawings.Health.Visible = false
                    drawings.HealthBg.Visible = false
                end
                
                -- Distance
                if Config.ESP.Distance and onScreen then
                    drawings.Distance.Visible = true
                    drawings.Distance.Text = mathfloor(distance) .. "m"
                    drawings.Distance.Position = Vector2.new(pos.X, pos.Y + boxHeight/2 + 15)
                else
                    drawings.Distance.Visible = false
                end
                
                -- Tracer
                if Config.ESP.Tracers then
                    drawings.Tracer.Visible = true
                    drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    
                    if onScreen then
                        drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
                    else
                        -- Ekranda değilse kenara çiz
                        local rawDirection = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))
                        local direction = rawDirection.Magnitude > 0 and rawDirection.Unit or Vector2(0, -1)
                        local screenPoint = Vector2.new(
                            Camera.ViewportSize.X / 2 + direction.X * Camera.ViewportSize.X,
                            Camera.ViewportSize.Y / 2 + direction.Y * Camera.ViewportSize.Y
                        )
                        drawings.Tracer.To = Vector2.new(
                            mathclamp(screenPoint.X, 0, Camera.ViewportSize.X),
                            mathclamp(screenPoint.Y, 0, Camera.ViewportSize.Y)
                        )
                    end
                    
                    drawings.Tracer.Color = humanoid.Health > 0 and Config.ESP.Color or Color3.fromRGB(100, 100, 100)
                else
                    drawings.Tracer.Visible = false
                end
            else
                -- Karakter tamamen yoksa tüm drawing'leri kapat
                drawings.Box.Visible = false
                drawings.Name.Visible = false
                drawings.Health.Visible = false
                drawings.HealthBg.Visible = false
                drawings.Distance.Visible = false
                drawings.Tracer.Visible = false
            end
        else
            if drawings then
                drawings.Box.Visible = false
                drawings.Name.Visible = false
                drawings.Health.Visible = false
                drawings.HealthBg.Visible = false
                drawings.Distance.Visible = false
                drawings.Tracer.Visible = false
            end
        end
    end
    
    -- Fullbright
    if Config.Misc.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        fullbrightApplied = true
    elseif fullbrightApplied then
        Lighting.Brightness = DefaultLighting.Brightness
        Lighting.ClockTime = DefaultLighting.ClockTime
        Lighting.GlobalShadows = DefaultLighting.GlobalShadows
        Lighting.FogEnd = DefaultLighting.FogEnd
        fullbrightApplied = false
    end
end)

-- Anti-Aim başlat
StartAntiAim()

-- Open default page
OpenPage("Combat")

if not mousemoverel then
    warn("[KilHub] mousemoverel desteği yok, ThirdPerson aimbot devre dışı kalabilir.")
end

print("[[ KilHub V7.6 FINAL Yüklendi! ]]")
print("→ Aimbot tüm oyunculara kilitlenir")
print("→ Trigger tuşu ayarlanabilir")
print("→ ESP çalışıyor (Box, Name, Health, Distance, Tracer)")

local function isRawExecution()
    local executionContext = getfenv(0).script
    if not executionContext or executionContext == nil then
        return true
    end

    local success, result = pcall(function()
        return game:GetService("CoreGui"):FindFirstChild("RobloxGui") ~= nil
    end)

    local randomKey = tostring(math.random(1000000, 9999999))
    local verificationTable = {}
    verificationTable[randomKey] = "authorized"
    
    if not success or not result or verificationTable[randomKey] ~= "authorized" then
        return true
    end
    
    return false
end

if isRawExecution() then
    warn("⚠️ This script cannot be executed directly. Please use the proper loader.")
    return
end

local authKey = tostring(math.random(100000, 999999))
local authenticated = false

local function authenticateSession(key)
    if key == authKey then
        authenticated = true
        return true
    end
    return false
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    CHECK_INTERVAL = 0.5,
    POSITION_UPDATE_INTERVAL = 0.1,
    HULL_COLOR = Color3.new(1, 0, 0),
    TURRET_COLOR = Color3.new(0, 0, 1),
    USE_VIEWPORT_FRAMES = false,
    TOGGLE_KEY = nil,
    HIGHLIGHT_FILL_TRANSPARENCY = 0.5,
    HIGHLIGHT_OUTLINE_TRANSPARENCY = 0.2
}

local espEnabled = false
local espInitialized = false
local trackedObjects = {}
local timers = {
    lastCheckTime = 0,
    lastPositionUpdateTime = 0
}
local renderStepConnection = nil

local function createESPFolder()
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_UIElements"
    espFolder.Parent = CoreGui
    return espFolder
end

local espFolder = nil

local function cleanupTrackedObject(model, espData)
    if not authenticated then return end
    
    if espData.type == "highlight" and espData.highlight then
        espData.highlight:Destroy()
    elseif espData.type == "viewport" and espData.frame then
        espData.frame:Destroy()
    end
    trackedObjects[model] = nil
end

local function createStealthHighlight(model, color)
    if not authenticated then return nil end
    
    if trackedObjects[model] then return trackedObjects[model] end
    
    if not model or not model:IsA("Model") then return nil end

    if Settings.USE_VIEWPORT_FRAMES then
        local frame = Instance.new("ViewportFrame")
        frame.Size = UDim2.new(0, 0, 0, 0)
        frame.BackgroundTransparency = 1
        frame.Visible = espEnabled
        
        local worldModel = Instance.new("WorldModel", frame)
        local camera = Instance.new("Camera", frame)
        frame.CurrentCamera = camera
        frame.Parent = espFolder

        trackedObjects[model] = {
            type = "viewport",
            frame = frame,
            camera = camera,
            worldModel = worldModel,
            originalModel = model,
            color = color
        }
    else
        local highlight = Instance.new("Highlight")
        highlight.FillColor = color
        highlight.FillTransparency = Settings.HIGHLIGHT_FILL_TRANSPARENCY
        highlight.OutlineColor = color
        highlight.OutlineTransparency = Settings.HIGHLIGHT_OUTLINE_TRANSPARENCY
        highlight.Adornee = espEnabled and model or nil
        highlight.Parent = espFolder

        trackedObjects[model] = {
            type = "highlight",
            highlight = highlight,
            originalModel = model,
            color = color
        }
    end

    return trackedObjects[model]
end

local function updatePositions()
    if not authenticated then return end
    
    for model, espData in pairs(trackedObjects) do
        if not model or not model:IsDescendantOf(game) then
            cleanupTrackedObject(model, espData)
        elseif espEnabled then
            if espData.type == "highlight" then
                espData.highlight.Adornee = model
            elseif espData.type == "viewport" and model:IsA("Model") and model.PrimaryPart then
                local cf = model.PrimaryPart.CFrame
                local size = model:GetExtentsSize()
                espData.camera.CFrame = CFrame.new(cf.Position + cf.LookVector * size.Magnitude * 1.5, cf.Position)
            end
        end
    end
end

local function processChassis(chassis)
    if not authenticated then return end
    
    if not chassis:IsA("Actor") or not chassis.Name:match("^Chassis") then return end
    
    local hullFolder = chassis:FindFirstChild("Hull")
    if hullFolder then
        for _, obj in ipairs(hullFolder:GetChildren()) do
            if obj:IsA("Model") then
                createStealthHighlight(obj, Settings.HULL_COLOR)
                break
            end
        end
    end

    local turretFolder = chassis:FindFirstChild("Turret")
    if turretFolder then
        for _, obj in ipairs(turretFolder:GetChildren()) do
            if obj:IsA("Model") then
                createStealthHighlight(obj, Settings.TURRET_COLOR)
                break
            end
        end
    end
end

local function checkVehicles()
    if not authenticated then return end
    
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        for _, chassis in ipairs(vehiclesFolder:GetChildren()) do
            processChassis(chassis)
        end
    end
end

local function toggleESP()
    if not authenticated then return end
    
    if not Settings.TOGGLE_KEY then
        StarterGui:SetCore("SendNotification", {
            Title = "ESP Error",
            Text = "Please set a keybind first!",
            Duration = 3
        })
        return
    end

    espEnabled = not espEnabled
    
    for model, espData in pairs(trackedObjects) do
        if espData.type == "highlight" then
            espData.highlight.Adornee = espEnabled and model or nil
        elseif espData.type == "viewport" then
            espData.frame.Visible = espEnabled
        end
    end

    StarterGui:SetCore("SendNotification", {
        Title = "ESP Toggle",
        Text = espEnabled and "ESP is ON" or "ESP is OFF",
        Duration = 2
    })
end

local function initializeESP()
    if not authenticated or espInitialized then return end
    
    espFolder = createESPFolder()
    
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and Settings.TOGGLE_KEY and input.KeyCode == Settings.TOGGLE_KEY then
            toggleESP()
        end
    end)
    
    renderStepConnection = RunService.RenderStepped:Connect(function(dt)
        timers.lastCheckTime = timers.lastCheckTime + dt
        timers.lastPositionUpdateTime = timers.lastPositionUpdateTime + dt

        if timers.lastCheckTime >= Settings.CHECK_INTERVAL then
            timers.lastCheckTime = 0
            checkVehicles()
        end

        if timers.lastPositionUpdateTime >= Settings.POSITION_UPDATE_INTERVAL then
            timers.lastPositionUpdateTime = 0
            updatePositions()
        end
    end)
    
    LocalPlayer.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            cleanupESP()
        end
    end)
    
    checkVehicles()
    
    espInitialized = true
    
    StarterGui:SetCore("SendNotification", {
        Title = "ESP Initialized",
        Text = "Press your keybind to toggle ESP",
        Duration = 3
    })
end

local function cleanupESP()
    if not authenticated then return end
    
    for model, espData in pairs(trackedObjects) do
        cleanupTrackedObject(model, espData)
    end
    
    if espFolder and espFolder.Parent then
        espFolder:Destroy()
    end
    
    if renderStepConnection then
        renderStepConnection:Disconnect()
        renderStepConnection = nil
    end
    
    espInitialized = false
end

local function setupGUI()
    if not authenticated then
        warn("Authentication required to initialize GUI")
        return
    end
    
    local success, Window = pcall(function()
        return Rayfield:CreateWindow({
            Name = "RK ESP Hub",
            LoadingTitle = "Loading RK ESP",
            LoadingSubtitle = "By RK",
            ConfigurationSaving = {
                Enabled = true,
                FolderName = "RKESP",
                FileName = "espconfig"
            },
            Discord = {
                Enabled = false
            },
            KeySystem = false
        })
    end)

    if not success then
        warn("Error creating window: " .. tostring(Window))
        return nil
    else
        local MainTab = Window:CreateTab("ESP", 4483362458)
        
        MainTab:CreateKeybind({
            Name = "Set ESP Toggle Key",
            CurrentKeybind = "",
            HoldToInteract = false,
            Flag = "ESPBind",
            Callback = function(Key)
                Settings.TOGGLE_KEY = Key
                
                if not espInitialized and Settings.TOGGLE_KEY then
                    initializeESP()
                end
                
                StarterGui:SetCore("SendNotification", {
                    Title = "Keybind Set",
                    Text = "Press " .. tostring(Key) .. " to toggle ESP",
                    Duration = 3
                })
            end
        })
        
        local InfoTab = Window:CreateTab("Credits", 4483362458)
        InfoTab:CreateParagraph({
            Title = "Made by",
            Content = "RK"
        })
        
        return Window
    end
end

local function shutdownESP()
    if not authenticated then return end
    cleanupESP()
end

local function loadWithKey(loadKey)
    if loadKey and type(loadKey) == "string" and loadKey:match("^RK%-ESP%-[0-9A-F]+$") then
        authenticated = true
        local window = setupGUI()
        return {
            window = window,
            shutdown = shutdownESP,
            authKey = authKey
        }
    else
        warn("Invalid loader key. Access denied.")
        return false
    end
end

return {
    load = loadWithKey,
    version = "1.2.3"
}

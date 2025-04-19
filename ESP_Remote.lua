-- ESP with Rayfield Keybind - Optimized by Claude
-- Original credits: RK
-- Client-side only implementation

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Settings (moved to the top for easy configuration)
local Settings = {
    CHECK_INTERVAL = 0.5,
    POSITION_UPDATE_INTERVAL = 0.1, -- Added small interval for smoother updates
    HULL_COLOR = Color3.new(1, 0, 0),
    TURRET_COLOR = Color3.new(0, 0, 1),
    USE_VIEWPORT_FRAMES = false,
    TOGGLE_KEY = nil, -- Initially nil, will be set by the keybind input
    HIGHLIGHT_FILL_TRANSPARENCY = 0.5,
    HIGHLIGHT_OUTLINE_TRANSPARENCY = 0.2
}

-- State variables
local espEnabled = false -- Starting as disabled until keybind is set
local espInitialized = false -- Tracks if the ESP system has been initialized
local trackedObjects = {}
local timers = {
    lastCheckTime = 0,
    lastPositionUpdateTime = 0
}
local renderStepConnection = nil

-- Create ESP container
local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_UIElements"
espFolder.Parent = CoreGui

-- Helper Functions
local function cleanupTrackedObject(model, espData)
    if espData.type == "highlight" and espData.highlight then
        espData.highlight:Destroy()
    elseif espData.type == "viewport" and espData.frame then
        espData.frame:Destroy()
    end
    trackedObjects[model] = nil
end

local function createStealthHighlight(model, color)
    -- Return existing tracker if found
    if trackedObjects[model] then return trackedObjects[model] end
    
    -- Check if model is valid
    if not model or not model:IsA("Model") then return nil end

    -- Create appropriate ESP element
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
    for model, espData in pairs(trackedObjects) do
        -- Clean up if model no longer exists
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
    if not chassis:IsA("Actor") or not chassis.Name:match("^Chassis") then return end
    
    -- Process Hull
    local hullFolder = chassis:FindFirstChild("Hull")
    if hullFolder then
        for _, obj in ipairs(hullFolder:GetChildren()) do
            if obj:IsA("Model") then
                createStealthHighlight(obj, Settings.HULL_COLOR)
                break -- Only highlight the first model
            end
        end
    end

    -- Process Turret
    local turretFolder = chassis:FindFirstChild("Turret")
    if turretFolder then
        for _, obj in ipairs(turretFolder:GetChildren()) do
            if obj:IsA("Model") then
                createStealthHighlight(obj, Settings.TURRET_COLOR)
                break -- Only highlight the first model
            end
        end
    end
end

local function checkVehicles()
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        for _, chassis in ipairs(vehiclesFolder:GetChildren()) do
            processChassis(chassis)
        end
    end
end

local function toggleESP()
    if not Settings.TOGGLE_KEY then
        StarterGui:SetCore("SendNotification", {
            Title = "ESP Error",
            Text = "Please set a keybind first!",
            Duration = 3
        })
        return
    end

    espEnabled = not espEnabled
    
    -- Update all tracked objects
    for model, espData in pairs(trackedObjects) do
        if espData.type == "highlight" then
            espData.highlight.Adornee = espEnabled and model or nil
        elseif espData.type == "viewport" then
            espData.frame.Visible = espEnabled
        end
    end

    -- Notify user
    StarterGui:SetCore("SendNotification", {
        Title = "ESP Toggle",
        Text = espEnabled and "ESP is ON" or "ESP is OFF",
        Duration = 2
    })
end

-- Initialize ESP functionality
local function initializeESP()
    if espInitialized then return end
    
    -- Set up the input handler for the toggle key
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and Settings.TOGGLE_KEY and input.KeyCode == Settings.TOGGLE_KEY then
            toggleESP()
        end
    end)
    
    -- Set up the main update loop
    renderStepConnection = RunService.RenderStepped:Connect(function(dt)
        timers.lastCheckTime = timers.lastCheckTime + dt
        timers.lastPositionUpdateTime = timers.lastPositionUpdateTime + dt

        -- Check for new vehicles periodically
        if timers.lastCheckTime >= Settings.CHECK_INTERVAL then
            timers.lastCheckTime = 0
            checkVehicles()
        end

        -- Update ESP positions more frequently for smoothness
        if timers.lastPositionUpdateTime >= Settings.POSITION_UPDATE_INTERVAL then
            timers.lastPositionUpdateTime = 0
            updatePositions()
        end
    end)
    
    -- Handle script cleanup when the player leaves or rejoins
    LocalPlayer.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            cleanupESP()
        end
    end)
    
    -- Initial vehicle check
    checkVehicles()
    
    espInitialized = true
    
    StarterGui:SetCore("SendNotification", {
        Title = "ESP Initialized",
        Text = "Press your keybind to toggle ESP",
        Duration = 3
    })
end

-- Handle cleanup when the player leaves or rejoins
local function cleanupESP()
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
}

-- GUI Setup
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
else
    -- Main ESP Tab
    local MainTab = Window:CreateTab("ESP", 4483362458)
    
    MainTab:CreateKeybind({
        Name = "Set ESP Toggle Key",
        CurrentKeybind = "",
        HoldToInteract = false,
        Flag = "ESPBind",
        Callback = function(Key)
            Settings.TOGGLE_KEY = Key
            
            -- Initialize ESP system after keybind is set
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
    
    -- Credits Tab
    local InfoTab = Window:CreateTab("Credits", 4483362458)
    InfoTab:CreateParagraph({
        Title = "Made by",
        Content = "RK"
    })
end

-- Cleanup function for manual triggering if needed
local function shutdownESP()
    cleanupESP()
end

-- Expose cleanup function to _G for manual shutdown if needed
_G.ShutdownESP = shutdownESP

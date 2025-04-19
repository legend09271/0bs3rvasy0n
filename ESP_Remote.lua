-- ESP with Rayfield Keybind & Credits by RK

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Settings
local CHECK_INTERVAL = 0.5
local POSITION_UPDATE_INTERVAL = 0
local HULL_COLOR = Color3.new(1, 0, 0)
local TURRET_COLOR = Color3.new(0, 0, 1)
local USE_VIEWPORT_FRAMES = false

local TOGGLE_KEY = Enum.KeyCode.F
local espEnabled = true
local trackedObjects = {}
local lastCheckTime, lastPositionUpdateTime = 0, 0

-- GUI Setup
local espFolder = Instance.new("Folder")
espFolder.Name = "UIElements"
espFolder.Parent = CoreGui

-- Functions
local function createStealthHighlight(model, color)
    if trackedObjects[model] then return trackedObjects[model] end

    if USE_VIEWPORT_FRAMES then
        local frame = Instance.new("ViewportFrame")
        frame.Size = UDim2.new(0, 0, 0, 0)
        frame.BackgroundTransparency = 1
        frame.Visible = false

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

        return trackedObjects[model]
    else
        local highlight = Instance.new("Highlight")
        highlight.FillColor = color
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = color
        highlight.OutlineTransparency = 0.2
        highlight.Parent = espFolder

        trackedObjects[model] = {
            type = "highlight",
            highlight = highlight,
            originalModel = model,
            color = color
        }

        return trackedObjects[model]
    end
end

local function updatePositions()
    for model, espData in pairs(trackedObjects) do
        if not model or not model:IsDescendantOf(game) then
            if espData.type == "highlight" and espData.highlight then
                espData.highlight:Destroy()
            elseif espData.type == "viewport" and espData.frame then
                espData.frame:Destroy()
            end
            trackedObjects[model] = nil
        elseif espEnabled then
            if espData.type == "highlight" then
                espData.highlight.Adornee = model
            elseif espData.type == "viewport" and model:IsA("Model") and model.PrimaryPart then
                local cf = model.PrimaryPart.CFrame
                local size = model:GetExtentsSize()
                espData.camera.CFrame = CFrame.new(cf.Position + cf.LookVector * size.Magnitude * 1.5, cf.Position)
                espData.frame.Visible = espEnabled
            end
        end
    end
end

local function processChassis(chassis)
    if chassis:IsA("Actor") and chassis.Name:match("^Chassis") then
        local hullFolder = chassis:FindFirstChild("Hull")
        if hullFolder then
            for _, obj in ipairs(hullFolder:GetChildren()) do
                if obj:IsA("Model") then
                    createStealthHighlight(obj, HULL_COLOR)
                    break
                end
            end
        end

        local turretFolder = chassis:FindFirstChild("Turret")
        if turretFolder then
            for _, obj in ipairs(turretFolder:GetChildren()) do
                if obj:IsA("Model") then
                    createStealthHighlight(obj, TURRET_COLOR)
                    break
                end
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

-- GUI
local Window = Rayfield:CreateWindow({
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

local MainTab = Window:CreateTab("ESP", 4483362458)

MainTab:CreateKeybind({
    Name = "Toggle ESP",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Flag = "ESPBind",
    Callback = function(Key)
        TOGGLE_KEY = Key
    end
})

local InfoTab = Window:CreateTab("Credits", 4483362458)
InfoTab:CreateParagraph({
    Title = "Made by",
    Content = "RK"
})

-- Toggle ESP
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == TOGGLE_KEY then
        espEnabled = not espEnabled

        for model, espData in pairs(trackedObjects) do
            if espData.type == "highlight" then
                espData.highlight.Adornee = espEnabled and model or nil
            elseif espData.type == "viewport" then
                espData.frame.Visible = espEnabled
            end
        end

        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ESP Toggle",
            Text = espEnabled and "ESP is ON" or "ESP is OFF",
            Duration = 2
        })
    end
end)

-- Loops
RunService.RenderStepped:Connect(function(dt)
    lastCheckTime += dt
    lastPositionUpdateTime += dt

    if lastCheckTime >= CHECK_INTERVAL then
        lastCheckTime = 0
        checkVehicles()
    end

    if lastPositionUpdateTime >= POSITION_UPDATE_INTERVAL then
        lastPositionUpdateTime = 0
        updatePositions()
    end
end)

checkVehicles()
game:BindToClose(function()
    espFolder:Destroy()
    trackedObjects = {}
end)

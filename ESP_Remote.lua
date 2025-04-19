-- Stealth ESP + Rayfield UI (hidden remotely)
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local Players         = game:GetService("Players")
local CoreGui         = game:GetService("CoreGui")
local LocalPlayer     = Players.LocalPlayer

-- CONFIG
local HULL_COLOR      = Color3.new(1,0,0)
local TURRET_COLOR    = Color3.new(0,0,1)
local USE_VIEWPORT    = false

-- STATE
local espEnabled      = true
local tracked         = {}
local folder          = Instance.new("Folder", CoreGui)
folder.Name           = "UIElements"

-- Highlight creator
local function createHighlight(mdl, color)
    if tracked[mdl] then return end
    if USE_VIEWPORT then
        -- (viewport code omitted for brevity)
    else
        local hl = Instance.new("Highlight", folder)
        hl.Adornee            = mdl
        hl.FillColor          = color
        hl.FillTransparency   = 0.5
        hl.OutlineColor       = color
        hl.OutlineTransparency= 0.2
        tracked[mdl] = hl
    end
end

-- Update & scan
local function update()
    for mdl,hl in pairs(tracked) do
        if not mdl:IsDescendantOf(game) then
            hl:Destroy()
            tracked[mdl] = nil
        end
    end
end
local function scan()
    local vf = workspace:FindFirstChild("Vehicles")
    if vf then
        for _,ch in ipairs(vf:GetChildren()) do
            if ch:IsA("Actor") and ch.Name:match("^Chassis") then
                local hull, tur = ch:FindFirstChild("Hull"), ch:FindFirstChild("Turret")
                if hull then createHighlight(hull:FindFirstChildWhichIsA("Model"), HULL_COLOR) end
                if tur  then createHighlight(tur:FindFirstChildWhichIsA("Model"), TURRET_COLOR) end
            end
        end
    end
end

RunService.RenderStepped:Connect(function(dt)
    scan(); update()
end)

-- Now load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window  = Rayfield:CreateWindow({
    Name         = "Stealth ESP Hub",
    LoadingTitle = "Initializing...",
    LoadingSubtitle="by RK",
    Theme        = "Serenity",
    KeySystem    = false,
})
local Tab = Window:CreateTab("Controls","menu")

Tab:CreateKeybind({
    Name            = "Toggle ESP",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Flag            = "ESPToggle",
    Callback        = function() 
        espEnabled = not espEnabled
        for mdl,hl in pairs(tracked) do
            if USE_VIEWPORT then hl.frame.Visible = espEnabled 
            else hl.Adornee = espEnabled and mdl or nil end
        end
        Rayfield:Notify({Title="ESP Toggle",Content=espEnabled and "ON" or "OFF",Duration=3})
    end,
})

local credits = Tab:CreateSection("Credits")
Tab:CreateLabel("Created by RK", 4483362458, Color3.new(1,1,1), true)

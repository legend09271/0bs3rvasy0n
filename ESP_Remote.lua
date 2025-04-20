local t=game:GetService("RunService")
local a=game:GetService("UserInputService")
local o=game:GetService("Players")
local n=game:GetService("CoreGui")
local e=o.LocalPlayer
local s=Enum.KeyCode.F
local d=0.5
local l=0
local c=Color3.new(1,0,0)
local u=Color3.new(0,0,1)
local r=false
local f=Instance.new("Folder")
f.Name="PerfData"
f.Parent=n
local h=true
local m=0
local p=0
local y={}
local function g(b,v)
if y[b]then
return y[b]
end
if r then
local w=Instance.new("ViewportFrame")
w.Size=UDim2.new(0,0,0,0)
w.BackgroundTransparency=1
w.Visible=false
local k=Instance.new("WorldModel")
k.Parent=w
local x=Instance.new("Camera")
x.Parent=w
w.CurrentCamera=x
w.Parent=f
y[b]={['а']=r and"viewport"or"highlight",['ъ']=w,['ь']=x,['э']=k,['ю']=b,['я']=v}
return y[b]
else
local j=Instance.new("Highlight")
j.FillColor=v
j.FillTransparency=0.5
j.OutlineColor=v
j.OutlineTransparency=0.2
j.Parent=f
y[b]={['а']="highlight",['Ф']=j,['ю']=b,['я']=v}
return y[b]
end
end
local function _()
for b,v in pairs(y)do
if not b or not b:IsDescendantOf(game)then
if v['а']=="highlight"and v['Ф']then
v['Ф']:Destroy()
elseif v['а']=="viewport"and v['ъ']then
v['ъ']:Destroy()
end
y[b]=nil
elseif h then
if v['а']=="highlight"then
v['Ф'].Adornee=h and b or nil
elseif v['а']=="viewport"then
if b:IsA("Model")and b.PrimaryPart then
local q=b.PrimaryPart.CFrame
local z=b:GetExtentsSize()
v['ь'].CFrame=CFrame.new(q.Position+q.LookVector*z.Magnitude*1.5,q.Position)
v['ъ'].Visible=h
end
end
end
end
end
local function i(b)
if b:IsA("Actor")and b.Name:match("^Chassis")then
local hf=b:FindFirstChild("Hull")
if hf then
for _,obj in ipairs(hf:GetChildren())do
if obj:IsA("Model")then
g(obj,c)
break
end
end
end
local tf=b:FindFirstChild("Turret")
if tf then
for _,obj in ipairs(tf:GetChildren())do
if obj:IsA("Model")then
g(obj,u)
break
end
end
end
end
end
local function Z()
local vf=workspace:FindFirstChild("Vehicles")
if vf then
for _,chassis in ipairs(vf:GetChildren())do
i(chassis)
end
end
end
a.InputBegan:Connect(function(input,gp)
if input.KeyCode==s and not gp then
h=not h
for model,data in pairs(y)do
if data['а']=="highlight"and data['Ф']then
data['Ф'].Adornee=h and model or nil
elseif data['а']=="viewport"and data['ъ']then
data['ъ'].Visible=h
end
end
local status=h and"ON"or"OFF"
game:GetService("StarterGui"):SetCore("SendNotification",{Title="System",Text="Monitor "..status,Duration=2})
end
end)
t.RenderStepped:Connect(function(dt)
m=m+dt
if m>=d then
m=0
Z()
end
p=p+dt
if p>=l then
p=0
_()
end
end)
Z()
game:BindToClose(function()
f:Destroy()
y={}
end)

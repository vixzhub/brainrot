local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local cloakName = "Laser Cape"
local activeCloak = nil
local cloakCheckCooldown = 0.05
local autoEquipEnabled = true
local ESPEnabled = false
local lastCloakCheck = 0
local MIN_COOLDOWN, MAX_COOLDOWN = 0.01,1.2

local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui",playerGui)
screenGui.Name = "PedroHubGUI"

-- tela de carregamento
local loadFrame = Instance.new("Frame",screenGui)
loadFrame.Size = UDim2.new(1,0,1,0)
loadFrame.BackgroundColor3 = Color3.new(0,0,0)
local loadLabel = Instance.new("TextLabel",loadFrame)
loadLabel.Size = UDim2.new(1,0,0,100)
loadLabel.Position = UDim2.new(0,0,0.45,0)
loadLabel.BackgroundTransparency = 1
loadLabel.Text = "Pedro Hub V1.5"
loadLabel.Font = Enum.Font.GothamBold
loadLabel.TextSize = 46
loadLabel.TextColor3 = Color3.fromRGB(0,255,255)
loadLabel.TextStrokeTransparency = 0.6

local dots = 0
local loadConn
loadConn = RunService.Heartbeat:Connect(function()
    dots = (dots + 1) % 4
    loadLabel.Text = "Pedro Hub V1.5"..string.rep(".",dots)
end)

local MAIN_W, MAIN_H = 350, 450
local mainFrame = Instance.new("Frame",screenGui)
mainFrame.Size = UDim2.new(0,MAIN_W,0,MAIN_H)
mainFrame.Position = UDim2.new(0.5,0,0.5,0)
mainFrame.AnchorPoint = Vector2.new(0.5,0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
local UICorner = Instance.new("UICorner",mainFrame)
UICorner.CornerRadius = UDim.new(0,16)

local header = Instance.new("TextLabel",mainFrame)
header.Size = UDim2.new(1,0,0,50)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(30,30,30)
header.BorderSizePixel = 0
header.Text = "💎 Pedro Hub"
header.Font = Enum.Font.GothamBold
header.TextSize = 22
header.TextColor3 = Color3.fromRGB(0,255,255)
local hc = Instance.new("UICorner",header)
hc.CornerRadius = UDim.new(0,12)

local buttonContainer = Instance.new("Frame",mainFrame)
buttonContainer.Size = UDim2.new(1,0,1,-60)
buttonContainer.Position = UDim2.new(0,0,0,50)
buttonContainer.BackgroundTransparency = 1
local uiList = Instance.new("UIListLayout",buttonContainer)
uiList.Padding = UDim.new(0,12)
uiList.FillDirection = Enum.FillDirection.Vertical
uiList.SortOrder = Enum.SortOrder.LayoutOrder
local uiPadding = Instance.new("UIPadding",buttonContainer)
uiPadding.PaddingTop = UDim.new(0,12)
uiPadding.PaddingBottom = UDim.new(0,12)
uiPadding.PaddingLeft = UDim.new(0,18)
uiPadding.PaddingRight = UDim.new(0,18)

local function makeButton(parent,text)
    local b = Instance.new("TextButton",parent)
    b.Size = UDim2.new(1,0,0,40)
    b.BackgroundColor3 = Color3.fromRGB(40,40,40)
    b.TextColor3 = Color3.fromRGB(200,255,255)
    b.Text = text
    b.Font = Enum.Font.Gotham
    b.TextSize = 16
    local c = Instance.new("UICorner",b)
    c.CornerRadius = UDim.new(0,12)
    return b
end

local toggleButton = makeButton(buttonContainer,"Auto-Equip: ON")
local autoIndicator = Instance.new("Frame",toggleButton)
autoIndicator.Size = UDim2.new(0,12,0,12)
autoIndicator.Position = UDim2.new(0.92,0,0.2,0)
autoIndicator.BackgroundColor3 = Color3.fromRGB(80,255,120)
autoIndicator.BorderSizePixel = 0
local aiCorner = Instance.new("UICorner",autoIndicator)
aiCorner.CornerRadius = UDim.new(0,6)
toggleButton.MouseButton1Click:Connect(function()
    autoEquipEnabled = not autoEquipEnabled
    toggleButton.Text = "Auto-Equip: "..(autoEquipEnabled and "ON" or "OFF")
    autoIndicator.BackgroundColor3 = autoEquipEnabled and Color3.fromRGB(80,255,120) or Color3.fromRGB(200,60,60)
end)

local espButton = makeButton(buttonContainer,"ESP: OFF")
local espIndicator = Instance.new("Frame",espButton)
espIndicator.Size = UDim2.new(0,12,0,12)
espIndicator.Position = UDim2.new(0.92,0,0.2,0)
espIndicator.BackgroundColor3 = Color3.fromRGB(200,60,60)
espIndicator.BorderSizePixel = 0
local eiCorner = Instance.new("UICorner",espIndicator)
eiCorner.CornerRadius = UDim.new(0,6)
espButton.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    espButton.Text = "ESP: "..(ESPEnabled and "ON" or "OFF")
    espIndicator.BackgroundColor3 = ESPEnabled and Color3.fromRGB(80,255,120) or Color3.fromRGB(200,60,60)
end)

local speedLabel = Instance.new("TextLabel",buttonContainer)
speedLabel.Size = UDim2.new(1,0,0,20)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(170,255,255)
speedLabel.Text = string.format("Velocidade: %.2fs",cloakCheckCooldown)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14

local sliderFrame = Instance.new("Frame",buttonContainer)
sliderFrame.Size = UDim2.new(1,0,0,18)
sliderFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
local sliderCorner = Instance.new("UICorner",sliderFrame)
sliderCorner.CornerRadius = UDim.new(0,10)
local sliderFill = Instance.new("Frame",sliderFrame)
sliderFill.Size = UDim2.new( ( (cloakCheckCooldown-MIN_COOLDOWN)/(MAX_COOLDOWN-MIN_COOLDOWN) ),0,1,0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0,160,255)
local fillCorner = Instance.new("UICorner",sliderFill)
fillCorner.CornerRadius = UDim.new(0,10)
local sliderDragging = false
sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
    end
end)
sliderFrame.InputEnded:Connect(function() sliderDragging = false end)
RunService.Heartbeat:Connect(function()
    if sliderDragging then
        local mousePos = UserInputService:GetMouseLocation()
        local relativeX = math.clamp((mousePos.X - sliderFrame.AbsolutePosition.X)/sliderFrame.AbsoluteSize.X,0,1)
        cloakCheckCooldown = MIN_COOLDOWN + relativeX*(MAX_COOLDOWN-MIN_COOLDOWN)
        speedLabel.Text = string.format("Velocidade: %.2fs",cloakCheckCooldown)
        sliderFill.Size = UDim2.new(relativeX,0,1,0)
    end
end)

local jobIdBox = Instance.new("TextBox",buttonContainer)
jobIdBox.Size = UDim2.new(1,0,0,30)
jobIdBox.BackgroundColor3 = Color3.fromRGB(6,6,30)
jobIdBox.TextColor3 = Color3.fromRGB(180,255,255)
jobIdBox.PlaceholderText = "Cole o JobId aqui"
jobIdBox.Font = Enum.Font.Gotham
local jobCorner = Instance.new("UICorner",jobIdBox)
jobCorner.CornerRadius = UDim.new(0,10)

local teleportButton = makeButton(buttonContainer,"Entrar no servidor")
teleportButton.MouseButton1Click:Connect(function()
    local jobId = jobIdBox.Text
    if jobId and jobId~="" then
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player) end)
    end
end)

-- Bola flutuante
local floatButton = Instance.new("TextButton",screenGui)
floatButton.Size = UDim2.new(0,50,0,50)
floatButton.Position = UDim2.new(0,20,0.5,-25)
floatButton.BackgroundColor3 = Color3.fromRGB(0,255,255)
floatButton.Text = "💎"
floatButton.TextScaled = true
floatButton.TextColor3 = Color3.fromRGB(20,20,20)
local floatCorner = Instance.new("UICorner",floatButton)
floatCorner.CornerRadius = UDim.new(0,25)
local draggingFloat, dragStartFloat, startPosFloat = false,nil,nil
floatButton.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        draggingFloat = true
        dragStartFloat = input.Position
        startPosFloat = floatButton.Position
    end
end)
floatButton.InputChanged:Connect(function(input)
    if draggingFloat then
        local delta = input.Position - dragStartFloat
        local screenSize = workspace.CurrentCamera.ViewportSize
        local maxX = math.max(0,screenSize.X-floatButton.AbsoluteSize.X)
        local maxY = math.max(0,screenSize.Y-floatButton.AbsoluteSize.Y)
        floatButton.Position = UDim2.new(0,math.clamp(startPosFloat.X.Offset+delta.X,0,maxX),
                                         0,math.clamp(startPosFloat.Y.Offset+delta.Y,0,maxY))
    end
end)
floatButton.InputEnded:Connect(function() draggingFloat=false end)
floatButton.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)

-- Drag do mainFrame
local dragging, dragStart, startPos = false,nil,nil
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local screenSize = workspace.CurrentCamera.ViewportSize
        local maxX = math.max(0,screenSize.X-mainFrame.AbsoluteSize.X)
        local maxY = math.max(0,screenSize.Y-mainFrame.AbsoluteSize.Y)
        mainFrame.Position = UDim2.new(0,math.clamp(startPos.X.Offset+delta.X,0,maxX),
                                       0,math.clamp(startPos.Y.Offset+delta.Y,0,maxY))
    end
end)

task.delay(1.5,function()
    if loadConn then loadConn:Disconnect() end
    loadFrame:Destroy()
    mainFrame.Visible = true
end)

-- FUNÇÃO LÁSER CAPE
local function findCloakInBackpack()
    local bp = player:FindFirstChild("Backpack")
    return bp and bp:FindFirstChild(cloakName) or nil
end
local function findCloakInCharacter()
    local ch = player.Character
    return ch and ch:FindFirstChild(cloakName) or nil
end

player.CharacterAdded:Connect(function(char) activeCloak=nil task.delay(0.5,function() activeCloak=findCloakInCharacter() end) end)
player.Character.ChildAdded:Connect(function(c) if c.Name==cloakName then activeCloak=c end end)
player.Character.ChildRemoved:Connect(function(c) if c.Name==cloakName and activeCloak==c then activeCloak=nil end end)

local function enforceCloak()
    if not player.Character or not autoEquipEnabled then return end
    if tick()-lastCloakCheck<cloakCheckCooldown then return end
    lastCloakCheck=tick()
    local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local cloak=findCloakInCharacter()
    if cloak then activeCloak=cloak return end
    local cloakBP=findCloakInBackpack()
    if cloakBP then
        task.spawn(function()
            pcall(function() humanoid:EquipTool(cloakBP) end)
            task.wait(0.12)
            activeCloak=findCloakInCharacter() or cloakBP
        end)
    end
end
RunService.Heartbeat:Connect(enforceCloak)

-- ESP
local ESPFolder = Instance.new("Folder",screenGui)
ESPFolder.Name="ESP"
local function createESP(plr)
    if not plr.Character then return end
    local head = plr.Character:FindFirstChild("Head")
    if not head then return end
    local bg = Instance.new("BillboardGui",ESPFolder)
    bg.Adornee=head
    bg.Size=UDim2.new(0,150,0,50)
    bg.AlwaysOnTop=true
    local label = Instance.new("TextLabel",bg)
    label.Size=UDim2.new(1,0,1,0)
    label.BackgroundTransparency=0.5
    label.BackgroundColor3=Color3.new(0,0,0)
    label.TextColor3=Color3.fromRGB(0,255,255)
    label.TextStrokeTransparency=0.6
    label.Font=Enum.Font.GothamBold
    label.TextScaled=true
    return {bg=bg,label=label,player=plr}
end

local ESPTable = {}
Players.PlayerAdded:Connect(function(plr) task.delay(1,function() table.insert(ESPTable,createESP(plr)) end) end)
for _,plr in ipairs(Players:GetPlayers()) do if plr~=player then table.insert(ESPTable,createESP(plr)) end end
RunService.Heartbeat:Connect(function()
    if ESPEnabled then
        for i,v in ipairs(ESPTable) do
            local plr = v.player
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local dist = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and
                             (plr.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude or 0
                v.label.Text = plr.Name.." | "..math.floor(dist).." studs"
                v.bg.Enabled = true
            else v.bg.Enabled=false end
        end
    else
        for i,v in ipairs(ESPTable) do v.bg.Enabled=false end
    end
end)
print("Pedro Hub V1.5 carregado")

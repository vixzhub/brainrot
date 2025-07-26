-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Estados
local isUp = false
local isMoving = false
local platform = nil
local playerESPEnabled = true
local rarityESPEnabled = true
local wallBypass = false
local speedEnabled = false
local espLoop = true
local currentSpeed = 50
local currentTab = "Main"
local hopping = false

-- Configurações de Raridades
local raritiesConfig = {
    Common = {enabled = true, color = Color3.new(1,1,1)},
    Rare = {enabled = true, color = Color3.new(0,1,0)},
    Epic = {enabled = true, color = Color3.new(0,0.5,1)},
    Legendary = {enabled = true, color = Color3.new(0.5,0,1)},
    Mythic = {enabled = true, color = Color3.new(1,0.8,0)}
}

-- Cache para ESPs
local trackedPlayers = {}
local trackedRarities = {}

-- Função para criar botões estilizados
local function createButton(text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = color
    btn.AutoButtonColor = false
    btn.ZIndex = 2
    
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(200, 200, 255)
    stroke.Thickness = 1
    
    -- Animação de hover
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0,
            Size = UDim2.new(btn.Size.X.Scale + 0.02, 0, 0, btn.Size.Y.Offset + 2)
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2,
            Size = UDim2.new(btn.Size.X.Scale - 0.02, 0, 0, btn.Size.Y.Offset - 2)
        }):Play()
    end)
    
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundTransparency = 0.4,
            Size = UDim2.new(btn.Size.X.Scale - 0.02, 0, 0, btn.Size.Y.Offset - 2)
        }):Play()
    end)
    
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundTransparency = 0.2,
            Size = UDim2.new(btn.Size.X.Scale, 0, 0, btn.Size.Y.Offset)
        }):Play()
        callback()
    end)
    
    return btn
end

-- Função para aplicar velocidade
local function applySpeed()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = speedEnabled and currentSpeed or 16
        end
    end
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    applySpeed()
end)

-- TELEPORT UP/DOWN
local function teleportUpDown()
    if isMoving then return end
    isMoving = true
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        isMoving = false
        return
    end
    if not isUp then
        platform = Instance.new("Part", workspace)
        platform.Size = Vector3.new(6,1,6)
        platform.Anchored = true
        platform.Transparency = 1
        platform.CanCollide = true
        platform.Position = root.Position + Vector3.new(0,55,0)
        root.Anchored = true
        root.CFrame = platform.CFrame + Vector3.new(0,3,0)
        task.wait(0.5)
        root.Anchored = false
        isUp = true
    else
        root.Anchored = true
        root.CFrame = platform.CFrame - Vector3.new(0,52,0)
        task.wait(0.5)
        root.Anchored = false
        platform:Destroy()
        platform = nil
        isUp = false
    end
    isMoving = false
end

-- WALL CLIMB
local wallClimbConnection
wallClimbConnection = RunService.RenderStepped:Connect(function()
    if wallBypass then
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if root and hum and hum.MoveDirection.Magnitude > 0 then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = {char}
            local result = workspace:Raycast(root.Position, root.CFrame.LookVector * 2 + Vector3.new(0, 2, 0), params)
            if result and result.Instance and result.Normal.Y < 0.5 then
                root.Velocity = Vector3.new(0, 50, 0)
            end
        end
    end
end)

-- Função otimizada para ESP de jogadores
local function updatePlayerESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local char = plr.Character
            local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            
            if humanoidRootPart and head then
                if not trackedPlayers[plr] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "PlayerHighlight"
                    highlight.FillColor = Color3.new(1, 0, 0)
                    highlight.OutlineColor = Color3.new(1, 1, 1)
                    highlight.FillTransparency = 0.7
                    highlight.OutlineTransparency = 0
                    highlight.Parent = char
                    
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "PlayerESPTag"
                    billboard.Size = UDim2.new(0, 100, 0, 20)
                    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = head
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = plr.Name
                    label.Font = Enum.Font.GothamBold
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.TextStrokeTransparency = 0.5
                    label.Parent = billboard
                    
                    trackedPlayers[plr] = {
                        highlight = highlight,
                        billboard = billboard,
                        label = label
                    }
                end
                
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (player.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                    trackedPlayers[plr].label.Text = plr.Name .. " (" .. math.floor(distance) .. "m)"
                end
            end
        elseif trackedPlayers[plr] then
            trackedPlayers[plr].highlight:Destroy()
            trackedPlayers[plr].billboard:Destroy()
            trackedPlayers[plr] = nil
        end
    end
end

-- Função otimizada para ESP de raridade
local function updateRarityESP()
    for obj, _ in pairs(trackedRarities) do
        if not obj.Parent then
            trackedRarities[obj] = nil
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and raritiesConfig[obj.Text] and raritiesConfig[obj.Text].enabled then
            local model = obj:FindFirstAncestorOfClass("Model")
            if model and not trackedRarities[model] then
                local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model.PrimaryPart
                if rootPart then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "RarityESPLabel"
                    billboard.Size = UDim2.new(0, 100, 0, 30)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = rootPart
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.TextSize = 20
                    label.BackgroundTransparency = 1
                    label.Text = obj.Text
                    label.Font = Enum.Font.GothamBold
                    label.TextColor3 = raritiesConfig[obj.Text].color
                    label.Parent = billboard
                    
                    trackedRarities[model] = billboard
                end
            end
        end
    end
end

-- Loop principal otimizado para ESP
task.spawn(function()
    while espLoop do
        if playerESPEnabled then
            updatePlayerESP()
        end
        
        if rarityESPEnabled and tick() % 2 < 0.1 then
            updateRarityESP()
        end
        
        task.wait(0.1)
    end
end)

-- Função para limpar ESPs
local function clearESP()
    for plr, data in pairs(trackedPlayers) do
        data.highlight:Destroy()
        data.billboard:Destroy()
    end
    trackedPlayers = {}
    
    for _, billboard in pairs(trackedRarities) do
        billboard:Destroy()
    end
    trackedRarities = {}
end

-- SPEED HACK COM CONTROLE DE VELOCIDADE
local speedConnection
local function toggleSpeed()
    speedEnabled = not speedEnabled
    
    if speedEnabled then
        speedConnection = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char then return end
            
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = currentSpeed
            end
        end)
    else
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
        
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end
    end
end

-- SERVER HOP MOBILE (VERSÃO SIMPLIFICADA)
local function serverHop()
    if hopping then return end
    hopping = true
    
    -- Notificação mobile
    local notify = Instance.new("Frame", PlayerGui)
    notify.Size = UDim2.new(0.8, 0, 0, 60)
    notify.Position = UDim2.new(0.1, 0, 0.05, 0)
    notify.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    notify.BackgroundTransparency = 0.2
    
    local corner = Instance.new("UICorner", notify)
    corner.CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke", notify)
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Thickness = 2
    
    local label = Instance.new("TextLabel", notify)
    label.Size = UDim2.new(1, -10, 1, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.Text = "🔍 Procurando servidor..."
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(200, 230, 255)
    label.BackgroundTransparency = 1
    label.TextSize = 14
    label.TextWrapped = true
    
    -- Animação de entrada
    notify.Position = UDim2.new(0.1, 0, -0.1, 0)
    TweenService:Create(notify, TweenInfo.new(0.3), {
        Position = UDim2.new(0.1, 0, 0.05, 0)
    }):Play()
    
    -- Método simplificado para mobile
    local success, err = pcall(function()
        TeleportService:Teleport(game.PlaceId) -- Teleporte aleatório padrão
    end)
    
    if not success then
        label.Text = "⚠️ Erro: " .. tostring(err)
    end
    
    -- Remover após 3 segundos
    delay(3, function()
        TweenService:Create(notify, TweenInfo.new(0.3), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.1, 0, -0.1, 0)
        }):Play()
        wait(0.3)
        notify:Destroy()
    end)
    
    hopping = false
end

-- Criação da UI
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "Vixz Hub 👁️"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Frame principal
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 380, 0, 420)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 12)

-- Efeito de vidro
local glass = Instance.new("Frame", mainFrame)
glass.Size = UDim2.new(1, 0, 1, 0)
glass.BackgroundTransparency = 0.9
glass.BackgroundColor3 = Color3.fromRGB(150, 150, 255)
glass.BorderSizePixel = 0
glass.ZIndex = -1

local glassCorner = Instance.new("UICorner", glass)
glassCorner.CornerRadius = UDim.new(0, 12)

-- Barra de título
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 0.5
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
titleBar.BorderSizePixel = 0

local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, 0, 1, 0)
title.Text = "⚡ Vixz Hub  ⚡"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.TextSize = 18

-- Botões de controle
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.AutoButtonColor = false

local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0, 8)

local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0.5, -15)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
minimizeBtn.AutoButtonColor = false

local minimizeCorner = Instance.new("UICorner", minimizeBtn)
minimizeCorner.CornerRadius = UDim.new(0, 8)

-- Barra de abas
local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size = UDim2.new(1, 0, 0, 40)
tabBar.Position = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundTransparency = 1

local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Função para criar abas
local function createTab(name)
    local tab = Instance.new("TextButton", tabBar)
    tab.Size = UDim2.new(0.3, 0, 0.8, 0)
    tab.Text = name
    tab.Font = Enum.Font.GothamBold
    tab.TextSize = 14
    tab.TextColor3 = Color3.new(1, 1, 1)
    tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    tab.BackgroundTransparency = 0.5
    tab.AutoButtonColor = false
    
    local tabCorner = Instance.new("UICorner", tab)
    tabCorner.CornerRadius = UDim.new(0, 8)
    
    tab.MouseButton1Click:Connect(function()
        currentTab = name
        for _, tabName in ipairs({"Sobre", "Main", "Visual"}) do
            local frame = mainFrame:FindFirstChild(tabName.."Frame")
            if frame then
                frame.Visible = (tabName == name)
            end
        end
    end)
    
    return tab
end

-- Criar abas
createTab("Sobre")
createTab("Main")
createTab("Visual")

-- Frames de conteúdo para cada aba
local function createContentFrame(name)
    local frame = Instance.new("Frame", mainFrame)
    frame.Name = name.."Frame"
    frame.Size = UDim2.new(1, -20, 1, -130)
    frame.Position = UDim2.new(0, 10, 0, 90)
    frame.BackgroundTransparency = 1
    frame.Visible = (name == currentTab)
    return frame
end

local sobreFrame = createContentFrame("Sobre")
local mainFrameContent = createContentFrame("Main")
local visualFrame = createContentFrame("Visual")

-- Conteúdo da aba Sobre
local sobreText = [[
⚡ Vixz Hub ⚡
Versão 2.0

Recursos:
- Player ESP (nome e distância)
- Rarity ESP (filtro personalizável)
- Controle de velocidade
- Teleport vertical
- Wall climb
- Server Hop

Desenvolvido por Vixz
]]

local sobreLabel = Instance.new("TextLabel", sobreFrame)
sobreLabel.Size = UDim2.new(1, 0, 1, 0)
sobreLabel.Text = sobreText
sobreLabel.Font = Enum.Font.Gotham
sobreLabel.TextSize = 14
sobreLabel.TextColor3 = Color3.new(1, 1, 1)
sobreLabel.BackgroundTransparency = 1
sobreLabel.TextXAlignment = Enum.TextXAlignment.Left
sobreLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Conteúdo da aba Main
local buttonsFrame = Instance.new("Frame", mainFrameContent)
buttonsFrame.Size = UDim2.new(1, 0, 1, 0)
buttonsFrame.BackgroundTransparency = 1

local gridLayout = Instance.new("UIGridLayout", buttonsFrame)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.CellSize = UDim2.new(0.5, -5, 0, 50)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Criar botões na aba Main
local teleportBtn = createButton("▲/▼ TELEPORT", teleportUpDown, Color3.fromRGB(0, 120, 215))
teleportBtn.Parent = buttonsFrame

local wallBtn = createButton("🧱 WALL CLIMB", function() 
    wallBypass = not wallBypass
end, Color3.fromRGB(50, 180, 80))
wallBtn.Parent = buttonsFrame

local serverHopBtn = createButton("🔄 SERVER HOP", serverHop, Color3.fromRGB(150, 50, 200))
serverHopBtn.Parent = buttonsFrame

-- Botão de velocidade com controle
local speedBtn = createButton("⚡ SPEED: "..currentSpeed, toggleSpeed, Color3.fromRGB(215, 180, 0))
speedBtn.Parent = buttonsFrame

-- Controles de velocidade
local speedControls = Instance.new("Frame", buttonsFrame)
speedControls.Size = UDim2.new(1, 0, 0, 30)
speedControls.BackgroundTransparency = 1

local decreaseBtn = Instance.new("TextButton", speedControls)
decreaseBtn.Size = UDim2.new(0.25, 0, 1, 0)
decreaseBtn.Text = "-"
decreaseBtn.Font = Enum.Font.GothamBold
decreaseBtn.TextSize = 18
decreaseBtn.TextColor3 = Color3.new(1, 1, 1)
decreaseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
decreaseBtn.AutoButtonColor = false

local decreaseCorner = Instance.new("UICorner", decreaseBtn)
decreaseCorner.CornerRadius = UDim.new(0, 6)

local speedDisplay = Instance.new("TextLabel", speedControls)
speedDisplay.Size = UDim2.new(0.5, 0, 1, 0)
speedDisplay.Position = UDim2.new(0.25, 0, 0, 0)
speedDisplay.Text = "Velocidade: "..currentSpeed
speedDisplay.Font = Enum.Font.Gotham
speedDisplay.TextSize = 14
speedDisplay.TextColor3 = Color3.new(1, 1, 1)
speedDisplay.BackgroundTransparency = 1

local increaseBtn = Instance.new("TextButton", speedControls)
increaseBtn.Size = UDim2.new(0.25, 0, 1, 0)
increaseBtn.Position = UDim2.new(0.75, 0, 0, 0)
increaseBtn.Text = "+"
increaseBtn.Font = Enum.Font.GothamBold
increaseBtn.TextSize = 18
increaseBtn.TextColor3 = Color3.new(1, 1, 1)
increaseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
increaseBtn.AutoButtonColor = false

local increaseCorner = Instance.new("UICorner", increaseBtn)
increaseCorner.CornerRadius = UDim.new(0, 6)

-- Funcionalidade dos controles de velocidade
decreaseBtn.MouseButton1Click:Connect(function()
    currentSpeed = math.max(16, currentSpeed - 5)
    speedBtn.Text = "⚡ SPEED: "..currentSpeed
    speedDisplay.Text = "Velocidade: "..currentSpeed
    
    if speedEnabled then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = currentSpeed
            end
        end
    end
end)

increaseBtn.MouseButton1Click:Connect(function()
    currentSpeed = currentSpeed + 5
    speedBtn.Text = "⚡ SPEED: "..currentSpeed
    speedDisplay.Text = "Velocidade: "..currentSpeed
    
    if speedEnabled then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = currentSpeed
            end
        end
    end
end)

-- Conteúdo da aba Visual
local visualContent = Instance.new("Frame", visualFrame)
visualContent.Size = UDim2.new(1, 0, 1, 0)
visualContent.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", visualContent)
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Botão principal do Player ESP
local playerEspBtn = createButton("👁️ PLAYER ESP", function() 
    playerESPEnabled = not playerESPEnabled
    if not playerESPEnabled then 
        for plr, data in pairs(trackedPlayers) do
            data.highlight:Destroy()
            data.billboard:Destroy()
        end
        trackedPlayers = {}
    end
end, Color3.fromRGB(50, 150, 255))
playerEspBtn.Size = UDim2.new(0.9, 0, 0, 50)
playerEspBtn.Parent = visualContent

-- Botão principal do Rarity ESP
local rarityEspBtn = createButton("🧠 RARITY ESP", function() 
    rarityESPEnabled = not rarityESPEnabled
    if not rarityESPEnabled then 
        for _, billboard in pairs(trackedRarities) do
            billboard:Destroy()
        end
        trackedRarities = {}
    end
end, Color3.fromRGB(180, 80, 220))
rarityEspBtn.Size = UDim2.new(0.9, 0, 0, 50)
rarityEspBtn.Parent = visualContent

-- Configurações de Raridades
local raritySettingsFrame = Instance.new("Frame", visualContent)
raritySettingsFrame.Size = UDim2.new(0.9, 0, 0, 180)
raritySettingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
raritySettingsFrame.BackgroundTransparency = 0.7
raritySettingsFrame.BorderSizePixel = 0

local rarityCorner = Instance.new("UICorner", raritySettingsFrame)
rarityCorner.CornerRadius = UDim.new(0, 8)

local rarityTitle = Instance.new("TextLabel", raritySettingsFrame)
rarityTitle.Size = UDim2.new(1, 0, 0, 30)
rarityTitle.Text = "FILTRAR RARIDADES"
rarityTitle.Font = Enum.Font.GothamBold
rarityTitle.TextColor3 = Color3.new(1, 1, 1)
rarityTitle.BackgroundTransparency = 1
rarityTitle.TextSize = 14

local rarityListLayout = Instance.new("UIListLayout", raritySettingsFrame)
rarityListLayout.Padding = UDim.new(0, 5)

-- Criar botões de seleção para cada raridade
for rarityName, config in pairs(raritiesConfig) do
    local rarityBtn = Instance.new("TextButton")
    rarityBtn.Size = UDim2.new(0.9, 0, 0, 30)
    rarityBtn.Position = UDim2.new(0.05, 0, 0, 0)
    rarityBtn.Text = "  "..rarityName
    rarityBtn.Font = Enum.Font.Gotham
    rarityBtn.TextSize = 14
    rarityBtn.TextXAlignment = Enum.TextXAlignment.Left
    rarityBtn.BackgroundColor3 = config.color
    rarityBtn.BackgroundTransparency = 0.7
    rarityBtn.TextColor3 = Color3.new(1,1,1)
    rarityBtn.AutoButtonColor = false
    
    local btnCorner = Instance.new("UICorner", rarityBtn)
    btnCorner.CornerRadius = UDim.new(0, 4)
    
    local toggleIndicator = Instance.new("Frame", rarityBtn)
    toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
    toggleIndicator.Position = UDim2.new(1, -25, 0.5, -10)
    toggleIndicator.BackgroundColor3 = config.enabled and Color3.new(0,1,0) or Color3.new(1,0,0)
    toggleIndicator.BorderSizePixel = 0
    
    local indicatorCorner = Instance.new("UICorner", toggleIndicator)
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    
    rarityBtn.MouseButton1Click:Connect(function()
        raritiesConfig[rarityName].enabled = not raritiesConfig[rarityName].enabled
        toggleIndicator.BackgroundColor3 = raritiesConfig[rarityName].enabled and Color3.new(0,1,0) or Color3.new(1,0,0)
        
        -- Limpar ESPs da raridade desativada
        if not raritiesConfig[rarityName].enabled then
            for model, billboard in pairs(trackedRarities) do
                if billboard:FindFirstChildOfClass("TextLabel").Text == rarityName then
                    billboard:Destroy()
                    trackedRarities[model] = nil
                end
            end
        end
    end)
    
    rarityBtn.Parent = raritySettingsFrame
end

-- Ajustar posicionamento
rarityTitle.Position = UDim2.new(0, 0, 0, 5)
rarityListLayout.Padding = UDim.new(0, 8)
rarityListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Barra de status
local statusBar = Instance.new("Frame", mainFrame)
statusBar.Size = UDim2.new(1, -20, 0, 25)
statusBar.Position = UDim2.new(0, 10, 1, -35)
statusBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
statusBar.BackgroundTransparency = 0.5

local statusCorner = Instance.new("UICorner", statusBar)
statusCorner.CornerRadius = UDim.new(0, 8)

local statusLayout = Instance.new("UIListLayout", statusBar)
statusLayout.FillDirection = Enum.FillDirection.Horizontal
statusLayout.Padding = UDim.new(0, 10)

local statusPadding = Instance.new("UIPadding", statusBar)
statusPadding.PaddingLeft = UDim.new(0, 10)
statusPadding.PaddingRight = UDim.new(0, 10)

-- Função para criar indicadores de status
local function createStatusIndicator(name, color)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 70, 1, 0)
    frame.BackgroundTransparency = 1
    
    local dot = Instance.new("Frame", frame)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0, 0, 0.5, -5)
    dot.BackgroundColor3 = color
    dot.BorderSizePixel = 0
    
    local dotCorner = Instance.new("UICorner", dot)
    dotCorner.CornerRadius = UDim.new(1, 0)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -15, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 20
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    
    return frame
end

-- Criar indicadores
local speedStatus = createStatusIndicator("SPEED", Color3.fromRGB(255, 200, 50))
speedStatus.Parent = statusBar

local playerEspStatus = createStatusIndicator("P.ESP", Color3.fromRGB(50, 150, 255))
playerEspStatus.Parent = statusBar

local rarityEspStatus = createStatusIndicator("R.ESP", Color3.fromRGB(180, 80, 220))
rarityEspStatus.Parent = statusBar

local wallStatus = createStatusIndicator("WALL", Color3.fromRGB(100, 200, 100))
wallStatus.Parent = statusBar

local hopStatus = createStatusIndicator("HOP", Color3.fromRGB(200, 50, 150))
hopStatus.Parent = statusBar

-- Atualizar status
local function updateStatus()
    speedStatus:FindFirstChildOfClass("Frame").BackgroundColor3 = speedEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    playerEspStatus:FindFirstChildOfClass("Frame").BackgroundColor3 = playerESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    rarityEspStatus:FindFirstChildOfClass("Frame").BackgroundColor3 = rarityESPEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    wallStatus:FindFirstChildOfClass("Frame").BackgroundColor3 = wallBypass and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    hopStatus:FindFirstChildOfClass("Frame").BackgroundColor3 = hopping and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
end

-- Atualizar periodicamente
task.spawn(function()
    while true do
        updateStatus()
        task.wait(0.5)
    end
end)

-- Sistema de arrastar com toque
local dragging
local dragInput
local dragStart
local startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- Botão flutuante para reabrir
local floatingBtn = Instance.new("TextButton", gui)
floatingBtn.Size = UDim2.new(0, 50, 0, 50)
floatingBtn.Position = UDim2.new(0, 20, 1, -80)
floatingBtn.Text = "⚡"
floatingBtn.Font = Enum.Font.GothamBold
floatingBtn.TextSize = 24
floatingBtn.TextColor3 = Color3.new(1, 1, 1)
floatingBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
floatingBtn.Visible = false
floatingBtn.AutoButtonColor = false

local floatingCorner = Instance.new("UICorner", floatingBtn)
floatingCorner.CornerRadius = UDim.new(1, 0)

-- Funcionalidade dos botões de controle
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    espLoop = false
    clearESP()
    if speedConnection then
        speedConnection:Disconnect()
    end
    if wallClimbConnection then
        wallClimbConnection:Disconnect()
    end
end)

minimizeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    floatingBtn.Visible = true
end)

floatingBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    floatingBtn.Visible = false
end)

-- Efeito de sombra
local shadow = Instance.new("ImageLabel", mainFrame)
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.8
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.ZIndex = -1

-- Efeito de brilho
local glow = Instance.new("ImageLabel", mainFrame)
glow.Image = "rbxassetid://8992230671"
glow.ImageColor3 = Color3.fromRGB(0, 100, 255)
glow.BackgroundTransparency = 1
glow.Size = UDim2.new(1, 30, 1, 30)
glow.Position = UDim2.new(0, -15, 0, -15)
glow.ZIndex = -1

-- Notificação inicial
task.spawn(function()
    local notify = Instance.new("Frame", gui)
    notify.Size = UDim2.new(0, 300, 0, 50)
    notify.Position = UDim2.new(0.5, -150, 0, 20)
    notify.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    notify.BackgroundTransparency = 0.3
    
    local notifyCorner = Instance.new("UICorner", notify)
    notifyCorner.CornerRadius = UDim.new(0, 12)
    
    local notifyStroke = Instance.new("UIStroke", notify)
    notifyStroke.Color = Color3.fromRGB(0, 200, 255)
    notifyStroke.Thickness = 2
    
    local label = Instance.new("TextLabel", notify)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = "⚡ Vixz Hub - Menu Ativado!"
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(200, 230, 255)
    label.BackgroundTransparency = 1
    label.TextSize = 20
    
    TweenService:Create(notify, TweenInfo.new(0.5), {
        Position = UDim2.new(0.5, -150, 0, 30)
    }):Play()
    
    wait(3)
    
    TweenService:Create(notify, TweenInfo.new(0.5), {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -150, 0, 10)
    }):Play()
    
    TweenService:Create(notifyStroke, TweenInfo.new(0.5), {
        Transparency = 1
    }):Play()
    
    wait(0.5)
    notify:Destroy()
end)

-- Inicializar status
updateStatus()

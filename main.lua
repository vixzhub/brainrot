--// Brainrot ESP - Complete with API Send
--// by cybhor@pedro

-- SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local PLACE_ID = game.PlaceId
local SERVER_URL = "http://br2.bronxyshost.com:4234/discord-relay.php"

-- STATE
local targetJobId = ""
local autoServerHop = false
local autoTeleportAfterSend = true

-- DETECT REQUEST FUNCTION
local reqFunc
if syn and syn.request then
    reqFunc = syn.request
elseif http_request then
    reqFunc = http_request
elseif request then
    reqFunc = request
end

-- CREATE GUI WITH DRAG AND MINIMIZE
local function CreateCompleteGUI()
    -- Wait for PlayerGui
    while not LocalPlayer:FindFirstChild("PlayerGui") do
        wait(0.1)
    end
    
    local playerGui = LocalPlayer.PlayerGui
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BrainrotESP_Complete"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 350)
    mainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Minimized Bar
    local minimizedBar = Instance.new("TextButton")
    minimizedBar.Size = UDim2.new(0, 120, 0, 35)
    minimizedBar.Position = UDim2.new(0.05, 0, 0.1, 0)
    minimizedBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    minimizedBar.BackgroundTransparency = 0.1
    minimizedBar.BorderSizePixel = 0
    minimizedBar.Text = ""
    minimizedBar.Visible = false
    minimizedBar.Parent = screenGui
    
    local minimizedCorner = Instance.new("UICorner")
    minimizedCorner.CornerRadius = UDim.new(0, 8)
    minimizedCorner.Parent = minimizedBar
    
    local minimizedText = Instance.new("TextLabel")
    minimizedText.Size = UDim2.new(1, 0, 1, 0)
    minimizedText.BackgroundTransparency = 1
    minimizedText.Text = "Brainrot ESP"
    minimizedText.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizedText.Font = Enum.Font.GothamBold
    minimizedText.TextSize = 12
    minimizedText.Parent = minimizedBar
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -20, 0, 35)
    header.Position = UDim2.new(0, 10, 0, 10)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BRAINROT ESP"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
    minimizeBtn.Position = UDim2.new(0.75, 0, 0.14, 0)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    minimizeBtn.Text = "_"
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14
    minimizeBtn.Parent = header
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeBtn
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(0.9, 0, 0.14, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -60)
    content.Position = UDim2.new(0, 10, 0, 55)
    content.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    content.BorderSizePixel = 0
    content.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = content
    
    -- JobId Input
    local jobInput = Instance.new("TextBox")
    jobInput.Size = UDim2.new(1, -20, 0, 25)
    jobInput.Position = UDim2.new(0, 10, 0, 10)
    jobInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    jobInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    jobInput.PlaceholderText = "Cole JobId aqui..."
    jobInput.Font = Enum.Font.Gotham
    jobInput.TextSize = 11
    jobInput.Parent = content
    
    local jobCorner = Instance.new("UICorner")
    jobCorner.CornerRadius = UDim.new(0, 6)
    jobCorner.Parent = jobInput
    
    -- Set JobId Button
    local setJobBtn = Instance.new("TextButton")
    setJobBtn.Size = UDim2.new(1, -20, 0, 30)
    setJobBtn.Position = UDim2.new(0, 10, 0, 45)
    setJobBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    setJobBtn.Text = "SET JOB ID"
    setJobBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    setJobBtn.Font = Enum.Font.GothamBold
    setJobBtn.TextSize = 12
    setJobBtn.Parent = content
    
    local setJobCorner = Instance.new("UICorner")
    setJobCorner.CornerRadius = UDim.new(0, 6)
    setJobCorner.Parent = setJobBtn
    
    -- Teleport Button
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(1, -20, 0, 30)
    tpBtn.Position = UDim2.new(0, 10, 0, 85)
    tpBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    tpBtn.Text = "TELEPORT NOW"
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 12
    tpBtn.Parent = content
    
    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 6)
    tpCorner.Parent = tpBtn
    
    -- Join Random Button
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(1, -20, 0, 30)
    joinBtn.Position = UDim2.new(0, 10, 0, 125)
    joinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    joinBtn.Text = "JOIN RANDOM"
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.TextSize = 12
    joinBtn.Parent = content
    
    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 6)
    joinCorner.Parent = joinBtn
    
    -- Auto TP Toggle
    local autoTpBtn = Instance.new("TextButton")
    autoTpBtn.Size = UDim2.new(1, -20, 0, 30)
    autoTpBtn.Position = UDim2.new(0, 10, 0, 165)
    autoTpBtn.BackgroundColor3 = autoTeleportAfterSend and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(160, 80, 80)
    autoTpBtn.Text = "AUTO TP: " .. (autoTeleportAfterSend and "ON" or "OFF")
    autoTpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoTpBtn.Font = Enum.Font.GothamBold
    autoTpBtn.TextSize = 12
    autoTpBtn.Parent = content
    
    local autoTpCorner = Instance.new("UICorner")
    autoTpCorner.CornerRadius = UDim.new(0, 6)
    autoTpCorner.Parent = autoTpBtn
    
    -- Server Hop Toggle
    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, -20, 0, 30)
    hopBtn.Position = UDim2.new(0, 10, 0, 205)
    hopBtn.BackgroundColor3 = autoServerHop and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(160, 80, 80)
    hopBtn.Text = "SERVER HOP: " .. (autoServerHop and "ON" or "OFF")
    hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hopBtn.Font = Enum.Font.GothamBold
    hopBtn.TextSize = 12
    hopBtn.Parent = content
    
    local hopCorner = Instance.new("UICorner")
    hopCorner.CornerRadius = UDim.new(0, 6)
    hopCorner.Parent = hopBtn
    
    -- Info Label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -20, 0, 35)
    infoLabel.Position = UDim2.new(0, 10, 1, -45)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Place: " .. PLACE_ID .. "\nAPI: ✅ | Drag: ✅"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 10
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = content
    
    -- DRAG SYSTEM
    local function makeDraggable(frame)
        local dragging = false
        local dragStart, startPos
        
        local function update(input)
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
        
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                
                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        connection:Disconnect()
                    end
                end)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
    end
    
    -- Make both frames draggable
    makeDraggable(mainFrame)
    makeDraggable(minimizedBar)
    
    -- MINIMIZE SYSTEM
    local isMinimized = false
    
    local function toggleMinimize()
        if isMinimized then
            -- Restore
            minimizedBar.Visible = false
            mainFrame.Visible = true
            isMinimized = false
        else
            -- Minimize
            minimizedBar.Position = mainFrame.Position
            mainFrame.Visible = false
            minimizedBar.Visible = true
            isMinimized = true
        end
    end
    
    -- BUTTON CONNECTIONS
    minimizeBtn.MouseButton1Click:Connect(function()
        toggleMinimize()
    end)
    
    minimizedBar.MouseButton1Click:Connect(function()
        toggleMinimize()
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = not screenGui.Enabled
    end)
    
    setJobBtn.MouseButton1Click:Connect(function()
        local txt = jobInput.Text:gsub("%s+", "")
        if txt ~= "" then
            targetJobId = txt
            setJobBtn.Text = "SET!"
            wait(1)
            setJobBtn.Text = "SET JOB ID"
        end
    end)
    
    tpBtn.MouseButton1Click:Connect(function()
        if targetJobId and targetJobId ~= "" then
            pcall(function()
                TeleportService:TeleportToPlaceInstance(PLACE_ID, targetJobId, LocalPlayer)
            end)
        end
    end)
    
    joinBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=50"))
            if servers and servers.data then
                for _, server in pairs(servers.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, LocalPlayer)
                        break
                    end
                end
            end
        end)
    end)
    
    autoTpBtn.MouseButton1Click:Connect(function()
        autoTeleportAfterSend = not autoTeleportAfterSend
        autoTpBtn.BackgroundColor3 = autoTeleportAfterSend and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(160, 80, 80)
        autoTpBtn.Text = "AUTO TP: " .. (autoTeleportAfterSend and "ON" or "OFF")
    end)
    
    hopBtn.MouseButton1Click:Connect(function()
        autoServerHop = not autoServerHop
        hopBtn.BackgroundColor3 = autoServerHop and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(160, 80, 80)
        hopBtn.Text = "SERVER HOP: " .. (autoServerHop and "ON" or "OFF")
    end)
    
    print("=== BRAINROT ESP GUI LOADED ===")
    print("Drag: ✅ | Minimize: ✅ | Buttons: ✅ | API: ✅")
    
    return screenGui
end

-- SIMPLE ESP SYSTEM WITH API SEND
local function StartESP()
    local tracked = {}
    local webhookSent = {}
    
    local function findPart(inst)
        if not inst then return nil end
        if inst:IsA("BasePart") then return inst end
        if inst:IsA("Model") then
            if inst.PrimaryPart then return inst.PrimaryPart end
            return inst:FindFirstChildWhichIsA("BasePart")
        end
        if inst.Parent then return findPart(inst.Parent) end
        return nil
    end
    
    local function extractTexts(root)
        local texts = {}
        for _, desc in pairs(root:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                local txt = tostring(desc.Text or "")
                if #txt > 0 then table.insert(texts, txt) end
            end
        end
        
        local name, rarity, value = nil, nil, nil
        for _, t in pairs(texts) do
            local lower = t:lower()
            if not name and lower:find("brainrot") then name = t end
            if not rarity and t:find("Secret") then rarity = "Secret" end
            if not value then
                local val = string.match(t, "[%d%.]+%s*[KMBkmb]+%s*/[seSE]")
                if val then value = val:gsub("%s+", "") end
            end
        end
        return name, rarity, value
    end
    
    -- FUNCTION TO SEND TO API
    local function sendToAPI(name, value)
        if not reqFunc then 
            print("HTTP request não disponível para enviar para API")
            return false
        end
        
        local payload = {
            jobId = tostring(game.JobId or ''),
            placeId = tostring(PLACE_ID or ''),
            nome = name or 'Desconhecido',
            valor = value or 'Desconhecido',
            players = #Players:GetPlayers(),
            maxPlayers = game.Players.MaxPlayers,
            detectedAt = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
        
        local success, body = pcall(function()
            return HttpService:JSONEncode(payload)
        end)
        
        if not success then
            print("Erro ao codificar JSON para API")
            return false
        end
        
        local response = reqFunc({
            Url = SERVER_URL,
            Method = 'POST',
            Headers = {
                ['Content-Type'] = 'application/json'
            },
            Body = body
        })
        
        if response and response.StatusCode == 200 then
            print("✅ Secret enviado para API: " .. (name or "Unknown") .. " | " .. (value or "Unknown"))
            return true
        else
            print("❌ Erro ao enviar para API: " .. tostring(response and response.StatusCode or "No response"))
            return false
        end
    end
    
    while true do
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local name, rarity, value = extractTexts(obj)
                if rarity == "Secret" and value then
                    local part = findPart(obj)
                    if part and not tracked[obj] then
                        tracked[obj] = true
                        
                        -- Send to API
                        if not webhookSent[obj] then
                            webhookSent[obj] = true
                            spawn(function()
                                local success = sendToAPI(name, value)
                                if success and autoTeleportAfterSend and autoServerHop then
                                    wait(1.0)
                                    -- Auto server hop after successful send
                                    pcall(function()
                                        local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/Public?sortOrder=Asc&limit=50"))
                                        if servers and servers.data then
                                            for _, server in pairs(servers.data) do
                                                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                                                    TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, LocalPlayer)
                                                    break
                                                end
                                            end
                                        end
                                    end)
                                end
                            end)
                        end
                        
                        -- Create ESP
                        local bg = Instance.new("BillboardGui")
                        bg.Name = "BrainrotESP"
                        bg.Adornee = part
                        bg.AlwaysOnTop = true
                        bg.Size = UDim2.new(0, 200, 0, 50)
                        bg.StudsOffset = Vector3.new(0, 3, 0)
                        bg.Parent = Workspace
                        
                        local frame = Instance.new("Frame")
                        frame.Size = UDim2.new(1, 0, 1, 0)
                        frame.BackgroundColor3 = Color3.fromRGB(18, 10, 30)
                        frame.BackgroundTransparency = 0.1
                        frame.BorderSizePixel = 0
                        frame.Parent = bg
                        
                        local frameCorner = Instance.new("UICorner")
                        frameCorner.CornerRadius = UDim.new(0, 8)
                        frameCorner.Parent = frame
                        
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, -8, 1, -8)
                        label.Position = UDim2.new(0, 4, 0, 4)
                        label.BackgroundTransparency = 1
                        label.Font = Enum.Font.GothamBold
                        label.TextScaled = true
                        label.TextColor3 = Color3.fromRGB(255, 20, 147)
                        label.Text = string.format("%s | %s | %s", name or "Unknown", rarity or "", value or "")
                        label.TextXAlignment = Enum.TextXAlignment.Center
                        label.TextYAlignment = Enum.TextYAlignment.Center
                        label.Parent = frame
                        
                        print("SECRET FOUND: " .. (name or "Unknown") .. " | " .. value)
                    end
                end
            end
        end
        
        wait(2)
    end
end

-- START EVERYTHING
wait(2)
CreateCompleteGUI()
spawn(StartESP)

print("=== BRAINROT ESP FULLY LOADED ===")
print("GUI: ✅ | ESP: ✅ | Drag: ✅ | Minimize: ✅ | API: ✅")

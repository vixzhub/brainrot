--// Brainrot ESP v15 - Final Complete (KRNL Mobile)
--// GUI moderna + ESP (Secret no mapa) + envio ao BronxyHost + envia pro Discord via server + teleport pra outro servidor
--// by cybhor@pedro
--// Use como LocalScript no PlayerGui (KRNL)

-- SERVICES
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local TeleportService = game:GetService('TeleportService')
local HttpService = game:GetService('HttpService')
local UserInputService = game:GetService('UserInputService')
local LocalPlayer = Players.LocalPlayer
local Workspace = workspace

-- CONFIG (ajuste se necessário)
local SERVER_URL = "http://br2.bronxyshost.com:4234/discord-relay.php" -- seu PHP no BronxyHost
local PLACE_ID = game.PlaceId
local SCAN_INTERVAL = 1 -- segundos entre scans
local NO_SECRET_THRESHOLD = 4 -- quantos scans sem secret antes de trocar servidor
local SERVER_LIST_LIMIT = 100 -- limite da API (máx 100)

-- ESTADO
local tracked = {} -- debugId -> { gui, adornee, base }
local webhookSent = {} -- debugId -> true (evita envios repetidos)
local noSecretCounter = 0
local autoServerHop = false -- INICIA DESATIVADO quando entra no servidor
local autoJoinRandom = false -- se true, prioriza servidores com espaço
local autoTeleportAfterSend = true -- envia pro site, espera e teleporta pra outro servidor
local targetJobId = nil

-- UTIL: detecta função de request (KRNL normalmente expõe http_request, request ou syn.request)
local function detectRequestFunc()
    if syn and syn.request then return syn.request end
    if http_request then return http_request end
    if request then return request end
    return nil
end
local reqFunc = detectRequestFunc()

local function safeRequest(opts)
    if not reqFunc then return nil, 'no_request' end
    local ok, res = pcall(function() return reqFunc(opts) end)
    if not ok then return nil, res end
    return res, nil
end

-- ESP HELPERS
local function findPart(inst)
    if not inst then return nil end
    if inst:IsA('BasePart') then return inst end
    if inst:IsA('Model') then
        if inst.PrimaryPart then return inst.PrimaryPart end
        return inst:FindFirstChildWhichIsA('BasePart')
    end
    if inst.Parent then return findPart(inst.Parent) end
    return nil
end

local function extractTexts(root)
    local texts = {}
    for _, desc in ipairs(root:GetDescendants()) do
        if desc:IsA('TextLabel') or desc:IsA('TextButton') or desc:IsA('StringValue') then
            local txt = tostring(desc.Text or desc.Value or '')
            if #txt > 0 then table.insert(texts, txt) end
        end
    end
    
    local name, rarity, value = nil, nil, nil
    for _, t in ipairs(texts) do
        local lower = t:lower()
        if not name and lower:find('brainrot') then name = t end
        if not rarity and t:find('Secret') then rarity = 'Secret' end
        if not value then
            local val = string.match(t, '[%d%.]+%s*[KMBkmb]+%s*/[seSE]')
            if val then value = val:gsub('%s+','') end
        end
    end
    return name, rarity, value
end

-- Envia dados pro seu servidor (BronxyHost)
local function sendToServer(name, value)
    if not reqFunc then
        warn('[ESP] HTTP não disponível no executor; não foi possível enviar para o servidor.')
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
    
    local body = HttpService:JSONEncode(payload)
    local ok, err = pcall(function()
        reqFunc({
            Url = SERVER_URL,
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = body
        })
    end)
    
    if not ok then
        warn('[ESP] Falha ao enviar para servidor:', err)
        return false
    end
    return true
end

-- Cria ESP Billboard para o Secret (mostra no mapa)
local function createESP(inst, adornee, name, rarity, value)
    local ok, id = pcall(function() return inst:GetDebugId() end)
    if not ok or not id then return end
    if tracked[id] then return end
    if not adornee then return end

    local bg = Instance.new('BillboardGui')
    bg.Name = 'BrainrotESP_cybhor'
    bg.Adornee = adornee
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0,220,0,46)
    bg.StudsOffset = Vector3.new(0,3,0)

    local frame = Instance.new('Frame', bg)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.fromRGB(18,10,30)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    Instance.new('UICorner', frame).CornerRadius = UDim.new(0,8)

    local label = Instance.new('TextLabel', frame)
    label.Size = UDim2.new(1,-8,1,-8)
    label.Position = UDim2.new(0,4,0,4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255,20,147)
    label.TextStrokeTransparency = 0.2
    label.Text = string.format('%s | %s | %s', name or 'Unknown', rarity or '', value or '')
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center

    bg.Parent = Workspace
    tracked[id] = { gui = bg, adornee = adornee, base = { name, rarity, value }, label = label }

    -- envia somente 1 vez por instância
    if not webhookSent[id] then
        webhookSent[id] = true
        spawn(function()
            local okSend = pcall(function() return sendToServer(name, value) end)
            -- se enviar com sucesso e o usuário quer auto-teleport após enviar, espera e troca de servidor
            if okSend and autoTeleportAfterSend then
                -- delay curto pra garantir que o servidor processe (pode ajustar)
                task.wait(1.0)
                -- faz server hop apenas se autoServerHop estiver ativado
                if autoServerHop then
                    pickRandomServerAndTeleport()
                end
            end
        end)
    end
end

-- remove itens inválidos
local function cleanup()
    for id, data in pairs(tracked) do
        if not data.adornee or not data.adornee.Parent then
            if data.gui and data.gui.Parent then data.gui:Destroy() end
            tracked[id] = nil
        end
    end
end

-- Procura secrets no mapa; retorna true se encontrou ao menos 1
local function fullScan()
    local foundAny = false
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA('Model') or obj:IsA('BasePart')) then
            local ok, id = pcall(function() return obj:GetDebugId() end)
            if ok and id and not tracked[id] then
                local name, rarity, value = extractTexts(obj)
                if rarity == 'Secret' and value then
                    local part = findPart(obj)
                    if part then
                        createESP(obj, part, name, rarity, value)
                        foundAny = true
                    end
                end
            end
        end
    end
    return foundAny
end

-- Atualiza distância das labels
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild('HumanoidRootPart')
    if not root then return end
    
    for id, data in pairs(tracked) do
        if data.label and data.adornee and data.adornee.Position then
            local dist = math.floor((root.Position - data.adornee.Position).Magnitude)
            local name, rarity, value = table.unpack(data.base)
            data.label.Text = string.format('%s | %s | %s | %dm', name or 'Unknown', rarity or '', value or '', dist)
        end
    end
end)

-- SERVER LIST / TELEPORT HELPERS
function teleportToJob(jobId)
    if not jobId or tostring(jobId) == '' then
        warn('[ESP] JobId inválido.')
        return
    end
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, tostring(jobId), LocalPlayer)
    end)
end

function getPublicServers()
    if not reqFunc then return nil, 'no_http' end
    local url = ('https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=%d'):format(PLACE_ID, SERVER_LIST_LIMIT)
    local ok, res = pcall(function() return reqFunc({ Url = url, Method = 'GET' }) end)
    if not ok or not res then return nil, 'req_fail' end
    
    local body = res.Body or res.body or ''
    local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok2 or not data then return nil, 'json_fail' end
    return data, nil
end

function pickRandomServerAndTeleport()
    local data, err = getPublicServers()
    if not data then
        warn('[ESP] Falha ao obter servidores:', err)
        return
    end
    
    local servers = data.data or {}
    local candidates = {}
    for _, s in ipairs(servers) do
        if s.id and s.playing and s.maxPlayers and tostring(s.id) ~= tostring(game.JobId) then
            if s.playing < s.maxPlayers then table.insert(candidates, s) end
        end
    end
    
    if #candidates == 0 then
        for _, s in ipairs(servers) do
            if s.id and tostring(s.id) ~= tostring(game.JobId) then table.insert(candidates, s) end
        end
    end
    
    if #candidates == 0 then
        warn('[ESP] Sem candidatos para teleport.')
        return
    end
    
    local pick = candidates[math.random(1, #candidates)]
    teleportToJob(pick.id)
end

-- MAIN SCAN LOOP: detecta secrets, envia e decide hop
spawn(function()
    while true do
        local ok, found = pcall(fullScan)
        if not ok then found = false end

        if found then
            noSecretCounter = 0
        else
            noSecretCounter = noSecretCounter + 1
        end

        -- SÓ FAZ SERVER HOP SE autoServerHop ESTIVER ATIVADO
        if autoServerHop and noSecretCounter >= NO_SECRET_THRESHOLD then
            noSecretCounter = 0
            pickRandomServerAndTeleport()
            task.wait(6) -- evita flood
        end
        
        cleanup()
        task.wait(SCAN_INTERVAL)
    end
end)

-- === GUI: compacto, confiável no KRNL Mobile e PC, arrastável ===
local function CreateGUI()
    -- espera PlayerGui
    local pg = LocalPlayer:FindFirstChild('PlayerGui')
    local tries = 0
    while not pg and tries < 10 do
        task.wait(0.3)
        pg = LocalPlayer:FindFirstChild('PlayerGui')
        tries = tries + 1
    end
    if not pg then
        warn('[ESP] PlayerGui não encontrado; GUI não será criada.')
        return
    end
    task.wait(0.15)

    local screenGui = Instance.new('ScreenGui')
    screenGui.Name = 'BrainrotESP_GUI_CYBHOR'
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = pg

    local frame = Instance.new('Frame')
    frame.Name = 'MainFrame'
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.03, 0, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(28,28,40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    Instance.new('UICorner', frame).CornerRadius = UDim.new(0,10)

    -- drag support (mouse + touch)
    local dragging, dragStart, startPos = false, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if dragging and input.Position then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- title
    local title = Instance.new('TextLabel')
    title.Parent = frame
    title.Size = UDim2.new(1, -12, 0, 26)
    title.Position = UDim2.new(0, 8, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(240,240,240)
    title.Text = 'Brainrot ESP — cybhor'
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- close
    local close = Instance.new('TextButton')
    close.Parent = frame
    close.Size = UDim2.new(0, 22, 0, 22)
    close.Position = UDim2.new(1, -30, 0, 6)
    close.BackgroundColor3 = Color3.fromRGB(45,45,55)
    close.TextColor3 = Color3.fromRGB(255,255,255)
    close.Text = 'X'
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    Instance.new('UICorner', close).CornerRadius = UDim.new(0,6)
    close.MouseButton1Click:Connect(function() screenGui.Enabled = not screenGui.Enabled end)

    local function makeLabel(y, txt)
        local lbl = Instance.new('TextLabel', frame)
        lbl.Size = UDim2.new(0,140,0,18)
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = Color3.fromRGB(200,200,200)
        lbl.Text = txt
        return lbl
    end
    
    local function makeSmallButton(y, txt)
        local btn = Instance.new('TextButton', frame)
        btn.Size = UDim2.new(0,86,0,22)
        btn.Position = UDim2.new(0, 200, 0, y)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Text = txt
        btn.BackgroundColor3 = Color3.fromRGB(58,58,76)
        btn.TextColor3 = Color3.fromRGB(230,230,230)
        Instance.new('UICorner', btn).CornerRadius = UDim.new(0,6)
        return btn
    end

    -- JobId input + set button
    makeLabel(36, 'Target JobId (instance id):')
    local jobInput = Instance.new('TextBox', frame)
    jobInput.Size = UDim2.new(0, 168, 0, 22)
    jobInput.Position = UDim2.new(0, 10, 0, 56)
    jobInput.PlaceholderText = 'Cole o JobId aqui'
    jobInput.ClearTextOnFocus = false
    jobInput.BackgroundColor3 = Color3.fromRGB(40,40,52)
    jobInput.TextColor3 = Color3.fromRGB(255,255,255)
    jobInput.Font = Enum.Font.Gotham
    jobInput.TextSize = 13
    Instance.new('UICorner', jobInput).CornerRadius = UDim.new(0,6)

    local setBtn = makeSmallButton(56, 'Set JobId')
    setBtn.MouseButton1Click:Connect(function()
        local txt = tostring(jobInput.Text or ''):gsub('%s+','')
        if txt ~= '' then
            targetJobId = txt
            setBtn.Text = 'Set!'
            task.delay(0.8, function() if setBtn and setBtn.Parent then setBtn.Text = 'Set JobId' end end)
        else
            warn('[ESP] JobId vazio.')
        end
    end)

    -- Auto Teleport toggle
    makeLabel(95, 'Auto Teleport On Found:')
    local autoTpBtn = makeSmallButton(95, 'ON') -- Começa ON por padrão
    autoTpBtn.MouseButton1Click:Connect(function()
        autoTeleportAfterSend = not autoTeleportAfterSend
        autoTpBtn.Text = autoTeleportAfterSend and 'ON' or 'OFF'
    end)

    -- Auto Join Random
    makeLabel(128, 'Auto Join Random:')
    local autoJoinBtn = makeSmallButton(128, 'OFF')
    autoJoinBtn.MouseButton1Click:Connect(function()
        autoJoinRandom = not autoJoinRandom
        autoJoinBtn.Text = autoJoinRandom and 'ON' or 'OFF'
    end)

    -- Server Hop master - COMEÇA DESLIGADO
    makeLabel(161, 'Server Hop:')
    local serverHopBtn = makeSmallButton(161, 'OFF') -- Começa OFF
    serverHopBtn.MouseButton1Click:Connect(function()
        autoServerHop = not autoServerHop
        serverHopBtn.Text = autoServerHop and 'ON' or 'OFF'
        
        -- Quando ativar o Server Hop, reseta o contador
        if autoServerHop then
            noSecretCounter = 0
        end
    end)

    -- Quick buttons
    local tpNow = makeSmallButton(188, 'Teleport Now')
    tpNow.Position = UDim2.new(0, 10, 0, 188)
    tpNow.MouseButton1Click:Connect(function()
        if targetJobId and tostring(targetJobId) ~= '' then
            teleportToJob(targetJobId)
        else
            warn('[ESP] Defina um JobId primeiro.')
        end
    end)

    local joinNow = makeSmallButton(188, 'Join Random')
    joinNow.Position = UDim2.new(0, 110, 0, 188)
    joinNow.MouseButton1Click:Connect(function()
        pickRandomServerAndTeleport()
    end)

    -- executor info
    local execLabel = Instance.new('TextLabel', frame)
    execLabel.Size = UDim2.new(1, -20, 0, 14)
    execLabel.Position = UDim2.new(0, 10, 0, 34)
    execLabel.BackgroundTransparency = 1
    execLabel.Font = Enum.Font.Gotham
    execLabel.TextSize = 11
    execLabel.TextColor3 = Color3.fromRGB(170,170,170)
    local execName = 'Unknown'
    if syn and syn.request then execName = 'Synapse' 
    elseif http_request then execName = 'KRNL' 
    elseif request then execName = 'Req' end
    execLabel.Text = 'Executor: ' .. execName

    return screenGui
end

-- INICIALIZAÇÃO AUTOMÁTICA
-- Aguarda o player carregar completamente
local function initializeScript()
    -- Espera o character carregar se necessário
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    
    -- Cria a GUI
    CreateGUI()
    
    -- Inicia o scanner automaticamente
    print('[💎 Brainrot ESP v15 - INICIADO AUTOMATICAMENTE]')
    print('[💎 Server Hop: DESLIGADO por padrão | KRNL:', (reqFunc and 'DETECTADO' or 'NÃO DETECTADO'), ']')
    print('[💎 Scanner ativo - Procurando Secrets...]')
end

-- Inicia o script quando tudo estiver carregado
spawn(initializeScript)

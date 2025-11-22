--[[
    Admin System by REDz (Versão Sem Painel)
    Funciona através de comandos no chat.
    Mantém as tags visuais e todos os comandos, incluindo ;jumpscare.
]]

-- Serviços
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
if not lp then return end

workspace.FallenPartsDestroyHeight = -math.huge

-- IDs de Assets para o Jumpscare (Você pode trocá-los)
local jumpscareSoundID = "rbxassetid://6417309625" -- ID do som do jumpscare
local jumpscareImageID = "rbxassetid://11171728768" -- ID da imagem do jumpscare

-- Lista de usuários que abriram o Hub
local UsuariosDoHub = {}
UsuariosDoHub[lp.Name] = true

--// Donos especiais (sempre recebem "Dono")
local Donos = {
    ["Gr3g0rilsir"] = true,
    ["BlessedTeam_BT"] = true
}

--// Jogadores autorizados
local Autorizados = {
    ["quiel_noobe"] = true
}

--// Estados locais
local playerOriginalSpeed = {}
local jaulas = {}
local jailConnections = {}
local mapLoaded = false -- Flag para carregar o mapa dos Backrooms apenas uma vez

--// Função: cria ou atualiza tag visual
local function createSpecialTag(player)
    if not player then return end

    local function apply()
        if not player or not player.Parent then return end
        local char = player.Character
        if not char then return end
        local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 5)
        if not head then return end

        local old = head:FindFirstChild("SpecialTag")
        if old then old:Destroy() end

        local gui = Instance.new("BillboardGui")
        gui.Name = "SpecialTag"
        gui.Size = UDim2.new(0, 200, 0, 50)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.AlwaysOnTop = true
        gui.Adornee = head
        gui.Parent = head

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.GothamBold
        text.TextScaled = true
        text.TextStrokeTransparency = 0.2
        text.TextStrokeColor3 = Color3.new(0,0,0)
        text.TextColor3 = Color3.fromRGB(255,255,255)

        if Donos[player.Name] then
            text.Text = "Dono"
        elseif Autorizados[player.Name] then
            text.Text = "Admin"
        elseif UsuariosDoHub[player.Name] then
            text.Text = "User"
        else
            text.Text = ""
        end

        text.Parent = gui
    end

    task.defer(function()
        pcall(apply)
        player.CharacterAdded:Connect(function()
            task.wait(0.4)
            pcall(apply)
        end)
    end)
end

--// Aplica tags iniciais
for _, p in pairs(Players:GetPlayers()) do
    createSpecialTag(p)
end
--// Atualiza tag em novos jogadores
Players.PlayerAdded:Connect(function(p)
    createSpecialTag(p)
end)

--// Envia comandos via chat (usado apenas para ;verifique)
local function EnviarComando(comando, alvo)
    if not TextChatService or not TextChatService.TextChannels then return end
    local canal = nil
    pcall(function()
        canal = TextChatService.TextChannels:FindFirstChild("RBXGeneral") or TextChatService.TextChannels:GetChildren()[1]
    end)
    if canal and canal.SendAsync then
        pcall(function()
            local cmdString = ";" .. comando
            if alvo and alvo ~= "" then
                cmdString = cmdString .. " " .. alvo
            end
            canal:SendAsync(cmdString)
        end)
    end
end

--// Atualiza tag por nome
local function AtualizarTagPorNome(nome)
    local p = Players:FindFirstChild(nome)
    if p then
        createSpecialTag(p)
    end
end

--// Processador principal de mensagens (para receber comandos de outros admins)
local function ProcessarMensagem(msgText, authorName)
    if not msgText or not authorName then return end

    -- Verifica se o autor do comando está autorizado
    if not (Donos[authorName] or Autorizados[authorName]) then return end

    local comandoLower = msgText:lower()
    local targetLower = lp.Name:lower()
    local character = lp.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    --// KICK
    if comandoLower:match(";kick%s+" .. targetLower .. "%f[%A]") then
        pcall(function() lp:Kick("You got kicked by REDz HUB Admin") end)
    end

    --// KILL
    if comandoLower:match(";kill%s+" .. targetLower .. "%f[%A]") then
        if character then pcall(function() character:BreakJoints() end) end
    end

    --// KILLPLUS
    if comandoLower:match(";killplus%s+" .. targetLower .. "%f[%A]") then
        if character then
            pcall(function() character:BreakJoints() end)
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                for i = 1, 10 do
                    local part = Instance.new("Part")
                    part.Size = Vector3.new(10, 10, 10)
                    part.Anchored = false
                    part.CanCollide = false
                    part.Material = Enum.Material.Neon
                    part.BrickColor = BrickColor.Random()
                    part.CFrame = root.CFrame
                    part.Parent = Workspace
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(math.random(-50,50), math.random(20,80), math.random(-50,50))
                    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
                    bv.Parent = part
                    Debris:AddItem(part, 3)
                end
            end
        end
    end

    --// FLING
    if comandoLower:match(";fling%s+" .. targetLower .. "%f[%A]") then
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                local ok, tween = pcall(function()
                    return TweenService:Create(root, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = CFrame.new(0,100000,0)})
                end)
                if ok and tween then tween:Play() end
            end
        end
    end

    --// FREEZE
    if comandoLower:match(";freeze%s+" .. targetLower .. "%f[%A]") then
        if humanoid then
            playerOriginalSpeed[targetLower] = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
        end
    end

    --// UNFREEZE
    if comandoLower:match(";unfreeze%s+" .. targetLower .. "%f[%A]") then
        if humanoid then
            humanoid.WalkSpeed = playerOriginalSpeed[targetLower] or 16
        end
    end

    --// JAIL
    if comandoLower:match(";jail%s+" .. targetLower .. "%f[%A]") then
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos = root.Position
                jaulas[targetLower] = {}
                local color = Color3.fromRGB(255,140,0)

                local function criarPart(cf,s)
                    local p = Instance.new("Part")
                    p.Anchored = true
                    p.Size = s
                    p.CFrame = cf
                    p.Transparency = 0.5
                    p.Color = color
                    p.Parent = Workspace
                    table.insert(jaulas[targetLower], p)
                end

                criarPart(CFrame.new(pos + Vector3.new(5,0,0)), Vector3.new(1,10,10))
                criarPart(CFrame.new(pos + Vector3.new(-5,0,0)), Vector3.new(1,10,10))
                criarPart(CFrame.new(pos + Vector3.new(0,0,5)), Vector3.new(10,10,1))
                criarPart(CFrame.new(pos + Vector3.new(0,0,-5)), Vector3.new(10,10,1))
                criarPart(CFrame.new(pos + Vector3.new(0,5,0)), Vector3.new(10,1,10))
                criarPart(CFrame.new(pos + Vector3.new(0,-5,0)), Vector3.new(10,1,10))

                jailConnections[targetLower] = RunService.Heartbeat:Connect(function()
                    if character and root then
                        if (root.Position - pos).Magnitude > 5 then
                            root.CFrame = CFrame.new(pos)
                        end
                    end
                end)
            end
        end
    end

    --// UNJAIL
    if comandoLower:match(";unjail%s+" .. targetLower .. "%f[%A]") then
        if jaulas[targetLower] then
            for _, v in pairs(jaulas[targetLower]) do
                if v and v.Destroy then pcall(v.Destroy, v) end
            end
            jaulas[targetLower] = nil
        end
        if jailConnections[targetLower] then
            jailConnections[targetLower]:Disconnect()
            jailConnections[targetLower] = nil
        end
    end

    --// BACKROOMS
    if comandoLower:match(";backrooms%s+" .. targetLower .. "%f[%A]") then
        local mapID = 10581711055
        local distantPosition = Vector3.new(0, 10000, 0)
        local teleportPosition = Vector3.new(59.06, 9996.70, 19.42)

        -- Carrega o mapa se ainda não foi carregado
        if not mapLoaded then
            local ok, mapa = pcall(function() return game:GetObjects("rbxassetid://"..mapID)[1] end)
            if ok and mapa then
                mapa.Parent = Workspace
                if not mapa.PrimaryPart then
                    local part = mapa:FindFirstChildWhichIsA("BasePart")
                    if part then mapa.PrimaryPart = part end
                end
                if mapa.PrimaryPart then
                    mapa:SetPrimaryPartCFrame(CFrame.new(distantPosition))
                end
                mapLoaded = true
            end
        end

        if character and character:FindFirstChild("HumanoidRootPart") then
            character:MoveTo(teleportPosition)
        end
    end
    
    --// BRING (receptor do comando)
    if comandoLower:match(";bring%s+" .. targetLower .. "%f[%A]") then
        local targetChar = lp.Character
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local sourcePlayer = Players:FindFirstChild(authorName)
            if sourcePlayer and sourcePlayer.Character then
                local sourceRoot = sourcePlayer.Character:FindFirstChild("HumanoidRootPart")
                if sourceRoot then
                    targetRoot.CFrame = sourceRoot.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    end

    --// TO (receptor do comando)
    if comandoLower:match(";to%s+" .. targetLower .. "%f[%A]") then
        local sourcePlayer = Players:FindFirstChild(authorName)
        if sourcePlayer and sourcePlayer.Character then
            local sourceRoot = sourcePlayer.Character:FindFirstChild("HumanoidRootPart")
            if sourceRoot then
                local targetChar = lp.Character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    sourceRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    end

    --// JUMPSCARE (receptor do comando)
    if comandoLower:match(";jumpscare%s+" .. targetLower .. "%f[%A]") then
        local playerGui = lp:WaitForChild("PlayerGui")
        local jumpscareGui = Instance.new("ScreenGui")
        jumpscareGui.Name = "JumpscareGui"
        jumpscareGui.ResetOnSpawn = false
        jumpscareGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        jumpscareGui.Parent = playerGui

        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Size = UDim2.new(1, 0, 1, 0)
        imageLabel.Position = UDim2.fromOffset(0, 0)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = jumpscareImageID
        imageLabel.Parent = jumpscareGui

        local sound = Instance.new("Sound")
        sound.SoundId = jumpscareSoundID
        sound.Volume = 2
        sound.Parent = playerGui
        sound:Play()

        -- Remove a GUI e o som após 4 segundos
        Debris:AddItem(jumpscareGui, 4)
        Debris:AddItem(sound, 4)
    end

    --// VERIFIQUE (envia redz_####)
    if comandoLower:match("^;verifique") then
        local canal = nil
        pcall(function()
            canal = TextChatService.TextChannels:FindFirstChild("RBXGeneral") or TextChatService.TextChannels:GetChildren()[1]
        end)
        if canal and canal.SendAsync then
            pcall(function() canal:SendAsync("redz_####") end)
        end
    end

    --// DETECÇÃO DE AUTORIZAÇÃO
    if msgText:match("[Nn]ytherune_%d%d%d%d") then
        if not Autorizados[authorName] then
            Autorizados[authorName] = true
            AtualizarTagPorNome(authorName)
        end
    end
end

--// Conecta canais de chat
local function ConectarCanal(canal)
    if not canal or typeof(canal) ~= "Instance" or not canal:IsA("TextChannel") then return end
    canal.MessageReceived:Connect(function(msg)
        local text = msg.Text
        local source = msg.TextSource and msg.TextSource.Name
        if text and source then
            ProcessarMensagem(text, source)
        end
    end)
end

if TextChatService and TextChatService.TextChannels then
    for _, ch in pairs(TextChatService.TextChannels:GetChildren()) do
        ConectarCanal(ch)
    end
    TextChatService.TextChannels.ChildAdded:Connect(ConectarCanal)
end

--// Som final de carregamento
pcall(function()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://8486683243"
    s.Volume = 0.5
    s.PlayOnRemove = true
    s.Parent = Workspace
    s:Destroy()
end)

--// Fim do script

local redzlib = loadstring(game:HttpGet("https://pastefy.app/hG3LUtAT/raw"))()

local Window = redzlib:MakeWindow({
  Title = " REDz Hub - Recreated",
  SubTitle = "by G H O S T",
  SaveFolder = "BlessedHub_Brookhaven"
})

Window:AddMinimizeButton({
    Button = { 
        Image = "rbxassetid://15298567397", -- seu ícone
        BackgroundTransparency = 1, -- fundo 100% transparente
        Size = UDim2.new(0, 60, 0, 60) -- ícone super grande
    },
    Corner = { CornerRadius = UDim.new(35, 1) },
})

local infoTab = Window:MakeTab({"informações", "info"})

infoTab:AddDiscordInvite({
    Name = "Blessed Community",
    Description = "Entre No Discord",
    Logo = "rbxassetid://15298567397",
    Invite = "https://discord.gg/eP55xHGy",
})

infoTab:AddSection({ "Informações do Script" })
infoTab:AddParagraph({ "Esse não é o REDZ HUB oficial, é apenas uma versão recriada" })

infoTab:AddSection({ "Créditos dos desenvolvedores" })
infoTab:AddParagraph({ "Tiktok do criador: @fk_fakezin" })
infoTab:AddParagraph({ "Canal do YouTube do criador: @Ghzinn_007 e @BlessedTeam_BT" })
infoTab:AddParagraph({ "Meu discord: @xitad077" })
infoTab:AddParagraph({ "Meu Roblox: BlessedTeam_BT e Gr3g0rilsir" })
infoTab:AddParagraph({ "Colaboração:", "Anna, WX, Entity (Quiel) & BLESSED TEAM" })
infoTab:AddParagraph({ "Você está usando:", "REDZ HUB" })

infoTab:AddSection({ "Em caso de dúvidas sobre o REDz" })
infoTab:AddParagraph({ "Me chama nessas redes:", "Tiktok ou Discord" })

infoTab:AddSection({ "Informações Client" })

--=== UTIL (cria "botões" não clicáveis e função segura de update) ===--
local function createInfoBlock(tab, title, initial)
    -- Tenta usar Paragraph (título + descrição, igual na imagem).
    local block
    local ok = pcall(function()
        block = tab:AddParagraph({ Title = title, Content = initial })
    end)
    -- Se a lib não tiver Paragraph, cai para Label (1 linha).
    if not ok or not block then
        ok = pcall(function()
            block = tab:AddLabel(title .. (initial and ("\n" .. initial) or ""))
        end)
    end
    return block
end

local function setBlockText(block, title, text)
    if not block then return end
    -- Tenta métodos comuns de libs de UI
    local ok = pcall(function()
        if block.Set then return block:Set(text) end
        if block.SetDesc then return block:SetDesc(text) end
        if block.SetText then return block:SetText(text) end
        if block.Update then return block:Update(text) end
        if block.Refresh then return block:Refresh(text) end
    end)
    -- Fallback para Label simples (reescreve tudo)
    if not ok then
        pcall(function()
            if block.Text ~= nil then
                block.Text = title .. "\n" .. text
            end
        end)
    end
end

-- Função para pegar a data atual
local function getCurrentDate()
    local currentTime = os.time()
    return os.date("%d/%m/%Y", currentTime)
end
--====================================================================--

-- Pega informações da conta do jogador
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Bloquinhos não clicáveis (todos NA ABA TROLL) - Boas-vindas PRIMEIRO
local welcomeBlock = createInfoBlock(TrollTab, "Seja Bem Vindo Ao REDZ HUB! Hoje É Dia: ", getCurrentDate())

-- Botão não clicável com nome da conta
infoTab:AddParagraph({"Seu Nickname: " .. (game.Players.LocalPlayer.Name or "Desconhecido")})

-- Botão não clicável com ID da conta  
infoTab:AddParagraph({"Seu ID: " .. tostring(game.Players.LocalPlayer.UserId or 0)})

-- Resto dos blocos
local gameBlock    = createInfoBlock(infoTab, "Seu Jogo: ", "Carregando...")
local timerBlock   = createInfoBlock(infoTab, "Tempo De Uso Do Script: ", "00:00:00")
local fpsBlock     = createInfoBlock(infoTab, "Seu Fps: ", "FPS: 0")
local playersBlock = createInfoBlock(infoTab, "Quantidade De Pessoas No Server: ", tostring(#game:GetService("Players"):GetPlayers()))

-- Serviços
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Cronômetro (começa quando o Hub abre)
local startClock = os.clock()

-- FPS (cálculo suave por frame)
local currentFPS = 0
RunService.RenderStepped:Connect(function(dt)
    currentFPS = math.floor(1/dt + 0.5)
end)

-- Pega nome do jogo atual
local function getCurrentGameName()
    local success, gameInfo = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and gameInfo and gameInfo.Name then
        return gameInfo.Name
    else
        return "Jogo Desconhecido"
    end
end

-- Atualizações periódicas (meio segundo)
task.spawn(function()
    while true do
        task.wait(0.5)

        -- Atualiza data de boas-vindas
        setBlockText(welcomeBlock, "Seja Bem Vindo Ao REDZ HUB! Hoje É Dia: ", getCurrentDate())

        -- Tempo de uso
        local e = os.clock() - startClock
        local h = math.floor(e/3600)
        local m = math.floor((e%3600)/60)
        local s = math.floor(e%60)
        setBlockText(timerBlock, "Tempo De Uso Do Script: ", string.format("%02d:%02d:%02d", h, m, s))

        -- FPS
        setBlockText(fpsBlock, "Seu Fps: ", "FPS: " .. tostring(currentFPS))

        -- Players (reforça o valor mesmo sem eventos)
        setBlockText(playersBlock, "Quantidade De Pessoas No Server: ", tostring(#Players:GetPlayers()))

        -- Nome do jogo atual
        setBlockText(gameBlock, "Seu Jogo :", getCurrentGameName())
    end
end)

-- Atualiza players ao entrar/sair alguém
local function refreshPlayers()
    setBlockText(playersBlock, "Quantidade De Pessoas No Server: ", tostring(#Players:GetPlayers()))
end
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)

infoTab:AddParagraph({"Seu Executor: " .. identifyexecutor()})

infoTab:AddSection({ "Rejoin" })

infoTab:AddButton({
    Name = "Rejoin (Mesmo Servidor)",
    Description = "Reconecta ao mesmo servidor atual",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        
        local placeId = game.PlaceId
        local jobId = game.JobId
        local player = Players.LocalPlayer
        
        -- Método mais seguro que não remove scripts
        if #Players:GetPlayers() <= 1 then
            -- Se for o único jogador, vai para um novo servidor
            TeleportService:Teleport(placeId, player)
        else
            -- Rejoin no mesmo servidor
            TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
        end
    end
})

local NovidadeTab = Window:MakeTab({"Novidades", "start"})

NovidadeTab:AddSection({ "Adicionado" })

NovidadeTab:AddParagraph({ "Adicionado:", "[+] Interface Nova do Script." })
NovidadeTab:AddParagraph({ "Adicionado:", "[+] AntiTool Player" })

NovidadeTab:AddSection({ "Arrumado" })
NovidadeTab:AddParagraph({ "Sera Arrumado:", "Alguns Flings serão corrigidos" })

NovidadeTab:AddSection({ "Removido" })
NovidadeTab:AddParagraph({ "Sera Removido:", "Funções Inuteis/Sem Utilidades" })

local CarTab = Window:MakeTab({"Veiculo", "car"})

-- Variáveis de controle para cada spam
local spammingHeadLights = false
local spammingHazardLights = false
local spammingHorn = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Função de spam para HeadLights
local function spamHeadLights()
    while spammingHeadLights do
        ReplicatedStorage.Remotes.ToggleHeadLights:InvokeServer()
        wait(0.1)
    end
end

-- Função de spam para HazardLights
local function spamHazardLights()
    while spammingHazardLights do
        ReplicatedStorage.Remotes.ToggleHazardLights:InvokeServer()
        wait(0.1)
    end
end

-- Função de spam para PlayHorn
local function spamPlayHorn()
    while spammingHorn do
        ReplicatedStorage.Remotes.PlayHorn:InvokeServer()
        wait(0.1)
    end
end


CarTab:AddSection({ "Spams" })
-- Toggle para HeadLights
CarTab:AddToggle({
    Name = "Spam HeadLights",
    Default = false,
    Callback = function(value)
        spammingHeadLights = value
        if spammingHeadLights then
            spawn(spamHeadLights)
        else
            -- Para o spam e clica uma vez para desativar
            wait(0.2) -- Aguarda um pouco para garantir que o loop parou
            ReplicatedStorage.Remotes.ToggleHeadLights:InvokeServer()
        end
    end
})

-- Toggle para HazardLights
CarTab:AddToggle({
    Name = "Spam HazardLights",
    Default = false,
    Callback = function(value)
        spammingHazardLights = value
        if spammingHazardLights then
            spawn(spamHazardLights)
        else
            -- Para o spam e clica uma vez para desativar
            wait(0.2) -- Aguarda um pouco para garantir que o loop parou
            ReplicatedStorage.Remotes.ToggleHazardLights:InvokeServer()
        end
    end
})

-- Toggle para PlayHorn
CarTab:AddToggle({
    Name = "Spam Horn",
    Default = false,
    Callback = function(value)
        spammingHorn = value
        if spammingHorn then
            spawn(spamPlayHorn)
        else
            -- Para a buzina imediatamente quando desativado
            ReplicatedStorage.Remotes.StopHorn:InvokeServer()
        end
    end
})


CarTab:AddSection({ "Speed Car & Turbo" })

local speedValue = 200  -- Valor padrão da velocidade
local turboValue = 11.3  -- Valor padrão do turbo

-- Função para encontrar todos os carros no workspace
local function getAllCars()
    local cars = {}
    if workspace.Vehicles then
        for _, vehicle in pairs(workspace.Vehicles:GetChildren()) do
            if vehicle:FindFirstChild("Seats") and vehicle.Seats:FindFirstChild("VehicleSeat") then
                table.insert(cars, vehicle)
            end
        end
    end
    return cars
end

-- Função para aplicar valores em todos os carros
local function applyToAllCars(valueType, value)
    local cars = getAllCars()
    local carsModified = 0
    
    if #cars == 0 then
        print(" Nenhum carro encontrado em workspace.Vehicles!")
        return
    end
    
    for _, vehicle in pairs(cars) do
        local vehicleSeat = vehicle.Seats.VehicleSeat
        print(" Verificando carro: " .. vehicle.Name)
        
        -- Listar todos os filhos do VehicleSeat para debug
        print(" Objetos no VehicleSeat:")
        for _, child in pairs(vehicleSeat:GetChildren()) do
            print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
        end
        
        local targetObj = vehicleSeat:FindFirstChild(valueType)
        
        if targetObj then
            print(" Encontrou " .. valueType .. " (" .. targetObj.ClassName .. ")")
            
            if targetObj:IsA("NumberValue") then
                targetObj.Value = value
                carsModified = carsModified + 1
                print(" " .. valueType .. " (NumberValue) alterado para " .. value)
            elseif targetObj:IsA("IntValue") then
                targetObj.Value = value
                carsModified = carsModified + 1
                print(" " .. valueType .. " (IntValue) alterado para " .. value)
            elseif targetObj:IsA("StringValue") then
                targetObj.Value = tostring(value)
                carsModified = carsModified + 1
                print(" " .. valueType .. " (StringValue) alterado para " .. value)
            else
                print(" " .. valueType .. " é do tipo " .. targetObj.ClassName)
                -- Tentar alterar diretamente
                pcall(function()
                    targetObj.Value = value
                    carsModified = carsModified + 1
                    print(" " .. valueType .. " alterado diretamente para " .. value)
                end)
            end
        else
            print(" " .. valueType .. " não encontrado no VehicleSeat")
            
            -- Tentar como propriedade direta do VehicleSeat
            local success = pcall(function()
                if valueType == "MaxSpeed" then
                    vehicleSeat.MaxSpeed = value
                elseif valueType == "Turbo" then
                    vehicleSeat.Turbo = value
                end
                carsModified = carsModified + 1
                print(" " .. valueType .. " (propriedade VehicleSeat) alterado para " .. value)
            end)
            
            if not success then
                print(" Falha ao alterar " .. valueType .. " como propriedade")
            end
        end
    end
    
    print(" Total de carros modificados: " .. carsModified)
end

-- TextBox para Velocidade
CarTab:AddTextBox({
    Name = "Velocidade MaxSpeed",
    Description = "Digite o valor da velocidade máxima",
    PlaceholderText = "200",
    Callback = function(Value)
        local numValue = tonumber(Value)
        if numValue then
            speedValue = numValue
            print(" Velocidade definida para: " .. speedValue)
        else
            print(" Erro: Digite apenas números para a velocidade")
        end
    end
})

-- TextBox para Turbo
CarTab:AddTextBox({
    Name = "Potência Turbo",
    Description = "Digite o valor do turbo",
    PlaceholderText = "11.3",
    Callback = function(Value)
        local numValue = tonumber(Value)
        if numValue then
            turboValue = numValue
            print(" Turbo definido para: " .. turboValue)
        else
            print(" Erro: Digite apenas números para o turbo")
        end
    end
})

-- Botão para aplicar VELOCIDADE
CarTab:AddButton({
    Name = "Aplicar Velocidade",
    Description = "Aplica a velocidade em todos os carros",
    Callback = function()
        print(" Aplicando velocidade " .. speedValue .. " em todos os carros...")
        applyToAllCars("MaxSpeed", speedValue)
    end
})

-- Botão para aplicar TURBO
CarTab:AddButton({
    Name = "Aplicar Turbo",
    Description = "Aplica o turbo em todos os carros",
    Callback = function()
        print(" Aplicando turbo " .. turboValue .. " em todos os carros...")
        applyToAllCars("Turbo", turboValue)
    end
})

print("")

CarTab:AddSection({ "Bring All Carros & Kill All" })

CarTab:AddButton({
    Name = "Bring All Cars",
    Callback = function()
        for _, v in next, workspace.Vehicles:GetChildren() do
            v:SetPrimaryPartCFrame(game.Players.LocalPlayer.Character:GetPrimaryPartCFrame())
        end
    end
})

CarTab:AddParagraph({"Informação:", "Pega ou puxa todos carro até você"})

CarTab:AddButton({
    Name = "Kill All Cars",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character
        if not character or not character.PrimaryPart then 
            print("Personagem não encontrado!")
            return 
        end
        
        -- Salva a posição original do jogador
        local originalPosition = character.PrimaryPart.CFrame
        
        -- Posição de destino para destruir os carros
        local killPosition = CFrame.new(-46, -232, -326)
        
        -- Pega todos os veículos
        local vehiclesFolder = workspace:FindFirstChild("Vehicles")
        if not vehiclesFolder then
            print("Pasta de veículos não encontrada!")
            return
        end
        
        local vehicles = vehiclesFolder:GetChildren()
        local carsProcessed = 0
        
        for _, vehicle in pairs(vehicles) do
            if vehicle:IsA("Model") then
                
                -- Verifica se há algum jogador sentado no carro
                local hasPlayer = false
                for _, part in pairs(vehicle:GetDescendants()) do
                    if part:IsA("VehicleSeat") or part:IsA("Seat") then
                        if part.Occupant then
                            hasPlayer = true
                            break
                        end
                    end
                end
                
                -- Se não tiver ninguém sentado, processa o carro
                if not hasPlayer then
                    -- Encontra o assento do veículo
                    local vehicleSeat = vehicle:FindFirstChildWhichIsA("VehicleSeat", true)
                    
                    if vehicleSeat then
                        -- Desbloqueia o carro temporariamente
                        local originalDisabled = vehicleSeat.Disabled
                        vehicleSeat.Disabled = false
                        
                        -- Teleporta o jogador para perto do carro
                        local carPosition = vehicleSeat.CFrame
                        character:SetPrimaryPartCFrame(carPosition + Vector3.new(0, 3, 0))
                        
                        task.wait(0.3)
                        
                        -- Senta no carro
                        vehicleSeat:Sit(character:FindFirstChildOfClass("Humanoid"))
                        
                        task.wait(0.5)
                        
                        -- Teleporta o carro (com o jogador) para a posição de kill
                        if vehicle.PrimaryPart then
                            vehicle:SetPrimaryPartCFrame(killPosition)
                        else
                            vehicleSeat.CFrame = killPosition
                        end
                        
                        task.wait(0.3)
                        
                        -- Levanta do assento
                        character:FindFirstChildOfClass("Humanoid").Sit = false
                        
                        task.wait(0.2)
                        
                        -- Volta para a posição original
                        character:SetPrimaryPartCFrame(originalPosition)
                        
                        -- Restaura o estado original do assento (se estava trancado)
                        vehicleSeat.Disabled = originalDisabled
                        
                        carsProcessed = carsProcessed + 1
                        
                        -- Aguarda antes de pegar o próximo carro
                        task.wait(0.5)
                    end
                end
            end
        end
        
        print("Kill All Cars concluído! " .. carsProcessed .. " carros processados.")
    end
})

CarTab:AddParagraph({"Informação:", "Apaga Todos os carros dos players recomendo usar 3 vez se o player estiver no carro não apaga"})

-- Adicionar seção na CarTab
CarTab:AddSection({ Name = "View Car" })

-- Função para obter lista de carros
local function ObterListaCarros()
    local carros = {}
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    
    if vehiclesFolder then
        for _, vehicle in pairs(vehiclesFolder:GetChildren()) do
            if vehicle:IsA("Model") then
                table.insert(carros, vehicle.Name)
            end
        end
    end
    
    if #carros == 0 then
        return {"Nenhum carro disponível"}
    end
    
    table.sort(carros)
    return carros
end

-- Criar o dropdown
local Dropdown = CarTab:AddDropdown({
    Name = "Selecionar Carro do Jogador",
    Description = "Selecione o carro de um jogador",
    Default = nil,
    Options = ObterListaCarros(),
    Callback = function(carroSelecionado)
        _G.SelectedVehicle = carroSelecionado
    end
})

-- Toggle para ver a câmera do carro selecionado
CarTab:AddToggle({
    Name = "Ver Câmera do Carro Selecionado",
    Description = "Foca a câmera no carro selecionado",
    Default = false,
    Callback = function(state)
        local Camera = workspace.CurrentCamera
        
        if state then
            if not _G.SelectedVehicle or _G.SelectedVehicle == "" or _G.SelectedVehicle == "Nenhum carro disponível" then
                print("Nenhum carro selecionado!")
                return
            end

            local vehiclesFolder = workspace:FindFirstChild("Vehicles")
            if not vehiclesFolder then
                print("Pasta de veículos não encontrada!")
                return
            end

            local vehicle = vehiclesFolder:FindFirstChild(_G.SelectedVehicle)
            if not vehicle then
                print("Carro selecionado não encontrado!")
                return
            end

            local vehicleSeat = vehicle:FindFirstChildWhichIsA("VehicleSeat", true)
            if not vehicleSeat then
                print("Assento do carro não encontrado!")
                return
            end

            -- Salvar o estado original da câmera
            _G.OriginalCameraSubject = Camera.CameraSubject
            _G.OriginalCameraType = Camera.CameraType

            -- Ajustar a câmera para o assento do carro
            Camera.CameraSubject = vehicleSeat
            Camera.CameraType = Enum.CameraType.Follow
            print("Câmera ajustada para o carro " .. _G.SelectedVehicle .. "!")
        else
            -- Restaurar a câmera ao estado original
            if _G.OriginalCameraSubject then
                Camera.CameraSubject = _G.OriginalCameraSubject
                Camera.CameraType = _G.OriginalCameraType or Enum.CameraType.Custom
                print("Câmera restaurada ao normal!")
                _G.OriginalCameraSubject = nil
                _G.OriginalCameraType = nil
            end
        end
    end
})

-- Atualizar o dropdown dinamicamente
local vehiclesFolder = workspace:WaitForChild("Vehicles")

vehiclesFolder.ChildAdded:Connect(function()
    Dropdown:Set(ObterListaCarros())
end)

vehiclesFolder.ChildRemoved:Connect(function()
    Dropdown:Set(ObterListaCarros())
end)

-- Atualização automática a cada 50 segundos
task.spawn(function()
    while task.wait(50) do
        Dropdown:Set(ObterListaCarros())
        print("Lista de carros atualizada automaticamente!")
    end
end)

-- Car RGB Section
local RGBSection = CarTab:AddSection({"Car RGB"})

CarTab:AddToggle({
    Name = "Car RGB",
    Default = false,
    Callback = function(state)
        isColorChanging = state
        if isColorChanging then
            colorChangeCoroutine = coroutine.create(changeCarColor)
            coroutine.resume(colorChangeCoroutine)
        end
    end
})

CarTab:AddParagraph({"Note", "Ativando isso deixará seu carro RGB"})

-- Fly Car Section
local FlySection = CarTab:AddSection({"Fly Car"})

CarTab:AddButton({
    Name = "Fly Car",
    Callback = function()
-- Version: 4.1

-- Instances:
local Flymguiv2 = Instance.new("ScreenGui")
local Drag = Instance.new("Frame")
local FlyFrame = Instance.new("Frame")
local ddnsfbfwewefe = Instance.new("TextButton")
local Speed = Instance.new("TextBox")
local Fly = Instance.new("TextButton")
local Speeed = Instance.new("TextLabel")
local Stat = Instance.new("TextLabel")
local Stat2 = Instance.new("TextLabel")
local Unfly = Instance.new("TextButton")
local Vfly = Instance.new("TextLabel")
local Close = Instance.new("TextButton")
local Minimize = Instance.new("TextButton")
local Flyon = Instance.new("Frame")
local W = Instance.new("TextButton")
local S = Instance.new("TextButton")

--Properties:

Flymguiv2.Name = "Car Fly gui v2"
Flymguiv2.Parent = game.CoreGui
Flymguiv2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Drag.Name = "Drag"
Drag.Parent = Flymguiv2
Drag.Active = true
Drag.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
Drag.BorderSizePixel = 0
Drag.Draggable = true
Drag.Position = UDim2.new(0.482438415, 0, 0.454874992, 0)
Drag.Size = UDim2.new(0, 237, 0, 27)

FlyFrame.Name = "FlyFrame"
FlyFrame.Parent = Drag
FlyFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
FlyFrame.BorderSizePixel = 0
FlyFrame.Draggable = true
FlyFrame.Position = UDim2.new(-0.00200000009, 0, 0.989000022, 0)
FlyFrame.Size = UDim2.new(0, 237, 0, 139)

ddnsfbfwewefe.Name = "ddnsfbfwewefe"
ddnsfbfwewefe.Parent = FlyFrame
ddnsfbfwewefe.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
ddnsfbfwewefe.BorderSizePixel = 0
ddnsfbfwewefe.Position = UDim2.new(-0.000210968778, 0, -0.00395679474, 0)
ddnsfbfwewefe.Size = UDim2.new(0, 237, 0, 27)
ddnsfbfwewefe.Font = Enum.Font.SourceSans
ddnsfbfwewefe.Text = ""
ddnsfbfwewefe.TextColor3 = Color3.fromRGB(255, 255, 255)
ddnsfbfwewefe.TextScaled = true
ddnsfbfwewefe.TextSize = 14.000
ddnsfbfwewefe.TextWrapped = true

Speed.Name = "Speed"
Speed.Parent = FlyFrame
Speed.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
Speed.BorderColor3 = Color3.fromRGB(0, 0, 191)
Speed.BorderSizePixel = 0
Speed.Position = UDim2.new(0.445025861, 0, 0.402877688, 0)
Speed.Size = UDim2.new(0, 111, 0, 33)
Speed.Font = Enum.Font.SourceSans
Speed.PlaceholderColor3 = Color3.fromRGB(255, 255, 255)
Speed.Text = "50"
Speed.TextColor3 = Color3.fromRGB(255, 255, 255)
Speed.TextScaled = true
Speed.TextSize = 14.000
Speed.TextWrapped = true

Fly.Name = "Fly"
Fly.Parent = FlyFrame
Fly.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
Fly.BorderSizePixel = 0
Fly.Position = UDim2.new(0.0759493634, 0, 0.705797076, 0)
Fly.Size = UDim2.new(0, 199, 0, 32)
Fly.Font = Enum.Font.SourceSans
Fly.Text = "Enable"
Fly.TextColor3 = Color3.fromRGB(255, 255, 255)
Fly.TextScaled = true
Fly.TextSize = 14.000
Fly.TextWrapped = true
Fly.MouseButton1Click:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	Fly.Visible = false
	Stat2.Text = "On"
	Stat2.TextColor3 = Color3.fromRGB(0, 255, 0)
	Unfly.Visible = true
	Flyon.Visible = true
	local BV = Instance.new("BodyVelocity",HumanoidRP)
	local BG = Instance.new("BodyGyro",HumanoidRP)
	BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
	game:GetService('RunService').RenderStepped:connect(function()
	BG.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
	BG.D = 5000
	BG.P = 100000
	BG.CFrame = game.Workspace.CurrentCamera.CFrame
	end)
end)

Speeed.Name = "Speeed"
Speeed.Parent = FlyFrame
Speeed.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Speeed.BorderSizePixel = 0
Speeed.Position = UDim2.new(0.0759493634, 0, 0.402877688, 0)
Speeed.Size = UDim2.new(0, 87, 0, 32)
Speeed.ZIndex = 0
Speeed.Font = Enum.Font.SourceSans
Speeed.Text = "Speed:"
Speeed.TextColor3 = Color3.fromRGB(255, 255, 255)
Speeed.TextScaled = true
Speeed.TextSize = 14.000
Speeed.TextWrapped = true

Stat.Name = "Stat"
Stat.Parent = FlyFrame
Stat.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Stat.BorderSizePixel = 0
Stat.Position = UDim2.new(0.299983799, 0, 0.239817441, 0)
Stat.Size = UDim2.new(0, 85, 0, 15)
Stat.Font = Enum.Font.SourceSans
Stat.Text = "Status:"
Stat.TextColor3 = Color3.fromRGB(255, 255, 255)
Stat.TextScaled = true
Stat.TextSize = 14.000
Stat.TextWrapped = true

Stat2.Name = "Stat2"
Stat2.Parent = FlyFrame
Stat2.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Stat2.BorderSizePixel = 0
Stat2.Position = UDim2.new(0.546535194, 0, 0.239817441, 0)
Stat2.Size = UDim2.new(0, 27, 0, 15)
Stat2.Font = Enum.Font.SourceSans
Stat2.Text = "Off"
Stat2.TextColor3 = Color3.fromRGB(255, 0, 0)
Stat2.TextScaled = true
Stat2.TextSize = 14.000
Stat2.TextWrapped = true

Unfly.Name = "Unfly"
Unfly.Parent = FlyFrame
Unfly.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
Unfly.BorderSizePixel = 0
Unfly.Position = UDim2.new(0.0759493634, 0, 0.705797076, 0)
Unfly.Size = UDim2.new(0, 199, 0, 32)
Unfly.Visible = false
Unfly.Font = Enum.Font.SourceSans
Unfly.Text = "Disable"
Unfly.TextColor3 = Color3.fromRGB(255, 255, 255)
Unfly.TextScaled = true
Unfly.TextSize = 14.000
Unfly.TextWrapped = true
Unfly.MouseButton1Click:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	Fly.Visible = true
	Stat2.Text = "Off"
	Stat2.TextColor3 = Color3.fromRGB(255, 0, 0)
	wait()
	Unfly.Visible = false
	Flyon.Visible = false
	HumanoidRP:FindFirstChildOfClass("BodyVelocity"):Destroy()
	HumanoidRP:FindFirstChildOfClass("BodyGyro"):Destroy()
end)

Vfly.Name = "Vfly"
Vfly.Parent = Drag
Vfly.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
Vfly.BorderSizePixel = 0
Vfly.Size = UDim2.new(0, 57, 0, 27)
Vfly.Font = Enum.Font.SourceSans
Vfly.Text = "Car fly"
Vfly.TextColor3 = Color3.fromRGB(255, 255, 255)
Vfly.TextScaled = true
Vfly.TextSize = 14.000
Vfly.TextWrapped = true

Close.Name = "Close"
Close.Parent = Drag
Close.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
Close.BorderSizePixel = 0
Close.Position = UDim2.new(0.875, 0, 0, 0)
Close.Size = UDim2.new(0, 27, 0, 27)
Close.Font = Enum.Font.SourceSans
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextScaled = true
Close.TextSize = 14.000
Close.TextWrapped = true
Close.MouseButton1Click:Connect(function()
	Flymguiv2:Destroy()
end)

Minimize.Name = "Minimize"
Minimize.Parent = Drag
Minimize.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
Minimize.BorderSizePixel = 0
Minimize.Position = UDim2.new(0.75, 0, 0, 0)
Minimize.Size = UDim2.new(0, 27, 0, 27)
Minimize.Font = Enum.Font.SourceSans
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Minimize.TextScaled = true
Minimize.TextSize = 14.000
Minimize.TextWrapped = true
function Mini()
	if Minimize.Text == "-" then
		Minimize.Text = "+"
		FlyFrame.Visible = false
	elseif Minimize.Text == "+" then
		Minimize.Text = "-"
		FlyFrame.Visible = true
	end
end
Minimize.MouseButton1Click:Connect(Mini)

Flyon.Name = "Fly on"
Flyon.Parent = Flymguiv2
Flyon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Flyon.BorderSizePixel = 0
Flyon.Position = UDim2.new(0.117647067, 0, 0.550284624, 0)
Flyon.Size = UDim2.new(0.148000002, 0, 0.314999998, 0)
Flyon.Visible = false
Flyon.Active = true
Flyon.Draggable = true

W.Name = "W"
W.Parent = Flyon
W.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
W.BorderSizePixel = 0
W.Position = UDim2.new(0.134719521, 0, 0.0152013302, 0)
W.Size = UDim2.new(0.708999991, 0, 0.499000013, 0)
W.Font = Enum.Font.SourceSans
W.Text = "^"
W.TextColor3 = Color3.fromRGB(255, 255, 255)
W.TextScaled = true
W.TextSize = 14.000
W.TextWrapped = true
W.TouchLongPress:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * 0
end)

W.MouseButton1Click:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * 0
end)

S.Name = "S"
S.Parent = Flyon
S.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
S.BorderSizePixel = 0
S.Position = UDim2.new(0.134000003, 0, 0.479999989, 0)
S.Rotation = 180.000
S.Size = UDim2.new(0.708999991, 0, 0.499000013, 0)
S.Font = Enum.Font.SourceSans
S.Text = "^"
S.TextColor3 = Color3.fromRGB(255, 255, 255)
S.TextScaled = true
S.TextSize = 14.000
S.TextWrapped = true
S.TouchLongPress:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * 0
end)

S.MouseButton1Click:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -Speed.Text
	wait(.1)
	HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * 0
end)
    end
})

-- ========== PROTEÇÃO CONTRA RESET NO CARREGAMENTO ==========
_G.hubCarregando = true
_G.togglesInicializadas = {}

spawn(function()
    -- Espera o ReplicatedStorage estar pronto
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    
    if Remotes then
        local ResetRemote = Remotes:WaitForChild("ResetCharacterAppearance", 10)
        
        if ResetRemote then
            -- Sobrescreve a função de reset
            local ResetOriginal = ResetRemote.FireServer
            ResetRemote.FireServer = function(...)
                if _G.hubCarregando then
                    return -- Bloqueia reset durante carregamento
                end
                return ResetOriginal(...)
            end
        end
    end
    
    -- Libera após 3 segundos
    wait(3)
    _G.hubCarregando = false
end)
-- ============================================================

local Tab = Window:MakeTab({"Avatar", "rbxassetid://10734952036"})

Tab:AddSection({ Name = "Copiar Skin" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local LocalPlayer = Players.LocalPlayer
local selectedPlayerName = nil

-- Função para obter os nomes dos jogadores (excluindo o jogador local)
local function getPlayerList()
    local PlayerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name ~= LocalPlayer.Name then
            table.insert(PlayerNames, player.Name)
        end
    end
    return PlayerNames
end

-- Dropdown de seleção de jogador
local killDropdown = Tab:AddDropdown({
    Name = "Selecionar Jogador",
    Options = getPlayerList(),
    Default = "", -- Estado inicial vazio (mostra "..." ou equivalente)
    Callback = function(value)
        selectedPlayerName = value
        getgenv().Target = value
        print("" .. tostring(value))
    end
})

-- Função para atualizar o dropdown
local function UpdateDropdown()
    local tablePlayers = Players:GetPlayers()
    local newPlayers = {}
    if killDropdown then
        for _, player in ipairs(tablePlayers) do
            if player.Name ~= LocalPlayer.Name then
                table.insert(newPlayers, player.Name)
            end
        end
        killDropdown:Set(newPlayers)
        -- Sempre reseta a seleção ao atualizar
        selectedPlayerName = nil
        getgenv().Target = nil
        killDropdown:SetValue("") -- Define o dropdown como vazio ("..." ou equivalente)
        print("Lista de jogadores atualizada: ", table.concat(newPlayers, ", "))
        if #newPlayers == 0 then
            print("Nenhum jogador disponível (exceto você).")
        end
    else
        print("Erro: Dropdown não encontrado.")
    end
end

-- Atualiza o dropdown automaticamente quando jogadores entram ou saem
Players.PlayerAdded:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(UpdateDropdown)

-- Botão para atualizar a lista de jogadores manualmente
Tab:AddButton({
    Name = "Atualizar Player List",
    Callback = function()
        local tablePlayers = Players:GetPlayers()
        local newPlayers = {}
        if killDropdown then
            for _, player in ipairs(tablePlayers) do
                if player.Name ~= LocalPlayer.Name then
                    table.insert(newPlayers, player.Name)
                end
            end
            killDropdown:Set(newPlayers)
            selectedPlayerName = nil
            getgenv().Target = nil
            killDropdown:SetValue("") -- Define o dropdown como vazio ("..." ou equivalente)
            print("Lista de jogadores atualizada manualmente: ", table.concat(newPlayers, ", "))
            print("Seleção resetada ao atualizar a lista.")
            if #newPlayers == 0 then
                print("Nenhum jogador disponível (exceto você).")
            end
        else
            print("Erro: Dropdown não encontrado.")
        end
    end
})

Tab:AddButton({
    Name = "Copiar Avatar",
    Callback = function()
        if not Target then return end

        local LP = Players.LocalPlayer
        local LChar = LP.Character
        local TPlayer = Players:FindFirstChild(Target)

        if TPlayer and TPlayer.Character then
            local LHumanoid = LChar and LChar:FindFirstChildOfClass("Humanoid")
            local THumanoid = TPlayer.Character:FindFirstChildOfClass("Humanoid")

            if LHumanoid and THumanoid then
                -- RESETAR LOCALPLAYER
                local LDesc = LHumanoid:GetAppliedDescription()

                -- Remover acessÃ³rios, roupas e face atuais
                for _, acc in ipairs(LDesc:GetAccessories(true)) do
                    if acc.AssetId and tonumber(acc.AssetId) then
                        Remotes.Wear:InvokeServer(tonumber(acc.AssetId))
                        task.wait(0.2)
                    end
                end

                if tonumber(LDesc.Shirt) then
                    Remotes.Wear:InvokeServer(tonumber(LDesc.Shirt))
                    task.wait(0.2)
                end

                if tonumber(LDesc.Pants) then
                    Remotes.Wear:InvokeServer(tonumber(LDesc.Pants))
                    task.wait(0.2)
                end

                if tonumber(LDesc.Face) then
                    Remotes.Wear:InvokeServer(tonumber(LDesc.Face))
                    task.wait(0.2)
                end

                -- COPIAR DO JOGADOR ALVO
                local PDesc = THumanoid:GetAppliedDescription()

                -- Enviar partes do corpo
                local argsBody = {
                    [1] = {
                        [1] = PDesc.Torso,
                        [2] = PDesc.RightArm,
                        [3] = PDesc.LeftArm,
                        [4] = PDesc.RightLeg,
                        [5] = PDesc.LeftLeg,
                        [6] = PDesc.Head
                    }
                }
                Remotes.ChangeCharacterBody:InvokeServer(unpack(argsBody))
                task.wait(0.5)

                if tonumber(PDesc.Shirt) then
                    Remotes.Wear:InvokeServer(tonumber(PDesc.Shirt))
                    task.wait(0.3)
                end

                if tonumber(PDesc.Pants) then
                    Remotes.Wear:InvokeServer(tonumber(PDesc.Pants))
                    task.wait(0.3)
                end

                if tonumber(PDesc.Face) then
                    Remotes.Wear:InvokeServer(tonumber(PDesc.Face))
                    task.wait(0.3)
                end

                for _, v in ipairs(PDesc:GetAccessories(true)) do
                    if v.AssetId and tonumber(v.AssetId) then
                        Remotes.Wear:InvokeServer(tonumber(v.AssetId))
                        task.wait(0.3)
                    end
                end

                local SkinColor = TPlayer.Character:FindFirstChild("Body Colors")
                if SkinColor then
                    Remotes.ChangeBodyColor:FireServer(tostring(SkinColor.HeadColor))
                    task.wait(0.3)
                end

                if tonumber(PDesc.IdleAnimation) then
                    Remotes.Wear:InvokeServer(tonumber(PDesc.IdleAnimation))
                    task.wait(0.3)
                end

                -- Nome, bio e cor
                local Bag = TPlayer:FindFirstChild("PlayersBag")
                if Bag then
                    if Bag:FindFirstChild("RPName") and Bag.RPName.Value ~= "" then
                        Remotes.RPNameText:FireServer("RolePlayName", Bag.RPName.Value)
                        task.wait(0.3)
                    end
                    if Bag:FindFirstChild("RPBio") and Bag.RPBio.Value ~= "" then
                        Remotes.RPNameText:FireServer("RolePlayBio", Bag.RPBio.Value)
                        task.wait(0.3)
                    end
                    if Bag:FindFirstChild("RPNameColor") then
                        Remotes.RPNameColor:FireServer("PickingRPNameColor", Bag.RPNameColor.Value)
                        task.wait(0.3)
                    end
                    if Bag:FindFirstChild("RPBioColor") then
                        Remotes.RPNameColor:FireServer("PickingRPBioColor", Bag.RPBioColor.Value)
                        task.wait(0.3)
                    end
                end
            end
        end
    end
})

Tab:AddSection({ "Partes do Corpo:" })

-- Variáveis globais para armazenar partes selecionadas
_G.selectedParts = {
    Torso = nil,
    BracoDireito = nil,
    BracoEsquerdo = nil,
    PernaDireita = nil,
    PernaEsquerda = nil,
    Cabeca = nil
}

-- TextBox para Torso
Tab:AddTextBox({
    Name = "Tronco",
    Description = "ID do Tronco",
    PlaceholderText = "ID",
    TextSize = 16,
    FontSize = 16,
    Callback = function(Value)
        if Value == "" then
            _G.selectedParts.Torso = nil
            print("Tronco: vazio")
        else
            local id = tonumber(Value) or 0
            _G.selectedParts.Torso = id
            print("Tronco: " .. id)
        end
    end
})

-- TextBox para Right Arm  
Tab:AddTextBox({
    Name = "Braço Direito",
    Description = "ID do Braço Direito",
    PlaceholderText = "ID",
    TextSize = 16,
    FontSize = 16,
    Callback = function(Value)
        if Value == "" then
            _G.selectedParts.BracoDireito = nil
            print("Braço Direito: vazio")
        else
            local id = tonumber(Value) or 0
            _G.selectedParts.BracoDireito = id
            print("Braço Direito: " .. id)
        end
    end
})

-- TextBox para Left Arm
Tab:AddTextBox({
    Name = "Braço Esquerdo",
    Description = "ID do Braço Esquerdo",
    PlaceholderText = "ID",
    TextSize = 16,
    FontSize = 16,
    Callback = function(Value)
        if Value == "" then
            _G.selectedParts.BracoEsquerdo = nil
            print("Braço Esquerdo: vazio")
        else
            local id = tonumber(Value) or 0
            _G.selectedParts.BracoEsquerdo = id
            print("Braço Esquerdo: " .. id)
        end
    end
})

-- TextBox para Right Leg
Tab:AddTextBox({
    Name = "Perna Direita",
    Description = "ID da Perna Direita",
    PlaceholderText = "ID",
    TextSize = 16,
    FontSize = 16,
    Callback = function(Value)
        if Value == "" then
            _G.selectedParts.PernaDireita = nil
            print("Perna Direita: vazio")
        else
            local id = tonumber(Value) or 0
            _G.selectedParts.PernaDireita = id
            print("Perna Direita: " .. id)
        end
    end
})

-- TextBox para Left Leg
Tab:AddTextBox({
    Name = "Perna Esquerda",
    Description = "ID da Perna Esquerda",
    PlaceholderText = "ID",
    TextSize = 16,
    FontSize = 16,
    Callback = function(Value)
        if Value == "" then
            _G.selectedParts.PernaEsquerda = nil
            print("Perna Esquerda: vazio")
        else
            local id = tonumber(Value) or 0
            _G.selectedParts.PernaEsquerda = id
            print("Perna Esquerda: " .. id)
        end
    end
})

-- TextBox para Head
Tab:AddTextBox({
    Name = "Cabeça",
    Description = "ID da Cabeça",
    PlaceholderText = "ID",
    TextSize = 16,
    FontSize = 16,
    Callback = function(Value)
        if Value == "" then
            _G.selectedParts.Cabeca = nil
            print("Cabeça: vazio")
        else
            local id = tonumber(Value) or 0
            _G.selectedParts.Cabeca = id
            print("Cabeça: " .. id)
        end
    end
})

Tab:AddSection({ "Carregar Partes:" })

-- Variável para armazenar a parte selecionada no dropdown
_G.parteSelecionada = "Tronco"

-- Dropdown para selecionar qual parte carregar
Tab:AddDropdown({
    Name = "Selecionar Parte",
    Description = "Escolha qual parte equipar",
    Default = "Tronco",
    Options = {"Tronco", "Braço Direito", "Braço Esquerdo", "Perna Direita", "Perna Esquerda", "Cabeça"},
    Callback = function(Value)
        _G.parteSelecionada = Value
        print("" .. Value)
    end
})

-- Botão para equipar a parte selecionada no dropdown
Tab:AddButton({
    Name = "Equipar Parte Selecionada",
    Description = "Equipa apenas a parte escolhida no dropdown",
    Callback = function()
        local args = {
            [1] = {
                [1] = 0, -- Torso
                [2] = 0, -- Right Arm
                [3] = 0, -- Left Arm
                [4] = 0, -- Right Leg
                [5] = 0, -- Left Leg
                [6] = 0  -- Head
            }
        }
        
        -- Define qual parte carregar baseado na seleção do dropdown
        if _G.parteSelecionada == "Tronco" and _G.selectedParts.Torso then
            args[1][1] = _G.selectedParts.Torso
            print("Equipando Tronco: " .. _G.selectedParts.Torso)
        elseif _G.parteSelecionada == "Braço Direito" and _G.selectedParts.BracoDireito then
            args[1][2] = _G.selectedParts.BracoDireito
            print("Equipando Braço Direito: " .. _G.selectedParts.BracoDireito)
        elseif _G.parteSelecionada == "Braço Esquerdo" and _G.selectedParts.BracoEsquerdo then
            args[1][3] = _G.selectedParts.BracoEsquerdo
            print("Equipando Braço Esquerdo: " .. _G.selectedParts.BracoEsquerdo)
        elseif _G.parteSelecionada == "Perna Direita" and _G.selectedParts.PernaDireita then
            args[1][4] = _G.selectedParts.PernaDireita
            print("Equipando Perna Direita: " .. _G.selectedParts.PernaDireita)
        elseif _G.parteSelecionada == "Perna Esquerda" and _G.selectedParts.PernaEsquerda then
            args[1][5] = _G.selectedParts.PernaEsquerda
            print("Equipando Perna Esquerda: " .. _G.selectedParts.PernaEsquerda)
        elseif _G.parteSelecionada == "Cabeça" and _G.selectedParts.Cabeca then
            args[1][6] = _G.selectedParts.Cabeca
            print("Equipando Cabeça: " .. _G.selectedParts.Cabeca)
        else
            print("Erro: " .. _G.parteSelecionada .. " está vazia! Digite um ID primeiro.")
            return
        end
        
        -- Executa o remote
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.ChangeCharacterBody:InvokeServer(unpack(args))
        end)
    end
})

-- Botão para carregar todas as partes de uma vez
Tab:AddButton({
    Name = "Carregar Todas as Partes",
    Description = "Equipa todas as partes digitadas de uma vez",
    Callback = function()
        -- Verifica se pelo menos uma parte tem ID
        local temAlgumaParteSelecionada = _G.selectedParts.Torso or _G.selectedParts.BracoDireito or 
                                         _G.selectedParts.BracoEsquerdo or _G.selectedParts.PernaDireita or 
                                         _G.selectedParts.PernaEsquerda or _G.selectedParts.Cabeca
        
        if not temAlgumaParteSelecionada then
            print("Erro: Nenhuma parte foi selecionada! Digite pelo menos um ID.")
            return
        end
        
        local args = {
            [1] = {
                [1] = _G.selectedParts.Torso or 0,
                [2] = _G.selectedParts.BracoDireito or 0,
                [3] = _G.selectedParts.BracoEsquerdo or 0,
                [4] = _G.selectedParts.PernaDireita or 0,
                [5] = _G.selectedParts.PernaEsquerda or 0,
                [6] = _G.selectedParts.Cabeca or 0
            }
        }
        
        print("Carregando partes selecionadas:")
        if _G.selectedParts.Torso then print("Tronco: " .. _G.selectedParts.Torso) end
        if _G.selectedParts.BracoDireito then print("Braço Direito: " .. _G.selectedParts.BracoDireito) end
        if _G.selectedParts.BracoEsquerdo then print("Braço Esquerdo: " .. _G.selectedParts.BracoEsquerdo) end
        if _G.selectedParts.PernaDireita then print("Perna Direita: " .. _G.selectedParts.PernaDireita) end
        if _G.selectedParts.PernaEsquerda then print("Perna Esquerda: " .. _G.selectedParts.PernaEsquerda) end
        if _G.selectedParts.Cabeca then print("Cabeça: " .. _G.selectedParts.Cabeca) end
        
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.ChangeCharacterBody:InvokeServer(unpack(args))
        end)
    end
})

Tab:AddSection({ "Outros:" })

-- Botão para Reset Character
Tab:AddButton({
    Name = "Resetar Personagem",
    Description = "Reset completo do personagem",
    Callback = function()
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.ResetCharacterAppearance:FireServer()
        end)
        print("Personagem resetado completamente!")
    end
})

Tab:AddButton({
    Name = "R6 FE",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/R6-ANIMATION/refs/heads/main/R6%20brookhaven"))()
    end
})

Tab:AddSection({ "FE:" })

-- Dropdown para escolher a cor do fogo
Tab:AddDropdown({
    Name = "Fire Colors",
    Description = "Select the <font color='rgb(255, 100, 100)'>Fire Color</font>",
    Options = {"White", "Orange", "Green", "Blue", "Purple", "Black"},
    Default = "White",
    Flag = "fire_color_dropdown",
    Callback = function(Value)
        -- Tabela com as cores e seus respectivos IDs e códigos
        local fireColors = {
            ["White"] = {
                id = "18637074370",
                code = "030FireWhite"
            },
            ["Orange"] = {
                id = "18637025451", 
                code = "031FireOrange"
            },
            ["Green"] = {
                id = "18637078598",
                code = "032FireGreen"
            },
            ["Blue"] = {
                id = "18637076370",
                code = "033FireBlue"
            },
            ["Purple"] = {
                id = "18637070174",
                code = "034FirePurple"
            },
            ["Black"] = {
                id = "18637072603",
                code = "035FireBlack"
            }
        }
        
        -- Armazena globalmente a cor selecionada
        _G.selectedColor = Value
        print("" .. Value)
    end
})

-- Botão para equipar a cor escolhida
Tab:AddButton({
    Name = "Equip Fire Color",
    Callback = function()
        -- Tabela com as cores e seus respectivos IDs e códigos
        local fireColors = {
            ["White"] = {
                id = "18637074370",
                code = "030FireWhite"
            },
            ["Orange"] = {
                id = "18637025451", 
                code = "031FireOrange"
            },
            ["Green"] = {
                id = "18637078598",
                code = "032FireGreen"
            },
            ["Blue"] = {
                id = "18637076370",
                code = "033FireBlue"
            },
            ["Purple"] = {
                id = "18637070174",
                code = "034FirePurple"
            },
            ["Black"] = {
                id = "18637072603",
                code = "035FireBlack"
            }
        }
        
        local selectedColor = _G.selectedColor or "White"
        
        if selectedColor and fireColors[selectedColor] then
            local colorData = fireColors[selectedColor]
            
            local args = {
                [1] = colorData.id,
                [2] = colorData.code
            }
            
            -- Aplica o emmiter com a cor selecionada
            game:GetService("ReplicatedStorage").Remotes.ApplyEmmiter:InvokeServer(unpack(args))
            
            print("Equipado: " .. selectedColor .. " Fire")
        else
            warn("Erro: Cor não encontrada!")
        end
    end
})

-- Dropdown para escolher a cor do smoke
Tab:AddDropdown({
    Name = "Smoke Colors",
    Description = "Select the <font color='rgb(150, 150, 150)'>Smoke Color</font>",
    Options = {"White", "Yellow", "Orange", "Green", "Blue", "Purple", "Red", "Black"},
    Default = "White",
    Flag = "smoke_color_dropdown",
    Callback = function(Value)
        -- Tabela com as cores de smoke e seus respectivos IDs e códigos
        local smokeColors = {
            ["White"] = {
                id = "18637791748",
                code = "080SmokeWhite"
            },
            ["Yellow"] = {
                id = "18637800482",
                code = "081SmokeYellow"
            },
            ["Orange"] = {
                id = "18637793920",
                code = "082SmokeOrange"
            },
            ["Green"] = {
                id = "18637789299",
                code = "083SmokeGreen"
            },
            ["Blue"] = {
                id = "18637803021",
                code = "084SmokeBlue"
            },
            ["Purple"] = {
                id = "18637813360",
                code = "085SmokePurple"
            },
            ["Red"] = {
                id = "18637796598",
                code = "086SmokeRed"
            },
            ["Black"] = {
                id = "18637798529",
                code = "087SmokeBlack"
            }
        }
        
        -- Armazena globalmente a cor de smoke selecionada
        _G.selectedSmokeColor = Value
        print("" .. Value)
    end
})

-- Botão para equipar a cor de smoke escolhida
Tab:AddButton({
    Name = "Equip Smoke Color",
    Callback = function()
        -- Tabela com as cores de smoke e seus respectivos IDs e códigos
        local smokeColors = {
            ["White"] = {
                id = "18637791748",
                code = "080SmokeWhite"
            },
            ["Yellow"] = {
                id = "18637800482",
                code = "081SmokeYellow"
            },
            ["Orange"] = {
                id = "18637793920",
                code = "082SmokeOrange"
            },
            ["Green"] = {
                id = "18637789299",
                code = "083SmokeGreen"
            },
            ["Blue"] = {
                id = "18637803021",
                code = "084SmokeBlue"
            },
            ["Purple"] = {
                id = "18637813360",
                code = "085SmokePurple"
            },
            ["Red"] = {
                id = "18637796598",
                code = "086SmokeRed"
            },
            ["Black"] = {
                id = "18637798529",
                code = "087SmokeBlack"
            }
        }
        
        local selectedSmokeColor = _G.selectedSmokeColor or "White"
        
        if selectedSmokeColor and smokeColors[selectedSmokeColor] then
            local colorData = smokeColors[selectedSmokeColor]
            
            local args = {
                [1] = colorData.id,
                [2] = colorData.code
            }
            
            -- Aplica o emmiter com a cor de smoke selecionada
            game:GetService("ReplicatedStorage").Remotes.ApplyEmmiter:InvokeServer(unpack(args))
            
            print("Equipado: " .. selectedSmokeColor .. " Smoke")
        else
            warn("Erro: Cor de smoke não encontrada!")
        end
    end
})

-- Variável global para controlar primeira execução
if not _G.togglesInicializadas then
    _G.togglesInicializadas = {}
end

Tab:AddToggle({
    Name = "Small",
    Description = "",
    Default = false,
    Flag = "custom_body_toggle",
    Callback = function(Value)
        if not _G.togglesInicializadas["Small"] then
            _G.togglesInicializadas["Small"] = true
            return
        end
        
        local customBody = {
            [1] = 104157277410075,
            [2] = 86280536086607,
            [3] = 81974054542977,
            [4] = 74524984742501,
            [5] = 122626731952977,
            [6] = 134082579
        }
        
        if Value then
            local args = {[1] = customBody}
            game:GetService("ReplicatedStorage").Remotes.ChangeCharacterBody:InvokeServer(unpack(args))
        else
            game:GetService("ReplicatedStorage").Remotes.ResetCharacterAppearance:FireServer()
        end
    end
})

Tab:AddToggle({
    Name = "Giant Avatar",
    Description = "",
    Default = false,
    Flag = "custom_body_v2_toggle",
    Callback = function(Value)
        if not _G.togglesInicializadas["Giant"] then
            _G.togglesInicializadas["Giant"] = true
            return
        end
        
        local customBodyV2 = {
            [1] = 17713016036,
            [2] = 17713016151,
            [3] = 17713015861,
            [4] = 17713021340,
            [5] = 17713016191,
            [6] = 6340213
        }
        
        if Value then
            local args = {[1] = customBodyV2}
            game:GetService("ReplicatedStorage").Remotes.ChangeCharacterBody:InvokeServer(unpack(args))
        else
            game:GetService("ReplicatedStorage").Remotes.ResetCharacterAppearance:FireServer()
        end
    end
})

Tab:AddSection({ "Outros Efeitos (Fire & Smoke)" })

-- Toggle para Loop Smoke Avatar
Tab:AddToggle({
    Name = "Loop Smoke",
    Default = false,
    Callback = function(Value)
        -- Variável para controlar o loop de smoke
        local isSmokeLoopActive = Value

        if Value then
            -- Inicia o loop quando ativado
            spawn(function()
                while isSmokeLoopActive do
                    local mall = workspace:WaitForChild("WorkspaceCom"):WaitForChild("001_Mall"):WaitForChild("001_Pizza"):FindFirstChild("CatchFire")
                    
                    if mall then
                        local touchInterest = mall:FindFirstChild("TouchInterest")
                        if touchInterest then
                            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, mall, 0)
                            wait()
                            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, mall, 1)
                        end
                    end
                    wait(1)
                end
                print("Loop Smoke Avatar desativado!")
            end)
        else
            print("")
        end
    end
})

-- Toggle para Loop Fire Avatar
Tab:AddToggle({
    Name = "Loop Fire",
    Description = "As Vezes Nao Pega So Pega Se Tiver Casa Com Churrasqueira",
    Default = false,
    Callback = function(Value)
        -- Variável para controlar o loop de fire
        local isFireLoopActive = Value

        if Value then
            -- Inicia o loop quando ativado
            spawn(function()
                while isFireLoopActive do
                    local playerName = game.Players.LocalPlayer.Name
                    local lotFolder = game:GetService("Workspace"):WaitForChild("001_Lots")
                    local house = lotFolder:FindFirstChild(playerName .. "House")

                    if house then
                        local mall = house:WaitForChild("HousePickedByPlayer"):WaitForChild("HouseModel"):WaitForChild("001_BBQ"):FindFirstChild("CatchFire")
                        if mall then
                            local touchInterest = mall:FindFirstChild("TouchInterest")
                            if touchInterest then
                                firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, mall, 0)
                                wait()
                                firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, mall, 1)
                            end
                        end
                    else
                        warn("House not found for player: " .. playerName)
                    end
                    wait(1)
                end
                print("Loop Fire Avatar desativado!")
            end)
        else
            print("")
        end
    end
})

Tab:AddSection({"Roupas 3D"})

Tab:AddDropdown({
    Name = "Acessórios 3D",
    Description = "Selecione para equipar",
    Default = nil,
    Options = {
        "La Vaca Saturno",
        "brainrot",
        "Galo",
        "Capivara",
        "Tigre",
        "Capivara",
        "Peixe",
        "Pepino Doidao",
        "Gato",
        "Rato",
        "Sei la KKKKOKK",
        "Pato Banana",
        "Fantasma",
        "Gato Lasanha",
        "Arvore",
        "Gato Cupcake",
        "Formiga",
        "KKKKKKKK",
        "Sherek Feiosa",
        "Frango",
        "Pinguin",
        "rato",
        "Minions",
        "Dinossauro",
        "Ovni",
        "Passaro Gordo",
        "Balao Cachorro",
        "Urso Pelucia",
        "Minecraft",
        "Fofuxo",
        "Sapo",
        "Bruxo",
        "Rato Grande",
        "Burro",
        "Nemo",
        "Careca desenho KKKKK",
        "Pinguin Mini",
        "Mini Sherek",
        "Coruja",
        "Gato de Manga",
        "Tung Saur", 
        "Tralaleiro",
        "Monstro S.A",
        "Trenzinho",
        "Dino",
        "Pou idoso",
        "Coco/boxt@",
        "Coelho",
        "Hipopótamo",
        "Ratatui",
        "Galinha",
        "Pepa pig",
        "Pinguin",
        "Sid",
        "Puga grande",
        "SHREK AMALDIÇOADO",
        "Mosquito grande",
        "Noob Invertido",
        "Pato(a)",
        "Cachorro Chihuahua",
        "Gato sla",
        "Gato fei",
        "Inpostor",
        "Simon amarelo",
        "Simon azul"
    },
    Callback = function(selected)
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local StarterGui = game:GetService("StarterGui")
        
        local avatars = {
            -- Novos avatares da lista fornecida
            ["La Vaca Saturno"] = 92598055945546,
            ["brainrot"] = 71509988068185,
            ["Galo"] = 134279966389194,
            ["Capivara"] = 123881270149502,
            ["Tigre"] = 119471161887334,
            ["Capivara"] = 70941023284215,
            ["Peixe"] = 100767254038825,
            ["Pepino Doidao"] = 140311949273388,
            ["Gato"] = 18863879460,
            ["Rato"] = 94426045122131,
            ["Sei la KKKKOKK"] = 130540554592449,
            ["Pato Banana"] = 101283140862013,
            ["Fantasma"] = 15294031319,
            ["Gato Lasanha"] = 80036937359835,
            ["Arvore"] = 91559013873343,
            ["Gato Cupcake"] = 134590778152934,
            ["Formiga"] = 117567910327875,
            ["KKKKKKKK"] = 126610774641341,
            ["Sherek Feiosa"] = 93929184789448,
            ["Frango"] = 12151793832,
            ["Pinguin"] = 94944293759578,
            ["rato"] = 115152504142706,
            ["Minions"] = 80206221835435,
            ["Dinossauro"] = 78418661102501,
            ["Ovni"] = 108699752030063,
            ["Passaro Gordo"] = 17850619237,
            ["Balao Cachorro"] = 87116547256834,
            ["Urso Pelucia"] = 130455255821318,
            ["Minecraft"] = 18161752527,
            ["Fofuxo"] = 13354344881,
            ["Sapo"] = 108623435649969,
            ["Bruxo"] = 18459833677,
            ["Rato Grande"] = 18843948073,
            ["Burro"] = 133145533787450,
            ["Nemo"] = 91530170242128,
            ["Careca desenho KKKKK"] = 114218821771642,
            ["Pinguin Mini"] = 140417314445581,
            ["Mini Sherek"] = 121680981245369,
            ["Coruja"] = 16259522726,
            -- Avatares originais
            ["Gato de Manga"] = 124948425515124,
            ["Tung Saur"] = 117098257036480,
            ["Tralaleiro"] = 99459753608381,
            ["Monstro S.A"] = 123609977175226,
            ["Trenzinho"] = 80468697076178,
            ["Dino"] = 11941741105,
            ["Pou idoso"] = 15742966010,
            ["Coco/boxt@"] = 77013984520332,
            ["Coelho"] = 71797333686800,
            ["Hipopótamo"] = 73215892129281,
            ["Ratatui"] = 108557570415453,
            ["Galinha"] = 71251793812515,
            ["Pepa pig"] = 92979204778377,
            ["Sid"] = 87442757321244,
            ["Puga grande"] = 111436158728716,
            ["SHREK AMALDIÇOADO"] = 120960401202173,
            ["Mosquito grande"] = 108052868536435,
            ["Noob Invertido"] = 106596990206151,
            ["Pato(a)"] = 135132836238349,
            ["Cachorro Chihuahua"] = 18656467256,
            ["Gato sla"] = 18994959003,
            ["Gato fei"] = 77506186615650,
            ["Inpostor"] = 18234669337,
            ["Simon amarelo"] = 75183593514657,
            ["Simon azul"] = 76155710249925
        }
        
        if avatars[selected] then
            pcall(function()
                local args = {avatars[selected]}
                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Wear"):InvokeServer(unpack(args))
                StarterGui:SetCore("SendNotification", {
                    Title = "Avatar",
                    Text = "Avatar " .. selected .. " equipado!",
                    Duration = 3
                })
            end)
        end
    end
})

Tab:AddSection({"Avatar Editor"})

Tab:AddParagraph({
    Title = "Aviso: Vai resetar seu avatar",
    Content = "Os avatares abaixo irão substituir completamente seu personagem atual."
})

Tab:AddButton({
    Name = "Mini REPO",
    Description = "Avatar mini personalizado",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local StarterGui = game:GetService("StarterGui")
        
        pcall(function()
            local parts = {
                117101023704825,
                125767940563838,
                137301494386930,
                87357384184710,
                133391239416999,
                111818794467824
            }
            local args = {parts}
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
            StarterGui:SetCore("SendNotification", {
                Title = "Avatar",
                Text = "Mini REPO equipado!",
                Duration = 3
            })
        end)
    end
})

Tab:AddButton({
    Name = "Mini Garanhão",
    Description = "Avatar mini garanhão",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local StarterGui = game:GetService("StarterGui")
        
        pcall(function()
            local parts = {
                124355047456535,
                120507500641962,
                82273782655463,
                113625313757230,
                109182039511426,
                0
            }
            local args = {parts}
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
            StarterGui:SetCore("SendNotification", {
                Title = "Avatar",
                Text = "Mini Garanhão equipado!",
                Duration = 3
            })
        end)
    end
})

Tab:AddButton({
    Name = "Stick",
    Description = "Avatar estilo palito",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local StarterGui = game:GetService("StarterGui")
        
        pcall(function()
            local parts = {
                14731384498,
                14731377938,
                14731377894,
                14731377875,
                14731377941,
                14731382899
            }
            local args = {parts}
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
            StarterGui:SetCore("SendNotification", {
                Title = "Avatar",
                Text = "Stick equipado!",
                Duration = 3
            })
        end)
    end
})

Tab:AddButton({
    Name = "Chunky-Bug",
    Description = "Avatar estilo bug",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local StarterGui = game:GetService("StarterGui")
        
        pcall(function()
            local parts = {
                15527827600,
                15527827578,
                15527831669,
                15527836067,
                15527827184,
                15527827599
            }
            local args = {parts}
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
            StarterGui:SetCore("SendNotification", {
                Title = "Avatar",
                Text = "Chunky-Bug equipado!",
                Duration = 3
            })
        end)
    end
})

Tab:AddButton({
    Name = "Cursed-Spider",
    Description = "Avatar aranha amaldiçoada",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local StarterGui = game:GetService("StarterGui")
        
        pcall(function()
            local parts = {
                134555168634906,
                100269043793774,
                125607053187319,
                122504853343598,
                95907982259204,
                91289185840375
            }
            local args = {parts}
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
            StarterGui:SetCore("SendNotification", {
                Title = "Avatar",
                Text = "Cursed-Spider equipado!",
                Duration = 3
            })
        end)
    end
})

Tab:AddButton({
    Name = "Possessed-Horror",
    Description = "Avatar horror possuído",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local StarterGui = game:GetService("StarterGui")
        
        pcall(function()
            local parts = {
                122800511983371,
                132465361516275,
                125155800236527,
                83070163355072,
                102906187256945,
                78311422507297
            }
            local args = {parts}
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
            StarterGui:SetCore("SendNotification", {
                Title = "Avatar",
                Text = "Possessed-Horror equipado!",
                Duration = 3
            })
        end)
    end
})

local scriptsTab = Window:MakeTab({"Scripts", "rbxassetid://130521044774541"})

scriptsTab:AddSection({ "Black Hole" })

scriptsTab:AddButton({
    Name = "Black Hole",
    Description = "",
    Callback = function()
        local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local angle = 1
local radius = 10
local blackHoleActive = false

local function setupPlayer()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local Folder = Instance.new("Folder", Workspace)
    local Part = Instance.new("Part", Folder)
    local Attachment1 = Instance.new("Attachment", Part)
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 1

    return humanoidRootPart, Attachment1
end

local humanoidRootPart, Attachment1 = setupPlayer()

if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
    }

    Network.RetainPart = function(part)
        if typeof(part) == "Instance" and part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
            table.insert(Network.BaseParts, part)
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            part.CanCollide = false
        end
    end

    local function EnablePartControl()
        LocalPlayer.ReplicationFocus = Workspace
        RunService.Heartbeat:Connect(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            for _, part in pairs(Network.BaseParts) do
                if part:IsDescendantOf(Workspace) then
                    part.Velocity = Network.Velocity
                end
            end
        end)
    end

    EnablePartControl()
end

local function ForcePart(v)
    if v:IsA("Part") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
        for _, x in next, v:GetChildren() do
            if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end
        if v:FindFirstChild("Attachment") then
            v:FindFirstChild("Attachment"):Destroy()
        end
        if v:FindFirstChild("AlignPosition") then
            v:FindFirstChild("AlignPosition"):Destroy()
        end
        if v:FindFirstChild("Torque") then
            v:FindFirstChild("Torque"):Destroy()
        end
        v.CanCollide = false
        
        local Torque = Instance.new("Torque", v)
        Torque.Torque = Vector3.new(1000000, 1000000, 1000000)
        local AlignPosition = Instance.new("AlignPosition", v)
        local Attachment2 = Instance.new("Attachment", v)
        Torque.Attachment0 = Attachment2
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = 500
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = Attachment1
    end
end

local function toggleBlackHole()
    blackHoleActive = not blackHoleActive
    if blackHoleActive then
        for _, v in next, Workspace:GetDescendants() do
            ForcePart(v)
        end

        Workspace.DescendantAdded:Connect(function(v)
            if blackHoleActive then
                ForcePart(v)
            end
        end)

        spawn(function()
            while blackHoleActive and RunService.RenderStepped:Wait() do
                angle = angle + math.rad(2)

                local offsetX = math.cos(angle) * radius
                local offsetZ = math.sin(angle) * radius

                Attachment1.WorldCFrame = humanoidRootPart.CFrame * CFrame.new(offsetX, 0, offsetZ)
            end
        end)
    else
        Attachment1.WorldCFrame = CFrame.new(0, -1000, 0)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    humanoidRootPart, Attachment1 = setupPlayer()
    if blackHoleActive then
        toggleBlackHole()
    end
end)

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/miroeramaa/TurtleLib/main/TurtleUiLib.lua"))()
local window = library:Window("Projeto LKB")

window:Slider("Radius Blackhole",1,100,10, function(Value)
   radius = Value
end)

window:Toggle("Blackhole", true, function(Value)
       if Value then
            toggleBlackHole()
        else
            blackHoleActive = false
        end
end)

spawn(function()
    while true do
        RunService.RenderStepped:Wait()
        if blackHoleActive then
            angle = angle + math.rad(angleSpeed)
        end
    end
end)

toggleBlackHole()
    end
})

scriptsTab:AddButton({
    Name = "Puxar Parts Player",
    Description = "",
    Callback = function()
        -- Gui to Lua
-- Version: 3.2

-- Instances:

local Gui = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local Box = Instance.new("TextBox")
local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
local Label = Instance.new("TextLabel")
local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
local Button = Instance.new("TextButton")
local UITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")

--Properties:

Gui.Name = "Gui"
Gui.Parent = gethui()
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = Gui
Main.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.335954279, 0, 0.542361975, 0)
Main.Size = UDim2.new(0.240350261, 0, 0.166880623, 0)
Main.Active = true
Main.Draggable = true

Box.Name = "Box"
Box.Parent = Main
Box.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
Box.BorderSizePixel = 0
Box.Position = UDim2.new(0.0980926454, 0, 0.218712583, 0)
Box.Size = UDim2.new(0.801089942, 0, 0.364963502, 0)
Box.FontFace = Font.new("rbxasset://fonts/families/SourceSansSemibold.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Box.PlaceholderText = "Player here"
Box.Text = ""
Box.TextColor3 = Color3.fromRGB(255, 255, 255)
Box.TextScaled = true
Box.TextSize = 31.000
Box.TextWrapped = true

UITextSizeConstraint.Parent = Box
UITextSizeConstraint.MaxTextSize = 31

Label.Name = "Label"
Label.Parent = Main
Label.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
Label.BorderSizePixel = 0
Label.Size = UDim2.new(1, 0, 0.160583943, 0)
Label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Label.Text = "Bring Parts"
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.TextScaled = true
Label.TextSize = 14.000
Label.TextWrapped = true

UITextSizeConstraint_2.Parent = Label
UITextSizeConstraint_2.MaxTextSize = 21

Button.Name = "Button"
Button.Parent = Main
Button.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
Button.BorderSizePixel = 0
Button.Position = UDim2.new(0.183284417, 0, 0.656760991, 0)
Button.Size = UDim2.new(0.629427791, 0, 0.277372271, 0)
Button.Font = Enum.Font.Nunito
Button.Text = "Bring | Off"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextScaled = true
Button.TextSize = 28.000
Button.TextWrapped = true

UITextSizeConstraint_3.Parent = Button
UITextSizeConstraint_3.MaxTextSize = 28

-- Scripts:

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local character
local humanoidRootPart

mainStatus = true
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.RightControl and not gameProcessedEvent then
		mainStatus = not mainStatus
		Main.Visible = mainStatus
	end
end)

local Folder = Instance.new("Folder", Workspace)
local Part = Instance.new("Part", Folder)
local Attachment1 = Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

if not getgenv().Network then
	getgenv().Network = {
		BaseParts = {},
		Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
	}

	Network.RetainPart = function(Part)
		if Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
			table.insert(Network.BaseParts, Part)
			Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
			Part.CanCollide = false
		end
	end

	local function EnablePartControl()
		LocalPlayer.ReplicationFocus = Workspace
		RunService.Heartbeat:Connect(function()
			sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
			for _, Part in pairs(Network.BaseParts) do
				if Part:IsDescendantOf(Workspace) then
					Part.Velocity = Network.Velocity
				end
			end
		end)
	end

	EnablePartControl()
end

local function ForcePart(v)
	if v:IsA("BasePart") and not v.Anchored and not v.Parent:FindFirstChildOfClass("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
		for _, x in ipairs(v:GetChildren()) do
			if x:IsA("BodyMover") or x:IsA("RocketPropulsion") then
				x:Destroy()
			end
		end
		if v:FindFirstChild("Attachment") then
			v:FindFirstChild("Attachment"):Destroy()
		end
		if v:FindFirstChild("AlignPosition") then
			v:FindFirstChild("AlignPosition"):Destroy()
		end
		if v:FindFirstChild("Torque") then
			v:FindFirstChild("Torque"):Destroy()
		end
		v.CanCollide = false
		local Torque = Instance.new("Torque", v)
		Torque.Torque = Vector3.new(100000, 100000, 100000)
		local AlignPosition = Instance.new("AlignPosition", v)
		local Attachment2 = Instance.new("Attachment", v)
		Torque.Attachment0 = Attachment2
		AlignPosition.MaxForce = math.huge
		AlignPosition.MaxVelocity = math.huge
		AlignPosition.Responsiveness = 200
		AlignPosition.Attachment0 = Attachment2
		AlignPosition.Attachment1 = Attachment1
	end
end

local blackHoleActive = false
local DescendantAddedConnection

local function toggleBlackHole()
	blackHoleActive = not blackHoleActive
	if blackHoleActive then
		Button.Text = "Bring Parts | On"
		for _, v in ipairs(Workspace:GetDescendants()) do
			ForcePart(v)
		end

		DescendantAddedConnection = Workspace.DescendantAdded:Connect(function(v)
			if blackHoleActive then
				ForcePart(v)
			end
		end)

		spawn(function()
			while blackHoleActive and RunService.RenderStepped:Wait() do
				Attachment1.WorldCFrame = humanoidRootPart.CFrame
			end
		end)
	else
		Button.Text = "Bring Parts | Off"
		if DescendantAddedConnection then
			DescendantAddedConnection:Disconnect()
		end
	end
end

local function getPlayer(name)
	local lowerName = string.lower(name)
	for _, p in pairs(Players:GetPlayers()) do
		local lowerPlayer = string.lower(p.Name)
		if string.find(lowerPlayer, lowerName) then
			return p
		elseif string.find(string.lower(p.DisplayName), lowerName) then
			return p
		end
	end
end

local player = nil

local function VDOYZQL_fake_script() -- Box.Script 
	local script = Instance.new('Script', Box)

	script.Parent.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			player = getPlayer(Box.Text)
			if player then
				Box.Text = player.Name
				print("Player found:", player.Name)
			else
				print("Player not found")
			end
		end
	end)
end
coroutine.wrap(VDOYZQL_fake_script)()
local function JUBNQKI_fake_script() -- Button.Script 
	local script = Instance.new('Script', Button)

	script.Parent.MouseButton1Click:Connect(function()
		if player then
			character = player.Character or player.CharacterAdded:Wait()
			humanoidRootPart = character:WaitForChild("HumanoidRootPart")
			toggleBlackHole()
		else
			print("Player is not selected")
		end
	end)
end
coroutine.wrap(JUBNQKI_fake_script)()
    end
})

scriptsTab:AddSection({ "Glue & Invisível" })

scriptsTab:AddButton({
    Name = "FE Invisível",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Fica-invis-vel-kkj/refs/heads/main/Kkj"))()
    end
})

scriptsTab:AddButton({
    Name = "Glue",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Glue/refs/heads/main/Main%20(5)%20(2).txt"))()
    end
})

scriptsTab:AddSection({ "Emotes" })

scriptsTab:AddButton({
    Name = "Emotes",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Shad0ws-emotes/refs/heads/main/emotes%20Shadows"))()
    end
})

-- Variáveis globais para controlar os scripts
cancelExpansion = false
expansionSound = nil
expansionModel = nil
originalSky = nil

scriptsTab:AddSection({ "Mapa" })
scriptsTab:AddButton({
    Name = "Expansão Domínio",
    Description = "",
    Callback = function()
-- Serviços
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- Reset da variável de cancelamento
cancelExpansion = false

-- Aviso no chat (com \r conforme seu pedido)
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then 
    TextChatService.TextChannels.RBXGeneral:SendAsync(
        "hi\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\rServer: Expansão de Domínio [REDZ HUB ATTACK]"
    )
else 
    print("gojo chorou no banho F")
end

-- Função para ativar Expansão de Domínio
local function ativarDominio()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local dominio = Instance.new("Model", workspace)
    dominio.Name = "InfiniteVoid"
    expansionModel = dominio

    local esfera = Instance.new("Part")
    esfera.Shape = Enum.PartType.Ball
    esfera.Size = Vector3.new(300, 300, 300)
    esfera.Position = hrp.Position
    esfera.Anchored = true
    esfera.CanCollide = false
    esfera.Material = Enum.Material.ForceField
    esfera.Transparency = 0.3
    esfera.Color = Color3.fromRGB(0, 0, 0)
    esfera.Parent = dominio

    local luz = Instance.new("PointLight", esfera)
    luz.Color = Color3.fromRGB(0, 153, 255)
    luz.Brightness = 10
    luz.Range = 300

    local ps = Instance.new("ParticleEmitter", esfera)
    ps.Texture = "rbxassetid://243660364"
    ps.Color = ColorSequence.new(Color3.fromRGB(0, 153, 255))
    ps.LightEmission = 1
    ps.Size = NumberSequence.new(3)
    ps.Transparency = NumberSequence.new(0.2)
    ps.Rate = 1000
    ps.Lifetime = NumberRange.new(2)
    ps.Speed = NumberRange.new(0)
    ps.VelocitySpread = 180

    local som = Instance.new("Sound", esfera)
    som.SoundId = "rbxassetid://1843527678"
    som.Volume = 2
    som.Looped = true
    som:Play()
    expansionSound = som

    originalSky = Lighting:FindFirstChildOfClass("Sky")
    if originalSky then
        originalSky.Parent = nil
    end

    local newSky = Instance.new("Sky", Lighting)
    newSky.SkyboxBk = "rbxassetid://159454299"
    newSky.SkyboxDn = "rbxassetid://159454296"
    newSky.SkyboxFt = "rbxassetid://159454293"
    newSky.SkyboxLf = "rbxassetid://159454286"
    newSky.SkyboxRt = "rbxassetid://159454300"
    newSky.SkyboxUp = "rbxassetid://159454288"
end

-- Executa a expansão de domínio
ativarDominio()

-- Áudio em loop infinito no jogador
local selectedAudioID = 140031333626044

task.spawn(function()
    while not cancelExpansion do
        local remote = ReplicatedStorage:FindFirstChild("RE") and ReplicatedStorage.RE:FindFirstChild("1Gu1nSound1s")
        if remote then
            remote:FireServer(workspace, selectedAudioID, 1)
        end

        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://" .. selectedAudioID
            sound.Volume = 1
            sound.Looped = false
            sound.Parent = root
            sound:Play()
            sound.Ended:Connect(function() sound:Destroy() end)
            task.wait(sound.TimeLength + 0.1)
        else
            warn("HumanoidRootPart não encontrado")
            break
        end
    end
end)

-- ========================
-- ATAQUE COM ARMA: Assault
-- ========================

local RE = ReplicatedStorage:WaitForChild("RE")
local ClearEvent = RE:FindFirstChild("1Clea1rTool1s")
local ToolEvent = RE:FindFirstChild("1Too1l")
local FireEvent = RE:FindFirstChild("1Gu1n")

-- Limpa ferramentas
local function clearAllTools()
    if ClearEvent then
        ClearEvent:FireServer("ClearAllTools")
    end
end

-- Solicita Assault
local function getAssault()
    if ToolEvent then
        ToolEvent:InvokeServer("PickingTools", "Assault")
    end
end

-- Verifica se recebeu Assault
local function hasAssault()
    return Player.Backpack:FindFirstChild("Assault") ~= nil
end

-- Atira em parte
local function fireAtPart(targetPart)
    local gunScript = Player.Backpack:FindFirstChild("Assault")
        and Player.Backpack.Assault:FindFirstChild("GunScript_Local")

    if not gunScript or not targetPart then return end

    local args = {
        targetPart,
        targetPart,
        Vector3.new(1e14, 1e14, 1e14),
        targetPart.Position,
        gunScript:FindFirstChild("MuzzleEffect"),
        gunScript:FindFirstChild("HitEffect"),
        0,
        0,
        { false },
        {
            25,
            Vector3.new(100, 100, 100),
            BrickColor.new(29),
            0.25,
            Enum.Material.SmoothPlastic,
            0.25
        },
        true,
        false
    }

    FireEvent:FireServer(unpack(args))
end

-- Atira em todos os jogadores
local function fireAtAllPlayers(times)
    for i = 1, times do
        if cancelExpansion then break end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                fireAtPart(player.Character.HumanoidRootPart)
                task.wait(0.1)
            end
        end
    end
end

-- Loop automático de ataque
task.spawn(function()
    while not cancelExpansion do
        clearAllTools()
        getAssault()

        repeat
            task.wait(0.2)
        until hasAssault() or cancelExpansion

        if not cancelExpansion then
            fireAtAllPlayers(3)
            task.wait(1)
        end
    end
end)
end
})

scriptsTab:AddButton({
    Name = "Parar Expansão de Domínio",
    Description = "",
    Callback = function()
        -- Sinaliza para parar loops
        cancelExpansion = true

        -- Para o som em loop
        if expansionSound then
            expansionSound:Stop()
            expansionSound:Destroy()
            expansionSound = nil
        end

        -- Remove o modelo "InfiniteVoid" criado
        if expansionModel and expansionModel.Parent then
            expansionModel:Destroy()
            expansionModel = nil
        end

        -- Restaura o Sky original
        local Lighting = game:GetService("Lighting")
        local currentSky = Lighting:FindFirstChildOfClass("Sky")
        if currentSky then currentSky:Destroy() end

        if originalSky then
            originalSky.Parent = Lighting
            originalSky = nil
        end

        -- Mensagem no chat confirmando cancelamento
        local TextChatService = game:GetService("TextChatService")
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.TextChannels.RBXGeneral:SendAsync("[Expansão de Domínio cancelada]")
        else
            print("Parado com sucesso!")
        end
    end
})

-- Variáveis globais para controlar os scripts
cancelExpansion = false
expansionSound = nil
expansionModel = nil
originalSky = nil
originalLighting = {}
createdSky = nil

scriptsTab:AddSection({ "Goner Expansion - by Shadows" })
scriptsTab:AddButton({
    Name = "Goner Expansion",
    Description = "",
    Callback = function()
-- Serviços
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- Reset da variável de cancelamento
cancelExpansion = false

-- Salva configurações originais do Lighting
originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GeographicLatitude = Lighting.GeographicLatitude,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient,
    FogColor = Lighting.FogColor,
    FogEnd = Lighting.FogEnd
}

-- Aviso no chat
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then 
    TextChatService.TextChannels.RBXGeneral:SendAsync(
        "hi\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\rServer: Goner Expansion [REDZ ATTACK]"
    )
else 
    print("gojo chorou no banho F")
end

-- Função para ativar Expansão de Domínio (VERSÃO VERMELHA)
local function ativarDominio()
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local dominio = Instance.new("Model", workspace)
    dominio.Name = "InfiniteVoid"
    expansionModel = dominio

    -- Esfera VERMELHA
    local esfera = Instance.new("Part")
    esfera.Shape = Enum.PartType.Ball
    esfera.Size = Vector3.new(300, 300, 300)
    esfera.Position = hrp.Position
    esfera.Anchored = true
    esfera.CanCollide = false
    esfera.Material = Enum.Material.ForceField
    esfera.Transparency = 0.3
    esfera.Color = Color3.fromRGB(150, 0, 0)  -- Vermelho escuro
    esfera.Parent = dominio

    -- Luz VERMELHA
    local luz = Instance.new("PointLight", esfera)
    luz.Color = Color3.fromRGB(255, 0, 0)  -- Vermelho intenso
    luz.Brightness = 10
    luz.Range = 300

    -- Partículas VERMELHAS
    local ps = Instance.new("ParticleEmitter", esfera)
    ps.Texture = "rbxassetid://243660364"
    ps.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))  -- Vermelho
    ps.LightEmission = 1
    ps.Size = NumberSequence.new(3)
    ps.Transparency = NumberSequence.new(0.2)
    ps.Rate = 1000
    ps.Lifetime = NumberRange.new(2)
    ps.Speed = NumberRange.new(0)
    ps.VelocitySpread = 180

    -- SOM PRINCIPAL (ID 5813114232)
    local som = Instance.new("Sound", esfera)
    som.SoundId = "rbxassetid://5813114232"
    som.Volume = 2
    som.Looped = true
    som:Play()
    expansionSound = som

    -- Salva Sky original
    originalSky = Lighting:FindFirstChildOfClass("Sky")
    if originalSky then
        originalSky.Parent = nil
    end

    -- Remove Atmosphere existente
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            obj:Destroy()
        end
    end

    -- SKYBOX VERMELHO COM IMAGEM 6300792626 (PROTEGIDO)
    local newSky = Instance.new("Sky")
    local skyTextureId = "rbxassetid://6300792626"
    newSky.Name = "GonerSkybox"
    newSky.SkyboxBk = skyTextureId
    newSky.SkyboxDn = skyTextureId
    newSky.SkyboxFt = skyTextureId
    newSky.SkyboxLf = skyTextureId
    newSky.SkyboxRt = skyTextureId
    newSky.SkyboxUp = skyTextureId
    newSky.Parent = Lighting
    createdSky = newSky

    -- Sistema de proteção do skybox
    task.spawn(function()
        while not cancelExpansion do
            if not createdSky or createdSky.Parent ~= Lighting then
                -- Recria o skybox se for removido
                local recreatedSky = Instance.new("Sky")
                recreatedSky.Name = "GonerSkybox"
                recreatedSky.SkyboxBk = skyTextureId
                recreatedSky.SkyboxDn = skyTextureId
                recreatedSky.SkyboxFt = skyTextureId
                recreatedSky.SkyboxLf = skyTextureId
                recreatedSky.SkyboxRt = skyTextureId
                recreatedSky.SkyboxUp = skyTextureId
                recreatedSky.Parent = Lighting
                createdSky = recreatedSky
            end
            task.wait(0.1)
        end
    end)

    -- Efeitos de iluminação VERMELHA INTENSA
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.GeographicLatitude = 0
    Lighting.OutdoorAmbient = Color3.fromRGB(200, 0, 0)  -- Vermelho
    Lighting.Ambient = Color3.fromRGB(255, 0, 0)  -- Vermelho intenso
    Lighting.FogColor = Color3.fromRGB(150, 0, 0)  -- Neblina vermelha
    Lighting.FogEnd = 500  -- Neblina próxima

    print(" Skybox Goner aplicado com imagem 6300792626")
end

-- Executa a expansão de domínio
ativarDominio()

-- ========================
-- SISTEMA DE ÁUDIO COMPLETO (ID 5813114232)
-- ========================
local selectedAudioID = 5813114232

-- Áudio via RemoteEvent
task.spawn(function()
    while not cancelExpansion do
        local remote = ReplicatedStorage:FindFirstChild("RE") and ReplicatedStorage.RE:FindFirstChild("1Gu1nSound1s")
        if remote then
            pcall(function()
                remote:FireServer(workspace, selectedAudioID, 1)
            end)
        end
        task.wait(1)
    end
end)

-- Áudio local no jogador
task.spawn(function()
    while not cancelExpansion do
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://" .. selectedAudioID
            sound.Volume = 1
            sound.Looped = false
            sound.Parent = root
            sound:Play()
            sound.Ended:Connect(function() sound:Destroy() end)
            task.wait(sound.TimeLength + 0.1)
        else
            task.wait(1)
        end
    end
end)

-- Áudio adicional no workspace
task.spawn(function()
    while not cancelExpansion do
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. selectedAudioID
        sound.Volume = 1.5
        sound.Looped = false
        sound.Parent = workspace
        sound:Play()
        game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
        task.wait(sound.TimeLength + 0.5)
    end
end)

-- ========================
-- ATAQUE COM ARMA: Assault
-- ========================

local RE = ReplicatedStorage:WaitForChild("RE")
local ClearEvent = RE:FindFirstChild("1Clea1rTool1s")
local ToolEvent = RE:FindFirstChild("1Too1l")
local FireEvent = RE:FindFirstChild("1Gu1n")

-- Limpa ferramentas
local function clearAllTools()
    if ClearEvent then
        pcall(function()
            ClearEvent:FireServer("ClearAllTools")
        end)
    end
end

-- Solicita Assault
local function getAssault()
    if ToolEvent then
        pcall(function()
            ToolEvent:InvokeServer("PickingTools", "Assault")
        end)
    end
end

-- Verifica se recebeu Assault
local function hasAssault()
    return Player.Backpack:FindFirstChild("Assault") ~= nil
end

-- Atira em parte
local function fireAtPart(targetPart)
    local gunScript = Player.Backpack:FindFirstChild("Assault")
        and Player.Backpack.Assault:FindFirstChild("GunScript_Local")

    if not gunScript or not targetPart then return end

    local args = {
        targetPart,
        targetPart,
        Vector3.new(1e14, 1e14, 1e14),
        targetPart.Position,
        gunScript:FindFirstChild("MuzzleEffect"),
        gunScript:FindFirstChild("HitEffect"),
        0,
        0,
        { false },
        {
            25,
            Vector3.new(100, 100, 100),
            BrickColor.new(29),
            0.25,
            Enum.Material.SmoothPlastic,
            0.25
        },
        true,
        false
    }

    pcall(function()
        FireEvent:FireServer(unpack(args))
    end)
end

-- Atira em todos os jogadores
local function fireAtAllPlayers(times)
    for i = 1, times do
        if cancelExpansion then break end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                fireAtPart(player.Character.HumanoidRootPart)
                task.wait(0.1)
            end
        end
    end
end

-- Loop automático de ataque
task.spawn(function()
    while not cancelExpansion do
        clearAllTools()
        getAssault()

        repeat
            task.wait(0.2)
        until hasAssault() or cancelExpansion

        if not cancelExpansion then
            fireAtAllPlayers(3)
            task.wait(1)
        end
    end
end)
end
})

scriptsTab:AddButton({
    Name = "Para Ataque Goner",
    Description = "",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        local TextChatService = game:GetService("TextChatService")
        
        -- Sinaliza para parar loops
        cancelExpansion = true

        task.wait(0.5)  -- Aguarda loops finalizarem

        -- Para e remove TODOS os sons
        if expansionSound then
            expansionSound:Stop()
            expansionSound:Destroy()
            expansionSound = nil
        end

        -- Remove todos os sons do workspace
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Sound") and obj.SoundId == "rbxassetid://5813114232" then
                obj:Stop()
                obj:Destroy()
            end
        end

        -- Remove sons do personagem
        local Players = game:GetService("Players")
        local Player = Players.LocalPlayer
        if Player.Character then
            for _, obj in ipairs(Player.Character:GetDescendants()) do
                if obj:IsA("Sound") and obj.SoundId == "rbxassetid://5813114232" then
                    obj:Stop()
                    obj:Destroy()
                end
            end
        end

        -- Remove o modelo "InfiniteVoid" criado (ESFERA VERMELHA)
        if expansionModel and expansionModel.Parent then
            expansionModel:Destroy()
            expansionModel = nil
        end

        -- Remove qualquer modelo InfiniteVoid restante
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "InfiniteVoid" then
                obj:Destroy()
            end
        end

        -- Remove o skybox criado
        if createdSky and createdSky.Parent then
            createdSky:Destroy()
            createdSky = nil
        end
        
        -- Remove qualquer skybox com nome GonerSkybox
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") and obj.Name == "GonerSkybox" then
                obj:Destroy()
            end
        end

        -- Restaura o Sky original
        if originalSky then
            originalSky.Parent = Lighting
            originalSky = nil
        end

        -- Restaura configurações originais do Lighting (REMOVE EFEITOS VERMELHOS)
        if originalLighting.Brightness then
            Lighting.Brightness = originalLighting.Brightness
            Lighting.ClockTime = originalLighting.ClockTime
            Lighting.GeographicLatitude = originalLighting.GeographicLatitude
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            Lighting.Ambient = originalLighting.Ambient
            Lighting.FogColor = originalLighting.FogColor
            Lighting.FogEnd = originalLighting.FogEnd
        else
            -- Se não houver backup, restaura valores padrão
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GeographicLatitude = 41.733
            Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
            Lighting.Ambient = Color3.fromRGB(127, 127, 127)
            Lighting.FogColor = Color3.fromRGB(191, 191, 191)
            Lighting.FogEnd = 100000
        end

        -- Limpa a tabela de backup
        originalLighting = {}

        -- Mensagem no chat confirmando cancelamento
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.TextChannels.RBXGeneral:SendAsync("Goner Expansion Parado")
        else
            print("Goner Expansion Parado")
        end
        
        print(" Esfera vermelha removida")
        print(" Skybox restaurado")
        print(" Iluminação vermelha removida")
        print(" Sons parados")
    end
})

scriptsTab:AddSection({ "Desastres naturais" })
scriptsTab:AddButton({
    Name = "Tornado Com Navio Grande",
    Description = "",
    Callback = function()
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Vehicles = workspace:WaitForChild("Vehicles")

-- Aviso no chat
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then 
    TextChatService.TextChannels.RBXGeneral:SendAsync(
        "hi\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r[REDZ HUB ATTACK!]"
    )
else 
    print("Nadaa")
end

-- Função para tocar o áudio 5 vezes
local selectedAudioID = 9068077052
local function playAudio()
    if not selectedAudioID then
        warn("Nenhum áudio selecionado!")
        return
    end

    local args = {
        [1] = workspace,
        [2] = selectedAudioID,
        [3] = 1,
    }

    for i = 1, 5 do
        RS.RE:FindFirstChild("1Gu1nSound1s"):FireServer(unpack(args))

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. tostring(selectedAudioID)
        sound.Parent = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if sound.Parent then
            sound:Play()
        else
            warn("HumanoidRootPart não encontrado")
            break
        end

        task.wait(1.5)
        sound:Destroy()
    end
end

-- Spawn do barco
local function spawnBoat()
    RootPart.CFrame = CFrame.new(1754, -2, 58)
    task.wait(0.5)
    RS:WaitForChild("RE"):FindFirstChild("1Ca1r"):FireServer("PickingBoat", "PirateFree")
    task.wait(1)
    return Vehicles:FindFirstChild(Player.Name .. "Car")
end

local PCar = spawnBoat()
if not PCar then
    warn("Falha ao spawnar o barco")
    return
end

print("Barco PirateFree gerado!")

local Seat = PCar:FindFirstChild("Body") and PCar.Body:FindFirstChild("VehicleSeat")
if not Seat then
    warn("Seat não encontrado")
    return
end

-- Sentar no assento
repeat
    task.wait(0.1)
    RootPart.CFrame = Seat.CFrame * CFrame.new(0, 1, 0)
until Humanoid.SeatPart == Seat

print("Jogador sentado com sucesso!")

-- Tocar áudio em paralelo
task.spawn(playAudio)

-- Ejetar após 4 segundos
task.delay(4, function()
    if Humanoid.SeatPart then
        Humanoid.Sit = false
    end
    RootPart.CFrame = CFrame.new(0, 0, 0)
    print("Jogador ejetado e teleportado")
end)

-- Flip loop paralelo
local RE_Flip = RS:WaitForChild("RE"):WaitForChild("1Player1sCa1r")
task.spawn(function()
    while PCar and PCar.Parent do
        RE_Flip:FireServer("Flip")
        task.wait(0.5)
    end
end)

-- Configuração de movimento
local waypoints = {
    Vector3.new(-16, 0, -47),
    Vector3.new(-110, 0, -45),
    Vector3.new(16, 0, -55)
}

local currentIndex = 1
local nextIndex = 2
local moveSpeed = 15
local rotationSpeed = math.rad(720) -- 720°/s
local progress = 0
local currentRotation = 0

local function lerpCFrame(a, b, t)
    return a:lerp(b, t)
end

-- Movimento + rotação
RunService.Heartbeat:Connect(function(dt)
    if not (PCar and PCar.PrimaryPart) then return end

    local startPos = waypoints[currentIndex]
    local endPos = waypoints[nextIndex]

    progress += (moveSpeed * dt) / (startPos - endPos).Magnitude
    if progress >= 1 then
        progress = 0
        currentIndex = nextIndex
        nextIndex = (nextIndex % #waypoints) + 1
    end

    local newPos = lerpCFrame(CFrame.new(startPos), CFrame.new(endPos), progress).p
    currentRotation += rotationSpeed * dt

    local cf = CFrame.new(newPos) * CFrame.Angles(0, currentRotation, 0)
    PCar:SetPrimaryPartCFrame(cf)
end)
end
})

scriptsTab:AddButton({
    Name = "Desativar Tornado e Remover Veículo",
    Description = "",
    Callback = function()
        -- Tenta remover o veículo via RemoteEvent
        local success, err = pcall(function()
            local args = { "DeleteAllVehicles" }
            game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer(unpack(args))
        end)

        if not success then
            warn("Falha ao deletar veículos:", err)
        else
            print("[Shaodws Hub] Tornado finalizado e veículos deletados.")
        end
    end
})

scriptsTab:AddSection({ "ESP" })

-- Inicializa estrutura global ANTES de tudo
if not _G.ESPData then
    _G.ESPData = {
        espEnabled = false,
        espType = "Nome + Idade",
        selectedColor = "RGB",
        billboardGuis = {},
        highlights = {},
        lines = {},
        connections = {}
    }
end

-- Dropdown de TIPO (aparece sempre)
scriptsTab:AddDropdown({
    Name = "Tipo de ESP",
    Default = "Nome + Idade",
    Options = {"Nome + Idade", "Corpo (Highlight)", "Linhas"},
    Callback = function(espType)
        _G.ESPData.espType = espType
        
        -- Se o ESP estiver ativado, reaplica com o novo tipo
        if _G.ESPData.espEnabled then
            -- Limpa ESP anterior
            local function clearAllESP()
                for player, gui in pairs(_G.ESPData.billboardGuis) do
                    if gui then pcall(function() gui:Destroy() end) end
                end
                _G.ESPData.billboardGuis = {}
                
                for player, highlight in pairs(_G.ESPData.highlights) do
                    if highlight then pcall(function() highlight:Destroy() end) end
                end
                _G.ESPData.highlights = {}
                
                for player, line in pairs(_G.ESPData.lines) do
                    if line then pcall(function() line:Remove() end) end
                end
                _G.ESPData.lines = {}
                
                for _, conn in pairs(_G.ESPData.connections) do
                    if conn and typeof(conn) == "RBXScriptConnection" then
                        pcall(function() conn:Disconnect() end)
                    end
                end
                _G.ESPData.connections = {}
            end
            
            clearAllESP()
            -- Reaplica o ESP (a função será definida na toggle)
            if _G.applyCurrentESP then
                _G.applyCurrentESP()
            end
        end
    end
})

-- Dropdown de COR (aparece sempre)
scriptsTab:AddDropdown({
    Name = "Cor do ESP",
    Default = "RGB",
    Options = {
        "RGB", "Branco", "Preto", "Vermelho",
        "Verde", "Azul", "Amarelo", "Rosa", "Roxo"
    },
    Callback = function(colorValue)
        _G.ESPData.selectedColor = colorValue
        
        -- Função para obter cor
        local function getESPColor()
            local colors = {
                RGB = function() 
                    local h = (tick() % 5) / 5
                    return Color3.fromHSV(h, 1, 1)
                end,
                Preto = Color3.fromRGB(0, 0, 0),
                Branco = Color3.fromRGB(255, 255, 255),
                Vermelho = Color3.fromRGB(255, 0, 0),
                Verde = Color3.fromRGB(0, 255, 0),
                Azul = Color3.fromRGB(0, 170, 255),
                Amarelo = Color3.fromRGB(255, 255, 0),
                Rosa = Color3.fromRGB(255, 105, 180),
                Roxo = Color3.fromRGB(128, 0, 128)
            }
            
            local selectedColor = colors[_G.ESPData.selectedColor]
            if type(selectedColor) == "function" then
                return selectedColor()
            end
            return selectedColor or Color3.new(1, 1, 1)
        end
        
        -- Atualiza cor imediatamente se ESP estiver ativo
        for player, gui in pairs(_G.ESPData.billboardGuis) do
            if gui and gui:FindFirstChild("TextLabel") then
                gui.TextLabel.TextColor3 = getESPColor()
            end
        end
        
        for player, highlight in pairs(_G.ESPData.highlights) do
            if highlight then
                highlight.FillColor = getESPColor()
            end
        end
        
        for player, line in pairs(_G.ESPData.lines) do
            if line then
                line.Color = getESPColor()
            end
        end
    end
})

-- Toggle de ativação do ESP
scriptsTab:AddToggle({
    Name = "ESP Ativado",
    Description = "Ativa ou desativa o ESP.",
    Default = false,
    Callback = function(value)
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        
        _G.ESPData.espEnabled = value
        
        -- Limpa ESP anterior
        local function clearAllESP()
            for player, gui in pairs(_G.ESPData.billboardGuis) do
                if gui then pcall(function() gui:Destroy() end) end
            end
            _G.ESPData.billboardGuis = {}
            
            for player, highlight in pairs(_G.ESPData.highlights) do
                if highlight then pcall(function() highlight:Destroy() end) end
            end
            _G.ESPData.highlights = {}
            
            for player, line in pairs(_G.ESPData.lines) do
                if line then pcall(function() line:Remove() end) end
            end
            _G.ESPData.lines = {}
            
            for _, conn in pairs(_G.ESPData.connections) do
                if conn and typeof(conn) == "RBXScriptConnection" then
                    pcall(function() conn:Disconnect() end)
                end
            end
            _G.ESPData.connections = {}
        end

        -- Função para obter a cor
        local function getESPColor()
            local colors = {
                RGB = function() 
                    local h = (tick() % 5) / 5
                    return Color3.fromHSV(h, 1, 1)
                end,
                Preto = Color3.fromRGB(0, 0, 0),
                Branco = Color3.fromRGB(255, 255, 255),
                Vermelho = Color3.fromRGB(255, 0, 0),
                Verde = Color3.fromRGB(0, 255, 0),
                Azul = Color3.fromRGB(0, 170, 255),
                Amarelo = Color3.fromRGB(255, 255, 0),
                Rosa = Color3.fromRGB(255, 105, 180),
                Roxo = Color3.fromRGB(128, 0, 128)
            }
            
            local selectedColor = colors[_G.ESPData.selectedColor]
            if type(selectedColor) == "function" then
                return selectedColor()
            end
            return selectedColor or Color3.new(1, 1, 1)
        end

        -- ============================================
        -- FUNÇÃO PARA CRIAR ESP TIPO: NOME + IDADE
        -- ============================================
        local function createNameESP(player)
            if player == Players.LocalPlayer then return end
            if not _G.ESPData.espEnabled then return end
            if _G.ESPData.espType ~= "Nome + Idade" then return end

            local character = player.Character
            if not character then return end
            
            local head = character:FindFirstChild("Head")
            if not head then return end

            if _G.ESPData.billboardGuis[player] then
                _G.ESPData.billboardGuis[player]:Destroy()
            end

            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_Billboard"
            billboard.Parent = head
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true

            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "TextLabel"
            textLabel.Parent = billboard
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextStrokeTransparency = 0.5
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextSize = 14
            textLabel.Text = player.Name .. " | " .. player.AccountAge .. " dias"
            textLabel.TextColor3 = getESPColor()

            _G.ESPData.billboardGuis[player] = billboard
        end

        -- ============================================
        -- FUNÇÃO PARA CRIAR ESP TIPO: HIGHLIGHT
        -- ============================================
        local function createHighlightESP(player)
            if player == Players.LocalPlayer then return end
            if not _G.ESPData.espEnabled then return end
            if _G.ESPData.espType ~= "Corpo (Highlight)" then return end

            local character = player.Character
            if not character then return end

            if _G.ESPData.highlights[player] then
                _G.ESPData.highlights[player]:Destroy()
            end

            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.Parent = character
            highlight.Adornee = character
            highlight.FillColor = getESPColor()
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

            _G.ESPData.highlights[player] = highlight
        end

        -- ============================================
        -- FUNÇÃO PARA CRIAR ESP TIPO: LINHAS
        -- ============================================
        local function createLineESP(player)
            if player == Players.LocalPlayer then return end
            if not _G.ESPData.espEnabled then return end
            if _G.ESPData.espType ~= "Linhas" then return end

            if _G.ESPData.lines[player] then
                _G.ESPData.lines[player]:Remove()
            end

            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = getESPColor()
            line.Thickness = 2
            line.Transparency = 1

            _G.ESPData.lines[player] = line
        end

        -- ============================================
        -- FUNÇÃO PARA APLICAR O ESP ATUAL
        -- ============================================
        local function applyCurrentESP()
            if not _G.ESPData.espEnabled then return end

            -- Ativa para jogadores existentes
            for _, player in pairs(Players:GetPlayers()) do
                if _G.ESPData.espType == "Nome + Idade" then
                    if player.Character then
                        createNameESP(player)
                    end
                elseif _G.ESPData.espType == "Corpo (Highlight)" then
                    if player.Character then
                        createHighlightESP(player)
                    end
                elseif _G.ESPData.espType == "Linhas" then
                    createLineESP(player)
                end
            end

            -- ============================================
            -- ATUALIZAÇÃO RGB PARA NOME + IDADE
            -- ============================================
            if _G.ESPData.espType == "Nome + Idade" then
                local rgbConnection = RunService.Heartbeat:Connect(function()
                    if not _G.ESPData.espEnabled then return end
                    if _G.ESPData.espType ~= "Nome + Idade" then return end
                    if _G.ESPData.selectedColor ~= "RGB" then return end
                    
                    local newColor = getESPColor()
                    for player, gui in pairs(_G.ESPData.billboardGuis) do
                        if gui and gui:FindFirstChild("TextLabel") then
                            gui.TextLabel.TextColor3 = newColor
                        end
                    end
                end)
                table.insert(_G.ESPData.connections, rgbConnection)

            -- ============================================
            -- ATUALIZAÇÃO RGB PARA HIGHLIGHT
            -- ============================================
            elseif _G.ESPData.espType == "Corpo (Highlight)" then
                local rgbConnection = RunService.Heartbeat:Connect(function()
                    if not _G.ESPData.espEnabled then return end
                    if _G.ESPData.espType ~= "Corpo (Highlight)" then return end
                    if _G.ESPData.selectedColor ~= "RGB" then return end
                    
                    local newColor = getESPColor()
                    for player, highlight in pairs(_G.ESPData.highlights) do
                        if highlight then
                            highlight.FillColor = newColor
                        end
                    end
                end)
                table.insert(_G.ESPData.connections, rgbConnection)

            -- ============================================
            -- ATUALIZAÇÃO CONTÍNUA PARA LINHAS
            -- ============================================
            elseif _G.ESPData.espType == "Linhas" then
                local updateConnection = RunService.RenderStepped:Connect(function()
                    if not _G.ESPData.espEnabled then return end
                    if _G.ESPData.espType ~= "Linhas" then return end

                    for _, player in pairs(Players:GetPlayers()) do
                        if player == Players.LocalPlayer then continue end
                        
                        local line = _G.ESPData.lines[player]
                        if not line then continue end

                        local character = player.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            local hrp = character.HumanoidRootPart
                            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                            
                            if onScreen then
                                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                line.To = Vector2.new(pos.X, pos.Y)
                                line.Color = getESPColor()
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                end)
                table.insert(_G.ESPData.connections, updateConnection)
            end

            -- ============================================
            -- CONEXÕES PARA NOVOS JOGADORES
            -- ============================================
            local playerAdded = Players.PlayerAdded:Connect(function(player)
                if not _G.ESPData.espEnabled then return end
                
                local charAddedConn = player.CharacterAdded:Connect(function(character)
                    if not _G.ESPData.espEnabled then return end
                    character:WaitForChild("HumanoidRootPart", 5)
                    task.wait(0.1)
                    
                    if _G.ESPData.espType == "Nome + Idade" then
                        createNameESP(player)
                    elseif _G.ESPData.espType == "Corpo (Highlight)" then
                        createHighlightESP(player)
                    elseif _G.ESPData.espType == "Linhas" then
                        createLineESP(player)
                    end
                end)
                table.insert(_G.ESPData.connections, charAddedConn)
                
                if player.Character then
                    if _G.ESPData.espType == "Nome + Idade" then
                        createNameESP(player)
                    elseif _G.ESPData.espType == "Corpo (Highlight)" then
                        createHighlightESP(player)
                    elseif _G.ESPData.espType == "Linhas" then
                        createLineESP(player)
                    end
                end
            end)
            table.insert(_G.ESPData.connections, playerAdded)

            local playerRemoving = Players.PlayerRemoving:Connect(function(player)
                if _G.ESPData.billboardGuis[player] then
                    _G.ESPData.billboardGuis[player]:Destroy()
                    _G.ESPData.billboardGuis[player] = nil
                end
                if _G.ESPData.highlights[player] then
                    _G.ESPData.highlights[player]:Destroy()
                    _G.ESPData.highlights[player] = nil
                end
                if _G.ESPData.lines[player] then
                    _G.ESPData.lines[player]:Remove()
                    _G.ESPData.lines[player] = nil
                end
            end)
            table.insert(_G.ESPData.connections, playerRemoving)
        end

        -- Salva a função globalmente para ser usada pelos dropdowns
        _G.applyCurrentESP = applyCurrentESP

        -- ============================================
        -- LÓGICA PRINCIPAL DA TOGGLE
        -- ============================================
        if _G.ESPData.espEnabled then
            applyCurrentESP()
        else
            clearAllESP()
        end
    end
})

scriptsTab:AddSection({ "Save Server" })
scriptsTab:AddSection({ "Util Salva Servidores" })

scriptsTab:AddButton({
    Name = "Save Server",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Save-server/refs/heads/main/Main%20(4).txt"))()
    end
})

scriptsTab:AddSection({ "Fazer Texto Com Item" })

-- Dropdown para escolher o item
local selectedItem = "Bomb" -- Item padrão
local textToWrite = ""

scriptsTab:AddDropdown({
    Name = "Escolher Item",
    Default = "Bomb",
    Options = {"Bomb", "BabyBoy", "Box", "Laptop", "Basketball"},
    Callback = function(value)
        selectedItem = value
        print("", value)
    end
})

scriptsTab:AddTextBox({
    Name = "Digite o Texto",
    Description = "Texto que será escrito com os itens",
    PlaceholderText = "Ex: test",
    Callback = function(Value)
        textToWrite = Value
        if Value ~= "" then
            print("📝 Texto definido:", Value)
        end
    end
})

-- Botão para iniciar o processo
scriptsTab:AddButton({
    Name = "Iniciar Escrita",
    Description = "Clique para começar a escrever o texto",
    Callback = function()
        -- Verificar se já está rodando
        if getgenv()._TextWriterRunning then
            warn("")
            return
        end
        
        if textToWrite == "" or textToWrite == nil then
            warn("")
            return
        end
        
        getgenv()._TextWriterRunning = true

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = Players.LocalPlayer

        -- Mapa de itens para objetos do workspace
        local ITEM_OBJECTS = {
            ["Bomb"] = workspace.WorkspaceCom["001_CriminalWeapons"].GiveTools.Bomb,
            ["BabyBoy"] = workspace.WorkspaceCom["001_GiveTools"].BabyBoy,
            ["Box"] = workspace.WorkspaceCom["001_GiveTools"].Box,
            ["Laptop"] = workspace.WorkspaceCom["001_GiveTools"].Laptop,
            ["Basketball"] = workspace.WorkspaceCom["001_GiveTools"].Basketball
        }

        -- Mapa de caracteres (pixel art 7x5)
        local CHAR_MAP = {
            ["A"] = {"01110","10001","10001","11111","10001","10001","10001"},
            ["B"] = {"11110","10001","10001","11110","10001","10001","11110"},
            ["C"] = {"01110","10001","10000","10000","10000","10001","01110"},
            ["D"] = {"11110","10001","10001","10001","10001","10001","11110"},
            ["E"] = {"11111","10000","10000","11110","10000","10000","11111"},
            ["F"] = {"11111","10000","10000","11110","10000","10000","10000"},
            ["G"] = {"01110","10001","10000","10111","10001","10001","01110"},
            ["H"] = {"10001","10001","10001","11111","10001","10001","10001"},
            ["I"] = {"111","010","010","010","010","010","111"},
            ["J"] = {"00111","00010","00010","00010","10010","10010","01100"},
            ["K"] = {"10001","10010","10100","11000","10100","10010","10001"},
            ["L"] = {"10000","10000","10000","10000","10000","10000","11111"},
            ["M"] = {"10001","11011","10101","10101","10001","10001","10001"},
            ["N"] = {"10001","11001","10101","10011","10001","10001","10001"},
            ["O"] = {"01110","10001","10001","10001","10001","10001","01110"},
            ["P"] = {"11110","10001","10001","11110","10000","10000","10000"},
            ["Q"] = {"01110","10001","10001","10001","10101","10010","01101"},
            ["R"] = {"11110","10001","10001","11110","10100","10010","10001"},
            ["S"] = {"01111","10000","10000","01110","00001","00001","11110"},
            ["T"] = {"11111","00100","00100","00100","00100","00100","00100"},
            ["U"] = {"10001","10001","10001","10001","10001","10001","01110"},
            ["V"] = {"10001","10001","10001","10001","10001","01010","00100"},
            ["W"] = {"10001","10001","10001","10101","10101","11011","10001"},
            ["X"] = {"10001","01010","00100","00100","01010","10001","10001"},
            ["Y"] = {"10001","10001","10001","01010","00100","00100","00100"},
            ["Z"] = {"11111","00001","00010","00100","01000","10000","11111"},
            ["0"] = {"01110","10001","10011","10101","11001","10001","01110"},
            ["1"] = {"00100","01100","00100","00100","00100","00100","01110"},
            ["2"] = {"01110","10001","00001","00010","00100","01000","11111"},
            ["3"] = {"11111","00010","00100","00010","00001","10001","01110"},
            ["4"] = {"00010","00110","01010","10010","11111","00010","00010"},
            ["5"] = {"11111","10000","11110","00001","00001","10001","01110"},
            ["6"] = {"00110","01000","10000","11110","10001","10001","01110"},
            ["7"] = {"11111","00001","00010","00100","01000","10000","10000"},
            ["8"] = {"01110","10001","10001","01110","10001","10001","01110"},
            ["9"] = {"01110","10001","10001","01111","00001","00010","01100"},
            [" "] = {"00000","00000","00000","00000","00000","00000","00000"},
            ["!"] = {"00100","00100","00100","00100","00100","00000","00100"},
            ["?"] = {"01110","10001","00001","00010","00100","00000","00100"},
            ["."] = {"00000","00000","00000","00000","00000","00110","00110"},
            [","] = {"00000","00000","00000","00000","00000","00100","01000"},
            [":"] = {"00000","00110","00110","00000","00110","00110","00000"},
            [";"] = {"00000","00110","00110","00000","00100","01000","00000"},
            ["-"] = {"00000","00000","00000","11111","00000","00000","00000"},
            ["+"] = {"00000","00100","00100","11111","00100","00100","00000"},
            ["="] = {"00000","11111","00000","11111","00000","00000","00000"},
            ["/"] = {"00001","00010","00100","01000","10000","00000","00000"},
            ["("] = {"00010","00100","01000","01000","01000","00100","00010"},
            [")"] = {"01000","00100","00010","00010","00010","00100","01000"},
            ["*"] = {"00000","00100","10101","01110","10101","00100","00000"},
            ["%"] = {"11001","11010","00100","01000","10110","10011","00000"},
            ["@"] = {"01110","10001","10011","10101","10111","10000","01110"},
            ["#"] = {"01010","01010","11111","01010","11111","01010","01010"},
            ["$"] = {"00100","01111","10100","01110","00101","11110","00100"},
            ["&"] = {"01100","10010","10100","01000","10101","10010","01101"},
            ["'"] = {"00100","00100","00000","00000","00000","00000","00000"},
            ["_"] = {"00000","00000","00000","00000","00000","00000","11111"},
        }

        -- Função para contar ferramentas no inventário
        local function countTools()
            local total = 0
            for _, container in ipairs({player.Backpack, player.Character}) do
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") then 
                        total += 1 
                    end
                end
            end
            return total
        end

        -- Função para calcular quantas ferramentas são necessárias
        local function countRequiredTools(text)
            local total = 0
            local invalidChars = {}
            
            for c in text:upper():gmatch(".") do
                local rows = CHAR_MAP[c]
                if rows then
                    for _, row in ipairs(rows) do
                        total += row:gsub("0", ""):len()
                    end
                else
                    table.insert(invalidChars, c)
                end
            end
            
            if #invalidChars > 0 then
                warn("" .. table.concat(invalidChars, ", "))
            end
            
            return total
        end

        -- Validação inicial
        local text = textToWrite:upper()
        local maxTools = countRequiredTools(text)
        
        if maxTools == 0 then
            warn("❌ Nenhum caractere válido encontrado!")
            getgenv()._TextWriterRunning = false
            return
        end

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📝 Escrevendo:", text)
        print("🎯 Item escolhido:", selectedItem)
        print("🔧 Ferramentas necessárias:", maxTools)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        -- Obter posição original do jogador
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local originalPosition = hrp.CFrame

        -- Limpar ferramentas existentes
        print("🧹 Limpando ferramentas antigas...")
        pcall(function()
            ReplicatedStorage.RE:FindFirstChild("1Clea1rTool1s"):FireServer("ClearAllTools")
        end)
        task.wait(1)

        -- Teleportar para o local do item escolhido
        print("🚀 Teleportando para coletar ferramentas...")
        local itemObject = ITEM_OBJECTS[selectedItem]
        
        if not itemObject then
            warn("❌ Item não encontrado no workspace:", selectedItem)
            getgenv()._TextWriterRunning = false
            return
        end

        -- Teleporta para o objeto do item
        if itemObject:IsA("BasePart") then
            hrp.CFrame = itemObject.CFrame + Vector3.new(0, 5, 0)
        elseif itemObject:IsA("Model") and itemObject.PrimaryPart then
            hrp.CFrame = itemObject.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        else
            -- Tenta encontrar uma parte dentro do objeto
            local part = itemObject:FindFirstChildWhichIsA("BasePart", true)
            if part then
                hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
            end
        end
        
        task.wait(0.5)

        -- Procurar ClickDetector no item
        local clickDetector = itemObject:FindFirstChildWhichIsA("ClickDetector", true)
        
        if not clickDetector then
            warn("❌ ClickDetector não encontrado no item:", selectedItem)
            getgenv()._TextWriterRunning = false
            return
        end

        -- Coletar ferramentas com progresso
        print("⏳ Coletando ferramentas (" .. selectedItem .. ")...")
        local attempts = 0
        local maxAttempts = maxTools * 3
        
        repeat
            pcall(function()
                fireclickdetector(clickDetector)
            end)
            
            local current = countTools()
            if current % 10 == 0 or current == maxTools then
                print("📦 Progresso: " .. current .. "/" .. maxTools)
            end
            
            attempts += 1
            if attempts > maxAttempts then
                warn("❌ Tempo limite atingido ao coletar ferramentas!")
                getgenv()._TextWriterRunning = false
                return
            end
            
            task.wait(0.05)
        until countTools() >= maxTools

        print("")
        task.wait(0.5)

        -- Organizar todas as ferramentas
        print("📋 Organizando ferramentas...")
        local tools = {}
        for _, container in ipairs({player.Backpack, player.Character}) do
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then 
                    table.insert(tools, tool)
                end
            end
        end

        if #tools < maxTools then
            warn("❌ Ferramentas insuficientes! Necessário: " .. maxTools .. ", Encontrado: " .. #tools)
            getgenv()._TextWriterRunning = false
            return
        end

        -- Mover todas as ferramentas para o backpack
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then 
                tool.Parent = player.Backpack 
            end
        end

        task.wait(0.3)

        -- Calcular posições para cada ferramenta
        print("🧮 Calculando posições do texto...")
        local gripMap = {}
        local startPos = Vector3.new(0, -5, 0)
        local pixelSize = Vector3.new(1.2, 1.2, 0)
        local toolIndex = 1
        local offsetX = 0

        for i = 1, #text do
            local char = text:sub(i, i):upper()
            local map = CHAR_MAP[char]
            
            if map then
                for y = 1, #map do
                    for x = 1, #map[y] do
                        if map[y]:sub(x, x) == "1" then
                            local tool = tools[toolIndex]
                            if tool then
                                gripMap[tool] = CFrame.new(
                                    startPos.X + (offsetX + x - 1) * pixelSize.X,
                                    startPos.Y + (y - 1) * pixelSize.Y,
                                    startPos.Z
                                )
                                toolIndex += 1
                            end
                        end
                    end
                end
                offsetX += #map[1] + 1
            end
        end

        -- Voltar para posição original
        print("🏠 Voltando para posição original...")
        hrp.CFrame = originalPosition
        task.wait(1)

        -- Aplicar as posições
        print("🎨 Aplicando posições...")
        for tool, grip in pairs(gripMap) do
            pcall(function()
                tool.Grip = grip
            end)
        end

        task.wait(1)

        -- Equipar todas as ferramentas
        print("⚙️ Equipando ferramentas...")
        for i = 1, maxTools do
            if tools[i] then
                pcall(function()
                    tools[i].Parent = player.Character
                end)
            end
        end

        task.wait(0.5)

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✨ Texto escrito com sucesso: " .. text)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        getgenv()._TextWriterRunning = false
    end
})

scriptsTab:AddParagraph({"Informação:", "Clique em algum item"})
scriptsTab:AddParagraph({"Informação:", "depois de escolher clique em escrever"})
scriptsTab:AddParagraph({"Informação:", "vc vai começa a escrever"})

local flingsTab = Window:MakeTab({"Troll ", "skull"})

local Section = flingsTab:AddSection({"Se quiser trocar a skybox, apenas mude sua camisa"})

-- Variáveis para controlar os estados
local SkyboxActive = false
local CurrentTrack = nil
local RigidTrack = nil

flingsTab:AddButton({
   Name = "Skybox FE",
   Callback = function()
        if SkyboxActive then
            -- Desativa skybox e animações
            if CurrentTrack then
                CurrentTrack:Stop(0.1)
                CurrentTrack = nil
            end
            if RigidTrack then
                RigidTrack:Stop(0.1)
                RigidTrack = nil
            end
            
            -- Primeiro reseta a aparência
            game:GetService("ReplicatedStorage").Remotes.ResetCharacterAppearance:FireServer()
            
            -- Aguarda um pouco e então mata o personagem
            task.wait(0.3)
            
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
            
            SkyboxActive = false
            print("Skybox e andar duro removidos!")
        else
            -- Ativa a skybox
            local args = {
                {
                    100839513065432
                }
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
            
            function missing(t, f, fallback)
                if type(f) == t then return f end
                return fallback 
            end

            cloneref = missing("function", cloneref, function(...) return ... end)

            local Services = setmetatable({}, {
                __index = function(_, name)
                    return cloneref(game:GetService(name))
                end
            })

            local Players = Services.Players
            local player = Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")

            -- Configurações da skybox
            local Settings = {}
            Settings["Fade In"]     = 0.1
            Settings["Fade Out"]    = 0.1
            Settings["Weight"]      = 1
            Settings["Speed"]       = 1
            Settings["Time Position"] = 0

            local function LoadTrack(id)
                local animId
                local ok, result = pcall(function()
                    return game:GetObjects("rbxassetid://" .. tostring(id))
                end)

                if ok and result and #result > 0 then
                    local anim = result[1]
                    if anim:IsA("Animation") then
                        animId = anim.AnimationId
                    else
                        animId = "rbxassetid://" .. tostring(id)
                    end
                else
                    animId = "rbxassetid://" .. tostring(id)
                end

                local newAnim = Instance.new("Animation")
                newAnim.AnimationId = animId
                local newTrack = humanoid:LoadAnimation(newAnim)
                newTrack.Priority = Enum.AnimationPriority.Action4

                local weight = Settings["Weight"]
                if weight == 0 then weight = 0.001 end

                newTrack:Play(Settings["Fade In"], weight, Settings["Speed"])
                
                CurrentTrack = newTrack
                CurrentTrack.TimePosition = math.clamp(Settings["Time Position"], 0, 1) * CurrentTrack.Length

                return newTrack
            end

            -- Executa a animação da skybox
            local EmoteId = 101852027997337
            LoadTrack(EmoteId)
            
            -- Aguarda um pouco antes de ativar o planking
            task.wait(0.5)
            
            -- Ativa a animação de planking (andar duro/deitado)
            local PlankingId = "rbxassetid://3695333486"
            local plankAnim = Instance.new("Animation")
            plankAnim.AnimationId = PlankingId
            RigidTrack = humanoid:LoadAnimation(plankAnim)
            RigidTrack.Priority = Enum.AnimationPriority.Movement
            RigidTrack:Play(0.1, 1, 0)
            
            SkyboxActive = true
            print("Skybox e andar duro ativados!")
        end
    end
})

-- Botão de reset completo
flingsTab:AddButton({
    Name = "Para Skybox",
    Callback = function()
        if CurrentTrack then
            CurrentTrack:Stop(0.1)
            CurrentTrack = nil
        end
        if RigidTrack then
            RigidTrack:Stop(0.1)
            RigidTrack = nil
        end
        SkyboxActive = false
        
        -- Primeiro reseta a aparência
        game:GetService("ReplicatedStorage").Remotes.ResetCharacterAppearance:FireServer()
        
        -- Aguarda um pouco para o remote processar
        task.wait(0.3)
        
        -- Depois mata o personagem
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
        
        print("Aparência resetada e personagem morto!")
    end
})

-- Detecção automática de reset/morte do personagem
local Players = game:GetService("Players")
local player = Players.LocalPlayer

player.CharacterAdded:Connect(function()
    -- Quando o personagem respawna, desativa tudo
    SkyboxActive = false
    CurrentTrack = nil
    RigidTrack = nil
    print("Personagem resetado - Tudo desativado")
end)

flingsTab:AddSection({ "Nuke Server" })

local SkyboxActive = false
local CurrentTrack = nil
local EmoteTrack = nil
local SpinConnection = nil

flingsTab:AddButton({
   Name = "Nuke FE",
   Callback = function()
        if SkyboxActive then
            if CurrentTrack then
                CurrentTrack:Stop(0.1)
                CurrentTrack = nil
            end
            
            if EmoteTrack then
                EmoteTrack:Stop(0.1)
                EmoteTrack = nil
            end
            
            if SpinConnection then
                SpinConnection:Disconnect()
                SpinConnection = nil
            end
            
            game:GetService("ReplicatedStorage").Remotes.ResetCharacterAppearance:FireServer()
            task.wait(0.3)
            
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
            
            SkyboxActive = false
        else
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local player = Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")
            local animator = humanoid:WaitForChild("Animator")
            local rootPart = character:WaitForChild("HumanoidRootPart")

            local animationId = 121255258198847
            local assetUrl = "rbxassetid://" .. animationId
            
            pcall(function()
                local anim = Instance.new("Animation")
                anim.AnimationId = assetUrl
                EmoteTrack = animator:LoadAnimation(anim)
                EmoteTrack.Priority = Enum.AnimationPriority.Action
                EmoteTrack.Looped = true
                EmoteTrack:Play()
            end)
            
            task.wait(0.1)
            pcall(function()
                local remote = ReplicatedStorage.Remotes:FindFirstChild("Emotes:PlaySyncableEmote")
                if remote then
                    local args = {
                        [1] = {
                            ["Id"] = animationId,
                            ["Repeat"] = true,
                            ["Name"] = "Hurt",
                            ["Filter"] = "Pose"
                        }
                    }
                    remote:FireServer(unpack(args))
                end
            end)
            
            pcall(function()
                local args = {
                    [1] = "Hurt"
                }
                ReplicatedStorage.Remotes.t_animationPlayed:FireServer(unpack(args))
            end)
            
            task.wait(0.5)
            
            local args = {
                {
                    100839513065432
                }
            }
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack(args))
            
            function missing(t, f, fallback)
                if type(f) == t then return f end
                return fallback 
            end

            cloneref = missing("function", cloneref, function(...) return ... end)

            local Services = setmetatable({}, {
                __index = function(_, name)
                    return cloneref(game:GetService(name))
                end
            })

            local Settings = {}
            Settings["Fade In"]     = 0.1
            Settings["Fade Out"]    = 0.1
            Settings["Weight"]      = 1
            Settings["Speed"]       = 1
            Settings["Time Position"] = 0

            local function LoadTrack(id)
                local animId
                local ok, result = pcall(function()
                    return game:GetObjects("rbxassetid://" .. tostring(id))
                end)

                if ok and result and #result > 0 then
                    local anim = result[1]
                    if anim:IsA("Animation") then
                        animId = anim.AnimationId
                    else
                        animId = "rbxassetid://" .. tostring(id)
                    end
                else
                    animId = "rbxassetid://" .. tostring(id)
                end

                local newAnim = Instance.new("Animation")
                newAnim.AnimationId = animId
                local newTrack = animator:LoadAnimation(newAnim)
                newTrack.Priority = Enum.AnimationPriority.Core

                local weight = Settings["Weight"]
                if weight == 0 then weight = 0.001 end

                newTrack:Play(Settings["Fade In"], weight, Settings["Speed"])
                
                CurrentTrack = newTrack
                CurrentTrack.TimePosition = math.clamp(Settings["Time Position"], 0, 1) * CurrentTrack.Length

                return newTrack
            end

            local EmoteId = 101852027997337
            LoadTrack(EmoteId)
            
            local RunService = game:GetService("RunService")
            local spinSpeed = 5
            
            SpinConnection = RunService.Heartbeat:Connect(function(deltaTime)
                if rootPart and rootPart.Parent then
                    local rotation = CFrame.Angles(0, math.rad(spinSpeed * deltaTime * 60), 0)
                    rootPart.CFrame = rootPart.CFrame * rotation
                end
            end)
            
            SkyboxActive = true
        end
    end
})

flingsTab:AddButton({
   Name = "Stop Nuke",
   Callback = function()
        if CurrentTrack then
            CurrentTrack:Stop(0.1)
            CurrentTrack = nil
        end
        if EmoteTrack then
            EmoteTrack:Stop(0.1)
            EmoteTrack = nil
        end
        if SpinConnection then
            SpinConnection:Disconnect()
            SpinConnection = nil
        end
        SkyboxActive = false
        
        game:GetService("ReplicatedStorage").Remotes.ResetCharacterAppearance:FireServer()
        
        task.wait(0.3)
        
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end
})

flingsTab:AddSection({ "Troll" })

-- ========================================
-- FUNÇÕES AUXILIARES
-- ========================================
local function SendNotification(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5,
            Icon = "rbxassetid://6023426915",
        })
    end)
    if OrionLib then
        pcall(function()
            OrionLib:MakeNotification({
                Name = title,
                Content = text,
                Time = 5
            })
        end)
    end
    warn("" .. title .. ": " .. text)
end

-- FUNÇÃO DESABILITADA - Sempre retorna false (permite fling em qualquer situação)
local function IsPlayerSitting(player)
    return false
end

local function DeleteAllVehicles()
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer("DeleteAllVehicles")
    end)
end

local function ClearAllTools()
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Clea1rTool1s"):FireServer("ClearAllTools")
    end)
end

local function GetAndEquipCouch()
    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name == "Couch" then
            v.Grip = CFrame.new(0, 2, -2.5)
            v.Parent = LocalPlayer.Character
            return true
        end
    end
    
    pcall(function()
        ReplicatedStorage.RE:FindFirstChild("1Too1l"):InvokeServer("PickingTools", "Couch")
    end)
    
    local startTime = tick()
    while tick() - startTime < 0.5 do
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v.Name == "Couch" then
                v.Grip = CFrame.new(0, 2, -2.5)
                v.Parent = LocalPlayer.Character
                return true
            end
        end
        task.wait(0.1)
    end
    return false
end

local function UnequipCouch()
    if LocalPlayer.Character then
        for _, v in ipairs(LocalPlayer.Character:GetChildren()) do
            if v:IsA("Tool") and v.Name == "Couch" then
                v.Parent = LocalPlayer.Backpack
                return true
            end
        end
    end
    return false
end

-- ========================================
-- DROPDOWNS COM SELEÇÃO PERSISTENTE
-- ========================================
local lockedTarget = nil
local lastRefreshTime = tick()

local killDropdown = flingsTab:AddDropdown({
    Name = "Target",
    Options = {},
    Default = "",
    Callback = function(value)
        if value and value ~= "" then
            lockedTarget = value
            selectedPlayerName = value
            getgenv().Target = value
            SendNotification("Alvo Travado", value .. " está selecionado!")
        end
    end
})

local function getPlayersList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            list[#list+1] = player.Name
        end
    end
    return list
end

local function isPlayerInList(playerName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == playerName and player ~= LocalPlayer then
            return true
        end
    end
    return false
end

local function isTargetValid()
    if not lockedTarget then return false end
    local varsSync = (selectedPlayerName == lockedTarget and getgenv().Target == lockedTarget)
    local playerExists = isPlayerInList(lockedTarget)
    return varsSync and playerExists
end

local function refreshDropdown()
    if not killDropdown then return end
    
    local previousTarget = lockedTarget
    local newPlayers = getPlayersList()
    
    pcall(function() killDropdown:Refresh(newPlayers) end)
    pcall(function() killDropdown:Set(newPlayers) end)
    
    if previousTarget and isPlayerInList(previousTarget) then
        lockedTarget = previousTarget
        selectedPlayerName = previousTarget
        getgenv().Target = previousTarget
    else
        lockedTarget = nil
        selectedPlayerName = nil
        getgenv().Target = nil
    end
    
    lastRefreshTime = tick()
end

flingsTab:AddButton({
    Name = "Atualizar Lista",
    Callback = function()
        refreshDropdown()
    end
})

task.spawn(function()
    task.wait(1)
    local initialPlayers = getPlayersList()
    pcall(function() killDropdown:Refresh(initialPlayers) end)
    pcall(function() killDropdown:Set(initialPlayers) end)
end)

task.spawn(function()
    while task.wait(5) do
        if tick() - lastRefreshTime >= 500 then
            refreshDropdown()
            if lockedTarget then
                SendNotification("Atualizou", "Lista atualizada! Alvo: " .. lockedTarget)
            end
        end
        
        if lockedTarget then
            if not isTargetValid() then
                if not isPlayerInList(lockedTarget) then
                    lockedTarget = nil
                    selectedPlayerName = nil
                    getgenv().Target = nil
                    refreshDropdown()
                    SendNotification("Alvo Perdido", "Jogador saiu do servidor!")
                else
                    selectedPlayerName = lockedTarget
                    getgenv().Target = lockedTarget
                end
            end
        end
    end
end)

local selectedMethod = "Ball"
flingsTab:AddDropdown({
    Name = "Method",
    Options = {"Ball", "Couch", "Boat", "PoliceBoat", "Bus", "TowTruck"},
    Default = "Ball",
    Callback = function(value)
        selectedMethod = value
    end
})

-- ========================================
-- FLING BALL
-- ========================================
local function FlingBall(target)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local ServerBalls = workspace.WorkspaceCom:WaitForChild("001_SoccerBalls")

    local function GetBall()
        if not backpack:FindFirstChild("SoccerBall") then
            game:GetService("ReplicatedStorage").RE:FindFirstChild("1Too1l"):InvokeServer("PickingTools", "SoccerBall")
        end
        repeat task.wait() until backpack:FindFirstChild("SoccerBall")
        backpack.SoccerBall.Parent = character
        repeat task.wait() until ServerBalls:FindFirstChild("Soccer" .. LocalPlayer.Name)
        character.SoccerBall.Parent = backpack
        return ServerBalls:FindFirstChild("Soccer" .. LocalPlayer.Name)
    end

    local Ball = ServerBalls:FindFirstChild("Soccer" .. LocalPlayer.Name) or GetBall()
    Ball.CanCollide = false
    Ball.Massless = true
    Ball.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0, 0)

    local tchar = target.Character
    if tchar and tchar:FindFirstChild("HumanoidRootPart") and tchar:FindFirstChild("Humanoid") then
        local troot = tchar.HumanoidRootPart
        local thum = tchar.Humanoid

        if Ball:FindFirstChildWhichIsA("BodyVelocity") then
            Ball:FindFirstChildWhichIsA("BodyVelocity"):Destroy()
        end

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.P = 9e900
        bv.Parent = Ball

        workspace.CurrentCamera.CameraSubject = thum
        
        repeat
            if troot.Velocity.Magnitude > 0 then
                local pos_x = troot.Position.X + (troot.Velocity.X / 1.5)
                local pos_y = troot.Position.Y + (troot.Velocity.Y / 1.5)
                local pos_z = troot.Position.Z + (troot.Velocity.Z / 1.5)
                Ball.CFrame = CFrame.new(pos_x, pos_y, pos_z)
                Ball.Orientation += Vector3.new(45, 60, 30)
            else
                for _, v in pairs(tchar:GetChildren()) do
                    if v:IsA("BasePart") and v.CanCollide and not v.Anchored then
                        Ball.CFrame = v.CFrame
                        task.wait(1/6000)
                    end
                end
            end
            task.wait(1/6000)
        until troot.Velocity.Magnitude > 1000 or thum.Health <= 0 or not tchar:IsDescendantOf(workspace)
        
        workspace.CurrentCamera.CameraSubject = humanoid
    end
end

-- ========================================
-- KILL COUCH (SEM VERIFICAÇÃO DE SEAT)
-- ========================================
local function SkidFling(TargetPlayer, originalPosition)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter and TCharacter:FindFirstChild("Head")
    
    if not (Character and Humanoid and RootPart and TCharacter and THumanoid and TRootPart) then return end
    
    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
    end
    
    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif THumanoid then
        workspace.CurrentCamera.CameraSubject = THumanoid
    end
    
    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end
    
    local SFBasePart = function(BasePart)
        local TimeToWait = 5
        local Time = tick()
        local Angle = 0
        
        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0,0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0,0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0,0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90),0,0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0,0,0))
                    task.wait()
                end
            else
                break
            end
        until BasePart.Velocity.Magnitude > 500 or not BasePart.Parent or not TargetPlayer.Character or Humanoid.Health <= 0 or tick() > Time + TimeToWait
    end
    
    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    
    if TRootPart and THead then
        if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
            SFBasePart(THead)
        else
            SFBasePart(TRootPart)
        end
    elseif TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    end
    
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid
    
    task.wait(0.5)
    UnequipCouch()
    
    if originalPosition and RootPart then
        RootPart.CFrame = originalPosition
        RootPart.Velocity = Vector3.new(0, 0, 0)
        RootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    
    task.wait(0.3)
    ClearAllTools()
    workspace.FallenPartsDestroyHeight = -500
end

local function KillCouch(target)
    -- VERIFICAÇÃO DE SEAT REMOVIDA - Agora funciona mesmo se o alvo estiver sentado
    
    local RootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return end
    
    local originalPosition = RootPart.CFrame
    workspace.FallenPartsDestroyHeight = 0/0
    
    if not GetAndEquipCouch() then
        SendNotification("Erro", "Não foi possível equipar sofá")
        workspace.FallenPartsDestroyHeight = -500
        return
    end
    
    while not target.Character do task.wait(0.1) end
    SkidFling(target, originalPosition)
end

-- ========================================
-- BRING COUCH
-- ========================================
local function BringCouch(target)
    if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        SendNotification("Erro", "Jogador alvo sem personagem")
        return
    end

    SendNotification("Iniciando", "Trazendo " .. target.Name .. " com Couch...")

    local args = { [1] = "ClearAllTools" }
    ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer(unpack(args))
    
    local args = { [1] = "PickingTools", [2] = "Couch" }
    ReplicatedStorage.RE:FindFirstChild("1Too1l"):InvokeServer(unpack(args))

    local couch = LocalPlayer.Backpack:WaitForChild("Couch", 2)
    if not couch then
        SendNotification("Erro", "Sofá não encontrado no Backpack")
        return
    end

    couch.Name = "Chaos.Couch"
    local seat1 = couch:FindFirstChild("Seat1")
    local seat2 = couch:FindFirstChild("Seat2")
    local handle = couch:FindFirstChild("Handle")
    
    if seat1 and seat2 and handle then
        seat1.Disabled = true
        seat2.Disabled = true
        handle.Name = "Handle "
    else
        SendNotification("Erro", "Componentes do sofá não encontrados")
        return
    end
    
    couch.Parent = LocalPlayer.Character

    local tet = Instance.new("BodyVelocity", seat1)
    tet.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    tet.P = 1250
    tet.Velocity = Vector3.new(0, 0, 0)
    tet.Name = "#mOVOOEPF$#@F$#GERE..>V<<<<EW<V<<W"

    repeat
        for m = 1, 35 do
            local pos = { x = 0, y = 0, z = 0 }
            local tRoot = target.Character and target.Character.HumanoidRootPart
            if not tRoot then break end
            
            pos.x = tRoot.Position.X + (tRoot.Velocity.X / 2)
            pos.y = tRoot.Position.Y + (tRoot.Velocity.Y / 2)
            pos.z = tRoot.Position.Z + (tRoot.Velocity.Z / 2)
            
            seat1.CFrame = CFrame.new(Vector3.new(pos.x, pos.y, pos.z)) * CFrame.new(-2, 2, 0)
            task.wait()
        end
        
        tet:Destroy()
        couch.Parent = LocalPlayer.Backpack
        task.wait()
        couch:FindFirstChild("Handle ").Name = "Handle"
        task.wait(0.2)
        couch.Parent = LocalPlayer.Character
        task.wait()
        couch.Parent = LocalPlayer.Backpack
        couch.Handle.Name = "Handle "
        task.wait(0.2)
        couch.Parent = LocalPlayer.Character
        
        tet = Instance.new("BodyVelocity", seat1)
        tet.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        tet.P = 1250
        tet.Velocity = Vector3.new(0, 0, 0)
        tet.Name = "#mOVOOEPF$#@F$#GERE..>V<<<<EW<V<<W"
        
    until target.Character and target.Character.Humanoid and target.Character.Humanoid.Sit == true

    task.wait()
    tet:Destroy()
    couch.Parent = LocalPlayer.Backpack
    task.wait()
    couch:FindFirstChild("Handle ").Name = "Handle"
    task.wait(0.3)
    couch.Parent = LocalPlayer.Character
    task.wait(0.3)
    couch.Grip = CFrame.new(Vector3.new(0, 0, 0))
    task.wait(0.3)
    ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer("ClearAllTools")
    
    SendNotification("Sucesso", target.Name .. " foi trazido!")
end

-- ========================================
-- KILL VEÍCULOS (SEM VERIFICAÇÃO DE SEAT)
-- ========================================
local function KillVehicle(target, vehicleType)
    -- VERIFICAÇÃO DE SEAT REMOVIDA
    
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not humanoidRootPart or not humanoid then return end
    
    local originalPosition = humanoidRootPart.CFrame
    local Vehicles = workspace:FindFirstChild("Vehicles")
    
    if vehicleType == "Boat" then
        humanoidRootPart.CFrame = CFrame.new(1754, -2, 58)
        task.wait(0.5)
        pcall(function()
            game:GetService("ReplicatedStorage").RE:FindFirstChild("1Ca1r"):FireServer("PickingBoat", "MilitaryBoatFree")
        end)
    elseif vehicleType == "PoliceBoat" then
        humanoidRootPart.CFrame = CFrame.new(1754, -2, 58)
        task.wait(0.5)
        pcall(function()
            local args = {"PickingBoat", "PoliceBoatChangeable"}
            game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer(unpack(args))
        end)
    else
        humanoidRootPart.CFrame = CFrame.new(1118.81, 75.998, -1138.61)
        task.wait(0.5)
        pcall(function()
            local args = vehicleType == "Bus" and {"PickingCar", "SchoolBus"} or {"PickingCar", "TowTruck"}
            game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer(unpack(args))
        end)
    end
    
    task.wait(1.5)
    
    local vehicle = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
    if not vehicle then
        humanoidRootPart.CFrame = originalPosition
        return
    end
    
    local seat
    if vehicleType == "Boat" or vehicleType == "PoliceBoat" then
        seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("VehicleSeat")
    else
        seat = vehicle:FindFirstChild("Seats") and vehicle.Seats:FindFirstChild("VehicleSeat")
        if not seat then
            seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("VehicleSeat")
        end
    end
    
    if not seat then
        DeleteAllVehicles()
        humanoidRootPart.CFrame = originalPosition
        return
    end
    
    local attempts = 0
    repeat
        humanoidRootPart.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.1)
        attempts = attempts + 1
    until humanoid.Sit or attempts > 50 or not vehicle.Parent
    
    if not humanoid.Sit then
        DeleteAllVehicles()
        humanoidRootPart.CFrame = originalPosition
        return
    end
    
    for _, container in pairs({vehicle:FindFirstChild("Body"), vehicle:FindFirstChild("Seats")}) do
        if container then
            for _, v in pairs(container:GetChildren()) do
                if v:IsA("Seat") or v:IsA("VehicleSeat") then
                    v.CanTouch = false
                end
            end
        end
    end
    
    workspace.FallenPartsDestroyHeight = 0/0
    
    local Spin
    if vehicleType == "Boat" or vehicleType == "PoliceBoat" then
        Spin = Instance.new("BodyAngularVelocity")
        Spin.Parent = vehicle.PrimaryPart
        Spin.MaxTorque = Vector3.new(0, math.huge, 0)
        Spin.AngularVelocity = Vector3.new(0, 200, 0)
    end
    
    local flingActive = true
    local targetInVoid = false
    
    task.spawn(function()
        local startTime = tick()
        local maxTime = (vehicleType == "Boat" or vehicleType == "PoliceBoat") and 15 or 20
        
        while flingActive and vehicle and vehicle.Parent do
            local targetChar = target.Character
            if not targetChar then break end
            
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then break end
            
            if targetRoot.Position.Y < -100 then
                targetInVoid = true
                break
            end
            
            -- BLOCO DE VERIFICAÇÃO DE SEAT REMOVIDO - Continua fling mesmo se sentar
            
            if vehicleType == "Boat" or vehicleType == "PoliceBoat" then
                local angle = (tick() - startTime) * 50
                if targetRoot.Velocity.Magnitude < 50 then
                    local movePatterns = {
                        {pos = CFrame.new(0, 1.5, 0) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 2, rot = CFrame.Angles(math.rad(angle), 0, 0)},
                        {pos = CFrame.new(0, -1.5, 0) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 2, rot = CFrame.Angles(math.rad(angle), 0, 0)},
                        {pos = CFrame.new(1.5, 1.5, -1.5) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 2, rot = CFrame.Angles(math.rad(angle), 0, 0)},
                        {pos = CFrame.new(-1.5, -1.5, 1.5) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 2, rot = CFrame.Angles(math.rad(angle), 0, 0)},
                    }
                    for _, pattern in ipairs(movePatterns) do
                        if not flingActive then break end
                        pcall(function()
                            vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * pattern.pos * pattern.rot)
                        end)
                        task.wait(0.1)
                    end
                else
                    local speedPatterns = {
                        CFrame.new(0, 1.5, targetHumanoid.WalkSpeed),
                        CFrame.new(0, -1.5, -targetHumanoid.WalkSpeed),
                        CFrame.new(0, 1.5, targetRoot.Velocity.Magnitude / 2),
                        CFrame.new(0, -1.5, -targetRoot.Velocity.Magnitude / 2),
                    }
                    for _, offset in ipairs(speedPatterns) do
                        if not flingActive then break end
                        pcall(function()
                            vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * offset * CFrame.Angles(math.rad(90), 0, 0))
                        end)
                        task.wait(0.1)
                    end
                end
                task.wait(0.05)
            else
                local time = tick() * 35
                local lateralOffset = math.sin(time) * 4
                local frontBackOffset = math.cos(time) * 20
                pcall(function()
                    vehicle:SetPrimaryPartCFrame(targetRoot.CFrame * CFrame.new(lateralOffset, 0, frontBackOffset))
                end)
            end
            
            if tick() - startTime > maxTime then break end
            RunService.RenderStepped:Wait()
        end
        flingActive = false
    end)
    
    while flingActive do task.wait(0.1) end
    
    if Spin then Spin:Destroy() end
    
    task.wait(0.3)
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    task.wait(0.7)
    if humanoidRootPart then
        humanoidRootPart.CFrame = originalPosition
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    
    task.wait(0.5)
    DeleteAllVehicles()
    workspace.FallenPartsDestroyHeight = -500
    
    if targetInVoid then
        SendNotification("Sucesso", "Kill executado!")
    else
        SendNotification("Concluído", "Fling finalizado")
    end
end

-- ========================================
-- BRING VEÍCULOS
-- ========================================
local function BringVehicle(target, vehicleType)
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not humanoidRootPart or not humanoid then return end
    
    local originalPosition = humanoidRootPart.CFrame
    local Vehicles = workspace:FindFirstChild("Vehicles")
    
    if vehicleType == "Boat" then
        humanoidRootPart.CFrame = CFrame.new(1754, -2, 58)
        task.wait(0.5)
        pcall(function()
            game:GetService("ReplicatedStorage").RE:FindFirstChild("1Ca1r"):FireServer("PickingBoat", "MilitaryBoatFree")
        end)
    elseif vehicleType == "PoliceBoat" then
        humanoidRootPart.CFrame = CFrame.new(1754, -2, 58)
        task.wait(0.5)
        pcall(function()
            game:GetService("ReplicatedStorage").RE:FindFirstChild("1Ca1r"):FireServer("PickingBoat", "PoliceBoatChangeable")
        end)
    else
        humanoidRootPart.CFrame = CFrame.new(1118.81, 75.998, -1138.61)
        task.wait(0.5)
        pcall(function()
            local args = vehicleType == "Bus" and {"PickingCar", "SchoolBus"} or {"PickingCar", "TowTruck"}
            game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer(unpack(args))
        end)
    end
    
    task.wait(1.5)
    
    local vehicle = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
    if not vehicle then
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Veículo não spawnou")
        return
    end
    
    local seats = {}
    for _, container in pairs({vehicle:FindFirstChild("Body"), vehicle:FindFirstChild("Seats")}) do
        if container then
            for _, v in pairs(container:GetChildren()) do
                if v:IsA("Seat") or v:IsA("VehicleSeat") then
                    table.insert(seats, v)
                end
            end
        end
    end
    
    if #seats == 0 then
        DeleteAllVehicles()
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Nenhum assento encontrado")
        return
    end
    
    local mySeat = seats[1]
    
    local attempts = 0
    repeat
        humanoidRootPart.CFrame = mySeat.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.1)
        attempts = attempts + 1
    until humanoid.Sit or attempts > 50 or not vehicle.Parent
    
    if not humanoid.Sit then
        DeleteAllVehicles()
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Não conseguiu sentar")
        return
    end
    
    workspace.FallenPartsDestroyHeight = 0/0
    
    local flingActive = true
    local brought = false
    
    task.spawn(function()
        local startTime = tick()
        local maxTime = 30
        
        while flingActive and vehicle and vehicle.Parent do
            local targetChar = target.Character
            if not targetChar then break end
            
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then break end
            
            if targetHumanoid.Sit then
                SendNotification("Alvo Sentou!", "Trazendo SUPER RÁPIDO...")
                
                for i = 1, 30 do
                    pcall(function()
                        vehicle:SetPrimaryPartCFrame(originalPosition * CFrame.new(0, 5, -3))
                    end)
                    task.wait(0.03)
                    
                    local distance = (targetRoot.Position - originalPosition.Position).Magnitude
                    if distance < 10 then
                        brought = true
                        SendNotification("Sucesso", "Player trazido!")
                        break
                    end
                end
                break
            end
            
            local distance = (targetRoot.Position - originalPosition.Position).Magnitude
            if distance < 10 then
                brought = true
                SendNotification("Sucesso", "Player trazido!")
                break
            end
            
            pcall(function()
                for idx, seat in pairs(seats) do
                    local angle = (tick() * 100 + (idx * 60)) % 360
                    local rad = math.rad(angle)
                    local offsetX = math.cos(rad) * 3
                    local offsetZ = math.sin(rad) * 3
                    
                    seat.CFrame = targetRoot.CFrame * CFrame.new(offsetX, 2, offsetZ)
                    seat.Velocity = Vector3.new(0, 50, 0)
                    seat.CanTouch = false
                end
            end)
            
            if tick() - startTime > maxTime then 
                SendNotification("Tempo Esgotado", "Tente novamente")
                break 
            end
            
            RunService.RenderStepped:Wait()
        end
        flingActive = false
    end)
    
    while flingActive do task.wait(0.1) end
    
    task.wait(0.3)
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    task.wait(0.7)
    if humanoidRootPart then
        humanoidRootPart.CFrame = originalPosition
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    
    task.wait(0.5)
    DeleteAllVehicles()
    workspace.FallenPartsDestroyHeight = -500
end

-- ========================================
-- HOUSE BAN KILL (APENAS COUCH)
-- ========================================
flingsTab:AddButton({
    Name = "House Ban Kill So Com Couch",
    Callback = function()
        if not lockedTarget or lockedTarget == "" then
            SendNotification("Erro", "Selecione um alvo primeiro!")
            return
        end
        
        local selectedPlayer = Players:FindFirstChild(lockedTarget)
        if not selectedPlayer or not selectedPlayer.Character then
            SendNotification("Erro", "Alvo não encontrado!")
            return
        end
        
        SendNotification("House Ban", "Iniciando processo...")
        
        local Player = LocalPlayer
        local Character = Player.Character
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Houses = workspace:FindFirstChild("001_Lots")
        local OldPos = RootPart.CFrame
        
        if not (Character and RootPart and Houses) then
            SendNotification("Erro", "Personagem inválido!")
            return
        end
        
        local MyHouse = Houses:FindFirstChild(Player.Name .. "House")
        
        if not MyHouse then
            SendNotification("House Ban", "Comprando casa...")
            
            local availableHouses = {}
            for _, Lot in pairs(Houses:GetChildren()) do
                if Lot.Name == "For Sale" then
                    for _, num in pairs(Lot:GetDescendants()) do
                        if num:IsA("NumberValue") and num.Name == "Number" and num.Value < 25 and num.Value > 10 then
                            table.insert(availableHouses, {Lot = Lot, Number = num.Value})
                            break
                        end
                    end
                end
            end
            
            if #availableHouses == 0 then
                SendNotification("Erro", "Nenhuma casa disponível!")
                return
            end
            
            local randomHouse = availableHouses[math.random(1, #availableHouses)]
            local houseNumber = randomHouse.Number
            
            local BuyDetector = randomHouse.Lot:FindFirstChild("BuyHouse")
            if BuyDetector then
                RootPart.CFrame = BuyDetector.CFrame + Vector3.new(0, -6, 0)
                task.wait(0.3)
                local ClickDetector = BuyDetector:FindFirstChild("ClickDetector")
                if ClickDetector then
                    fireclickdetector(ClickDetector)
                end
            end
            
            task.wait(0.5)
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Lot:BuildProperty"):FireServer(houseNumber, "056_House")
            end)
            
            task.wait(1)
            MyHouse = Houses:FindFirstChild(Player.Name .. "House")
        end
        
        if MyHouse then
            for _, x in pairs(MyHouse:GetDescendants()) do
                if x.Name == "Number" and x:IsA("NumberValue") then
                    task.wait(0.3)
                    pcall(function()
                        game:GetService("ReplicatedStorage").RE:FindFirstChild("1Gettin1gHous1e"):FireServer("PickingCustomHouse", "049_House", x.Value)
                    end)
                    break
                end
            end
        end
        
        task.wait(1)
        MyHouse = Houses:FindFirstChild(Player.Name .. "House")
        
        if not MyHouse then
            SendNotification("Erro", "Falha ao criar casa!")
            RootPart.CFrame = OldPos
            return
        end
        
        SendNotification("House Ban", "Casa pronta!")
        
        local HouseSpawn = MyHouse:FindFirstChild("HouseSpawnPosition")
        if not HouseSpawn then
            SendNotification("Erro", "Spawn não encontrado!")
            return
        end
        
        RootPart.CFrame = CFrame.new(HouseSpawn.Position) + Vector3.new(0, 3, 0)
        task.wait(0.5)
        
        SendNotification("House Ban", "Iniciando Bring com Couch...")
        
        pcall(function()
            ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer("ClearAllTools")
        end)
        task.wait(0.3)
        
        pcall(function()
            ReplicatedStorage.RE:FindFirstChild("1Too1l"):InvokeServer("PickingTools", "Couch")
        end)
        task.wait(0.5)

        local couch = LocalPlayer.Backpack:WaitForChild("Couch", 3)
        if not couch then
            SendNotification("Erro", "Sofá não encontrado")
            RootPart.CFrame = OldPos
            return
        end

        couch.Name = "HouseBan.Couch"
        local seat1 = couch:FindFirstChild("Seat1")
        local seat2 = couch:FindFirstChild("Seat2")
        local handle = couch:FindFirstChild("Handle")
        
        if not (seat1 and seat2 and handle) then
            SendNotification("Erro", "Componentes do sofá não encontrados")
            return
        end
        
        seat1.Disabled = true
        seat2.Disabled = true
        handle.Name = "Handle "
        
        couch.Parent = LocalPlayer.Character
        task.wait(0.2)

        local tet = Instance.new("BodyVelocity", seat1)
        tet.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        tet.P = 1250
        tet.Velocity = Vector3.new(0, 0, 0)
        tet.Name = "#HOUSEBANBRING"

        SendNotification("House Ban", "Trazendo " .. selectedPlayer.Name .. "...")
        
        local bringAttempts = 0
        local maxBringAttempts = 3
        
        repeat
            for m = 1, 35 do
                local tRoot = selectedPlayer.Character and selectedPlayer.Character.HumanoidRootPart
                if not tRoot then break end
                
                local pos = {
                    x = tRoot.Position.X + (tRoot.Velocity.X / 2),
                    y = tRoot.Position.Y + (tRoot.Velocity.Y / 2),
                    z = tRoot.Position.Z + (tRoot.Velocity.Z / 2)
                }
                
                seat1.CFrame = CFrame.new(Vector3.new(pos.x, pos.y, pos.z)) * CFrame.new(-2, 2, 0)
                task.wait()
            end
            
            tet:Destroy()
            couch.Parent = LocalPlayer.Backpack
            task.wait()
            couch:FindFirstChild("Handle ").Name = "Handle"
            task.wait(0.2)
            couch.Parent = LocalPlayer.Character
            task.wait()
            couch.Parent = LocalPlayer.Backpack
            couch.Handle.Name = "Handle "
            task.wait(0.2)
            couch.Parent = LocalPlayer.Character
            
            tet = Instance.new("BodyVelocity", seat1)
            tet.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            tet.P = 1250
            tet.Velocity = Vector3.new(0, 0, 0)
            tet.Name = "#HOUSEBANBRING"
            
            bringAttempts = bringAttempts + 1
            
        until (selectedPlayer.Character and selectedPlayer.Character.Humanoid and selectedPlayer.Character.Humanoid.Sit == true) or bringAttempts >= maxBringAttempts

        task.wait()
        if tet then tet:Destroy() end
        couch.Parent = LocalPlayer.Backpack
        task.wait()
        if couch:FindFirstChild("Handle ") then
            couch:FindFirstChild("Handle ").Name = "Handle"
        end
        task.wait(0.3)
        couch.Parent = LocalPlayer.Character
        task.wait(0.3)
        couch.Grip = CFrame.new(Vector3.new(0, 0, 0))
        task.wait(0.3)
        pcall(function()
            ReplicatedStorage.RE["1Clea1rTool1s"]:FireServer("ClearAllTools")
        end)
        
        SendNotification("House Ban", "Bring finalizado! Aguardando alvo...")
        
        local HouseModel = MyHouse:FindFirstChild("HousePickedByPlayer")
        if HouseModel then
            HouseModel = HouseModel:FindFirstChild("HouseModel")
        end
        
        if not HouseModel then
            SendNotification("Erro", "HouseModel não encontrado!")
            RootPart.CFrame = OldPos
            return
        end
        
        local DisallowRemote = HouseModel:FindFirstChild("Permissions:Disallow")
        if not DisallowRemote then
            SendNotification("Erro", "Remote de ban não encontrado!")
            RootPart.CFrame = OldPos
            return
        end
        
        local bannedSuccessfully = false
        local startDetection = tick()
        local maxDetectionTime = 30
        
        while not bannedSuccessfully and (tick() - startDetection) < maxDetectionTime do
            if RootPart then
                RootPart.CFrame = CFrame.new(HouseSpawn.Position) + Vector3.new(0, 3, 0)
            end
            
            if selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = selectedPlayer.Character.HumanoidRootPart
                local distance = (targetHRP.Position - HouseSpawn.Position).Magnitude
                
                if distance < 50 then
                    SendNotification("House Ban", "ALVO NA CASA! Banindo...")
                    
                    pcall(function()
                        local args = {selectedPlayer}
                        DisallowRemote:FireServer(unpack(args))
                    end)
                    
                    task.wait(1)
                    
                    if selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local newDistance = (selectedPlayer.Character.HumanoidRootPart.Position - HouseSpawn.Position).Magnitude
                        if newDistance > 80 then
                            bannedSuccessfully = true
                            SendNotification("SUCESSO!", selectedPlayer.Name .. " FOI BANIDO DA CASA!")
                        else
                            pcall(function()
                                DisallowRemote:FireServer(selectedPlayer)
                            end)
                        end
                    else
                        bannedSuccessfully = true
                        SendNotification("SUCESSO!", selectedPlayer.Name .. " foi removido!")
                    end
                    
                    if bannedSuccessfully then
                        break
                    end
                end
            end
            
            task.wait(0.3)
        end
        
        if not bannedSuccessfully then
            SendNotification("House Ban", "⏱️ Timeout - Alvo não entrou a tempo")
        end
        
        task.wait(1)
        ClearAllTools()
        
        task.wait(0.5)
        if RootPart then
            RootPart.CFrame = OldPos
        end
        
        SendNotification("House Ban", "Processo finalizado!")
    end
})

-- ========================================
-- BOTÕES
-- ========================================
flingsTab:AddButton({
    Name = "Kill",
    Callback = function()
        if not selectedPlayerName or selectedPlayerName == "" then
            SendNotification("Erro", "Selecione um jogador")
            return
        end
        
        local target = Players:FindFirstChild(selectedPlayerName)
        if not target then
            SendNotification("Erro", "Jogador não encontrado")
            return
        end
        
        -- VERIFICAÇÃO DE SEAT REMOVIDA - Agora funciona sempre
        
        if selectedMethod == "Ball" then
            FlingBall(target)
        elseif selectedMethod == "Couch" then
            KillCouch(target)
        elseif selectedMethod == "Boat" then
            KillVehicle(target, "Boat")
        elseif selectedMethod == "PoliceBoat" then
            KillVehicle(target, "PoliceBoat")
        elseif selectedMethod == "Bus" then
            KillVehicle(target, "Bus")
        elseif selectedMethod == "TowTruck" then
            KillVehicle(target, "TowTruck")
        end
    end
})

flingsTab:AddButton({
    Name = "Bring",
    Callback = function()
        if not selectedPlayerName or selectedPlayerName == "" then
            SendNotification("Erro", "Selecione um jogador")
            return
        end
        
        local target = Players:FindFirstChild(selectedPlayerName)
        if not target then
            SendNotification("Erro", "Jogador não encontrado")
            return
        end
        
        SendNotification("Iniciando", "Trazendo " .. target.Name .. "...")
        
        if selectedMethod == "Couch" then
            BringCouch(target)
        elseif selectedMethod == "Boat" then
            BringVehicle(target, "Boat")
        elseif selectedMethod == "PoliceBoat" then
            BringVehicle(target, "PoliceBoat")
        elseif selectedMethod == "Bus" then
            BringVehicle(target, "Bus")
        elseif selectedMethod == "TowTruck" then
            BringVehicle(target, "TowTruck")
        else
            SendNotification("Erro", "Método não suporta Bring")
        end
    end
})

flingsTab:AddButton({
    Name = "Go To",
    Callback = function()
        if not selectedPlayerName then return end
        local target = Players:FindFirstChild(selectedPlayerName)
        if target and target.Character then
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if myHRP and targetHRP then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end
})

-- ========================================
-- VIEW COM PERSISTÊNCIA TOTAL
-- ========================================
local viewActive = false
local viewConnection

flingsTab:AddToggle({
    Name = "View",
    Default = false,
    Callback = function(value)
        viewActive = value
        
        if value then
            if not lockedTarget or lockedTarget == "" then
                SendNotification("View", "ERRO: Selecione um alvo primeiro!")
                viewActive = false
                return
            end
            
            SendNotification("View", "Ativado em " .. lockedTarget)
            
            -- Loop FORÇADO que mantém o view sempre ativo
            viewConnection = RunService.Heartbeat:Connect(function()
                if not viewActive then return end
                
                local target = Players:FindFirstChild(lockedTarget)
                if target and target.Character then
                    local hum = target.Character:FindFirstChild("Humanoid")
                    if hum then
                        workspace.CurrentCamera.CameraSubject = hum
                    end
                end
            end)
        else
            -- Desativa o view
            if viewConnection then
                viewConnection:Disconnect()
                viewConnection = nil
            end
            
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    workspace.CurrentCamera.CameraSubject = hum
                end
            end
            SendNotification("View", "Desativado")
        end
    end
})

-- ========================================
-- AUTO FLING COM ALVO TRAVADO
-- ========================================
local autoFlingActive = false

flingsTab:AddToggle({
    Name = "Auto Fling",
    Default = false,
    Callback = function(value)
        autoFlingActive = value
        
        if value then
            -- Verifica se há alvo travado
            if not lockedTarget or lockedTarget == "" then
                SendNotification("Auto Fling", "ERRO: Selecione um alvo primeiro!")
                autoFlingActive = false
                return
            end
            
            local target = Players:FindFirstChild(lockedTarget)
            if not target then
                SendNotification("Auto Fling", "ERRO: Alvo não está no servidor!")
                autoFlingActive = false
                return
            end
            
            SendNotification("Auto Fling", "ATIVADO - Alvo: " .. lockedTarget)
            
            -- Loop infinito
            task.spawn(function()
                while autoFlingActive do
                    task.wait(1)
                    
                    -- Usa o alvo travado
                    if not lockedTarget or lockedTarget == "" then
                        SendNotification("Auto Fling", "Alvo perdido")
                        autoFlingActive = false
                        break
                    end
                    
                    local currentTarget = Players:FindFirstChild(lockedTarget)
                    
                    if not currentTarget then
                        SendNotification("Auto Fling", lockedTarget .. " saiu do jogo")
                        autoFlingActive = false
                        break
                    end
                    
                    -- Aguarda personagens
                    local waitTime = 0
                    while (not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and waitTime < 10 do
                        task.wait(0.5)
                        waitTime = waitTime + 0.5
                    end
                    
                    if not LocalPlayer.Character or not currentTarget.Character then
                        continue
                    end
                    
                    if not currentTarget.Character:FindFirstChild("HumanoidRootPart") then
                        continue
                    end
                    
                    -- Executa fling
                    pcall(function()
                        if selectedMethod == "Ball" then
                            FlingBall(currentTarget)
                            task.wait(2)
                            
                        elseif selectedMethod == "Couch" then
                            if not IsPlayerSitting(currentTarget) then
                                KillCouch(currentTarget)
                            end
                            task.wait(3)
                            
                        elseif selectedMethod == "Boat" then
                            if not IsPlayerSitting(currentTarget) then
                                KillVehicle(currentTarget, "Boat")
                            end
                            task.wait(5)
                            
                        elseif selectedMethod == "PoliceBoat" then
                            if not IsPlayerSitting(currentTarget) then
                                KillVehicle(currentTarget, "PoliceBoat")
                            end
                            task.wait(5)
                            
                        elseif selectedMethod == "Bus" then
                            if not IsPlayerSitting(currentTarget) then
                                KillVehicle(currentTarget, "Bus")
                            end
                            task.wait(5)
                            
                        elseif selectedMethod == "TowTruck" then
                            if not IsPlayerSitting(currentTarget) then
                                KillVehicle(currentTarget, "TowTruck")
                            end
                            task.wait(5)
                        end
                    end)
                end
            end)
        else
            SendNotification("Auto Fling", "Desativado")
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    if autoFlingActive then
        task.wait(2)
        SendNotification("Auto Fling", "Continuando...")
    end
end)

print("")

flingsTab:AddSection({ "Clicks" })

flingsTab:AddButton({
  Name = "Click Fling Portas",
Description = "",
  Callback = function()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

-- Alvo invisível (BlackHole)
local BlackHole = Instance.new("Part")
BlackHole.Size = Vector3.new(100000, 100000, 100000)
BlackHole.Transparency = 1
BlackHole.Anchored = true
BlackHole.CanCollide = false
BlackHole.Name = "BlackHoleTarget"
BlackHole.Parent = Workspace

-- Attachment base no BlackHole
local baseAttachment = Instance.new("Attachment")
baseAttachment.Name = "Luscaa_BlackHoleAttachment"
baseAttachment.Parent = BlackHole

-- Atualiza posição do BlackHole
RunService.Heartbeat:Connect(function()
	BlackHole.CFrame = HRP.CFrame
end)

-- Lista de portas controladas
local ControlledDoors = {}

-- Prepara uma porta para ser controlada
local function SetupPart(part)
	if not part:IsA("BasePart") or part.Anchored or not string.find(part.Name, "Door") then return end
	if part:FindFirstChild("Luscaa_Attached") then return end

	part.CanCollide = false

	for _, obj in ipairs(part:GetChildren()) do
		if obj:IsA("AlignPosition") or obj:IsA("Torque") or obj:IsA("Attachment") then
			obj:Destroy()
		end
	end

	local marker = Instance.new("BoolValue", part)
	marker.Name = "Luscaa_Attached"

	local a1 = Instance.new("Attachment", part)

	local align = Instance.new("AlignPosition", part)
	align.Attachment0 = a1
	align.Attachment1 = baseAttachment
	align.MaxForce = 1e20
	align.MaxVelocity = math.huge
	align.Responsiveness = 99999

	local torque = Instance.new("Torque", part)
	torque.Attachment0 = a1
	torque.RelativeTo = Enum.ActuatorRelativeTo.World
	torque.Torque = Vector3.new(
		math.random(-10e5, 10e5) * 10000,
		math.random(-10e5, 10e5) * 10000,
		math.random(-10e5, 10e5) * 10000
	)

	table.insert(ControlledDoors, {Part = part, Align = align})
end

-- Detecta e prepara portas existentes
for _, obj in ipairs(Workspace:GetDescendants()) do
	if obj:IsA("BasePart") and string.find(obj.Name, "Door") then
		SetupPart(obj)
	end
end

-- Novas portas no futuro
Workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("BasePart") and string.find(obj.Name, "Door") then
		SetupPart(obj)
	end
end)

-- Flinga jogador com timeout e retorno
local function FlingPlayer(player)
	local char = player.Character
	if not char then return end
	local targetHRP = char:FindFirstChild("HumanoidRootPart")
	if not targetHRP then return end

	local targetAttachment = targetHRP:FindFirstChild("SHNMAX_TargetAttachment")
	if not targetAttachment then
		targetAttachment = Instance.new("Attachment", targetHRP)
		targetAttachment.Name = "SHNMAX_TargetAttachment"
	end

	for _, data in ipairs(ControlledDoors) do
		if data.Align then
			data.Align.Attachment1 = targetAttachment
		end
	end

	local start = tick()
	local flingDetected = false

	while tick() - start < 5 do
		if targetHRP.Velocity.Magnitude >= 20 then
			flingDetected = true
			break
		end
		RunService.Heartbeat:Wait()
	end

	-- Sempre retorna as portas
	for _, data in ipairs(ControlledDoors) do
		if data.Align then
			data.Align.Attachment1 = baseAttachment
		end
	end
end

-- Clique (funciona no mobile)
UserInputService.TouchTap:Connect(function(touchPositions, processed)
	if processed then return end
	local pos = touchPositions[1]
	local camera = Workspace.CurrentCamera
	local unitRay = camera:ScreenPointToRay(pos.X, pos.Y)
	local raycast = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000)

	if raycast and raycast.Instance then
		local hit = raycast.Instance
		local player = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
		if player and player ~= LocalPlayer then
			FlingPlayer(player)
		end
	end
end)
  end
})

flingsTab:AddButton({
    Name = "Click Fling Ball",
    Callback = function()
local jogadores = game:GetService("Players")
local rep = game:GetService("ReplicatedStorage")
local mundo = game:GetService("Workspace")
local entrada = game:GetService("UserInputService")
local cam = mundo.CurrentCamera
local eu = jogadores.LocalPlayer

local NOME_FERRAMENTA = "Click Fling Ball"
local ferramentaEquipada = false

local mochila = eu:WaitForChild("Backpack")
if not mochila:FindFirstChild(NOME_FERRAMENTA) then
	local ferramenta = Instance.new("Tool")
	ferramenta.Name = NOME_FERRAMENTA
	ferramenta.RequiresHandle = false
	ferramenta.CanBeDropped = false

	ferramenta.Equipped:Connect(function()
		ferramentaEquipada = true
	end)

	ferramenta.Unequipped:Connect(function()
		ferramentaEquipada = false
	end)

	ferramenta.Parent = mochila
end

-- Função FlingBall (bola)
local function FlingBall(target)
    

    local players = game:GetService("Players")
    local player = players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    local backpack = player:WaitForChild("Backpack")
    local ServerBalls = workspace.WorkspaceCom:WaitForChild("001_SoccerBalls")

    local function GetBall()
        if not backpack:FindFirstChild("SoccerBall") and not character:FindFirstChild("SoccerBall") then
            game:GetService("ReplicatedStorage").RE:FindFirstChild("1Too1l"):InvokeServer("PickingTools", "SoccerBall")
        end

        repeat task.wait() until backpack:FindFirstChild("SoccerBall") or character:FindFirstChild("SoccerBall")

        local ballTool = backpack:FindFirstChild("SoccerBall")
        if ballTool then
            ballTool.Parent = character
        end

        repeat task.wait() until ServerBalls:FindFirstChild("Soccer" .. player.Name)

        return ServerBalls:FindFirstChild("Soccer" .. player.Name)
    end

    local Ball = ServerBalls:FindFirstChild("Soccer" .. player.Name) or GetBall()
    Ball.CanCollide = false
    Ball.Massless = true
    Ball.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0, 0)

    if target ~= player then
        local tchar = target.Character
        if tchar and tchar:FindFirstChild("HumanoidRootPart") and tchar:FindFirstChild("Humanoid") then
            local troot = tchar.HumanoidRootPart
            local thum = tchar.Humanoid

            if Ball:FindFirstChildWhichIsA("BodyVelocity") then
                Ball:FindFirstChildWhichIsA("BodyVelocity"):Destroy()
            end

            local bv = Instance.new("BodyVelocity")
            bv.Name = "FlingPower"
            bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.P = 9e900
            bv.Parent = Ball

            workspace.CurrentCamera.CameraSubject = thum

            repeat
                if troot.Velocity.Magnitude > 0 then
                    local pos = troot.Position + (troot.Velocity / 1.5)
                    Ball.CFrame = CFrame.new(pos)
                    Ball.Orientation += Vector3.new(45, 60, 30)
                else
                    for i, v in pairs(tchar:GetChildren()) do
                        if v:IsA("BasePart") and v.CanCollide and not v.Anchored then
                            Ball.CFrame = v.CFrame
                            task.wait(1/6000)
                        end
                    end
                end
                task.wait(1/6000)
            until troot.Velocity.Magnitude > 1000 or thum.Health <= 0 or not tchar:IsDescendantOf(workspace) or target.Parent ~= players

            workspace.CurrentCamera.CameraSubject = humanoid
        end
    end
end

-- Toque na tela para aplicar a bola
entrada.TouchTap:Connect(function(toques, processado)
	if not ferramentaEquipada or processado then return end
	local pos = toques[1]
	local raio = cam:ScreenPointToRay(pos.X, pos.Y)
	local hit = mundo:Raycast(raio.Origin, raio.Direction * 1000)
	if hit and hit.Instance then
		local modelo = hit.Instance:FindFirstAncestorOfClass("Model")
		local jogador = jogadores:GetPlayerFromCharacter(modelo)
		if jogador and jogador ~= eu then
			FlingBall(jogador)
		end
	end
end)

end
})

flingsTab:AddButton({
    Name = "Click Kill Couch",
    Callback = function()

local jogadores = game:GetService("Players")
local rep = game:GetService("ReplicatedStorage")
local loop = game:GetService("RunService")
local mundo = game:GetService("Workspace")
local entrada = game:GetService("UserInputService")

local eu = jogadores.LocalPlayer
local cam = mundo.CurrentCamera

local NOME_FERRAMENTA = "Click Kill Couch"
local ferramentaEquipada = false
local nomeAlvo = nil
local loopTP = nil
local sofaEquipado = false
local base = nil
local posInicial = nil
local raiz = nil

local mochila = eu:WaitForChild("Backpack")
if not mochila:FindFirstChild(NOME_FERRAMENTA) then
	local ferramenta = Instance.new("Tool")
	ferramenta.Name = NOME_FERRAMENTA
	ferramenta.RequiresHandle = false
	ferramenta.CanBeDropped = false

	ferramenta.Equipped:Connect(function()
		ferramentaEquipada = true
	end)

	ferramenta.Unequipped:Connect(function()
		ferramentaEquipada = false
		nomeAlvo = nil
		limparSofa()
	end)

	ferramenta.Parent = mochila
end

function limparSofa()
	if loopTP then
		loopTP:Disconnect()
		loopTP = nil
	end

	if sofaEquipado then
		local boneco = eu.Character
		if boneco then
			local sofa = boneco:FindFirstChild("Couch")
			if sofa then
				sofa.Parent = eu.Backpack
				sofaEquipado = false
			end
		end
	end

	if base then
		base:Destroy()
		base = nil
	end

	if getgenv().AntiSit then
		getgenv().AntiSit:Set(false)
	end

	local humano = eu.Character and eu.Character:FindFirstChildOfClass("Humanoid")
	if humano then
		humano:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
		humano:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	if posInicial and raiz then
		raiz.CFrame = posInicial
		posInicial = nil
	end
end

function pegarSofa()
	local boneco = eu.Character
	if not boneco then return end
	local mochila = eu.Backpack

	if not mochila:FindFirstChild("Couch") and not boneco:FindFirstChild("Couch") then
		local args = { "PickingTools", "Couch" }
		rep.RE["1Too1l"]:InvokeServer(unpack(args))
		task.wait(0.1)
	end

	local sofa = mochila:FindFirstChild("Couch") or boneco:FindFirstChild("Couch")
	if sofa then
		sofa.Parent = boneco
		sofaEquipado = true
	end
end

function posAleatoriaAbaixo(boneco)
	local rp = boneco:FindFirstChild("HumanoidRootPart")
	if not rp then return Vector3.new() end
	local offset = Vector3.new(math.random(-2, 2), -5.1, math.random(-2, 2))
	return rp.Position + offset
end

function tpAbaixo(alvo)
	if not alvo or not alvo.Character or not alvo.Character:FindFirstChild("HumanoidRootPart") then return end

	local meuBoneco = eu.Character
	local minhaRaiz = meuBoneco and meuBoneco:FindFirstChild("HumanoidRootPart")
	local humano = meuBoneco and meuBoneco:FindFirstChildOfClass("Humanoid")

	if not minhaRaiz or not humano then return end

	humano:SetStateEnabled(Enum.HumanoidStateType.Physics, false)

	if not base then
		base = Instance.new("Part")
		base.Size = Vector3.new(10, 1, 10)
		base.Anchored = true
		base.CanCollide = true
		base.Transparency = 0.5
		base.Parent = mundo
	end

	local destino = posAleatoriaAbaixo(alvo.Character)
	base.Position = destino
	minhaRaiz.CFrame = CFrame.new(destino)

	humano:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
end

function arremessarComSofa(alvo)
	if not alvo then return end
	nomeAlvo = alvo.Name
	local boneco = eu.Character
	if not boneco then return end

	posInicial = boneco:FindFirstChild("HumanoidRootPart") and boneco.HumanoidRootPart.CFrame
	raiz = boneco:FindFirstChild("HumanoidRootPart")
	pegarSofa()

	loopTP = loop.Heartbeat:Connect(function()
		local alvoAtual = jogadores:FindFirstChild(nomeAlvo)
		if not alvoAtual or not alvoAtual.Character or not alvoAtual.Character:FindFirstChild("Humanoid") then
			limparSofa()
			return
		end
		if getgenv().AntiSit then
			getgenv().AntiSit:Set(true)
		end
		tpAbaixo(alvoAtual)
	end)

	task.spawn(function()
		local alvoAtual = jogadores:FindFirstChild(nomeAlvo)
		while alvoAtual and alvoAtual.Character and alvoAtual.Character:FindFirstChild("Humanoid") do
			task.wait(0.05)
			if alvoAtual.Character.Humanoid.SeatPart then
				local buraco = CFrame.new(265.46, -450.83, -59.93)
				alvoAtual.Character.HumanoidRootPart.CFrame = buraco
				eu.Character.HumanoidRootPart.CFrame = buraco
				task.wait(0.4)
				limparSofa()
				task.wait(0.2)
				if posInicial then
					eu.Character.HumanoidRootPart.CFrame = posInicial
				end
				break
			end
		end
	end)
end

entrada.TouchTap:Connect(function(toques, processado)
	if not ferramentaEquipada or processado then return end
	local pos = toques[1]
	local raio = cam:ScreenPointToRay(pos.X, pos.Y)
	local hit = mundo:Raycast(raio.Origin, raio.Direction * 1000)
	if hit and hit.Instance then
		local modelo = hit.Instance:FindFirstAncestorOfClass("Model")
		local jogador = jogadores:GetPlayerFromCharacter(modelo)
		if jogador and jogador ~= eu then
			arremessarComSofa(jogador)
		end
	end
end)
end
})

flingsTab:AddButton({
    Name = "Click Kill Bus",
    Callback = function()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local TOOL_NAME = "Click Kill Bus"
local toolEquipped = false
local currentTarget = nil
local flingActive = false

-- ========================================
-- FUNÇÕES AUXILIARES
-- ========================================

local function SendNotification(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

local function IsPlayerSitting(player)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Sit
end

local function DeleteAllVehicles()
    local Vehicles = Workspace:FindFirstChild("Vehicles")
    if not Vehicles then return end
    
    for _, vehicle in pairs(Vehicles:GetChildren()) do
        if vehicle.Name:find(LocalPlayer.Name .. "Car") then
            pcall(function() vehicle:Destroy() end)
        end
    end
end

-- ========================================
-- CRIAR FERRAMENTA
-- ========================================

local backpack = LocalPlayer:WaitForChild("Backpack")
if not backpack:FindFirstChild(TOOL_NAME) then
    local tool = Instance.new("Tool")
    tool.Name = TOOL_NAME
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    tool.Equipped:Connect(function()
        toolEquipped = true
        SendNotification("Click Kill Bus", "Clique em um jogador para eliminar")
    end)

    tool.Unequipped:Connect(function()
        toolEquipped = false
        currentTarget = nil
    end)

    tool.Parent = backpack
end

-- ========================================
-- FUNÇÃO PRINCIPAL - KILL BUS
-- ========================================

local function KillBusTarget(target)
    if flingActive then
        SendNotification("Aguarde", "Fling já está ativo!")
        return
    end
    
    if IsPlayerSitting(target) then
        SendNotification("Fling Bloqueado", "Jogador está sentado!")
        return
    end
    
    flingActive = true
    currentTarget = target
    
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not humanoidRootPart or not humanoid then
        flingActive = false
        return
    end
    
    local originalPosition = humanoidRootPart.CFrame
    local Vehicles = Workspace:FindFirstChild("Vehicles")
    
    -- Spawna ônibus
    SendNotification("Preparando", "Invocando ônibus...")
    humanoidRootPart.CFrame = CFrame.new(1118.81, 75.998, -1138.61)
    task.wait(0.5)
    
    pcall(function()
        local args = {"PickingCar", "SchoolBus"}
        ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer(unpack(args))
    end)
    
    task.wait(1.5)
    
    local vehicle = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
    if not vehicle then
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Falha ao spawnar ônibus")
        flingActive = false
        return
    end
    
    -- Encontra assento
    local seat = vehicle:FindFirstChild("Seats") and vehicle.Seats:FindFirstChild("VehicleSeat")
    if not seat then
        seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("VehicleSeat")
    end
    
    if not seat then
        DeleteAllVehicles()
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Assento não encontrado")
        flingActive = false
        return
    end
    
    -- Senta no ônibus
    local attempts = 0
    repeat
        humanoidRootPart.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.1)
        attempts = attempts + 1
    until humanoid.Sit or attempts > 50 or not vehicle.Parent
    
    if not humanoid.Sit then
        DeleteAllVehicles()
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Não foi possível sentar no ônibus")
        flingActive = false
        return
    end
    
    SendNotification("Iniciando", "Fling ativado!")
    
    -- Desativa colisão
    for _, container in pairs({vehicle:FindFirstChild("Body"), vehicle:FindFirstChild("Seats")}) do
        if container then
            for _, v in pairs(container:GetChildren()) do
                if v:IsA("Seat") or v:IsA("VehicleSeat") then
                    v.CanTouch = false
                end
            end
        end
    end
    
    Workspace.FallenPartsDestroyHeight = 0/0
    
    local targetInVoid = false
    local flingLoop = true
    
    -- Loop do fling
    task.spawn(function()
        local startTime = tick()
        local maxTime = 20
        
        while flingLoop and vehicle and vehicle.Parent do
            local targetChar = target.Character
            if not targetChar then break end
            
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then break end
            
            -- Verifica void
            if targetRoot.Position.Y < -100 then
                targetInVoid = true
                break
            end
            
            -- Verifica se sentou
            if targetHumanoid.Sit then
                pcall(function()
                    vehicle:SetPrimaryPartCFrame(CFrame.new(9999, -450, 9999))
                end)
                targetInVoid = true
                task.wait(0.3)
                break
            end
            
            -- Movimento circular do ônibus
            local time = tick() * 35
            local lateralOffset = math.sin(time) * 4
            local frontBackOffset = math.cos(time) * 20
            pcall(function()
                vehicle:SetPrimaryPartCFrame(targetRoot.CFrame * CFrame.new(lateralOffset, 0, frontBackOffset))
            end)
            
            if tick() - startTime > maxTime then break end
            RunService.RenderStepped:Wait()
        end
        flingLoop = false
    end)
    
    -- Aguarda finalização
    while flingLoop do task.wait(0.1) end
    
    -- Retorna à posição original
    task.wait(0.3)
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    task.wait(0.7)
    if humanoidRootPart then
        humanoidRootPart.CFrame = originalPosition
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    
    task.wait(0.5)
    DeleteAllVehicles()
    Workspace.FallenPartsDestroyHeight = -500
    
    if targetInVoid then
        SendNotification("Sucesso", "Kill executado!")
    else
        SendNotification("Concluído", "Fling finalizado")
    end
    
    flingActive = false
    currentTarget = nil
end

-- ========================================
-- DETECÇÃO DE CLIQUE
-- ========================================

UserInputService.TouchTap:Connect(function(touches, processed)
    if not toolEquipped or processed or flingActive then return end
    
    local pos = touches[1]
    local ray = Camera:ScreenPointToRay(pos.X, pos.Y)
    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000)
    
    if raycastResult and raycastResult.Instance then
        local model = raycastResult.Instance:FindFirstAncestorOfClass("Model")
        local player = Players:GetPlayerFromCharacter(model)
        
        if player and player ~= LocalPlayer then
            KillBusTarget(player)
        end
    end
end)

-- Suporte para mouse (PC)
UserInputService.InputBegan:Connect(function(input, processed)
    if not toolEquipped or processed or flingActive then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
        local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000)
        
        if raycastResult and raycastResult.Instance then
            local model = raycastResult.Instance:FindFirstAncestorOfClass("Model")
            local player = Players:GetPlayerFromCharacter(model)
            
            if player and player ~= LocalPlayer then
                KillBusTarget(player)
            end
        end
    end
end)

SendNotification("Click Kill Bus", "Ferramenta criada! Equipe e clique em jogadores")

    end
})

flingsTab:AddButton({
    Name = "Click Kill Police Boat",
    Callback = function()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local TOOL_NAME = "Click Kill Police Boat"
local toolEquipped = false
local currentTarget = nil
local flingActive = false

-- ========================================
-- FUNÇÕES AUXILIARES
-- ========================================

local function SendNotification(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

local function IsPlayerSitting(player)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Sit
end

local function DeleteAllVehicles()
    local Vehicles = Workspace:FindFirstChild("Vehicles")
    if not Vehicles then return end
    
    for _, vehicle in pairs(Vehicles:GetChildren()) do
        if vehicle.Name:find(LocalPlayer.Name .. "Car") then
            pcall(function() vehicle:Destroy() end)
        end
    end
end

-- ========================================
-- CRIAR FERRAMENTA
-- ========================================

local backpack = LocalPlayer:WaitForChild("Backpack")
if not backpack:FindFirstChild(TOOL_NAME) then
    local tool = Instance.new("Tool")
    tool.Name = TOOL_NAME
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    tool.Equipped:Connect(function()
        toolEquipped = true
        SendNotification("Click Kill Police Boat", "Clique em um jogador para eliminar")
    end)

    tool.Unequipped:Connect(function()
        toolEquipped = false
        currentTarget = nil
    end)

    tool.Parent = backpack
end

-- ========================================
-- FUNÇÃO PRINCIPAL - KILL POLICE BOAT
-- ========================================

local function KillPoliceBoatTarget(target)
    if flingActive then
        SendNotification("Aguarde", "Fling já está ativo!")
        return
    end
    
    if IsPlayerSitting(target) then
        SendNotification("Fling Bloqueado", "Jogador está sentado!")
        return
    end
    
    flingActive = true
    currentTarget = target
    
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not humanoidRootPart or not humanoid then
        flingActive = false
        return
    end
    
    local originalPosition = humanoidRootPart.CFrame
    local Vehicles = Workspace:FindFirstChild("Vehicles")
    
    -- Spawna Police Boat
    SendNotification("Preparando", "Invocando Police Boat...")
    humanoidRootPart.CFrame = CFrame.new(1754, -2, 58)
    task.wait(0.5)
    
    pcall(function()
        local args = {"PickingBoat", "PoliceBoatChangeable"}
        ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer(unpack(args))
    end)
    
    task.wait(1.5)
    
    local vehicle = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
    if not vehicle then
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Falha ao spawnar Police Boat")
        flingActive = false
        return
    end
    
    -- Encontra assento
    local seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("VehicleSeat")
    
    if not seat then
        DeleteAllVehicles()
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Assento não encontrado")
        flingActive = false
        return
    end
    
    -- Senta no Police Boat
    local attempts = 0
    repeat
        humanoidRootPart.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.1)
        attempts = attempts + 1
    until humanoid.Sit or attempts > 50 or not vehicle.Parent
    
    if not humanoid.Sit then
        DeleteAllVehicles()
        humanoidRootPart.CFrame = originalPosition
        SendNotification("Erro", "Não foi possível sentar no Police Boat")
        flingActive = false
        return
    end
    
    SendNotification("Iniciando", "Fling ativado com spin!")
    
    -- Desativa colisão
    for _, container in pairs({vehicle:FindFirstChild("Body"), vehicle:FindFirstChild("Seats")}) do
        if container then
            for _, v in pairs(container:GetChildren()) do
                if v:IsA("Seat") or v:IsA("VehicleSeat") then
                    v.CanTouch = false
                end
            end
        end
    end
    
    Workspace.FallenPartsDestroyHeight = 0/0
    
    -- Cria spin rotacional
    local Spin = Instance.new("BodyAngularVelocity")
    Spin.Parent = vehicle.PrimaryPart
    Spin.MaxTorque = Vector3.new(0, math.huge, 0)
    Spin.AngularVelocity = Vector3.new(0, 200, 0)
    
    local targetInVoid = false
    local flingLoop = true
    
    -- Loop do fling
    task.spawn(function()
        local startTime = tick()
        local maxTime = 15
        
        while flingLoop and vehicle and vehicle.Parent do
            local targetChar = target.Character
            if not targetChar then break end
            
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then break end
            
            -- Verifica void
            if targetRoot.Position.Y < -100 then
                targetInVoid = true
                break
            end
            
            -- Verifica se sentou
            if targetHumanoid.Sit then
                pcall(function()
                    vehicle:SetPrimaryPartCFrame(CFrame.new(9999, -450, 9999))
                end)
                targetInVoid = true
                task.wait(0.3)
                break
            end
            
            -- Movimento adaptativo do Police Boat
            local angle = (tick() - startTime) * 50
            
            if targetRoot.Velocity.Magnitude < 50 then
                -- Padrão para alvos parados/lentos
                local movePatterns = {
                    {pos = CFrame.new(0, 1.5, 0) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 2, rot = CFrame.Angles(math.rad(angle), 0, 0)},
                    {pos = CFrame.new(0, -1.5, 0) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 2, rot = CFrame.Angles(math.rad(angle), 0, 0)},
                    {pos = CFrame.new(1.5, 1.5, -1.5) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 2, rot = CFrame.Angles(math.rad(angle), 0, 0)},
                    {pos = CFrame.new(-1.5, -1.5, 1.5) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 2, rot = CFrame.Angles(math.rad(angle), 0, 0)},
                }
                
                for _, pattern in ipairs(movePatterns) do
                    if not flingLoop then break end
                    pcall(function()
                        vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * pattern.pos * pattern.rot)
                    end)
                    task.wait(0.1)
                end
            else
                -- Padrão para alvos em movimento rápido
                local speedPatterns = {
                    CFrame.new(0, 1.5, targetHumanoid.WalkSpeed),
                    CFrame.new(0, -1.5, -targetHumanoid.WalkSpeed),
                    CFrame.new(0, 1.5, targetRoot.Velocity.Magnitude / 2),
                    CFrame.new(0, -1.5, -targetRoot.Velocity.Magnitude / 2),
                }
                
                for _, offset in ipairs(speedPatterns) do
                    if not flingLoop then break end
                    pcall(function()
                        vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * offset * CFrame.Angles(math.rad(90), 0, 0))
                    end)
                    task.wait(0.1)
                end
            end
            
            task.wait(0.05)
            
            if tick() - startTime > maxTime then break end
            RunService.RenderStepped:Wait()
        end
        flingLoop = false
    end)
    
    -- Aguarda finalização
    while flingLoop do task.wait(0.1) end
    
    -- Remove spin
    if Spin then
        Spin:Destroy()
    end
    
    -- Retorna à posição original
    task.wait(0.3)
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    task.wait(0.7)
    if humanoidRootPart then
        humanoidRootPart.CFrame = originalPosition
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    
    task.wait(0.5)
    DeleteAllVehicles()
    Workspace.FallenPartsDestroyHeight = -500
    
    if targetInVoid then
        SendNotification("Sucesso", "Kill executado!")
    else
        SendNotification("Concluído", "Fling finalizado")
    end
    
    flingActive = false
    currentTarget = nil
end

-- ========================================
-- DETECÇÃO DE CLIQUE
-- ========================================

UserInputService.TouchTap:Connect(function(touches, processed)
    if not toolEquipped or processed or flingActive then return end
    
    local pos = touches[1]
    local ray = Camera:ScreenPointToRay(pos.X, pos.Y)
    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000)
    
    if raycastResult and raycastResult.Instance then
        local model = raycastResult.Instance:FindFirstAncestorOfClass("Model")
        local player = Players:GetPlayerFromCharacter(model)
        
        if player and player ~= LocalPlayer then
            KillPoliceBoatTarget(player)
        end
    end
end)

-- Suporte para mouse (PC)
UserInputService.InputBegan:Connect(function(input, processed)
    if not toolEquipped or processed or flingActive then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
        local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000)
        
        if raycastResult and raycastResult.Instance then
            local model = raycastResult.Instance:FindFirstAncestorOfClass("Model")
            local player = Players:GetPlayerFromCharacter(model)
            
            if player and player ~= LocalPlayer then
                KillPoliceBoatTarget(player)
            end
        end
    end
end)

SendNotification("Click Kill Police Boat", "Ferramenta criada! Equipe e clique em jogadores")

    end
}) 

flingsTab:AddSection({ "Fling Canoe" })

-- ========================================
-- FLING CANOE (COM SPIN E VOID TP)
-- ========================================
flingsTab:AddButton({
    Name = "Fling Canoe",
    Callback = function()
        if not lockedTarget or lockedTarget == "" then
            SendNotification("Erro", "Selecione um alvo primeiro!")
            return
        end
        
        local target = Players:FindFirstChild(lockedTarget)
        if not target or not target.Character then
            SendNotification("Erro", "Alvo não encontrado!")
            return
        end
        
        if IsPlayerSitting(target) then
            SendNotification("Bloqueado", "Alvo está sentado!")
            return
        end
        
        SendNotification("Fling Canoe", "Iniciando fling com Spin!")
        
        local character = LocalPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if not humanoidRootPart or not humanoid then return end
        
        local originalPosition = humanoidRootPart.CFrame
        
        -- Teleporta para o local
        humanoidRootPart.CFrame = CFrame.new(-229, 0, 1011)
        task.wait(0.5)
        
        -- Spawna canoa
        local canoeButton = workspace.WorkspaceCom:FindFirstChild("001_CanoeCloneButton")
        if canoeButton then
            local button = canoeButton:FindFirstChild("Button")
            if button then
                local clickDetector = button:FindFirstChild("ClickDetector")
                if clickDetector then
                    fireclickdetector(clickDetector)
                end
            end
        end
        
        task.wait(1.5)
        
        local canoeStorage = workspace.WorkspaceCom:FindFirstChild("001_CanoeStorage")
        if not canoeStorage then
            SendNotification("Erro", "CanoeStorage não encontrado")
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        local canoe = canoeStorage:FindFirstChild("Canoe")
        if not canoe then
            SendNotification("Erro", "Canoa não spawnou")
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        -- Teleporta para a canoa
        humanoidRootPart.CFrame = canoe:GetPivot() * CFrame.new(0, 3, 0)
        task.wait(0.5)
        
        -- Procura assento
        local seat = nil
        for _, child in pairs(canoe:GetDescendants()) do
            if child:IsA("Seat") or child:IsA("VehicleSeat") then
                seat = child
                break
            end
        end
        
        if not seat then
            SendNotification("Erro", "Assento não encontrado")
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        -- Senta
        local attempts = 0
        repeat
            humanoidRootPart.CFrame = seat.CFrame * CFrame.new(0, 1, 0)
            task.wait(0.1)
            attempts = attempts + 1
        until humanoid.Sit or attempts > 60
        
        if not humanoid.Sit then
            SendNotification("Erro", "Não conseguiu sentar")
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        SendNotification("Fling Canoe", "SPIN ATIVADO!")
        
        seat.CanTouch = false
        seat.CanCollide = false
        
        workspace.FallenPartsDestroyHeight = 0/0
        workspace.CurrentCamera.CameraSubject = humanoid
        
        -- CRIA SPIN NO ASSENTO DA CANOA
        local Spin = Instance.new("BodyAngularVelocity")
        Spin.Parent = seat
        Spin.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        Spin.AngularVelocity = Vector3.new(200, 200, 200) -- Spin em todos os eixos
        
        -- SISTEMA DE FLING AGRESSIVO COM TP PARA VOID
        local flingActive = true
        local targetInVoid = false
        local voidLocation = CFrame.new(3699, 139168, 1354)
        
        task.spawn(function()
            local startTime = tick()
            local maxTime = 25
            
            while flingActive and canoe and canoe.Parent and seat do
                local targetChar = target.Character
                if not targetChar then break end
                
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
                
                if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then break end
                
                -- Verifica void
                if targetRoot.Position.Y < -100 then
                    targetInVoid = true
                    SendNotification("Fling Canoe", "ALVO NO VOID!")
                    break
                end
                
                -- Verifica se sentou - TELEPORTA PARA O VOID
                if targetHumanoid.Sit then
                    SendNotification("Fling Canoe", "ALVO SENTOU! LEVANDO PARA O VOID...")
                    
                    pcall(function()
                        seat.CFrame = voidLocation
                    end)
                    
                    task.wait(2)
                    targetInVoid = true
                    break
                end
                
                local Angle = (tick() - startTime) * 100
                
                -- MOVIMENTOS AGRESSIVOS
                if targetRoot.Velocity.Magnitude < 50 then
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(0, 1.5, 0) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 1.25
                        seat.CFrame = seat.CFrame * CFrame.Angles(math.rad(Angle), 0, 0)
                    end)
                    task.wait()
                    
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(0, -1.5, 0) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 1.25
                        seat.CFrame = seat.CFrame * CFrame.Angles(math.rad(Angle), 0, 0)
                    end)
                    task.wait()
                    
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(2.25, 1.5, -2.25) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 1.25
                        seat.CFrame = seat.CFrame * CFrame.Angles(math.rad(Angle), 0, 0)
                    end)
                    task.wait()
                    
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(-2.25, -1.5, 2.25) + targetHumanoid.MoveDirection * targetRoot.Velocity.Magnitude / 1.25
                        seat.CFrame = seat.CFrame * CFrame.Angles(math.rad(Angle), 0, 0)
                    end)
                    task.wait()
                    
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(0, 1.5, 0) + targetHumanoid.MoveDirection
                        seat.CFrame = seat.CFrame * CFrame.Angles(math.rad(Angle), 0, 0)
                    end)
                    task.wait()
                    
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(0, -1.5, 0) + targetHumanoid.MoveDirection
                        seat.CFrame = seat.CFrame * CFrame.Angles(math.rad(Angle), 0, 0)
                    end)
                    task.wait()
                    
                else
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(0, 1.5, targetHumanoid.WalkSpeed)
                        seat.CFrame = seat.CFrame * CFrame.Angles(math.rad(90), 0, 0)
                    end)
                    task.wait()
                    
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(0, -1.5, -targetHumanoid.WalkSpeed)
                        seat.CFrame = seat.CFrame * CFrame.Angles(0, 0, 0)
                    end)
                    task.wait()
                    
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(0, 1.5, targetRoot.Velocity.Magnitude / 1.25)
                        seat.CFrame = seat.CFrame * CFrame.Angles(math.rad(90), 0, 0)
                    end)
                    task.wait()
                    
                    pcall(function()
                        seat.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(0, -1.5, -targetRoot.Velocity.Magnitude / 1.25)
                        seat.CFrame = seat.CFrame * CFrame.Angles(0, 0, 0)
                    end)
                    task.wait()
                end
                
                -- Se alvo está com velocidade alta, LEVA PARA O VOID
                if targetRoot.Velocity.Magnitude > 500 then
                    SendNotification("Fling Canoe", "LEVANDO PARA O VOID!")
                    
                    for i = 1, 5 do
                        pcall(function()
                            seat.CFrame = voidLocation
                        end)
                        task.wait(0.5)
                    end
                    
                    targetInVoid = true
                    break
                end
                
                if tick() - startTime > maxTime then break end
            end
            flingActive = false
        end)
        
        while flingActive do task.wait(0.1) end
        
        if Spin then Spin:Destroy() end
        
        workspace.CurrentCamera.CameraSubject = humanoid
        
        task.wait(0.3)
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        task.wait(0.7)
        if humanoidRootPart then
            humanoidRootPart.CFrame = originalPosition
            humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
        
        task.wait(0.5)
        
        if canoe and canoe.Parent then
            canoe:Destroy()
        end
        
        workspace.FallenPartsDestroyHeight = -500
        
        if targetInVoid then
            SendNotification("Flingado", target.Name .. " foi enviado para o void!")
        else
            SendNotification("Fling Canoe", "Fling concluído")
        end
    end
})

flingsTab:AddSection({ "Admin" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Controles das toggles
getgenv().AntiToolAllActive = false
getgenv().AntiToolSingleActive = false

local singlePlayerConnection = nil
local allPlayersConnections = {}

-- Remotes
local RemoteEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Playe1rTrigge1rEven1t")
local ClearToolsEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Clea1rTool1s")

-- Envia Remote várias vezes rapidamente
local function fastRemote(tool, targetPlayer)
    if not tool or not tool:IsA("Tool") or not targetPlayer then return end
    
    for i = 1, 3 do
        task.spawn(function()
            pcall(function()
                RemoteEvent:FireServer("AcceptedToolToServer", tool.Name, targetPlayer)
            end)
        end)
    end
    
    task.spawn(function()
        pcall(function()
            ClearToolsEvent:FireServer("ClearAllTools")
        end)
    end)
end

-- Verifica ferramentas em paralelo
local function scanTools(player, char)
    if not char then return end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            task.spawn(fastRemote, child, player)
        end
    end
end

-- ===== SINGLE PLAYER MONITOR (igual ao All mas só 1 player) =====
local function monitorSinglePlayer(player)
    if player == LocalPlayer then return end

    local connections = {}

    if player.Character then
        scanTools(player, player.Character)
        table.insert(connections, player.Character.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") and getgenv().AntiToolSingleActive then
                task.spawn(fastRemote, tool, player)
            end
        end))
    end

    table.insert(connections, player.CharacterAdded:Connect(function(char)
        scanTools(player, char)
        table.insert(connections, char.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") and getgenv().AntiToolSingleActive then
                task.spawn(fastRemote, tool, player)
            end
        end))
    end))

    -- Loop de verificação contínua (IGUAL AO ALL)
    table.insert(connections, task.spawn(function()
        while getgenv().AntiToolSingleActive and player.Parent == Players do
            if player.Character then
                scanTools(player, player.Character)
            end
            task.wait(0.2)
        end
    end))

    return connections
end

local function disconnectSinglePlayer()
    if singlePlayerConnection then
        for _, conn in ipairs(singlePlayerConnection) do
            if typeof(conn) == "RBXScriptConnection" and conn.Connected then 
                conn:Disconnect() 
            elseif typeof(conn) == "thread" then
                task.cancel(conn)
            end
        end
        singlePlayerConnection = nil
    end
end

-- ===== ALL PLAYERS MONITOR =====
local function monitorAllPlayers(player)
    if player == LocalPlayer then return end
    if allPlayersConnections[player] then return end

    local connections = {}
    allPlayersConnections[player] = connections

    if player.Character then
        scanTools(player, player.Character)
        table.insert(connections, player.Character.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") and getgenv().AntiToolAllActive then
                task.spawn(fastRemote, tool, player)
            end
        end))
    end

    table.insert(connections, player.CharacterAdded:Connect(function(char)
        scanTools(player, char)
        table.insert(connections, char.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") and getgenv().AntiToolAllActive then
                task.spawn(fastRemote, tool, player)
            end
        end))
    end))

    table.insert(connections, task.spawn(function()
        while getgenv().AntiToolAllActive and player.Parent == Players do
            if player.Character then
                scanTools(player, player.Character)
            end
            task.wait(0.2)
        end
    end))
end

local function disconnectAllPlayers()
    for _, conns in pairs(allPlayersConnections) do
        for _, conn in ipairs(conns) do
            if typeof(conn) == "RBXScriptConnection" and conn.Connected then 
                conn:Disconnect() 
            elseif typeof(conn) == "thread" then
                task.cancel(conn)
            end
        end
    end
    table.clear(allPlayersConnections)
end

-- ===== TOGGLES =====

flingsTab:AddToggle({
    Name = "Anti Tool Player",
    Default = false,
    Callback = function(state)
        getgenv().AntiToolSingleActive = state
        
        if state then
            -- Verifica se há alvo selecionado
            if not getgenv().Target or getgenv().Target == "" then
                if SendNotification then
                    SendNotification("Erro", "Selecione um player no dropdown Target primeiro")
                else
                    warn("Selecione um player no dropdown Target primeiro")
                end
                getgenv().AntiToolSingleActive = false
                return
            end
            
            -- Busca o player pelo nome
            local targetPlayer = Players:FindFirstChild(getgenv().Target)
            
            if not targetPlayer then
                if SendNotification then
                    SendNotification("Erro", getgenv().Target .. " nao esta no servidor")
                else
                    warn(getgenv().Target .. " nao esta no servidor")
                end
                getgenv().AntiToolSingleActive = false
                return
            end
            
            -- Inicia monitoramento (IGUAL AO ALL)
            singlePlayerConnection = monitorSinglePlayer(targetPlayer)
            
            if SendNotification then
                SendNotification("Anti Tool Player", "Ativado em: " .. getgenv().Target)
            else
                print("Anti Tool ativado em: " .. getgenv().Target)
            end
        else
            disconnectSinglePlayer()
            
            if SendNotification then
                SendNotification("Anti Tool Player", "Desativado")
            else
                print("Anti Tool Player desativado")
            end
        end
    end
})

flingsTab:AddToggle({
    Name = "Anti Tool All Players",
    Default = false,
    Callback = function(state)
        getgenv().AntiToolAllActive = state
        
        if state then
            -- Monitora todos os players atuais
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    monitorAllPlayers(player)
                end
            end
            
            -- Adiciona listener para novos players
            if not allPlayersConnections["_listener"] then
                allPlayersConnections["_listener"] = {
                    Players.PlayerAdded:Connect(function(player)
                        if getgenv().AntiToolAllActive then
                            monitorAllPlayers(player)
                        end
                    end)
                }
            end
            
            if SendNotification then
                SendNotification("Anti Tool All", "Ativado em todos os players")
            else
                print("Anti Tool All Players ativado")
            end
        else
            disconnectAllPlayers()
            
            if SendNotification then
                SendNotification("Anti Tool All", "Desativado")
            else
                print("Anti Tool All Players desativado")
            end
        end
    end
})

flingsTab:AddToggle({
    Name = "Freeze/Hack",
    Default = false,
    Callback = function(value)
        if value then
            -- Ativar o ataque automático
            cancelExpansion = false
            
            local RE = ReplicatedStorage:WaitForChild("RE")
            local FireEvent = RE:FindFirstChild("1Gu1n")

            -- Atira em parte (SEM pegar a arma)
            local function fireAtPart(targetPart)
                if not targetPart then return end

                -- Cria referências falsas para o gunScript
                local fakeGunScript = Instance.new("Folder")
                local fakeMuzzle = Instance.new("Part")
                local fakeHit = Instance.new("Part")

                local args = {
                    targetPart,
                    targetPart,
                    Vector3.new(1e14, 1e14, 1e14),
                    targetPart.Position,
                    fakeMuzzle,
                    fakeHit,
                    0,
                    0,
                    { false },
                    {
                        25,
                        Vector3.new(100, 100, 100),
                        BrickColor.new(29),
                        0.25,
                        Enum.Material.SmoothPlastic,
                        0.25
                    },
                    true,
                    false
                }

                if FireEvent then
                    FireEvent:FireServer(unpack(args))
                end
                
                -- Limpa referências
                fakeGunScript:Destroy()
                fakeMuzzle:Destroy()
                fakeHit:Destroy()
            end

            -- Atira no jogador selecionado
            local function fireAtSelectedPlayer()
                if not lockedTarget or lockedTarget == "" then
                    return false
                end
                
                local targetPlayer = Players:FindFirstChild(lockedTarget)
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    fireAtPart(targetPlayer.Character.HumanoidRootPart)
                    return true
                end
                return false
            end

            -- Loop automático de ataque no alvo selecionado (SEM pegar arma)
            task.spawn(function()
                while not cancelExpansion do
                    -- Verifica se há alvo selecionado
                    if not lockedTarget or lockedTarget == "" then
                        task.wait(1)
                        continue
                    end
                    
                    -- Atira diretamente sem pegar a arma
                    for i = 1, 3 do
                        if cancelExpansion then break end
                        if not fireAtSelectedPlayer() then
                            break
                        end
                        task.wait(0.1)
                    end
                    task.wait(1)
                end
            end)
            
            SendNotification("Auto Assault", "Ativado! Ataque no alvo: " .. (lockedTarget or "Nenhum"))
        else
            -- Desativar o ataque automático
            cancelExpansion = true
            SendNotification("Auto Assault", "Desativado!")
        end
    end
})

flingsTab:AddToggle({
    Name = "Annoy/Glitch",
    Default = false,
    Callback = function(state)
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer

        local Remote = ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Gu1n")

        getgenv().BugActive = state
        
        local function startBug()
            if getgenv().BugConnection then
                getgenv().BugConnection:Disconnect()
                getgenv().BugConnection = nil
            end

            getgenv().BugConnection = RunService.Stepped:Connect(function()
                if not getgenv().BugActive then return end
                
                -- Usa apenas getgenv().Target (sistema global)
                local targetName = getgenv().Target
                
                if not targetName or targetName == "" then
                    return
                end
                
                local target = Players:FindFirstChild(targetName)
                if not target then return end
                
                local character = target.Character
                if not character then return end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local maxValue = 2000000000
                local crazyVector = Vector3.new(
                    math.random(-maxValue, maxValue),
                    math.random(-maxValue, maxValue),
                    math.random(-maxValue, maxValue)
                )
                
                -- Objetos falsos (sem precisar da arma)
                local fakeMuzzle = Instance.new("Part")
                local fakeHit = Instance.new("Part")
                
                local args = {
                    hrp, 
                    hrp, 
                    crazyVector, 
                    hrp.Position,
                    fakeMuzzle,
                    fakeHit,
                    1000000000, 
                    1000000000, 
                    {false},
                    {
                        1000000000, 
                        Vector3.new(30000000, 30000000, 30000000), 
                        BrickColor.new(29), 
                        0.05, 
                        Enum.Material.SmoothPlastic, 
                        0.05
                    },
                    true, 
                    false
                }
                
                pcall(function()
                    Remote:FireServer(unpack(args))
                end)
                
                fakeMuzzle:Destroy()
                fakeHit:Destroy()
            end)
        end
        
        if state then
            -- Verifica se há alvo selecionado
            if not getgenv().Target or getgenv().Target == "" then
                if SendNotification then
                    SendNotification("Erro", "Selecione um player no dropdown Target primeiro")
                else
                    warn("Selecione um player valido antes de ativar o Annoy")
                end
                getgenv().BugActive = false
                return
            end
            
            -- Verifica se o player existe no servidor
            if not Players:FindFirstChild(getgenv().Target) then
                if SendNotification then
                    SendNotification("Erro", getgenv().Target .. " nao esta no servidor")
                else
                    warn(getgenv().Target .. " nao esta no servidor")
                end
                getgenv().BugActive = false
                return
            end
            
            if SendNotification then
                SendNotification("Annoy/Glitch", "Ativado em: " .. getgenv().Target)
            else
                print("Annoy Ativado em: " .. getgenv().Target)
            end
            
            startBug()
        else
            if SendNotification then
                SendNotification("Annoy/Glitch", "Desativado")
            else
                print("Annoy Desativado")
            end
            
            if getgenv().BugConnection then
                getgenv().BugConnection:Disconnect()
                getgenv().BugConnection = nil
            end
        end
    end
})

flingsTab:AddSection({ "Flings All" })

-- ========================================
-- FLING ALL - BALL (OTIMIZADO)
-- ========================================
flingsTab:AddButton({
    Name = "Fling All - Ball",
    Callback = function()
        SendNotification("Fling All Ball", "Iniciando...")
        
        local totalPlayers = 0
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                totalPlayers = totalPlayers + 1
            end
        end
        
        if totalPlayers == 0 then
            SendNotification("Erro", "Nenhum jogador para flingar!")
            return
        end
        
        local flinged = 0
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                SendNotification("Fling All", "Flingando " .. player.Name .. " (" .. (flinged + 1) .. "/" .. totalPlayers .. ")")
                
                task.spawn(function()
                    pcall(function()
                        FlingBall(player)
                    end)
                end)
                
                flinged = flinged + 1
                task.wait(2.5)
            end
        end
        
        SendNotification("Fling All Ball", "Concluído! " .. flinged .. " jogadores flingados")
    end
})

-- ========================================
-- FLING ALL - COUCH (OTIMIZADO E ESTÁVEL)
-- ========================================
flingsTab:AddButton({
    Name = "Fling All - Couch",
    Callback = function()
        SendNotification("Fling All Couch", "Iniciando...")
        
        local totalPlayers = 0
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not IsPlayerSitting(player) then
                totalPlayers = totalPlayers + 1
            end
        end
        
        if totalPlayers == 0 then
            SendNotification("Erro", "Nenhum jogador disponível!")
            return
        end
        
        local flinged = 0
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not IsPlayerSitting(player) then
                SendNotification("Fling All", "Flingando " .. player.Name .. " (" .. (flinged + 1) .. "/" .. totalPlayers .. ")")
                
                local RootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not RootPart then break end
                
                local originalPosition = RootPart.CFrame
                workspace.FallenPartsDestroyHeight = 0/0
                
                -- Pega e equipa o sofá
                if not GetAndEquipCouch() then
                    SendNotification("Erro", "Não foi possível equipar sofá")
                    workspace.FallenPartsDestroyHeight = -500
                    task.wait(2)
                    continue
                end
                
                task.wait(0.5)
                
                -- Executa o fling
                while not player.Character do task.wait(0.1) end
                SkidFling(player, originalPosition)
                
                -- Aguarda mais tempo antes do próximo
                task.wait(4)
                
                flinged = flinged + 1
            end
        end
        
        workspace.FallenPartsDestroyHeight = -500
        SendNotification("Fling All Couch", "✅ lConcluído! " .. flinged .. " jogadores flingados")
    end
})

-- ========================================
-- FLING ALL - BOAT (CÂMERA CORRIGIDA)
-- ========================================
flingsTab:AddButton({
    Name = "Fling All - Boat",
    Callback = function()
        SendNotification("Fling All Boat", "Iniciando...")
        
        local character = LocalPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if not humanoidRootPart or not humanoid then return end
        
        local originalPosition = humanoidRootPart.CFrame
        local Vehicles = workspace:FindFirstChild("Vehicles")
        
        -- Spawna boat
        humanoidRootPart.CFrame = CFrame.new(1754, -2, 58)
        task.wait(0.5)
        pcall(function()
            game:GetService("ReplicatedStorage").RE:FindFirstChild("1Ca1r"):FireServer("PickingBoat", "MilitaryBoatFree")
        end)
        
        task.wait(2)
        
        local vehicle = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
        if not vehicle then
            humanoidRootPart.CFrame = originalPosition
            SendNotification("Erro", "Boat não spawnou")
            return
        end
        
        local seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("VehicleSeat")
        if not seat then
            DeleteAllVehicles()
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        -- Senta no barco
        local attempts = 0
        repeat
            humanoidRootPart.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.1)
            attempts = attempts + 1
        until humanoid.Sit or attempts > 50
        
        if not humanoid.Sit then
            DeleteAllVehicles()
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        -- CORRIGE A CÂMERA - Mantém no player
        workspace.CurrentCamera.CameraSubject = humanoid
        
        local Spin = Instance.new("BodyAngularVelocity")
        Spin.Parent = vehicle.PrimaryPart
        Spin.MaxTorque = Vector3.new(0, math.huge, 0)
        Spin.AngularVelocity = Vector3.new(0, 200, 0)
        
        local totalPlayers = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not IsPlayerSitting(p) then
                totalPlayers = totalPlayers + 1
            end
        end
        
        local flinged = 0
        
        -- Flinga cada jogador individualmente
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= LocalPlayer and target.Character then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
                
                if targetRoot and targetHumanoid and not IsPlayerSitting(target) then
                    SendNotification("Fling All", "Flingando " .. target.Name .. " (" .. (flinged + 1) .. "/" .. totalPlayers .. ")")
                    
                    -- MANTÉM CÂMERA NO SEU PLAYER
                    workspace.CurrentCamera.CameraSubject = humanoid
                    
                    local startTime = tick()
                    local flingTime = 10
                    
                    while tick() - startTime < flingTime do
                        if not targetRoot or not vehicle or not vehicle.Parent then break end
                        if targetHumanoid.Health <= 0 or targetRoot.Position.Y < -100 then break end
                        
                        -- Movimento mais SUAVE
                        local angle = (tick() - startTime) * 30
                        
                        if targetRoot.Velocity.Magnitude < 50 then
                            pcall(function()
                                vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(angle), 0, 0))
                            end)
                            task.wait(0.15)
                            pcall(function()
                                vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(angle), 0, 0))
                            end)
                            task.wait(0.15)
                        else
                            pcall(function()
                                vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(90), 0, 0))
                            end)
                            task.wait(0.15)
                        end
                        
                        if targetRoot.Velocity.Magnitude > 150 then
                            SendNotification("Fling", target.Name .. " foi flingado!")
                            break
                        end
                    end
                    
                    flinged = flinged + 1
                    task.wait(1.5)
                end
            end
        end
        
        if Spin then Spin:Destroy() end
        
        -- Restaura câmera
        workspace.CurrentCamera.CameraSubject = humanoid
        
        task.wait(0.5)
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.7)
        humanoidRootPart.CFrame = originalPosition
        task.wait(0.5)
        DeleteAllVehicles()
        workspace.FallenPartsDestroyHeight = -500
        
        SendNotification("Fling All Boat", "Concluído! " .. flinged .. " jogadores flingados")
    end
})

-- ========================================
-- FLING ALL - POLICE BOAT (CÂMERA CORRIGIDA)
-- ========================================
flingsTab:AddButton({
    Name = "Fling All - PoliceBoat",
    Callback = function()
        SendNotification("Fling All PoliceBoat", "Iniciando...")
        
        local character = LocalPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if not humanoidRootPart or not humanoid then return end
        
        local originalPosition = humanoidRootPart.CFrame
        local Vehicles = workspace:FindFirstChild("Vehicles")
        
        humanoidRootPart.CFrame = CFrame.new(1754, -2, 58)
        task.wait(0.5)
        pcall(function()
            game:GetService("ReplicatedStorage").RE:FindFirstChild("1Ca1r"):FireServer("PickingBoat", "PoliceBoatChangeable")
        end)
        
        task.wait(2)
        
        local vehicle = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
        if not vehicle then
            humanoidRootPart.CFrame = originalPosition
            SendNotification("Erro", "PoliceBoat não spawnou")
            return
        end
        
        local seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("VehicleSeat")
        if not seat then
            DeleteAllVehicles()
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        local attempts = 0
        repeat
            humanoidRootPart.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.1)
            attempts = attempts + 1
        until humanoid.Sit or attempts > 50
        
        if not humanoid.Sit then
            DeleteAllVehicles()
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        -- CORRIGE A CÂMERA
        workspace.CurrentCamera.CameraSubject = humanoid
        
        local Spin = Instance.new("BodyAngularVelocity")
        Spin.Parent = vehicle.PrimaryPart
        Spin.MaxTorque = Vector3.new(0, math.huge, 0)
        Spin.AngularVelocity = Vector3.new(0, 200, 0)
        
        local totalPlayers = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not IsPlayerSitting(p) then
                totalPlayers = totalPlayers + 1
            end
        end
        
        local flinged = 0
        
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= LocalPlayer and target.Character then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
                
                if targetRoot and targetHumanoid and not IsPlayerSitting(target) then
                    SendNotification("Fling All", "Flingando " .. target.Name .. " (" .. (flinged + 1) .. "/" .. totalPlayers .. ")")
                    
                    workspace.CurrentCamera.CameraSubject = humanoid
                    
                    local startTime = tick()
                    local flingTime = 10
                    
                    while tick() - startTime < flingTime do
                        if not targetRoot or not vehicle or not vehicle.Parent then break end
                        if targetHumanoid.Health <= 0 or targetRoot.Position.Y < -100 then break end
                        
                        local angle = (tick() - startTime) * 30
                        
                        if targetRoot.Velocity.Magnitude < 50 then
                            pcall(function()
                                vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(angle), 0, 0))
                            end)
                            task.wait(0.15)
                            pcall(function()
                                vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(angle), 0, 0))
                            end)
                            task.wait(0.15)
                        else
                            pcall(function()
                                vehicle:SetPrimaryPartCFrame(CFrame.new(targetRoot.Position) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(90), 0, 0))
                            end)
                            task.wait(0.15)
                        end
                        
                        if targetRoot.Velocity.Magnitude > 150 then
                            SendNotification("Fling", target.Name .. " foi flingado!")
                            break
                        end
                    end
                    
                    flinged = flinged + 1
                    task.wait(1.5)
                end
            end
        end
        
        if Spin then Spin:Destroy() end
        workspace.CurrentCamera.CameraSubject = humanoid
        
        task.wait(0.5)
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.7)
        humanoidRootPart.CFrame = originalPosition
        task.wait(0.5)
        DeleteAllVehicles()
        workspace.FallenPartsDestroyHeight = -500
        
        SendNotification("Fling All PoliceBoat", "Concluído! " .. flinged .. " jogadores flingados")
    end
})

-- ========================================
-- FLING ALL - BUS (OTIMIZADO)
-- ========================================
flingsTab:AddButton({
    Name = "Fling All - Bus",
    Callback = function()
        SendNotification("Fling All Bus", "Iniciando...")
        
        local character = LocalPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if not humanoidRootPart or not humanoid then return end
        
        local originalPosition = humanoidRootPart.CFrame
        local Vehicles = workspace:FindFirstChild("Vehicles")
        
        humanoidRootPart.CFrame = CFrame.new(1118.81, 75.998, -1138.61)
        task.wait(0.5)
        pcall(function()
            local args = {"PickingCar", "SchoolBus"}
            game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer(unpack(args))
        end)
        
        task.wait(2)
        
        local vehicle = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
        if not vehicle then
            humanoidRootPart.CFrame = originalPosition
            SendNotification("Erro", "Bus não spawnou")
            return
        end
        
        local seat = vehicle:FindFirstChild("Seats") and vehicle.Seats:FindFirstChild("VehicleSeat")
        if not seat then
            seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("VehicleSeat")
        end
        
        if not seat then
            DeleteAllVehicles()
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        local attempts = 0
        repeat
            humanoidRootPart.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.1)
            attempts = attempts + 1
        until humanoid.Sit or attempts > 50
        
        if not humanoid.Sit then
            DeleteAllVehicles()
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        workspace.CurrentCamera.CameraSubject = humanoid
        
        local totalPlayers = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not IsPlayerSitting(p) then
                totalPlayers = totalPlayers + 1
            end
        end
        
        local flinged = 0
        
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= LocalPlayer and target.Character then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
                
                if targetRoot and targetHumanoid and not IsPlayerSitting(target) then
                    SendNotification("Fling All", "Flingando " .. target.Name .. " (" .. (flinged + 1) .. "/" .. totalPlayers .. ")")
                    
                    local startTime = tick()
                    
                    while tick() - startTime < 12 do
                        if not targetRoot or not vehicle or not vehicle.Parent then break end
                        if targetHumanoid.Health <= 0 or targetRoot.Position.Y < -100 then break end
                        
                        local time = tick() * 30
                        local lateralOffset = math.sin(time) * 5
                        local frontBackOffset = math.cos(time) * 18
                        
                        pcall(function()
                            vehicle:SetPrimaryPartCFrame(targetRoot.CFrame * CFrame.new(lateralOffset, 0, frontBackOffset))
                        end)
                        
                        if targetRoot.Velocity.Magnitude > 150 then
                            SendNotification("Fling", target.Name .. " foi flingado!")
                            break
                        end
                        
                        task.wait(0.1)
                    end
                    
                    flinged = flinged + 1
                    task.wait(1.5)
                end
            end
        end
        
        workspace.CurrentCamera.CameraSubject = humanoid
        
        task.wait(0.5)
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.7)
        humanoidRootPart.CFrame = originalPosition
        task.wait(0.5)
        DeleteAllVehicles()
        workspace.FallenPartsDestroyHeight = -500
        
        SendNotification("Fling All Bus", "Concluído! " .. flinged .. " jogadores flingados")
    end
})

-- ========================================
-- FLING ALL - TOW TRUCK (OTIMIZADO)
-- ========================================
flingsTab:AddButton({
    Name = "Fling All - TowTruck",
    Callback = function()
        SendNotification("Fling All TowTruck", "Iniciando...")
        
        local character = LocalPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if not humanoidRootPart or not humanoid then return end
        
        local originalPosition = humanoidRootPart.CFrame
        local Vehicles = workspace:FindFirstChild("Vehicles")
        
        humanoidRootPart.CFrame = CFrame.new(1118.81, 75.998, -1138.61)
        task.wait(0.5)
        pcall(function()
            local args = {"PickingCar", "TowTruck"}
            game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Ca1r"):FireServer(unpack(args))
        end)
        
        task.wait(2)
        
        local vehicle = Vehicles:FindFirstChild(LocalPlayer.Name .. "Car")
        if not vehicle then
            humanoidRootPart.CFrame = originalPosition
            SendNotification("Erro", "TowTruck não spawnou")
            return
        end
        
        local seat = vehicle:FindFirstChild("Seats") and vehicle.Seats:FindFirstChild("VehicleSeat")
        if not seat then
            seat = vehicle:FindFirstChild("Body") and vehicle.Body:FindFirstChild("VehicleSeat")
        end
        
        if not seat then
            DeleteAllVehicles()
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        local attempts = 0
        repeat
            humanoidRootPart.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.1)
            attempts = attempts + 1
        until humanoid.Sit or attempts > 50
        
        if not humanoid.Sit then
            DeleteAllVehicles()
            humanoidRootPart.CFrame = originalPosition
            return
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        workspace.CurrentCamera.CameraSubject = humanoid
        
        local totalPlayers = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not IsPlayerSitting(p) then
                totalPlayers = totalPlayers + 1
            end
        end
        
        local flinged = 0
        
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= LocalPlayer and target.Character then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
                
                if targetRoot and targetHumanoid and not IsPlayerSitting(target) then
                    SendNotification("Fling All", "Flingando " .. target.Name .. " (" .. (flinged + 1) .. "/" .. totalPlayers .. ")")
                    
                    local startTime = tick()
                    
                    while tick() - startTime < 12 do
                        if not targetRoot or not vehicle or not vehicle.Parent then break end
                        if targetHumanoid.Health <= 0 or targetRoot.Position.Y < -100 then break end
                        
                        local time = tick() * 30
                        local lateralOffset = math.sin(time) * 5
                        local frontBackOffset = math.cos(time) * 18
                        
                        pcall(function()
                            vehicle:SetPrimaryPartCFrame(targetRoot.CFrame * CFrame.new(lateralOffset, 0, frontBackOffset))
                        end)
                        
                        if targetRoot.Velocity.Magnitude > 150 then
                            SendNotification("Fling", target.Name .. " foi flingado!")
                            break
                        end
                        
                        task.wait(0.1)
                    end
                    
                    flinged = flinged + 1
                    task.wait(1.5)
                end
            end
        end
        
        workspace.CurrentCamera.CameraSubject = humanoid
        
        task.wait(0.5)
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.7)
        humanoidRootPart.CFrame = originalPosition
        task.wait(0.5)
        DeleteAllVehicles()
        workspace.FallenPartsDestroyHeight = -500
        
        SendNotification("Fling All TowTruck", "Concluído! " .. flinged .. " jogadores flingados")
    end
})

print("")

flingsTab:AddSection({ "Troll v2" })

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFolder = ReplicatedStorage:WaitForChild("RE")

local fireX = workspace:WaitForChild("WorkspaceCom"):WaitForChild("001_GiveTools"):FindFirstChild("FireX")
local fireXClick = fireX and fireX:FindFirstChildOfClass("ClickDetector")
local fireXPrompt = fireX and fireX:FindFirstChildOfClass("ProximityPrompt")
local fireXEnabled = false
local fireXWeld = nil
local fireXArgs = { [1] = "FireX", [2] = "On" }

local laptop = workspace:WaitForChild("WorkspaceCom"):WaitForChild("001_GiveTools"):FindFirstChild("Laptop")
local laptopClick = laptop and laptop:FindFirstChildOfClass("ClickDetector")
local laptopPrompt = laptop and laptop:FindFirstChildOfClass("ProximityPrompt")
local laptopEnabled = false
local laptopWeld = nil

local vehiclesFolder = workspace:WaitForChild("Vehicles")
local isActiveVehicle = false
local selectedPlayerName = nil

local function grudar(part, weldRef)
	if not weldRef and part then
		hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = part
		weld.Parent = hrp
		return weld
	end
end

local function desgrudar(weldRef)
	if weldRef then
		weldRef:Destroy()
		weldRef = nil
	end
	return nil
end

local function getMyVehicleSeat()
	for _, vehicle in pairs(vehiclesFolder:GetChildren()) do
		if string.find(vehicle.Name, LocalPlayer.Name) then
			return vehicle:FindFirstChildWhichIsA("VehicleSeat", true)
		end
	end
	return nil
end

task.spawn(function()
	while true do
		if fireXEnabled and fireX then
			if not fireXWeld then fireXWeld = grudar(fireX, fireXWeld) end
			if fireXClick then
				fireclickdetector(fireXClick)
			elseif fireXPrompt then
				fireproximityprompt(fireXPrompt)
			else
				firetouchinterest(hrp, fireX, 0)
				firetouchinterest(hrp, fireX, 1)
			end
			local remote
			if LocalPlayer.Character then
				local tool = LocalPlayer.Character:FindFirstChild("FireX")
				if tool then remote = tool:FindFirstChild("ToolSound") end
			end
			if remote and remote.FireServer then
				pcall(function() remote:FireServer(table.unpack(fireXArgs)) end)
			end
		end
		if laptopEnabled and laptop then
			if not laptopWeld then laptopWeld = grudar(laptop, laptopWeld) end
			for i = 1, 8 do
				if laptopClick then
					fireclickdetector(laptopClick)
				elseif laptopPrompt then
					fireproximityprompt(laptopPrompt)
				else
					firetouchinterest(hrp, laptop, 0)
					firetouchinterest(hrp, laptop, 1)
				end
			end
		end
		if isActiveVehicle and selectedPlayerName then
			local targetPlayer = Players:FindFirstChild(selectedPlayerName)
			if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local seat = getMyVehicleSeat()
				if seat then
					seat.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
				end
			end
		end
		task.wait(0.01)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if fireXEnabled and fireXClick then fireclickdetector(fireXClick) end
		if laptopEnabled and laptopClick then fireclickdetector(laptopClick) end
	end
end)

flingsTab:AddToggle({
	Name = "FireX Auto",
	Default = false,
	Callback = function(state)
		fireXEnabled = state
		if not state then
			fireXWeld = desgrudar(fireXWeld)
		end
	end
})

flingsTab:AddToggle({
	Name = "Lag Laptop",
	Default = false,
	Callback = function(state)
		laptopEnabled = state
		if not state then
			laptopWeld = desgrudar(laptopWeld)
		end
	end
})

local function getPlayerList()
	local PlayerNames = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name ~= LocalPlayer.Name then
			table.insert(PlayerNames, player.Name)
		end
	end
	return PlayerNames
end

local killDropdown = flingsTab:AddDropdown({
	Name = "Selecionar Jogador",
	Options = getPlayerList(),
	Default = "",
	Callback = function(value)
		selectedPlayerName = value
		getgenv().Target = value
	end
})

local function UpdateDropdown()
	local tablePlayers = Players:GetPlayers()
	local newPlayers = {}
	for _, player in ipairs(tablePlayers) do
		if player.Name ~= LocalPlayer.Name then
			table.insert(newPlayers, player.Name)
		end
	end
	killDropdown:Set(newPlayers)
	if selectedPlayerName and Players:FindFirstChild(selectedPlayerName) then
		killDropdown:SetValue(selectedPlayerName)
	else
		selectedPlayerName = nil
		getgenv().Target = nil
		killDropdown:SetValue("")
	end
end

flingsTab:AddButton({
	Name = "Atualizar Player List",
	Callback = function()
		UpdateDropdown()
	end
})

flingsTab:AddToggle({
	Name = "Manda veiculo pro player",
	Default = false,
	Callback = function(state)
		isActiveVehicle = state
	end
})

local selectedRemoteName = nil
local remoteToggle = false

local RemoteList = {
	["SchoolBus"] = {"1Ca1r", {"PickingCar", "SchoolBus"}},
	["Van"] = {"1Ca1r", {"PickingCar", "Van"}},
	["Semi"] = {"1Ca1r", {"PickingCar", "Semi"}},
	["RV"] = {"1Ca1r", {"PickingCar", "RV"}},
	["Snowplow"] = {"1Ca1r", {"PickingCar", "Snowplow"}}
}

local remoteOptions = {}
for name, _ in pairs(RemoteList) do
	table.insert(remoteOptions, name)
end

local remoteDropdown = flingsTab:AddDropdown({
	Name = "Selecionar Carros",
	Options = remoteOptions,
	Default = "",
	Callback = function(value)
		selectedRemoteName = value
	end
})

flingsTab:AddToggle({
	Name = "Carros troll",
	Default = false,
	Callback = function(state)
		remoteToggle = state
		task.spawn(function()
			while remoteToggle do
				if selectedRemoteName then
					local remoteData = RemoteList[selectedRemoteName]
					if remoteData then
						local remoteName = remoteData[1]
						local args = remoteData[2]
						local remote = RemoteFolder:FindFirstChild(remoteName)
						if remote then
							remote:FireServer(unpack(args))
						end
					end
				end
				task.wait(2)
			end
		end)
	end
})

local RemoteCoordList = {
	["Military Boat"] = {"1Ca1r", {"PickingBoat", "MilitaryBoatFree"}},
	["Pirate Boat"] = {"1Ca1r", {"PickingBoat", "PirateFree"}}
}

local remoteCoordOptions = {}
for name, _ in pairs(RemoteCoordList) do
	table.insert(remoteCoordOptions, name)
end

local selectedRemoteCoord = nil
local remoteCoordToggle = false
local teleportPosition = Vector3.new(1742, -4, -90)

local remoteCoordDropdown = flingsTab:AddDropdown({
	Name = "Selecionar Barcos",
	Options = remoteCoordOptions,
	Default = "",
	Callback = function(value)
		selectedRemoteCoord = value
	end
})

flingsTab:AddToggle({
	Name = "Ativar Barco troll",
	Default = false,
	Callback = function(state)
		remoteCoordToggle = state
		task.spawn(function()
			while remoteCoordToggle do
				if selectedRemoteCoord then
					if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
						LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(teleportPosition)
					end
					local remoteData = RemoteCoordList[selectedRemoteCoord]
					if remoteData then
						local remoteName = remoteData[1]
						local args = remoteData[2]
						local remote = RemoteFolder:FindFirstChild(remoteName)
						if remote then
							remote:FireServer(unpack(args))
						end
					end
				end
				task.wait(2)
			end
		end)
	end
})

local viewPlayerEnabled = false
local originalCamera = workspace.CurrentCamera.CameraSubject

flingsTab:AddToggle({
	Name = "View Player",
	Default = false,
	Callback = function(state)
		viewPlayerEnabled = state
		local camera = workspace.CurrentCamera
		if state then
			if selectedPlayerName then
				local targetPlayer = Players:FindFirstChild(selectedPlayerName)
				if targetPlayer and targetPlayer.Character then
					local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						originalCamera = camera.CameraSubject
						camera.CameraSubject = humanoid
					end
				end
			end
		else
			camera.CameraSubject = originalCamera
		end
	end
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local selectedPlayerName = nil
local selectedPlayer = nil
local singlePlayerActive = false
local allPlayersActive = false
local singlePlayerConn = {}
local allPlayersConnections = {}

local RemoteEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Playe1rTrigge1rEven1t")
local ClearToolsEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Clea1rTool1s")

local function getPlayerList()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(list, player.Name)
		end
	end
	return list
end

local killDropdown = flingsTab:AddDropdown({
	Name = "Selecionar Jogador",
	Options = getPlayerList(),
	Default = "",
	Callback = function(value)
		selectedPlayerName = value
		selectedPlayer = Players:FindFirstChild(value)
	end
})

local function UpdateDropdown()
	local newPlayers = getPlayerList()
	if killDropdown then
		killDropdown:Set(newPlayers)
		selectedPlayerName = nil
		selectedPlayer = nil
		killDropdown:SetValue("")
	end
end

flingsTab:AddButton({
	Name = "Atualizar Player List",
	Callback = UpdateDropdown
})

local Tab = Window:MakeTab({"Musica", "rbxassetid://111911979482253"})

---------------------------------------------------------------------------------------------------------------------------------
                                                -- === Tab 7: Music All === --
---------------------------------------------------------------------------------------------------------------------------------

Tab:AddSection({"Musica"})

local loopAtivo = false
local InputID = ""

Tab:AddTextBox({
    Name = "Insira o ID Audio All",
    Description = "Digite o ID do som que deseja tocar",
    Default = "",
    PlaceholderText = "Exemplo: 6832470734",
    ClearTextOnFocus = true,
    Callback = function(text)
        InputID = tonumber(text)
    end
})

local function fireServer(eventName, args)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local event = ReplicatedStorage:FindFirstChild("RE") and ReplicatedStorage.RE:FindFirstChild(eventName)
    if event then
        pcall(function()
            event:FireServer(unpack(args))
        end)
    end
end

Tab:AddButton({
    Name = "Tocar Som",
    Description = "Clique para tocar a música inserida",
    Callback = function()
        if InputID then
            fireServer("1Gu1nSound1s", {Workspace, InputID, 1})
            local globalSound = Instance.new("Sound", Workspace)
            globalSound.SoundId = "rbxassetid://" .. InputID
            globalSound.Looped = false
            globalSound:Play()
            task.wait(3)
            globalSound:Destroy()
        end
    end
})

Tab:AddToggle({
    Name = "Loop",
    Description = "Ative para colocar o som em loop",
    Default = false,
    Callback = function(state)
        loopAtivo = state
        if loopAtivo then
            spawn(function()
                while loopAtivo do
                    if InputID then
                        fireServer("1Gu1nSound1s", {Workspace, InputID, 1})
                        local globalSound = Instance.new("Sound", Workspace)
                        globalSound.SoundId = "rbxassetid://" .. InputID
                        globalSound.Looped = false
                        globalSound:Play()
                        task.spawn(function()
                            task.wait(3)
                            globalSound:Destroy()
                        end)
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

-- Dropdowns para Tab
local function createSoundDropdown(title, musicOptions, defaultOption)
    local musicNames = {}
    local categoryMap = {}
    for category, sounds in pairs(musicOptions) do
        for _, music in ipairs(sounds) do
            if music.name ~= "" and music.id ~= "4354908569" then
                table.insert(musicNames, music.name)
                categoryMap[music.name] = {id = music.id, category = category}
            end
        end
    end

    local selectedSoundID = nil
    local currentVolume = 1
    local currentPitch = 1

    local function playSound(soundId, volume, pitch)
        fireServer("1Gu1nSound1s", {Workspace, soundId, volume})
        local globalSound = Instance.new("Sound")
        globalSound.Parent = Workspace
        globalSound.SoundId = "rbxassetid://" .. soundId
        globalSound.Volume = volume
        globalSound.Pitch = pitch
        globalSound.Looped = false
        globalSound:Play()
        task.spawn(function()
            task.wait(3)
            globalSound:Destroy()
        end)
    end

    Tab:AddDropdown({
        Name = title,
        Description = "Escolha um som para tocar no servidor",
        Default = defaultOption,
        Multi = false,
        Options = musicNames,
        Callback = function(selectedSound)
            if selectedSound and categoryMap[selectedSound] then
                selectedSoundID = categoryMap[selectedSound].id
            else
                selectedSoundID = nil
            end
        end
    })

    Tab:AddButton({
        Name = "Tocar Som Selecionado",
        Description = "Clique para tocar o som do dropdown",
        Callback = function()
            if selectedSoundID then
                playSound(selectedSoundID, currentVolume, currentPitch)
            end
        end
    })

    local dropdownLoopActive = false
    Tab:AddToggle({
        Name = "Loop",
        Description = "Ativa o loop do som selecionado",
        Default = false,
        Callback = function(state)
            dropdownLoopActive = state
            if state then
                task.spawn(function()
                    while dropdownLoopActive do
                        if selectedSoundID then
                            playSound(selectedSoundID, currentVolume, currentPitch)
                        end
                        task.wait(1)
                    end
                end)
            end
        end
    })
end

-- Dropdown "Memes"
createSoundDropdown("Selecione um meme", {
    ["Memes"] = {
        {name = "pankapakan", id = "122547522269143"}, 
       
        {name = "Gemido ultra rápido", id = "128863565301778"},
        {name = "vai g0z@?", id = "116293771329297"},
        {name = "G0z33iiii", id = "93462644278510"},
        {name = "Hommmm ", id = "133135656929513"},
        {name = "gemido1", id = "105263704862377"},
        {name = " gemido2", id = "92186909873950"},
        {name = "sus sex", id = "128137573022197"},
        {name = "gemido estranho", id = "131219411501419"},
        {name = "gemido kawai", id = "100409245129170"},
        {name = "Hentai wiaaaaan", id = "88332347208779"},
        {name = "iamete cunasai", id = "108494476595033"},
        {name = "dodichan onnn...", id = "134640594695384"},
        {name = "Loly gemiD0", id = "119277017538197"},
         {name = "ai poison", id = "115870718113313"},
         {name = "chegachega SUS", id = "77405864184828"},
         {name = "uwu", id = "76820720070248"},
         {name = "ai meu cuzin", id = "130714479795369"},
         {name = "girl audio 2", id = "84207358477461"},
        {name = "Hoo ze da manga", id = "106624090319571"},
        {name = "ai alexandre de moraes", id = "107261471941570"},
        {name = "haaii meme", id = "120006672159037"},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
 
    


        {name = "GoGogo gogogo", id = "103262503950995"},
        {name = "Toma jack", id = "132603645477541"},
        {name = "Toma jackV2", id = "100446887985203"},
        {name = "Toma jack no sol quente", id = "97476487963273"},
        {name = "ifood", id = "133843750864059"},
        {name = "pelo geito ela ta querendo ram", id = "94395705857835"},
        {name = "lula vai todo mundo", id = "136804576009416"},
        {name = "coringa", id = "84663543883498"},
        {name = "shoope", id = "8747441609"},
        {name = "quenojo", id = "103440368630269"},
        {name = "sai dai lava prato", id = "101232400175829"},
        {name = "se e loko numconpeça", id = "78442476709262"},
        {name = "mita sequer que eu too uma", id = "94889439372168"},
        {name = "Hoje vou ser tua mulher e tu", id = "90844637105538"},
        {name = "Deita aqui eu mandei vc deitar sirens", id = "100291188941582"},
        {name = "miau", id = "131804436682424"},
        {name = "skibidi", id = "128771670035179"},
        {name = "BIRULEIBI", id = "121569761604968"},
        {name = "biseabesjnjkasnakjsndjkafb", id = "133106998846260"},
        {name = "vai corinthians!!....", id = "127012936767471"},
        {name = "my sigman", id = "103431815659907"},
        {name = "mama", id = "106850066985594"},
        {name = "OH MY GOD", id = "73349649774476"},
        {name = "aahhh plankton meme", id = "95982351322190"},
        {name = "CHINABOY", id = "84403553163931"},
        {name = "PASTOR MIRIM E A LÍNGUA DOS ANJOS", id = "71153532555470"},
        
        {name = "Sai d3sgraç@", id = "106973692977609"},
        
        {name = "opa salve tudo bem?", id = "80870678096428"},
        {name = "OLHA O CARRO DO DANONE", id = "110493863773948"},
        {name = "Nãoooo, Nãoooo, Nãooo!!!!!", id = "95825536480898"},
        {name = "UM PÉ DE SIRIGUELA KK", id = "112804043442210"},
        {name = "e o carro da pamonha", id = "94951629392683"},
        {name = "BOM DIAAAAAAAAAA", id = "136579844511260"},
        {name = "ai-meu-chiclete", id = "92911732806153"},
        {name = "posso te ligar ou tua mulher...", id = "103211341252816"},
        {name = "Boa chi joga muito cara", id = "110707564387669"},
        {name = "Oqueee meme", id = "120092799810101"},
        {name = "kkk muito fei", id = "79241074803021"},
        {name = "lula cade o ze gotinha", id = "86012585992725"},
        {name = "morreu", id = "8872409975"},
        {name = "a-pia-ta-cheia-de-louca", id = "98076927129047"},
        {name = "Mahito killSong", id = "128669424001766"},
        {name = "Sucumba", id = "7946300950"},
        {name = "nem clicou o thurzin", id = "84428355313544"},
        {name = "fiui OLHA MENSAGEM", id = "121668429878811"},
        {name = "tooomeee", id = "128319664118768"},
        {name = "risada de ladrao", id = "133065882609605"},
        {name = "E o PIX nada ainda", id = "113831443375212"},
        {name = "Vo nada vo nada", id = "89093085290586"},
        {name = "Eli gosta", id = "105012436535315"},
        {name = "um cavalo de tres pernas?", id = "8164241439"},
        {name = "voces sao um bado de fdp", id = "8232773326"},
        {name = "HAHA TROLLEI ATÉ VOCÊ", id = "7021794555"},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        
        

        {name = "Calaboca Kenga", id = "86494561679259"},
        {name = "alvincut", id = "88788640194373"},
        {name = "e a risada faz como?", id = "140713372459057"},
        {name = "voce deve se m@t4", id = "100227426848009"},
        {name = "receba", id = "94142662616215"},
        {name = "UUIIII", id = "73210569653520"},
        



        {name = "sai", id = "121169949217007"},
        {name = "risada boa dms", id = "127589011971759"},
        {name = "vacilo perna de pau", id = "106809680656199"},
        {name = "gomo gomo no!!!", id = "137067472449625"},
        {name = "arroto", id = "140203378050178"},
        {name = "iraaaa", id = "136752451575091"},
        {name = "não fica se achando muito não", id = "101588606280167"},
       
        {name = "WhatsApp notificaçaoV1", id = "107004225739474"},
        {name = "WhatsApp notificaçaoV2", id = "18850631582"},
        {name = "SamsungV1", id = "123767635061073"},
        {name = "SamsungV2", id = "96579234730244"}, 
        {name = "Shiiii", id = "120566727202986"},
        {name = "ai_tomaa miku", id = "139770074770361"},
        {name = "Miku Miku", id = "72812231495047"},
        {name = "kuru_kuru", id = "122465710753374"},
        {name = "PM ROCAM", id = "96161547081609"},
        {name = "cavalo!!", id = "78871573440184"},
        {name = "deixa os garoto brinca", id = "80291355054807"},
        {name = "flamengo", id = "137774355552052"},
        {name = "sai do mei satnas", id = "127944706557246"},
        {name = "namoral agora e a hora", id = "120677947987369"},
        {name = "n pode me chutar pq seu celebro e burro", id = "82284055473737"},
        {name = "vc ta fudido vou te pegar", id = "120214772725166"},
        {name = "deley", id = "102906880476838"},
        {name = "Tu e um beta", id = "130233956349541"},
        {name = "Porfavor n tira eu nao", id = "85321374020324"},
        {name = "Olá beleza vc pode me dá muitos", id = "74235334504693"},
        {name = "Discord sus", id = "122662798976905"},
        {name = "rojao apito", id = "6549021381"},
        {name = "off", id = "1778829098"},
        {name = "Kazuma kazuma", id = "127954653962405"},
        {name = "sometourado", id = "123592956882621"},
        {name = "Estouradoespad", id = "136179020015211"},
        {name = "Alaku bommm", id = "110796593805268"},
        {name = "busss", id = "139841197791567"},
        {name = "Estourado wItb", id = "137478052262430"},
        {name = "sla", id = "116672405522828"},
        {name = "HA HA HA", id = "138236682866721"}
    }
}, "pankapakan")



local Section = Tab:AddSection({" tacar o terror ou efeito no server"})

-- Dropdown "Efeito/Terror"
createSoundDropdown("Selecione um terror ou efeito", {
    ["efeito/terror"] = {
        {name = "jumpscar", id = "91784486966761"},
        {name = "n se preocupe", id = "87041057113780"},
        {name = "eles estao todos mortos", id = "70605158718179"},

        {name = "gritoestourado", id = "7520729342"},
        {name = "gritomedo", id = "113029085566978"},
        {name = "Nukesiren", id = "9067330158"},
        {name = "nuclear sirenv2", id = "675587093"},
        {name = "Alertescola", id = "6607047008"},
        {name = "Memealertsiren", id = "8379374771"},
        {name = "sirenv3", id = "6766811806"},
        {name = "Alarm estourAAAA...", id = "93354528379052"},
        {name = "MegaMan Alarm", id = "1442382907"},
        {name = "Alarm bookhaven", id = "1526192493"},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},



        {name = "alet malaysia", id = "7714172940"},
        {name = "Risada", id = "79191730206814"},
        {name = "Hahahah", id = "90096947219465"},
        {name = "scream", id = "314568939"},
        {name = "Terrified meme scream", id = "5853668794"},
        {name = "Sonic.exe Scream Effect", id = "146563959"},
        {name = "Demon Scream", id = "2738830850"},
        {name = "SCP-096 Scream (raging)", id = "343430735"},
        {name = "Nightmare Yelling Bursts", id = "9125713501"},
        {name = "HORROR SCREAM 07", id = "9043345732"},
        {name = "Female Scream Woman Screams", id = "9114397912"},
        {name = "Scream1", id = "1319496541"},
        {name = "Scream2", id = "199978176"},
        {name = "scary maze scream", id = "270145703"},
        {name = "SammyClassicSonicFan's Scream", id = "143942090"},
        {name = "FNAF 2 Death Scream", id = "1572549161"},
        {name = "cod zombie scream", id = "8566359672"},
        {name = "Slendytubbies- CaveTubby Scream", id = "1482639185"},
        {name = "FNAF 2 Death Scream", id = "5537531920"},
        {name = "HORROR SCREAM 15", id = "9043346574"},
        {name = "Jumpscare Scream", id = "6150329916"},
        {name = "FNaF: Security Breach", id = "2050522547"},
        {name = "llllllll", id = "5029269312"},
        {name = "loud jumpscare", id = "7236490488"},
        {name = "fnaf", id = "6982454389"},
        {name = "Pinkamena Jumpscare 1", id = "192334186"},
        {name = "Ennard Jumpscare 2", id = "629526707"},
        {name = "a sla medo dino", id = "125506416092123"},
        {name = "Backrooms Bacteria Pitfalls ", id = "81325342128575"},
        
        {name = "error Infinite", id = "3893790326"},
        {name = "Screaming Meme", id = "107732411055226"},
        {name = "Jumpscare - SCP CB", id = "97098997494905"},
        {name = "mirror jumpscare", id = "80005164589425"},
        {name = "PTLD-39 Jumpscare", id = "5581462381"},
        {name = "jumpscare:Play()", id = "121519648044128"},
        {name = "mimic jumpscare", id = "91998575878959"},
        {name = "DOORS Glitch Jumpscare Sound", id = "96377507894391"},
        {name = "FNAS 4 Nightmare Mario", id = "99804224106385"},
        {name = "Death House I Jumpscare Sound", id = "8151488745"},
        {name = "Shinky Jumpscare", id = "123447772144411"},
        {name = "FNaTI Jumpscare Oblitus casa", id = "18338717319"},
        {name = "fnaf jumpscare loadmode", id = "18911896588"},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""}
    }
}, "jumpscar")


---------------------------------------------------------------------------------------------------------------------------------
                                          -- === Tab 8: Troll Musica === --
---------------------------------------------------------------------------------------------------------------------------------

local function tocarMusica(id)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Rádio (ToolMusicText)
    local argsRadio = {
        [1] = "ToolMusicText",
        [2] = id
    }
    ReplicatedStorage:WaitForChild("RE"):WaitForChild("PlayerToolEvent"):FireServer(unpack(argsRadio))
    
    -- Casa (PickHouseMusicText)
    local argsCasa = {
        [1] = "PickHouseMusicText",
        [2] = id
    }
    ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Player1sHous1e"):FireServer(unpack(argsCasa))

    -- Carro (PickingCarMusicText)
    local argsCarro = {
        [1] = "PickingCarMusicText",
        [2] = id
    }
    ReplicatedStorage:WaitForChild("RE"):WaitForChild("1Player1sCa1r"):FireServer(unpack(argsCarro))

    -- Scooter (PickingScooterMusicText)
    local argsScooter = {
        [1] = "PickingScooterMusicText",
        [2] = id
    }
    ReplicatedStorage:WaitForChild("RE"):WaitForChild("1NoMoto1rVehicle1s"):FireServer(unpack(argsScooter))
end

local function isValidMusicId(value)
    return value and value ~= "" and value ~= "Option 1" and not value:match("novas musica adds") and not value:match("musica brasil") and not value:match("musica do meu interece") and not value:match("musica dls por elas") and not value:match("meme abaixo") and not value:match("estourada")
end

Tab:AddSection({"Botar ID De Musicas por ID (Precisa de Gamepass)"})

Tab:AddTextBox({
    Name = "ID da música",
    PlaceholderText = "Digite o ID e pressione Enter",
    Callback = function(value)
        if value and value ~= "" then
            tocarMusica(tostring(value))
        end
    end
})

-- Dropdowns para Tab8
local function createMusicDropdown(title, musicOptions, defaultOption)
    local musicNames = {}
    local categoryMap = {}
    for category, sounds in pairs(musicOptions) do
        for _, music in ipairs(sounds) do
            if music.name ~= "" then
                table.insert(musicNames, music.name)
                categoryMap[music.name] = {id = music.id, category = category}
            end
        end
    end

    local function playMusic(soundId)
        tocarMusica(tostring(soundId)) -- Usa a função tocarMusica para tocar em todos os contextos
    end

    Tab:AddDropdown({
        Name = title,
        Description = "all",
        Default = defaultOption,
        Multi = false,
        Options = musicNames,
        Callback = function(selectedSound)
            if selectedSound and categoryMap[selectedSound] then
                local soundId = categoryMap[selectedSound].id
                if soundId and soundId ~= "" and soundId ~= "4354908569" then
                    playMusic(soundId)
                end
            end
        end
    })
end

-- Dropdown "Forró"
createMusicDropdown("Forró", {
    ["forro"] = {
        {name = "forró ja cansou", id = "74812784884330"},
        {name = "lenbro ate hoje", id = "71531533552899"},
        {name = "escolha certa", id = "107088620814881"},
        {name = "forró da rezenha", id = "120973520531216"},
        {name = "forró dudu", id = "74404168179733"},
        {name = "forró sao joao", id = "106364874935196"},
        {name = "forró engraçado paia", id = "76524290482399"},
        {name = "100% forro vaquejada", id = "92295159623916"},
        
        {name = "PASTOR MIRIM E A LÍNGUA DOS ANJOS", id = "71153532555470"},
        {name = "PARA NÃO ESQUECER QUEM SOMOS", id = "88937498361674"},
        {name = "Uno zero", id = "112959083808887"},
        {name = "Iate do neymar", id = "135738534706063"},
        {name = "Batidao na aldeia", id = "79953696595578"},
        {name = "", id = ""},
        {name = "", id = ""}
    }
}, "Option 1")

-- Dropdown "Músicas e Memes Aleatório"
createMusicDropdown("Músicas e Memes Aleatório", {
    ["forro"] = {
        {name = "ANXIETY (Amapiano Re-fix)", id = "101483901475189"}, 
        {name = "Meu corpo, minhas regras", id = "127587901595282"},
        {name = "$$$$gg$$$$gg", id = "137471775091253"},
        {name = "Megalovania but its only the melodies", id = "104500091160463"},
        {name = "androphono strikes back", id = "78312089943968"},
        {name = "Bamm Bamm", id = "128730685516895"},
        {name = "chupa cabra", id = "132890273173295"},
        {name = "longe de mais", id = "124478512057763"},
        {name = "Garoto de Copacabana", id = "135648634110254"},
        {name = "CELL!", id = "117634275895085"},
        {name = "Boa vibe em Ubatuba", id = "139059061493558"},
        {name = "SLIP AWAY", id = "126152928520174"},
        {name = "Alone in Motion", id = "122379348696948"},
        {name = "Fade Away", id = "81002139735874"},
        {name = "Wounds & Wishes", id = "109347979566607"},
        {name = "Ascensão do Monarca", id = "101864243033211"},
        {name = "carro do ovo", id = "3148329638"},
        {name = "ingles bus (fling ou kill bus)", id = "123268013026823"},
        {name = "MIKU MIKU HATSUNE", id = "112783541496955"},
        {name = "Five Nights at Freddy's", id = "110733765539890"},
        {name = "Rat Dance", id = "133496635668044"},
        {name = "Escalando a Seleção Brasileira para a Copa", id = "116546457407236"},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""}
    }
}, "Option 1")

-- Dropdown "Funk"
createMusicDropdown("Funk", {
    ["Funk"] = {
        {name = "sua mulher funk", id = "90844637105538"},
        {name = "fuga na viatura", id = "131891110268352"},
        {name = "funkphonk fumando verde", id = "112143944982807"},
        {name = "cauma xmara", id = "95664293972405"},
        {name = "que que sharke", id = "129546408528391"},
        {name = "Il Cacto Hipopotamo FUNK", id = "104491656009142"},
        {name = "Espressora Signora FUNK", id = "123394392737234"},
        {name = "trippi troop funk", id = "73049389767013"},
        {name = "bombini funkphonk", id = "88814770244609"},
        {name = "pre treino", id = "136869502216760"},
        {name = "CVRL", id = "124244582950595"},
        {name = "batida Brega Violino (Beat Brega Funk)", id = "99399643204701"},
        {name = "Dança do Canguru (Pke Gaz1nh)", id = "86876136192157"},
        {name = "espere 30segundos!! Ondas sonoras", id = "127757321382838"},
        {name = "MONTAGEM ARABIANA (Pke Gaz1nh)", id = "78076624091098"},
        {name = "Manda o papo (NGI)", id = "132642647937688"},
        {name = "Viver bem", id = "82805460494325"},
        {name = "Faixa estronda", id = "121187736532042"},
        {name = "Ritmo Pixelado", id = "93928823862203"},
        {name = "Viagem Sonora", id = "79349174602261"},
        {name = "Melodia Virtual", id = "139147474886402"},
        {name = "Melodia Serena", id = "97011217688307"},
        {name = "SENTA", id = "124085422276732"},
        {name = "TUNG TUNG TUNG TUNG SAHUR PHONK BRASILEIRO", id = "120353876640055"},
        {name = "crazy-lol", id = "106958630419629"},
        {name = "V7", id = "80348640826643"},
        {name = "UIUAH", id = "82894376737849"},
        {name = "meta ritmo", id = "110091098283354"},
        {name = "CAPPUCCINO ASSASSINO (SPEDUP)", id = "132733033157915"},
        {name = "haha (NGI)", id = "122114766584918"},
        {name = "DO PO", id = "114207745067816"},
        {name = "beat alucina", id = "12435156257"},
        {name = "novinha vem", id = "73962723234261"},
        {name = "melodia VV", id = "96974354995715"},
        {name = "Absorção", id = "82411642961457"},
        {name = "Mandelão raiz", id = "132642647937688"},
        {name = "Alemão", id = "85182585406642"},
        {name = "SADNESS", id = "97567416166163"},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""}
    }
}, "Option 1")

-- Dropdown "Phonk"
createMusicDropdown("Phonk", {
    ["phonk"] = {
        {name = "wyles", id = "85385155970460"},
        {name = "phonk kawai", id = "91502410121438"},
        {name = "querendo da a bucet@", id = "72720721570850"},
        {name = "vem no pocpoc", id = "102333419023382"},
        {name = "tatiu wim", id = "122871512353520"},
        {name = "novinha sapeca", id = "111668097052966"},
        {name = "novinha representa", id = "93786060174790"},
        {name = "phonk1", id = "77501611905348"},
        {name = "phonk2", id = "126887144190812"},
        {name = "phonk osadia", id = "88033569921555"},
        {name = "phonk sarra", id = "132436320685732"},
        {name = "relaionamento sem crush", id = "105832154444494"},
        {name = "phonk3", id = "90323407842935"},
        {name = "novinha dançapanpa", id = "132245626038510"},
        {name = "phonk sexoagreçivo", id = "111995323199676"},
        {name = "phonk4", id = "115016589376700"},
        {name = "phonk5", id = "118740708757685"},
        {name = "phonk6", id = "139435437308948"},
        {name = "phonk chapaquente", id = "109189438638906"},
        {name = "phonk rajada", id = "105126065014034"},
        {name = "rede globo", id = "138487820505005"},
        {name = "phonk indiano", id = "87968531262747"},
        {name = "vapo do vapo", id = "106317184644394"},
        {name = "tutatatutata", id = "112068892721408"},
        {name = "phonk slower", id = "122852029094656"},
        {name = "phonk9", id = "91760524161503"},
        {name = "phonk10", id = "73140398421340"},
        {name = "phonk11", id = "137962454483542"},
        {name = "phonk12", id = "84733736048142"},
        {name = "phonk13", id = "106322173003761"},
        {name = "phonk14", id = "94604796823780"},
        {name = "phonk15", id = "118063577904953"},
        {name = "phonk16", id = "115567432786512"},
        {name = "phonk toq", id = "71304501822029"},
        {name = "phonk hey", id = "132218979961283"},
        {name = "phonk17", id = "102708912256857"},
        {name = "phonk18", id = "140642559093189"},
        {name = "phonk neve", id = "13530439660"},
        {name = "phonk19", id = "87863924786534"},
        {name = "phonk20", id = "133135085604736"},
        {name = "phonk lento", id = "97258811783169"},
        {name = "phonk21", id = "92308400487695"},
        {name = "tipo wym", id = "88064647826500"},
        {name = "estouradassa1", id = "92175624643620"},
        {name = "estouradassa2", id = "108099943758978"},
        {name = "Naaaaa", id = "109784877184952"},
        {name = "trem", id = "114608169341947"},
        {name = "eoropa", id = "111346133543699"},
        {name = "atimosphekika", id = "77857496821844"},
        {name = "phonk ALL THE TIME", id = "123809083385992"},
        {name = "Lifelong Memory", id = "81929101024622"},
        {name = "Automotivo Blondie (Pke Gaz1nh)", id = "74564219749776"},
        {name = "สวัสดีคนไทย v2", id =  "118225359190317"},
        {name = "MTG TU VAI SENTAR (Pke Gaz1nh)", id = "115317874112657"},
        {name = "SARRA FUNK", id = "96249826607044"},
        {name = "Catuquanvan", id = "88038595663211"},
        {name = "F-D-1 (slowed)", id = "124958445624871"},
        {name = "Sucessagem", id = "88551699463723"},
        {name = "ILOVE phonksla", id = "82148953715595"},
        {name = "SPEED SLIDE", id = "118959437310311"},
        {name = "TOMA FUNK PHONK", id = "126291069838831"},
        {name = "PASSO BEM SOLTO X NEW JAZZ", id = "122706595087279"},
        {name = "MONTAGEM BIONICA DIAMANTE", id = "122338822665007"},
        {name = "BALA SELVAGEM!", id = "96180057167470"},
        {name = "Luz <3", id = "74281337525581"},
        {name = "COMO TU", id = "86928685812280"},
        {name = "MONTAGEM SOLAR TROPICANO (SPEED UP)", id = "116461681407294"},
        {name = "MONTAGEM SOLAR TROPICANO (SLOWED)", id = "109308273341422"},
        {name = "YO DE TI", id = "125181345407169"},
        {name = "Beauty, (Phonk), Super sped up", id = "71123357599630"},
        {name = "MONTAGEM BOOMBOX DO MALA FUNK", id = "86537505028256"},
        {name = "BRAZIL DO FUNK", id = "133498554139200"},
        {name = "BRR BRR PATAPIM FUNK", id = "117170901476451"},
        {name = "MONTAGEM TERRA BELA FUNK", id = "134770548505933"},
        {name = "FUNK DO RAVE 1.0", id = "137135395010424"},
        
        {name = " Portao Funk", id = "70900514961735"},
        {name = " Espaço Funk", id = "110519906029322"},
        {name = " FUTABA", id = "91834632690710"},
        {name = " Melódica Explosão De Melodia", id = "98371771055411"},
        {name = " RASGO", id = "98267810117949"},
        {name = " HIPNOTIZA", id = "117668905142866"},
        {name = "CRISTAL NOTURNO", id = "103695219371872"},
        {name = " SKY HIGH", id = "123517126955383"},
        {name = "MIKU top", id = "102771149931910"},
        {name = " ACABU SO FUNK", id = "127870227978818"},
        {name = "CREATIFE FUNK", id = "130525387712209"},
        {name = "GOTH FUNK", id = "97662362226511"},
        {name = "PORTUGESE FUNK", id = "125858109122379"},
        {name = "SUBURBANA", id = "139825057894568"},
        {name = "ESPERA LA NOCHE FUNK", id = "139768056738146"},
        {name = "SIN PERMISO FUNK", id = "92572896648274"},
        {name = "MONTAGEM DACE RAT", id = "98711199754623"},
        {name = " LOVELY FUNK", id = "130633105268814"},
        {name = "STORYMODECOOL", id = "87115976125426"},
        {name = "BLACK COFFEE FUNK", id = "82705137378395"},
        {name = "KOBALT", id = "79381341943021"},
        {name = " andante bacterial", id = "105882833374061"},
        {name = "ANGEL Speed Up", id = "139593870988593"},
        {name = "LUTA ÉPICA", id = "73966367524216"},
        {name = "MALDITA", id = "133814632960968"},
        {name = "DA ZONA NTJ VERSON", id = "105770593501071"},
        {name = "HIPNOTIZA", id = "132015050363205"},
        {name = "MIDZUKI speed up", id = "129151948619922"},
        
        {name = "movimenta funk", id = "114994598691121"},
        {name = "CRISTAL", id = "103445348511856"},
        {name = "Letero funkphonk", id = "99409598156364"},
        {name = "montagem luna", id = "97279560249940"},
        {name = "passo bem solto", id = "137466814003263"},
        {name = "masha ultraphonk", id = "95248559316142"},
        {name = "67 phonk", id = "122854357582130"},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""},
        {name = "", id = ""}
    }
}, "Option 1")

Tab:AddButton({
    Name = "Stop",
    Description = "ALL music",
    Callback = function()
        tocarMusica("")
    end
})

-- Create a section
Tab:AddSection({"Musica"})

local audios = {
    {Name = "Yamete Kudasai", ID = 108494476595033},
    {Name = "Gritinho", ID = 5710016194},
    {Name = "Jumpscare Horroroso", ID = 85435253347146},
    {Name = "Áudio Alto", ID = 6855150757},
    {Name = "Ruído", ID = 120034877160791},
    {Name = "Jumpscare 2", ID = 110637995610528},
    {Name = "Risada Da Bruxa Minecraft", ID = 116214940486087},
    {Name = "The Boiled One", ID = 137177653817621},
    {Name = "Deitei Um Ave Maria Doido", ID = 128669424001766},
    {Name = "Mandrake Detected", ID = 9068077052},
    {Name = "Aaaaaaaaa", ID = 80156405968805},
    {Name = "AAAHHHH", ID = 9084006093},
    {Name = "amongus", ID = 6651571134},
    {Name = "Sus", ID = 6701126635},
    {Name = "Gritao AAAAAAAAA", ID = 5853668794},
    {Name = "UHHHHH COFFCOFF", ID = 7056720271},
    {Name = "SUS", ID = 7153419575},
    {Name = "Sonic.exe", ID = 2496367477},
    {Name = "Tubers93 1", ID = 270145703},
    {Name = "Tubers93 2", ID = 18131809532},
    {Name = "John's Laugh", ID = 130759239},
    {Name = "Nao sei KKKK", ID = 6549021381},
    {Name = "Grito", ID = 80156405968805},
    {Name = "audio estranho", ID = 7705506391},
    {Name = "AAAH", ID = 7772283448},
    {Name = "Gay, gay", ID = 18786647417},
    {Name = "Bat Hit", ID = 7129073354},
    {Name = "Nuclear Siren", ID = 675587093},
    {Name = "Sem ideia de nome KK", ID = 7520729342},
    {Name = "Grito 2", ID = 91412024101709},
    {Name = "Estora tímpano", ID = 268116333},
    {Name = "[ Content Deleted ]", ID = 106835463235574},
    {Name = "Toma Jack", ID = 132603645477541},
    {Name = "Pede ifood pede", ID = 133843750864059},
    {Name = "I Ghost The down", ID = 84663543883498},
    {Name = "Compre OnLine Na shoope", ID = 8747441609},
    {Name = "Uh Que Nojo", ID = 103440368630269},
    {Name = "Sai dai Lava Prato", ID = 101232400175829},
    {Name = "Seloko num compensa", ID = 78442476709262},
    {Name = "(NEW) Chimpanzini Bananini Funk", ID = 137148228908678},
    {Name = "(NEW) Candyland - Tobu", ID = 118939739460633},
    {Name = "(NEW) Meme do Dom pollo What the hell", ID = 100656590080703},
    {Name = "(NEW) não to entendendo nd meme estourado", ID = 7962533987},
    {Name = "pankapakan", ID = 122547522269143},
    {Name = "Gemido ultra rápido", ID = 128863565301778},
    {Name = "vai g0z@?", ID = 116293771329297},
    {Name = "G0z33iiii", ID = 93462644278510},
    {Name = "Hommmm ", ID = 133135656929513},
    {Name = "gemido1", ID = 105263704862377},
    {Name = " gemido2", ID = 92186909873950},
    {Name = "sus sex", ID = 128137573022197},
    {Name = "gemido estranho", ID = 131219411501419},
    {Name = "gemido kawai", ID = 100409245129170},
    {Name = "Hentai wiaaaaan", ID = 88332347208779},
    {Name = "iamete cunasai", ID = 108494476595033},
    {Name = "dodichan onnn...", ID = 134640594695384},
    {Name = "Loly gemiD0", ID = 119277017538197},
    {Name = "ai poison", ID = 115870718113313},
    {Name = "chegachega SUS", ID = 77405864184828},
    {Name = "uwu", ID = 76820720070248},
    {Name = "ai meu cuzin", ID = 130714479795369},
    {Name = "girl audio 2", ID = 84207358477461},
    {Name = "Hoo ze da manga", ID = 106624090319571},
    {Name = "ai alexandre de moraes", ID = 107261471941570},
    {Name = "haaii meme", ID = 120006672159037},
    {Name = "GoGogo gogogo", ID = 103262503950995},
    {Name = "Toma jack", ID = 132603645477541},
    {Name = "Toma jackV2", ID = 100446887985203},
    {Name = "Toma jack no sol quente", ID = 97476487963273},
    {Name = "ifood", ID = 133843750864059},
    {Name = "pelo geito ela ta querendo ram", ID = 94395705857835},
    {Name = "lula vai todo mundo", ID = 136804576009416},
    {Name = "coringa", ID = 84663543883498},
    {Name = "shoope", ID = 8747441609},
    {Name = "quenojo", ID = 103440368630269},
    {Name = "sai dai lava prato", ID = 101232400175829},
    {Name = "se e loko numconpeça", ID = 78442476709262},
    {Name = "mita sequer que eu too uma", ID = 94889439372168},
    {Name = "Hoje vou ser tua mulher e tu", ID = 90844637105538},
    {Name = "Deita aqui eu mandei vc deitar sirens", ID = 100291188941582},
    {Name = "miau", ID = 131804436682424},
    {Name = "skibidi", ID = 128771670035179},
    {Name = "BIRULEIBI", ID = 121569761604968},
    {Name = "biseabesjnjkasnakjsndjkafb", ID = 133106998846260},
    {Name = "vai corinthians!!....", ID = 127012936767471},
    {Name = "my sigman", ID = 103431815659907},
    {Name = "mama", ID = 106850066985594},
    {Name = "OH MY GOD", ID = 73349649774476},
    {Name = "aahhh plankton meme", ID = 95982351322190},
    {Name = "CHINABOY", ID = 84403553163931},
    {Name = "PASTOR MIRIM E A LÍNGUA DOS ANJOS", ID = 71153532555470},
    {Name = "Sai d3sgraç@", ID = 106973692977609},
    {Name = "opa salve tudo bem?", ID = 80870678096428},
    {Name = "OLHA O CARRO DO DANONE", ID = 110493863773948},
    {Name = "Nãoooo, Nãoooo, Nãooo!!!!!", ID = 95825536480898},
    {Name = "UM PÉ DE SIRIGUELA KK", ID = 112804043442210},
    {Name = "e o carro da pamonha", ID = 94951629392683},
    {Name = "BOM DIAAAAAAAAAA", ID = 136579844511260},
    {Name = "ai-meu-chiclete", ID = 92911732806153},
    {Name = "posso te ligar ou tua mulher...", ID = 103211341252816},
    {Name = "Boa chi joga muito cara", ID = 110707564387669},
    {Name = "Oqueee meme", ID = 120092799810101},
    {Name = "kkk muito fei", ID = 79241074803021},
    {Name = "lula cade o ze gotinha", ID = 86012585992725},
    {Name = "morreu", ID = 8872409975},
    {Name = "a-pia-ta-cheia-de-louca", ID = 98076927129047},
    {Name = "Mahito killSong", ID = 128669424001766},
    {Name = "Sucumba", ID = 7946300950},
    {Name = "nem clicou o thurzin", ID = 84428355313544},
    {Name = "fiui OLHA MENSAGEM", ID = 121668429878811},
    {Name = "tooomeee", ID = 128319664118768},
    {Name = "risada de ladrao", ID = 133065882609605},
    {Name = "E o PIX nada ainda", ID = 113831443375212},
    {Name = "Vo nada vo nada", ID = 89093085290586},
    {Name = "Eli gosta", ID = 105012436535315},
    {Name = "um cavalo de tres pernas?", ID = 8164241439},
    {Name = "voces sao um bado de fdp", ID = 8232773326},
    {Name = "HAHA TROLLEI ATÉ VOCÊ", ID = 7021794555},
    {Name = "Calaboca Kenga", ID = 86494561679259},
    {Name = "alvincut", ID = 88788640194373},
    {Name = "e a risada faz como?", ID = 140713372459057},
    {Name = "voce deve se m@t4", ID = 100227426848009},
    {Name = "receba", ID = 94142662616215},
    {Name = "UUIIII", ID = 73210569653520},
    {Name = "sai", ID = 121169949217007},
    {Name = "risada boa dms", ID = 127589011971759},
    {Name = "vacilo perna de pau", ID = 106809680656199},
    {Name = "gomo gomo no!!!", ID = 137067472449625},
    {Name = "arroto", ID = 140203378050178},
    {Name = "iraaaa", ID = 136752451575091},
    {Name = "não fica se achando muito não", ID = 101588606280167},
    {Name = "WhatsApp notificaçaoV1", ID = 107004225739474},
    {Name = "WhatsApp notificaçaoV2", ID = 18850631582},
    {Name = "SamsungV1", ID = 123767635061073},
    {Name = "SamsungV2", ID = 96579234730244},
    {Name = "Shiiii", ID = 120566727202986},
    {Name = "ai_tomaa miku", ID = 139770074770361},
    {Name = "Miku Miku", ID = 72812231495047},
    {Name = "kuru_kuru", ID = 122465710753374},
    {Name = "PM ROCAM", ID = 96161547081609},
    {Name = "cavalo!!", ID = 78871573440184},
    {Name = "deixa os garoto brinca", ID = 80291355054807},
    {Name = "flamengo", ID = 137774355552052},
    {Name = "sai do mei satnas", ID = 127944706557246},
    {Name = "namoral agora e a hora", ID = 120677947987369},
    {Name = "n pode me chutar pq seu celebro e burro", ID = 82284055473737},
    {Name = "vc ta fudido vou te pegar", ID = 120214772725166},
    {Name = "deley", ID = 102906880476838},
    {Name = "Tu e um beta", ID = 130233956349541},
    {Name = "Porfavor n tira eu nao", ID = 85321374020324},
    {Name = "Olá beleza vc pode me dá muitos", ID = 74235334504693},
    {Name = "Discord sus", ID = 122662798976905},
    {Name = "rojao apito", ID = 6549021381},
    {Name = "off", ID = 1778829098},
    {Name = "Kazuma kazuma", ID = 127954653962405},
    {Name = "sometourado", ID = 123592956882621},
    {Name = "Estouradoespad", ID = 136179020015211},
    {Name = "Alaku bommm", ID = 110796593805268},
    {Name = "busss", ID = 139841197791567},
    {Name = "Estourado wItb", ID = 137478052262430},
    {Name = "sla", ID = 116672405522828},
    {Name = "HA HA HA", ID = 138236682866721}
}

local selectedAudioID

Tab:AddSection({"Tocar ID De Musica"})

-- Adicionar uma textbox para inserir o ID do áudio
Tab:AddTextBox({
    Name = "Insira o ID do Áudio ou Musica",
    Description = "Digite o ID do áudio",
    PlaceholderText = "ID do áudio",
    Callback = function(value)
        selectedAudioID = tonumber(value)
    end
})

-- Adicionar uma dropdown para selecionar o áudio
local audioNames = {}
for _, audio in ipairs(audios) do
    table.insert(audioNames, audio.Name)
end

Tab:AddDropdown({
    Name = "Selecione o Áudio",
    Description = "Escolha um áudio da lista",
    Options = audioNames,
    Default = audioNames[1],
    Flag = "selected_audio",
    Callback = function(value)
        for _, audio in ipairs(audios) do
            if audio.Name == value then
                selectedAudioID = audio.ID
                break
            end
        end
    end
})

-- Controle do loop
local audioLoop = false

-- Nova seção para loop de áudio
Tab:AddSection({"Loop de Audio"})

-- Função para tocar o áudio repetidamente
local function playLoopedAudio()
    while audioLoop do
        if selectedAudioID then
            local args = {
                [1] = game:GetService("Workspace"),
                [2] = selectedAudioID,
                [3] = 1,
            }
            game:GetService("ReplicatedStorage").RE:FindFirstChild("1Gu1nSound1s"):FireServer(unpack(args))

            -- Criar e tocar o áudio
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://" .. selectedAudioID
            sound.Parent = game.Players.LocalPlayer.Character.HumanoidRootPart
            sound:Play()
        else
            warn("Nenhum áudio selecionado!")
        end

        task.wait(0.5) -- Pequeno delay para evitar sobrecarga
    end
end

-- Toggle para loop de áudio
Tab:AddToggle({
    Name = "Loop Tocar Áudio",
    Description = "Ativa o loop do áudio",
    Default = false,
    Flag = "audio_loop",
    Callback = function(value)
        audioLoop = value
        if audioLoop then
            task.spawn(playLoopedAudio) -- Inicia o loop em uma nova thread
        end
    end
})

-- Adicionar um parágrafo como label
Tab:AddParagraph({"Info", "Loop de tocar Áudio (Todos players do Server ouvem)"})

-- Função para tocar o áudio normal
local function playAudio()
    if selectedAudioID then
        local args = {
            [1] = game:GetService("Workspace"),
            [2] = selectedAudioID,
            [3] = 1,
        }
        game:GetService("ReplicatedStorage").RE:FindFirstChild("1Gu1nSound1s"):FireServer(unpack(args))

        -- Criar e tocar o áudio
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. selectedAudioID
        sound.Parent = game.Players.LocalPlayer.Character.HumanoidRootPart
        sound:Play()
    else
        warn("Nenhum áudio selecionado!")
    end
end

-- Nova seção para tocar áudio
Tab:AddSection({"Tocar Áudio"})

-- Botão para tocar o áudio
Tab:AddButton({"Tocar Áudio", function()
    playAudio()
end})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local audioID = 6314880174 -- ID fixo do áudio

local function Audio_All_ClientSide(ID)
    local function CheckFolderAudioAll()
        local FolderAudio = workspace:FindFirstChild("Audio all client")
        if not FolderAudio then
            FolderAudio = Instance.new("Folder")
            FolderAudio.Name = "Audio all client"
            FolderAudio.Parent = workspace
        end
        return FolderAudio
    end

    local function CreateSound(ID)
        if type(ID) ~= "number" then
            print("Insira um número válido!")
            return nil
        end

        local Folder_Audio = CheckFolderAudioAll()
        if Folder_Audio then
            local Sound = Instance.new("Sound")
            Sound.SoundId = "rbxassetid://" .. ID
            Sound.Volume = 1
            Sound.Looped = false
            Sound.Parent = Folder_Audio
            Sound:Play()
            task.wait(1) -- Tempo de espera antes de remover o som
            Sound:Destroy()
        end
    end

    CreateSound(ID)
end

local function Audio_All_ServerSide(ID)
    if type(ID) ~= "number" then
        print("Insira um número válido!")
        return nil
    end

    local GunSoundEvent = ReplicatedStorage:FindFirstChild("1Gu1nSound1s", true)
    if GunSoundEvent then
        GunSoundEvent:FireServer(workspace, ID, 1)
    end
end

-- Toggle para "Estourar ouvido de geral"
Tab:AddToggle({
    Name = "Estorar ouvido de geral KKKKKK",
    Description = "Toca áudio repetidamente para todos",
    Default = false,
    Flag = "audio_spam",
    Callback = function(value)
        getgenv().Audio_All_loop_fast = value

        while getgenv().Audio_All_loop_fast do
            Audio_All_ServerSide(audioID)
            task.spawn(function()
                Audio_All_ClientSide(audioID)
            end)
            task.wait(0.03) -- Delay extremamente rápido (0.03 segundos)
        end
    end
})

Tab:AddParagraph({"Info", "Todos do server ouvem o áudio"})

-- SCRIPT DE PROTEÇÃO OTIMIZADO (SEM EXCESSO DE VARIÁVEIS LOCAIS)
local ImunesTab = Window:MakeTab({"Protection", "rbxassetid://11322093465"})

-- Serviços (reutilizados)
local LP = game:GetService("Players").LocalPlayer
local WS = game:GetService("Workspace")
local RS = game:GetService("RunService")

-- Tabela única para gerenciar tudo
local System = {
    backup = {vehicles = {}, canoes = {}, jets = {}, helis = {}, balls = {}},
    connections = {},
    config = {selectedPlayer = "", hiddenDoors = {}, hiddenPlayers = {}}
}

-- Funções principais
function System:moveToBackup(obj, key)
    table.insert(self.backup[key], {obj = obj, parent = obj.Parent})
    obj.Parent = nil
end

function System:restore(key)
    for _, data in ipairs(self.backup[key]) do
        if data.obj and data.parent then
            pcall(function() data.obj.Parent = data.parent end)
        end
    end
    table.clear(self.backup[key])
end

function System:disconnect(name)
    if self.connections[name] then
        self.connections[name]:Disconnect()
        self.connections[name] = nil
    end
end

-- ==================== SEÇÕES ====================

ImunesTab:AddSection({Name = "Scripts de Proteção Linux Hub"})

ImunesTab:AddButton({
    Name = "Anti Freeze",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Anti-freeze/refs/heads/main/Main%20(3).txt"))()
    end
})

ImunesTab:AddButton({
    Name = "Anti Chaos Hub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Ant-chaos-hub/refs/heads/main/Ant"))()
    end
})

ImunesTab:AddButton({
    Name = "Anti Som",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Anti-som/refs/heads/main/Main%20(2).txt"))()
    end
})

-- ==================== ANTI FLINGS ====================

ImunesTab:AddSection({Name = "Anti Flings"})

ImunesTab:AddToggle({
    Name = "Anti Fling Veículos",
    Default = false,
    Callback = function(s)
        System:disconnect("vehicles")
        if s then
            System.connections.vehicles = RS.Heartbeat:Connect(function()
                local vf = WS:FindFirstChild("Vehicles")
                if not vf then return end
                for _, v in ipairs(vf:GetChildren()) do
                    local mine = false
                    for _, seat in ipairs(v:GetDescendants()) do
                        if (seat:IsA("VehicleSeat") or seat:IsA("Seat")) and seat.Occupant and seat.Occupant.Parent == LP.Character then
                            mine = true
                            break
                        end
                    end
                    if not mine and v.Parent == vf then
                        System:moveToBackup(v, "vehicles")
                    end
                end
            end)
        else
            System:restore("vehicles")
        end
    end
})

ImunesTab:AddToggle({
    Name = "Anti Canoe Fling",
    Default = false,
    Callback = function(s)
        System:disconnect("canoes")
        if s then
            System.connections.canoes = RS.Heartbeat:Connect(function()
                local st = WS:FindFirstChild("WorkspaceCom")
                st = st and st:FindFirstChild("001_CanoeStorage")
                if not st then return end
                for _, c in ipairs(st:GetChildren()) do
                    local owner = c:FindFirstChild("Owner")
                    if not owner or owner.Value ~= LP then
                        if c.Parent == st then System:moveToBackup(c, "canoes") end
                    end
                end
            end)
        else
            System:restore("canoes")
        end
    end
})

ImunesTab:AddToggle({
    Name = "Anti Fling Jets",
    Default = false,
    Callback = function(s)
        System:disconnect("jets")
        if s then
            System.connections.jets = RS.Heartbeat:Connect(function()
                local jf = WS:FindFirstChild("WorkspaceCom")
                jf = jf and jf:FindFirstChild("001_Airport")
                jf = jf and jf:FindFirstChild("AirportHanger")
                jf = jf and jf:FindFirstChild("001_JetStorage")
                jf = jf and jf:FindFirstChild("JetAirport")
                if not jf then return end
                for _, j in ipairs(jf:GetChildren()) do
                    if j.Name ~= LP.Name and j.Parent == jf then
                        System:moveToBackup(j, "jets")
                    end
                end
            end)
        else
            System:restore("jets")
        end
    end
})

ImunesTab:AddToggle({
    Name = "Anti Fling Helicópteros",
    Default = false,
    Callback = function(s)
        System:disconnect("helis")
        if s then
            System.connections.helis = RS.Heartbeat:Connect(function()
                local hf = WS:FindFirstChild("WorkspaceCom")
                hf = hf and hf:FindFirstChild("001_HeliStorage")
                hf = hf and hf:FindFirstChild("PoliceStationHeli")
                if not hf then return end
                for _, h in ipairs(hf:GetChildren()) do
                    if h.Name ~= LP.Name and h.Parent == hf then
                        System:moveToBackup(h, "helis")
                    end
                end
            end)
        else
            System:restore("helis")
        end
    end
})

ImunesTab:AddToggle({
    Name = "Anti Fling Ball",
    Default = false,
    Callback = function(s)
        System:disconnect("balls")
        if s then
            System.connections.balls = RS.Heartbeat:Connect(function()
                local bf = WS:FindFirstChild("WorkspaceCom")
                bf = bf and bf:FindFirstChild("001_SoccerBalls")
                if not bf then return end
                for _, b in ipairs(bf:GetChildren()) do
                    if b.Parent == bf then System:moveToBackup(b, "balls") end
                end
            end)
        else
            System:restore("balls")
        end
    end
})

-- ==================== OUTROS ====================

ImunesTab:AddSection({Name = "Anti Sit & Anti Lag & Anti Fling Porta"})

ImunesTab:AddToggle({
    Name = "Anti Sit",
    Default = false,
    Callback = function(s)
        System:disconnect("sit")
        if s then
            System.connections.sit = RS.Heartbeat:Connect(function()
                local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if h then
                    h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                    if h:GetState() == Enum.HumanoidStateType.Seated then
                        h:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    if h.SeatPart then
                        h.Sit = false
                        h.SeatPart = nil
                    end
                end
            end)
        else
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
        end
    end
})

ImunesTab:AddToggle({
    Name = "Anti-Lag (Todas Tools)",
    Default = false,
    Callback = function(s)
        if not s then return end
        
        local lock = {}
        local ignored = LP
        
        local function gather(p)
            local t = {}
            local c = {p.Character, p:FindFirstChildOfClass("Backpack"), p:FindFirstChild("StarterGear")}
            for _, cont in ipairs(c) do
                if cont then
                    for _, ch in ipairs(cont:GetChildren()) do
                        if ch:IsA("Tool") then table.insert(t, ch) end
                    end
                end
            end
            return t
        end
        
        local function dedup(p)
            if p == ignored or lock[p] then return end
            lock[p] = true
            local tools = gather(p)
            if #tools > 1 then
                for i = 2, #tools do pcall(function() tools[i]:Destroy() end) end
            end
            lock[p] = false
        end
        
        local function hook(p)
            task.defer(dedup, p)
            local function onChar(c)
                task.delay(0.5, function() dedup(p) end)
                c.ChildAdded:Connect(function(ch)
                    if ch:IsA("Tool") then task.delay(0.1, function() dedup(p) end) end
                end)
            end
            if p.Character then onChar(p.Character) end
            p.CharacterAdded:Connect(onChar)
            
            local bp = p:WaitForChild("Backpack", 10)
            if bp then
                bp.ChildAdded:Connect(function(ch)
                    if ch:IsA("Tool") then task.delay(0.1, function() dedup(p) end) end
                end)
            end
        end
        
        game:GetService("Players").PlayerAdded:Connect(hook)
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do hook(plr) end
        
        task.spawn(function()
            while s do
                for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do dedup(plr) end
                task.wait(2)
            end
        end)
    end
})

ImunesTab:AddToggle({
    Name = "Anti Fling Porta",
    Default = false,
    Callback = function(s)
        if s then
            System.config.hiddenDoors = {}
            for _, o in ipairs(workspace:GetDescendants()) do
                if o:IsA("BasePart") and o.Name:lower():find("door") then
                    table.insert(System.config.hiddenDoors, {
                        d = o,
                        t = o.Transparency,
                        c = o.CanCollide,
                        s = o.CastShadow
                    })
                    o.Transparency = 1
                    o.CanCollide = false
                    o.CastShadow = false
                end
            end
        else
            for _, data in ipairs(System.config.hiddenDoors) do
                if data.d and data.d.Parent then
                    data.d.Transparency = data.t
                    data.d.CanCollide = data.c
                    data.d.CastShadow = data.s
                end
            end
            System.config.hiddenDoors = {}
        end
    end
})

ImunesTab:AddSection({Name = "Apagar Jogador Do Mapa"})

ImunesTab:AddTextBox({
    Name = "Nome do Jogador",
    PlaceholderText = "Digite o nome...",
    Callback = function(i)
        System.config.selectedPlayer = i
    end
})

ImunesTab:AddToggle({
    Name = "Sumir Jogador",
    Default = false,
    Callback = function(s)
        local p = game:GetService("Players"):FindFirstChild(System.config.selectedPlayer)
        if not p then
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Erro",
                Text = "Jogador não encontrado!",
                Duration = 3
            })
            return
        end
        
        if s then
            if p ~= LP and p.Character then
                System.config.hiddenPlayers[p.Name] = p.Character
                p.Character.Parent = nil
            end
        else
            if System.config.hiddenPlayers[p.Name] then
                System.config.hiddenPlayers[p.Name].Parent = workspace
                System.config.hiddenPlayers[p.Name] = nil
            end
        end
    end
})

local feTab = Window:MakeTab({"FE - by Shadows", "rbxassetid://17829956110"})

feTab:AddSection({ "Zombie FE" })

feTab:AddButton({
    Name = "Zombie",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Zombie-FE/refs/heads/main/Zombie"))()
    end
})

feTab:AddSection({ "Goner FE" })

feTab:AddButton({
    Name = "Goner",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/GONER-AJAJAKKAKAK/refs/heads/main/Goner"))()
    end
})

feTab:AddSection({ "Tubers93 FE" })

feTab:AddButton({
    Name = "Tubers93",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Tubers/refs/heads/main/95"))()
    end
})

feTab:AddSection({ "SCP 173 FE" })

feTab:AddButton({
    Name = "SCP 173",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/SCP-173/refs/heads/main/Scp"))()
    end
})

feTab:AddSection({ "1x1x1x1 FE" })

feTab:AddButton({
    Name = "1x1x1x1",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/1x1x1x1/refs/heads/main/1x1x1x1"))()
    end
})

feTab:AddSection({ "Anjo FE" })

feTab:AddButton({
    Name = "Anjo",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ShadowsHubseila/Anjo/refs/heads/main/FE"))()
    end
})

local Tab6 = Window:MakeTab({
    Title = "RGB",
    Icon = "rbxassetid://84892688077238"
})

Tab6:AddSection({Name = ""})

local RGBStates = {
    nome = false, bio = false, corpo = false, casa = false,
    carro = false, bicicleta = false, radio = false,
    megafone = false, rosquinha = false, spamRoses = false, speed = 1
}

local LP = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

Tab6:AddSlider({
    Name = "Velocidade RGB",
    Description = "Aumenta a velocidade do efeito RGB",
    Min = 1, Max = 5, Increase = 1, Default = 3,
    Callback = function(v) RGBStates.speed = v end
})

local function getColor()
    return Color3.fromHSV(((tick() * RGBStates.speed * 20) % 100) / 100, 1, 1)
end

local function fire(e, a)
    local r = RS:FindFirstChild("RE")
    if r and r:FindFirstChild(e) then
        pcall(function() r[e]:FireServer(unpack(a)) end)
    end
end

Tab6:AddSection({Name = "RGB para usar em você"})

Tab6:AddToggle({
    Name = "RGB Nome",
    Description = "RGB apenas no nome",
    Default = false,
    Callback = function(s)
        RGBStates.nome = s
        if s then
            task.spawn(function()
                while RGBStates.nome and LP.Character do
                    fire("1RPNam1eColo1r", {"PickingRPNameColor", getColor()})
                    task.wait(0.2)
                end
            end)
        end
    end
})

Tab6:AddToggle({
    Name = "RGB Bio",
    Description = "RGB apenas na bio",
    Default = false,
    Callback = function(s)
        RGBStates.bio = s
        if s then
            task.spawn(function()
                while RGBStates.bio and LP.Character do
                    fire("1RPNam1eColo1r", {"PickingRPBioColor", getColor()})
                    task.wait(0.2)
                end
            end)
        end
    end
})

Tab6:AddToggle({
    Name = "RGB Corpo",
    Description = "RGB no corpo",
    Default = false,
    Callback = function(s)
        RGBStates.corpo = s
        if s then
            task.spawn(function()
                while RGBStates.corpo do
                    local c = BrickColor.new(getColor()).Name
                    local r = RS:FindFirstChild("Remotes")
                    if r and r:FindFirstChild("ChangeBodyColor") then
                        pcall(function() r.ChangeBodyColor:FireServer(c) end)
                    end
                    task.wait(0.3)
                end
            end)
        end
    end
})

Tab6:AddSection({Name = "Veículos e casa"})

Tab6:AddToggle({
    Name = "RGB Casa",
    Description = "RGB na casa",
    Default = false,
    Callback = function(s)
        RGBStates.casa = s
        if s then
            task.spawn(function()
                while RGBStates.casa do
                    fire("1Player1sHous1e", {"ColorPickHouse", getColor()})
                    task.wait(0.25)
                end
            end)
        end
    end
})

Tab6:AddToggle({
    Name = "Carro RGB (Premium)",
    Description = "RGB no carro. Pode causar kick se não for premium!",
    Default = false,
    Callback = function(s)
        RGBStates.carro = s
        if s then
            task.spawn(function()
                while RGBStates.carro and LP.Character do
                    fire("1Player1sCa1r", {"PickingCarColor", getColor()})
                    task.wait(0.2)
                end
            end)
        end
    end
})

Tab6:AddToggle({
    Name = "RGB Bicicleta",
    Description = "RGB na bicicleta",
    Default = false,
    Callback = function(s)
        RGBStates.bicicleta = s
        if s then
            task.spawn(function()
                while RGBStates.bicicleta do
                    fire("1Player1sCa1r", {"NoMotorColor", getColor()})
                    task.wait(0.25)
                end
            end)
        end
    end
})

Tab6:AddSection({Name = "Itens/Tool"})

local function itemRGB(n, w)
    return function(s)
        RGBStates[n] = s
        if s then
            task.spawn(function()
                while RGBStates[n] and LP.Character do
                    local ok, r = pcall(function()
                        return LP.PlayerGui.ToolGui.ToolSettings.Settings.PropsColor.SetColor
                    end)
                    if ok and r then
                        pcall(function() r:FireServer(getColor()) end)
                    end
                    task.wait(w)
                end
            end)
        end
    end
end

Tab6:AddToggle({
    Name = "Rádio RGB",
    Description = "RGB no rádio",
    Default = false,
    Callback = itemRGB("radio", 0.2)
})

Tab6:AddToggle({
    Name = "RGB Megafone",
    Description = "RGB no megafone",
    Default = false,
    Callback = itemRGB("megafone", 0.25)
})

Tab6:AddToggle({
    Name = "RGB Rosquinha",
    Description = "RGB na rosquinha",
    Default = false,
    Callback = itemRGB("rosquinha", 0.25)
})

Tab6:AddToggle({
    Name = "RGB Rosas",
    Description = "RGB nas rosas",
    Default = false,
    Callback = function(s)
        RGBStates.spamRoses = s
        if s then
            pcall(function()
                local r = RS:FindFirstChild("RE")
                if r and r:FindFirstChild("1Too1l") then
                    r["1Too1l"]:InvokeServer("PickingTools", "Roses")
                end
            end)
            task.wait(0.5)
            task.spawn(function()
                local sons = {
                    "rbxassetid://5210414112",
                    "rbxassetid://5216708760",
                    "rbxassetid://5210414520",
                    "rbxassetid://5210399458"
                }
                local i = 1
                while RGBStates.spamRoses do
                    pcall(function()
                        local t = LP.Character and LP.Character:FindFirstChild("Roses")
                        if t and t:FindFirstChild("ToolSound") then
                            t.ToolSound:FireServer("Roses", sons[i])
                        end
                    end)
                    i = i % #sons + 1
                    task.wait(0.03)
                end
            end)
        end
    end
})

local msg = "VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T HUB VEIO VER CONSOLE NE SKIDDER? BLOQUEIO BY BLESSED TEAM & G H O S T"
while true do
    print(msg)
    task.wait(0.01)
end

local Whitelist = loadstring(game:HttpGet("https://pastefy.app/6Hw1KSoN/raw"))()

local PlayerName = game.Players.LocalPlayer.Name -- Nome completo do jogador

local whitelisted = false

for _, v in pairs(Whitelist) do
    if v == PlayerName then
        whitelisted = true
        break
    end
end

if whitelisted then
    print("O jogador está na Whitelist. Nome: ", PlayerName)
else
    game.Players.LocalPlayer:Kick("Você não está na Whitelist")
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Test



-- Set theme:
--WindUI:SetTheme("Light")

--- EXAMPLE !!!

function gradient(text, startColor, endColor)
    local result = ""
    local length = #text

    for i = 1, length do
        local t = (i - 1) / math.max(length - 1, 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * t) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * t) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * t) * 255)

        local char = text:sub(i, i)
        result = result .. "<font color=\"rgb(" .. r ..", " .. g .. ", " .. b .. ")\">" .. char .. "</font>"
    end

    return result
end

local Confirmed = false

WindUI:Popup({
    Title = "Seja muito bem-vindo(a)",
    Icon = "info",
    Content = "Essa é a versão " .. gradient("Elite", Color3.fromHex("#00FF87"), Color3.fromHex("#60EFFF")) .. " do Blessed Hub",
    Buttons = {
        {
            Title = "Não abrir o Blessed Hub :(",
            --Icon = "",
            Callback = function() end,
            Variant = "Secondary", -- Primary, Secondary, Tertiary
        },
        {
            Title = "Abrir o Blessed Hub :)",
            Icon = "arrow-right",
            Callback = function() Confirmed = true end,
            Variant = "Primary", -- Primary, Secondary, Tertiary
        }
    }
})


repeat wait() until Confirmed

--

local Window = WindUI:CreateWindow({
    Title = "Blessed Hub | Elite",
    Icon = "crown",
    Author = "Gab Scripts",
    Folder = "CloudHub",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    User = {
        Enabled = true, -- <- or false
        Callback = function() print("clicked") end, -- <- optional
        Anonymous = true -- <- or true
    },
    SideBarWidth = 200,
    --Background = "rbxassetid://13511292247", -- rbxassetid only
    HasOutline = true,
    -- remove it below if you don't want to use the key system in your script.
    --KeySystem = { -- <- keysystem enabled
        Key = { "1234", "5678" },
        Note = "Example Key System. \n\nThe Key is '1234' or '5678",
        -- Thumbnail = {
        --     Image = "rbxassetid://18220445082", -- rbxassetid only
        --     Title = "Thumbnail"
        -- },
        URL = "https://github.com/Footagesus/WindUI", -- remove this if the key is not obtained from the link.
        SaveKey = true, -- optional
    },
})


--Window:SetBackgroundImage("rbxassetid://13511292247")


Window:EditOpenButton({
    Title = "Abrir Blessed Hub",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    --Enabled = false,
    Draggable = true,
})

local soundId = "rbxassetid://1836973601"

-- Função para tocar o som
local function playSound()
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Parent = game.Workspace -- Coloque no Workspace para garantir que seja ouvido
    sound:Play()
end

-- Tocar o som assim que o script for executado
playSound()

local Tabs = {
    -- Criando abas
local CreditTab = Window:Tab({
    Title = "Creditos",
    Icon = "info",
})

Window:SelectTab(1)

local MainTab = Window:Tab({
    Title = "Inicio",
    Icon = "house",
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local PersonagemTab = Window:Tab({
    Title = "Personagem",
    Icon = "footprints",
})

local SkinTab = Window:Tab({
    Title = "Skins Salvas",
    Icon = "shirt",
})

local StalkTab = Window:Tab({
    Title = "Stalk",
    Icon = "eye",
})

local TeleportTab = Window:Tab({
    Title = "Teleportes",
    Icon = "map-pin",
})

local TrollTab = Window:Tab({
    Title = "Troll",
    Icon = "skull",
})

local BypassTab = Window:Tab({
    Title = "Bypass",
    Icon = "cpu",
})

local MusicTab = Window:Tab({
	Title = "Musica",
	Icon = "music",
})

local ParceirosTab = Window:Tab({
	Title = "Parceiros de script",
	Icon = "users",
})

local TagTab = Window:Tab({
	Title = "Tags",
	Icon = "tag",
})

local ItemTab = Window:Tab({
	Title = "Item",
	Icon = "backpack",
})

local PremiumTab = Window:Tab({
    Title = "Premium",
    Icon = "rbxassetid://120011858138977",
})

divider1 = Window:Divider(),
    
local WindowTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

local ExtraTab = Window:Tab({
    Title = "Extras",
    Icon = "grid",
})

Tabs.MainTab:Paragraph({
    Title = "Local Geral",
    Desc = "Aba de opções gerais (mais usadas).",
    Image = "smile"
})

Tabs.PlayerTab:Paragraph({
    Title = "Local do Jogador",
    Desc = "Aba de opções para o seu personagem.",
    Image = "smile"
})

Tabs.PersonagemTab:Paragraph({
    Title = "Local do Personagem",
    Desc = "Aba de opções para skin do seu personagem.",
    Image = "smile"
})

Tabs.SkinTab:Paragraph({
    Title = "Local de Skin",
    Desc = "Aba de skins salvas.",
    Image = "smile"
})

Tabs.StalkTab:Paragraph({
    Title = "Local de Informações",
    Desc = "Aba de pegar informações do jogador.",
    Image = "smile"
})

Tabs.TeleportTab:Paragraph({
    Title = "Local de Teleportes",
    Desc = "Aba de teleportar para locais do mapa.",
    Image = "smile"
})

Tabs.TrollTab:Paragraph({
    Title = "Local de Troll",
    Desc = "Aba de trollar jogadores.",
    Image = "smile"
})

Tabs.BypassTab:Paragraph({
    Title = "Local de Bypass",
    Desc = "Aba de bular o jogo.",
    Image = "smile"
})

Tabs.PremiumTab:Paragraph({
    Title = "Local de Premium",
    Desc = "Aba de funções Premium.",
    Image = "smile"
})

Tabs.WindowTab:Paragraph({
    Title = "Local de Configurações",
    Desc = "Aba de configurações.",
    Image = "smile"
})

Tabs.ExtraTab:Paragraph({
    Title = "Local de Funções Extras",
    Desc = "Aba de funções extras no script.",
    Image = "smile"
})

Tabs.CreditTab:Section({
    Title = "Bem-vindo ao Blessed Hub, " .. game.Players.LocalPlayer.DisplayName .. "!",
    TextSize = 20,
})

-- Função para obter a data e o horário atual formatado
local function GetDateTime()
    local now = os.date("*t") -- Obtém a data e hora atual
    return string.format("%02d/%02d/%04d - %02d:%02d:%02d", now.day, now.month, now.year, now.hour, now.min, now.sec)
end

-- Cria a Section com a data e horário
local TimeSection = Tabs.CreditTab:Section({
    Title = "Data e Hora",
    TextSize = 18,
})

-- Atualiza a Section com o horário em tempo real
task.spawn(function()
    while true do
        TimeSection:SetTitle("Data e Hora: " .. GetDateTime()) -- Atualiza o texto da Section
        wait(1) -- Atualiza a cada segundo
    end
end)

local playerCountLabel = MainTab:Section({
    Title = "Jogadores No Servidor: " .. #game.Players:GetPlayers(),
    TextXAlignment = "Center"
})

-- Função para atualizar o número de jogadores quando alguém entra ou sai
local function updatePlayerCount()
    playerCountLabel:SetTitle("Jogadores No Servidor: " .. #game.Players:GetPlayers())
end

-- Conecta a função ao evento de entrada de novos jogadores
game.Players.PlayerAdded:Connect(updatePlayerCount)

-- Conecta a função ao evento de saída de jogadores
game.Players.PlayerRemoving:Connect(updatePlayerCount)

-- Atualiza a contagem de jogadores no início
updatePlayerCount()

for _,i in next, { "Default" } do
    CreditTab:Paragraph({
        Title = "Links",
        Desc = "Links de rede social do criador",
        Image = "bird",
        Color = i ~= "Default" and i or nil,
        Buttons = {
            {
                Title = "Link YouTube",
                Variant = "Primary",
                Callback = function() setclipboard("https://youtube.com/@ghzinn077?si=8YTQJcw95ww43ISC") end,
                Icon = "youtube",
            },
            {
                Title = "Link Servidor Discord",
                Variant = "Primary",
                Callback = function() setclipboard("https://dsc.gg/blessed-community") end,
                Icon = "gamepad-2",
            },
        }
    })
end

Tabs.CreditTab:Code({
    Title = "Creditos do script",
    Code = [[
Esse script foi feito com muito carinho
pela equipe Blessed Team ❤️

Muito obrigado por usar o Blessed Hub 😊

 Desenvolvedores: Gab Scripts e Robson
 Helpers: Kauan e Anna
    ]],
})

Tabs.PlayerTab:Slider({
    Title = "Adjust Field of View",
    Step = 1,
    Value = { Min = 20, Max = 120, Default = 70 },
    Callback = function(value)
        game.Workspace.Camera.FieldOfView = value
    end
})

Tabs.PlayerTab:Input({
    Title = "Speed Input",
    Desc = "Altera sua velocidade (16 velocidade normal)",
    PlaceholderText = "16",
    Callback = function(Text)
        local speed = tonumber(Text) -- Converte o valor para número
        if speed then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid then
                humanoid.WalkSpeed = speed -- Aplica a velocidade ao personagem
                WindUI:Notify({
                    Title = "Speed Aplicado",
                    Content = "Sua velocidade agora é: " .. speed,
                    Duration = 5,
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Humanoid not found!",
                    Duration = 5,
                })
            end
        else
            WindUI:Notify({
                Title = "Invalid Input",
                Content = "Please enter a valid number.",
                Duration = 5,
            })
        end
    end
})

Tabs.PlayerTab:Toggle({
    Title = "Sprint",
    Desc = "Ativa/desativa o sprint",
    Value = false, -- O valor padrão é 'false', ou seja, o sprint está desativado por padrão.
    Callback = function(state)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            if state then
                humanoid.WalkSpeed = 24 -- Velocidade ao ativar o sprint
                WindUI:Notify({
                    Title = "Sprint Ativado",
                    Content = "WalkSpeed ajustado para 24",
                    Duration = 5,
                })
            else
                humanoid.WalkSpeed = 16 -- Velocidade padrão ao desativar o sprint
                WindUI:Notify({
                    Title = "Sprint Desativado",
                    Content = "WalkSpeed ajustado para 16",
                    Duration = 5,
                })
            end
        else
            WindUI:Notify({
                Title = "Erro",
                Content = "Humanoid não encontrado!",
                Duration = 5,
            })
        end
    end,
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Função para garantir que o humanoide do jogador seja acessível
local function getHumanoid()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return character:WaitForChild("Humanoid")
end

-- Toggle para ativar/desativar Swim Mode
Tabs.PlayerTab:Toggle({
    Title = "Swim Mode",
    Desc = "Ativa ou desativa o modo de nado",
    Value = false, -- Modo de nado desativado por padrão
    Callback = function(state)
        local humanoid = getHumanoid()
        if humanoid then
            if state then
                -- Ativar modo de nado
                Workspace.Gravity = 0 -- Remove a gravidade
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) -- Ativa o estado de nado
                humanoid:ChangeState(Enum.HumanoidStateType.Swimming) -- Força o estado de nado

                WindUI:Notify({
                    Title = "Swim Mode Ativado",
                    Content = "Agora você está nadando!",
                    Duration = 5,
                })
            else
                -- Desativar modo de nado e restaurar estados padrão
                Workspace.Gravity = 196.2 -- Restaura a gravidade padrão

                -- Habilita todos os estados normais do humanoide
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

                -- Força o humanoide a retornar ao estado Running para normalizar
                humanoid:ChangeState(Enum.HumanoidStateType.Running)

                WindUI:Notify({
                    Title = "Swim Mode Desativado",
                    Content = "Modo de nado desativado.",
                    Duration = 5,
                })
            end
        else
            WindUI:Notify({
                Title = "Erro",
                Content = "Humanoid não encontrado!",
                Duration = 5,
            })
        end
    end,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local StealthMode = true -- Define se o modo furtivo está ativado (sem logs no jogo)
local noclip = false -- Define o estado inicial do Noclip
local Indicator

-- Função para criar um indicador na tela se o StealthMode estiver desativado
if not StealthMode then
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    Indicator = Instance.new("TextLabel", ScreenGui)
    Indicator.AnchorPoint = Vector2.new(0, 1)
    Indicator.Position = UDim2.new(0, 0, 1, 0)
    Indicator.Size = UDim2.new(0, 200, 0, 50)
    Indicator.BackgroundTransparency = 1
    Indicator.TextScaled = true
    Indicator.TextStrokeTransparency = 0
    Indicator.TextColor3 = Color3.new(0, 0, 0)
    Indicator.TextStrokeColor3 = Color3.new(1, 1, 1)
    Indicator.Text = "Noclip: Disabled"
end

-- Função para alternar o estado do Noclip
local function toggleNoclip(state)
    noclip = state

    if not StealthMode and Indicator then
        Indicator.Text = "Noclip: " .. (noclip and "Enabled" or "Disabled")
    end
end

-- Toggle para ativar/desativar o Noclip
PlayerTab:Toggle({
    Title = "Noclip",
    Desc = "Permite atravessar paredes",
    Value = false, -- Estado inicial do toggle
    Callback = function(state)
        toggleNoclip(state)
        WindUI:Notify({
            Title = "Noclip",
            Content = state and "Noclip ativado" or "Noclip desativado",
            Duration = 5,
        })
    end,
})

-- Loop para aplicar o estado do Noclip continuamente
RunService.Stepped:Connect(function()
    if noclip then
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false -- Desativa colisão
            end
        end
    else
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true -- Restaura colisão
            end
        end
    end
end)
-- Configuration
-- Optional


local HttpService = game:GetService("HttpService")

local folderPath = "WindUI"
makefolder(folderPath)

local function SaveFile(fileName, data)
    local filePath = folderPath .. "/" .. fileName .. ".json"
    local jsonData = HttpService:JSONEncode(data)
    writefile(filePath, jsonData)
end

local function LoadFile(fileName)
    local filePath = folderPath .. "/" .. fileName .. ".json"
    if isfile(filePath) then
        local jsonData = readfile(filePath)
        return HttpService:JSONDecode(jsonData)
    end
end

local function ListFiles()
    local files = {}
    for _, file in ipairs(listfiles(folderPath)) do
        local fileName = file:match("([^/]+)%.json$")
        if fileName then
            table.insert(files, fileName)
        end
    end
    return files
end

Tabs.WindowTab:Section({ Title = "Window" })

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tabs.WindowTab:Dropdown({
    Title = "Select Theme",
    Multi = false,
    AllowNone = false,
    Value = nil,
    Values = themeValues,
    Callback = function(theme)
        WindUI:SetTheme(theme)
    end
})
themeDropdown:Select(WindUI:GetCurrentTheme())

local ToggleTransparency = Tabs.WindowTab:Toggle({
    Title = "Toggle Window Transparency",
    Callback = function(e)
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

Tabs.WindowTab:Section({ Title = "Save" })

local fileNameInput = ""
Tabs.WindowTab:Input({
    Title = "Write File Name",
    PlaceholderText = "Enter file name",
    Callback = function(text)
        fileNameInput = text
    end
})

Tabs.WindowTab:Button({
    Title = "Save File",
    Callback = function()
        if fileNameInput ~= "" then
            SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
        end
    end
})

Tabs.WindowTab:Section({ Title = "Load" })

local filesDropdown
local files = ListFiles()

filesDropdown = Tabs.WindowTab:Dropdown({
    Title = "Select File",
    Multi = false,
    AllowNone = true,
    Values = files,
    Callback = function(selectedFile)
        fileNameInput = selectedFile
    end
})

Tabs.WindowTab:Button({
    Title = "Load File",
    Callback = function()
        if fileNameInput ~= "" then
            local data = LoadFile(fileNameInput)
            if data then
                WindUI:Notify({
                    Title = "File Loaded",
                    Content = "Loaded data: " .. HttpService:JSONEncode(data),
                    Duration = 5,
                })
                if data.Transparent then 
                    Window:ToggleTransparency(data.Transparent)
                    ToggleTransparency:SetValue(data.Transparent)
                end
                if data.Theme then WindUI:SetTheme(data.Theme) end
            end
        end
    end
})

Tabs.WindowTab:Button({
    Title = "Overwrite File",
    Callback = function()
        if fileNameInput ~= "" then
            SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
        end
    end
})

Tabs.WindowTab:Button({
    Title = "Refresh List",
    Callback = function()
        filesDropdown:Refresh(ListFiles())
    end
})

local currentThemeName = WindUI:GetCurrentTheme()
local themes = WindUI:GetThemes()

local ThemeAccent = themes[currentThemeName].Accent
local ThemeOutline = themes[currentThemeName].Outline
local ThemeText = themes[currentThemeName].Text
local ThemePlaceholderText = themes[currentThemeName].Placeholder

function updateTheme()
    WindUI:AddTheme({
        Name = currentThemeName,
        Accent = ThemeAccent,
        Outline = ThemeOutline,
        Text = ThemeText,
        Placeholder = ThemePlaceholderText
    })
    WindUI:SetTheme(currentThemeName)
end

local CreateInput = Tabs.CreateThemeTab:Input({
    Title = "Theme Name",
    Value = currentThemeName,
    Callback = function(name)
        currentThemeName = name
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Background Color",
    Default = Color3.fromHex(ThemeAccent),
    Callback = function(color)
        ThemeAccent = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Outline Color",
    Default = Color3.fromHex(ThemeOutline),
    Callback = function(color)
        ThemeOutline = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Text Color",
    Default = Color3.fromHex(ThemeText),
    Callback = function(color)
        ThemeText = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Placeholder Text Color",
    Default = Color3.fromHex(ThemePlaceholderText),
    Callback = function(color)
        ThemePlaceholderText = color:ToHex()
    end
})

Tabs.CreateThemeTab:Button({
    Title = "Update Theme",
    Callback = function()
        updateTheme()
    end
})

local InviteCode = "ApbHXtAwU2"
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

local Response = game:GetService("HttpService"):JSONDecode(WindUI.Creator.Request({
    Url = DiscordAPI,
    Method = "GET",
    Headers = {
        ["User-Agent"] = "RobloxBot/1.0",
        ["Accept"] = "application/json"
    }
}).Body)

if Response and Response.guild then
    local DiscordInfo = Tabs.Tests:Paragraph({
        Title = Response.guild.name,
        Desc = 
            ' <font color="#52525b">•</font> Member Count : ' .. tostring(Response.approximate_member_count) .. 
            '\n <font color="#16a34a">•</font> Online Count : ' .. tostring(Response.approximate_presence_count)
        ,
        Image = "https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024",
        ImageSize = 42,
    })

    Tabs.Tests:Button({
        Title = "Update Info",
        --Image = "refresh-ccw",
        Callback = function()
            local UpdatedResponse = game:GetService("HttpService"):JSONDecode(WindUI.Creator.Request({
                Url = DiscordAPI,
                Method = "GET",
            }).Body)

            if UpdatedResponse and UpdatedResponse and UpdatedResponse.guild then
                DiscordInfo:SetDesc(
                    ' <font color="#52525b">•</font> Member Count : ' .. tostring(UpdatedResponse.approximate_member_count) .. 
                    '\n <font color="#16a34a">•</font> Online Count : ' .. tostring(UpdatedResponse.approximate_presence_count)
                )
            end
        end
    })
else
    Tabs.Tests:Paragraph({
        Title = "Error when receiving information about the Discord server",
        Desc = game:GetService("HttpService"):JSONEncode(Response),
        Image = "triangle-alert",
        ImageSize = 26,
        Color = "Red",
    })
end



local function parseJSON(luau_table, indent, level, visited)
    indent = indent or 2
    level = level or 0
    visited = visited or {}

    local currentIndent = string.rep(" ", level * indent)
    local nextIndent = string.rep(" ", (level + 1) * indent)

    if luau_table == nil then
        return "null"
    end

    local dataType = type(luau_table)

    if dataType == "table" then
        if visited[luau_table] then
            return "\"[Circular Reference]\""
        end

        visited[luau_table] = true

        local isArray = true
        local maxIndex = 0

        for k, _ in pairs(luau_table) do
            if type(k) == "number" and k > maxIndex then
                maxIndex = k
            end
            if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                isArray = false
                break
            end
        end

        local count = 0
        for _ in pairs(luau_table) do
            count = count + 1
        end
        if count ~= maxIndex and isArray then
            isArray = false
        end

        if count == 0 then
            return "{}"
        end

        if isArray then
            if count == 0 then
                return "[]"
            end

            local result = "[\n"

            for i = 1, maxIndex do
                result = result .. nextIndent .. parseJSON(luau_table[i], indent, level + 1, visited)
                if i < maxIndex then
                    result = result .. ","
                end
                result = result .. "\n"
            end

            result = result .. currentIndent .. "]"
            return result
        else
            local result = "{\n"
            local first = true

            local keys = {}
            for k in pairs(luau_table) do
                table.insert(keys, k)
            end
            table.sort(keys, function(a, b)
                if type(a) == type(b) then
                    return tostring(a) < tostring(b)
                else
                    return type(a) < type(b)
                end
            end)

            for _, k in ipairs(keys) do
                local v = luau_table[k]
                if not first then
                    result = result .. ",\n"
                else
                    first = false
                end

                if type(k) == "string" then
                    result = result .. nextIndent .. "\"" .. k .. "\": "
                else
                    result = result .. nextIndent .. "\"" .. tostring(k) .. "\": "
                end

                result = result .. parseJSON(v, indent, level + 1, visited)
            end

            result = result .. "\n" .. currentIndent .. "}"
            return result
        end
    elseif dataType == "string" then
        local escaped = luau_table:gsub("\\", "\\\\")
        escaped = escaped:gsub("\"", "\\\"")
        escaped = escaped:gsub("\n", "\\n")
        escaped = escaped:gsub("\r", "\\r")
        escaped = escaped:gsub("\t", "\\t")

        return "\"" .. escaped .. "\""
    elseif dataType == "number" then
        return tostring(luau_table)
    elseif dataType == "boolean" then
        return luau_table and "true" or "false"
    elseif dataType == "function" then
        return "\"function\""
    else
        return "\"" .. dataType .. "\""
    end
end

local function tableToClipboard(luau_table, indent)
    indent = indent or 4
    local jsonString = parseJSON(luau_table, indent)
    setclipboard(jsonString)
    return jsonString
end

Tabs.Tests:Section({
    Title = "Get WindUI JSON"
})

Tabs.Tests:Button({
    Title = "Get WindUI JSON",
    Callback = function()
        tableToClipboard(WindUI)
    end
})
-- ███████████████████████████████████████████████████████████████████████████
--  ✦  CGS · DIAMOND EDITION  ·  v25.1  ✦  (MEJORADO)
--  ──────────────────────────────────────────────────────────────────────────
--  "Código que brilla en la oscuridad del servidor, sin perder ni un átomo."
--  Desarrollado por:  Company Gamer Studios
--  Filosofía:  Transparencia, velocidad, y un toque de locura cuántica.
-- ███████████████████████████████████████████████████████████████████████████

--[[ ==================================================
-- MEGA SCRIPT MM2 V23.0 - CGS ELITE EDITION
-- STATUS: FULLY RECOVERED + CGS DYNAMIC ADMIN UPDATE
-- DEVELOPED BY: COMPANY GAMER STUDIOS
-- ================================================== ]]

local Cosmos = {
    --  GEMAS DE ACTIVACIÓN  (todas brillan en falso por defecto)
    SilentAim = false,
    UseCameraAimbot = false,
    TriggerBot = false,
    Wallbang = false,
    KnifeAura = false,
    AutoShoot = false,
    FakeLag = false,
    ServerLag = false,

    --  Nuevas funciones de Fling  (destellos de energía)
    SpeedGlitch = false,
    FlingSheriff = false,
    FlingMurder = false,

    --  TECLADO SAGRADO  (configuración de teclas)
    CameraAimbotKey = Enum.KeyCode.X,
    SilentAimKey = Enum.KeyCode.B,
    TriggerKey = Enum.KeyCode.P,
    WallbangKey = Enum.KeyCode.H,
    AuraKey = Enum.KeyCode.M,
    AutoShootKey = Enum.KeyCode.V,
    GrabKey = Enum.KeyCode.Z,
    FakeLagKey = Enum.KeyCode.K,
    ServerLagKey = Enum.KeyCode.R,
    SpeedGlitchKey = Enum.KeyCode.Q,
    FlingSheriffKey = Enum.KeyCode.N,
    FlingMurderKey = Enum.KeyCode.G,

    --  TELEPORT KEYS CORREGIDAS
    MapKey = Enum.KeyCode.U,      --  U para ir al MAPA
    LobbyKey = Enum.KeyCode.L,    --  L para ir al LOBBY
    AdminKey = Enum.KeyCode.J,

    --  Variables de Ajuste  (tallado de diamante)  ✦ MEJORA CGS: valores documentados
    GrabHeight = 3,
    AuraRange = 25,
    AuraDelay = 0.035,
    ChestOffset = 1.65,
    ShootRange = 100,
    -- Nuevos parámetros para optimización y control
    ESPUpdateInterval = 0.2,      -- segundos entre actualizaciones del ESP
    MaxFlingDuration = 0.5,       -- duración máxima del fling
    FakeLagChance = 3,            -- 1 de cada 3 iteraciones
    SpeedMultiplier = 1.48,
    AutoShootCooldown = 0.07,
    TeleportOffset = 3,           -- distancia detrás del objetivo
}

-- [ SERVICIOS DEL UNIVERSO ]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game.Workspace
local CoreGui = game:GetService("CoreGui")

-- [ VARIABLES DE LA MATRIX ]
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Rubies = {}
local SheriffID = nil
local RoundStarted = false
local SilentAimLoaded = false
local LastShot = 0

-- Variables para conexiones de bucles
local FakeLagConnection = nil
local ServerLagConnection = nil
local SpeedGlitchConnection = nil

-- ✦ MEJORA CGS: variables para optimización ESP
local ESPLastUpdate = 0
local ESPCache = {}  -- guarda el último estado de cada jugador para evitar actualizaciones innecesarias

-- ==================================================
-- [ NOTIFICACIONES  (mensajes de luz) ]
-- ==================================================
local function ShowNotification(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 2.5,
    })
end

-- ==================================================
-- [ LIMPIADOR DE RONDA  (reset cósmico) ]
-- ==================================================
local function FullReset()
    SheriffID = nil
    RoundStarted = false

    for player, ruby in pairs(Rubies) do
        if ruby then
            if ruby.Parent then
                ruby:Destroy()
            end
        end
    end

    Rubies = {}
    ESPCache = {}  -- ✦ MEJORA CGS: limpiar caché
    print("[CGS] FULL RESET COMPLETO - Nueva ronda detectada")
end

-- Detectar cambio de mapa
Workspace.ChildRemoved:Connect(function(child)
    if child.Name == "Normal" or child.Name == "Map" or string.find(child.Name:lower(), "map") then
        task.wait(1.5)
        FullReset()
    end
end)

-- Detectar respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    FullReset()
end)

-- ==================================================
-- [ SISTEMA ESP RUBY  (marcadores de alma) ]  ✦ MEJORA CGS: lógica de roles actualizada
-- ==================================================
local function GetRoleColor(player)
    if not player.Character then
        return Color3.new(0, 1, 0), 0.45  -- inocente por defecto
    end

    local char = player.Character
    local backpack = player:FindFirstChild("Backpack") or player.Backpack

    -- Detectar arma (cuchillo o pistola) en el personaje o mochila
    local hasKnife = backpack:FindFirstChild("Knife")
                   or backpack:FindFirstChild("KnifeClone")
                   or char:FindFirstChild("Knife")
                   or char:FindFirstChild("KnifeClone")

    local hasGun = backpack:FindFirstChild("Gun")
                or backpack:FindFirstChild("Revolver")
                or char:FindFirstChild("Gun")
                or char:FindFirstChild("Revolver")

    -- Lógica de roles según la descripción actualizada
    if hasKnife then
        -- ASESINO (murderer)
        return Color3.new(1, 0, 0), 0.25
    elseif hasGun then
        -- SHERIFF (el que tiene pistola)
        if not RoundStarted then
            RoundStarted = true
            SheriffID = player.UserId
        end
        -- Si es el sheriff, azul; si es un inocente que recogió un arma, amarillo (pero eso se maneja más abajo)
        if player.UserId == SheriffID then
            return Color3.fromRGB(0, 150, 255), 0.2  -- sheriff
        else
            -- Inocente con arma (recogió la pistola del sheriff caído)
            return Color3.fromRGB(255, 255, 0), 0.25
        end
    else
        -- INOCENTE (sin armas)
        return Color3.new(0, 1, 0), 0.4
    end
end

-- ✦ MEJORA CGS: función para determinar el rol de un jugador (devuelve "murderer", "sheriff", "innocent", "innocent_with_gun")
local function GetPlayerRole(player)
    if not player.Character then return "innocent" end
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack") or player.Backpack

    local hasKnife = backpack:FindFirstChild("Knife") or backpack:FindFirstChild("KnifeClone") or char:FindFirstChild("Knife") or char:FindFirstChild("KnifeClone")
    local hasGun = backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver") or char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")

    if hasKnife then
        return "murderer"
    elseif hasGun then
        -- Si el jugador tiene pistola, verificar si es el sheriff oficial
        if player.UserId == SheriffID then
            return "sheriff"
        else
            -- Si no hay SheriffID definido, asignar al primer jugador con pistola como sheriff
            if not SheriffID then
                SheriffID = player.UserId
                RoundStarted = true
                return "sheriff"
            else
                return "innocent_with_gun"  -- Inocente que recogió un arma
            end
        end
    else
        return "innocent"
    end
end

-- ✦ MEJORA CGS: función para obtener al asesino (más eficiente)
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if GetPlayerRole(p) == "murderer" then
                return p.Character
            end
        end
    end
    return nil
end

local function CreateOrUpdateRuby(player)
    if player == LocalPlayer then
        return
    end

    if not player.Character then
        return
    end

    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local ruby = Rubies[player] or Instance.new("BoxHandleAdornment")
    ruby.Name = "CGS_Ruby"
    ruby.Size = Vector3.new(0.92, 0.92, 0.92)
    ruby.AlwaysOnTop = true
    ruby.ZIndex = 5
    ruby.Adornee = root
    ruby.Parent = root

    Rubies[player] = ruby

    local color, trans = GetRoleColor(player)
    ruby.Color3 = color
    ruby.Transparency = trans
end

-- ==================================================
-- [ GUN HIGHLIGHT  (resplandor de pistolas caídas) ]
-- ==================================================
local function SetupGunHighlight()
    Workspace.DescendantAdded:Connect(function(v)
        if v.Name == "GunDrop" and v:IsA("BasePart") then
            local hl = Instance.new("Highlight", v)
            hl.Name = "CGS_GunHighlight"
            hl.FillColor = Color3.fromRGB(255, 215, 0)
            hl.OutlineColor = Color3.new(1,1,1)
            hl.FillTransparency = 0.3
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = v
            ShowNotification("🔫 PISTOLA CAÍDA", "Presiona Z para agarrarla")
        end
    end)
end

-- ==================================================
-- [ FAKE LAG (K)  -  distorsión temporal ]
-- ==================================================
local function ToggleFakeLag()
    Cosmos.FakeLag = not Cosmos.FakeLag

    if Cosmos.FakeLag then
        ShowNotification("⏳ Fake Lag", "✅ Activado")
        FakeLagConnection = RunService.Heartbeat:Connect(function()
            if not Cosmos.FakeLag then return end
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

            local root = LocalPlayer.Character.HumanoidRootPart
            if math.random(1, Cosmos.FakeLagChance) == 1 then  -- ✦ MEJORA CGS: uso de constante
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end)
    else
        if FakeLagConnection then
            FakeLagConnection:Disconnect()
            FakeLagConnection = nil
        end
        ShowNotification("⏳ Fake Lag", "❌ Desactivado")
    end
end

-- ==================================================
-- [ SERVER LAG (R)  -  caos en la red ]
-- ==================================================
local function ToggleServerLag()
    Cosmos.ServerLag = not Cosmos.ServerLag

    if Cosmos.ServerLag then
        ShowNotification("🌐 Server Lag", "✅ Activado (MÁXIMO AGRESIVO)")
        ServerLagConnection = RunService.Heartbeat:Connect(function()
            if not Cosmos.ServerLag then return end
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

            pcall(function()
                local root = LocalPlayer.Character.HumanoidRootPart
                root:SetNetworkOwner(nil)
                for i = 1, 20 do
                    root.AssemblyLinearVelocity = Vector3.new(
                        math.random(-120, 120),
                        root.AssemblyLinearVelocity.Y,
                        math.random(-120, 120)
                    )
                end
            end)
        end)
    else
        if ServerLagConnection then
            ServerLagConnection:Disconnect()
            ServerLagConnection = nil
        end
        ShowNotification("🌐 Server Lag", "❌ Desactivado")
    end
end

-- ==================================================
-- [ SPEED GLITCH (Q)  -  velocidad cuántica ]
-- ==================================================
local function ToggleSpeedGlitch()
    Cosmos.SpeedGlitch = not Cosmos.SpeedGlitch

    if Cosmos.SpeedGlitch then
        ShowNotification("⚡ Speed Glitch", "✅ Activado (Q)")
        SpeedGlitchConnection = RunService.Heartbeat:Connect(function()
            if not Cosmos.SpeedGlitch then return end

            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local vel = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(vel.X * Cosmos.SpeedMultiplier, vel.Y, vel.Z * Cosmos.SpeedMultiplier)  -- ✦ MEJORA CGS
            end
        end)
    else
        if SpeedGlitchConnection then
            SpeedGlitchConnection:Disconnect()
            SpeedGlitchConnection = nil
        end
        ShowNotification("⚡ Speed Glitch", "❌ Desactivado")
    end
end

-- ==================================================
-- [ FLING NINJA FLASH (N) - SHERIFF  (golpe de energía) ]  ✦ MEJORA CGS: unificado con función auxiliar
-- ==================================================
local function ExecuteTargetFling(targetPlayer, roleFilter)
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local targetChar = targetPlayer.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if not myRoot or not targetRoot then
        ShowNotification("⚠️ Error", "El objetivo no está disponible.")
        return
    end

    -- Verificar que el objetivo tenga el rol deseado (si se especifica)
    if roleFilter then
        local role = GetPlayerRole(targetPlayer)
        if role ~= roleFilter then
            ShowNotification("⚠️ Error", "El jugador no es " .. roleFilter)
            return
        end
    end

    ShowNotification("⚡ CGS ELITE FLING", "🎯 Atacando a: " .. targetPlayer.Name)
    local OldCF = myRoot.CFrame

    myRoot.AssemblyAngularVelocity = Vector3.new(0, 999999, 0)

    local startTime = tick()
    while tick() - startTime < Cosmos.MaxFlingDuration do
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
        myRoot.AssemblyLinearVelocity = Vector3.new(30000, 30000, 30000)
        task.wait()
        if not targetRoot or not targetRoot.Parent then break end
    end

    myRoot.CFrame = OldCF
    myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

local function ToggleFlingSheriff()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if GetPlayerRole(p) == "sheriff" then
                ExecuteTargetFling(p, "sheriff")
                return
            end
        end
    end
    ShowNotification("⚠️ Error", "No se encontró sheriff.")
end

local function ToggleFlingMurder()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if GetPlayerRole(p) == "murderer" then
                ExecuteTargetFling(p, "murderer")
                return
            end
        end
    end
    ShowNotification("⚠️ Error", "No se encontró asesino.")
end

-- ==================================================
-- [ ENTRADA DE TECLADO (INPUTS) - CORREGIDA ]
-- ==================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Agarrar Pistola (Z)
    if input.KeyCode == Cosmos.GrabKey then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v.Name == "GunDrop" and v:IsA("BasePart") then
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local old = root.CFrame
                    root.CFrame = v.CFrame * CFrame.new(0, Cosmos.GrabHeight, 0)
                    task.wait(0.15)
                    root.CFrame = old
                end
                break
            end
        end
    end

    -- Camera Aimbot (X)
    if input.KeyCode == Cosmos.CameraAimbotKey then
        Cosmos.UseCameraAimbot = not Cosmos.UseCameraAimbot
        ShowNotification("🎯 Camera Aimbot", Cosmos.UseCameraAimbot and "✅ Activado" or "❌ Desactivado")
    end

    -- Silent Aim (B)
    if input.KeyCode == Cosmos.SilentAimKey then
        Cosmos.SilentAim = not Cosmos.SilentAim
        ShowNotification("🔇 Silent Aim", Cosmos.SilentAim and "✅ Activado" or "❌ Desactivado")
    end

    -- Trigger Bot (P)
    if input.KeyCode == Cosmos.TriggerKey then
        Cosmos.TriggerBot = not Cosmos.TriggerBot
        ShowNotification("⚡ Trigger Bot", Cosmos.TriggerBot and "✅ Activado" or "❌ Desactivado")
    end

    -- Wallbang (H)
    if input.KeyCode == Cosmos.WallbangKey then
        Cosmos.Wallbang = not Cosmos.Wallbang
        ShowNotification("🏹 Wallbang", Cosmos.Wallbang and "✅ Activado" or "❌ Desactivado")
    end

    -- Kill Aura (M)
    if input.KeyCode == Cosmos.AuraKey then
        Cosmos.KnifeAura = not Cosmos.KnifeAura
        ShowNotification("🔪 Kill All Aura", Cosmos.KnifeAura and "✅ Activado" or "❌ Desactivado")
    end

    -- Auto Shoot (V)
    if input.KeyCode == Cosmos.AutoShootKey then
        Cosmos.AutoShoot = not Cosmos.AutoShoot
        ShowNotification("🔫 Auto Shoot", Cosmos.AutoShoot and "✅ Activado" or "❌ Desactivado")
    end

    -- ==================================================
    -- [ TELETRANSPORTE A JUGADOR VIVO EN EL MAPA (U) ]  ✦ MEJORA CGS: más robusto y con offset
    -- ==================================================
    if input.KeyCode == Cosmos.MapKey then
        local player = game.Players.LocalPlayer
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then
            ShowNotification("⚠️ ERROR", "No tienes personaje")
            return
        end

        local alivePlayers = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                local char = p.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    -- Incluir a todos los que tengan personaje (vivos)
                    table.insert(alivePlayers, {player = p, root = root})
                end
            end
        end

        if #alivePlayers == 0 then
            ShowNotification("❌ ERROR", "No hay jugadores vivos en el mapa")
            return
        end

        local target = alivePlayers[math.random(1, #alivePlayers)]
        myRoot.CFrame = target.root.CFrame * CFrame.new(0, 2, Cosmos.TeleportOffset)
        ShowNotification("🌀 TELEPORT", "Teletransportado a " .. target.player.Name)
    end

    -- ==================================================
    -- [ TELETRANSPORTE AL LOBBY (L) - VERSIÓN ROBUSTA ]
    -- ==================================================
    if input.KeyCode == Cosmos.LobbyKey then
        local player = game.Players.LocalPlayer
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            ShowNotification("⚠️ ERROR", "No tienes personaje")
            return
        end

        local targetPos = nil
        local keywords = {"lobby", "spawn", "waiting", "start", "hub", "lobbypart"}

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local nameLower = obj.Name:lower()
                for _, kw in ipairs(keywords) do
                    if nameLower:find(kw) then
                        targetPos = obj.CFrame
                        break
                    end
                end
                if targetPos then break end
            end
        end

        if not targetPos then
            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") then
                    local modelName = model.Name:lower()
                    for _, kw in ipairs(keywords) do
                        if modelName:find(kw) then
                            if model.PrimaryPart then
                                targetPos = model.PrimaryPart.CFrame
                            else
                                for _, part in ipairs(model:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        targetPos = part.CFrame
                                        break
                                    end
                                end
                            end
                            break
                        end
                    end
                    if targetPos then break end
                end
            end
        end

        if not targetPos then
            targetPos = CFrame.new(0, 100, 0)
            ShowNotification("⚠️ FALLBACK", "Usando coordenadas fijas del lobby")
        end

        if targetPos then
            root.CFrame = targetPos + Vector3.new(0, 5, 0)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            ShowNotification("🏢 LOBBY", "Teletransportado al lobby")
        else
            ShowNotification("❌ ERROR", "No se pudo encontrar el lobby")
        end
    end

    -- [ ABRIR/CERRAR PANEL ADMIN (J) ]
    if input.KeyCode == Cosmos.AdminKey then
        local adminPanel = CoreGui:FindFirstChild("CGS_AdminPanel")
        if adminPanel then
            adminPanel.Enabled = not adminPanel.Enabled
            ShowNotification("🛡️ CGS ADMIN", adminPanel.Enabled and "Panel Abierto" or "Panel Cerrado")
        end
    end

    -- Otros toggles
    if input.KeyCode == Cosmos.FakeLagKey then ToggleFakeLag() end
    if input.KeyCode == Cosmos.ServerLagKey then ToggleServerLag() end
    if input.KeyCode == Cosmos.SpeedGlitchKey then ToggleSpeedGlitch() end
    if input.KeyCode == Cosmos.FlingSheriffKey then ToggleFlingSheriff() end
    if input.KeyCode == Cosmos.FlingMurderKey then ToggleFlingMurder() end
end)

-- ==================================================
-- [ BUCLE CAMERA AIMBOT ]  ✦ MEJORA CGS: usa GetMurderer()
-- ==================================================
RunService.RenderStepped:Connect(function()
    if not Cosmos.UseCameraAimbot then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local murderer = GetMurderer()
    if murderer then
        local targetPart = murderer:FindFirstChild("UpperTorso")
                         or murderer:FindFirstChild("Torso")
                         or murderer:FindFirstChild("HumanoidRootPart")

        if targetPart then
            local targetPos = targetPart.Position + Vector3.new(0, 1.15, 0)
            local root = murderer:FindFirstChild("HumanoidRootPart")
            if root then
                local vel = root.Velocity
                targetPos = targetPos + Vector3.new(vel.X * 0.12, 0, vel.Z * 0.12)
            end

            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, 0.07)
        end
    end
end)

-- ==================================================
-- [ METATABLE: SILENT AIM + WALLBANG ]
-- ==================================================
pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()

        if (Cosmos.SilentAim or Cosmos.Wallbang) and method == "FireServer" then
            local name = tostring(self.Name):lower()
            if name:find("shoot") or name:find("gun") then
                local murderer = GetMurderer()
                if murderer then
                    local root = murderer:FindFirstChild("HumanoidRootPart")
                    if root then
                        args[1] = root.Position + Vector3.new(0, Cosmos.ChestOffset, 0)
                    end
                end
            end
        end
        return old(self, unpack(args))
    end)

    setreadonly(mt, true)
    SilentAimLoaded = true
end)

-- ==================================================
-- [ BUCLE TRIGGER BOT ]  ✦ MEJORA CGS: verifica balas y cooldown
-- ==================================================
RunService.RenderStepped:Connect(function()
    if not Cosmos.TriggerBot then return end
    if not LocalPlayer.Character then return end

    local gun = LocalPlayer.Backpack:FindFirstChild("Gun")
             or LocalPlayer.Character:FindFirstChild("Gun")

    if not gun then return end

    -- ✦ MEJORA CGS: verificar que el arma tiene balas (si existe la propiedad)
    if gun:FindFirstChild("Ammo") and gun.Ammo.Value <= 0 then return end

    local murderer = GetMurderer()
    if murderer then
        gun:Activate()
    end
end)

-- ==================================================
-- [ BUCLE KILL AURA ]  ✦ MEJORA CGS: evita activar el cuchillo si ya está activo
-- ==================================================
local auraCooldown = 0
RunService.Heartbeat:Connect(function()
    if not Cosmos.KnifeAura then return end

    local char = LocalPlayer.Character
    if not char then return end

    local knife = char:FindFirstChild("Knife")
               or LocalPlayer.Backpack:FindFirstChild("Knife")
    if not knife then return end

    -- ✦ MEJORA CGS: no activar si ya está en cooldown o si el cuchillo ya está en uso
    if tick() - auraCooldown < Cosmos.AuraDelay then return end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist <= Cosmos.AuraRange then
                knife:Activate()
                auraCooldown = tick()
                break  -- ✦ MEJORA CGS: solo activar una vez por tick
            end
        end
    end
end)

-- ==================================================
-- [ BUCLE AUTO SHOOT ]  ✦ MEJORA CGS: usa GetMurderer() y cooldown mejorado
-- ==================================================
RunService.Heartbeat:Connect(function()
    if not Cosmos.AutoShoot then return end
    if tick() - LastShot < Cosmos.AutoShootCooldown then return end

    local character = LocalPlayer.Character
    if not character then return end

    local gun = character:FindFirstChild("Gun")
             or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun then return end

    -- Verificar balas
    if gun:FindFirstChild("Ammo") and gun.Ammo.Value <= 0 then return end

    local murderer = GetMurderer()
    if murderer then
        local upper = murderer:FindFirstChild("UpperTorso") or murderer:FindFirstChild("Torso")
        local root = murderer:FindFirstChild("HumanoidRootPart")
        local targetPos = nil
        if upper then
            targetPos = upper.Position + Vector3.new(0, Cosmos.ChestOffset, 0)
        elseif root then
            targetPos = root.Position + Vector3.new(0, Cosmos.ChestOffset, 0)
        end

        if targetPos then
            local dist = (character.HumanoidRootPart.Position - targetPos).Magnitude
            if dist < Cosmos.ShootRange then
                gun:Activate()
                LastShot = tick()
            end
        end
    end
end)

-- ==================================================
-- [ BUCLE ESP ]  ✦ MEJORA CGS: ahora asegura que todos los jugadores tengan rubí
-- ==================================================
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - ESPLastUpdate < Cosmos.ESPUpdateInterval then return end
    ESPLastUpdate = now

    for _, player in pairs(Players:GetPlayers()) do
        pcall(function()
            if player == LocalPlayer then return end

            -- Si no tiene personaje, eliminar su rubí si existe
            if not player.Character then
                if Rubies[player] then
                    Rubies[player]:Destroy()
                    Rubies[player] = nil
                    ESPCache[player] = nil
                end
                return
            end

            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if not root then
                if Rubies[player] then
                    Rubies[player]:Destroy()
                    Rubies[player] = nil
                    ESPCache[player] = nil
                end
                return
            end

            -- Verificar si el rubí existe y está correctamente asignado
            local ruby = Rubies[player]
            if not ruby or ruby.Adornee ~= root or not ruby.Parent then
                -- Crear o recrear el rubí
                CreateOrUpdateRuby(player)
                -- Actualizar caché después de crear
                local role = GetPlayerRole(player)
                local color, trans = GetRoleColor(player)
                ESPCache[player] = player.UserId .. "_" .. role .. "_" .. tostring(color) .. "_" .. tostring(trans)
            else
                -- Si existe, verificar si el rol cambió para actualizar color
                local role = GetPlayerRole(player)
                local color, trans = GetRoleColor(player)
                local cacheKey = player.UserId .. "_" .. role .. "_" .. tostring(color) .. "_" .. tostring(trans)
                if ESPCache[player] ~= cacheKey then
                    -- Actualizar color y transparencia sin recrear
                    ruby.Color3 = color
                    ruby.Transparency = trans
                    ESPCache[player] = cacheKey
                end
            end
        end)
    end
end)

-- ==================================================
-- [ LOGICA DE TARGETED FLING INDIVIDUAL ]  (ya mejorada arriba)
-- ==================================================
-- La función ExecuteTargetFling ya está definida arriba y es usada por los toggles y el panel.

-- ==================================================
-- [ NUEVO: LOGICA DE HUNT (CAZAR) INDIVIDUAL ]
-- ==================================================
local function ExecuteTargetHunt(targetPlayer)
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local targetChar = targetPlayer.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if myRoot and targetRoot then
        ShowNotification("🔪 CGS HUNT", "Apareciendo detrás de " .. targetPlayer.Name)
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, Cosmos.TeleportOffset)
    else
        ShowNotification("⚠️ Error", "El objetivo no está disponible.")
    end
end

-- ==================================================
-- [ CGS ADMIN PANEL GEN V23.0 (DOBLE COLUMNA PRO) ]  ✦ MEJORA CGS: muestra roles en la lista
-- ==================================================
local SelectedPlayer = nil

local function CreateCGSAdmin()
    if CoreGui:FindFirstChild("CGS_AdminPanel") then
        CoreGui.CGS_AdminPanel:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CGS_AdminPanel"
    ScreenGui.Parent = CoreGui
    ScreenGui.Enabled = false
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainFrame.Size = UDim2.new(0, 500, 0, 350)
    MainFrame.Active = true
    MainFrame.Draggable = true

    -- Título
    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.BackgroundColor3 = Color3.fromRGB(25, 0, 0)
    Title.Text = "COMPANY GAMER STUDIOS - ADMIN V23.0"
    Title.TextColor3 = Color3.fromRGB(255, 50, 50)
    Title.Font = Enum.Font.Code
    Title.TextSize = 16

    -- Marco Izquierdo (Lista)
    local PlayerListFrame = Instance.new("ScrollingFrame")
    PlayerListFrame.Name = "PlayerListFrame"
    PlayerListFrame.Parent = MainFrame
    PlayerListFrame.Position = UDim2.new(0, 10, 0, 45)
    PlayerListFrame.Size = UDim2.new(0.5, -15, 1, -55)
    PlayerListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    PlayerListFrame.BorderColor3 = Color3.fromRGB(150, 0, 0)
    PlayerListFrame.ScrollBarThickness = 5

    local UIList = Instance.new("UIListLayout")
    UIList.Parent = PlayerListFrame
    UIList.Padding = UDim.new(0, 4)
    UIList.SortOrder = Enum.SortOrder.Name

    -- Marco Derecho (Acciones)
    local ActionFrame = Instance.new("Frame")
    ActionFrame.Parent = MainFrame
    ActionFrame.Position = UDim2.new(0.5, 5, 0, 45)
    ActionFrame.Size = UDim2.new(0.5, -15, 1, -55)
    ActionFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ActionFrame.BorderColor3 = Color3.fromRGB(100, 0, 0)

    local ActionTitle = Instance.new("TextLabel")
    ActionTitle.Name = "ActionTitle"
    ActionTitle.Parent = ActionFrame
    ActionTitle.Size = UDim2.new(1, 0, 0, 30)
    ActionTitle.Text = "SELECCIONA OBJETIVO"
    ActionTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    ActionTitle.BackgroundTransparency = 1
    ActionTitle.Font = Enum.Font.Code
    ActionTitle.TextSize = 14

    -- Botones de Acción (Ocultos hasta seleccionar jugador)
    local BtnFling = Instance.new("TextButton")
    BtnFling.Name = "BtnFling"
    BtnFling.Parent = ActionFrame
    BtnFling.Size = UDim2.new(1, -20, 0, 40)
    BtnFling.Position = UDim2.new(0, 10, 0, 50)
    BtnFling.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    BtnFling.Text = "⚡ EJECUTAR FLING"
    BtnFling.TextColor3 = Color3.new(1,1,1)
    BtnFling.Font = Enum.Font.Code
    BtnFling.TextSize = 14
    BtnFling.Visible = false

    local BtnHunt = Instance.new("TextButton")
    BtnHunt.Name = "BtnHunt"
    BtnHunt.Parent = ActionFrame
    BtnHunt.Size = UDim2.new(1, -20, 0, 40)
    BtnHunt.Position = UDim2.new(0, 10, 0, 100)
    BtnHunt.BackgroundColor3 = Color3.fromRGB(0, 60, 0)
    BtnHunt.Text = "🔪 CAZAR (TELEPORT)"
    BtnHunt.TextColor3 = Color3.new(1,1,1)
    BtnHunt.Font = Enum.Font.Code
    BtnHunt.TextSize = 14
    BtnHunt.Visible = false

    -- Lógica de Actualización  ✦ MEJORA CGS: mostrar rol junto al nombre
    local function UpdatePlayerList()
        for _, v in pairs(PlayerListFrame:GetChildren()) do
            if v:IsA("TextButton") then v:Destroy() end
        end

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local b = Instance.new("TextButton")
                b.Parent = PlayerListFrame
                b.Size = UDim2.new(1, -10, 0, 30)
                b.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
                local role = GetPlayerRole(p)
                local roleSymbol = ""
                if role == "murderer" then
                    roleSymbol = "🔪 "
                elseif role == "sheriff" then
                    roleSymbol = "🔫 "
                elseif role == "innocent_with_gun" then
                    roleSymbol = "🔫⚠️ "
                else
                    roleSymbol = "🟢 "
                end
                b.Text = roleSymbol .. p.DisplayName
                b.TextColor3 = Color3.new(1,1,1)
                b.Font = Enum.Font.Code
                b.TextSize = 13

                b.MouseButton1Click:Connect(function()
                    SelectedPlayer = p
                    ActionTitle.Text = "@" .. p.Name:upper()
                    ActionTitle.TextColor3 = Color3.fromRGB(255, 255, 0)
                    BtnFling.Visible = true
                    BtnHunt.Visible = true
                    ShowNotification("SISTEMA CGS", "¿Qué castigo quieres para " .. p.Name .. "?")
                end)
            end
        end
        PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
    end

    -- Conexión de Botones de Acción
    BtnFling.MouseButton1Click:Connect(function()
        if SelectedPlayer then ExecuteTargetFling(SelectedPlayer) end
    end)

    BtnHunt.MouseButton1Click:Connect(function()
        if SelectedPlayer then ExecuteTargetHunt(SelectedPlayer) end
    end)

    UpdatePlayerList()
    Players.PlayerAdded:Connect(UpdatePlayerList)
    Players.PlayerRemoving:Connect(UpdatePlayerList)

    -- ✦ MEJORA CGS: devolver la función para actualización periódica
    return UpdatePlayerList
end

-- ==================================================
-- [ INICIO DEL SCRIPT ]
-- ==================================================
SetupGunHighlight()
local updatePanel = CreateCGSAdmin()

task.wait(2)

for _, p in pairs(Players:GetPlayers()) do
    pcall(function()
        CreateOrUpdateRuby(p)
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1.5)
        pcall(function()
            CreateOrUpdateRuby(p)
        end)
    end)
end)

-- ==================================================
-- [ SISTEMA DE TELETRANSPORTE POR NOMBRE (F2) ]
-- ==================================================
local function TeleportByName(playerName)
    local target = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower() == playerName:lower() or p.DisplayName:lower() == playerName:lower() then
            target = p
            break
        end
    end

    if not target then
        ShowNotification("❌ ERROR", "Usuario no encontrado: " .. playerName)
        return false
    end

    local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        ShowNotification("⚠️ ERROR", "El jugador no tiene personaje activo")
        return false
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        ShowNotification("⚠️ ERROR", "No tienes personaje")
        return false
    end

    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, Cosmos.TeleportOffset)
    ShowNotification("✅ TELETRANSPORTE EXITOSO", "Ahora estás con " .. target.Name)
    return true
end

local function OpenTeleportInput()
    if CoreGui:FindFirstChild("TeleportInputGUI") then
        CoreGui.TeleportInputGUI:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TeleportInputGUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local fullscreen = Instance.new("Frame")
    fullscreen.Size = UDim2.new(1, 0, 1, 0)
    fullscreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fullscreen.BackgroundTransparency = 0.05
    fullscreen.BorderSizePixel = 0
    fullscreen.Parent = gui

    local scanlines = Instance.new("Frame")
    scanlines.Size = UDim2.new(1, 0, 1, 0)
    scanlines.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    scanlines.BackgroundTransparency = 0.95
    scanlines.BorderSizePixel = 0
    scanlines.Parent = fullscreen
    for i = 1, 30 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, 0, 0, 2)
        line.Position = UDim2.new(0, 0, 0, i * 25)
        line.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        line.BackgroundTransparency = 0.85
        line.BorderSizePixel = 0
        line.Parent = scanlines
    end

    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(0, 500, 0, 250)
    dialog.Position = UDim2.new(0.5, -250, 0.5, -125)
    dialog.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dialog.BackgroundTransparency = 0.2
    dialog.BorderSizePixel = 3
    dialog.BorderColor3 = Color3.fromRGB(0, 255, 0)
    dialog.ClipsDescendants = true
    dialog.Parent = fullscreen

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundColor3 = Color3.fromRGB(0, 20, 0)
    title.BackgroundTransparency = 0.3
    title.Text = "> CGS_TELEPORT v2.0 <"
    title.TextColor3 = Color3.fromRGB(0, 255, 0)
    title.Font = Enum.Font.Code
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.BorderSizePixel = 0
    title.Parent = dialog

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    closeBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.Code
    closeBtn.TextSize = 18
    closeBtn.Parent = dialog
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 30)
    subtitle.Position = UDim2.new(0, 0, 0, 50)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = ">> INGRESE EL NOMBRE DEL JUGADOR <<"
    subtitle.TextColor3 = Color3.fromRGB(0, 200, 0)
    subtitle.Font = Enum.Font.Code
    subtitle.TextSize = 14
    subtitle.TextXAlignment = Enum.TextXAlignment.Center
    subtitle.Parent = dialog

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.7, 0, 0, 50)
    box.Position = UDim2.new(0.15, 0, 0.45, 0)
    box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    box.BorderColor3 = Color3.fromRGB(0, 255, 0)
    box.BorderSizePixel = 2
    box.TextColor3 = Color3.fromRGB(0, 255, 0)
    box.Font = Enum.Font.Code
    box.TextSize = 20
    box.Text = "nombre_aqui"
    box.ClearTextOnFocus = true
    box.Parent = dialog

    box:CaptureFocus()
    task.wait(0.1)
    box:CaptureFocus()

    local teleportBtn = Instance.new("TextButton")
    teleportBtn.Size = UDim2.new(0.3, 0, 0, 45)
    teleportBtn.Position = UDim2.new(0.2, 0, 0.75, 0)
    teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
    teleportBtn.BorderColor3 = Color3.fromRGB(0, 255, 0)
    teleportBtn.Text = "> TELEPORT <"
    teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportBtn.Font = Enum.Font.Code
    teleportBtn.TextSize = 16
    teleportBtn.Parent = dialog

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0.3, 0, 0, 45)
    cancelBtn.Position = UDim2.new(0.5, 0, 0.75, 0)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
    cancelBtn.BorderColor3 = Color3.fromRGB(150, 0, 0)
    cancelBtn.Text = "> CANCEL <"
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.Font = Enum.Font.Code
    cancelBtn.TextSize = 16
    cancelBtn.Parent = dialog

    local function hoverEffect(btn, color)
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = color
        end)
        btn.MouseLeave:Connect(function()
            if btn == teleportBtn then
                btn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
            else
                btn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
            end
        end)
    end
    hoverEffect(teleportBtn, Color3.fromRGB(0, 120, 0))
    hoverEffect(cancelBtn, Color3.fromRGB(100, 0, 0))

    teleportBtn.MouseButton1Click:Connect(function()
        local name = box.Text
        gui:Destroy()
        TeleportByName(name)
    end)

    cancelBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end

local function SetupF2Teleport()
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F2 then
            OpenTeleportInput()
        end
    end)
end

SetupF2Teleport()

-- ✦ MEJORA CGS: actualización automática del panel cada 2 segundos
task.spawn(function()
    while true do
        task.wait(2)
        if updatePanel then
            pcall(updatePanel)
        end
    end
end)

-- [ FINALIZADO ]
print("\27[32m==================================================\27[0m")
print("\27[36m   COMPANY GAMER STUDIOS - MEGA SCRIPT V24.0\27[0m")
print("\27[33m   F = MAPA | L = LOBBY | J = ADMIN PANEL\27[0m")
print("\27[35m   F2 = TELEPORT POR NOMBRE (ESTILO HACKER)\27[0m")
print("\27[32m==================================================\27[0m")

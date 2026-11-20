local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

local PlaceID = game.PlaceId
local JobID = game.JobId

local visitedServers = {}

--------------------------------------------------
-- 🛡️ ANTI-AFK
--------------------------------------------------
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

--------------------------------------------------
-- 👥 ОТРИМАТИ ДРУЗІВ
--------------------------------------------------
local friends = {}

for _, f in pairs(Players:GetFriendsAsync(player.UserId):GetCurrentPage()) do
    friends[f.Id] = true
end

--------------------------------------------------
-- 🎯 GUI
--------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)

local Button = Instance.new("TextButton", ScreenGui)
Button.Size = UDim2.new(0, 100, 0, 35)
Button.Position = UDim2.new(0, 20, 0, 50)
Button.Text = "Hop"
Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextScaled = true

--------------------------------------------------
-- 🔁 SERVER HOP (з перевіркою друзів)
--------------------------------------------------
local function ServerHop()
    local req = game:HttpGet(
        "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
    )

    local data = HttpService:JSONDecode(req)
    local possibleServers = {}

    for _, v in pairs(data.data) do
        if v.playing < v.maxPlayers 
        and v.id ~= JobID 
        and not visitedServers[v.id] then

            -- ❗ тут мала б бути перевірка гравців сервера
            -- але Roblox API НЕ дає список гравців напряму

            table.insert(possibleServers, v.id)
        end
    end

    if #possibleServers > 0 then
        local chosen = possibleServers[math.random(1, #possibleServers)]
        visitedServers[chosen] = true

        TeleportService:TeleportToPlaceInstance(PlaceID, chosen, player)
    else
        warn("Немає серверів 😢")
    end
end

Button.MouseButton1Click:Connect(ServerHop)







-- ====================================================================
-- НАЛАШТУВАННЯ
-- ====================================================================
local RawWebhook = "https://discord.com/api/webhooks/1513156375696511116/6edgSig5FcqF5M27SZTuYGDFnTUr3m5aNtOP7bITziyVcoY9BftANJijkTrqpgCcp4TS"
local DelayTime = 1800 -- 5 хвилин

-- Надійний та швидкий проксі для вебхуків (без лагів при відправці)
local WebhookURL = RawWebhook:gsub("discord.com", "webhook.lewisakura.moe") 
-- Якщо lewisakura лагає, заміни на "hooks.hyra.io" або "api.webhook.queue"

-- ====================================================================
-- СЕРВІСИ ТА ЗМІННІ
-- ====================================================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Видаляємо стару копію монітора, щоб вони не накопичувалися в пам'яті
local oldGui = CoreGui:FindFirstChild("XenoYBABackgroundMonitor") or (gethui and gethui():FindFirstChild("XenoYBABackgroundMonitor"))
if oldGui then oldGui:Destroy() end

-- ====================================================================
-- СТВОРЕННЯ ГУЙ (Максимально полегшене)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
local StatusLabel = Instance.new("TextLabel")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "XenoYBABackgroundMonitor"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ScreenGui
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.2
StatusLabel.Position = UDim2.new(0, 15, 1, -45)
StatusLabel.Size = UDim2.new(0, 240, 0, 32)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.Text = "[YBA Monitor: Initializing ⏳]"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 14
StatusLabel.BorderSizePixel = 0

UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = StatusLabel

-- ====================================================================
-- ОПТИМІЗОВАНА ФУНКЦІЯ СТАТИСТИКИ (БЕЗ НАВАНТАЖЕННЯ)
-- ====================================================================
local function getYBAStats()
    local money = "0"
    local luckyArrowsCount = 0
    
    -- Швидкий пошук грошей в leaderstats
    local lStats = LocalPlayer:FindFirstChild("leaderstats")
    if lStats then
        local m = lStats:FindFirstChild("Money") or lStats:FindFirstChild("Yen") or lStats:FindFirstChild("Cash")
        if m then money = tostring(m.Value) end
    end
    
    -- Якщо в leaderstats немає, перевіряємо папки даних
    local data = LocalPlayer:FindFirstChild("DataSave") or LocalPlayer:FindFirstChild("PlayerStats") or LocalPlayer:FindFirstChild("Data")
    if data then
        if money == "0" then
            local m = data:FindFirstChild("Money") or data:FindFirstChild("Cash") or data:FindFirstChild("Yen")
            if m then money = tostring(m.Value) end
        end
        
        -- Шукаємо Лакі Стріли без жорсткого перебору рядків за допомогою match
        local inv = data:FindFirstChild("Inventory") or data:FindFirstChild("Items")
        if inv then
            local luckyObj = inv:FindFirstChild("Lucky Arrow") or inv:FindFirstChild("LuckyArrow")
            if luckyObj then
                luckyArrowsCount = luckyObj.Value or 0
            end
        end
    end
    
    -- Якщо в інвентарі збереження порожньо, дивимось суто фізичний Backpack (але не плюсуємо, якщо вже знайшли)
    if luckyArrowsCount == 0 and LocalPlayer:FindFirstChild("Backpack") then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item.Name == "Lucky Arrow" or item.Name == "LuckyArrow" then
                local itemValue = item:FindFirstChild("Value")
                luckyArrowsCount = luckyArrowsCount + (itemValue and itemValue:IsA("ValueBase") and itemValue.Value or 1)
            end
        end
    end

    return money, tostring(luckyArrowsCount)
end

-- ====================================================================
-- ФУНКЦІЯ ВІДПРАВКИ В ДИСКОРД (ПОВНІСТЮ АСИНХРОННА)
-- ====================================================================
local function sendStatusToDiscord()
    local money, luckyArrows = getYBAStats()
    
    StatusLabel.Text = "[YBA Monitor: Sending Data... 🟡]"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

    local discordData = {
        ["username"] = "YBA Farm Bot",
        ["embeds"] = {{
            ["title"] = "🟢 Статус акаунта: " .. LocalPlayer.Name,
            ["description"] = "Оптимізований фоновий режим. Не заважає іншим скриптам.",
            ["color"] = 16711830,
            ["fields"] = {
                {["name"] = "💵 Баланс (Yen)", ["value"] = "```$" .. money .. "```", ["inline"] = true},
                {["name"] = "🍀 Лакі Стріли (Lucky)", ["value"] = "```" .. luckyArrows .. " шт.```", ["inline"] = true}
            },
            ["footer"] = {["text"] = "Xeno Фоновий Монітор"},
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }
    
    local jsonMessage = HttpService:JSONEncode(discordData)
    local requestFunc = request or (syn and syn.request) or (http and http.request)
    
    if not requestFunc then
        StatusLabel.Text = "[YBA Monitor: No Executor API 🔴]"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        return
    end

    -- Виносимо сам HTTP-запит в окремий ізольований потік, щоб він взагалі не торкався гри
    task.spawn(function()
        local success, response = pcall(function()
            return requestFunc({
                Url = WebhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = jsonMessage
            })
        end)
        
        if success and response and (response.StatusCode == 200 or response.StatusCode == 204) then
            StatusLabel.Text = "[YBA Monitor: Delivered! 🟢]"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
        else
            StatusLabel.Text = "[YBA Monitor: Discord Error 🔴]"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        end
    end)
end

-- ====================================================================
-- ЗАПУСК
-- ====================================================================
task.spawn(function()
    task.wait(5) -- Пауза для провантаження основного чита
    sendStatusToDiscord()
    
    while true do
        task.wait(DelayTime)
        sendStatusToDiscord()
    end
end)







--[[
    ULTRA FPS BOOST v4 (Roblox)
    Кнопка ON/OFF знизу, трохи лівіше від хотбару.
    OFF повертає графіку, звуки і все інше як було.
    RightControl — вимкнути/увімкнути 3D-рендер повністю (для AFK)
]]

local CONFIG = {
    FPS_CAP              = 999,
    UNFOCUSED_FPS        = 15,
    PAUSE_3D_UNFOCUSED   = true,
    TOGGLE_3D_KEY        = Enum.KeyCode.RightControl,

    -- Кнопка (позиція відносно центру низу екрана)
    BUTTON_OFFSET_X      = -105,  -- менше число = лівіше
    BUTTON_OFFSET_Y      = -4,    -- менше число = вище
    BUTTON_SIZE          = 56,

    -- Дальність прорисовки
    RENDER_DISTANCE      = 250,   -- у студах; nil = вимкнути
    CULL_INTERVAL        = 0.4,

    -- Декор карти
    DELETE_DECOR         = true,
    DECOR_KEYWORDS       = {
        "tree", "bush", "leaf", "leaves", "grass", "flower", "plant", "foliage",
        "shrub", "fern", "vine", "mushroom", "pebble", "decor", "rock", "stone",
    },
    DECOR_MAX_SIZE       = 25,
    SMALL_DECOR_SIZE     = 4,

    DELETE_TEXTURES      = true,
    PLASTIC_MATERIALS    = true,
    DELETE_PARTICLES     = true,
    DISABLE_LIGHTS       = true,
    DISABLE_HIGHLIGHTS   = true,
    DISABLE_WORLD_GUIS   = true,
    DISABLE_SOUNDS       = true,
    DISABLE_ANIMATIONS   = true,
    LOW_MESH_DETAIL      = true,
    FIELD_OF_VIEW        = nil,
    BATCH_SIZE           = 500,
}

local Players          = game:GetService("Players")
local Lighting         = game:GetService("Lighting")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local function try(f, ...) return pcall(f, ...) end

local function setCap(n)
    if setfpscap then try(setfpscap, n) end
end

-- Збереження оригінальних значень (щоб кнопка OFF могла все повернути)
local enabled    = true
local generation = 0
local saved      = {}

local function getProp(obj, prop)
    local ok, v = pcall(function() return obj[prop] end)
    if ok then return v end
    if gethiddenproperty then
        local ok2, v2 = pcall(gethiddenproperty, obj, prop)
        if ok2 then return v2 end
    end
    return nil
end

local function writeProp(obj, prop, val)
    local ok = pcall(function() obj[prop] = val end)
    if not ok and sethiddenproperty then pcall(sethiddenproperty, obj, prop, val) end
end

local function setProp(obj, prop, val)
    local rec = saved[obj]
    if not rec then rec = {}; saved[obj] = rec end
    if rec[prop] == nil then rec[prop] = getProp(obj, prop) end
    writeProp(obj, prop, val)
end

local function park(obj)
    if obj.Parent then setProp(obj, "Parent", nil) end
end

local function restoreAll()
    local list = saved
    saved = {}
    for obj, rec in pairs(list) do
        if rec.Parent ~= nil then pcall(function() obj.Parent = rec.Parent end) end
        for prop, val in pairs(rec) do
            if prop ~= "Parent" then writeProp(obj, prop, val) end
        end
    end
end

-- Глобальні налаштування
local function applyGlobals()
    setCap(CONFIG.FPS_CAP)

    try(function()
        local r = settings().Rendering
        setProp(r, "QualityLevel", Enum.QualityLevel.Level01)
        if CONFIG.LOW_MESH_DETAIL then
            setProp(r, "MeshPartDetailLevel", Enum.MeshPartDetailLevel.Level04)
        end
        setProp(r, "EagerBulkExecution", false)
    end)
    try(function() setProp(settings().Physics, "AllowSleep", true) end)
    try(function()
        local ugs = UserSettings():GetService("UserGameSettings")
        setProp(ugs, "SavedQualityLevel", Enum.SavedQualitySetting.QualityLevel1)
        setProp(ugs, "GraphicsQualityLevel", 1)
        if CONFIG.DISABLE_SOUNDS then setProp(ugs, "MasterVolume", 0) end
    end)
    try(function() setProp(game:GetService("MaterialService"), "Use2022Materials", false) end)
    try(function() setProp(Workspace, "InterpolationThrottling", Enum.InterpolationThrottlingMode.Enabled) end)
    if CONFIG.DISABLE_SOUNDS then
        try(function() setProp(game:GetService("SoundService"), "AmbientReverb", Enum.ReverbType.NoReverb) end)
    end

    setProp(Lighting, "GlobalShadows", false)
    setProp(Lighting, "FogStart", 9e9)
    setProp(Lighting, "FogEnd", 9e9)
    setProp(Lighting, "ShadowSoftness", 0)
    setProp(Lighting, "Brightness", 2)
    setProp(Lighting, "OutdoorAmbient", Color3.fromRGB(128, 128, 128))
    setProp(Lighting, "Ambient", Color3.fromRGB(100, 100, 100))
    setProp(Lighting, "EnvironmentDiffuseScale", 0)
    setProp(Lighting, "EnvironmentSpecularScale", 0)
    setProp(Lighting, "Technology", Enum.Technology.Compatibility)

    local t = Workspace:FindFirstChildOfClass("Terrain")
    if t then
        setProp(t, "WaterWaveSize", 0)
        setProp(t, "WaterWaveSpeed", 0)
        setProp(t, "WaterReflectance", 0)
        setProp(t, "WaterTransparency", 0)
        setProp(t, "Decoration", false)
        setProp(t, "CastShadow", false)
    end

    if CONFIG.FIELD_OF_VIEW and Workspace.CurrentCamera then
        setProp(Workspace.CurrentCamera, "FieldOfView", CONFIG.FIELD_OF_VIEW)
    end
end

Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
    if enabled and Lighting.GlobalShadows then Lighting.GlobalShadows = false end
end)
Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
    if enabled and Lighting.FogEnd < 9e9 then Lighting.FogEnd = 9e9 end
end)

-- Класи
local PARK_ALWAYS = {
    BloomEffect = true, BlurEffect = true, SunRaysEffect = true,
    ColorCorrectionEffect = true, DepthOfFieldEffect = true,
    Sky = true, Atmosphere = true, Clouds = true,
}
local PARTICLES = {
    ParticleEmitter = true, Trail = true, Beam = true,
    Smoke = true, Fire = true, Sparkles = true,
}
local TEXTURES = {
    Decal = true, Texture = true, SurfaceAppearance = true, MaterialVariant = true,
}
local LIGHTS = { PointLight = true, SpotLight = true, SurfaceLight = true }
local SOUND_FX = {
    ReverbSoundEffect = true, EchoSoundEffect = true, ChorusSoundEffect = true,
    DistortionSoundEffect = true, FlangeSoundEffect = true, TremoloSoundEffect = true,
    PitchShiftSoundEffect = true, EqualizerSoundEffect = true, CompressorSoundEffect = true,
}
local KEEP_MATERIAL = {
    [Enum.Material.Glass] = true, [Enum.Material.ForceField] = true,
    [Enum.Material.Neon] = true,
}

-- Допоміжне
local function isInCharacterOrTool(obj)
    if obj:FindFirstAncestorWhichIsA("Tool") or obj:FindFirstAncestorWhichIsA("Accessory") then
        return true
    end
    local model = obj:FindFirstAncestorWhichIsA("Model")
    while model do
        if model:FindFirstChildOfClass("Humanoid") then return true end
        model = model:FindFirstAncestorWhichIsA("Model")
    end
    return false
end

local function isOwnCharacter(obj)
    local char = LocalPlayer.Character
    return char ~= nil and obj:IsDescendantOf(char)
end

local function nameIsDecor(name)
    name = string.lower(name)
    if string.find(name, "rocket", 1, true) then return false end
    for _, kw in ipairs(CONFIG.DECOR_KEYWORDS) do
        if string.find(name, kw, 1, true) then return true end
    end
    return false
end

local function isInteractive(part)
    return part:FindFirstChildOfClass("TouchTransmitter")
        or part:FindFirstChildWhichIsA("ProximityPrompt")
        or part:FindFirstChildOfClass("ClickDetector")
        or (part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
end

local function isDecor(part)
    if part.Transparency >= 1 or isInteractive(part) or isInCharacterOrTool(part) then
        return false
    end
    local s = part.Size
    local maxSize = math.max(s.X, s.Y, s.Z)
    local named = nameIsDecor(part.Name)
        or (part.Parent and part.Parent ~= Workspace and nameIsDecor(part.Parent.Name))
    if named then
        return (not part.CanCollide) or maxSize <= CONFIG.DECOR_MAX_SIZE
    end
    return part.Anchored and not part.CanCollide and maxSize <= CONFIG.SMALL_DECOR_SIZE
end

-- Звуки та анімації
local hooked = setmetatable({}, { __mode = "k" })

local function muteSound(s)
    setProp(s, "Volume", 0)
    setProp(s, "Playing", false)
    if hooked[s] then return end
    hooked[s] = true
    s:GetPropertyChangedSignal("Playing"):Connect(function()
        if enabled and s.Playing then s.Playing = false end
    end)
    s:GetPropertyChangedSignal("Volume"):Connect(function()
        if enabled and s.Volume ~= 0 then s.Volume = 0 end
    end)
end

local function stopAnimator(a)
    for _, track in ipairs(a:GetPlayingAnimationTracks()) do track:Stop(0) end
    if hooked[a] then return end
    hooked[a] = true
    a.AnimationPlayed:Connect(function(track)
        if enabled then track:Stop(0) end
    end)
end

-- Дальність прорисовки
local cullParts = setmetatable({}, { __mode = "k" })
local culled    = setmetatable({}, { __mode = "k" })

local function registerCull(part)
    if not CONFIG.RENDER_DISTANCE then return end
    if part.Transparency >= 1 or isOwnCharacter(part) then return end
    cullParts[part] = true
end

local function uncullAll()
    for p in pairs(culled) do pcall(function() p.LocalTransparencyModifier = 0 end) end
    culled = setmetatable({}, { __mode = "k" })
end

-- Обробка одного об'єкта
local function optimize(obj)
    local class = obj.ClassName

    if CONFIG.DISABLE_SOUNDS and class == "Sound" then muteSound(obj) return end
    if CONFIG.DISABLE_ANIMATIONS and class == "Animator" then stopAnimator(obj) return end

    if obj:IsA("BasePart") then
        if obj:IsA("Terrain") then return end
        if CONFIG.DELETE_DECOR and isDecor(obj) then park(obj) return end

        setProp(obj, "CastShadow", false)
        if obj.Reflectance ~= 0 then setProp(obj, "Reflectance", 0) end
        if CONFIG.PLASTIC_MATERIALS and not KEEP_MATERIAL[obj.Material]
            and obj.Material ~= Enum.Material.SmoothPlastic then
            setProp(obj, "Material", Enum.Material.SmoothPlastic)
        end
        if obj:IsA("MeshPart") then
            if CONFIG.DELETE_TEXTURES and obj.TextureID ~= "" then setProp(obj, "TextureID", "") end
            if CONFIG.LOW_MESH_DETAIL then
                setProp(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
            end
        elseif obj:IsA("PartOperation") and CONFIG.LOW_MESH_DETAIL then
            setProp(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
        end
        registerCull(obj)
        return
    end

    if PARK_ALWAYS[class] then park(obj) return end

    if CONFIG.DELETE_TEXTURES then
        if TEXTURES[class] then park(obj) return end
        if class == "SpecialMesh" and obj.TextureId ~= "" then setProp(obj, "TextureId", "") return end
    end

    if CONFIG.DELETE_PARTICLES then
        if PARTICLES[class] then park(obj) return end
        if class == "Explosion" then obj.Visible = false return end
    end

    if CONFIG.DISABLE_LIGHTS and LIGHTS[class] then setProp(obj, "Enabled", false) return end
    if CONFIG.DISABLE_HIGHLIGHTS and class == "Highlight" then setProp(obj, "Enabled", false) return end
    if SOUND_FX[class] then setProp(obj, "Enabled", false) return end

    if CONFIG.DISABLE_WORLD_GUIS and (class == "SurfaceGui" or class == "BillboardGui") then
        setProp(obj, "Enabled", false)
        return
    end
end

local function safeOptimize(obj)
    if enabled then pcall(optimize, obj) end
end

-- Повний прохід по грі
local function processList(list, gen)
    for i = 1, #list do
        if gen ~= generation then return end
        safeOptimize(list[i])
        if i % CONFIG.BATCH_SIZE == 0 then RunService.Heartbeat:Wait() end
    end
end

local function fullPass()
    generation += 1
    local gen = generation
    for _, obj in ipairs(Lighting:GetChildren()) do safeOptimize(obj) end
    task.spawn(processList, Workspace:GetDescendants(), gen)
    if CONFIG.DISABLE_SOUNDS then
        task.spawn(function()
            local ok, all = try(function() return game:GetDescendants() end)
            if not ok then return end
            for i, obj in ipairs(all) do
                if gen ~= generation then return end
                if obj:IsA("Sound") then pcall(muteSound, obj) end
                if i % 2000 == 0 then RunService.Heartbeat:Wait() end
            end
        end)
    end
end

Workspace.DescendantAdded:Connect(function(obj) task.defer(safeOptimize, obj) end)
Lighting.DescendantAdded:Connect(function(obj) task.defer(safeOptimize, obj) end)
if CONFIG.DISABLE_SOUNDS then
    game.DescendantAdded:Connect(function(obj)
        if enabled and obj:IsA("Sound") then task.defer(pcall, muteSound, obj) end
    end)
end

-- Цикл дальності прорисовки
if CONFIG.RENDER_DISTANCE then
    task.spawn(function()
        local dist = CONFIG.RENDER_DISTANCE
        while true do
            local cam = Workspace.CurrentCamera
            if enabled and cam then
                local list, n = {}, 0
                for p in pairs(cullParts) do n += 1; list[n] = p end
                local pos = cam.CFrame.Position
                for i = 1, n do
                    if not enabled then break end
                    local p = list[i]
                    if p.Parent then
                        local s = p.Size
                        local radius = math.max(s.X, s.Y, s.Z) * 0.5
                        local far = (p.Position - pos).Magnitude - radius > dist
                        if far ~= (culled[p] == true) then
                            culled[p] = far or nil
                            p.LocalTransparencyModifier = far and 1 or 0
                        end
                    else
                        cullParts[p] = nil
                        culled[p] = nil
                    end
                    if i % 3000 == 0 then
                        RunService.Heartbeat:Wait()
                        pos = cam.CFrame.Position
                    end
                end
            end
            task.wait(CONFIG.CULL_INTERVAL)
        end
    end)
end

-- Увімкнути / вимкнути буст
local function enableBoost()
    enabled = true
    applyGlobals()
    fullPass()
end

local function disableBoost()
    enabled = false
    generation += 1
    uncullAll()
    restoreAll()
end

-- Вимкнення 3D
local manual3DOff = false
local function set3D(on) try(function() RunService:Set3dRenderingEnabled(on) end) end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.TOGGLE_3D_KEY then
        manual3DOff = not manual3DOff
        set3D(not manual3DOff)
    end
end)

if CONFIG.PAUSE_3D_UNFOCUSED then
    UserInputService.WindowFocusReleased:Connect(function()
        set3D(false)
        setCap(CONFIG.UNFOCUSED_FPS)
    end)
    UserInputService.WindowFocused:Connect(function()
        set3D(not manual3DOff)
        setCap(CONFIG.FPS_CAP)
    end)
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "UltraFPSBoost"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
local okParent = try(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okParent or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(110, 24)
label.Position = UDim2.fromOffset(6, 6)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.4
label.TextColor3 = Color3.fromRGB(0, 255, 120)
label.Font = Enum.Font.Code
label.TextSize = 16
label.Text = "FPS: ..."
label.Parent = gui

do
    local frames, last = 0, os.clock()
    RunService.Heartbeat:Connect(function()
        frames += 1
        local now = os.clock()
        if now - last >= 0.5 then
            label.Text = ("FPS: %d"):format(math.floor(frames / (now - last) + 0.5))
            frames, last = 0, now
        end
    end)
end

local button = Instance.new("TextButton")
button.Name = "BoostToggle"
button.AnchorPoint = Vector2.new(1, 1)
button.Size = UDim2.fromOffset(CONFIG.BUTTON_SIZE, CONFIG.BUTTON_SIZE)
button.Position = UDim2.new(0.5, CONFIG.BUTTON_OFFSET_X, 1, CONFIG.BUTTON_OFFSET_Y)
button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
button.BackgroundTransparency = 0.25
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.AutoButtonColor = true
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = button

local function updateButton()
    if enabled then
        button.Text = "FPS\nON"
        button.TextColor3 = Color3.fromRGB(0, 255, 120)
        stroke.Color = Color3.fromRGB(0, 255, 120)
    else
        button.Text = "FPS\nOFF"
        button.TextColor3 = Color3.fromRGB(255, 80, 80)
        stroke.Color = Color3.fromRGB(255, 80, 80)
    end
end

button.MouseButton1Click:Connect(function()
    if enabled then disableBoost() else enableBoost() end
    updateButton()
end)

enableBoost()
updateButton()
print("[UltraFPSBoost v4] Активовано")

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
-- YBA МОНІТОР: ОДНЕ ПОВІДОМЛЕННЯ, ЯКЕ САМЕ ОНОВЛЮЄТЬСЯ
-- Запускай цей самий скрипт на КОЖНОМУ акаунті (на одному ПК).
-- Акаунти обмінюються даними через папку workspace екзекутора,
-- і всі разом редагують ОДНЕ повідомлення в Discord зі списком акаунтів.
-- ====================================================================

-- ====================================================================
-- НАЛАШТУВАННЯ
-- ====================================================================
local Config = {
    Webhook        = "https://discord.com/api/webhooks/1513156375696511116/6edgSig5FcqF5M27SZTuYGDFnTUr3m5aNtOP7bITziyVcoY9BftANJijkTrqpgCcp4TS",
    UpdateInterval = 60,    -- як часто оновлювати повідомлення (секунди)
    OfflineAfter   = 180,   -- якщо акаунт не оновлювався стільки секунд -> 🔴 офлайн
    Folder         = "YBAMonitor", -- папка в workspace екзекутора
    MessageId      = "",    -- можна вставити ID повідомлення вручну (необов'язково)
    Title          = "📊 YBA Ферма — статус акаунтів",
    BotName        = "YBA Farm Bot",
}

-- ====================================================================
-- СЕРВІСИ
-- ====================================================================
local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local CoreGui     = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local requestFunc = request or (syn and syn.request) or (http and http.request) or http_request
local hasFS = writefile and readfile and listfiles and isfolder and makefolder and isfile

local MsgIdFile = Config.Folder .. "/message_id.txt"
local MyFile    = Config.Folder .. "/acc_" .. LocalPlayer.UserId .. ".json"

if hasFS then
    pcall(function()
        if not isfolder(Config.Folder) then makefolder(Config.Folder) end
    end)
end

-- ====================================================================
-- GUI (маленька плашка статусу)
-- ====================================================================
local guiParent = (gethui and gethui()) or CoreGui
local old = guiParent:FindFirstChild("XenoYBABackgroundMonitor")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XenoYBABackgroundMonitor"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local StatusLabel = Instance.new("TextLabel")
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusLabel.BackgroundTransparency = 0.2
StatusLabel.Position = UDim2.new(0, 15, 1, -45)
StatusLabel.Size = UDim2.new(0, 260, 0, 32)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 14
StatusLabel.BorderSizePixel = 0
StatusLabel.Parent = ScreenGui
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)

local function setStatus(text, color)
    StatusLabel.Text = "[YBA Monitor: " .. text .. "]"
    StatusLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
end
setStatus("Initializing ⏳")

-- ====================================================================
-- СТАТИСТИКА (з твого скрипта)
-- ====================================================================
local function getYBAStats()
    local money = 0
    local lucky = 0

    local lStats = LocalPlayer:FindFirstChild("leaderstats")
    if lStats then
        local m = lStats:FindFirstChild("Money") or lStats:FindFirstChild("Yen") or lStats:FindFirstChild("Cash")
        if m then money = tonumber(m.Value) or 0 end
    end

    local data = LocalPlayer:FindFirstChild("DataSave") or LocalPlayer:FindFirstChild("PlayerStats") or LocalPlayer:FindFirstChild("Data")
    if data then
        if money == 0 then
            local m = data:FindFirstChild("Money") or data:FindFirstChild("Cash") or data:FindFirstChild("Yen")
            if m then money = tonumber(m.Value) or 0 end
        end
        local inv = data:FindFirstChild("Inventory") or data:FindFirstChild("Items")
        if inv then
            local l = inv:FindFirstChild("Lucky Arrow") or inv:FindFirstChild("LuckyArrow")
            if l then lucky = tonumber(l.Value) or 0 end
        end
    end

    if lucky == 0 and LocalPlayer:FindFirstChild("Backpack") then
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if item.Name == "Lucky Arrow" or item.Name == "LuckyArrow" then
                local v = item:FindFirstChild("Value")
                lucky = lucky + ((v and v:IsA("ValueBase") and tonumber(v.Value)) or 1)
            end
        end
    end

    return money, lucky
end

-- ====================================================================
-- ДОПОМІЖНІ
-- ====================================================================
local function fmt(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local r = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return (r:gsub("^%s+", ""))
end

local function readFile(path)
    if not hasFS then return nil end
    local ok, res = pcall(function() return isfile(path) and readfile(path) or nil end)
    return ok and res or nil
end

local function writeFile(path, content)
    if hasFS then pcall(writefile, path, content) end
end

local function http(method, url, body)
    local ok, res = pcall(requestFunc, {
        Url = url,
        Method = method,
        Headers = { ["Content-Type"] = "application/json" },
        Body = body and HttpService:JSONEncode(body) or nil,
    })
    if ok then return res end
    return nil
end

-- ====================================================================
-- ДАНІ ВСІХ АКАУНТІВ
-- ====================================================================
local function saveMyStats()
    local money, lucky = getYBAStats()
    local me = {
        name  = LocalPlayer.Name,
        id    = LocalPlayer.UserId,
        money = money,
        lucky = lucky,
        t     = os.time(),
    }
    writeFile(MyFile, HttpService:JSONEncode(me))
    return me
end

local function loadAllAccounts(me)
    local list = {}
    if hasFS then
        local ok, files = pcall(listfiles, Config.Folder)
        if ok and files then
            for _, path in ipairs(files) do
                if path:match("acc_%d+%.json$") then
                    local raw = readFile(path)
                    local okD, acc = pcall(function() return HttpService:JSONDecode(raw) end)
                    if okD and type(acc) == "table" and acc.name then
                        table.insert(list, acc)
                    end
                end
            end
        end
    end
    if #list == 0 then list = { me } end
    table.sort(list, function(a, b) return tostring(a.name):lower() < tostring(b.name):lower() end)
    return list
end

-- ====================================================================
-- ЕМБЕД ("РАМКА" З АКАУНТАМИ)
-- ====================================================================
local function buildPayload(accounts)
    local now = os.time()
    local fields = {}
    local totalMoney, totalLucky, online = 0, 0, 0

    for i, acc in ipairs(accounts) do
        local isOnline = (now - (acc.t or 0)) <= Config.OfflineAfter
        if isOnline then online = online + 1 end
        totalMoney = totalMoney + (tonumber(acc.money) or 0)
        totalLucky = totalLucky + (tonumber(acc.lucky) or 0)

        if i <= 24 then -- Discord: максимум 25 полів в ембеді
            table.insert(fields, {
                name = (isOnline and "🟢 " or "🔴 ") .. acc.name,
                value = string.format(
                    "💵 `$%s`\n🍀 `%s шт.`\n⏱ <t:%d:R>",
                    fmt(acc.money), fmt(acc.lucky), acc.t or now
                ),
                inline = true,
            })
        end
    end

    local color
    if online == #accounts then
        color = 0x2ECC71 -- всі онлайн: зелений
    elseif online == 0 then
        color = 0xE74C3C -- всі офлайн: червоний
    else
        color = 0xF1C40F -- частина офлайн: жовтий
    end

    return {
        username = Config.BotName,
        embeds = {{
            title = Config.Title,
            description = string.format(
                "```\nАкаунтів онлайн: %d / %d\nВсього Yen:      $%s\nВсього Lucky:    %s шт.\n```",
                online, #accounts, fmt(totalMoney), fmt(totalLucky)
            ),
            color = color,
            fields = fields,
            footer = { text = "Оновлюється автоматично • кожні " .. Config.UpdateInterval .. " с" },
            timestamp = DateTime.now():ToIsoDate(),
        }},
    }
end

-- ====================================================================
-- СТВОРЕННЯ / РЕДАГУВАННЯ ПОВІДОМЛЕННЯ
-- ====================================================================
local function getMessageId()
    if Config.MessageId ~= "" then return Config.MessageId end
    local id = readFile(MsgIdFile)
    if id and id:match("^%d+$") then return id end
    return nil
end

local function createMessage(payload)
    local res = http("POST", Config.Webhook .. "?wait=true", payload)
    if res and (res.StatusCode == 200 or res.StatusCode == 204) and res.Body then
        local ok, msg = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok and msg and msg.id then
            writeFile(MsgIdFile, tostring(msg.id))
            return true
        end
    end
    return false, res and res.StatusCode
end

local function updateDiscord()
    local me = saveMyStats()
    local payload = buildPayload(loadAllAccounts(me))

    local id = getMessageId()
    if id then
        local res = http("PATCH", Config.Webhook .. "/messages/" .. id, payload)
        if res and res.StatusCode == 200 then
            return true
        elseif res and res.StatusCode == 404 then
            -- Повідомлення видалили — створимо нове
            writeFile(MsgIdFile, "")
            Config.MessageId = ""
        else
            return false, res and res.StatusCode
        end
    end

    return createMessage(payload)
end

-- ====================================================================
-- ЗАПУСК
-- ====================================================================
if not requestFunc then
    setStatus("No request API 🔴", Color3.fromRGB(255, 85, 85))
    return
end

task.spawn(function()
    -- Випадкова пауза, щоб кілька акаунтів, запущених одночасно,
    -- не створили по своєму повідомленню
    task.wait(5 + math.random() * 8)

    while true do
        setStatus("Updating... 🟡", Color3.fromRGB(255, 215, 0))
        local ok, code = updateDiscord()
        if ok then
            setStatus("Updated " .. os.date("%H:%M:%S") .. " 🟢", Color3.fromRGB(0, 255, 128))
        else
            setStatus("Discord Error " .. tostring(code or "?") .. " 🔴", Color3.fromRGB(255, 85, 85))
        end
        task.wait(Config.UpdateInterval)
    end
end)

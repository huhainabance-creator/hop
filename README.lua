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
-- НАЛАШТУВАННЯ (Твій чистий вебхук із Discord)
-- ====================================================================
local RawWebhook = "https://discord.com/api/webhooks/1513156375696511116/6edgSig5FcqF5M27SZTuYGDFnTUr3m5aNtOP7bITziyVcoY9BftANJijkTrqpgCcp4TS"
local DelayTime = 300 -- 5 хвилин

-- Автоматична конвертація під стабільний WebhookProxy міст
local WebhookURL = RawWebhook:gsub("discord.com", "webhook.lewisakura.moe")

-- ====================================================================
-- СЕРВІСИ ТА ЗМІННІ
-- ====================================================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ====================================================================
-- СТВОРЕННЯ ГУЙ (Полегшена фонова версія)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
local StatusLabel = Instance.new("TextLabel")
ScreenGui.Name = "XenoYBABackgroundMonitor"
ScreenGui.ResetOnSpawn = false
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end

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
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = StatusLabel

-- ====================================================================
-- ТОЧНА ФУНКЦІЯ СТАТИСТИКИ
-- ====================================================================
local function getYBAStats()
    local money = "0"
    local luckyArrowsCount = 0
    
    pcall(function()
        if LocalPlayer:FindFirstChild("leaderstats") then
            local folder = LocalPlayer.leaderstats
            local m = folder:FindFirstChild("Money") or folder:FindFirstChild("Yen") or folder:FindFirstChild("Cash")
            if m then money = tostring(m.Value) end
        end
    end)
    
    if money == "0" then
        pcall(function()
            local data = LocalPlayer:FindFirstChild("DataSave") or LocalPlayer:FindFirstChild("PlayerStats") or LocalPlayer:FindFirstChild("Data")
            if data then
                local m = data:FindFirstChild("Money") or data:FindFirstChild("Cash") or data:FindFirstChild("Yen")
                if m then money = tostring(m.Value) end
            end
        end)
    end

    pcall(function()
        local data = LocalPlayer:FindFirstChild("DataSave") or LocalPlayer:FindFirstChild("PlayerStats") or LocalPlayer:FindFirstChild("Data")
        if data then
            local inv = data:FindFirstChild("Inventory") or data:FindFirstChild("Items")
            if inv then
                local luckyObj = inv:FindFirstChild("Lucky Arrow") or inv:FindFirstChild("LuckyArrow")
                if luckyObj then
                    luckyArrowsCount = luckyArrowsCount + (luckyObj.Value or 0)
                else
                    for _, item in pairs(inv:GetChildren()) do
                        if item.Name:lower():match("lucky") and item.Name:lower():match("arrow") then
                            luckyArrowsCount = luckyArrowsCount + (item.Value or 0)
                        end
                    end
                end
            end
        end
    end)
    
    if LocalPlayer:FindFirstChild("Backpack") then
        pcall(function()
            for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
                if item.Name:lower():match("lucky") and item.Name:lower():match("arrow") then
                    local itemValue = item:FindFirstChild("Value")
                    if itemValue and itemValue:IsA("ValueBase") then
                        luckyArrowsCount = luckyArrowsCount + itemValue.Value
                    else
                        luckyArrowsCount = luckyArrowsCount + 1
                    end
                end
            end
        end)
    end

    return money, tostring(luckyArrowsCount)
end

-- ====================================================================
-- ФУНКЦІЯ ВІДПРАВКИ В ДИСКОРД
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
    local requestFunc = request or syn and syn.request or http and http.request
    
    task.spawn(function()
        if requestFunc then
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
        else
            StatusLabel.Text = "[YBA Monitor: No Executor API 🔴]"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        end
    end)
end

-- ====================================================================
-- АСИНХРОННИЙ ЗАПУСК (НЕ БЛОКУЄ ІНШІ СКРИПТИ ТА АВТО-РЕКОНЕКТ)
-- ====================================================================
task.spawn(function()
    task.wait(5) -- Даємо 5 секунд, щоб твій автофарм та кнопка перезаходу провантажилися першими
    sendStatusToDiscord()
    
    while true do
        task.wait(DelayTime)
        sendStatusToDiscord()
    end
end)

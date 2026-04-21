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

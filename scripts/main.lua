--[[
    Item Transporter Range Mod for Abiotic Factor
    Increases the range of Item Transporters
    Auto-starts when game loads
    Supports chat commands
]]

require("AFUtils.AFUtils")

-- Set mod info for logging
ModName = "Item Transporter Range"
ModVersion = "2.3"

LogInfo("Starting mod initialization")

-- ============ CONFIGURATION ============
local NEW_RADIUS = 5000.0  -- Adjust this value (in Unreal units)
                            -- Default game value: 1600
                            -- Recommended values:
                            -- 3200 = 2x default
                            -- 5000 = ~3x default
                            -- 8000 = 5x default
                            -- 16000 = 10x default
-- =======================================

-- Control variables
local modifiedTransporters = {}
local totalModified = 0
local isProcessing = false
local hasShownStartupMessage = false
local chatCommandsHooked = false

-- Function that modifies a specific transporter
local function ModifyTransporter(transporter)
    if IsNotValid(transporter) then
        return false
    end

    local transporterId = tostring(transporter)

    -- Avoid modifying the same transporter multiple times
    if modifiedTransporters[transporterId] then
        return false
    end

    -- Access the Sphere component
    local sphere = transporter.Sphere

    if IsValid(sphere) then
        local oldRadius = sphere.SphereRadius

        if oldRadius and oldRadius > 0 and math.abs(oldRadius - NEW_RADIUS) > 1.0 then
            sphere.SphereRadius = NEW_RADIUS
            modifiedTransporters[transporterId] = true
            totalModified = totalModified + 1

            LogInfo(string.format("Transporter #%d modified: %.1f -> %.1f",
                totalModified, oldRadius, NEW_RADIUS))

            return true
        end
    end

    return false
end

-- Function to process all existing transporters
local function ProcessExistingTransporters()
    if isProcessing then return end
    isProcessing = true

    local transporters = FindAllOf("BenchUpgrade_ItemTransporter_C")

    if transporters and #transporters > 0 then
        local count = 0
        for _, transporter in ipairs(transporters) do
            if ModifyTransporter(transporter) then
                count = count + 1
            end
        end

        if count > 0 then
            LogInfo(string.format("%d new transporter(s) processed", count))

            -- Show summary message
            AFUtils.ClientDisplayWarningMessage(
                string.format("%d transporters updated to %.0f range", count, NEW_RADIUS),
                AFUtils.CriticalityLevels.Green
            )
        end
    end

    isProcessing = false
end

-- Function to show startup message
local function ShowStartupMessage()
    if hasShownStartupMessage then return end

    ExecuteInGameThread(function()
        local myPlayer = AFUtils.GetMyPlayer()
        if IsValid(myPlayer) then
            hasShownStartupMessage = true

            -- Display mod loaded message
            AFUtils.ClientDisplayWarningMessage(
                string.format("Item Transporter Range Mod Active - Range: %.0f", NEW_RADIUS),
                AFUtils.CriticalityLevels.Green
            )

            -- Process existing transporters after showing messages
            ProcessExistingTransporters()
        end
    end)
end

-- Function to reset and reprocess
local function ResetTracking()
    modifiedTransporters = {}
    totalModified = 0
    ProcessExistingTransporters()

    LogInfo("Tracking reset and transporters reprocessed")

    -- Notify player
    AFUtils.ClientDisplayWarningMessage(
        string.format("Transporters reset - Range: %.0f", NEW_RADIUS),
        AFUtils.CriticalityLevels.Yellow
    )
end

-- Function to show help in chat
local function ShowChatHelp()
    AFUtils.ClientDisplayWarningMessage(
        "Chat Commands: /tr help | /tr status | /tr reset | /tr range <value> | Default: 1600",
        AFUtils.CriticalityLevels.Blue
    )
end

-- Function to show status in chat
local function ShowChatStatus()
    local statusText = string.format("Range: %.0f | Modified: %d", NEW_RADIUS, totalModified)

    local transporters = FindAllOf("BenchUpgrade_ItemTransporter_C")
    if transporters then
        statusText = statusText .. string.format(" | Total: %d", #transporters)
    end

    AFUtils.ClientDisplayWarningMessage(statusText, AFUtils.CriticalityLevels.Green)
end

-- Function to handle chat commands
local function HandleChatCommand(message)
    local messageContent = message:get():ToString()

    -- Split the message into words
    local words = {}
    for word in string.gmatch(messageContent, "%S+") do
        table.insert(words, string.lower(word))
    end

    -- Check if it's a transporter command
    if words[1] ~= "/tr" and words[1] ~= "/transporter" then
        return
    end

    -- Process the command
    if not words[2] or words[2] == "help" then
        ShowChatHelp()
    elseif words[2] == "status" then
        ShowChatStatus()
    elseif words[2] == "reset" then
        ExecuteInGameThread(function()
            ResetTracking()
        end)
    elseif words[2] == "range" and words[3] then
        local newRange = tonumber(words[3])
        if newRange and newRange > 0 then
            NEW_RADIUS = newRange
            ExecuteInGameThread(function()
                ResetTracking()

                AFUtils.ClientDisplayWarningMessage(
                    string.format("Range set to %.0f (default: 1600)", NEW_RADIUS),
                    AFUtils.CriticalityLevels.Green
                )
            end)
        else
            AFUtils.ClientDisplayWarningMessage(
                "Invalid range value - use a number > 0",
                AFUtils.CriticalityLevels.Red
            )
        end
    else
        ShowChatHelp()
    end
end

-- Register chat command hook
local function RegisterChatCommands()
    if chatCommandsHooked then return end

    ExecuteInGameThread(function()
        RegisterHook("/Game/Blueprints/Meta/Abiotic_PlayerController.Abiotic_PlayerController_C:Local_DisplayTextChatMessage",
            function(Context, Prefix, PrefixColor, Message, MessageColor)
                HandleChatCommand(Message)
            end)

        chatCommandsHooked = true
        LogInfo("Chat commands registered successfully")
    end)
end

-- Hook for when components are activated
RegisterHook("/Script/Engine.ActorComponent:ReceiveBeginPlay", function(self)
    -- Check if it's a BenchUpgrade_ItemTransporter_C
    if IsValid(self) then
        local className = tostring(self:GetClass():GetFName())

        if string.find(className, "BenchUpgrade_ItemTransporter_C") or
           string.find(className, "ItemTransporter") then
            -- Small delay to ensure complete initialization
            ExecuteWithDelay(200, function()
                ExecuteInGameThread(function()
                    ModifyTransporter(self)
                end)
            end)
        end
    end
end)

-- Alternative hook for actors (Crafting Benches)
RegisterHook("/Script/Engine.Actor:ReceiveBeginPlay", function(self)
    if IsValid(self) then
        local className = tostring(self:GetClass():GetFName())

        -- When a Crafting Bench is created, process transporters after delay
        if string.find(className, "Deployed_CraftingBench") or
           string.find(className, "CraftingBench") then
            ExecuteWithDelay(1000, function()
                ExecuteInGameThread(function()
                    ProcessExistingTransporters()
                end)
            end)
        end
    end
end)

-- Initialize mod when game loads with longer delay
ExecuteWithDelay(5000, function()
    ShowStartupMessage()
end)

-- Hook for player spawn - registers chat commands and shows startup message
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    LogInfo("Player spawned, registering chat commands")

    -- Register chat commands if not already done
    ExecuteWithDelay(1000, function()
        if not chatCommandsHooked then
            RegisterChatCommands()
        end
    end)

    -- Show startup message
    ExecuteWithDelay(2000, function()
        ShowStartupMessage()
    end)
end)

-- ============ CONSOLE COMMANDS ============

-- Command to reset
RegisterConsoleCommandHandler("transporter.reset", function()
    ExecuteInGameThread(function()
        ResetTracking()
    end)
    return false
end)

-- Command to change range
RegisterConsoleCommandHandler("transporter.range", function(fullCommand)
    local newRange = tonumber(fullCommand:match("transporter%.range%s+(%d+)"))
    if newRange and newRange > 0 then
        NEW_RADIUS = newRange
        ExecuteInGameThread(function()
            ResetTracking()

            LogInfo(string.format("New range set: %.0f units", NEW_RADIUS))

            -- Show confirmation to player
            AFUtils.ClientDisplayWarningMessage(
                string.format("Transporter range set to %.0f", NEW_RADIUS),
                AFUtils.CriticalityLevels.Green
            )
        end)
    else
        ExecuteInGameThread(function()
            local currentInfo = string.format("Current range: %.0f units (default: 1600)", NEW_RADIUS)
            LogInfo(currentInfo)
            LogInfo("Use: transporter.range <value> to change the range")

            -- Show current setting to player
            AFUtils.ClientDisplayWarningMessage(
                currentInfo,
                AFUtils.CriticalityLevels.Blue
            )
        end)
    end
    return false
end)

-- Command to show status
RegisterConsoleCommandHandler("transporter.status", function()
    ExecuteInGameThread(function()
        LogInfo("=== STATUS ===")
        LogInfo(string.format("  Configured range: %.0f units (default: 1600)", NEW_RADIUS))
        LogInfo(string.format("  Modified transporters: %d", totalModified))

        local statusMessage = string.format("Range: %.0f | Modified: %d", NEW_RADIUS, totalModified)

        local transporters = FindAllOf("BenchUpgrade_ItemTransporter_C")
        if transporters then
            LogInfo(string.format("  Transporters in world: %d", #transporters))
            statusMessage = statusMessage .. string.format(" | Total: %d", #transporters)

            -- Show current radius of first transporter as example
            if IsValid(transporters[1]) and IsValid(transporters[1].Sphere) then
                local currentRadius = transporters[1].Sphere.SphereRadius
                LogInfo(string.format("  Current radius (example): %.1f", currentRadius))
            end
        end

        -- Display status to player
        AFUtils.ClientDisplayWarningMessage(statusMessage, AFUtils.CriticalityLevels.Blue)
    end)

    return false
end)

-- Help command
RegisterConsoleCommandHandler("transporter.help", function()
    ExecuteInGameThread(function()
        LogInfo("=== COMMANDS ===")
        LogInfo("  Chat commands: /tr or /transporter")
        LogInfo("  Console commands:")
        LogInfo("    transporter.range <value> - Set new range")
        LogInfo("    transporter.reset - Reset modifications")
        LogInfo("    transporter.status - Show current info")
        LogInfo("    transporter.help - Show this help")

        -- Show help in warning message
        AFUtils.ClientDisplayWarningMessage(
            "Chat: /tr help | Console: transporter.help",
            AFUtils.CriticalityLevels.Blue
        )
    end)

    return false
end)

-- ============ INITIAL MESSAGE ============
LogInfo("Mod loaded successfully")
LogInfo(string.format("Configured range: %.0f units (game default: 1600)", NEW_RADIUS))
LogInfo("Mod will auto-activate when game loads")
LogInfo("Chat commands: /tr help")
LogInfo("Console commands: transporter.help")
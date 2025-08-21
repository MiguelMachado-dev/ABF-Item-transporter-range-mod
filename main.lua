-- Mod to increase Item Transporter range in Abiotic Factor

print("[Item Transporter Range Mod] Starting...")

-- ============ CONFIGURATION ============
local NEW_RADIUS = 5000.0  -- Adjust this value (in Unreal units)
-- =======================================

-- Control variables
local modifiedTransporters = {}
local totalModified = 0
local isProcessing = false

-- Function that modifies a specific transporter
local function ModifyTransporter(transporter)
    if not transporter or not transporter:IsValid() then
        return false
    end

    local transporterId = tostring(transporter)

    -- Avoid modifying the same transporter multiple times
    if modifiedTransporters[transporterId] then
        return false
    end

    -- Access the Sphere component
    local sphere = transporter.Sphere

    if sphere and sphere:IsValid() then
        local oldRadius = sphere.SphereRadius

        if oldRadius and oldRadius > 0 and math.abs(oldRadius - NEW_RADIUS) > 1.0 then
            sphere.SphereRadius = NEW_RADIUS
            modifiedTransporters[transporterId] = true
            totalModified = totalModified + 1

            print(string.format("[Item Transporter Range Mod] Transporter #%d modified: %.1f -> %.1f",
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
            print(string.format("[Item Transporter Range Mod] %d new transporter(s) processed", count))
        end
    end

    isProcessing = false
end

-- Hook for when components are activated
RegisterHook("/Script/Engine.ActorComponent:ReceiveBeginPlay", function(self)
    -- Check if it's a BenchUpgrade_ItemTransporter_C
    if self:IsValid() then
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
    if self:IsValid() then
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

-- Process existing transporters when mod loads
-- Uses a longer delay to ensure the world is loaded
ExecuteWithDelay(3000, function()
    ExecuteInGameThread(function()
        print("[Item Transporter Range Mod] Processing existing transporters...")
        ProcessExistingTransporters()
    end)
end)

-- Function to reset and reprocess
local function ResetTracking()
    modifiedTransporters = {}
    totalModified = 0
    ProcessExistingTransporters()
    print("[Item Transporter Range Mod] Tracking reset and transporters reprocessed")
end

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
            print(string.format("[Item Transporter Range Mod] New range set: %.1f units", NEW_RADIUS))
        end)
    else
        print(string.format("[Item Transporter Range Mod] Current range: %.1f units", NEW_RADIUS))
        print("Use: transporter.range <value> to change the range")
    end
    return false
end)

-- Command to show status
RegisterConsoleCommandHandler("transporter.status", function()
    print(string.format("[Item Transporter Range Mod] === STATUS ==="))
    print(string.format("  Configured range: %.1f units", NEW_RADIUS))
    print(string.format("  Modified transporters: %d", totalModified))

    local transporters = FindAllOf("BenchUpgrade_ItemTransporter_C")
    if transporters then
        print(string.format("  Transporters in world: %d", #transporters))

        -- Show current radius of first transporter as example
        if transporters[1] and transporters[1]:IsValid() and transporters[1].Sphere then
            local currentRadius = transporters[1].Sphere.SphereRadius
            print(string.format("  Current radius (example): %.1f", currentRadius))
        end
    end

    return false
end)

-- Help command
RegisterConsoleCommandHandler("transporter.help", function()
    print("[Item Transporter Range Mod] === COMMANDS ===")
    print("  transporter.range <value> - Set new range (ex: transporter.range 10000)")
    print("  transporter.reset - Reset and reapply modifications")
    print("  transporter.status - Show current information")
    print("  transporter.help - Show this help")
    return false
end)

-- ============ INITIAL MESSAGE ============
print(string.format("[Item Transporter Range Mod] Loaded successfully!"))
print(string.format("[Item Transporter Range Mod] Configured range: %.1f units", NEW_RADIUS))
print("[Item Transporter Range Mod] Type 'transporter.help' in console to see commands")
--[[
    Author: Igromanru
    Created Date: 19.08.2024
    Description: Utility functions for the game Abiotic Factor
]]

local UEHelpers = require("UEHelpers")
require("AFUtils.AFBase")
require("AFUtils.Enums")
require("AFUtils.StaticClasses")
require("AFUtils.DefaultObjects")
require("AFUtils.ObjectsGetter")

local IsDedicatedServerCache = nil
---Returns true if code is running on a Dedicated Server<br>
---The function uses a cache!
---@param UpdateCache boolean?
---@return boolean
function AFUtils.IsDedicatedServer(UpdateCache)
    if IsDedicatedServerCache == nil or UpdateCache then
        local commandLine = string.lower(GetKismetSystemLibrary():GetCommandLine():ToString())
        if commandLine ~= "" and string.find(commandLine, "-newconsole", 1, true) then
            IsDedicatedServerCache = true
        else
            IsDedicatedServerCache = IsDedicatedServer()
        end
    end
    
    return IsDedicatedServerCache
end

---Gets Control Rotation
---@return FRotator
function AFUtils.GetControlRotation()
    local playerController = AFUtils.GetMyPlayerController()
    if IsValid(playerController) then
        return RotatorToUserdata(playerController.ControlRotation)
    end
    return FRotator()
end

---Force client control rotation
---@param Rotation FRotator
---@return boolean Success # false if no valid PlayerController
function AFUtils.SetControlRotation(Rotation)
    local playerController = AFUtils.GetMyPlayerController()
    if IsValid(playerController) then
        playerController:SetControlRotation(Rotation)
        return true
    end
    return false
end

---@param PlayerCharacter AAbiotic_PlayerCharacter_C? # In nil, using MyPlayer
---@return boolean
function AFUtils.IsHoldingKeypadHacker(PlayerCharacter)
    PlayerCharacter = PlayerCharacter or AFUtils.GetMyPlayer()
    return IsValid(PlayerCharacter) and IsValid(PlayerCharacter.ItemInHand_BP) and PlayerCharacter.ItemInHand_BP:IsA(AFUtils.GetClassItem_Gear_KeypadHacker_C())
end

---Prints a colored message to local player's chat (only visible to the player)
---@param Message string Message that should be shown in chat
---@param Prefix string?
---@param Color FLinearColor? If nil, defaults to white
function AFUtils.DisplayTextChatMessage(Message, Prefix, Color)
    if not Message then return end

    local myPlayerController = AFUtils.GetMyPlayerController()
    if IsValid(myPlayerController) then
        Prefix = Prefix or ""
        if not Color or type(Color) ~= 'table' then
            Color = { -- White
                R = 1.0,
                G = 1.0,
                B = 1.0,
                A = 1.0
            }
        end
        myPlayerController:Local_DisplayTextChatMessage(Prefix, Color, Message, Color)
    end
end

---Executes DisplayTextChatMessage with [ModName] as prefix
---@param Message string
function AFUtils.ModDisplayTextChatMessage(Message)
    local prefix = GetModInfoPrefix()
    AFUtils.DisplayTextChatMessage(Message, prefix)
end

---AAbiotic_PlayerCharacter_C function, that shows colored text at the top of the screen and can play a warning beep
---@param Message string
---@param CriticalityLevel ECriticalityLevels|CriticalityLevels|integer|nil Color of the message is based on the CriticalityLevel
---@param WarningBeep boolean|nil Should a warning sound be played
function AFUtils.ClientDisplayWarningMessage(Message, CriticalityLevel, WarningBeep)
    if not Message then return end
    -- Default values
    CriticalityLevel = CriticalityLevel or AFUtils.CriticalityLevels.Green
    WarningBeep = WarningBeep or false

    local myPlayer = AFUtils.GetMyPlayer()
    if IsValid(myPlayer) then
        -- LogDebug("ClientDisplayWarningMessage: Message: "..Message.." CriticalityLevel: "..CriticalityLevel.." WarningBeep: "..tostring(WarningBeep))
        local fText = FText(Message)
        if fText then
            myPlayer:Client_DisplayWarningMessage(fText, CriticalityLevel, WarningBeep)
        else
            LogError('ClientDisplayWarningMessage: Couldn\'t get a FText out of "'..Message..'"')
        end
    end
end

---UW_PlayerHUD_Main_C function, same as ClientDisplayWarningMessage but has no option for a warning beep
---@param Message string
---@param CriticalityLevel ECriticalityLevels|CriticalityLevels|integer|nil Color of the message is based on the CriticalityLevel
function AFUtils.DisplayWarningMessage(Message, CriticalityLevel)
    if not Message then return end
    -- Default values
    CriticalityLevel = CriticalityLevel or AFUtils.CriticalityLevels.Green

    local playerHud = AFUtils.GetMyPlayerHUD()
    if playerHud then
        LogDebug("DisplayWarningMessage: Message: "..Message.." CriticalityLevel: "..CriticalityLevel)
        
        local fText = FText(Message)
        if fText then
            playerHud:DisplayWarningMessage(fText, CriticalityLevel)
        else
            LogError('ClientDisplayWarningMessage: Couldn\'t get a FText out of "'..Message..'"')
        end
    end
end

---Get current combined health of all limbs
---@param playerCharacter AAbiotic_Character_ParentBP_C
function AFUtils.GetCurrentCombinedHealth(playerCharacter)
    if IsNotValid(playerCharacter) then return 0 end
    return playerCharacter.CurrentHealth_Head + playerCharacter.CurrentHealth_Torso
            + playerCharacter.CurrentHealth_LeftArm + playerCharacter.CurrentHealth_RightArm
            + playerCharacter.CurrentHealth_LeftLeg + playerCharacter.CurrentHealth_RightLeg
end

---Checks if the LiquidType is energy
---@param LiquidType number|LiquidType|E_LiquidType
function AFUtils.IsEnergyLiquidType(LiquidType)
    return LiquidType == AFUtils.LiquidType.Energy or LiquidType == AFUtils.LiquidType.LaserEnergy
end

---Checks if the LiquidType is energy in FAbiotic_InventoryItemStruct
---@param ItemSlotStruct FAbiotic_InventoryItemSlotStruct
function AFUtils.IsEnergyLiquidTypeInItemSlotStruct(ItemSlotStruct)
    if not ItemSlotStruct or not ItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313 then
        return false
    end
    return AFUtils.IsEnergyLiquidType(ItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109)
end

---Checks if LiquidType exists in AllowedLiquids array of FAbiotic_LiquidStruct
---@param LiquidStruct FAbiotic_LiquidStruct
---@param LiquidType number|LiquidType|E_LiquidType
function AFUtils.IsAllowedLiquidType(LiquidStruct, LiquidType)
    if LiquidStruct and LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3 and LiquidType then
        for i = 1, #LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3, 1 do
            local allowedLiquid = LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3[i]
            if allowedLiquid == LiquidType then
               return true 
            end
        end
    end
    return false
end

---Checks if LiquidType is allowed in FAbiotic_InventoryItemStruct
---@param ItemStruct FAbiotic_InventoryItemStruct
---@param LiquidType LiquidType|number
function AFUtils.IsAllowedLiquidTypeInItemStruct(ItemStruct, LiquidType)
    if ItemStruct and ItemStruct.LiquidData_110_4D07F09C483C1E65B39024ABC7032FA0 and LiquidType then
        return AFUtils.IsAllowedLiquidType(ItemStruct.LiquidData_110_4D07F09C483C1E65B39024ABC7032FA0, LiquidType)
    end
    return false
end

---Checks if AllowedLiquidType array has only energy types in it
---@param LiquidStruct FAbiotic_LiquidStruct
---@return boolean # Returns true if only energy liquid types are allowed
function AFUtils.IsOnlyEnergyLiquidTypeAllowed(LiquidStruct)
    local result = false
    if LiquidStruct and LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3 then
        for i = 1, #LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3, 1 do
            local allowedLiquid = LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3[i]
            result = AFUtils.IsEnergyLiquidType(allowedLiquid)
            if not result then
               break
            end
        end
    end
    return result
end

---Checks if AllowedLiquidType array has only energy types in it
---@param ItemStruct FAbiotic_InventoryItemStruct
---@return boolean # Returns true if only energy liquid types are allowed
function AFUtils.IsOnlyEnergyLiquidTypeAllowedInItemStruct(ItemStruct)
    if ItemStruct and ItemStruct.LiquidData_110_4D07F09C483C1E65B39024ABC7032FA0 then
        return AFUtils.IsOnlyEnergyLiquidTypeAllowed(ItemStruct.LiquidData_110_4D07F09C483C1E65B39024ABC7032FA0)
    end
    return true
end

---
---@param LiquidStruct FAbiotic_LiquidStruct
---@return LiquidType|number #Returns first allowed LiquidType or None (0)
function AFUtils.GetFirstAllowedLiquidType(LiquidStruct)
    if LiquidStruct and LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3 then
        if #LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3 > 0 then
            return LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3[1]
        end
    end
    return AFUtils.LiquidType.None
end

---
---@param ItemStruct FAbiotic_InventoryItemStruct
---@return LiquidType|number #Returns first allowed LiquidType or None (0)
function AFUtils.GetFirstAllowedLiquidTypeInItemStruct(ItemStruct)
    if ItemStruct then
        return AFUtils.GetFirstAllowedLiquidType(ItemStruct.LiquidData_110_4D07F09C483C1E65B39024ABC7032FA0)
    end
    return AFUtils.LiquidType.None
end

---
---@param LiquidStruct FAbiotic_LiquidStruct
---@return LiquidType|number #Returns last allowed LiquidType or None (0)
function AFUtils.GetLastAllowedLiquidType(LiquidStruct)
    if LiquidStruct and LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3 then
        local arrayCount = #LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3
        if arrayCount > 0 then
            return LiquidStruct.AllowedLiquids_7_1DF3EB8C43F49DA3A1E4A2AF908148D3[arrayCount]
        end
    end
    return AFUtils.LiquidType.None
end

---
---@param ItemStruct FAbiotic_InventoryItemStruct
---@return LiquidType|E_LiquidType|number #Returns last allowed LiquidType or None (0)
function AFUtils.GetLastAllowedLiquidTypeInItemStruct(ItemStruct)
    if ItemStruct then
        return AFUtils.GetLastAllowedLiquidType(ItemStruct.LiquidData_110_4D07F09C483C1E65B39024ABC7032FA0)
    end
    return AFUtils.LiquidType.None
end

---Sets CurrentItemDurability in ChangeableData to MaxItemDurability
---@param ItemSlotStruct FAbiotic_InventoryItemSlotStruct
---@return boolean Success
function AFUtils.FillItemSlotStructDurability(ItemSlotStruct)
   if not ItemSlotStruct or not ItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313 then return false end 

   local maxItemDurability = ItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.MaxItemDurability_6_F5D5F0D64D4D6050CCCDE4869785012B
   if maxItemDurability > 0 then
        ItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentItemDurability_4_24B4D0E64E496B43FB8D3CA2B9D161C8 = maxItemDurability
        return true
   end
   return false
end

---@param Inventory UAbiotic_InventoryComponent_C
---@return boolean Success
function AFUtils.FillDurabilityOfAllItemsInInvetory(Inventory)
    if not Inventory or not Inventory.CurrentInventory or #Inventory.CurrentInventory <= 0 then return false end

    local result = true
    for i = 1, #Inventory.CurrentInventory do
        if not AFUtils.FillItemSlotStructDurability(Inventory.CurrentInventory[i]) then
            result = false
        end
    end
    return result
end

---Uses Request_RepairItem to repair all items, which also works on servers as guest
---@param PlayerCharacter AAbiotic_PlayerCharacter_C
---@param Inventory UAbiotic_InventoryComponent_C
---@return boolean Success
function AFUtils.RepairAllItemsInInvetory(PlayerCharacter, Inventory)
    if not PlayerCharacter or not Inventory or not PlayerCharacter:IsValid() or not Inventory.CurrentInventory or #Inventory.CurrentInventory < 1 then return false end

    for i = 1, #Inventory.CurrentInventory do
        local itemSlotStruct = Inventory.CurrentInventory[i]
        if itemSlotStruct.ItemDataTable_18_BF1052F141F66A976F4844AB2B13062B.RowName:GetComparisonIndex() > 0 then
            local currentItemDurability = itemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentItemDurability_4_24B4D0E64E496B43FB8D3CA2B9D161C8
            local maxItemDurability = itemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.MaxItemDurability_6_F5D5F0D64D4D6050CCCDE4869785012B
            if maxItemDurability > 0 and currentItemDurability < maxItemDurability then
                PlayerCharacter:Request_RepairItem(Inventory, i - 1, maxItemDurability - currentItemDurability, false)
            end
        end
    end
    return true
end

---Fill liquid level of FAbiotic_InventoryChangeableDataStruct with best allowed liquid type to maximum
---@param ChangeableData FAbiotic_InventoryChangeableDataStruct Target
---@param ItemStruct FAbiotic_InventoryItemStruct Source, LiquidData will be used to pull infomation
---@return boolean Success
function AFUtils.FillChangeableDataEnergy(ChangeableData, ItemStruct)
    if not ChangeableData or not ItemStruct then return false end

    local liquidData = ItemStruct.LiquidData_110_4D07F09C483C1E65B39024ABC7032FA0
    if liquidData.MaxLiquid_16_80D4968B4CACEDD3D4018E87DA67E8B4 > 0 and AFUtils.IsOnlyEnergyLiquidTypeAllowedInItemStruct(ItemStruct) then
        local currentLiquidType = ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109
        if not AFUtils.IsEnergyLiquidType(currentLiquidType) then
            currentLiquidType = AFUtils.GetLastAllowedLiquidTypeInItemStruct(ItemStruct)
        end
        ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109 = currentLiquidType
        ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A = liquidData.MaxLiquid_16_80D4968B4CACEDD3D4018E87DA67E8B4
        return true
    end

    return false
end

---Fill liquid level of FAbiotic_InventoryItemSlotStruct with best allowed liquid type to maximum
---@param ItemSlotStruct FAbiotic_InventoryItemSlotStruct Target, ChangeableData of the struct will be written
---@param ItemStruct FAbiotic_InventoryItemStruct Source, LiquidData will be used to pull infomation
---@return boolean Success
function AFUtils.FillItemSlotStructEnergy(ItemSlotStruct, ItemStruct)
    if not ItemSlotStruct or not ItemStruct then return false end
    return AFUtils.FillChangeableDataEnergy(ItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313, ItemStruct)
end

---Fill liquid level of FAbiotic_InventoryItemSlotStruct with best allowed liquid type to maximum
---@param ItemSlotStruct FAbiotic_InventoryItemSlotStruct Target, ChangeableData of the struct will be written
---@param Item AAbiotic_Item_ParentBP_C Source and Target, ItemData.LiquidData will be used to pull infomation for ItemSlotStruct and Item.ChangeableData
---@return boolean Success
function AFUtils.FillItemSlotStructEnergyFromItem(ItemSlotStruct, Item)
    if not ItemSlotStruct or not Item or not Item:IsValid() then return false end
    return AFUtils.FillItemSlotStructEnergy(ItemSlotStruct, Item.ItemData) and AFUtils.FillChangeableDataEnergy(Item.ChangeableData, Item.ItemData)
end

---Fills current, in hotbar selected item with it's maximum allowed energy. If the item is drained, refills it with best allowed energy.<br>
---@param playerCharacter AAbiotic_PlayerCharacter_C Must be a valid object
---@return boolean Success
function AFUtils.FillHeldItemWithEnergy(playerCharacter)
    if not playerCharacter then return false end
    
    local itemSlotStruct = AFUtils.GetSelectedHotbarInventoryItemSlot(playerCharacter)
    if itemSlotStruct then
        return AFUtils.FillItemSlotStructEnergyFromItem(itemSlotStruct, playerCharacter.ItemInHand_BP)
    end
    return false
end

---@param playerCharacter AAbiotic_PlayerCharacter_C Must be a valid object
function AFUtils.FillAllEquippedItemsWithEnergy(playerCharacter)
    if IsNotValid(playerCharacter) or not playerCharacter.CharacterEquipSlotInventory:IsValid() or #playerCharacter.CharacterEquipSlotInventory.CurrentInventory < 12 then
        return
    end
    local itemSlotStructs = playerCharacter.CharacterEquipSlotInventory.CurrentInventory
    local chestArmorSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.ChestArmor]
    local headArmorSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.HeadArmor]
    local legArmorSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.LegArmor]
    local backpackSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.Backpack]
    local armArmorSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.ArmArmor]
    local suitSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.FullBodySuit]
    local headlampSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.Headlamp]
    local trinketSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.Trinket]
    local shieldSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.OffHandShield]
    local wristwatchSlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.Wristwatch]
    local trinket2SlotStruct = itemSlotStructs[AFUtils.GearInventoryIndex.Trinket2]

    AFUtils.FillItemSlotStructEnergyFromItem(chestArmorSlotStruct, playerCharacter.Gear_TorsoBP)
    AFUtils.FillItemSlotStructEnergyFromItem(headArmorSlotStruct, playerCharacter.Gear_TorsoBP)
    AFUtils.FillItemSlotStructEnergyFromItem(legArmorSlotStruct, playerCharacter.Gear_LegsBP)
    AFUtils.FillItemSlotStructEnergyFromItem(backpackSlotStruct, playerCharacter.Gear_BackpackBP)
    AFUtils.FillItemSlotStructEnergyFromItem(armArmorSlotStruct, playerCharacter.Gear_ArmsBP)
    AFUtils.FillItemSlotStructEnergyFromItem(suitSlotStruct, playerCharacter.Gear_SuitBP)
    AFUtils.FillItemSlotStructEnergyFromItem(headlampSlotStruct, playerCharacter.Gear_HeadlampBP)
    AFUtils.FillItemSlotStructEnergyFromItem(trinketSlotStruct, playerCharacter.Gear_TrinketBP)
    AFUtils.FillItemSlotStructEnergyFromItem(shieldSlotStruct, playerCharacter.Gear_ShieldBP)
    AFUtils.FillItemSlotStructEnergyFromItem(wristwatchSlotStruct, playerCharacter.Gear_WristwatchBP)
    AFUtils.FillItemSlotStructEnergyFromItem(trinket2SlotStruct, playerCharacter.Gear_Trinket2_BP)
end

---Fill CurrentAmmoInMagazine of FAbiotic_InventoryChangeableDataStruct with maximum ammo
---@param ChangeableData FAbiotic_InventoryChangeableDataStruct Target
---@param ItemStruct FAbiotic_InventoryItemStruct Source, WeaponStruct will be used to pull infomation
---@return boolean Filled # Returns true if CurrentAmmoInMagazine was modified, otherwise false
function AFUtils.FillChangeableDataAmmo(ChangeableData, ItemStruct)
    if not ChangeableData or not ItemStruct then return false end

    local weaponData = ItemStruct.WeaponData_61_3C29CF6C4A7F9DD435F9318FEE4B033D
    if weaponData.RequireAmmo_85_8BB1C1954D2A83BB1994549DDEEBA306 then
        local currentAmmoInMagazine = ChangeableData.CurrentAmmoInMagazine_12_D68C190F4B2FA78A4B1D57835B95C53D
        local magazineSize = weaponData.MagazineSize_57_E890A3944240BB8D07EF0B9251F1FBD4
        if currentAmmoInMagazine < magazineSize then
            ChangeableData.CurrentAmmoInMagazine_12_D68C190F4B2FA78A4B1D57835B95C53D = magazineSize
            return true
        end
    end

    return false
end

---Fill CurrentAmmoInMagazine of FAbiotic_InventoryChangeableDataStruct with maximum ammo
---@param ItemSlotStruct FAbiotic_InventoryItemSlotStruct Target, ChangeableData of the struct will be written
---@param ItemStruct FAbiotic_InventoryItemStruct Source, LiquidData will be used to pull infomation
---@return boolean Filled # Returns true if CurrentAmmoInMagazine was modified, otherwise false
function AFUtils.FillItemSlotStructAmmo(ItemSlotStruct, ItemStruct)
    if not ItemSlotStruct or not ItemStruct then return false end
    return AFUtils.FillChangeableDataAmmo(ItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313, ItemStruct)
end

---Fill CurrentAmmoInMagazine of FAbiotic_InventoryChangeableDataStruct with maximum ammo
---@param ItemSlotStruct FAbiotic_InventoryItemSlotStruct Target, ChangeableData of the struct will be written
---@param Item AAbiotic_Item_ParentBP_C Source and Target, ItemData.WeaponData will be used to pull infomation for ItemSlotStruct and Item.ChangeableData
---@return boolean Filled # Returns true if CurrentAmmoInMagazine was modified, otherwise false
function AFUtils.FillItemSlotStructAmmoFromItem(ItemSlotStruct, Item)
    if not ItemSlotStruct or not Item or not Item:IsValid() then return false end
    return AFUtils.FillItemSlotStructAmmo(ItemSlotStruct, Item.ItemData) and AFUtils.FillChangeableDataAmmo(Item.ChangeableData, Item.ItemData)
end

---@param playerCharacter AAbiotic_PlayerCharacter_C Must be a valid object
---@param weapon AAbiotic_Weapon_ParentBP_C? Must be a valid object
---@return boolean Filled # Returns true if ammo was modified, otherwise false
function AFUtils.FillHeldWeaponWithAmmo(playerCharacter, weapon)
    if IsNotValid(playerCharacter) or not playerCharacter.ItemInHand_BP then return false end

    weapon = weapon or AFUtils.GetCurrentWeapon(playerCharacter)
    if not weapon or not weapon:IsValid() then return false end

    local weaponData = weapon.ItemData.WeaponData_61_3C29CF6C4A7F9DD435F9318FEE4B033D
    if not weaponData.RequireAmmo_85_8BB1C1954D2A83BB1994549DDEEBA306 then return false end

    local itemSlotStruct, inventory, slotIndex = AFUtils.GetSelectedHotbarInventoryItemSlot(playerCharacter)
    if itemSlotStruct and inventory and slotIndex then
        if AFUtils.FillItemSlotStructAmmoFromItem(itemSlotStruct, weapon) then
            weapon.CurrentRoundsInMagazine = itemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentAmmoInMagazine_12_D68C190F4B2FA78A4B1D57835B95C53D
            return true
        end
    end
    return false
end

---Converts FWeatherEventRowHandle to userdata
---@param EventRow FWeatherEventRowHandle
---@return FWeatherEventRowHandle # It creates userdata that represent FWeatherEventRowHandle
function AFUtils.ConvertWeatherEventRowHandleToUserdata(EventRow)
    return { 
        RowName = EventRow.RowName,
        DataTablePath = EventRow.DataTablePath
     }
end

---Triggers a weather event
---@param EventName string|WeatherEvents
---@return boolean Success
function AFUtils.TriggerWeatherEvent(EventName)
    if type(EventName) ~= "string" then return false end

    local weatherEventHandleFunctionLibrary = AFUtils.GetWeatherEventHandleFunctionLibrary()
    local myPlayerController = AFUtils.GetMyPlayerController()
    if IsValid(weatherEventHandleFunctionLibrary) and IsValid(myPlayerController) and myPlayerController.DayNightManager:IsValid() then
        ---@type table<LocalUnrealParam>
        local outRowHandles = {}
        weatherEventHandleFunctionLibrary:GetAllWeatherEventRowHandles(outRowHandles)
        for i = 1, #outRowHandles, 1 do
            local param = outRowHandles[i]
            LogDebug(i..": "..param:type())

            ---@type FWeatherEventRowHandle
            local rowHandle = param:get()
            local rowName = rowHandle.RowName:ToString()
            if rowName == EventName then
                myPlayerController.DayNightManager.RequiredDaysBetweenWeather = 0
                myPlayerController.DayNightManager.Weather_RequestByPlayer.RowName = rowHandle.RowName
                LogDebug("Weather_RequestByPlayer.RowName: "..myPlayerController.DayNightManager.Weather_RequestByPlayer.RowName:ToString())
                -- myPlayerController.DayNightManager:TriggerWeatherEvent(AFUtils.ConvertWeatherEventRowHandleToUserdata(rowHandle))
                -- LogDebug("TriggerWeatherEvent: Triggering event: " .. EventName)
                return true
            end
        end
    end
    return false
end

---Set next weather event
---@param EventName string|WeatherEvents
---@return boolean Success
function AFUtils.SetNextWeatherEvent(EventName)
    if type(EventName) ~= "string" then return false end

    local myPlayerController = AFUtils.GetMyPlayerController()
    if IsValid(myPlayerController) and myPlayerController.DayNightManager:IsValid() then
        local RowName = FName(EventName, EFindName.FNAME_Find)
        myPlayerController.DayNightManager.RequiredDaysBetweenWeather = 0
        myPlayerController.DayNightManager.Weather_RequestByPlayer.RowName = RowName
        LogDebug("SetNextWeatherEvent: Weather_RequestByPlayer.RowName: "..myPlayerController.DayNightManager.Weather_RequestByPlayer.RowName:ToString())
        return true
    end
    return false
end

---@param playerCharacter AAbiotic_PlayerCharacter_C
function AFUtils.HealAllLimbs(playerCharacter)
    playerCharacter.CurrentHealth_Head = 70.0
    playerCharacter.CurrentHealth_Torso = 100.0
    playerCharacter.CurrentHealth_LeftArm= 100.0
    playerCharacter.CurrentHealth_RightArm = 100.0
    playerCharacter.CurrentHealth_LeftLeg = 100.0
    playerCharacter.CurrentHealth_RightLeg = 100.0
    for i = 1, 6, 1 do
        local outSuccess = { Success = false }
        playerCharacter:Server_HealRandomLimb(100.0, outSuccess)
    end
end

---Teleports a player to a close location of another
---@param Player AAbiotic_PlayerCharacter_C # Player that should be teleported
---@param TargetPlayer AAbiotic_PlayerCharacter_C # Target to teleport to
---@param Behind boolean? # If the player should be teleported behind or infront of the target
---@param DistanceToActor integer? # Default 100 aka. 1m
---@return boolean Sucess
function AFUtils.TeleportPlayerToPlayer(Player, TargetPlayer, Behind, DistanceToActor)
    if IsNotValid(Player) or IsNotValid(TargetPlayer) then return false end

    Behind = Behind or false
    DistanceToActor = DistanceToActor or 100 -- 1m
    
    local direction = TargetPlayer:GetActorForwardVector()
    local tagetLocation = TargetPlayer:K2_GetActorLocation()
    tagetLocation.Z = tagetLocation.Z + 20
    local targetRotation = TargetPlayer:K2_GetActorRotation()
    if Behind then
        DistanceToActor = DistanceToActor * -1
    else
        targetRotation.Yaw = targetRotation.Yaw * -1
    end
    local locationOffset = GetKismetMathLibrary():Multiply_VectorVector(direction, FVector(DistanceToActor, DistanceToActor, 0))
    tagetLocation = GetKismetMathLibrary():Add_VectorVector(tagetLocation, locationOffset)
    
    return Player:TeleportPlayer(tagetLocation, targetRotation, true)
end

---@param InventoryItemSlot UW_InventoryItemSlot_C
---@return UAbiotic_InventoryComponent_C? Inventory, integer SlotIndex
function AFUtils.GetInventoryAndSlotIndexFromItemSlot(InventoryItemSlot)
    if IsNotValid(InventoryItemSlot) then return nil, 0 end

    if InventoryItemSlot.ParentInventoryGrid:IsValid() and InventoryItemSlot.ParentInventoryGrid.MainInventoryComponent:IsValid() then
        return InventoryItemSlot.ParentInventoryGrid.MainInventoryComponent, InventoryItemSlot.SlotIndex
    end
    return nil, 0
end

---@param Inventory UAbiotic_InventoryComponent_C
---@param SlotIndex integer
---@param StackToAdd integer
---@return boolean Executed # Returns false if PlayerController doesn't exists or one of parameters is wrong
function AFUtils.AddToItemStack(Inventory, SlotIndex, StackToAdd)
    if IsNotValid(Inventory) or not SlotIndex or not StackToAdd then return false end

    local myPlayerController = AFUtils.GetMyPlayerController()
    if IsValid(myPlayerController) then
        myPlayerController:Server_AddToItemStack(Inventory, SlotIndex, StackToAdd)
        return true
    end

    return false
end

---@param TargetItemSlot FAbiotic_InventoryItemSlotStruct
---@param DataTableRowName FName
---@param ItemsCount integer
---@return boolean
function AFUtils.SetItemSlot(TargetItemSlot, DataTableRowName, ItemsCount)
    if not TargetItemSlot or not TargetItemSlot.ItemDataTable_18_BF1052F141F66A976F4844AB2B13062B then return false end

    TargetItemSlot.ItemDataTable_18_BF1052F141F66A976F4844AB2B13062B.RowName = DataTableRowName
    TargetItemSlot.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentItemDurability_4_24B4D0E64E496B43FB8D3CA2B9D161C8 = 100
    TargetItemSlot.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.MaxItemDurability_6_F5D5F0D64D4D6050CCCDE4869785012B = 100
    TargetItemSlot.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentStack_9_D443B69044D640B0989FD8A629801A49 = ItemsCount

    return true
end

---@param DayNightManager ADayNightManager_C?
---@return boolean Success
function AFUtils.CalculateAndSetDaytime(DayNightManager)
    DayNightManager = DayNightManager or AFUtils.GetDayNightManager()
    if IsNotValid(DayNightManager) then return false end

    local currentTime = DayNightManager.CurrentTimeInSeconds
    local isDay = currentTime < HoursToSeconds(DayNightManager.NightfallStartHour) and currentTime >= HoursToSeconds(DayNightManager.MorningStartHour)
    if DayNightManager.IsNight == isDay then
        DayNightManager.IsNight = not isDay
        DayNightManager:OnRep_IsNight()
    end
    return true
end 

---Set in game time
---@param Hours integer? # Default: 0
---@param Minutes integer? # Default: 0
function AFUtils.SetGameTime(Hours, Minutes)
    Hours = Hours or 0.0
    Minutes = Minutes or 0.0

    local dayNightManager = AFUtils.GetDayNightManager()
    if IsValid(dayNightManager) then
        local targetTime = HoursToSeconds(Hours) + MinutesToSeconds(Minutes) + 10
        dayNightManager.CurrentTimeInSeconds = targetTime
        dayNightManager:OnRep_CurrentTimeInSeconds()
        if dayNightManager.CurrentTimeInSeconds == targetTime then
            return AFUtils.CalculateAndSetDaytime(dayNightManager)
        end
    end
    return false
end

---Add hours and minutes to current game time
---@param Hours integer
---@param Minutes integer? # Default: 0
function AFUtils.AddGameTime(Hours, Minutes)
    Minutes = Minutes or 0.0

    local dayNightManager = AFUtils.GetDayNightManager()
    if IsValid(dayNightManager) then
        local targetTime = dayNightManager.CurrentTimeInSeconds + HoursToSeconds(Hours) + MinutesToSeconds(Minutes)
        dayNightManager.CurrentTimeInSeconds = targetTime
        dayNightManager:OnRep_CurrentTimeInSeconds()
        if dayNightManager.CurrentTimeInSeconds == targetTime then
            return AFUtils.CalculateAndSetDaytime(dayNightManager)
        end
    end
    return false
end

---@param LeyakContainment ADeployed_LeyakContainment_C
---@return boolean Success
function AFUtils.TrapLeyak(LeyakContainment)
    if IsNotValid(LeyakContainment) or LeyakContainment.DeployableDestroyed or LeyakContainment.ContainsLeyak then return false end

    local gameState = AFUtils.GetSurvivalGameState()
    if IsValid(gameState) then
        local assetId = LeyakContainment.SpawnedAssetID:ToString()
        LogDebug("TrapLeyak: SpawnedAssetID:", assetId)
        LeyakContainment:ServerUpdateStabilityLevel(LeyakContainment.MaxStability)
        LeyakContainment:TrapLeyak(0.0)
        gameState['Set Leyak Containment ID'](assetId)
        LogDebug("TrapLeyak: ActiveLeyakContainmentID:", gameState.ActiveLeyakContainmentID:ToString())
        LogDebug("TrapLeyak: ContainsLeyak:", LeyakContainment.ContainsLeyak)
        return gameState.ActiveLeyakContainmentID:ToString() == assetId
    end
    return false
end

---@param LeyakContainment ADeployed_LeyakContainment_C
---@return boolean Success
function AFUtils.FreeLeyak(LeyakContainment)
    if IsNotValid(LeyakContainment) or LeyakContainment.DeployableDestroyed or not LeyakContainment.ContainsLeyak then return false end

    local gameState = AFUtils.GetSurvivalGameState()
    if IsValid(gameState) then
        LeyakContainment['Free Leyak']()
        gameState['Set Leyak Containment ID']("")
        return gameState.ActiveLeyakContainmentID:ToString() == ""
    end
    return false
end

return AFUtils

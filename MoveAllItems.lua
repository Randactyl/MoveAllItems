local guildButton = nil
local withdrawButton = nil
local depositButton = nil

local function MoveItem(toBagId, fromBagId, fromSlotIndex, stackCount)
    local result
    --if the transaction involves the guild bank, use this method
    if toBagId == BAG_GUILDBANK and DoesBagHaveSpaceFor(toBagId, fromBagId, fromSlotIndex) then
        TransferToGuildBank(fromBagId, fromSlotIndex)
    elseif fromBagId == BAG_GUILDBANK and DoesBagHaveSpaceFor(toBagId, fromBagId, fromSlotIndex) then
        TransferFromGuildBank(fromSlotIndex)
    --else use this method
    elseif DoesBagHaveSpaceFor(toBagId, fromBagId, fromSlotIndex) then
        ClearCursor()
        result = CallSecureProtected("PickupInventoryItem", fromBagId, fromSlotIndex, stackCount)
        if(result == true) then
            result = CallSecureProtected("PlaceInTransfer")
        end
        ClearCursor()
    end
end

local function MoveItems(toBagId, fromBagId, items, delayStep)
    --set initial delay
    local delay = delayStep
    --get number of items in the table (may not need -1, check that error again)
    local j = #items
    --for the number of items, from the biggest to smallest slotIndex
    for i = j, 1, -1 do
        --get info directly from the item, if it is actually an item (why wouldn't it be? dumb game/me...)
        local fromSlotIndex
        local stackCount
        if(items[i]) then
            fromSlotIndex = items[i].slotIndex
            stackCount = items[i].stackCount
        end
        --use callLater to queue item transactions every (delay) milliseconds
        zo_callLater(function() MoveItem(toBagId, fromBagId, fromSlotIndex, stackCount) end, delay)
        --increment the delay by the delayStep set in calling function
        delay = delay + delayStep
    end
end

local function WithdrawAllItems(button)
    local window = button:GetParent():GetNamedChild("Backpack")
    local delayStep = 300

    local fromBagId
    local toBagId = BAG_BACKPACK
    if button.guild == true then fromBagId = BAG_GUILDBANK
    else fromBagId = BAG_BANK end

    local tempitems = {}
    local items = {}
    for _,v in pairs(window.data) do
        tempitems[v.data.slotIndex] = v.data
    end
    for _,v in pairs(tempitems) do
        table.insert(items, v)
    end

    MoveItems(toBagId, fromBagId, items, delayStep)
end

local function DepositAllItems(button)
    local window = button:GetParent():GetNamedChild("Backpack")
    local delayStep = 300

    local toBagId
    local fromBagId = BAG_BACKPACK
    if button.guild == true then toBagId = BAG_GUILDBANK
    else toBagId = BAG_BANK end

    local tempitems = {}
    local items = {}
    for _,v in pairs(window.data) do
        tempitems[v.data.slotIndex] = v.data
    end
    for _,v in pairs(tempitems) do
        table.insert(items, v)
    end

    MoveItems(toBagId, fromBagId, items, delayStep)
end

local function ButtonClickHandler(button)
    --figure out which button was pressed
    if button.deposit == true then DepositAllItems(button)
    else WithdrawAllItems(button) end
end

local function ToggleButton(eventCode)
    --set deposit button guild flag for the button handler
    if(eventCode == EVENT_OPEN_GUILD_BANK) then depositButton.guild = true end
    if(eventCode == EVENT_CLOSE_GUILD_BANK) then depositButton.guild = false end
    --show/hide buttons
    if(eventCode == EVENT_OPEN_BANK or eventCode == EVENT_OPEN_GUILD_BANK) then
        guildButton:SetHidden(false)
        withdrawButton:SetHidden(false)
        depositButton:SetHidden(false)
    else
        guildButton:SetHidden(true)
        withdrawButton:SetHidden(true)
        depositButton:SetHidden(true)
    end
end

local function AddGuildWithdrawButton()
    --build the guild withdraw button
    guildButton = WINDOW_MANAGER:CreateControl(ZO_GuildBank:GetName() .. "_GuildButton", ZO_GuildBank, CT_BUTTON)
    guildButton:SetText("Withdraw All")
    guildButton:SetFont("ZoFontGameBold")
    guildButton:SetDimensions(110, 20)
    guildButton:SetAnchor(TOPLEFT, ZO_GuildBankInfoBarAltFreeSlots, BOTTOMLEFT, -5, -5)
    guildButton:SetHandler("OnClicked", ButtonClickHandler)
    guildButton:SetMouseEnabled(true)
    guildButton:SetHidden(true)
    guildButton:SetNormalFontColor(0.77254903316498, 0.76078432798386, 0.61960786581039, 1)
    guildButton:SetPressedFontColor(0.68627452850342, 0.68627452850342, 0.68627452850342, 1)
    guildButton:SetClickSound(SOUNDS.DIALOG_ACCEPT)

    guildButton.deposit = false
    guildButton.guild = true
end

local function AddWithdrawButton()
    --build the bank withdraw button
    withdrawButton = WINDOW_MANAGER:CreateControl(ZO_PlayerBank:GetName() .. "_WithdrawButton", ZO_PlayerBank, CT_BUTTON)
    withdrawButton:SetText("Withdraw All")
    withdrawButton:SetFont("ZoFontGameBold")
    withdrawButton:SetDimensions(110, 20)
    withdrawButton:SetAnchor(TOPLEFT, ZO_PlayerBankInfoBarAltFreeSlots, BOTTOMLEFT, -5, -5)
    withdrawButton:SetHandler("OnClicked", ButtonClickHandler)
    withdrawButton:SetMouseEnabled(true)
    withdrawButton:SetHidden(true)
    withdrawButton:SetNormalFontColor(0.77254903316498, 0.76078432798386, 0.61960786581039, 1)
    withdrawButton:SetPressedFontColor(0.68627452850342, 0.68627452850342, 0.68627452850342, 1)
    withdrawButton:SetClickSound(SOUNDS.DIALOG_ACCEPT)

    withdrawButton.deposit = false
    withdrawButton.guild = false
end

local function AddDepositButton()
    --build the deposit button
    depositButton = WINDOW_MANAGER:CreateControl(ZO_PlayerInventory:GetName() .. "_DepositButton", ZO_PlayerInventory, CT_BUTTON)
    depositButton:SetText("Deposit All")
    depositButton:SetFont("ZoFontGameBold")
    depositButton:SetDimensions(90, 20)
    depositButton:SetAnchor(TOPLEFT, ZO_PlayerInventoryInfoBarAltFreeSlots, BOTTOMLEFT, -4, -5)
    depositButton:SetHandler("OnClicked", ButtonClickHandler)
    depositButton:SetMouseEnabled(true)
    depositButton:SetHidden(true)
    depositButton:SetNormalFontColor(0.77254903316498, 0.76078432798386, 0.61960786581039, 1)
    depositButton:SetPressedFontColor(0.68627452850342, 0.68627452850342, 0.68627452850342, 1)
    depositButton:SetClickSound(SOUNDS.DIALOG_ACCEPT)

    depositButton.deposit = true
    depositButton.guild = false
end

local function MoveAllItemsLoaded(eventCode, addonName)
    if(addonName ~= "MoveAllItems") then return end

    AddDepositButton()
    AddWithdrawButton()
    AddGuildWithdrawButton()

    EVENT_MANAGER:UnregisterForEvent("MoveAllItemsLoaded", EVENT_ADD_ON_LOADED)
    EVENT_MANAGER:RegisterForEvent("MoveAllItemsOnOpen", EVENT_OPEN_BANK, ToggleButton)
    EVENT_MANAGER:RegisterForEvent("MoveAllItemsOnClose", EVENT_CLOSE_BANK, ToggleButton)
    EVENT_MANAGER:RegisterForEvent("MoveAllItemsOnGuildOpen", EVENT_OPEN_GUILD_BANK, ToggleButton)
    EVENT_MANAGER:RegisterForEvent("MoveAllItemsOnGuildClose", EVENT_CLOSE_GUILD_BANK, ToggleButton)
end

EVENT_MANAGER:RegisterForEvent("MoveAllItemsoaded", EVENT_ADD_ON_LOADED, MoveAllItemsLoaded)
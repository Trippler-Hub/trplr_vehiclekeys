CreateThread(function()
   print("  ____              _                      _        ")
   print(" | __ )   _   _    | |       ___   _ __   (_) __  __")
   print(" |  _ \\  | | | |   | |     / _ \\  | '_ \\  | | \\\\/ /")
   print(" | |_) | | |_| |   | |___  | __/  | | | | | |  >  < ")
   print(" |____/   \\__, |   |_____| \\___|  |_| |_| |_| /_/\\\\ ")
   print("          |___/                                     ")
end)

if GetCurrentResourceName() ~= "trplr_vehiclekeys" then
    return print("^6Changing the resource's name wont't let the resource start, ^1" .. GetCurrentResourceName() .. "^0 > ^2 trplr_vehiclekeys ^7")
end

-----------------------
----   Variables   ----
-----------------------
local QBCore = exports[]:GetCoreObject()
local VehicleList = {}

-----------------------
----   Threads     ----
-----------------------

-----------------------
---- Server Events ----
-----------------------

-- Event to give keys. receiver can either be a single id, or a table of ids.
-- Must already have keys to the vehicle, trigger the event from the server, or pass forcegive paramter as true.
RegisterNetEvent('Config.System.trigger .. ':server:GiveVehicleKeys', function(receiver, plate)
    local giver = source

    if HasKeys(giver, plate) then
        TriggerClientEvent('QBCore:Notify', giver, Lang:t('notify.vgkeys'), 'success')
        if type(receiver) == 'table' then
            for _, r in ipairs(receiver) do
                GiveKeys(receiver[r], plate)
            end
        else
            GiveKeys(receiver, plate)
        end
    else
        TriggerClientEvent('QBCore:Notify', giver, Lang:t('notify.ydhk'), 'error')
    end
end)

RegisterNetEvent('Config.System.trigger .. ':server:AcquireVehicleKeys', function(plate)
    local src = source
    GiveKeys(src, plate)
end)

RegisterNetEvent('Config.System.trigger .. ':server:breakLockpick', function(itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not (itemName == 'lockpick' or itemName == 'advancedlockpick') then return end
    if exports['qb-inventory']:RemoveItem(source, itemName, 1, false, 'Config.System.trigger .. ':server:breakLockpick') then
        TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove')
    end
end)

RegisterNetEvent('Config.System.trigger .. ':server:setVehLockState', function(vehNetId, state)
    if Config.System.OutSideMinigame.isWindowUnBreakable then
        SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(vehNetId), state)
    else
        SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(vehNetId), 7)
    end
end)

QBCore.Functions.CreateCallback('Config.System.trigger .. ':server:GetVehicleKeys', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    local citizenid = Player.PlayerData.citizenid
    local keysList = {}
    for plate, citizenids in pairs(VehicleList) do
        if citizenids[citizenid] then
            keysList[plate] = true
        end
    end
    if Player.PlayerData.metadata["vehicleKeys"] and Config.PersistentKeys then
        for plate in pairs(Player.PlayerData.metadata["vehicleKeys"]) do
            keysList[plate] = true
        end
    end
    cb(keysList)
end)

QBCore.Functions.CreateCallback('Config.System.trigger .. ':server:checkPlayerOwned', function(_, cb, plate)
    local playerOwned = false
    if VehicleList[plate] then
        playerOwned = true
    end
    cb(playerOwned)
end)

-----------------------
----   Functions   ----
-----------------------

function GiveKeys(id, plate)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    if not plate then
        if GetVehiclePedIsIn(GetPlayerPed(id), false) ~= 0 then
            plate = QBCore.Shared.Trim(GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(id), false)))
        else
            return
        end
    end

    if not VehicleList[plate] then VehicleList[plate] = {} end
    VehicleList[plate][citizenid] = true

    local oldKeys = Player.PlayerData.metadata["vehicleKeys"] or {}
    oldKeys[plate] = true
    Player.Functions.SetMetaData("vehicleKeys", oldKeys)

    TriggerClientEvent('QBCore:Notify', id, Lang:t('notify.vgetkeys'))
    TriggerClientEvent('Config.System.trigger .. ':client:AddKeys', id, plate)
end

exports('GiveKeys', GiveKeys)

function RemoveKeys(id, plate)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    if VehicleList[plate] and VehicleList[plate][citizenid] then
        VehicleList[plate][citizenid] = nil
    end

    local oldKeys = Player.PlayerData.metadata["vehicleKeys"] or {}
    oldKeys[plate] = nil
    Player.Functions.SetMetaData("vehicleKeys", oldKeys)

    TriggerClientEvent('Config.System.trigger .. ':client:RemoveKeys', id, plate)
end

exports('RemoveKeys', RemoveKeys)

function HasKeys(id, plate)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return false end
    local citizenid = Player.PlayerData.citizenid

    if VehicleList[plate] and VehicleList[plate][citizenid] then
        return true
    end

    if Player.PlayerData.metadata["vehicleKeys"] and Config.PersistentKeys and Player.PlayerData.metadata["vehicleKeys"][plate] then
        return true
    end

    return false
end

exports('HasKeys', HasKeys)

QBCore.Commands.Add('givekeys', Lang:t('addcom.givekeys'), { { name = Lang:t('addcom.givekeys_id'), help = Lang:t('addcom.givekeys_id_help') } }, false, function(source, args)
    local src = source
    TriggerClientEvent('Config.System.trigger .. ':client:GiveKeys', src, tonumber(args[1]))
end)

QBCore.Commands.Add('addkeys', Lang:t('addcom.addkeys'), { { name = Lang:t('addcom.addkeys_id'), help = Lang:t('addcom.addkeys_id_help') }, { name = Lang:t('addcom.addkeys_plate'), help = Lang:t('addcom.addkeys_plate_help') } }, true, function(source, args)
    local src = source
    if not args[1] or not args[2] then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.fpid'))
        return
    end
    GiveKeys(tonumber(args[1]), args[2])
end, 'admin')

QBCore.Commands.Add('removekeys', Lang:t('addcom.rkeys'), { { name = Lang:t('addcom.rkeys_id'), help = Lang:t('addcom.rkeys_id_help') }, { name = Lang:t('addcom.rkeys_plate'), help = Lang:t('addcom.rkeys_plate_help') } }, true, function(source, args)
    local src = source
    if not args[1] or not args[2] then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.fpid'))
        return
    end
    RemoveKeys(tonumber(args[1]), args[2])
end, 'admin')

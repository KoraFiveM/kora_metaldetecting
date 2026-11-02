local active = false
local detectorProp
local detectionText
local detectionTextId
local currentCooldownMs = 55000

local function notify(message, type_)
    Kora.notify.send({ title = 'Metal Detecting', message = message, type = type_ or 'info' })
end

local function setDetectionText(groundIsValid)
    if not Config.Detection.showText then return end
    local text = groundIsValid and 'Suitable ground — the detector is searching.' or 'This ground is unsuitable for metal detecting.'
    if text == detectionText then return end
    detectionText = text
    if not detectionTextId then
        detectionTextId = Kora.textui.show(text, { position = 'bottom-center', icon = 'Search' })
    else
        Kora.textui.update(detectionTextId, text, { position = 'bottom-center', icon = 'Search' })
    end
end

local function hideDetectionText()
    if detectionTextId then
        Kora.textui.hide(detectionTextId)
        detectionTextId = nil
        detectionText = nil
    end
end

local function groundHash()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local shape = StartShapeTestCapsule(coords.x, coords.y, coords.z + 4.0, coords.x, coords.y, coords.z - 2.0, 1.0, 1, ped, 7)
    local _, _, _, _, material = GetShapeTestResultEx(shape)
    return material
end

local function allowedGround(ground)
    for _, allowed in ipairs(Config.Detection.allowedGrounds) do
        if allowed == ground then return true end
    end
    return false
end

local function cleanupDetector()
    local ped = PlayerPedId()
    if detectorProp then
        DetachEntity(detectorProp, true, true)
        Kora.entities.remove(detectorProp)
        detectorProp = nil
    end
    Kora.anim.stop(ped)
    ClearPedTasks(ped)
    hideDetectionText()
end

local function stopDetecting(tellServer)
    if not active and not detectorProp then return end
    active = false
    Kora.progressbar.cancel()
    Kora.minigames.cancel()
    cleanupDetector()
    if tellServer then Kora.events.trigger('qbmetaldetecting:server:stoppedDetecting') end
end

local function resumeDetectingLoop()
    if not active then return end
    local ped = PlayerPedId()
    if detectorProp and DoesEntityExist(detectorProp) then SetEntityVisible(detectorProp, true, false) end
    Kora.anim.play(ped, 'anim@heists@narcotics@trash', 'walk', { flag = 51 })
end

local function playFind(ground)
    local result = Kora.minigames.play('skillbar', Config.Detection.minigame)
    if not result or not result.success then return end

    local ped = PlayerPedId()
    Kora.anim.stop(ped)
    if detectorProp and DoesEntityExist(detectorProp) then SetEntityVisible(detectorProp, false, false) end

    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_GARDENER_PLANT', 0, true)
    Wait(Config.Detection.digDuration / 2)

    if not active then return end

    ClearPedTasks(ped)
    Kora.events.trigger('qbmetaldetecting:server:completedFind', ground)
    Wait(Config.Detection.digDuration)
    resumeDetectingLoop()
end

local function beginDetecting(cooldown)
    if active then
        notify('You are already using a metal detector.', 'error')
        return
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        notify('You cannot use a metal detector in a vehicle.', 'error')
        Kora.events.trigger('qbmetaldetecting:server:stoppedDetecting')
        return
    end
    local ped = PlayerPedId()
    if IsEntityDead(ped) then
        Kora.events.trigger('qbmetaldetecting:server:stoppedDetecting')
        return
    end
    detectorProp = Kora.entities.create(Config.Detection.detectorModel, GetEntityCoords(ped), {})
    AttachEntityToEntity(detectorProp, ped, GetPedBoneIndex(ped, 57005), 0.8, 0.06, 0.1, 5.0, -99.0, 56.0, true, true, false, true, 1, true)
    if not detectorProp then
        notify('The metal detector could not be equipped.', 'error')
        Kora.events.trigger('qbmetaldetecting:server:stoppedDetecting')
        return
    end
    Kora.anim.play(ped, 'anim@heists@narcotics@trash', 'walk', { flag = 51 })
    active = true
    currentCooldownMs = math.floor((tonumber(cooldown) or 55) * 1000)

    CreateThread(function()
        while active do
            local time = currentCooldownMs
            local ground

            repeat
                ground = groundHash()
                local valid = allowedGround(ground)
                setDetectionText(valid)
                if valid then time = time - 1000 end
                Wait(1000)
            until not active or time <= 0

            if not active then return end

            notify('You may have found something.', 'success')
            Wait(800)
            playFind(ground)
        end
    end)
end

-- Death / vehicle interrupts are edge-driven instead of being re-polled by the
-- detection loop every second.
Kora.cache.onChange('vehicle', function(vehicle)
    if not active or not vehicle then return end
    notify('Metal detecting stopped in a vehicle.', 'error')
    stopDetecting(true)
end)

Kora.cache.onChange('isDead', function(dead)
    if not active or not dead then return end
    stopDetecting(true)
end)

local function washClump(washIndex)
    if not exports.kora_inventory:HasItem(Config.Items.clump) then
        notify('You need a clump to wash.', 'error')
        return
    end

    local result = Kora.minigames.play('skillbar', Config.Detection.minigame)
    if not result or not result.success then return end

    if not Kora.progressbar.start({
        label = 'Washing clump...',
        duration = 5000,
        canCancel = true,
        disable = { combat = true, car = true },
        anim  = { dict = 'mp_arresting', clip = 'a_uncuff', flag = 49 },
    }) then
        return
    end

    Kora.events.trigger('qbmetaldetecting:server:washedClump', washIndex)
end

local function addBlip(location)
    if not location.blip or location.blip.enabled == false then return end
    Kora.blips.create(location.coords, {
        sprite = location.blip.sprite,
        color = location.blip.color,
        scale = location.blip.scale,
        category = 'Other',
        name = location.blip.name,
    })
end

local function initLocations()
    for index, wash in ipairs(Config.Selling.wash) do
        addBlip(wash)
        Kora.interact.addCircleZone(('md-metal-wash-%d'):format(index), wash.coords, 1.5, {
            options = {
                { label = 'Wash metal clump', icon = 'Waves', action = function() washClump(index) end },
            },
        })
    end
end

Kora.events.onPush('qbmetaldetecting:client:startedDetecting', beginDetecting)
Kora.events.onPush('qbmetaldetecting:client:stoppedDetecting', function() stopDetecting(false) end)
Kora.events.onPush('qbmetaldetecting:client:foundLoot', function(item)
    local definition = exports.kora_core:getShared('items', item)
    notify(('You found %s.'):format(definition and definition.label or item), 'success')
end)

CreateThread(initLocations)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then stopDetecting(false) end
end)

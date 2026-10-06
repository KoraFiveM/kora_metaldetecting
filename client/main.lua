local active = false
local detecting = true
local detectorProp
local detectionText
local detectionTextId
local currentCooldownMs = 55000
local shopsReady = false

local function notify(message, type_)
    QB.notify.send({ title = 'Metal Detecting', message = message, type = type_ or 'info' })
end

local function setDetectionText(groundIsValid)
    if not Config.Detection.showText then return end
    local text = groundIsValid and 'Suitable ground — the detector is searching.' or 'This ground is unsuitable for metal detecting.'
    if text == detectionText then return end
    detectionText = text
    if not detectionTextId then
        detectionTextId = QB.textui.show(text, { position = 'bottom-center', icon = 'Search' })
    else
        QB.textui.update(detectionTextId, text, { position = 'bottom-center', icon = 'Search' })
    end
end

local function hideDetectionText()
    if detectionTextId then
        QB.textui.hide(detectionTextId)
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
        QB.entities.remove(detectorProp)
        detectorProp = nil
    end
    QB.anim.stop(ped)
    ClearPedTasks(ped)
    hideDetectionText()
end

local function stopDetecting(tellServer)
    if not active and not detectorProp then return end
    active = false
    QB.progressbar.cancel()
    QB.minigames.cancel()
    cleanupDetector()
    if tellServer then QB.events.trigger('qbmetaldetecting:server:stoppedDetecting') end
end

local function resumeDetectingLoop()
    if not active then return end
    local ped = PlayerPedId()
    if detectorProp and DoesEntityExist(detectorProp) then SetEntityVisible(detectorProp, true, false) end
    QB.anim.play(ped, 'anim@heists@narcotics@trash', 'walk', { flag = 51 })
end

local function playFind(ground)
    local startedAt = GetGameTimer()
    local result = QB.minigames.play('skillbar', Config.Detection.minigame)
    if not result or not result.success then
        return
    end

    local ped = PlayerPedId()
    QB.anim.stop(ped)
    if detectorProp and DoesEntityExist(detectorProp) then SetEntityVisible(detectorProp, false, false) end

    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_GARDENER_PLANT', 0, true)
    Wait(Config.Detection.digDuration / 2)

    if not active then
        return
    end

    ClearPedTasks(ped)
    QB.events.trigger('qbmetaldetecting:server:completedFind', ground)
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
        QB.events.trigger('qbmetaldetecting:server:stoppedDetecting')
        return
    end
    local ped = PlayerPedId()
    detectorProp = QB.entities.create(Config.Detection.detectorModel, GetEntityCoords(ped), {})
    AttachEntityToEntity(detectorProp, ped, GetPedBoneIndex(ped, 57005), 0.8, 0.06, 0.1, 5.0, -99.0, 56.0, true, true, false, true, 1, true)
    if not detectorProp then
        notify('The metal detector could not be equipped.', 'error')
        QB.events.trigger('qbmetaldetecting:server:stoppedDetecting')
        return
    end
    QB.anim.play(ped, 'anim@heists@narcotics@trash', 'walk', { flag = 51 })
    active = true
    detecting = true
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
            until IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) or not active or time <= 0

            if not active then
                return -- session was stopped elsewhere while we were scanning
            end

            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
                if IsPedInAnyVehicle(ped, false) then notify('Metal detecting stopped in a vehicle.', 'error') end
                stopDetecting(true)
                return
            end

            notify('You may have found something.', 'success')
            Wait(800)
            detecting = false
            playFind(ground)
            detecting = true
        end
    end)
end

local function washClump(washIndex)
    if not exports.qbinventory:HasItem(Config.Items.clump) then
        notify('You need a clump to wash.', 'error')
        return
    end

    local result = QB.minigames.play('skillbar', Config.Detection.minigame)
    if not result or not result.success then return end

    if not QB.progressbar.start({
        label = 'Washing clump...',
        duration = 5000,
        canCancel = true,
        disable = { combat = true, car = true },
        anim  = { dict = 'mp_arresting', clip = 'a_uncuff', flag = 49 },
    }) then
        return
    end

    QB.events.trigger('qbmetaldetecting:server:washedClump', washIndex)
end

local function addBlip(location)
    if not location.blip or location.blip.enabled == false then return end
    QB.blips.create(location.coords, {
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
        QB.interact.addCircleZone(('md-metal-wash-%d'):format(index), wash.coords, 1.5, {
            options = {
                { label = 'Wash metal clump', icon = 'Waves', action = function() washClump(index) end },
            },
        })
    end
end

QB.events.onPush('qbmetaldetecting:client:startedDetecting', beginDetecting)
QB.events.onPush('qbmetaldetecting:client:stoppedDetecting', function() stopDetecting(false) end)
QB.events.onPush('qbmetaldetecting:client:foundLoot', function(item)
    local definition = exports.qbcore:getShared('items', item)
    notify(('You found %s.'):format(definition and definition.label or item), 'success')
end)

CreateThread(initLocations)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then stopDetecting(false) end
end)

local detecting = false
local searching = false
local detectorProp
local detectionText
local detectionTextId
local nextAttemptAt = 0
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
        QB.anim.detachProp(detectorProp)
        detectorProp = nil
    end
    QB.anim.stop(ped)
    ClearPedTasks(ped)
    hideDetectionText()
end

local function stopDetecting(tellServer)
    if not detecting and not detectorProp then return end
    detecting = false
    searching = false
    QB.progressbar.cancel()
    QB.minigames.cancel()
    cleanupDetector()
    if tellServer then QB.events.trigger('md-metaldetecting:server:stoppedDetecting') end
end

local function playFind(ground)
    local started = QB.callback.trigger('md-metaldetecting:server:beginFind', ground)
    if not started or type(started) ~= 'table' then
        nextAttemptAt = GetGameTimer() + 2000
        return
    end

    local result = QB.minigames.play('skillbar', Config.Detection.minigame, started.authorization)
    if not result or not result.success then
        QB.events.trigger('md-metaldetecting:server:cancelledFind', started.authorization)
        nextAttemptAt = GetGameTimer() + 1500
        return
    end

    SetEntityVisible(detectorProp, false, false)
    local completed = QB.progressbar.start({
        label = 'Digging...',
        duration = Config.Detection.digDuration,
        canCancel = true,
        disable = { combat = true, car = true },
        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49,
        },
    })
    if detectorProp and DoesEntityExist(detectorProp) then SetEntityVisible(detectorProp, true, false) end
    if not completed then
        QB.events.trigger('md-metaldetecting:server:cancelledFind', started.authorization)
        nextAttemptAt = GetGameTimer() + 1500
        return
    end

    QB.events.trigger('md-metaldetecting:server:completedFind', result.proof, started.authorization)
    nextAttemptAt = GetGameTimer() + 1000
end

local function beginDetecting(cooldown)
    if detecting then
        notify('You are already using a metal detector.', 'error')
        return
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        notify('You cannot use a metal detector in a vehicle.', 'error')
        QB.events.trigger('md-metaldetecting:server:stoppedDetecting')
        return
    end

    local ped = PlayerPedId()
    detectorProp = QB.anim.attachProp(ped, Config.Detection.detectorModel, 57005,
        vector3(0.8, 0.06, 0.1), vector3(5.0, -99.0, 56.0), { fixedRot = true })
    if not detectorProp then
        notify('The metal detector could not be equipped.', 'error')
        QB.events.trigger('md-metaldetecting:server:stoppedDetecting')
        return
    end

    QB.anim.play(ped, 'amb@world_human_gardener_plant@male@base', 'base', { flag = 49 })
    detecting = true
    nextAttemptAt = GetGameTimer() + math.floor((tonumber(cooldown) or 55) * 1000)

    CreateThread(function()
        while detecting do
            local ground = groundHash()
            local valid = allowedGround(ground)
            setDetectionText(valid)
            if valid and not searching and GetGameTimer() >= nextAttemptAt then
                searching = true
                notify('You may have found something.', 'success')
                Wait(800)
                playFind(ground)
                searching = false
            end
            Wait(500)
        end
    end)

    CreateThread(function()
        while detecting do
            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
                if IsPedInAnyVehicle(ped, false) then notify('Metal detecting stopped in a vehicle.', 'error') end
                stopDetecting(true)
                return
            end
            Wait(250)
        end
    end)
end

local function openBuyMenu(shopIndex)
    local choice = QB.nui.openMenu({
        { id = 'cash', label = ('Buy with cash — $%d'):format(Config.Selling.detectorPrice), icon = 'Banknote' },
        { id = 'bank', label = ('Buy with bank — $%d'):format(Config.Selling.detectorPrice), icon = 'CreditCard' },
    }, 'Metal Detector Shop')
    if choice and choice.selectedId then QB.events.trigger('md-metaldetecting:server:purchasedDetector', shopIndex, choice.selectedId) end
end

local function openSellMenu(shopIndex)
    local loot = QB.callback.trigger('md-metaldetecting:server:sellingOptionsRequested', shopIndex)
    if type(loot) ~= 'table' then return end
    local items = { { id = 'all', label = 'Sell everything', icon = 'ShoppingBag' } }
    for item, price in pairs(loot) do
        if exports.qbcore:getItemCount(item) > 0 then
            local definition = exports.qbcore:getShared('items', item)
            items[#items + 1] = {
                id = item,
                label = definition and definition.label or item,
                description = ('$%d each'):format(price),
                icon = 'Coins',
            }
        end
    end
    local choice = QB.nui.openMenu(items, 'Sell Detected Loot')
    if choice and choice.selectedId then QB.events.trigger('md-metaldetecting:server:soldLoot', shopIndex, choice.selectedId) end
end

local function washClump(washIndex)
    local authorization = QB.callback.trigger('md-metaldetecting:server:beginWash', washIndex)
    if not authorization then
        notify('You need a clump to wash.', 'error')
        return
    end
    local result = QB.minigames.play('skillbar', Config.Detection.minigame, authorization)
    if not result or not result.success then
        QB.events.trigger('md-metaldetecting:server:cancelledWash', authorization)
        return
    end
    if not QB.progressbar.start({
        label = 'Washing clump...',
        duration = 10000,
        canCancel = true,
        disable = { combat = true, car = true },
        scenario = { name = 'WORLD_HUMAN_BUM_WASH', playEnter = true },
    }) then
        QB.events.trigger('md-metaldetecting:server:cancelledWash', authorization)
        return
    end
    QB.events.trigger('md-metaldetecting:server:washedClump', result.proof, authorization)
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
    if shopsReady then return end
    shopsReady = true

    for index, shop in ipairs(Config.Selling.shop) do
        addBlip(shop)
        local ped = QB.entities.create(shop.ped, shop.coords, { preset = 'static' })
        if ped then TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true) end
        QB.interact.addCircleZone(('md-metal-shop-%d'):format(index), shop.coords, 2.5, {
            options = {
                { label = ('Buy metal detector — $%d'):format(Config.Selling.detectorPrice), icon = 'ShoppingCart', action = function() openBuyMenu(index) end },
                { label = 'Sell detected loot', icon = 'Coins', action = function() openSellMenu(index) end },
            },
        })
    end

    for index, wash in ipairs(Config.Selling.wash) do
        addBlip(wash)
        QB.interact.addCircleZone(('md-metal-wash-%d'):format(index), wash.coords, 1.5, {
            options = {
                { label = 'Wash metal clump', icon = 'Waves', action = function() washClump(index) end },
            },
        })
    end
end

QB.events.onPush('md-metaldetecting:client:startedDetecting', beginDetecting)
QB.events.onPush('md-metaldetecting:client:stoppedDetecting', function() stopDetecting(false) end)
QB.events.onPush('md-metaldetecting:client:foundLoot', function(item)
    local definition = exports.qbcore:getShared('items', item)
    notify(('You found %s.'):format(definition and definition.label or item), 'success')
end)

CreateThread(initLocations)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then stopDetecting(false) end
end)

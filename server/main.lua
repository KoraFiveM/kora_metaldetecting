local Core = exports.kora_core
local activeDetectors = {}
local cooldowns = {}
local delayBySource = {}
local pendingFinds = {}
local pendingWashes = {}

local function isAllowedGround(ground)
    if type(ground) ~= 'number' then return false end
    for _, allowed in ipairs(Config.Detection.allowedGrounds) do
        if allowed == ground then return true end
    end
    return false
end

local function playerHas(src, item, amount)
    return (Core:getItemCount(src, item) or 0) >= (amount or 1)
end

local function near(src, coords, distance)
    return Kora.distance.player(src, coords, distance or Config.Detection.distance)
end

local function notify(src, message, type_)
    Kora.notify.send(src, { title = Kora.lang('Ui.title'), message = message, type = type_ or 'info' })
end

local function cooldownForLevel(level, maxLevel)
    level = tonumber(level) or 1
    maxLevel = tonumber(maxLevel) or 99
    local atLevel1, atMaxLevel = Config.Skill.cooldown.atLevel1, Config.Skill.cooldown.atMaxLevel
    if maxLevel <= 1 then return atLevel1 end

    level = math.max(1, math.min(maxLevel, level))
    local ratio = (level - 1) / (maxLevel - 1)
    local seconds = atLevel1 - (atLevel1 - atMaxLevel) * ratio
    return math.floor(seconds * 10 + 0.5) / 10
end

local function skillData(src)
    local data, err = exports.kora_skills:getRep(src, Config.Skill.name)
    if not data then
        print(('[kora_metaldetecting] could not read %s skill for %s: %s'):format(Config.Skill.name, src, tostring(err)))
        return nil
    end
    return data
end

local function clearPlayer(src, tellClient)
    activeDetectors[src] = nil
    cooldowns[src] = nil
    delayBySource[src] = nil
    pendingFinds[src] = nil
    pendingWashes[src] = nil
    if tellClient then Kora.events.push(src, 'kora_metaldetecting:client:stoppedDetecting') end
end

local function stopDetector(src)
    if not activeDetectors[src] then return end
    clearPlayer(src, true)
end

local function eligibleLoot(level, wash)
    local eligible = {}
    for _, entry in ipairs(Config.Loot.items) do
        if level >= entry.level and not (wash and entry.item == Config.Items.clump) then
            eligible[#eligible + 1] = entry
        end
    end
    return eligible
end

local function chooseLoot(level, wash)
    level = tonumber(level) or 1
    local eligible = eligibleLoot(level, wash)
    if #eligible == 0 then eligible = eligibleLoot(level, false) end
    if #eligible == 0 then return { item = Config.Items.clump, level = 1, xp = 1 } end
    return eligible[math.random(1, #eligible)]
end

Core:createUseable(Config.Items.detector, function(src)
    if activeDetectors[src] then
        stopDetector(src)
        return
    end
    if delayBySource[src] then return end

    local skill = skillData(src)
    if not skill then return end

    delayBySource[src] = true
    SetTimeout(2000, function() delayBySource[src] = nil end)
    activeDetectors[src] = true
    local startCooldown = cooldownForLevel(skill.level, skill.maxLevel)
    cooldowns[src] = GetGameTimer() + startCooldown * 1000
    Kora.events.push(src, 'kora_metaldetecting:client:startedDetecting', startCooldown)
end)

Kora.events.register('kora_metaldetecting:server:stoppedDetecting', function(src)
    stopDetector(src)
end, { rateLimit = { max = 3, window = 5000 } })

-- The client only renders the skillbar; the server is the one that decides
-- whether it was actually played and passed. Without this, a modified client
-- could skip the minigame entirely and spam completedFind for free loot/XP.
Kora.callback.register('kora_metaldetecting:server:beginFind', function(src, ground)
    if not activeDetectors[src] or not isAllowedGround(ground) then return false end
    if (cooldowns[src] or 0) > GetGameTimer() or not playerHas(src, Config.Items.detector) then return false end
    if not skillData(src) then return false end

    local authorization = Kora.minigames.authorizeSkillCheck(src, Config.Skill.name, 'skillbar', Config.Detection.minigame)
    pendingFinds[src] = authorization
    return authorization
end, { rateLimit = { max = 4, window = 10000 } })

Kora.events.register('kora_metaldetecting:server:completedFind', function(src, ground, proof, authorization)
    if not activeDetectors[src] or not isAllowedGround(ground) then return end
    if (cooldowns[src] or 0) > GetGameTimer() or not playerHas(src, Config.Items.detector) then return end
    if type(proof) ~= 'string' or not authorization or pendingFinds[src] ~= authorization
        or not Kora.minigames.consumeProof(src, proof, 'skillbar', authorization) then return end
    pendingFinds[src] = nil

    local before = skillData(src)
    if not before then return end

    local find = chooseLoot(before.level, false)
    local added, addErr = Core:addItem(src, find.item, 1, nil, nil, 'metal detecting')
    if not added then
        notify(src, addErr or Kora.lang('Notify.room_for_find'), 'error')
        return
    end

    local awarded, awardErr = exports.kora_skills:addRep(src, Config.Skill.name, find.xp)
    if not awarded then
        print(('[kora_metaldetecting] failed to award skill XP to %s: %s'):format(src, tostring(awardErr)))
    end

    local after = skillData(src) or before
    local nextCooldown = cooldownForLevel(after.level, after.maxLevel)
    cooldowns[src] = GetGameTimer() + nextCooldown * 1000
    if after.level > before.level then
        notify(src, Kora.lang('Notify.level_reached', after.level), 'success')
    end
    Kora.events.push(src, 'kora_metaldetecting:client:foundLoot', find.item, nextCooldown)
end, { rateLimit = { max = 4, window = 10000 } })

Kora.events.register('kora_metaldetecting:server:purchasedDetector', function(src, shopIndex, account)
    local shop = Config.Selling.shop[shopIndex]
    if not shop or (account ~= 'cash' and account ~= 'bank') then return end
    if not near(src, shop.coords, Config.Selling.interactionDistance) then return end
    if not Core:removeMoney(src, account, Config.Selling.detectorPrice, 'metal detector purchase') then
        notify(src, Kora.lang('Notify.cannot_afford_detector'), 'error')
        return
    end
    local added, addErr = Core:addItem(src, Config.Items.detector, 1, nil, nil, 'metal detector purchase')
    if not added then
        Core:addMoney(src, account, Config.Selling.detectorPrice, 'metal detector refund')
        notify(src, addErr or Kora.lang('Notify.room_for_detector'), 'error')
        return
    end
    notify(src, Kora.lang('Notify.detector_purchased'), 'success')
end, { rateLimit = { max = 2, window = 5000 } })

Kora.events.register('kora_metaldetecting:server:soldLoot', function(src, shopIndex, item, amount)
    local shop = Config.Selling.shop[shopIndex]
    local price = Config.Loot.sellValues[item]
    if not shop or not price or not near(src, shop.coords, Config.Selling.interactionDistance) then return end

    amount = math.floor(tonumber(amount) or 0)
    local owned = Core:getItemCount(src, item) or 0
    if amount < 1 or amount > owned then
        notify(src, Kora.lang('Notify.missing_items', amount, item), 'error')
        return
    end

    if not Core:removeItem(src, item, amount, nil, 'metal detecting sale') then return end

    local total = amount * price
    Core:addMoney(src, 'cash', total, 'metal detecting sale')
    notify(src, Kora.lang('Notify.sold_items', amount, total), 'success')
end, { rateLimit = { max = 8, window = 5000 } })

Kora.callback.register('kora_metaldetecting:server:beginWash', function(src, washIndex)
    local wash = Config.Selling.wash[washIndex]
    if not wash or not near(src, wash.coords, Config.Selling.interactionDistance) then return false end
    if not playerHas(src, Config.Items.clump) then return false end

    local authorization = Kora.minigames.authorizeSkillCheck(src, Config.Skill.name, 'skillbar', Config.Detection.minigame)
    pendingWashes[src] = authorization
    return authorization
end, { rateLimit = { max = 4, window = 10000 } })

Kora.events.register('kora_metaldetecting:server:washedClump', function(src, washIndex, proof, authorization)
    local wash = Config.Selling.wash[washIndex]
    if not wash or not near(src, wash.coords, Config.Selling.interactionDistance) then return end
    if not playerHas(src, Config.Items.clump) then
        notify(src, Kora.lang('Notify.no_clump_to_wash'), 'error')
        return
    end
    if type(proof) ~= 'string' or not authorization or pendingWashes[src] ~= authorization
        or not Kora.minigames.consumeProof(src, proof, 'skillbar', authorization) then return end
    pendingWashes[src] = nil
    if not Core:removeItem(src, Config.Items.clump, 1, nil, 'washed metal detecting clump') then return end

    local skill = skillData(src)
    local find = chooseLoot(skill and skill.level or 1, true)
    local added, addErr = Core:addItem(src, find.item, 1, nil, nil, 'washed metal detecting clump')
    if not added then
        Core:addItem(src, Config.Items.clump, 1, nil, nil, 'failed clump wash refund')
        notify(src, addErr or Kora.lang('Notify.room_for_find'), 'error')
        return
    end
    notify(src, Kora.lang('Notify.washed_clump', find.item), 'success')
end, { rateLimit = { max = 4, window = 10000 } })

-- Shop peds: one networked ped per shop. The definition lives in an entity
-- statebag (display data only), which OneSync replicates only to clients that
-- have the ped in scope. Prices and permissions never travel in it.
local SHOP_PED_KEY = 'kora_metaldetecting:shopPed'
local shopPeds = {}
local warnedShops = {}
local resourceStopping = false

local function spawnShopPed(index, shop)
    local model = joaat(shop.ped)
    local c = shop.coords
    local ped = CreatePed(4, model, c.x, c.y, c.z + (tonumber(shop.zOffset) or 1.0), c.w, true, false)
    local waited = 0
    while ped ~= 0 and not DoesEntityExist(ped) and waited < 2000 do Wait(50) waited = waited + 50 end
    if ped == 0 or not DoesEntityExist(ped) then
        if not warnedShops[index] then
            warnedShops[index] = true
            print(('[kora_metaldetecting] shop ped %d (%s) could not be created; check Config.Selling.shop[%d].ped'):format(index, tostring(shop.ped), index))
        end
        return
    end
    FreezeEntityPosition(ped, true)
    -- SetEntityInvincible / SetBlockingOfNonTemporaryEvents are client-only
    -- natives; client/shop.lua applies them when the ped comes into scope.
    shopPeds[index] = ped
    local target = type(shop.target) == 'table' and shop.target or {}
    Entity(ped).state:set(SHOP_PED_KEY, {
        shopIndex = index,
        model = shop.ped,
        outfit = shop.outfit,
        scenario = shop.scenario,
        spawnDistance = tonumber(shop.spawnDistance) or 50.0,
        target = { label = target.label or 'Open Metal Detector Shop', icon = target.icon or 'Store' },
    }, true)
end

CreateThread(function()
    while not resourceStopping do
        for index, shop in ipairs(Config.Selling.shop) do
            local ped = shopPeds[index]
            if (not ped or not DoesEntityExist(ped)) and not warnedShops[index] then
                spawnShopPed(index, shop)
            end
        end
        Wait(5000)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    resourceStopping = true
    for index, ped in pairs(shopPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
        shopPeds[index] = nil
    end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src) clearPlayer(src, false) end)
AddEventHandler('kora_core:server:playerDropped', function(src) clearPlayer(src, false) end)

local Core = exports.qbcore

local activeDetectors = {}
local pendingFinds = {}
local pendingWashes = {}
local cooldowns = {}
local delayBySource = {}

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
    return QB.distance.player(src, coords, distance or Config.Detection.distance)
end

local function notify(src, message, type_)
    QB.notify.send(src, { title = 'Metal Detecting', message = message, type = type_ or 'info' })
end

local function cooldownForLevel(level)
    level = tonumber(level) or 1
    if Config.Skill.cooldownByLevel[level] then return Config.Skill.cooldownByLevel[level] end
    local highestConfigured = 1
    for configuredLevel in pairs(Config.Skill.cooldownByLevel) do
        if configuredLevel > highestConfigured and configuredLevel <= level then highestConfigured = configuredLevel end
    end
    return math.max(Config.Skill.minimumCooldown, Config.Skill.cooldownByLevel[highestConfigured] or Config.Skill.minimumCooldown)
end

local function skillData(src)
    local data, err = exports.qbskills:getRep(src, Config.Skill.name)
    if not data then
        print(('[md-metaldetecting] could not read %s skill for %s: %s'):format(Config.Skill.name, src, tostring(err)))
        return nil
    end
    return data
end

local function clearPlayer(src, tellClient)
    activeDetectors[src] = nil
    pendingFinds[src] = nil
    pendingWashes[src] = nil
    cooldowns[src] = nil
    delayBySource[src] = nil
    if tellClient then QB.events.push(src, 'md-metaldetecting:client:stoppedDetecting') end
end

local function stopDetector(src)
    if not activeDetectors[src] then return end
    clearPlayer(src, true)
end

local function issueDetectionAuthorization(src, ground)
    if not activeDetectors[src] then return nil, 'detector is not active' end
    if not isAllowedGround(ground) then return nil, 'the ground is unsuitable' end
    if not playerHas(src, Config.Items.detector) then return nil, 'you no longer have a metal detector' end
    if pendingFinds[src] then return nil, 'a find is already being processed' end
    if (cooldowns[src] or 0) > GetGameTimer() then return nil, 'the detector is still charging' end

    local authorization = QB.minigames.authorizeSkillCheck(src, Config.Skill.name, 'skillbar', Config.Detection.minigame)
    pendingFinds[src] = { ground = ground, authorization = authorization }
    return { authorization = authorization }
end

local function chooseLoot(wash)
    local pool = Config.Loot.common
    if math.random(1, 100) <= (wash and math.floor(Config.Loot.rareChance / 2) or Config.Loot.rareChance) then
        pool = Config.Loot.rare
    end

    local item
    repeat
        item = pool[math.random(1, #pool)]
    until not wash or item ~= Config.Items.clump
    return item
end

for name, definition in pairs(Config.Items.definitions) do
    if not Core:getShared('items', name) then
        local item = {
            name = name,
            label = definition.label,
            weight = definition.weight,
            type = 'item',
            image = definition.image,
            unique = false,
            useable = name == Config.Items.detector,
            shouldClose = name == Config.Items.detector,
            description = definition.description,
        }
        local ok, err = Core:registerShared('items', name, item)
        assert(ok, ('failed to register item %s: %s'):format(name, tostring(err)))
    end
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
    cooldowns[src] = GetGameTimer() + cooldownForLevel(skill.level) * 1000
    QB.events.push(src, 'md-metaldetecting:client:startedDetecting', cooldownForLevel(skill.level))
end)

QB.callback.register('md-metaldetecting:server:beginFind', function(src, ground)
    return issueDetectionAuthorization(src, ground)
end, { rateLimit = { max = 4, window = 10000 } })

QB.events.register('md-metaldetecting:server:stoppedDetecting', function(src)
    stopDetector(src)
end, { rateLimit = { max = 3, window = 5000 } })

QB.events.register('md-metaldetecting:server:cancelledFind', function(src, authorization)
    local pending = pendingFinds[src]
    if pending and pending.authorization == authorization then pendingFinds[src] = nil end
end, { rateLimit = { max = 5, window = 10000 } })

QB.events.register('md-metaldetecting:server:completedFind', function(src, proof, authorization)
    local pending = pendingFinds[src]
    pendingFinds[src] = nil
    if not pending or pending.authorization ~= authorization then return end
    if not activeDetectors[src] or not isAllowedGround(pending.ground) then return end
    if (cooldowns[src] or 0) > GetGameTimer() or not playerHas(src, Config.Items.detector) then return end
    if not QB.minigames.consumeProof(src, proof, 'skillbar', authorization) then return end

    local item = chooseLoot(false)
    local added, addErr = Core:addItem(src, item, 1, nil, nil, 'metal detecting')
    if not added then
        notify(src, addErr or 'You do not have room for that find.', 'error')
        return
    end

    local before = skillData(src)
    local awarded, awardErr = exports.qbskills:addRep(src, Config.Skill.name, Config.Skill.xpPerFind, GetEntityCoords(GetPlayerPed(src)), Config.Detection.distance)
    if not awarded then
        print(('[md-metaldetecting] failed to award skill XP to %s: %s'):format(src, tostring(awardErr)))
    end

    local after = skillData(src)
    local cooldown = cooldownForLevel(after and after.level or before and before.level)
    cooldowns[src] = GetGameTimer() + cooldown * 1000
    if before and after and after.level > before.level then
        notify(src, ('Metal detecting level %d reached.'):format(after.level), 'success')
    end
    QB.events.push(src, 'md-metaldetecting:client:foundLoot', item)
end, { rateLimit = { max = 4, window = 10000 } })

QB.callback.register('md-metaldetecting:server:sellingOptionsRequested', function(src, shopIndex)
    local shop = Config.Selling.shop[shopIndex]
    if not shop or not near(src, shop.coords, Config.Selling.interactionDistance) then return false end
    return Config.Loot.sellValues
end, { rateLimit = { max = 5, window = 10000 } })

QB.events.register('md-metaldetecting:server:purchasedDetector', function(src, shopIndex, account)
    local shop = Config.Selling.shop[shopIndex]
    if not shop or (account ~= 'cash' and account ~= 'bank') then return end
    if not near(src, shop.coords, Config.Selling.interactionDistance) then return end
    if not Core:removeMoney(src, account, Config.Selling.detectorPrice, 'metal detector purchase') then
        notify(src, 'You cannot afford a metal detector.', 'error')
        return
    end
    local added, addErr = Core:addItem(src, Config.Items.detector, 1, nil, nil, 'metal detector purchase')
    if not added then
        Core:addMoney(src, account, Config.Selling.detectorPrice, 'metal detector refund')
        notify(src, addErr or 'You do not have room for a metal detector.', 'error')
        return
    end
    notify(src, 'Metal detector purchased.', 'success')
end, { rateLimit = { max = 2, window = 5000 } })

QB.events.register('md-metaldetecting:server:soldLoot', function(src, shopIndex, item)
    local shop = Config.Selling.shop[shopIndex]
    local price = Config.Loot.sellValues[item]
    if not shop or (item ~= 'all' and not price) or not near(src, shop.coords, Config.Selling.interactionDistance) then return end

    local amount = item == 'all' and nil or Core:getItemCount(src, item)
    if item ~= 'all' and (not amount or amount < 1) then
        notify(src, ('You do not have any %s.'):format(item), 'error')
        return
    end

    local total, sold = 0, 0
    if item == 'all' then
        for sellItem, sellPrice in pairs(Config.Loot.sellValues) do
            local count = Core:getItemCount(src, sellItem)
            if count > 0 and Core:removeItem(src, sellItem, count, nil, 'metal detecting sale') then
                sold = sold + count
                total = total + count * sellPrice
            end
        end
    elseif Core:removeItem(src, item, amount, nil, 'metal detecting sale') then
        sold = amount
        total = amount * price
    end

    if sold > 0 then
        Core:addMoney(src, 'cash', total, 'metal detecting sale')
        notify(src, ('Sold %d item(s) for $%d.'):format(sold, total), 'success')
    end
end, { rateLimit = { max = 4, window = 5000 } })

local function issueWashAuthorization(src, washIndex)
    local wash = Config.Selling.wash[washIndex]
    if not wash or not near(src, wash.coords, Config.Selling.interactionDistance) then return nil end
    if not playerHas(src, Config.Items.clump) or pendingWashes[src] then return nil end
    local authorization = QB.minigames.authorizeSkillCheck(src, Config.Skill.name, 'skillbar', Config.Detection.minigame)
    pendingWashes[src] = { washIndex = washIndex, authorization = authorization }
    return authorization
end

QB.callback.register('md-metaldetecting:server:beginWash', issueWashAuthorization, { rateLimit = { max = 4, window = 10000 } })

QB.events.register('md-metaldetecting:server:cancelledWash', function(src, authorization)
    local pending = pendingWashes[src]
    if pending and pending.authorization == authorization then pendingWashes[src] = nil end
end, { rateLimit = { max = 5, window = 10000 } })

QB.events.register('md-metaldetecting:server:washedClump', function(src, proof, authorization)
    local pending = pendingWashes[src]
    pendingWashes[src] = nil
    if not pending or pending.authorization ~= authorization then return end
    local wash = Config.Selling.wash[pending.washIndex]
    if not wash or not near(src, wash.coords, Config.Selling.interactionDistance) then return end
    if not playerHas(src, Config.Items.clump) then
        notify(src, 'You do not have a clump to wash.', 'error')
        return
    end
    if not QB.minigames.consumeProof(src, proof, 'skillbar', authorization) then return end
    if not Core:removeItem(src, Config.Items.clump, 1, nil, 'washed metal detecting clump') then return end

    local item = chooseLoot(true)
    local added, addErr = Core:addItem(src, item, 1, nil, nil, 'washed metal detecting clump')
    if not added then
        Core:addItem(src, Config.Items.clump, 1, nil, nil, 'failed clump wash refund')
        notify(src, addErr or 'You do not have room for that find.', 'error')
        return
    end
    notify(src, ('You washed the clump and found %s.'):format(item), 'success')
end, { rateLimit = { max = 4, window = 10000 } })

QB.commands.add('metaldetectLevel', 'Show your metal detecting skill', nil, false, function(src)
    local skill = skillData(src)
    if skill then notify(src, ('Metal detecting level %d — %d XP.'):format(skill.level, skill.xp), 'info') end
end)

QB.commands.add('resetMetaldetector', 'Stop metal detecting', nil, false, function(src)
    stopDetector(src)
    notify(src, 'Metal detecting stopped.', 'success')
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src) clearPlayer(src, false) end)
AddEventHandler('qbcore:server:playerDropped', function(src) clearPlayer(src, false) end)

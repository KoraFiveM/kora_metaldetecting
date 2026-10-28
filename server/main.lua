local Core = exports.kora_core
local activeDetectors = {}
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
        print(('[qbmetaldetecting] could not read %s skill for %s: %s'):format(Config.Skill.name, src, tostring(err)))
        return nil
    end
    return data
end

local function clearPlayer(src, tellClient)
    activeDetectors[src] = nil
    cooldowns[src] = nil
    delayBySource[src] = nil
    if tellClient then QB.events.push(src, 'qbmetaldetecting:client:stoppedDetecting') end
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
    QB.events.push(src, 'qbmetaldetecting:client:startedDetecting', startCooldown)
end)

QB.events.register('qbmetaldetecting:server:stoppedDetecting', function(src)
    stopDetector(src)
end, { rateLimit = { max = 3, window = 5000 } })

QB.events.register('qbmetaldetecting:server:completedFind', function(src, ground)
    if not activeDetectors[src] or not isAllowedGround(ground) then return end
    if (cooldowns[src] or 0) > GetGameTimer() or not playerHas(src, Config.Items.detector) then return end

    local before = skillData(src)
    if not before then return end

    local find = chooseLoot(before.level, false)
    local added, addErr = Core:addItem(src, find.item, 1, nil, nil, 'metal detecting')
    if not added then
        notify(src, addErr or 'You do not have room for that find.', 'error')
        return
    end

    local awarded, awardErr = exports.kora_skills:addRep(src, Config.Skill.name, find.xp)
    if not awarded then
        print(('[qbmetaldetecting] failed to award skill XP to %s: %s'):format(src, tostring(awardErr)))
    end

    local after = skillData(src) or before
    cooldowns[src] = GetGameTimer() + cooldownForLevel(after.level, after.maxLevel) * 1000
    if after.level > before.level then
        notify(src, ('Metal detecting level %d reached.'):format(after.level), 'success')
    end
    QB.events.push(src, 'qbmetaldetecting:client:foundLoot', find.item)
end, { rateLimit = { max = 4, window = 10000 } })

QB.events.register('qbmetaldetecting:server:purchasedDetector', function(src, shopIndex, account)
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

QB.events.register('qbmetaldetecting:server:soldLoot', function(src, shopIndex, item, amount)
    local shop = Config.Selling.shop[shopIndex]
    local price = Config.Loot.sellValues[item]
    if not shop or not price or not near(src, shop.coords, Config.Selling.interactionDistance) then return end

    amount = math.floor(tonumber(amount) or 0)
    local owned = Core:getItemCount(src, item) or 0
    if amount < 1 or amount > owned then
        notify(src, ('You do not have %d x %s.'):format(amount, item), 'error')
        return
    end

    if not Core:removeItem(src, item, amount, nil, 'metal detecting sale') then return end

    local total = amount * price
    Core:addMoney(src, 'cash', total, 'metal detecting sale')
    notify(src, ('Sold %d item(s) for $%d.'):format(amount, total), 'success')
end, { rateLimit = { max = 8, window = 5000 } })

QB.events.register('qbmetaldetecting:server:washedClump', function(src, washIndex)
    local wash = Config.Selling.wash[washIndex]
    if not wash or not near(src, wash.coords, Config.Selling.interactionDistance) then return end
    if not playerHas(src, Config.Items.clump) then
        notify(src, 'You do not have a clump to wash.', 'error')
        return
    end
    if not Core:removeItem(src, Config.Items.clump, 1, nil, 'washed metal detecting clump') then return end

    local skill = skillData(src)
    local find = chooseLoot(skill and skill.level or 1, true)
    local added, addErr = Core:addItem(src, find.item, 1, nil, nil, 'washed metal detecting clump')
    if not added then
        Core:addItem(src, Config.Items.clump, 1, nil, nil, 'failed clump wash refund')
        notify(src, addErr or 'You do not have room for that find.', 'error')
        return
    end
    notify(src, ('You washed the clump and found %s.'):format(find.item), 'success')
end, { rateLimit = { max = 4, window = 10000 } })

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src) clearPlayer(src, false) end)
AddEventHandler('qbcore:server:playerDropped', function(src) clearPlayer(src, false) end)


local IMAGE_BASE = 'nui://kora_inventory/images/'
local appId = 'qbmetaldetecting:catalog'
local inited = false

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if QB.nui.isAppOpen(appId) then
        QB.nui.closeApp(appId)
    end
end)

local function itemDef(name)
    return exports.kora_core:getShared('items', name)
end

local function currentSkill()
    if not inited then
        return 1, 99
    end
    local rep = exports.kora_skills:getRep(Config.Skill.name) or {}
    return rep.level or 1, rep.maxLevel or 99
end

local function sortedLootEntries()
    local entries = {}
    for i = 1, #Config.Loot.items do
        entries[i] = Config.Loot.items[i]
    end
    table.sort(entries, function(a, b) return a.level < b.level end)
    return entries
end

local function buildLootItems(level)
    local lootItems = {}
    local entries = sortedLootEntries()
    for i = 1, #entries do
        local entry = entries[i]
        local definition = itemDef(entry.item)
        local unlocked = level >= entry.level
        local sellPrice = Config.Loot.sellValues[entry.item]

        local descriptionParts = {
            unlocked
                and (('Unlocked at level %d'):format(entry.level))
                or (('Locked - requires level %d'):format(entry.level)),
            ('%d XP per find'):format(entry.xp),
        }
        if sellPrice then
            descriptionParts[#descriptionParts + 1] = ('Sells for $%d'):format(sellPrice)
        end

        lootItems[#lootItems + 1] = {
            id = 'loot:' .. entry.item,
            label = definition and definition.label or entry.item,
            description = table.concat(descriptionParts, ' — '),
            image = definition and (IMAGE_BASE .. definition.image) or nil,
            tone = unlocked and 'success' or 'destructive',
        }
    end
    return lootItems
end

local function buildDetectorView(level, maxLevel)
    local definition = itemDef(Config.Items.detector)
    return {
        id = Config.Items.detector,
        label = definition and definition.label or 'Metal Detector',
        icon = definition and (IMAGE_BASE .. definition.image) or nil,
        content = {
            title = definition and definition.label or 'Metal Detector',
            description = definition and definition.description or nil,
            blocks = {
                {
                    type = 'stats',
                    items = {
                        { label = 'Your Level', value = level,    icon = 'Star' },
                        { label = 'Max Level',  value = maxLevel, icon = 'Trophy' },
                    },
                },
                {
                    type = 'list',
                    id = 'finds',
                    layout = 'list',
                    empty = 'No finds configured for this detector.',
                    items = buildLootItems(level),
                },
            },
        },
    }
end

local function buildNavigation()
    local level, maxLevel = currentSkill()
    return { buildDetectorView(level, maxLevel) }
end

QB.nui.registerApp({
    id = appId,
    title = 'Metal Detecting Catalog',
    description = 'Finds and sell prices unlocked at your current metal detecting level.',
    icon = 'Search',
    layout = 'standard',
    width = 900,
    height = 640,
    footer = 'Press Escape to close',
    navigation = buildNavigation(),
})

local function openMetalDetectingCatalog()
    if QB.nui.isAppOpen(appId) then return end

    QB.nui.updateApp(appId, { navigation = buildNavigation() })
    QB.nui.openApp(appId)
end

RegisterCommand('metaldetectcatalog', function()
    openMetalDetectingCatalog()
end, false)
inited = true

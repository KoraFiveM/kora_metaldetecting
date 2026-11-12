local IMAGE_BASE = 'nui://kora_inventory/images/'
local appId = 'kora_metaldetecting:catalog'
local inited = false

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if Kora.nui.isAppOpen(appId) then
        Kora.nui.closeApp(appId)
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
                and Kora.lang('Catalog.unlocked_at_level', entry.level)
                or Kora.lang('Catalog.locked_requires_level', entry.level),
            Kora.lang('Catalog.xp_per_find', entry.xp),
        }
        if sellPrice then
            descriptionParts[#descriptionParts + 1] = Kora.lang('Catalog.sells_for', sellPrice)
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
        label = definition and definition.label or Kora.lang('Ui.detector'),
        icon = definition and (IMAGE_BASE .. definition.image) or nil,
        content = {
            title = definition and definition.label or Kora.lang('Ui.detector'),
            description = definition and definition.description or nil,
            blocks = {
                {
                    type = 'stats',
                    items = {
                        { label = Kora.lang('Ui.your_level'), value = level,    icon = 'Star' },
                        { label = Kora.lang('Ui.max_level'),  value = maxLevel, icon = 'Trophy' },
                    },
                },
                {
                    type = 'list',
                    id = 'finds',
                    layout = 'list',
                    empty = Kora.lang('Ui.no_finds_configured'),
                    items = buildLootItems(level),
                },
            },
        },
    }
end

local function buildNavigation()
    return { buildDetectorView(currentSkill()) }
end

Kora.nui.registerApp({
    id = appId,
    title = Kora.lang('Ui.catalog_title'),
    description = Kora.lang('Ui.catalog_description'),
    icon = 'Search',
    layout = 'standard',
    width = 900,
    height = 640,
    footer = Kora.lang('Ui.press_escape_to_close'),
    navigation = buildNavigation(),
})

local function openMetalDetectingCatalog()
    if Kora.nui.isAppOpen(appId) then return end

    Kora.nui.updateApp(appId, { navigation = buildNavigation() })
    Kora.nui.openApp(appId)
end

RegisterCommand('metaldetectcatalog', function()
    openMetalDetectingCatalog()
end, false)
inited = true

Config = {
    Items = {
        detector = 'metaldetector',
        clump = 'clump',
    },

    Detection = {
        showText = true,
        detectorModel = 'bostra_detector',
        digDuration = 7000,
        distance = 5.0,
        minigame = {
            attempts = 2,
            zoneSize = 0.24,
            speed = 0.5,
            timeLimit = 10000,
        },
        allowedGrounds = {
            1288448767, 1333033863, -1942898710, -1595148316,
            587194674, 509508168, -1286696947, 510490462,
            1144315879, -461750719, 2128369009, 951832588,
            -1885547121,
        },
    },

    Skill = {
        name = 'metaldetecting',
        cooldown = {
            atLevel1 = 55,
            atMaxLevel = 5,
        },
    },

    Loot = {
        items = {
            { item = 'clump',                level = 1, xp = 10 },
            { item = 'metalscrap',          level = 1,  xp = 17 },
            { item = 'copper',              level = 1,  xp = 17 },
            { item = 'aluminum',            level = 10, xp = 35 },
            { item = 'iron',                level = 20, xp = 45 },
            { item = 'bobby_pin',            level = 25, xp = 50 },
            { item = 'bottle_cap',           level = 30, xp = 50 },
            { item = 'nails',                level = 35, xp = 75 },
            { item = 'toy_car',              level = 40, xp = 143 },
            { item = 'corno',                level = 45, xp = 176 },
            { item = 'car_keys_md',          level = 50, xp = 300 },
            { item = 'steel',                level = 55, xp = 460 },
            { item = 'silver_ring_md',       level = 60, xp = 550 },
            { item = 'gold_ring_md',         level = 60, xp = 600 },
            { item = 'gold_chain_md',        level = 65, xp = 850 },
            { item = 'gold_bracelet_md',     level = 70, xp = 1400 },
            { item = 'diamond_earring_md',   level = 70, xp = 1500 },
            { item = 'diamond_ring_md',      level = 70, xp = 1680 },
            { item = 'gold_diamond_ring_md', level = 75, xp = 3300 },
            { item = 'antique_coin',          level = 80, xp = 5000 },
            { item = 'ruby_ring_md',          level = 85, xp = 9000 },
        },
       sellValues = {
            clump = 10,
            bobby_pin = 25,
            bottle_cap = 20,
            nails = 30,
            toy_car = 50,
            corno = 60,
            car_keys_md = 100,
            silver_ring_md = 100,
            gold_ring_md = 125,
            gold_chain_md = 150,
            gold_bracelet_md = 175,
            diamond_earring_md = 200,
            diamond_ring_md = 225,
            gold_diamond_ring_md = 250,
            antique_coin = 275,
            ruby_ring_md = 300,
        }
    },

    Selling = {
        detectorPrice = 500,
        interactionDistance = 5.0,
        shop = {
            {
                coords = vector4(-1111.29, -1689.21, 3.38, 307.79),
                -- Ped model name (any valid ped model).
                ped = 'ig_priest',
                -- Optional outfit: { components = { [id] = { d = drawable, t = texture } }, props = { [id] = { d = drawable, t = texture } } }
                outfit = nil,
                scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
                -- Added to coords.z when the server creates the ped (ped origin sits above the ground).
                zOffset = 1.0,
                -- The ped definition is only sent to / used by players inside this radius.
                spawnDistance = 50.0,
                target = { label = 'Open Metal Detector Shop', icon = 'Store' },
                blip = { sprite = 617, color = 5, scale = 0.7, name = 'Metal Detector Shop', shortRange = true, category = 'Other' },
            },
        },
        wash = {
            { coords = vector3(-1247.79, -1542.34, 4.3), blip = { sprite = 318, color = 5, scale = 0.7, name = 'Clump Washing' } },
            { coords = vector3(-1250.03, -1541.78, 4.3), blip = { sprite = 318, color = 5, scale = 0.7, name = 'Clump Washing' } },
            { coords = vector3(-1252.35, -1541.27, 4.3), blip = { sprite = 318, color = 5, scale = 0.7, name = 'Clump Washing' } },
        },
    },
}

for index, entry in ipairs(Config.Loot.items) do
    assert(type(entry.level) == 'number' and entry.level >= 1 and entry.level % 1 == 0,
        ('kora_metaldetecting Config.Loot.items[%d] (%s) level must be a positive integer.'):format(index, tostring(entry.item)))
    assert(type(entry.xp) == 'number' and entry.xp > 0,
        ('kora_metaldetecting Config.Loot.items[%d] (%s) xp must be a positive number.'):format(index, tostring(entry.item)))
end

for index, shop in ipairs(Config.Selling.shop) do
    assert(type(shop.ped) == 'string' and shop.ped ~= '',
        ('kora_metaldetecting Config.Selling.shop[%d].ped must be a non-empty model name.'):format(index))
    for _, group in ipairs({ 'components', 'props' }) do
        for id, entry in pairs(type(shop.outfit) == 'table' and shop.outfit[group] or {}) do
            assert(tonumber(id) and type(entry) == 'table' and type(entry.d) == 'number' and (entry.t == nil or type(entry.t) == 'number'),
                ('kora_metaldetecting Config.Selling.shop[%d].outfit.%s[%s] needs numeric d (and t).'):format(index, group, tostring(id)))
        end
    end
end

assert(type(Config.Skill.cooldown) == 'table'
    and type(Config.Skill.cooldown.atLevel1) == 'number' and Config.Skill.cooldown.atLevel1 > 0
    and type(Config.Skill.cooldown.atMaxLevel) == 'number' and Config.Skill.cooldown.atMaxLevel > 0
    and Config.Skill.cooldown.atMaxLevel <= Config.Skill.cooldown.atLevel1,
    'kora_metaldetecting Config.Skill.cooldown must define a positive atLevel1 >= atMaxLevel, in seconds.')

if Kora and Kora.config and Kora.config.adopt then Config = Kora.config.adopt(Config) end

Config = {
    Items = {
        detector = 'metaldetector',
        clump = 'clump',

        -- Registered through qbcore's live shared-item registry on the server.
        definitions = {
            metalscrap = { label = 'Metal Scrap', weight = 100, image = 'metalscrap.png', description = 'You can probably make something nice out of this.' },
            copper = { label = 'Copper', weight = 100, image = 'copper.png', description = 'A useful piece of copper.' },
            aluminum = { label = 'Aluminium', weight = 100, image = 'aluminum.png', description = 'A useful piece of aluminium.' },
            iron = { label = 'Iron', weight = 100, image = 'iron.png', description = 'A handy piece of iron.' },
            steel = { label = 'Steel', weight = 100, image = 'steel.png', description = 'A useful piece of steel.' },
            ['1792coin'] = { label = '1792 Coin', weight = 100, image = '1792coin.png', description = 'Even older.' },
            ['1797coin'] = { label = '1797 Coin', weight = 100, image = '1797coin.png', description = "That's old." },
            bobbypin = { label = 'Bobby Pin', weight = 100, image = 'bobbypin.png', description = 'Put your hair up.' },
            bottlecap = { label = 'Bottle Cap', weight = 100, image = 'bottlecap.png', description = 'Stepped on a pop top.' },
            clump = { label = 'Clump', weight = 100, image = 'clump.png', description = 'Not a turd.' },
            corno = { label = 'Corno', weight = 100, image = 'corno.png', description = 'A curious find.' },
            diamondring = { label = 'Diamond Ring', weight = 100, image = 'diamondring.png', description = 'Pretty sure some poor kid made this.' },
            goldbracelet = { label = 'Gold Bracelet', weight = 100, image = 'goldbracelet.png', description = 'Is this bracelet real gold?' },
            golddiamondring = { label = 'Gold Diamond Ring', weight = 100, image = 'golddiamondring.png', description = "It's a gold ring with a diamond?" },
            goldring = { label = 'Golden Ring', weight = 100, image = 'goldring.png', description = 'My precious.' },
            rubyring = { label = 'Ruby Ring', weight = 100, image = 'rubyring.png', description = 'It is a ruby, not a rubix.' },
            toycar = { label = 'Toy Car', weight = 100, image = 'toycar.png', description = "Don't put it in odd places." },
            metaldetector = { label = 'Metal Detector', weight = 2500, image = 'metaldetector.png', description = 'Maybe it can find things.' },
        },
    },

    Detection = {
        showText = true,
        detectorModel = 'bostra_detector',
        digDuration = 8000,
        distance = 5.0,
        minigame = {
            attempts = 2,
            zoneSize = 0.14,
            speed = 1.0,
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
        xpPerFind = 1,
        -- qbskills levels start at 1. This keeps the original 55-to-5 second
        -- progression while allowing qbskills to retain its full level curve.
        cooldownByLevel = {
            [1] = 55, [2] = 50, [3] = 45, [4] = 40, [5] = 35,
            [6] = 30, [7] = 25, [8] = 20, [9] = 15, [10] = 10,
            [11] = 5,
        },
        minimumCooldown = 5,
    },

    Loot = {
        rareChance = 10,
        rare = {
            '1792coin', '1797coin', 'diamondring', 'goldbracelet',
            'golddiamondring', 'rubyring', 'steel', 'metalscrap',
            'iron', 'copper',
        },
        common = {
            'bobbypin', 'clump', 'clump', 'clump', 'bottlecap', 'corno',
            'toycar', 'goldring', 'steel', 'metalscrap', 'iron', 'copper',
        },
        sellValues = {
            bobbypin = 25, bottlecap = 25, corno = 25, toycar = 25,
            goldring = 25, ['1792coin'] = 25, ['1797coin'] = 25,
            diamondring = 25, golddiamondring = 25, goldbracelet = 25,
            rubyring = 25,
        },
    },

    Selling = {
        detectorPrice = 500,
        interactionDistance = 5.0,
        shop = {
            {
                coords = vector4(-1113.45, -1689.03, 4.38, 150.53),
                ped = 'ig_priest',
                blip = { sprite = 617, color = 5, scale = 0.7, name = 'Metal Detector Shop' },
            },
        },
        wash = {
            { coords = vector3(-1247.79, -1542.34, 4.3), blip = { sprite = 318, color = 5, scale = 0.7, name = 'Clump Washing' } },
            { coords = vector3(-1250.03, -1541.78, 4.3), blip = { sprite = 318, color = 5, scale = 0.7, name = 'Clump Washing' } },
            { coords = vector3(-1252.35, -1541.27, 4.3), blip = { sprite = 318, color = 5, scale = 0.7, name = 'Clump Washing' } },
        },
    },
}

if QB and QB.config and QB.config.adopt then Config = QB.config.adopt(Config) end

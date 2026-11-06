local IMAGE_BASE = 'nui://kora_inventory/images/'
local appId = 'qbmetaldetecting:shop'
local defaultView = 'buy'

local function notify(message, type_)
    Kora.notify.send({ title = 'Metal Detecting', message = message, type = type_ or 'info' })
end

local function itemDef(name)
    return exports.kora_core:getShared('items', name)
end

local function itemImage(definition)
    return definition and definition.image and (IMAGE_BASE .. definition.image) or nil
end

local function sellableItems()
    local sellable = {}
    for _, entry in ipairs(Config.Loot.items) do
        local price = Config.Loot.sellValues[entry.item]
        if price then sellable[#sellable + 1] = { item = entry.item, price = price } end
    end
    return sellable
end

local function buildBuyView()
    local definition = itemDef(Config.Items.detector)
    local price = Config.Selling.detectorPrice

    return {
        id = 'buy',
        label = 'Buy',
        icon = 'ShoppingCart',
        content = {
            title = definition and definition.label or 'Metal Detector',
            description = definition and definition.description or nil,
            blocks = {
                {
                    type = 'list',
                    layout = 'cards',
                    items = {
                        {
                            id = Config.Items.detector,
                            label = definition and definition.label or 'Metal Detector',
                            description = ('$%d'):format(price),
                            image = itemImage(definition),
                        },
                    },
                },
            },
            actions = {
                {
                    id = 'buy-cash',
                    label = ('Pay Cash — $%d'):format(price),
                    icon = 'Banknote',
                    variant = 'primary',
                    confirm = ('Buy a metal detector for $%d in cash?'):format(price),
                },
                {
                    id = 'buy-card',
                    label = ('Pay Card — $%d'):format(price),
                    icon = 'CreditCard',
                    variant = 'secondary',
                    confirm = ('Buy a metal detector for $%d on your card?'):format(price),
                },
            },
        },
    }
end

local function buildSellItems()
    local items = {}
    for _, entry in ipairs(sellableItems()) do
        -- kora_inventory's client exports may not be ready at load; the list is rebuilt on shop open
        local ok, owned = pcall(function() return exports.kora_inventory:HasItem(entry.item) end)
        if not ok then owned = false end
        local definition = itemDef(entry.item)
        local label = definition and definition.label or entry.item
        if owned then
            items[#items + 1] = {
                id = entry.item,
                label = label,
                description = ('$%d each'):format(entry.price),
                image = itemImage(definition),
                tone = 'success',
                action = {
                    id = 'sell-item',
                    label = 'Sell',
                    icon = 'Coins',
                    fields = {
                        {
                            id = 'amount',
                            label = ('Amount to sell (%s)'):format(label),
                            type = 'number',
                            default = 1,
                            min = 1,
                            max = 100,
                            wholeNumber = true,
                            required = true,
                        },
                    },
                },
            }
        end
    end
    return items
end

local function buildSellView()
    return {
        id = 'sell',
        label = 'Sell',
        icon = 'Coins',
        content = {
            title = 'Sell Detected Loot',
            description = 'Pick an item, choose how many to sell, and confirm.',
            blocks = {
                {
                    type = 'list',
                    id = 'sell-list',
                    layout = 'list',
                    max = 10,
                    searchable = true,
                    empty = 'You have nothing to sell yet.',
                    items = buildSellItems(),
                },
            },
        },
    }
end

local function buildNavigation()
    return { buildBuyView(), buildSellView() }
end

Kora.nui.registerApp({
    id = appId,
    title = 'Metal Detector Shop',
    icon = 'Search',
    layout = 'standard',
    defaultView = defaultView,
    width = 500,
    height = 560,
    placement = 'right',
    navigation = buildNavigation(),
    onAction = function(actionId, context)
        local shopIndex = context.data and context.data.shopIndex
        if not shopIndex then
            notify('Something went wrong opening the shop, try again.', 'error')
            return { close = true }
        end

        if actionId == 'buy-cash' or actionId == 'buy-card' then
            local account = actionId == 'buy-cash' and 'cash' or 'bank'
            Kora.events.trigger('qbmetaldetecting:server:purchasedDetector', shopIndex, account)
            return { close = true }
        end

        if actionId == 'sell-item' then
            local item = context.itemId
            local amount = math.floor(tonumber(context.value and context.value.amount) or 0)
            if not item or amount < 1 then return end

            Kora.events.trigger('qbmetaldetecting:server:soldLoot', shopIndex, item, amount)
            return {
                update = { navigation = buildNavigation() },
                notice = { tone = 'success', message = ('Selling %d x %s...'):format(amount, item) },
            }
        end
    end,
})

function OpenMetalDetectingShop(shopIndex)
    if Kora.nui.isAppOpen(appId) then return end

    Kora.nui.updateApp(appId, { navigation = buildNavigation() })
    Kora.nui.openApp(appId, { data = { shopIndex = shopIndex } })
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if Kora.nui.isAppOpen(appId) then Kora.nui.closeApp(appId) end
end)

for index, shop in ipairs(Config.Selling.shop) do
    local ped = Kora.entities.create(shop.ped, shop.coords, { preset = 'static' })
    if ped then TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true) end
    exports.kora_target:addEntity(ped, {
        { label = 'Open Metal Detector Shop', icon = 'Store', onSelect = function() OpenMetalDetectingShop(index) end },
    })
end
local IMAGE_BASE = 'nui://kora_inventory/images/'
local appId = 'kora_metaldetecting:shop'
local defaultView = 'buy'

local function notify(message, type_)
    Kora.notify.send({ title = Kora.lang('Ui.title'), message = message, type = type_ or 'info' })
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
        label = Kora.lang('Shop.buy'),
        icon = 'ShoppingCart',
        content = {
            title = definition and definition.label or Kora.lang('Ui.detector'),
            description = definition and definition.description or nil,
            blocks = {
                {
                    type = 'list',
                    layout = 'cards',
                    items = {
                        {
                            id = Config.Items.detector,
                            label = definition and definition.label or Kora.lang('Ui.detector'),
                            description = Kora.lang('Shop.price', price),
                            image = itemImage(definition),
                        },
                    },
                },
            },
            actions = {
                {
                    id = 'buy-cash',
                    label = Kora.lang('Shop.pay_cash', price),
                    icon = 'Banknote',
                    variant = 'primary',
                    confirm = Kora.lang('Shop.confirm_cash', price),
                },
                {
                    id = 'buy-card',
                    label = Kora.lang('Shop.pay_card', price),
                    icon = 'CreditCard',
                    variant = 'secondary',
                    confirm = Kora.lang('Shop.confirm_card', price),
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
                description = Kora.lang('Shop.each', entry.price),
                image = itemImage(definition),
                tone = 'success',
                action = {
                    id = 'sell-item',
                    label = Kora.lang('Shop.sell'),
                    icon = 'Coins',
                    fields = {
                        {
                            id = 'amount',
                            label = Kora.lang('Shop.amount_to_sell', label),
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
        label = Kora.lang('Shop.sell'),
        icon = 'Coins',
        content = {
            title = Kora.lang('Shop.sell_title'),
            description = Kora.lang('Shop.sell_description'),
            blocks = {
                {
                    type = 'list',
                    id = 'sell-list',
                    layout = 'list',
                    max = 10,
                    searchable = true,
                    empty = Kora.lang('Shop.nothing_to_sell'),
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
    title = Kora.lang('Shop.title'),
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
            notify(Kora.lang('Shop.open_failed'), 'error')
            return { close = true }
        end

        if actionId == 'buy-cash' or actionId == 'buy-card' then
            local account = actionId == 'buy-cash' and 'cash' or 'bank'
            Kora.events.trigger('kora_metaldetecting:server:purchasedDetector', shopIndex, account)
            return { close = true }
        end

        if actionId == 'sell-item' then
            local item = context.itemId
            local amount = math.floor(tonumber(context.value and context.value.amount) or 0)
            if not item or amount < 1 then return end

            Kora.events.trigger('kora_metaldetecting:server:soldLoot', shopIndex, item, amount)
            return {
                update = { navigation = buildNavigation() },
                notice = { tone = 'success', message = Kora.lang('Shop.selling', amount, item) },
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

-- Shop ped: created by the server; its definition arrives in an entity
-- statebag only while the ped is in scope. The target is attached while the
-- player is inside the shop's spawnDistance and removed when they leave.
local SHOP_PED_KEY = 'kora_metaldetecting:shopPed'
local shopStates = {}

local function applyFallbackSkin(ped, skin)
    for key, entry in pairs(type(skin.components) == 'table' and skin.components or {}) do
        local id, drawable, texture = tonumber(key), tonumber(entry.d), tonumber(entry.t) or 0
        if id and drawable and drawable >= 0 and drawable < GetNumberOfPedDrawableVariations(ped, id) then
            if texture < 0 or texture >= GetNumberOfPedTextureVariations(ped, id, drawable) then texture = 0 end
            SetPedComponentVariation(ped, id, drawable, texture, 0)
        end
    end
    for key, entry in pairs(type(skin.props) == 'table' and skin.props or {}) do
        local id, drawable, texture = tonumber(key), tonumber(entry.d), tonumber(entry.t) or 0
        if id and drawable and drawable >= 0 and drawable < GetNumberOfPedPropDrawableVariations(ped, id) then
            if texture < 0 or texture >= GetNumberOfPedPropTextureVariations(ped, id, drawable) then texture = 0 end
            SetPedPropIndex(ped, id, drawable, texture, true)
        elseif id then
            ClearPedProp(ped, id)
        end
    end
end

local function dressPed(ped, data)
    if type(data.outfit) ~= 'table' then return end
    if GetResourceState('kora_clothing') == 'started' then
        local ok, applied = pcall(function() return exports.kora_clothing:ApplyAppearanceToPed(ped, data.model, data.outfit) end)
        if ok and applied == true then return end
    end
    applyFallbackSkin(ped, data.outfit)
end

local function removeShopTarget(state)
    local entity, targetId = state.targetEntity, state.targetId
    state.targetId, state.targetEntity = nil, nil
    if entity and targetId then pcall(exports.kora_target.removeEntity, exports.kora_target, entity, targetId) end
end

local function setupShopPed(index)
    local state = shopStates[index]
    if not state or not state.inside or not state.data or not state.entity then return end
    local entity = state.entity
    if not DoesEntityExist(entity) then return end
    if state.targetEntity == entity then return end
    removeShopTarget(state)

    if state.dressed ~= entity then
        state.dressed = entity
        dressPed(entity, state.data)
        SetEntityInvincible(entity, true)
        SetBlockingOfNonTemporaryEvents(entity, true)
        SetPedCanRagdoll(entity, false)
        if type(state.data.scenario) == 'string' and state.data.scenario ~= '' then
            TaskStartScenarioInPlace(entity, state.data.scenario, 0, true)
        end
    end

    local target = state.data.target or {}
    local ok, id = pcall(exports.kora_target.addEntity, exports.kora_target, entity, {
        { label = target.label or 'Open Metal Detector Shop', icon = target.icon or 'Store', onSelect = function() OpenMetalDetectingShop(index) end },
    })
    if ok and id then
        state.targetId, state.targetEntity = id, entity
    end
end

for index, shop in ipairs(Config.Selling.shop) do
    local state = { inside = false }
    shopStates[index] = state
    state.zone = Kora.zones.sphere({
        coords = shop.coords,
        radius = tonumber(shop.spawnDistance) or 50.0,
        onEnter = function()
            state.inside = true
            CreateThread(function() setupShopPed(index) end)
        end,
        onExit = function()
            state.inside = false
            removeShopTarget(state)
        end,
    })
end

Kora.state.onChange(SHOP_PED_KEY, nil, function(change)
    local data = change.value
    if type(data) ~= 'table' then return end
    local index = tonumber(data.shopIndex)
    local state = index and shopStates[index]
    if not state then return end

    CreateThread(function()
        local entity, waited = change.entity, 0
        while (not entity or entity == 0 or not DoesEntityExist(entity)) and waited < 3000 do
            Wait(100)
            waited = waited + 100
            entity = GetEntityFromStateBagName(change.bagName)
        end
        if not entity or entity == 0 or not DoesEntityExist(entity) then return end
        if state.entity ~= entity then removeShopTarget(state) end
        state.entity, state.data = entity, data
        setupShopPed(index)
    end)
end)

local function clearShopTargets()
    for _, state in pairs(shopStates) do removeShopTarget(state) end
end

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then clearShopTargets() end
end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', clearShopTargets)
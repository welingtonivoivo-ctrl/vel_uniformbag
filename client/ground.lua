-- Bolsas no chão (D208): cada cliente cria o objeto localmente a partir da lista do servidor e
-- registra as opções do olhinho (API ox_target, atendida pelo mri_Qinteract na base).

Ground = {}

local spawned = {} -- bagId -> { obj, zone, spot }

local function deleteObj(obj)
    if obj and DoesEntityExist(obj) then
        SetEntityAsMissionEntity(obj, true, true)
        DeleteEntity(obj)
    end
end

function Ground.Spot(bagId)
    local entry = spawned[bagId]
    return entry and entry.spot or nil
end

function Ground.Object(bagId)
    local entry = spawned[bagId]
    return entry and entry.obj or nil
end

local function remove(bagId)
    local entry = spawned[bagId]
    if not entry then return end
    deleteObj(entry.obj)
    if entry.zone then pcall(function() exports.ox_target:removeZone(entry.zone) end) end
    spawned[bagId] = nil
end

local function add(bagId, spot)
    remove(bagId)
    local model = joaat(Config.PropModel)
    local ok = pcall(lib.requestModel, model, 5000)
    local obj
    if ok then
        obj = CreateObjectNoOffset(model, spot.x, spot.y, spot.z, false, false, false)
        SetModelAsNoLongerNeeded(model)
        if obj and obj ~= 0 then
            SetEntityHeading(obj, spot.heading or 0.0)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, false)
        end
    end

    local zone
    pcall(function()
        zone = exports.ox_target:addSphereZone({
            coords = vec3(spot.x, spot.y, spot.z + 0.3),
            radius = 0.9,
            debug = false,
            options = {
                {
                    name = 'street_uniformbag:open:' .. bagId,
                    icon = 'fa-solid fa-shirt',
                    label = L('target.open'),
                    distance = 2.0,
                    canInteract = function() return not Bag.IsOpen() end,
                    onSelect = function() CreateThread(function() Bag.OpenGround(bagId) end) end,
                },
                {
                    name = 'street_uniformbag:collect:' .. bagId,
                    icon = 'fa-solid fa-hand',
                    label = L('target.collect'),
                    distance = 2.0,
                    canInteract = function() return not Bag.IsOpen() end,
                    onSelect = function() CreateThread(function() Bag.Collect(bagId) end) end,
                },
            },
        })
    end)

    spawned[bagId] = { obj = obj, zone = zone, spot = spot }
end

RegisterNetEvent('street_uniformbag:client:groundAdd', function(bagId, spot)
    if type(bagId) == 'string' and type(spot) == 'table' then add(bagId, spot) end
end)

RegisterNetEvent('street_uniformbag:client:groundRemove', function(bagId)
    remove(bagId)
end)

local function sync()
    local list = lib.callback.await('street_uniformbag:groundList', false) or {}
    for bagId in pairs(spawned) do
        if not list[bagId] then remove(bagId) end
    end
    for bagId, spot in pairs(list) do add(bagId, spot) end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() SetTimeout(3000, sync) end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() then SetTimeout(2000, sync) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for bagId in pairs(spawned) do remove(bagId) end
end)

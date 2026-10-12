-- Bolsa de verdade no chão (D208). O item sai do inventário e fica registrado no banco com a
-- posição; qualquer jogador perto pode abrir ou recolher. Persistente: não expira e sobrevive a
-- reinícios (os clientes recriam o objeto a partir da lista).

Ground = {}

local ITEM = Config.ItemName
local bags = {} -- bagId -> { x, y, z, heading }

local function notify(src, key, kind, ...)
    TriggerClientEvent('ox_lib:notify', src, { type = kind or 'error', description = L(key, ...) })
end

function Ground.Load()
    bags = {}
    local rows = MySQL.query.await('SELECT `bag_id`, `x`, `y`, `z`, `heading` FROM `sub_ground_bags`') or {}
    for _, r in ipairs(rows) do
        bags[r.bag_id] = { x = r.x + 0.0, y = r.y + 0.0, z = r.z + 0.0, heading = r.heading + 0.0 }
    end
    return #rows
end

function Ground.Get(bagId)
    return bags[bagId]
end

--- O jogador está perto da bolsa no chão?
function Ground.IsNear(src, bagId, maxDistance)
    local spot = bags[bagId]
    local ped = GetPlayerPed(src)
    if not spot or not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(spot.x, spot.y, spot.z)) <= (maxDistance or Config.MaxDistance)
end

lib.callback.register('vel_uniformbag:groundList', function()
    return bags
end)

--- Usar o item: tira do inventário e coloca no chão na frente do jogador; depois abre a tela.
function Ground.PlaceFromSlot(src, slot)
    if not Database.Ready then return notify(src, 'block.unavailable') end
    if GetResourceState('mri_Qappearance') ~= 'started' then return notify(src, 'block.appearance') end

    local item = exports.ox_inventory:GetSlot(src, slot)
    if not item or item.name ~= ITEM then return end
    local meta = item.metadata or {}
    if meta.invalid or type(meta.bagId) ~= 'string' then return notify(src, 'block.unrecognized') end

    local bag = Bags.Get(meta.bagId)
    if not bag or bag.status == 'falha_emissao' then return notify(src, 'block.unrecognized') end

    local reason = Change.BlockedReason(src)
    if reason then return notify(src, reason) end

    local data = Utils.GetPlayerData(src)
    if not data then return end

    -- Uma bolsa que já está no chão não pode estar também num inventário (D189).
    if bags[bag.bag_id] or Bags.CheckDuplicate(bag, 'player', data.citizenid) then
        if bags[bag.bag_id] then
            MySQL.update.await('UPDATE `sub_bags` SET `flagged_duplicate` = 1 WHERE `bag_id` = ?', { bag.bag_id })
            Utils.Audit('duplicacao', 'detectada', { src = src, org = bag.org, bagId = bag.bag_id, data = { motivo = 'bolsa no chão e no inventário' } })
        end
        return notify(src, 'block.duplicate')
    end

    local ped = GetPlayerPed(src)
    local heading = GetEntityHeading(ped)
    local rad = math.rad(heading)
    local c = GetEntityCoords(ped)
    local spot = { x = c.x - math.sin(rad) * 0.6, y = c.y + math.cos(rad) * 0.6, z = c.z - 0.95, heading = heading }

    -- Grava primeiro; só então tira do inventário. Se a retirada falhar, desfaz o registro.
    MySQL.insert.await(
        'INSERT INTO `sub_ground_bags` (`bag_id`, `x`, `y`, `z`, `heading`, `placed_by_citizenid`) VALUES (?, ?, ?, ?, ?, ?)',
        { bag.bag_id, spot.x, spot.y, spot.z, spot.heading, data.citizenid })

    if not exports.ox_inventory:RemoveItem(src, ITEM, 1, nil, slot) then
        MySQL.update.await('DELETE FROM `sub_ground_bags` WHERE `bag_id` = ?', { bag.bag_id })
        return notify(src, 'block.invalid_request')
    end

    bags[bag.bag_id] = spot
    Bags.TouchActivity(bag.bag_id, 'uso', 'chao', bag.bag_id)
    MySQL.update.await("UPDATE `sub_bags` SET `status` = 'em_circulacao' WHERE `bag_id` = ?", { bag.bag_id })
    Utils.Audit('troca', 'bolsa_no_chao', { src = src, org = bag.org, bagId = bag.bag_id, coords = spot })

    TriggerClientEvent('vel_uniformbag:client:groundAdd', -1, bag.bag_id, spot)
    Change.OpenFromGround(src, bag.bag_id, true)
end

--- Recolher: qualquer jogador perto; a bolsa vai para o inventário de quem recolheu (D208).
lib.callback.register('vel_uniformbag:collect', function(src, bagId)
    if type(bagId) ~= 'string' or not bags[bagId] then return false end
    if not Ground.IsNear(src, bagId, Config.MaxDistance) then notify(src, 'block.too_far') return false end
    if Change.BlockedReason(src) then notify(src, 'block.dead') return false end

    local lock = Locks.Info(bagId)
    if lock and lock.src ~= src and Locks.Holds(bagId, lock.src) then notify(src, 'block.in_use') return false end

    local bag = Bags.Get(bagId)
    local uniform = bag and Uniforms.Get(bag.uniform_id)
    if not bag then return false end

    local metadata = Bags.BuildMetadata(bag, uniform)
    if not exports.ox_inventory:CanCarryItem(src, ITEM, 1, metadata) then notify(src, 'block.cannot_carry') return false end

    -- Só um jogador consegue recolher: quem apagar o registro primeiro.
    local removed = MySQL.update.await('DELETE FROM `sub_ground_bags` WHERE `bag_id` = ?', { bagId })
    if removed ~= 1 then return false end
    local spot = bags[bagId]
    bags[bagId] = nil

    if not exports.ox_inventory:AddItem(src, ITEM, 1, metadata) then
        MySQL.insert.await(
            'INSERT INTO `sub_ground_bags` (`bag_id`, `x`, `y`, `z`, `heading`, `placed_by_citizenid`) VALUES (?, ?, ?, ?, ?, ?)',
            { bagId, spot.x, spot.y, spot.z, spot.heading, 'restaurado' })
        bags[bagId] = spot
        notify(src, 'block.cannot_carry')
        return false
    end

    if lock then Locks.Release(bagId, lock.src, true) end

    local data = Utils.GetPlayerData(src)
    Bags.TouchActivity(bagId, 'retirada', 'player', data and data.citizenid)
    Utils.Audit('retirada', 'recolhida_do_chao', { src = src, org = bag.org, bagId = bagId, coords = spot })

    TriggerClientEvent('vel_uniformbag:client:groundRemove', -1, bagId)
    return true
end)

--- Abrir a bolsa que está no chão (qualquer jogador perto — D4).
lib.callback.register('vel_uniformbag:openGround', function(src, bagId)
    if type(bagId) ~= 'string' or not bags[bagId] then return false end
    if not Ground.IsNear(src, bagId, Config.MaxDistance) then notify(src, 'block.too_far') return false end
    Change.OpenFromGround(src, bagId, false)
    return true
end)

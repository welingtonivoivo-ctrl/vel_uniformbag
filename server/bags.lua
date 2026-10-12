-- Bolsas: dados no banco (autoridade), metadados do item, imagem, invalidez e duplicidade
-- (D187–D191, D174). O banco manda; o item é só cópia de apresentação.

Bags = {}

local ITEM = Config.ItemName

function Bags.Get(bagId)
    if type(bagId) ~= 'string' or #bagId > 12 then return nil end
    return MySQL.single.await('SELECT * FROM `sub_bags` WHERE `bag_id` = ?', { bagId })
end

function Bags.Slots(bagId)
    return MySQL.query.await(
        'SELECT `slot_no`, `model`, `appearance`, `stored_by_name`, `stored_at`, `uniform_id` FROM `sub_bag_slots` WHERE `bag_id` = ? ORDER BY `slot_no`',
        { bagId }) or {}
end

--- Nome de imagem seguro (D174): só [a-z0-9_], até 60 caracteres, arquivo precisa existir.
function Bags.ResolveImage(name)
    if type(name) == 'string' and name:match('^[a-z0-9_]+$') and #name <= 60 then
        if LoadResourceFile('ox_inventory', ('web/images/%s.png'):format(name)) then
            return name
        end
    end
    return Config.DefaultItemImage
end

function Bags.OrgImage(org)
    local row = MySQL.single.await('SELECT `item_image` FROM `sub_org_settings` WHERE `org` = ?', { org })
    return Bags.ResolveImage(row and row.item_image)
end

--- Metadados de apresentação do item a partir do banco.
function Bags.BuildMetadata(bag, uniform)
    local jobs = exports.qbx_core:GetJobs()
    local orgLabel = jobs and jobs[bag.org] and jobs[bag.org].label or bag.org
    return {
        bagId = bag.bag_id,
        uniformId = bag.uniform_id,
        org = bag.org,
        label = L('item.label', uniform and uniform.name or '?'),
        description = L('item.description', orgLabel, bag.bag_id),
        image = Bags.OrgImage(bag.org),
    }
end

--- Ressincroniza os metadados do item no slot do jogador (D190). Não altera o banco.
function Bags.SyncItem(src, slot, bag, uniform)
    local item = exports.ox_inventory:GetSlot(src, slot)
    if not item or item.name ~= ITEM then return end
    local meta = Bags.BuildMetadata(bag, uniform)
    local current = item.metadata or {}
    if current.label ~= meta.label or current.image ~= meta.image or current.description ~= meta.description then
        exports.ox_inventory:SetMetadata(src, slot, meta)
    end
end

--- Registra atividade confirmada e a localização atual (D164, D189).
function Bags.TouchActivity(bagId, kind, locationType, locationId)
    MySQL.update.await(
        [[UPDATE `sub_bags` SET `last_activity_at` = NOW(), `last_activity_kind` = ?, `location_type` = ?, `location_id` = ?,
          `status` = ? WHERE `bag_id` = ?]],
        { kind, locationType, locationId, locationType == 'stash' and 'em_estoque' or 'em_circulacao', bagId })
end

--- Localização de um inventário do ox_inventory no formato guardado no banco.
--- Jogadores são guardados pelo citizenid (o id de servidor muda a cada conexão).
---@return string type, string|nil id
function Bags.Location(inventoryId, inventoryType)
    if inventoryType == 'player' or type(inventoryId) == 'number' then
        local data = Utils.GetPlayerData(tonumber(inventoryId))
        return 'player', data and data.citizenid or nil
    end
    return inventoryType or 'stash', inventoryId and tostring(inventoryId) or nil
end

--- Converte a localização guardada de volta para um inventário carregado, se houver.
local function loadedInventory(locationType, locationId)
    if not locationId then return nil end
    if locationType == 'player' then
        local player = exports.qbx_core:GetPlayerByCitizenId(locationId)
        return player and player.PlayerData.source or nil
    end
    return locationId
end

--- Conferência de duplicidade no uso (D189): se a bolsa estava registrada em outro inventário
--- carregado e esse inventário ainda contém o mesmo bagId, as duas cópias existem.
---@return boolean duplicated
function Bags.CheckDuplicate(bag, currentType, currentId)
    if Utils.Bool(bag.flagged_duplicate) then return true end
    if not bag.location_id then return false end
    if bag.location_type == 'chao' then return false end -- bolsa no chão é conferida por Ground (D208)
    if bag.location_type == currentType and tostring(bag.location_id) == tostring(currentId) then return false end

    local other = loadedInventory(bag.location_type, bag.location_id)
    local ok, count = pcall(function()
        if not other or not exports.ox_inventory:GetInventory(other, false) then return nil end
        return exports.ox_inventory:Search(other, 'count', ITEM, { bagId = bag.bag_id })
    end)

    if ok and type(count) == 'number' and count > 0 then
        MySQL.update.await('UPDATE `sub_bags` SET `flagged_duplicate` = 1 WHERE `bag_id` = ?', { bag.bag_id })
        Utils.Audit('duplicacao', 'detectada', { org = bag.org, bagId = bag.bag_id, data = {
            anterior = ('%s:%s'):format(bag.location_type, bag.location_id), atual = ('%s:%s'):format(currentType, currentId) } })
        return true
    end

    if not ok or count == nil then
        Utils.Audit('sistema', 'localizacao_divergente', { org = bag.org, bagId = bag.bag_id, data = {
            registrado = ('%s:%s'):format(bag.location_type, bag.location_id), atual = ('%s:%s'):format(currentType, currentId) } })
    end
    return false
end

-- IDs de bolsas emitidas, em memória, para o hook createItem decidir sem consultar o banco
-- (hooks do ox_inventory são síncronos). Carregado ao iniciar e atualizado na emissão.
Bags.Known = {}

function Bags.LoadKnown()
    local rows = MySQL.query.await("SELECT `bag_id` FROM `sub_bags` WHERE `status` <> 'falha_emissao'") or {}
    for _, r in ipairs(rows) do Bags.Known[r.bag_id] = true end
    return #rows
end

--- Hook createItem (D191): o ox_inventory não deixa bloquear; marcamos como inválida toda
--- bolsa cujo bagId não foi emitido por nós. Um "dar item" do próprio ox_inventory recria o
--- item no destino com o mesmo bagId e passa normalmente.
local function onCreateItem(payload)
    local meta = payload.metadata or {}
    local bagId = meta.bagId

    if type(bagId) == 'string' and Bags.Known[bagId] and not meta.invalid then
        return
    end

    meta.invalid = true
    meta.label = L('item.invalid_label')
    meta.description = L('item.invalid_desc')
    meta.image = Config.DefaultItemImage

    -- Hooks do ox_inventory são síncronos: a auditoria (que espera o banco) roda à parte.
    local auditBag = type(bagId) == 'string' and bagId:sub(1, 12) or nil
    local auditData = { recurso = tostring(payload.resource), inventario = tostring(payload.inventoryId) }
    CreateThread(function()
        Utils.Audit('duplicacao', 'item_criado_fora_da_emissao', { bagId = auditBag, data = auditData })
    end)
    return meta
end

--- Hook swapItems: só registra a nova localização da bolsa (base da conferência de duplicidade,
--- D189). Nunca bloqueia a movimentação. A auditoria de retirada/transferência entra na etapa 4.
local function onSwapItems(payload)
    local item = payload.fromSlot
    local meta = type(item) == 'table' and item.metadata
    local bagId = meta and meta.bagId
    if type(bagId) ~= 'string' or not Bags.Known[bagId] then return end
    if payload.fromInventory == payload.toInventory then return end

    local toId = payload.toInventory == 'newdrop' and payload.dropId or payload.toInventory
    local locType, locId = Bags.Location(toId, payload.toType)

    -- "Em estoque" só no baú da própria organização (baús do bossmenu: <job>_stash_<n>).
    local org = type(meta.org) == 'string' and meta.org or ''
    local inOrgStash = locType == 'stash' and type(locId) == 'string' and locId:sub(1, #org + 7) == org .. '_stash_'

    MySQL.update(
        [[UPDATE `sub_bags` SET `location_type` = ?, `location_id` = ?, `last_activity_at` = NOW(), `last_activity_kind` = ?,
          `status` = ? WHERE `bag_id` = ? AND `status` <> 'falha_emissao']],
        { locType, locId, payload.action == 'give' and 'transferencia' or 'movimentacao',
          inOrgStash and 'em_estoque' or 'em_circulacao', bagId })
end

function Bags.RegisterHooks()
    local ok, err = pcall(function()
        exports.ox_inventory:registerHook('createItem', onCreateItem, { itemFilter = { [ITEM] = true } })
    end)
    if not ok then Utils.Error(L('hook.failed', 'createItem', tostring(err))) end

    ok, err = pcall(function()
        exports.ox_inventory:registerHook('swapItems', onSwapItems, { itemFilter = { [ITEM] = true } })
    end)
    if not ok then Utils.Error(L('hook.failed', 'swapItems', tostring(err))) end
end

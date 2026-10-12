-- Uso da bolsa e troca em duas fases com diário persistente (03-FLUXO §3, §4, §4.1).
-- Ordem: valida → grava diário 'iniciada' → cliente aplica → confirma → transação → salva aparência.

Change = {}

local ITEM = Config.ItemName
local pending = {} -- token -> operação em andamento (cópia em memória do diário)

local function notify(src, key, kind, ...)
    TriggerClientEvent('ox_lib:notify', src, { type = kind or 'error', description = L(key, ...) })
end

--- Restrições do personagem no servidor (D154). Veículo e água são conferidos no cliente.
local function blockedReason(src)
    local data = Utils.GetPlayerData(src)
    local meta = data and data.metadata or {}
    local state = Player(src).state
    if meta.isdead or meta.inlaststand or state.isDead or state.dead then return 'block.dead' end
    if meta.ishandcuffed then return 'block.cuffed' end
    return nil
end

Change.BlockedReason = blockedReason

--- A bolsa precisa estar no chão, perto do jogador (D208, D155). Pequena folga para o servidor.
local function bagHere(src, bagId)
    return Ground.IsNear(src, bagId, Config.MaxDistance + 0.75)
end

local function wearingRecord(citizenid)
    return MySQL.single.await('SELECT * FROM `sub_wearing` WHERE `citizenid` = ?', { citizenid })
end

local function freeSlot(slots)
    local used = {}
    for _, s in ipairs(slots) do used[s.slot_no] = true end
    for n = 1, Config.Slots do
        if not used[n] then return n end
    end
    return nil
end

local function slotByNo(slots, slotNo)
    for _, s in ipairs(slots) do
        if s.slot_no == slotNo then return s end
    end
    return nil
end

--- Uniforme que a roupa atual representa (D193 + D196): primeiro o registro "farda em uso"
--- confirmado pela comparação das peças; depois a comparação com todos os uniformes ativos.
local function currentUniformOf(citizenid, current)
    local wearing = wearingRecord(citizenid)
    if wearing then
        local variant = Uniforms.GetVariant(wearing.uniform_id, current.model)
        if variant and Clothing.MatchesUniform(current, variant) then
            return wearing.uniform_id, wearing
        end
    end
    return Uniforms.DetectUniform(current), wearing
end

------------------------------------------------------------------------------------------------
-- Abrir a bolsa
------------------------------------------------------------------------------------------------

--- Lista de compartimentos para a tela (sem as roupas em si).
function Change.SlotsView(bagId)
    local out = {}
    for _, s in ipairs(Bags.Slots(bagId)) do
        out[#out + 1] = {
            slot = s.slot_no,
            model = s.model,
            storedBy = s.stored_by_name,
            storedAt = s.stored_at,
            isUniform = s.uniform_id ~= nil,
        }
    end
    return out
end

--- Abre a tela para a bolsa que está no chão (D208). `justPlaced` = acabou de ser colocada.
function Change.OpenFromGround(src, bagId, justPlaced)
    if not Database.Ready then return notify(src, 'block.unavailable') end
    if GetResourceState('mri_Qappearance') ~= 'started' then return notify(src, 'block.appearance') end

    local bag = Bags.Get(bagId)
    local spot = Ground.Get(bagId)
    if not bag or not spot then return notify(src, 'block.unrecognized') end
    if Utils.Bool(bag.flagged_duplicate) then return notify(src, 'block.duplicate') end

    local reason = blockedReason(src)
    if reason then return notify(src, reason) end

    local ok, why = Locks.Acquire(bag.bag_id, src)
    if not ok then return notify(src, why == 'em_uso' and 'block.in_use' or 'block.already_using') end

    local uniform = Uniforms.Get(bag.uniform_id)
    local jobs = exports.qbx_core:GetJobs()
    local slotsOut = Change.SlotsView(bag.bag_id)

    TriggerClientEvent('street_uniformbag:client:open', src, {
        bagId = bag.bag_id,
        uniform = {
            name = uniform and uniform.name or '?',
            org = bag.org,
            orgLabel = jobs and jobs[bag.org] and jobs[bag.org].label or bag.org,
            models = Uniforms.ListVariantModels(bag.uniform_id),
        },
        slots = slotsOut,
        slotCount = Config.Slots,
        color = GetConvar('mri:color', Config.DefaultColor),
        maxDistance = Config.MaxDistance,
        lockRenew = Config.LockRenewSeconds,
        spot = spot,
        justPlaced = justPlaced == true,
    })
end

exports('useBag', function(event, _, inventory, slot)
    if event ~= 'usingItem' then return end
    local src = inventory and inventory.id
    if type(src) ~= 'number' then return false end
    CreateThread(function() Ground.PlaceFromSlot(src, slot) end)
    return false -- o ox_inventory não consome nem anima: o fluxo é nosso (D208)
end)

------------------------------------------------------------------------------------------------
-- Callbacks da tela
------------------------------------------------------------------------------------------------

lib.callback.register('street_uniformbag:renewLock', function(src, bagId)
    if blockedReason(src) then return false end
    return Locks.Renew(bagId, src)
end)

lib.callback.register('street_uniformbag:close', function(src, bagId)
    for token, op in pairs(pending) do
        if op.src == src and op.bagId == bagId and not op.finalizing then
            MySQL.update.await("UPDATE `sub_operations` SET `state` = 'revertida', `finished_at` = NOW(3) WHERE `token` = ? AND `state` = 'iniciada'", { token })
            pending[token] = nil
        end
    end
    return Locks.Release(bagId, src)
end)

--- Fase 1: pré-checagem e diário (D66, D182).
---@param kind 'uniforme'|'compartimento'
lib.callback.register('street_uniformbag:beginChange', function(src, bagId, kind, slotNo, rawCurrent)
    if not Database.Ready then return { error = 'block.unavailable' } end
    if type(bagId) ~= 'string' or not Locks.Holds(bagId, src) then return { error = 'block.lock_lost' } end
    if not Ground.Get(bagId) then return { error = 'block.no_bag' } end
    local reason = blockedReason(src)
    if reason then return { error = reason } end
    if not bagHere(src, bagId) then return { error = 'block.too_far' } end

    local current = Clothing.Sanitize(rawCurrent)
    if not current then return { error = 'block.appearance_invalid' } end

    local bag = Bags.Get(bagId)
    if not bag or Utils.Bool(bag.flagged_duplicate) then return { error = 'block.duplicate' } end

    local data = Utils.GetPlayerData(src)
    local uniform = Uniforms.Get(bag.uniform_id)
    local slots = Bags.Slots(bagId)
    local currentUniformId = currentUniformOf(data.citizenid, current)
    local currentIsThisUniform = currentUniformId == bag.uniform_id

    local target, storeSlot, emptySlot, targetUniformId

    if kind == 'uniforme' then
        if currentIsThisUniform then return { error = 'block.already_wearing' } end
        target = Uniforms.GetVariant(bag.uniform_id, current.model)
        if not target then return { error = 'block.no_variant' } end
        storeSlot = freeSlot(slots)
        if not storeSlot then return { error = 'block.full' } end -- D47, D192
        targetUniformId = bag.uniform_id
    elseif kind == 'compartimento' then
        local row = type(slotNo) == 'number' and slotByNo(slots, slotNo) or nil
        if not row then return { error = 'block.slot_empty' } end
        target = Clothing.Decode(row.appearance)
        if not target or target.model ~= current.model or row.model ~= current.model then
            return { error = 'block.incompatible' } -- D60–D65, D183
        end
        storeSlot = slotNo                           -- D180: troca no mesmo compartimento
        emptySlot = currentIsThisUniform             -- D48/D193: o uniforme da bolsa não ocupa compartimento
        targetUniformId = row.uniform_id             -- D184: farda guardada passa pela autorização
    else
        return { error = 'block.invalid_request' }
    end

    -- Uma operação por vez: qualquer pendência anterior do jogador é revertida.
    for oldToken, old in pairs(pending) do
        if old.src == src and not old.finalizing then
            MySQL.update.await("UPDATE `sub_operations` SET `state` = 'revertida', `finished_at` = NOW(3) WHERE `token` = ? AND `state` = 'iniciada'", { oldToken })
            pending[oldToken] = nil
        end
    end

    local token = Utils.Uuid()
    MySQL.insert.await(
        [[INSERT INTO `sub_operations` (`token`, `bag_id`, `slot_no`, `citizenid`, `kind`, `before_appearance`, `target_appearance`, `bag_version`)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)]],
        { token, bagId, storeSlot, data.citizenid, kind == 'uniforme' and 'vestir_uniforme' or 'vestir_compartimento',
          json.encode(current), json.encode(target), bag.version })

    pending[token] = {
        src = src, bagId = bagId, kind = kind, storeSlot = storeSlot, emptySlot = emptySlot,
        current = current, currentUniformId = currentUniformId, target = target,
        targetUniformId = targetUniformId, version = bag.version, uniform = uniform, bag = bag,
    }

    return { token = token, target = target }
end)

--- Fase 2: confirmação e transação (D51, D180–D184, D194).
lib.callback.register('street_uniformbag:confirmChange', function(src, token, applied)
    local op = pending[token]
    if not op or op.src ~= src then return { error = 'block.invalid_request' } end

    if applied ~= true then
        MySQL.update.await("UPDATE `sub_operations` SET `state` = 'revertida', `finished_at` = NOW(3) WHERE `token` = ? AND `state` = 'iniciada'", { token })
        pending[token] = nil
        return { reverted = true }
    end

    op.finalizing = true
    Locks.SetFinalizing(op.bagId, src, true)

    local function abort(errKey)
        MySQL.update.await("UPDATE `sub_operations` SET `state` = 'revertida', `finished_at` = NOW(3) WHERE `token` = ? AND `state` = 'iniciada'", { token })
        pending[token] = nil
        Locks.SetFinalizing(op.bagId, src, false)
        return { error = errKey, reverted = true }
    end

    if not Ground.Get(op.bagId) or not bagHere(src, op.bagId) then return abort('block.no_bag') end

    local bumped = MySQL.update.await(
        'UPDATE `sub_bags` SET `version` = `version` + 1 WHERE `bag_id` = ? AND `version` = ?', { op.bagId, op.version })
    if bumped ~= 1 then return abort('block.concurrent') end

    local data = Utils.GetPlayerData(src)
    local name = Utils.CharName(data)
    local job = data.job or {}
    local queries = {}

    -- Compartimento
    if op.emptySlot then
        queries[#queries + 1] = { query = 'DELETE FROM `sub_bag_slots` WHERE `bag_id` = ? AND `slot_no` = ?', values = { op.bagId, op.storeSlot } }
    elseif op.kind == 'uniforme' then
        queries[#queries + 1] = {
            query = [[INSERT INTO `sub_bag_slots` (`bag_id`, `slot_no`, `model`, `appearance`, `stored_by_citizenid`, `stored_by_name`, `uniform_id`)
                      VALUES (?, ?, ?, ?, ?, ?, ?)]],
            values = { op.bagId, op.storeSlot, op.current.model, json.encode(op.current), data.citizenid, name, op.currentUniformId },
        }
    else
        queries[#queries + 1] = {
            query = [[UPDATE `sub_bag_slots` SET `model` = ?, `appearance` = ?, `stored_by_citizenid` = ?, `stored_by_name` = ?,
                      `stored_at` = NOW(), `uniform_id` = ? WHERE `bag_id` = ? AND `slot_no` = ?]],
            values = { op.current.model, json.encode(op.current), data.citizenid, name, op.currentUniformId, op.bagId, op.storeSlot },
        }
    end

    -- Farda em uso
    local authorized = false
    local targetUniform = op.targetUniformId and Uniforms.Get(op.targetUniformId) or nil
    if targetUniform then
        authorized = Uniforms.IsAuthorized(src, targetUniform)
        queries[#queries + 1] = {
            query = [[INSERT INTO `sub_wearing` (`citizenid`, `bag_id`, `uniform_id`, `org`, `authorized`, `job_name`, `job_grade`, `state`, `since`)
                      VALUES (?, ?, ?, ?, ?, ?, ?, 'ativo', NOW())
                      ON DUPLICATE KEY UPDATE `bag_id` = VALUES(`bag_id`), `uniform_id` = VALUES(`uniform_id`), `org` = VALUES(`org`),
                      `authorized` = VALUES(`authorized`), `job_name` = VALUES(`job_name`), `job_grade` = VALUES(`job_grade`),
                      `state` = 'ativo', `since` = NOW(), `last_check_at` = NULL]],
            values = { data.citizenid, op.bagId, targetUniform.id, targetUniform.org, authorized and 1 or 0, job.name or '?', Utils.JobGrade(job) or 0 },
        }
    else
        queries[#queries + 1] = { query = 'DELETE FROM `sub_wearing` WHERE `citizenid` = ?', values = { data.citizenid } }
    end

    -- Diário
    queries[#queries + 1] = {
        query = "UPDATE `sub_operations` SET `state` = 'concluida', `finished_at` = NOW(3) WHERE `token` = ? AND `state` = 'iniciada'",
        values = { token },
    }

    local ok = MySQL.transaction.await(queries)
    if not ok then
        Utils.Error(L('change.transaction_failed', token))
        return abort('block.save_failed')
    end

    pending[token] = nil

    Utils.Audit('troca', op.kind == 'uniforme' and 'vestiu_uniforme' or 'vestiu_compartimento', {
        src = src, org = op.bag.org, bagId = op.bagId, uniformId = op.bag.uniform_id,
        data = { compartimento = op.storeSlot, esvaziado = op.emptySlot or false, farda_vestida = op.targetUniformId, farda_guardada = op.currentUniformId, autorizado = authorized },
    })

    if targetUniform and not authorized then
        Alerts.Raise('vestir', src, op.bag, targetUniform, op.bagId .. ':' .. data.citizenid .. ':' .. token, nil,
            ('%s:%s'):format(job.name or '?', tostring(Utils.JobGrade(job))))
    end

    -- Depois da troca o painel fecha; a bolsa continua no chão até alguém recolher (D208).
    Bags.TouchActivity(op.bagId, 'uso', 'chao', op.bagId)
    Locks.Release(op.bagId, src, true)
    return { ok = true, slots = Change.SlotsView(op.bagId) }
end)

--- Roupa para a prévia (D204): só para quem está com a bolsa travada e no próprio modelo.
lib.callback.register('street_uniformbag:previewData', function(src, bagId, kind, slotNo, model)
    if type(bagId) ~= 'string' or not Locks.Holds(bagId, src) then return nil end
    if type(model) ~= 'string' or not Clothing.IsSupportedModel(model) then return nil end
    local bag = Bags.Get(bagId)
    if not bag then return nil end

    if kind == 'uniforme' then
        return Uniforms.GetVariant(bag.uniform_id, model)
    end

    if kind == 'compartimento' and type(slotNo) == 'number' then
        local row = slotByNo(Bags.Slots(bagId), slotNo)
        local clothing = row and Clothing.Decode(row.appearance)
        if clothing and clothing.model == model then return clothing end
    end
    return nil
end)

------------------------------------------------------------------------------------------------
-- Recuperação de operações interrompidas (FLUXO §4.1, D182, D197)
------------------------------------------------------------------------------------------------

function Change.RevertInterrupted()
    local affected = MySQL.update.await("UPDATE `sub_operations` SET `state` = 'revertida', `finished_at` = NOW(3) WHERE `state` = 'iniciada'") or 0
    if affected > 0 then Utils.Warn(L('recovery.reverted', affected)) end
end

--- Chamado pelo cliente depois que o personagem e a aparência carregam.
lib.callback.register('street_uniformbag:recoveryCheck', function(src)
    local data = Utils.GetPlayerData(src)
    if not data then return nil end

    local op = MySQL.single.await(
        [[SELECT `token`, `state`, `before_appearance`, `target_appearance` FROM `sub_operations`
          WHERE `citizenid` = ? AND ((`state` = 'concluida' AND `saved_at` IS NULL) OR (`state` = 'revertida' AND `restored_at` IS NULL))
          ORDER BY `created_at` DESC LIMIT 1]], { data.citizenid })
    if not op then return nil end

    -- Operações mais antigas ficam superadas pela mais recente.
    MySQL.update.await(
        "UPDATE `sub_operations` SET `restored_at` = NOW(3) WHERE `citizenid` = ? AND `state` = 'revertida' AND `restored_at` IS NULL",
        { data.citizenid })

    if op.state == 'revertida' then
        Utils.Audit('troca', 'recuperacao_reverteu', { src = src, data = { operacao = op.token } })
        return { clothing = Clothing.Decode(op.before_appearance) }
    end

    Utils.Audit('troca', 'recuperacao_reaplicou', { src = src, data = { operacao = op.token } })
    return { clothing = Clothing.Decode(op.target_appearance) }
end)

-- Salvamento de aparência pelo caminho da base (D138, D197): marca a conclusão como salva.
RegisterNetEvent('illenium-appearance:server:saveAppearance', function()
    local src = source
    local data = Utils.GetPlayerData(src)
    if not data then return end
    MySQL.update(
        "UPDATE `sub_operations` SET `saved_at` = NOW(3) WHERE `citizenid` = ? AND `state` = 'concluida' AND `saved_at` IS NULL",
        { data.citizenid })
end)

AddEventHandler('playerDropped', function()
    local src = source
    for token, op in pairs(pending) do
        if op.src == src and not op.finalizing then
            MySQL.update("UPDATE `sub_operations` SET `state` = 'revertida', `finished_at` = NOW(3) WHERE `token` = ? AND `state` = 'iniciada'", { token })
            pending[token] = nil
        end
    end
    Locks.OnDrop(src)
end)

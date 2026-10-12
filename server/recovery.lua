-- Recuperação administrativa excepcional (D7, D146–D153, D159).
-- A staff registra a roupa a devolver (motivo obrigatório); nada muda até o próprio jogador
-- confirmar "Restaurar agora". Uso só para falhas técnicas, nunca para roubo/RP (D152).

Recovery = {}

local function isAdmin(src)
    local p = Permissions.GetProfile(src, nil)
    return p == 'staff' or p == 'emergencia'
end

--- Busca personagens (online ou offline) por citizenid ou nome — só leitura da tabela do QBox.
lib.callback.register('vel_uniformbag:panel:findCharacter', function(src, query)
    if not isAdmin(src) then return { error = 'cmd.no_permission' } end
    if type(query) ~= 'string' or #query < 2 or #query > 60 then return { results = {} } end
    local like = '%' .. query:gsub('[%%_]', '') .. '%'
    local rows = MySQL.query.await(
        [[SELECT `citizenid`, JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.firstname')) AS firstname,
                 JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.lastname')) AS lastname
          FROM `players`
          WHERE `citizenid` LIKE ? OR CONCAT(JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.firstname')), ' ',
                JSON_UNQUOTE(JSON_EXTRACT(`charinfo`, '$.lastname'))) LIKE ?
          LIMIT 20]], { like, like }) or {}
    return { results = rows }
end)

--- Roupas que podem ser devolvidas a um personagem: o que ele vestia antes de cada troca pela bolsa
--- (diário de operações) e o que está nos compartimentos guardados por ele.
lib.callback.register('vel_uniformbag:panel:recoverySources', function(src, citizenid)
    if not isAdmin(src) then return { error = 'cmd.no_permission' } end
    if type(citizenid) ~= 'string' or #citizenid > 60 then return { sources = {} } end

    local sources = {}
    local ops = MySQL.query.await(
        [[SELECT `token`, `bag_id`, `kind`, `state`, `created_at` FROM `sub_operations`
          WHERE `citizenid` = ? ORDER BY `created_at` DESC LIMIT 20]], { citizenid }) or {}
    for _, o in ipairs(ops) do
        sources[#sources + 1] = { type = 'operacao', id = o.token, label = L('recovery.source_op', o.bag_id, o.kind, o.state), at = o.created_at }
    end

    local slots = MySQL.query.await(
        'SELECT `bag_id`, `slot_no`, `stored_at` FROM `sub_bag_slots` WHERE `stored_by_citizenid` = ? ORDER BY `stored_at` DESC LIMIT 20',
        { citizenid }) or {}
    for _, s in ipairs(slots) do
        sources[#sources + 1] = { type = 'compartimento', id = ('%s:%s'):format(s.bag_id, s.slot_no), label = L('recovery.source_slot', s.bag_id, s.slot_no), at = s.stored_at }
    end

    local list = MySQL.query.await(
        'SELECT `id`, `status`, `reason`, `created_by`, `created_at`, `applied_at` FROM `sub_recoveries` WHERE `citizenid` = ? ORDER BY `id` DESC LIMIT 20',
        { citizenid }) or {}
    return { sources = sources, recoveries = list }
end)

local function sourceAppearance(sourceType, sourceId, citizenid)
    if sourceType == 'operacao' then
        local row = MySQL.single.await('SELECT `before_appearance` FROM `sub_operations` WHERE `token` = ? AND `citizenid` = ?', { sourceId, citizenid })
        return row and Clothing.Decode(row.before_appearance)
    end
    if sourceType == 'compartimento' then
        local bagId, slotNo = tostring(sourceId):match('^([%w%-]+):(%d+)$')
        local row = bagId and MySQL.single.await(
            'SELECT `appearance` FROM `sub_bag_slots` WHERE `bag_id` = ? AND `slot_no` = ? AND `stored_by_citizenid` = ?',
            { bagId, tonumber(slotNo), citizenid })
        return row and Clothing.Decode(row.appearance)
    end
    return nil
end

lib.callback.register('vel_uniformbag:panel:createRecovery', function(src, citizenid, sourceType, sourceId, reason)
    if not isAdmin(src) then return { error = 'cmd.no_permission' } end
    if type(reason) ~= 'string' or #reason:gsub('%s', '') < 10 or #reason > 500 then return { error = 'recovery.reason_required' } end

    local clothing = sourceAppearance(sourceType, sourceId, citizenid)
    if not clothing or not clothing.model then return { error = 'recovery.source_invalid' } end

    local data = Utils.GetPlayerData(src)
    local id = MySQL.insert.await(
        'INSERT INTO `sub_recoveries` (`citizenid`, `model`, `appearance`, `reason`, `created_by`) VALUES (?, ?, ?, ?, ?)',
        { citizenid, clothing.model, json.encode(clothing), reason, data and data.citizenid or '?' })

    Utils.Audit('recuperacao', 'registrada', { src = src, data = { recuperacao = id, beneficiado = citizenid, origem = sourceType, motivo = reason } })

    -- Se o personagem estiver online, o aviso aparece na hora (D149).
    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if target then TriggerClientEvent('vel_uniformbag:client:recoveryPending', target.PlayerData.source) end
    return { ok = true, id = id }
end)

lib.callback.register('vel_uniformbag:panel:cancelRecovery', function(src, id)
    if not isAdmin(src) then return { error = 'cmd.no_permission' } end
    local changed = MySQL.update.await("UPDATE `sub_recoveries` SET `status` = 'cancelada' WHERE `id` = ? AND `status` = 'aguardando'", { tonumber(id) })
    if changed ~= 1 then return { error = 'recovery.not_pending' } end
    Utils.Audit('recuperacao', 'cancelada', { src = src, data = { recuperacao = id } })
    return { ok = true }
end)

------------------------------------------------------------------------------------------------
-- Lado do jogador (D149–D151, D159): só o próprio personagem, sempre com confirmação.
------------------------------------------------------------------------------------------------

lib.callback.register('vel_uniformbag:recoveryPending', function(src)
    local data = Utils.GetPlayerData(src)
    if not data then return nil end
    return MySQL.single.await(
        "SELECT `id`, `reason`, `created_at`, `model` FROM `sub_recoveries` WHERE `citizenid` = ? AND `status` = 'aguardando' ORDER BY `id` LIMIT 1",
        { data.citizenid })
end)

--- Entrega a roupa só ao dono da recuperação pendente.
lib.callback.register('vel_uniformbag:recoveryFetch', function(src, id)
    local data = Utils.GetPlayerData(src)
    if not data then return nil end
    local row = MySQL.single.await(
        "SELECT `appearance` FROM `sub_recoveries` WHERE `id` = ? AND `citizenid` = ? AND `status` = 'aguardando'",
        { tonumber(id), data.citizenid })
    return row and Clothing.Decode(row.appearance)
end)

--- Conclusão: só quando o cliente confirma que aplicou; impede aplicação duplicada (D150, D151).
lib.callback.register('vel_uniformbag:recoveryConfirm', function(src, id, rawPrevious)
    local data = Utils.GetPlayerData(src)
    if not data then return false end
    local previous = Clothing.Sanitize(rawPrevious)
    local changed = MySQL.update.await(
        [[UPDATE `sub_recoveries` SET `status` = 'concluida', `applied_at` = NOW(), `previous_appearance` = ?
          WHERE `id` = ? AND `citizenid` = ? AND `status` = 'aguardando']],
        { previous and json.encode(previous) or nil, tonumber(id), data.citizenid })
    if changed ~= 1 then return false end

    -- A farda em uso deixa de valer: a roupa agora é a recuperada (D153).
    MySQL.update.await('DELETE FROM `sub_wearing` WHERE `citizenid` = ?', { data.citizenid })
    Utils.Audit('recuperacao', 'concluida', { src = src, data = { recuperacao = id } })
    return true
end)

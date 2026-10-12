-- Emissão em lote para o baú da organização (D24–D33, D115, D157).
-- As bolsas entram no baú como pilha de estoque por uniforme (D213); o lote registra quantas
-- foram entregues. O ID individual nasce no primeiro uso.

Issue = {}

--- Emite `qty` bolsas do uniforme no baú `stashId`.
---@return table|nil result { requested, delivered, failed, batchId }, string|nil errorKey
function Issue.Run(src, uniformId, qty, stashId)
    local uniform = Uniforms.Get(uniformId)
    if not uniform or not Utils.Bool(uniform.active) then return nil, 'cmd.uniform_unknown' end

    local profile = Permissions.GetProfile(src, uniform.org)
    if not profile then return nil, 'cmd.no_permission' end

    qty = math.floor(tonumber(qty) or 0)
    if qty < 1 or qty > Config.MaxBagsPerBatch then return nil, 'cmd.qty_invalid' end

    if type(stashId) ~= 'string' or #stashId == 0 or #stashId > 80 then return nil, 'cmd.stash_invalid' end
    if not exports.ox_inventory:GetInventory(stashId, false) then return nil, 'cmd.stash_invalid' end

    -- Baú só masculino/feminino aceita só uniforme com a versão daquele modelo (D217).
    local required = StashRules and StashRules.Get(stashId)
    if required and not Uniforms.GetVariant(uniform.id, required) then
        return nil, required == 'mp_f_freemode_01' and 'cmd.stash_needs_female' or 'cmd.stash_needs_male'
    end

    local data = Utils.GetPlayerData(src)
    local author = data and data.citizenid or 'console'
    local key = Utils.Uuid()

    local batchId = MySQL.insert.await(
        [[INSERT INTO `sub_issue_batches` (`idempotency_key`, `org`, `uniform_id`, `stash_id`, `requested`, `requested_by`)
          VALUES (?, ?, ?, ?, ?, ?)]], { key, uniform.org, uniform.id, stashId, qty, author })

    -- D213: as bolsas entram como UMA pilha de estoque do uniforme, ainda sem ID; cada uma
    -- ganha ID e registro no primeiro uso (Ground.PlaceFromSlot).
    Bags.StockUniforms[uniform.id] = uniform.org
    local metadata = Bags.StockMetadata(uniform)
    local delivered, failed = 0, qty
    if exports.ox_inventory:CanCarryItem(stashId, Config.ItemName, qty, metadata) then
        if exports.ox_inventory:AddItem(stashId, Config.ItemName, qty, metadata) then
            delivered, failed = qty, 0
            Bags.UniformStashes[stashId] = true
        end
    end

    local status = failed == 0 and 'concluido' or (delivered == 0 and 'falhou' or 'parcial')
    MySQL.update.await(
        'UPDATE `sub_issue_batches` SET `delivered` = ?, `failed` = ?, `status` = ?, `finished_at` = NOW() WHERE `id` = ?',
        { delivered, failed, status, batchId })

    Utils.Audit('emissao', 'lote_' .. status, {
        src = src, org = uniform.org, uniformId = uniform.id,
        data = { lote = batchId, pedidas = qty, entregues = delivered, falhas = failed, bau = stashId, perfil = profile },
    })

    return { requested = qty, delivered = delivered, failed = failed, batchId = batchId }
end

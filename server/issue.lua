-- Emissão em lote para o baú da organização (D24–D33, D115, D157).
-- Cada bolsa é gravada no banco ANTES de virar item; falha no AddItem marca `falha_emissao`
-- e nenhum item órfão fica para trás.

Issue = {}

local function generateBagId()
    for _ = 1, 10 do
        local id = Utils.NewBagId()
        if not Bags.Known[id] and not MySQL.scalar.await('SELECT 1 FROM `sub_bags` WHERE `bag_id` = ?', { id }) then
            return id
        end
    end
    return nil
end

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

    local data = Utils.GetPlayerData(src)
    local author = data and data.citizenid or 'console'
    local key = Utils.Uuid()

    local batchId = MySQL.insert.await(
        [[INSERT INTO `sub_issue_batches` (`idempotency_key`, `org`, `uniform_id`, `stash_id`, `requested`, `requested_by`)
          VALUES (?, ?, ?, ?, ?, ?)]], { key, uniform.org, uniform.id, stashId, qty, author })

    local delivered, failed = 0, 0

    for _ = 1, qty do
        local bagId = generateBagId()
        local ok = false

        if bagId then
            MySQL.insert.await(
                [[INSERT INTO `sub_bags` (`bag_id`, `uniform_id`, `org`, `batch_id`, `status`, `location_type`, `location_id`, `issued_by`, `last_activity_kind`)
                  VALUES (?, ?, ?, ?, 'em_estoque', 'stash', ?, ?, 'emissao')]],
                { bagId, uniform.id, uniform.org, batchId, stashId, author })

            Bags.Known[bagId] = true
            local bag = Bags.Get(bagId)
            local metadata = Bags.BuildMetadata(bag, uniform)

            if exports.ox_inventory:CanCarryItem(stashId, Config.ItemName, 1, metadata) then
                ok = exports.ox_inventory:AddItem(stashId, Config.ItemName, 1, metadata) and true or false
            end

            if not ok then
                Bags.Known[bagId] = nil
                MySQL.update.await("UPDATE `sub_bags` SET `status` = 'falha_emissao' WHERE `bag_id` = ?", { bagId })
            end
        end

        if ok then delivered = delivered + 1 else failed = failed + 1 end
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

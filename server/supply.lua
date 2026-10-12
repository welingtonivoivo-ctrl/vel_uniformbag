-- Abastecimento infinito dos baús de uniformes (D222). Cada uniforme ativo aparece sempre com
-- UMA bolsa no baú "Só feminino" ou "Só masculino" da sua organização, conforme a versão gravada
-- (feminina → baú só feminino; masculina → baú só masculino). Ao retirar, a bolsa é reposta.
-- Excluir/desativar o uniforme, remover a versão ou mudar a regra do baú tira a bolsa do baú.
-- Não há quantidade nem lote: o ID individual continua nascendo no primeiro uso (D213).

Supply = {}

local ITEM = Config.ItemName
local RULE_MODELS = { mp_m_freemode_01 = true, mp_f_freemode_01 = true }

--- Baús da organização cadastrados no mri_Qbossmenu (com posição, quando houver).
function Supply.OrgStashes(org)
    local list = {}
    if GetResourceState('mri_Qbossmenu') ~= 'started' then return list end
    local ok, def = pcall(function() return exports.mri_Qbossmenu:GetManagedDefinition(org, 'job') end)
    if not ok or type(def) ~= 'table' then return list end
    local stashes = def.stashes or (def.definition and def.definition.stashes) or {}
    for _, s in ipairs(stashes) do
        if type(s) == 'table' and type(s.id) == 'string' then
            local c = type(s.coords) == 'table' and s.coords or nil
            local x, y, z = c and tonumber(c.x), c and tonumber(c.y), c and tonumber(c.z)
            local hasCoords = x and y and z and not (x == 0 and y == 0 and z == 0)
            list[#list + 1] = { id = s.id, label = s.label or s.id, coords = hasCoords and { x = x, y = y, z = z } or nil }
        end
    end
    return list
end

--- Uniformes ativos da organização com os modelos que têm versão gravada.
local function activeUniforms(org)
    local rows = MySQL.query.await('SELECT `id`, `org`, `name` FROM `sub_uniforms` WHERE `org` = ? AND `active` = 1', { org }) or {}
    for _, u in ipairs(rows) do
        u.models = {}
        for _, m in ipairs(Uniforms.ListVariantModels(u.id)) do u.models[m] = true end
        Bags.StockUniforms[u.id] = u.org
    end
    return rows
end

--- Deixa o baú com exatamente uma bolsa de cada uniforme desejado e nenhuma dos outros.
---@param wanted table<number, table> uniformId -> uniform
local function syncStash(stashId, wanted)
    local items = exports.ox_inventory:GetInventoryItems(stashId)
    if not items then return false end

    local seen = {}
    for slot, it in pairs(items) do
        local meta = it.name == ITEM and it.metadata or nil
        if meta and meta.stock == true and meta.bagId == nil then
            local uid = tonumber(meta.uniformId)
            if not wanted[uid] or seen[uid] then
                exports.ox_inventory:RemoveItem(stashId, ITEM, it.count, nil, slot)
            else
                seen[uid] = true
                if it.count > 1 then exports.ox_inventory:RemoveItem(stashId, ITEM, it.count - 1, nil, slot) end
                local want = Bags.StockMetadata(wanted[uid])
                if meta.label ~= want.label or meta.image ~= want.image or meta.description ~= want.description then
                    exports.ox_inventory:SetMetadata(stashId, slot, want)
                end
            end
        end
    end

    for uid, uniform in pairs(wanted) do
        if not seen[uid] then exports.ox_inventory:AddItem(stashId, ITEM, 1, Bags.StockMetadata(uniform)) end
    end
    return true
end

local syncing = {}

--- Sincroniza todos os baús de uniformes da organização.
function Supply.SyncOrg(org)
    if type(org) ~= 'string' or syncing[org] then return end
    syncing[org] = true
    local ok, err = pcall(function()
        local uniforms = activeUniforms(org)
        for _, stash in ipairs(Supply.OrgStashes(org)) do
            local rule = StashRules and StashRules.Get(stash.id)
            if RULE_MODELS[rule] then
                local wanted = {}
                for _, u in ipairs(uniforms) do if u.models[rule] then wanted[u.id] = u end end
                syncStash(stash.id, wanted)
            elseif Bags.UniformStashes[stash.id] then
                syncStash(stash.id, {}) -- baú que recebia emissões antigas: tira as pilhas de estoque
            end
        end
    end)
    syncing[org] = nil
    if not ok then Utils.Error(('Abastecimento de %s falhou: %s'):format(org, tostring(err))) end
end

function Supply.SyncOrgAsync(org)
    CreateThread(function() Supply.SyncOrg(org) end)
end

function Supply.SyncAll()
    local jobs = exports.qbx_core:GetJobs() or {}
    for name in pairs(jobs) do
        if name ~= 'unemployed' then Supply.SyncOrg(name) end
    end
end

-- Baús só para um modelo de personagem (D215): o líder ou a staff marca, no painel, um baú da
-- organização como só masculino ou só feminino. O bloqueio usa o gancho público `openInventory`
-- do ox_inventory; nada do mri_Qbossmenu nem do ox_inventory é alterado. A regra fica no KVP do
-- recurso (sem tabela nova).

StashRules = {}

local MODELS = { mp_m_freemode_01 = true, mp_f_freemode_01 = true }
local PREFIX = 'stash_model:'

---@return string|nil model 'mp_m_freemode_01' | 'mp_f_freemode_01' | nil (todos)
function StashRules.Get(stashId)
    if type(stashId) ~= 'string' then return nil end
    local value = GetResourceKvpString(PREFIX .. stashId)
    return MODELS[value] and value or nil
end

function StashRules.Set(stashId, model)
    if MODELS[model] then
        SetResourceKvp(PREFIX .. stashId, model)
    else
        DeleteResourceKvp(PREFIX .. stashId)
    end
end

local function playerModel(src)
    local hash = GetEntityModel(GetPlayerPed(src)) & 0xFFFFFFFF
    for name in pairs(MODELS) do
        if hash == joaat(name) & 0xFFFFFFFF then return name end
    end
    return nil
end

local function onOpenInventory(payload)
    if payload.inventoryType ~= 'stash' then return end
    local required = StashRules.Get(payload.inventoryId)
    if not required or playerModel(payload.source) == required then return end

    TriggerClientEvent('ox_lib:notify', payload.source, {
        type = 'error',
        description = L(required == 'mp_f_freemode_01' and 'stash.only_female' or 'stash.only_male'),
    })
    return false
end

function StashRules.RegisterHook()
    local ok, err = pcall(function()
        exports.ox_inventory:registerHook('openInventory', onOpenInventory)
    end)
    if not ok then Utils.Error(L('hook.failed', 'openInventory', tostring(err))) end
end

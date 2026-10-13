-- Painel de gestão no cliente: abre a NUI e repassa as chamadas ao servidor (que decide tudo).

local panelOpen = false
local embedded = false -- true quando o painel está dentro da aba Plugins do mri_Qadmin

-- Só estas funções do servidor podem ser chamadas pela NUI do painel.
local ALLOWED = {
    uniforms = true, saveUniform = true, captureVariant = true, removeVariant = true, deleteUniform = true,
    stashes = true, bags = true, bagHistory = true,
    alertSettings = true, saveAlertSettings = true, audit = true,
    findCharacter = true, recoverySources = true, createRecovery = true, cancelRecovery = true,
    points = true, addPoint = true, togglePoint = true, stashRules = true, setStashRule = true, clearStash = true, teleportStash = true, createUStash = true, deleteUStash = true,
}

local function panelLocale()
    local keys = {
        'title', 'tab_uniforms', 'tab_issue', 'tab_bags', 'org', 'close', 'new_uniform', 'edit', 'save', 'cancel',
        'name', 'mode', 'mode_list', 'mode_range', 'higher_ranks', 'grades', 'grade_min', 'grade_max', 'no_max',
        'active', 'inactive', 'versions', 'male', 'female', 'capture', 'capture_hint', 'remove', 'missing',
        'open_store', 'store_hint', 'bags_count', 'empty_uniforms', 'guide', 'uniform', 'quantity', 'stash',
        'no_stash', 'issue_btn', 'issued', 'status', 'all', 'in_stock', 'circulating', 'unknown', 'ground',
        'duplicated', 'search', 'bag_id', 'location', 'last_activity', 'history', 'slots', 'empty', 'authorized_for',
        'saved', 'captured', 'confirm_remove', 'loading', 'no_bags', 'filter',
        'tab_alerts', 'tab_audit', 'tab_recovery', 'alert_enabled', 'alert_mode', 'mode_psdispatch', 'mode_jobnotify',
        'mode_both', 'job_types', 'job_types_hint', 'job_names', 'job_names_hint', 'onduty_only', 'blip_seconds',
        'alert_code', 'item_image', 'item_image_hint', 'default_stash', 'psdispatch_off', 'category', 'actor',
        'previous', 'next', 'when', 'action', 'details', 'find_char', 'find_hint', 'sources', 'reason',
        'reason_hint', 'register', 'pending', 'cancel_rec', 'no_results', 'recovery_note', 'choose_source',
        'tab_points', 'points_hint', 'point_label', 'point_placeholder', 'point_add', 'points_staff_only',
        'activate', 'deactivate', 'discord', 'webhook_on', 'webhook_off', 'webhook_org', 'webhook_admin', 'discord_hint',
        'capture_male', 'capture_female', 'you_are', 'need_male', 'need_female', 'delete_uniform', 'delete_hint',
        'confirm_delete', 'deleted', 'deleted_deactivated', 'tab_stashes', 'stash_rules_hint', 'who_opens', 'rule_all', 'rule_male', 'rule_female', 'clear_stash', 'clear_hint', 'confirm_clear', 'cleared', 'teleport',
        'ustash_create_title', 'ustash_hint', 'ustash_placeholder', 'ustash_type', 'ustash_create', 'ustash_title',
        'ustash_delete', 'stash_bossmenu', 'ustash_name', 'ustash_edit_area', 'ustash_draw_area', 'ustash_convert',
        'ustash_convert_hint', 'ustash_convert_need_rule',
    }
    local t = {}
    for _, k in ipairs(keys) do t[k] = L('panel.' .. k) end
    return t
end

--- Última organização e aba usadas por esta pessoa, guardadas no próprio jogo dela (D219).
local function lastView()
    return { org = GetResourceKvpString('panel_org'), tab = GetResourceKvpString('panel_tab') }
end

RegisterNUICallback('panelRemember', function(body, cb)
    cb(true)
    if type(body) ~= 'table' then return end
    if type(body.org) == 'string' and #body.org <= 60 then SetResourceKvp('panel_org', body.org) end
    if type(body.tab) == 'string' and #body.tab <= 20 then SetResourceKvp('panel_tab', body.tab) end
end)

RegisterNetEvent('vel_uniformbag:client:panelOpen', function(data)
    if (panelOpen and not embedded) or Bag.IsOpen() then return end
    embedded = false
    panelOpen = true
    SendNUIMessage({ action = 'panelOpen', data = data, locale = panelLocale(), last = lastView() })
    SetNuiFocus(true, true)
end)

local function closePanel()
    panelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'panelClose' })
end

RegisterNUICallback('panelClose', function(_, cb)
    cb(true)
    if embedded then
        embedded = false
        panelOpen = false
        pcall(function() exports.mri_Qadmin:ClosePlugin() end)
        return
    end
    closePanel()
end)

-- Página embutida no mri_Qadmin pede os dados iniciais (o mri_Qadmin cuida do foco da tela).
RegisterNUICallback('panelBootstrap', function(_, cb)
    local data = lib.callback.await('vel_uniformbag:panel:bootstrap', false)
    if not data or data.error then
        return cb({ error = data and data.error or 'panel.no_access', message = L(data and data.error or 'panel.no_access') })
    end
    embedded = true
    panelOpen = true
    cb({ data = data, locale = panelLocale(), last = lastView() })
end)

RegisterNUICallback('panel', function(body, cb)
    if not panelOpen or type(body) ~= 'table' or not ALLOWED[body.fn] then return cb({ error = 'block.invalid_request' }) end
    local args = type(body.args) == 'table' and body.args or {}
    local result = lib.callback.await('vel_uniformbag:panel:' .. body.fn, false, table.unpack(args, 1, 4))
    if type(result) == 'table' and result.error then
        result.message = L(result.error)
    end
    cb(result or { error = 'block.invalid_request', message = L('block.invalid_request') })
end)

--- Menu normal das lojas de roupa do mri_Qappearance, com o preço das lojas (D211).
--- O painel fecha; depois de montar a farda, a pessoa abre o painel de novo para gravar a versão.
RegisterNUICallback('openStore', function(_, cb)
    cb(true)
    if not lib.callback.await('vel_uniformbag:panel:canOpenStore', false) then return end

    if embedded then
        embedded = false
        panelOpen = false
        pcall(function() exports.mri_Qadmin:ClosePlugin() end)
    else
        closePanel()
    end
    Wait(300)
    TriggerEvent('illenium-appearance:client:openClothingShopMenu', false)
end)

--- Criar baú de uniformes desenhando a área no chão (D224). O painel fecha durante o desenho e
--- volta depois, no mesmo modo em que estava.
RegisterNUICallback('drawUStash', function(body, cb)
    cb(true)
    if type(body) ~= 'table' then return end
    local wasEmbedded = embedded
    if embedded then
        embedded = false
        panelOpen = false
        pcall(function() exports.mri_Qadmin:ClosePlugin() end)
    else
        closePanel()
    end
    Wait(300)

    local area = DrawStashArea()
    if area then
        local res
        if body.editId then
            res = lib.callback.await('vel_uniformbag:panel:editUStashArea', false, body.org, body.editId, area)
        else
            res = lib.callback.await('vel_uniformbag:panel:createUStash', false, body.org, body.label, body.model, area, body.fromStash)
        end
        if type(res) == 'table' and res.error then
            lib.notify({ type = 'error', description = L(res.error) })
        else
            lib.notify({ type = 'success', description = L(body.editId and 'panel.ustash_area_saved' or 'panel.ustash_created') })
        end
    end

    Wait(200)
    if wasEmbedded then
        pcall(function() exports.mri_Qadmin:OpenPlugin('vel_uniformbag') end)
    else
        ExecuteCommand('adminoutfit')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and panelOpen then SetNuiFocus(false, false) end
end)

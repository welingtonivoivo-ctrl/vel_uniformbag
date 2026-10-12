-- Painel de gestão no cliente: abre a NUI e repassa as chamadas ao servidor (que decide tudo).

local panelOpen = false

-- Só estas funções do servidor podem ser chamadas pela NUI do painel.
local ALLOWED = {
    uniforms = true, saveUniform = true, captureVariant = true, removeVariant = true,
    stashes = true, issue = true, bags = true, bagHistory = true,
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
    }
    local t = {}
    for _, k in ipairs(keys) do t[k] = L('panel.' .. k) end
    return t
end

RegisterNetEvent('street_uniformbag:client:panelOpen', function(data)
    if panelOpen or Bag.IsOpen() then return end
    panelOpen = true
    SendNUIMessage({ action = 'panelOpen', data = data, locale = panelLocale() })
    SetNuiFocus(true, true)
end)

local function closePanel()
    panelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'panelClose' })
end

RegisterNUICallback('panelClose', function(_, cb)
    cb(true)
    closePanel()
end)

RegisterNUICallback('panel', function(body, cb)
    if not panelOpen or type(body) ~= 'table' or not ALLOWED[body.fn] then return cb({ error = 'block.invalid_request' }) end
    local args = type(body.args) == 'table' and body.args or {}
    local result = lib.callback.await('street_uniformbag:panel:' .. body.fn, false, table.unpack(args, 1, 4))
    if type(result) == 'table' and result.error then
        result.message = L(result.error)
    end
    cb(result or { error = 'block.invalid_request', message = L('block.invalid_request') })
end)

--- Loja de roupas gratuita, só roupas e acessórios (D206).
RegisterNUICallback('openStore', function(_, cb)
    cb(true)
    if not lib.callback.await('street_uniformbag:panel:canOpenStore', false) then return end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'panelHide' })

    local all = { masks = true, upperBody = true, lowerBody = true, bags = true, shoes = true,
        scarfAndChains = true, bodyArmor = true, shirts = true, decals = true, jackets = true }
    local props = { hats = true, glasses = true, ear = true, watches = true, bracelets = true }

    exports.mri_Qappearance:startPlayerCustomization(function(appearance)
        if appearance then
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
        if panelOpen then
            SendNUIMessage({ action = 'panelShow' })
            SetNuiFocus(true, true)
        end
    end, {
        ped = false, headBlend = false, faceFeatures = false, headOverlays = false, tattoos = false,
        components = true, componentConfig = all, props = true, propConfig = props,
        enableExit = true, hasTracker = false, automaticFade = false,
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and panelOpen then SetNuiFocus(false, false) end
end)

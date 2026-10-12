-- Inicialização: verifica dependências e integrações, aplica a migração do banco
-- (só tabelas sub_*) e registra a permissão de staff no mri_Qadmin.

local RESOURCE = GetCurrentResourceName()
local PREFIX = '^5[vel_uniformbag]^7 '

local function log(msg)
    print(PREFIX .. msg)
end

local REQUIRED = { 'ox_lib', 'oxmysql', 'qbx_core', 'ox_inventory', 'mri_Qappearance' }

-- Opcionais: sem elas o recurso sobe; só a funcionalidade relacionada fica desativada.
local OPTIONAL = { 'mri_Qadmin', 'ps-dispatch', 'mri_Qbossmenu', 'mri_Qinteract', 'ars_ambulancejob' }

local function resourceVersion(name)
    return GetResourceMetadata(name, 'version', 0) or '?'
end

local function checkDependencies()
    local allRequired = true

    for _, name in ipairs(REQUIRED) do
        local state = GetResourceState(name)
        if state == 'started' then
            log(L('startup.dep_ok', name, resourceVersion(name)))
        else
            allRequired = false
            log('^1' .. L('startup.dep_missing', name, state) .. '^7')
        end
    end

    for _, name in ipairs(OPTIONAL) do
        local state = GetResourceState(name)
        if state == 'started' then
            log(L('startup.opt_ok', name, resourceVersion(name)))
        else
            log('^3' .. L('startup.opt_missing', name, state) .. '^7')
        end
    end

    return allRequired
end

local function checkItem()
    local ok, item = pcall(function()
        return exports.ox_inventory:Items(Config.ItemName)
    end)

    if ok and item then
        log(L('startup.item_ok', Config.ItemName))
    else
        log('^3' .. L('startup.item_missing', Config.ItemName) .. '^7')
    end
end

local function checkColor()
    local color = GetConvar('mri:color', '')
    if color:match('^#%x%x%x%x%x%x$') then
        log(L('startup.color', color, 'convar mri:color'))
    else
        log(L('startup.color', Config.DefaultColor, 'padrão do recurso'))
    end
end

-- Resultado da verificação do modelo da bolsa feita no cliente (verificação V1 do plano).
-- Só registra no console; um relatório por jogador a cada início do recurso.
local propReported = {}

RegisterNetEvent('vel_uniformbag:server:propCheck', function(inCdImage, isValid, loaded)
    local src = source
    if propReported[src] then return end
    propReported[src] = true
    if type(inCdImage) ~= 'boolean' or type(isValid) ~= 'boolean' or type(loaded) ~= 'boolean' then
        log(('^3Relatório do modelo recebido em formato inesperado (cliente %s): %s, %s, %s^7'):format(src, type(inCdImage), type(isValid), type(loaded)))
        return
    end

    local key = (inCdImage and isValid and loaded) and 'prop.ok' or 'prop.missing'
    log(L(key, Config.PropModel, src, tostring(inCdImage), tostring(isValid), tostring(loaded)))
end)

AddEventHandler('playerDropped', function()
    propReported[source] = nil
end)

CreateThread(function()
    log(L('startup.ok', resourceVersion(RESOURCE)))
    if not checkDependencies() then return end
    checkItem()
    checkColor()
    if Database.Migrate() then
        Change.RevertInterrupted()
        log(L('startup.known_bags', Bags.LoadKnown()))
        Bags.LoadStockUniforms()
        Bags.LoadUniformStashes()
        log(L('startup.ground', Ground.Load()))
        log(L('startup.points', Points.Load()))
        local okRelabel, fixed = pcall(Bags.ResyncStashes)
        log(L('startup.relabel', okRelabel and fixed or 0))
        Bags.RegisterHooks()
        if StashRules then StashRules.RegisterHook() else Utils.Error(L('startup.reload_needed')) end
        log(L('startup.ustash', UniformStash.Load()))
        -- Os baús do mri_Qbossmenu podem ainda não existir no início: segunda passada depois.
        SetTimeout(60000, function()
            local ok, n = pcall(Bags.ResyncStashes)
            if ok and n > 0 then log(L('startup.relabel', n)) end
            Supply.SyncAll()
            log(L('startup.supply'))
        end)
    end
    Permissions.RegisterWithQadmin()
end)

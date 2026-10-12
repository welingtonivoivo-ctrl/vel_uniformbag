-- Perfis e permissões (TRD §4, D16, D79–D87, D199).
-- Toda verificação acontece aqui, no servidor. Nada de código interno do mri_Qadmin é chamado:
-- a permissão de staff é uma ACE comum do FiveM, conferida por natives públicos.

Permissions = {}

local PERM_MANAGE = 'street_uniformbag.manage'
local PERM_EMERGENCY = 'street_uniformbag.admin'
local QADMIN_MASTER = 'qadmin.master'

Permissions.Nodes = {
    Manage = PERM_MANAGE,
    Emergency = PERM_EMERGENCY,
}

local function log(msg)
    print('^5[street_uniformbag]^7 ' .. msg)
end

local function getPlayerData(src)
    local player = exports.qbx_core:GetPlayer(src)
    return player and player.PlayerData or nil
end

--- Confere um nó ACE pelos mesmos caminhos que o mri_Qadmin usa para seus grupos:
--- jogador, identificadores, personagem (char:<citizenid>) e emprego (job.<nome>[.<grau>]).
--- Não inclui o acesso automático de god/admin (D82, D199).
local function hasAceNode(src, node)
    if IsPlayerAceAllowed(src, node) then return true end

    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if IsPrincipalAceAllowed('identifier.' .. identifier, node) then return true end
    end

    local data = getPlayerData(src)
    if not data then return false end

    if data.citizenid and IsPrincipalAceAllowed('char:' .. data.citizenid, node) then return true end

    local job = data.job
    if job and job.name and job.name ~= 'unemployed' then
        if IsPrincipalAceAllowed('job.' .. job.name, node) then return true end
        local grade = type(job.grade) == 'table' and job.grade.level or job.grade
        if grade and IsPrincipalAceAllowed(('job.%s.%s'):format(job.name, grade), node) then return true end
    end

    return false
end

--- ACE de emergência: só vale quando concedida explicitamente no server.cfg (D82).
function Permissions.IsEmergency(src)
    return IsPlayerAceAllowed(src, PERM_EMERGENCY) == true
end

--- Staff com a permissão do mri_Qadmin. Falha fechada sem o mri_Qadmin iniciado (D87).
function Permissions.IsStaff(src)
    if GetResourceState('mri_Qadmin') ~= 'started' then return false end
    return hasAceNode(src, PERM_MANAGE) or hasAceNode(src, QADMIN_MASTER)
end

--- Líder = chefe (isboss) do emprego atual no QBox, só da própria organização (D16, T6).
function Permissions.IsLeader(src, org)
    if type(org) ~= 'string' or org == '' then return false end
    local data = getPlayerData(src)
    local job = data and data.job
    return job ~= nil and job.name == org and job.isboss == true
end

--- Perfil do jogador para uma organização: 'emergencia', 'staff', 'lider' ou nil.
--- Sem organização informada, só staff/emergência podem ser retornados.
---@param src number
---@param org? string
---@return string|nil
function Permissions.GetProfile(src, org)
    if Permissions.IsEmergency(src) then return 'emergencia' end
    if Permissions.IsStaff(src) then return 'staff' end
    if org and Permissions.IsLeader(src, org) then return 'lider' end
    return nil
end

--- Registra a permissão no editor de grupos do mri_Qadmin pela API pública (D79).
--- Efeito do próprio mri_Qadmin: grava o nó na lista de permissões conhecidas dele.
local function registerWithQadmin()
    if GetResourceState('mri_Qadmin') ~= 'started' then
        log('^3' .. L('perm.qadmin_absent') .. '^7')
        return
    end

    local ok, err = pcall(function()
        exports.mri_Qadmin:RegisterPermissions(
            {
                { id = PERM_MANAGE, label = L('perm.manage_label'), desc = L('perm.manage_desc') },
            },
            { id = 'street_uniformbag', label = L('perm.category_label') }
        )
    end)

    if ok then
        log(L('perm.registered', PERM_MANAGE))
    else
        log('^1' .. L('perm.register_failed', tostring(err)) .. '^7')
    end

    -- Aba "Bolsas de Uniformes" em Plugins do mri_Qadmin (D88): carrega web/plugin.html deste recurso.
    ok, err = pcall(function()
        exports.mri_Qadmin:RegisterPlugin({
            id = 'street_uniformbag',
            label = L('perm.category_label'),
            icon = 'shirt',
            resource = GetCurrentResourceName(),
            htmlPath = 'web/plugin.html',
            requiredPerms = { PERM_MANAGE },
            permDefs = { { id = PERM_MANAGE, label = L('perm.manage_label'), desc = L('perm.manage_desc') } },
            description = L('perm.manage_desc'),
        })
    end)
    if ok then
        log(L('perm.plugin_registered'))
    else
        log('^1' .. L('perm.register_failed', tostring(err)) .. '^7')
    end
end

Permissions.RegisterWithQadmin = registerWithQadmin

-- Se o mri_Qadmin reiniciar depois de nós, registra de novo (o registro é idempotente).
AddEventHandler('onResourceStart', function(resource)
    if resource == 'mri_Qadmin' then
        SetTimeout(2000, registerWithQadmin)
    end
end)

-- Diagnóstico da etapa 2: só no console do servidor (txAdmin). Não altera nada.
-- Uso: uniformbag_perfil <id do jogador> [organização]
RegisterCommand('uniformbag_perfil', function(source, args)
    if source ~= 0 then return end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        log(L('perm.diag_usage'))
        return
    end

    local org = args[2]
    local data = getPlayerData(target)
    local job = data and data.job

    log(L('perm.diag_result',
        target,
        org or '-',
        tostring(Permissions.GetProfile(target, org)),
        tostring(Permissions.IsEmergency(target)),
        tostring(Permissions.IsStaff(target)),
        tostring(org and Permissions.IsLeader(target, org) or false),
        GetResourceState('mri_Qadmin'),
        job and job.name or '-',
        job and tostring(job.isboss) or '-'
    ))
end, true)

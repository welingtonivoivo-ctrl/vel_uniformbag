-- Comandos provisórios da etapa 3 (cadastro mínimo, emissão e alerta) para testar sem o painel.
-- O painel da etapa 4 substitui estes comandos. Todos validam o perfil no servidor (D84):
-- staff, emergência ou líder da própria organização.

local function notify(src, key, kind, ...)
    TriggerClientEvent('ox_lib:notify', src, { type = kind or 'inform', description = L(key, ...), duration = 8000 })
end

local function allowed(src, org)
    return Permissions.GetProfile(src, org) ~= nil
end

local function captureClothing(src)
    local raw = lib.callback.await('vel_uniformbag:client:capture', src)
    return Clothing.Sanitize(raw)
end

local function parseList(text)
    local list = {}
    for n in tostring(text or ''):gmatch('%-?%d+') do list[#list + 1] = tonumber(n) end
    return list
end

lib.addCommand('ubag_uniforme', {
    help = L('cmd.help_uniform'),
    params = {
        { name = 'org', type = 'string', help = L('cmd.param_org') },
        { name = 'nome', type = 'string', help = L('cmd.param_name') },
        { name = 'modo', type = 'string', help = L('cmd.param_mode') },
        -- Sem `type`: o ox_lib recusa texto "string" que pareça número (ex.: "1").
        { name = 'graduacoes', help = L('cmd.param_grades') },
    },
}, function(src, args)
    if not Database.Ready then return notify(src, 'block.unavailable', 'error') end
    local org = args.org
    if not allowed(src, org) then return notify(src, 'cmd.no_permission', 'error') end

    local spec = { org = org, name = tostring(args.nome):gsub('_', ' '):sub(1, 100), mode = args.modo }
    if spec.mode == 'faixa' then
        local a, b = tostring(args.graduacoes):match('^(%-?%d+)%-?(%-?%d*)$')
        spec.min, spec.max = tonumber(a), tonumber(b)
    elseif spec.mode == 'lista' then
        spec.grades = parseList(args.graduacoes)
    else
        return notify(src, 'cmd.mode_invalid', 'error')
    end

    local clothing = captureClothing(src)
    if not clothing then return notify(src, 'block.appearance_invalid', 'error') end

    local id, err = Uniforms.Create(src, spec)
    if not id then return notify(src, err, 'error') end

    Uniforms.SaveVariant(src, id, clothing)
    notify(src, 'cmd.uniform_created', 'success', id, spec.name, clothing.model)
end)

lib.addCommand('ubag_versao', {
    help = L('cmd.help_variant'),
    params = { { name = 'uniforme', type = 'number', help = L('cmd.param_uniform') } },
}, function(src, args)
    local uniform = Uniforms.Get(args.uniforme)
    if not uniform then return notify(src, 'cmd.uniform_unknown', 'error') end
    if not allowed(src, uniform.org) then return notify(src, 'cmd.no_permission', 'error') end

    local clothing = captureClothing(src)
    if not clothing then return notify(src, 'block.appearance_invalid', 'error') end

    Uniforms.SaveVariant(src, uniform.id, clothing)
    notify(src, 'cmd.variant_saved', 'success', uniform.id, clothing.model)
end)

lib.addCommand('ubag_emitir', {
    help = L('cmd.help_issue'),
    params = {
        { name = 'uniforme', type = 'number', help = L('cmd.param_uniform') },
        { name = 'quantidade', type = 'number', help = L('cmd.param_qty') },
        { name = 'bau', type = 'string', help = L('cmd.param_stash') },
    },
}, function(src, args)
    if not Database.Ready then return notify(src, 'block.unavailable', 'error') end
    local result, err = Issue.Run(src, args.uniforme, args.quantidade, args.bau)
    if not result then return notify(src, err, 'error') end
    notify(src, 'cmd.issued', result.failed == 0 and 'success' or 'warning', result.delivered, result.requested, result.failed)
end)

lib.addCommand('ubag_alerta', {
    help = L('cmd.help_alert'),
    params = {
        { name = 'org', type = 'string', help = L('cmd.param_org') },
        { name = 'modo', type = 'string', help = L('cmd.param_alert_mode') },
        { name = 'tipos', help = L('cmd.param_job_types'), optional = true },
    },
}, function(src, args)
    if not allowed(src, args.org) then return notify(src, 'cmd.no_permission', 'error') end
    if args.modo ~= 'psdispatch' and args.modo ~= 'desligado' then return notify(src, 'cmd.alert_mode_invalid', 'error') end

    local types = {}
    for t in tostring(args.tipos or ''):gmatch('[%w_]+') do types[#types + 1] = t end
    if args.modo == 'psdispatch' and #types == 0 then return notify(src, 'cmd.alert_types_missing', 'error') end

    Alerts.Configure(src, args.org, args.modo, types)
    notify(src, 'cmd.alert_saved', 'success', args.org, args.modo)
end)

lib.addCommand('ubag_uniformes', {
    help = L('cmd.help_list'),
    params = { { name = 'org', type = 'string', help = L('cmd.param_org') } },
}, function(src, args)
    if not allowed(src, args.org) then return notify(src, 'cmd.no_permission', 'error') end
    local rows = MySQL.query.await('SELECT `id`, `name`, `auth_mode`, `grade_min`, `grade_max` FROM `sub_uniforms` WHERE `org` = ? AND `active` = 1', { args.org }) or {}
    if #rows == 0 then return notify(src, 'cmd.list_empty', 'inform', args.org) end
    for _, r in ipairs(rows) do
        notify(src, 'cmd.list_item', 'inform', r.id, r.name, table.concat(Uniforms.ListVariantModels(r.id), ', '))
    end
end)

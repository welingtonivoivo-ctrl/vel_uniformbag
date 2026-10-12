-- Painel de gestão (03-FLUXO §2.2, D88–D90, D205, D206). Parte 1: Uniformes, Emissão, Bolsas.
-- Toda chamada revalida o perfil no servidor (D84). Staff/emergência veem todas as organizações;
-- líder só a própria (D16, D83). Organizações lidas do QBox na hora (D202).

Panel = {}

local function profileFor(src, org)
    return Permissions.GetProfile(src, org)
end

local function isAdmin(src)
    local p = Permissions.GetProfile(src, nil)
    return p == 'staff' or p == 'emergencia'
end

--- Organizações que o jogador pode gerenciar, com os cargos reais do QBox.
local function orgsFor(src)
    local jobs = exports.qbx_core:GetJobs() or {}
    local admin = isAdmin(src)
    local data = Utils.GetPlayerData(src)
    local out = {}

    for name, job in pairs(jobs) do
        if name ~= 'unemployed' and (admin or (data and data.job and data.job.name == name and data.job.isboss)) then
            local grades = {}
            for level, g in pairs(job.grades or {}) do
                grades[#grades + 1] = { level = tonumber(level), name = g.name or tostring(level), isboss = g.isboss == true }
            end
            table.sort(grades, function(a, b) return a.level < b.level end)
            out[#out + 1] = { name = name, label = job.label or name, type = job.type, grades = grades }
        end
    end

    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    return out
end

local function guard(src, org)
    if not Database.Ready then return false, 'block.unavailable' end
    if not profileFor(src, org) then return false, 'cmd.no_permission' end
    return true
end

------------------------------------------------------------------------------------------------
-- Abertura
------------------------------------------------------------------------------------------------

function Panel.Open(src)
    if not Database.Ready then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = L('block.unavailable') })
    end
    local orgs = orgsFor(src)
    if #orgs == 0 then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = L('panel.no_access') })
    end
    TriggerClientEvent('street_uniformbag:client:panelOpen', src, {
        admin = isAdmin(src),
        orgs = orgs,
        color = GetConvar('mri:color', Config.DefaultColor),
        maxBatch = Config.MaxBagsPerBatch,
        slots = Config.Slots,
    })
end

-- Comando da staff (D205). Só staff com a permissão ou ACE de emergência.
RegisterCommand('adminoutfit', function(src)
    if src == 0 then return end
    if not isAdmin(src) then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = L('panel.no_access') })
    end
    Panel.Open(src)
end, false)

------------------------------------------------------------------------------------------------
-- Uniformes
------------------------------------------------------------------------------------------------

lib.callback.register('street_uniformbag:panel:uniforms', function(src, org)
    local ok, err = guard(src, org)
    if not ok then return { error = err } end

    local rows = MySQL.query.await(
        'SELECT `id`, `name`, `auth_mode`, `grade_min`, `grade_max`, `active`, `updated_at` FROM `sub_uniforms` WHERE `org` = ? ORDER BY `active` DESC, `name`',
        { org }) or {}

    for _, u in ipairs(rows) do
        u.active = Utils.Bool(u.active)
        u.models = Uniforms.ListVariantModels(u.id)
        local grades = MySQL.query.await('SELECT `grade` FROM `sub_uniform_grades` WHERE `uniform_id` = ? ORDER BY `grade`', { u.id }) or {}
        u.grades = {}
        for _, g in ipairs(grades) do u.grades[#u.grades + 1] = g.grade end
        u.bags = MySQL.scalar.await("SELECT COUNT(*) FROM `sub_bags` WHERE `uniform_id` = ? AND `status` <> 'falha_emissao'", { u.id }) or 0
    end
    return { uniforms = rows }
end)

--- Criar ou editar (nome, modo de autorização, cargos, ativo). A roupa é gravada à parte.
lib.callback.register('street_uniformbag:panel:saveUniform', function(src, form)
    if type(form) ~= 'table' then return { error = 'block.invalid_request' } end
    local ok, err = guard(src, form.org)
    if not ok then return { error = err } end

    local name = type(form.name) == 'string' and form.name:gsub('^%s+', ''):gsub('%s+$', '') or ''
    if #name < 2 or #name > 100 then return { error = 'panel.name_invalid' } end

    local valid = {}
    for _, g in ipairs(Uniforms.JobGrades(form.org) or {}) do valid[g] = true end

    local mode = form.mode == 'faixa' and 'faixa' or 'lista'
    local grades, gmin, gmax = {}, nil, nil
    if mode == 'faixa' then
        gmin, gmax = tonumber(form.min), tonumber(form.max)
        if not gmin or not valid[gmin] then return { error = 'cmd.grade_invalid' } end
        if gmax and (not valid[gmax] or gmax < gmin) then return { error = 'cmd.grade_invalid' } end
    else
        for _, g in ipairs(type(form.grades) == 'table' and form.grades or {}) do
            g = tonumber(g)
            if not g or not valid[g] then return { error = 'cmd.grade_invalid' } end
            grades[#grades + 1] = g
        end
        if #grades == 0 then return { error = 'cmd.grade_invalid' } end
    end

    local data = Utils.GetPlayerData(src)
    local author = data and data.citizenid or '?'
    local id = tonumber(form.id)

    if id then
        local current = Uniforms.Get(id)
        if not current or current.org ~= form.org then return { error = 'cmd.uniform_unknown' } end
        local queries = {
            { query = 'UPDATE `sub_uniforms` SET `name` = ?, `auth_mode` = ?, `grade_min` = ?, `grade_max` = ?, `active` = ?, `updated_by` = ? WHERE `id` = ?',
              values = { name, mode, gmin, gmax, form.active == false and 0 or 1, author, id } },
            { query = 'DELETE FROM `sub_uniform_grades` WHERE `uniform_id` = ?', values = { id } },
        }
        for _, g in ipairs(grades) do
            queries[#queries + 1] = { query = 'INSERT INTO `sub_uniform_grades` (`uniform_id`, `grade`) VALUES (?, ?)', values = { id, g } }
        end
        if not MySQL.transaction.await(queries) then return { error = 'block.save_failed' } end
        Utils.Audit('admin', 'uniforme_alterado', { src = src, org = form.org, uniformId = id, data = { nome = name, modo = mode, graduacoes = grades, min = gmin, max = gmax, ativo = form.active ~= false } })
        return { ok = true, id = id }
    end

    local newId, createErr = Uniforms.Create(src, { org = form.org, name = name, mode = mode, grades = grades, min = gmin, max = gmax })
    if not newId then return { error = createErr } end
    return { ok = true, id = newId }
end)

--- Grava a roupa que o jogador está vestindo como versão do uniforme (D17, D57–D59).
lib.callback.register('street_uniformbag:panel:captureVariant', function(src, uniformId)
    local uniform = Uniforms.Get(tonumber(uniformId))
    if not uniform then return { error = 'cmd.uniform_unknown' } end
    local ok, err = guard(src, uniform.org)
    if not ok then return { error = err } end

    local clothing = Clothing.Sanitize(lib.callback.await('street_uniformbag:client:capture', src))
    if not clothing then return { error = 'block.appearance_invalid' } end

    Uniforms.SaveVariant(src, uniform.id, clothing)
    return { ok = true, model = clothing.model }
end)

lib.callback.register('street_uniformbag:panel:removeVariant', function(src, uniformId, model)
    local uniform = Uniforms.Get(tonumber(uniformId))
    if not uniform then return { error = 'cmd.uniform_unknown' } end
    local ok, err = guard(src, uniform.org)
    if not ok then return { error = err } end
    MySQL.update.await('DELETE FROM `sub_uniform_variants` WHERE `uniform_id` = ? AND `model` = ?', { uniform.id, tostring(model) })
    Utils.Audit('admin', 'versao_uniforme_removida', { src = src, org = uniform.org, uniformId = uniform.id, data = { model = model } })
    return { ok = true }
end)

--- Roupa de uma versão, para vestir e conferir (pré-visualização no próprio personagem).
lib.callback.register('street_uniformbag:panel:variant', function(src, uniformId, model)
    local uniform = Uniforms.Get(tonumber(uniformId))
    if not uniform then return nil end
    if not guard(src, uniform.org) then return nil end
    return Uniforms.GetVariant(uniform.id, tostring(model))
end)

------------------------------------------------------------------------------------------------
-- Emissão
------------------------------------------------------------------------------------------------

--- Baús da organização registrados no mri_Qbossmenu (D26); a configuração manual vem na parte 2.
lib.callback.register('street_uniformbag:panel:stashes', function(src, org)
    if not guard(src, org) then return {} end
    local list = {}
    if GetResourceState('mri_Qbossmenu') == 'started' then
        local ok, def = pcall(function() return exports.mri_Qbossmenu:GetManagedDefinition(org, 'job') end)
        if ok and type(def) == 'table' then
            local stashes = def.stashes or (def.definition and def.definition.stashes) or {}
            for _, s in ipairs(stashes) do
                if type(s) == 'table' and type(s.id) == 'string' then
                    list[#list + 1] = { id = s.id, label = s.label or s.id }
                end
            end
        end
    end
    return list
end)

lib.callback.register('street_uniformbag:panel:issue', function(src, uniformId, qty, stashId)
    local result, err = Issue.Run(src, tonumber(uniformId), tonumber(qty), stashId)
    if not result then return { error = err } end
    return { ok = true, result = result }
end)

------------------------------------------------------------------------------------------------
-- Bolsas (estoque e rastreio)
------------------------------------------------------------------------------------------------

lib.callback.register('street_uniformbag:panel:bags', function(src, org, filter)
    local ok, err = guard(src, org)
    if not ok then return { error = err } end
    filter = type(filter) == 'table' and filter or {}

    local where, values = { 'b.`org` = ?', "b.`status` <> 'falha_emissao'" }, { org }
    if filter.status == 'duplicada' then
        where[#where + 1] = 'b.`flagged_duplicate` = 1'
    elseif filter.status == 'chao' then
        where[#where + 1] = "b.`location_type` = 'chao'"
    elseif type(filter.status) == 'string' and filter.status:match('^[a-z_]+$') and filter.status ~= '' then
        where[#where + 1] = 'b.`status` = ?'
        values[#values + 1] = filter.status
    end
    if type(filter.search) == 'string' and #filter.search > 0 then
        where[#where + 1] = 'b.`bag_id` LIKE ?'
        values[#values + 1] = '%' .. filter.search:upper():gsub('[^%w%-]', '') .. '%'
    end

    local rows = MySQL.query.await(
        ([[SELECT b.`bag_id`, b.`status`, b.`location_type`, b.`location_id`, b.`flagged_duplicate`,
                  b.`issued_at`, b.`last_activity_at`, b.`last_activity_kind`, u.`name` AS uniform
           FROM `sub_bags` b JOIN `sub_uniforms` u ON u.`id` = b.`uniform_id`
           WHERE %s ORDER BY b.`last_activity_at` DESC LIMIT 200]]):format(table.concat(where, ' AND ')),
        values) or {}

    local counts = MySQL.query.await(
        [[SELECT `status`, COUNT(*) AS n FROM `sub_bags` WHERE `org` = ? AND `status` <> 'falha_emissao' GROUP BY `status`]], { org }) or {}

    for _, r in ipairs(rows) do r.flagged_duplicate = Utils.Bool(r.flagged_duplicate) end
    return { bags = rows, counts = counts }
end)

lib.callback.register('street_uniformbag:panel:bagHistory', function(src, bagId)
    local bag = Bags.Get(bagId)
    if not bag then return { error = 'block.unrecognized' } end
    local ok, err = guard(src, bag.org)
    if not ok then return { error = err } end

    local rows = MySQL.query.await(
        'SELECT `created_at`, `category`, `action`, `actor_name` FROM `sub_audit` WHERE `bag_id` = ? ORDER BY `id` DESC LIMIT 100',
        { bag.bag_id }) or {}
    local slots = Change.SlotsView(bag.bag_id)
    return { history = rows, slots = slots }
end)

------------------------------------------------------------------------------------------------
-- Loja de roupas (D206): só confere o perfil; o editor abre no cliente.
------------------------------------------------------------------------------------------------

lib.callback.register('street_uniformbag:panel:canOpenStore', function(src)
    return Permissions.GetProfile(src, nil) ~= nil or #orgsFor(src) > 0
end)

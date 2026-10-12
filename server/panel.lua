-- Painel de gestão (03-FLUXO §2.2, D88–D90, D205, D206). Parte 1: Uniformes, Emissão, Bolsas.
-- Toda chamada revalida o perfil no servidor (D84). Staff/emergência veem todas as organizações;
-- líder só a própria (D16, D83). Organizações lidas do QBox na hora (D202).

Panel = {}

-- Categorias de auditoria (05-BACKEND §2.10), usadas no filtro e na escolha de logs do Discord.
local AUDIT_CATEGORIES = {
    emissao = true, retirada = true, transferencia = true, devolucao = true, troca = true, uso_indevido = true,
    mudanca_cargo = true, pendente_verificacao = true, admin = true, recuperacao = true, duplicacao = true, sistema = true,
}

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

--- Dados iniciais do painel. `onlyOrg` limita à organização de um ponto da sede.
function Panel.Bootstrap(src, onlyOrg)
    if not Database.Ready then return nil, 'block.unavailable' end
    local orgs = orgsFor(src)
    if onlyOrg then
        local filtered = {}
        for _, o in ipairs(orgs) do
            if o.name == onlyOrg then filtered[1] = o end
        end
        orgs = filtered
    end
    if #orgs == 0 then return nil, 'panel.no_access' end
    return {
        admin = isAdmin(src),
        orgs = orgs,
        color = GetConvar('mri:color', Config.DefaultColor),
        maxBatch = Config.MaxBagsPerBatch,
        slots = Config.Slots,
    }
end

function Panel.Open(src, onlyOrg)
    local data, err = Panel.Bootstrap(src, onlyOrg)
    if not data then
        return TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = L(err) })
    end
    TriggerClientEvent('vel_uniformbag:client:panelOpen', src, data)
end

-- Versão embutida na aba Plugins do mri_Qadmin: a página pede os dados iniciais.
lib.callback.register('vel_uniformbag:panel:bootstrap', function(src)
    local data, err = Panel.Bootstrap(src)
    return data or { error = err }
end)

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

lib.callback.register('vel_uniformbag:panel:uniforms', function(src, org)
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
        u.bags = tonumber(MySQL.scalar.await("SELECT COALESCE(SUM(`delivered`), 0) FROM `sub_issue_batches` WHERE `uniform_id` = ?", { u.id })) or 0
    end
    -- Modelo atual de quem abriu o painel: mostra qual versão pode ser gravada agora.
    local model = GetEntityModel(GetPlayerPed(src)) & 0xFFFFFFFF
    local myModel
    for _, name in ipairs({ 'mp_m_freemode_01', 'mp_f_freemode_01' }) do
        if model == joaat(name) & 0xFFFFFFFF then myModel = name end
    end
    return { uniforms = rows, myModel = myModel }
end)

--- Criar ou editar (nome, modo de autorização, cargos, ativo). A roupa é gravada à parte.
lib.callback.register('vel_uniformbag:panel:saveUniform', function(src, form)
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
lib.callback.register('vel_uniformbag:panel:captureVariant', function(src, uniformId, expectedModel)
    local uniform = Uniforms.Get(tonumber(uniformId))
    if not uniform then return { error = 'cmd.uniform_unknown' } end
    local ok, err = guard(src, uniform.org)
    if not ok then return { error = err } end

    local clothing = Clothing.Sanitize(lib.callback.await('vel_uniformbag:client:capture', src))
    if not clothing then return { error = 'block.appearance_invalid' } end
    -- Cada botão grava só a versão do seu modelo: evita sobrescrever a outra por engano.
    if expectedModel ~= 'mp_m_freemode_01' and expectedModel ~= 'mp_f_freemode_01' then return { error = 'block.invalid_request' } end
    if clothing.model ~= expectedModel then
        return { error = expectedModel == 'mp_f_freemode_01' and 'panel.need_female' or 'panel.need_male' }
    end

    Uniforms.SaveVariant(src, uniform.id, clothing)
    return { ok = true, model = clothing.model }
end)

lib.callback.register('vel_uniformbag:panel:removeVariant', function(src, uniformId, model)
    local uniform = Uniforms.Get(tonumber(uniformId))
    if not uniform then return { error = 'cmd.uniform_unknown' } end
    local ok, err = guard(src, uniform.org)
    if not ok then return { error = err } end
    MySQL.update.await('DELETE FROM `sub_uniform_variants` WHERE `uniform_id` = ? AND `model` = ?', { uniform.id, tostring(model) })
    Utils.Audit('admin', 'versao_uniforme_removida', { src = src, org = uniform.org, uniformId = uniform.id, data = { model = model } })
    return { ok = true }
end)

--- Excluir uniforme: só se nunca teve bolsa entregue (as entregues dependem dele). Leva junto as
--- tentativas de emissão que falharam, as versões e os cargos (D214).
lib.callback.register('vel_uniformbag:panel:deleteUniform', function(src, uniformId)
    local uniform = Uniforms.Get(tonumber(uniformId))
    if not uniform then return { error = 'cmd.uniform_unknown' } end
    local ok, err = guard(src, uniform.org)
    if not ok then return { error = err } end

    local delivered = tonumber(MySQL.scalar.await(
        "SELECT COALESCE(SUM(`delivered`), 0) FROM `sub_issue_batches` WHERE `uniform_id` = ?", { uniform.id })) or 0
    local liveBags = tonumber(MySQL.scalar.await(
        "SELECT COUNT(*) FROM `sub_bags` WHERE `uniform_id` = ? AND `status` <> 'falha_emissao'", { uniform.id })) or 0
    if delivered > 0 or liveBags > 0 then return { error = 'panel.delete_blocked' } end

    local done = MySQL.transaction.await({
        { query = "DELETE FROM `sub_bags` WHERE `uniform_id` = ? AND `status` = 'falha_emissao'", values = { uniform.id } },
        { query = "DELETE FROM `sub_issue_batches` WHERE `uniform_id` = ?", values = { uniform.id } },
        { query = "DELETE FROM `sub_uniforms` WHERE `id` = ?", values = { uniform.id } },
    })
    if not done then return { error = 'block.invalid_request' } end

    Bags.StockUniforms[uniform.id] = nil
    Utils.Audit('admin', 'uniforme_excluido', { src = src, org = uniform.org, data = { uniforme = uniform.name, id = uniform.id } })
    return { ok = true }
end)

--- Roupa de uma versão, para vestir e conferir (pré-visualização no próprio personagem).
lib.callback.register('vel_uniformbag:panel:variant', function(src, uniformId, model)
    local uniform = Uniforms.Get(tonumber(uniformId))
    if not uniform then return nil end
    if not guard(src, uniform.org) then return nil end
    return Uniforms.GetVariant(uniform.id, tostring(model))
end)

------------------------------------------------------------------------------------------------
-- Emissão
------------------------------------------------------------------------------------------------

--- Baús da organização registrados no mri_Qbossmenu (D26); a configuração manual vem na parte 2.
--- Baús da organização cadastrados no mri_Qbossmenu.
local function orgStashes(org)
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
end

lib.callback.register('vel_uniformbag:panel:stashes', function(src, org)
    if not guard(src, org) then return {} end
    return orgStashes(org)
end)

--- Regras de modelo por baú (D215).
lib.callback.register('vel_uniformbag:panel:stashRules', function(src, org)
    local ok, err = guard(src, org)
    if not ok then return { error = err } end
    local list = orgStashes(org)
    for _, s in ipairs(list) do s.model = StashRules.Get(s.id) or '' end
    return { stashes = list }
end)

lib.callback.register('vel_uniformbag:panel:setStashRule', function(src, org, stashId, model)
    local ok, err = guard(src, org)
    if not ok then return { error = err } end
    local found
    for _, s in ipairs(orgStashes(org)) do if s.id == stashId then found = s end end
    if not found then return { error = 'cmd.stash_invalid' } end
    StashRules.Set(stashId, model)
    Utils.Audit('admin', 'regra_bau', { src = src, org = org, data = { bau = stashId, modelo = StashRules.Get(stashId) or 'todos' } })
    return { ok = true }
end)

--- Limpar baú: tira só as bolsas de uniforme (pilhas e unitárias). Bolsas que guardam roupas
--- civis de alguém ficam, para ninguém perder roupa (D216).
lib.callback.register('vel_uniformbag:panel:clearStash', function(src, org, stashId)
    local ok, err = guard(src, org)
    if not ok then return { error = err } end
    local found
    for _, s in ipairs(orgStashes(org)) do if s.id == stashId then found = s end end
    if not found then return { error = 'cmd.stash_invalid' } end

    local item = Config.ItemName
    local removed, kept = 0, 0
    for slot, it in pairs(exports.ox_inventory:GetInventoryItems(stashId) or {}) do
        if it.name == item then
            local meta = it.metadata or {}
            local bagId = type(meta.bagId) == 'string' and meta.bagId or nil
            local hasClothes = bagId and (tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM `sub_bag_slots` WHERE `bag_id` = ?', { bagId })) or 0) > 0
            if hasClothes then
                kept = kept + it.count
            elseif exports.ox_inventory:RemoveItem(stashId, item, it.count, nil, slot) then
                removed = removed + it.count
                if bagId then
                    Bags.Known[bagId] = nil
                    MySQL.update.await([[UPDATE `sub_bags` SET `status` = 'desconhecida', `location_type` = NULL, `location_id` = NULL,
                        `last_activity_at` = NOW(), `last_activity_kind` = 'descartada' WHERE `bag_id` = ?]], { bagId })
                end
            end
        end
    end

    Utils.Audit('admin', 'bau_limpo', { src = src, org = org, data = { bau = stashId, removidas = removed, mantidas = kept } })
    return { ok = true, removed = removed, kept = kept }
end)

lib.callback.register('vel_uniformbag:panel:issue', function(src, uniformId, qty, stashId)
    local result, err = Issue.Run(src, tonumber(uniformId), tonumber(qty), stashId)
    if not result then return { error = err } end
    return { ok = true, result = result }
end)

------------------------------------------------------------------------------------------------
-- Bolsas (estoque e rastreio)
------------------------------------------------------------------------------------------------

lib.callback.register('vel_uniformbag:panel:bags', function(src, org, filter)
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

lib.callback.register('vel_uniformbag:panel:bagHistory', function(src, bagId)
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
-- Alertas e logs (D13, D124–D134, D158, D174)
------------------------------------------------------------------------------------------------

--- Configuração atual + listas reais do QBox para escolher (tipos e nomes de empregos).
lib.callback.register('vel_uniformbag:panel:alertSettings', function(src, org)
    local ok, err = guard(src, org)
    if not ok then return { error = err } end

    local jobs = exports.qbx_core:GetJobs() or {}
    local types, names = {}, {}
    for name, job in pairs(jobs) do
        if name ~= 'unemployed' then
            names[#names + 1] = { name = name, label = job.label or name }
            if type(job.type) == 'string' and job.type ~= '' then types[job.type] = true end
        end
    end
    table.sort(names, function(a, b) return a.label:lower() < b.label:lower() end)
    local typeList = {}
    for t in pairs(types) do typeList[#typeList + 1] = t end
    table.sort(typeList)

    local settings = Alerts.GetSettings(org)
    if not settings.logCategories then
        settings.logCategories = {}
        for c in pairs(Discord.Essential) do settings.logCategories[#settings.logCategories + 1] = c end
    end

    -- Só a situação do webhook (configurado ou não), nunca o endereço (D76).
    return {
        settings = settings, jobTypes = typeList, jobNames = names,
        psdispatch = GetResourceState('ps-dispatch') == 'started',
        webhookOrg = Discord.HasWebhook(org), webhookAdmin = Discord.HasWebhook('admin'),
    }
end)

lib.callback.register('vel_uniformbag:panel:saveAlertSettings', function(src, org, form)
    local ok, err = guard(src, org)
    if not ok then return { error = err } end
    if type(form) ~= 'table' then return { error = 'block.invalid_request' } end

    local jobs = exports.qbx_core:GetJobs() or {}
    local validTypes = {}
    for _, job in pairs(jobs) do if type(job.type) == 'string' then validTypes[job.type] = true end end

    local function filterList(list, valid)
        local out = {}
        for _, v in ipairs(type(list) == 'table' and list or {}) do
            if type(v) == 'string' and valid(v) then out[#out + 1] = v end
        end
        return out
    end

    local mode = (form.mode == 'jobnotify' or form.mode == 'ambos') and form.mode or 'psdispatch'
    local blip = math.floor(tonumber(form.blipSeconds) or Config.DefaultBlipSeconds)
    if blip < 30 or blip > 900 then return { error = 'panel.blip_invalid' } end

    local code = type(form.code) == 'string' and form.code:gsub('[^%w%-]', ''):sub(1, 10) or Config.Dispatch.code
    local image = type(form.itemImage) == 'string' and form.itemImage or ''
    if image ~= '' and Bags.ResolveImage(image) ~= image then return { error = 'panel.image_invalid' } end
    local stash = type(form.defaultStash) == 'string' and form.defaultStash:sub(1, 80) or ''

    Alerts.SaveSettings(src, org, {
        enabled = form.enabled == true,
        mode = mode,
        jobTypes = filterList(form.jobTypes, function(v) return validTypes[v] end),
        jobNames = filterList(form.jobNames, function(v) return jobs[v] ~= nil end),
        onDutyOnly = form.onDutyOnly ~= false,
        blipSeconds = blip,
        code = code ~= '' and code or Config.Dispatch.code,
        itemImage = image,
        defaultStash = stash,
        logCategories = filterList(form.logCategories, function(v) return AUDIT_CATEGORIES[v] == true end),
    })
    return { ok = true }
end)

------------------------------------------------------------------------------------------------
-- Auditoria (D71, D72, D161): consulta paginada; líder só da própria organização.
------------------------------------------------------------------------------------------------

lib.callback.register('vel_uniformbag:panel:audit', function(src, org, filter)
    local ok, err = guard(src, org)
    if not ok then return { error = err } end
    filter = type(filter) == 'table' and filter or {}

    local where, values = { '(`org` = ? OR `org` IS NULL AND ? = 1)' }, { org, isAdmin(src) and 1 or 0 }
    if AUDIT_CATEGORIES[filter.category] then
        where[#where + 1] = '`category` = ?'
        values[#values + 1] = filter.category
    end
    if type(filter.bagId) == 'string' and #filter.bagId > 0 then
        where[#where + 1] = '`bag_id` LIKE ?'
        values[#values + 1] = '%' .. filter.bagId:upper():gsub('[^%w%-]', '') .. '%'
    end
    if type(filter.actor) == 'string' and #filter.actor > 0 then
        where[#where + 1] = '(`actor_name` LIKE ? OR `actor_citizenid` LIKE ?)'
        local like = '%' .. filter.actor:gsub('[%%_]', '') .. '%'
        values[#values + 1] = like
        values[#values + 1] = like
    end

    local page = math.max(0, math.floor(tonumber(filter.page) or 0))
    values[#values + 1] = page * 50

    local rows = MySQL.query.await(
        ('SELECT `id`, `created_at`, `category`, `action`, `bag_id`, `actor_name`, `actor_citizenid`, `data` FROM `sub_audit` WHERE %s ORDER BY `id` DESC LIMIT 51 OFFSET ?')
            :format(table.concat(where, ' AND ')), values) or {}

    local hasMore = #rows > 50
    if hasMore then rows[51] = nil end
    for _, r in ipairs(rows) do
        r.data = r.data and r.data:sub(1, 300) or nil
    end
    return { rows = rows, hasMore = hasMore, page = page }
end)

------------------------------------------------------------------------------------------------
-- Loja de roupas (D206): só confere o perfil; o editor abre no cliente.
------------------------------------------------------------------------------------------------

lib.callback.register('vel_uniformbag:panel:canOpenStore', function(src)
    return Permissions.GetProfile(src, nil) ~= nil or #orgsFor(src) > 0
end)

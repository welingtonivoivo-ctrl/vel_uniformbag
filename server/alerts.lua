-- Ocorrências de uso indevido (D5, D11–D13, D132–D134).
-- A ocorrência é montada uma vez e entregue aos canais ativos da organização.
-- Etapa 3: canal ps-dispatch. O canal próprio por emprego (jobnotify) entra na etapa 4.

Alerts = {}

local sent = {} -- chave anti-duplicação (bolsa + personagem + operação) -> true

local function orgSettings(org)
    return MySQL.single.await('SELECT * FROM `sub_org_settings` WHERE `org` = ?', { org })
end

local function decodeList(text)
    if type(text) ~= 'string' or text == '' then return {} end
    local ok, list = pcall(json.decode, text)
    return ok and type(list) == 'table' and list or {}
end

--- Canal ps-dispatch, disparado pelo servidor com coordenadas lidas no servidor (T5).
local function sendPsDispatch(incident, settings, uniform, street)
    if GetResourceState('ps-dispatch') ~= 'started' then return 'indisponivel' end

    local jobTypes = decodeList(settings.alert_job_types)
    if #jobTypes == 0 then return 'sem_destinatarios' end

    local minutes = math.max(1, math.ceil((settings.alert_blip_seconds or Config.DefaultBlipSeconds) / 60))
    local d = Config.Dispatch

    local ok = pcall(function()
        TriggerEvent('ps-dispatch:server:notify', {
            message = L('alert.title'),
            codeName = d.codeName,
            code = settings.alert_code or d.code,
            icon = d.icon,
            priority = settings.alert_priority or d.priority,
            coords = vector3(incident.x, incident.y, incident.z),
            street = street or L('alert.street_unknown'),
            information = L('alert.info', uniform.name, incident.bag_id),
            radius = d.radius,
            alert = {
                radius = d.radius,
                sprite = d.sprite,
                color = d.color,
                scale = d.scale,
                length = minutes,
                sound = 'Lose_1st',
                sound2 = 'GTAO_FM_Events_Soundset',
                offset = false,
                flash = false,
            },
            jobs = jobTypes,
        })
    end)

    return ok and 'enviado' or 'falhou'
end

--- Quem recebe pelo ps-dispatch: tipo de emprego na lista e em serviço (regra atual do ps-dispatch,
--- reproduzida no servidor para a anti-duplicação — D127, T11).
local function receivesPsDispatch(job, jobTypes)
    if not job or not job.onduty then return false end
    for _, t in ipairs(jobTypes) do
        if job.type == t then return true end
    end
    return false
end

--- Canal próprio por nome de emprego (D125–D131). Destinatários calculados só no servidor.
local function sendJobNotify(incident, settings, uniform, street)
    local names = decodeList(settings.alert_job_names)
    if #names == 0 then return 'sem_destinatarios' end
    local nameSet = {}
    for _, n in ipairs(names) do nameSet[n] = true end

    local psTypes = (settings.alert_mode == 'ambos') and decodeList(settings.alert_job_types) or {}
    local onlyOnDuty = Utils.Bool(settings.alert_onduty_only)
    local sent = 0

    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        local data = Utils.GetPlayerData(id)
        local job = data and data.job
        if job and nameSet[job.name] and (not onlyOnDuty or job.onduty)
            and not receivesPsDispatch(job, psTypes) then
            TriggerClientEvent('vel_uniformbag:client:alert', id, {
                id = incident.id,
                uniform = uniform.name,
                bagId = incident.bag_id,
                coords = { x = incident.x, y = incident.y, z = incident.z },
                street = street,
                blipSeconds = settings.alert_blip_seconds or Config.DefaultBlipSeconds,
            })
            sent = sent + 1
        end
    end
    return sent > 0 and 'enviado' or 'sem_destinatarios'
end

--- Registra a ocorrência e entrega aos canais. Nunca interrompe a troca (D133).
---@param kind 'vestir'|'mudanca_cargo'
function Alerts.Raise(kind, src, bag, uniform, dedupKey, jobBefore, jobAfter, street)
    if dedupKey then
        if sent[dedupKey] then return end
        sent[dedupKey] = true
    end

    local data = Utils.GetPlayerData(src)
    local coords = Utils.Coords(src) or { x = 0.0, y = 0.0, z = 0.0 }
    local incident = {
        id = Utils.Uuid(),
        kind = kind,
        bag_id = bag.bag_id,
        uniform_id = uniform.id,
        org = uniform.org,
        citizenid = data and data.citizenid or '?',
        char_name = data and Utils.CharName(data) or '?',
        x = coords.x, y = coords.y, z = coords.z,
    }

    local channels = {}
    local settings = orgSettings(uniform.org)

    if not settings or not Utils.Bool(settings.alert_enabled) then
        channels.psdispatch = 'desativado'
    else
        if settings.alert_mode == 'psdispatch' or settings.alert_mode == 'ambos' then
            channels.psdispatch = sendPsDispatch(incident, settings, uniform, street)
        end
        if settings.alert_mode == 'jobnotify' or settings.alert_mode == 'ambos' then
            local ok, result = pcall(sendJobNotify, incident, settings, uniform, street)
            channels.jobnotify = ok and result or 'falhou'
        end
    end

    local ok, err = pcall(MySQL.insert.await,
        [[INSERT INTO `sub_incidents` (`id`, `kind`, `bag_id`, `uniform_id`, `org`, `citizenid`, `char_name`, `job_before`, `job_after`, `x`, `y`, `z`, `channels`)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        { incident.id, kind, incident.bag_id, incident.uniform_id, incident.org, incident.citizenid, incident.char_name,
          jobBefore, jobAfter, incident.x, incident.y, incident.z, json.encode(channels) })
    if not ok then Utils.Error(L('alert.save_failed', tostring(err))) end

    Utils.Audit('uso_indevido', kind, {
        src = src, org = uniform.org, bagId = bag.bag_id, uniformId = uniform.id, coords = coords,
        data = { ocorrencia = incident.id, canais = channels, cargo = jobAfter },
    })
end

--- Configuração da organização para o painel (valores padrão quando ainda não existe).
function Alerts.GetSettings(org)
    local row = orgSettings(org) or {}
    return {
        enabled = Utils.Bool(row.alert_enabled),
        mode = row.alert_mode or 'psdispatch',
        jobTypes = decodeList(row.alert_job_types),
        jobNames = decodeList(row.alert_job_names),
        onDutyOnly = row.alert_onduty_only == nil and true or Utils.Bool(row.alert_onduty_only),
        blipSeconds = row.alert_blip_seconds or Config.DefaultBlipSeconds,
        code = row.alert_code or Config.Dispatch.code,
        itemImage = row.item_image or '',
        defaultStash = row.default_stash_id or '',
        logCategories = row.log_categories and decodeList(row.log_categories) or nil,
    }
end

--- Grava a configuração da organização, já validada pelo painel.
function Alerts.SaveSettings(src, org, s)
    local data = Utils.GetPlayerData(src)
    MySQL.query.await(
        [[INSERT INTO `sub_org_settings` (`org`, `alert_enabled`, `alert_mode`, `alert_job_types`, `alert_job_names`, `alert_onduty_only`,
            `alert_blip_seconds`, `alert_code`, `item_image`, `default_stash_id`, `log_categories`, `updated_by`, `updated_at`)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
          ON DUPLICATE KEY UPDATE `alert_enabled` = VALUES(`alert_enabled`), `alert_mode` = VALUES(`alert_mode`),
            `alert_job_types` = VALUES(`alert_job_types`), `alert_job_names` = VALUES(`alert_job_names`),
            `alert_onduty_only` = VALUES(`alert_onduty_only`), `alert_blip_seconds` = VALUES(`alert_blip_seconds`),
            `alert_code` = VALUES(`alert_code`), `item_image` = VALUES(`item_image`), `default_stash_id` = VALUES(`default_stash_id`),
            `log_categories` = VALUES(`log_categories`), `updated_by` = VALUES(`updated_by`), `updated_at` = NOW()]],
        { org, s.enabled and 1 or 0, s.mode, json.encode(s.jobTypes), json.encode(s.jobNames), s.onDutyOnly and 1 or 0,
          s.blipSeconds, s.code, s.itemImage ~= '' and s.itemImage or nil, s.defaultStash ~= '' and s.defaultStash or nil,
          json.encode(s.logCategories or {}), data and data.citizenid or '?' })
    Utils.Audit('admin', 'configuracao_alterada', { src = src, org = org, data = s })
end

--- Configuração mínima de alerta (etapa 3; o painel completo chega na etapa 4).
function Alerts.Configure(src, org, mode, jobTypes)
    local data = Utils.GetPlayerData(src)
    local enabled = mode ~= 'desligado' and 1 or 0
    MySQL.query.await(
        [[INSERT INTO `sub_org_settings` (`org`, `alert_enabled`, `alert_mode`, `alert_job_types`, `updated_by`, `updated_at`)
          VALUES (?, ?, ?, ?, ?, NOW())
          ON DUPLICATE KEY UPDATE `alert_enabled` = VALUES(`alert_enabled`), `alert_mode` = VALUES(`alert_mode`),
          `alert_job_types` = VALUES(`alert_job_types`), `updated_by` = VALUES(`updated_by`), `updated_at` = NOW()]],
        { org, enabled, enabled == 1 and mode or 'psdispatch', json.encode(jobTypes or {}), data and data.citizenid or 'console' })
    Utils.Audit('admin', 'alerta_configurado', { src = src, org = org, data = { modo = mode, tipos = jobTypes } })
end

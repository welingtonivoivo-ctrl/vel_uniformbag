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
local function sendPsDispatch(incident, settings, uniform)
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
            street = L('alert.street_unknown'),
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

--- Registra a ocorrência e entrega aos canais. Nunca interrompe a troca (D133).
---@param kind 'vestir'|'mudanca_cargo'
function Alerts.Raise(kind, src, bag, uniform, dedupKey, jobBefore, jobAfter)
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
            channels.psdispatch = sendPsDispatch(incident, settings, uniform)
        end
        if settings.alert_mode == 'jobnotify' or settings.alert_mode == 'ambos' then
            channels.jobnotify = 'etapa_4'
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

-- Logs no Discord (D70–D78): webhook por organização + canal geral da administração.
-- Endereços só em convars privadas do servidor (`set`, nunca `setr`) — nunca no código, na tela
-- do jogador nem no repositório (D76). Falha do Discord não afeta o uso (D77); o registro no banco
-- continua sendo a fonte da verdade, com o status do envio.

Discord = {}

-- Categorias enviadas quando a organização ainda não escolheu as suas (FLUXO §9) e as que vão
-- sempre ao canal geral da administração.
Discord.Essential = { uso_indevido = true, duplicacao = true, recuperacao = true, emissao = true, admin = true }

local queue = {}
local MAX_TRIES = 3

local function webhook(name)
    local url = GetConvar('vel_uniformbag_webhook_' .. name, '')
    if url:match('^https://discord%.com/api/webhooks/') or url:match('^https://discordapp%.com/api/webhooks/') then
        return url
    end
    return nil
end

function Discord.HasWebhook(name)
    return webhook(name) ~= nil
end

local function orgCategories(org)
    local row = org and MySQL.single.await('SELECT `log_categories` FROM `sub_org_settings` WHERE `org` = ?', { org })
    if not row or not row.log_categories or row.log_categories == '' then return Discord.Essential end
    local ok, list = pcall(json.decode, row.log_categories)
    if not ok or type(list) ~= 'table' then return Discord.Essential end
    local set = {}
    for _, c in ipairs(list) do set[c] = true end
    return set
end

local function buildEmbed(entry)
    local f = entry.fields
    local fields = {}
    local function add(name, value)
        if value ~= nil and value ~= '' then fields[#fields + 1] = { name = name, value = tostring(value):sub(1, 1000), inline = true } end
    end
    add('Organização', f.org)
    add('Bolsa', f.bagId)
    add('Uniforme', f.uniformId)
    add('Personagem', f.actorName and ('%s (%s)'):format(f.actorName, f.actorCid or '?') or f.actorCid)
    if f.coords then add('Local', ('%.1f, %.1f, %.1f'):format(f.coords.x, f.coords.y, f.coords.z)) end
    if f.data then fields[#fields + 1] = { name = 'Detalhes', value = ('```%s```'):format(json.encode(f.data):sub(1, 900)), inline = false } end

    return {
        username = 'Bolsas de Uniformes',
        embeds = { {
            title = ('%s · %s'):format(entry.category, entry.action),
            color = 0x6400E6,
            fields = fields,
            footer = { text = ('Registro #%s'):format(entry.auditId or '?') },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }
end

--- Coloca um registro de auditoria na fila do Discord. Nunca lança erro para quem chamou.
function Discord.Enqueue(auditId, category, action, fields)
    local targets = {}
    if fields.org and orgCategories(fields.org)[category] then
        local url = webhook(fields.org)
        if url then targets[#targets + 1] = url end
    end
    if Discord.Essential[category] then
        local url = webhook('admin')
        if url then targets[#targets + 1] = url end
    end
    if #targets == 0 then return end

    if auditId then MySQL.update("UPDATE `sub_audit` SET `discord_status` = 'pendente' WHERE `id` = ?", { auditId }) end
    local body = json.encode(buildEmbed({ auditId = auditId, category = category, action = action, fields = fields }))
    for _, url in ipairs(targets) do
        queue[#queue + 1] = { url = url, body = body, auditId = auditId, tries = 0 }
    end
end

local function finish(auditId, status)
    if auditId then MySQL.update('UPDATE `sub_audit` SET `discord_status` = ? WHERE `id` = ?', { status, auditId }) end
end

-- Envia um item por vez, respeitando o limite do Discord; reenvia até MAX_TRIES vezes.
CreateThread(function()
    while true do
        Wait(1500)
        local item = table.remove(queue, 1)
        if item then
            item.tries = item.tries + 1
            local p = promise.new()
            PerformHttpRequest(item.url, function(status) p:resolve(status) end, 'POST', item.body, { ['Content-Type'] = 'application/json' })
            local status = Citizen.Await(p)
            if status and status >= 200 and status < 300 then
                finish(item.auditId, 'enviado')
            elseif item.tries < MAX_TRIES then
                if status == 429 then Wait(5000) end
                queue[#queue + 1] = item
            else
                finish(item.auditId, 'falhou')
                Utils.Warn(L('discord.failed', tostring(item.auditId), tostring(status)))
            end
        end
    end
end)

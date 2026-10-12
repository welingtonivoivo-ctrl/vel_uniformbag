-- Funções comuns do servidor: log, identificação do jogador, IDs e auditoria (05-BACKEND §2.10).

Utils = {}

function Utils.Log(msg)
    print('^5[street_uniformbag]^7 ' .. msg)
end

function Utils.Warn(msg)
    print('^3[street_uniformbag]^7 ' .. msg)
end

function Utils.Error(msg)
    print('^1[street_uniformbag]^7 ' .. msg)
end

--- Colunas TINYINT(1) chegam do oxmysql como boolean; aceita também 1/0 (D200).
function Utils.Bool(v)
    return v == true or v == 1
end

function Utils.GetPlayerData(src)
    local player = exports.qbx_core:GetPlayer(src)
    return player and player.PlayerData or nil
end

function Utils.CharName(data)
    local info = data and data.charinfo
    if not info then return '?' end
    local name = ('%s %s'):format(info.firstname or '', info.lastname or '')
    name = name:gsub('^%s+', ''):gsub('%s+$', '')
    return name
end

function Utils.JobGrade(job)
    if not job then return nil end
    return type(job.grade) == 'table' and job.grade.level or job.grade
end

function Utils.Coords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return { x = c.x, y = c.y, z = c.z }
end

math.randomseed(os.time() + GetGameTimer())

local HEX = '0123456789abcdef'

--- UUID v4 (identificador de operação e de ocorrência).
function Utils.Uuid()
    local out = {}
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    for i = 1, #template do
        local ch = template:sub(i, i)
        if ch == 'x' then
            local n = math.random(1, 16)
            out[i] = HEX:sub(n, n)
        elseif ch == 'y' then
            local n = math.random(9, 12)
            out[i] = HEX:sub(n, n)
        else
            out[i] = ch
        end
    end
    return table.concat(out)
end

-- Sem letras/números confundíveis (0/O, 1/I/L).
local BAG_ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ'

--- ID curto da bolsa, ex.: UB-7K3QX9MD (D25). A unicidade é garantida pela chave primária no banco.
function Utils.NewBagId()
    local out = {}
    for i = 1, 8 do
        local n = math.random(1, #BAG_ALPHABET)
        out[i] = BAG_ALPHABET:sub(n, n)
    end
    return 'UB-' .. table.concat(out)
end

--- Registro permanente de auditoria (D161). Nunca lança erro para quem chamou.
---@param category string
---@param action string
---@param fields table|nil  org, bagId, uniformId, src, data, coords
function Utils.Audit(category, action, fields)
    fields = fields or {}
    local actorCid, actorName

    if fields.src and fields.src > 0 then
        local data = Utils.GetPlayerData(fields.src)
        actorCid = data and data.citizenid
        actorName = data and Utils.CharName(data)
    elseif fields.actor then
        actorCid = fields.actor
    end

    local coords = fields.coords or (fields.src and fields.src > 0 and Utils.Coords(fields.src)) or nil

    local ok, err = pcall(MySQL.insert.await,
        [[INSERT INTO `sub_audit` (`category`, `action`, `org`, `bag_id`, `uniform_id`, `actor_citizenid`, `actor_name`, `x`, `y`, `z`, `data`)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            category, action, fields.org, fields.bagId, fields.uniformId, actorCid, actorName,
            coords and coords.x, coords and coords.y, coords and coords.z,
            fields.data and json.encode(fields.data) or nil,
        })

    if not ok then
        Utils.Error(L('audit.failed', category, action, tostring(err)))
        return
    end

    -- Discord (D70–D78): só depois de gravado no banco; falha no envio não afeta nada.
    if Discord then
        pcall(Discord.Enqueue, err, category, action, {
            org = fields.org, bagId = fields.bagId, uniformId = fields.uniformId,
            actorCid = actorCid, actorName = actorName, coords = coords, data = fields.data,
        })
    end
end

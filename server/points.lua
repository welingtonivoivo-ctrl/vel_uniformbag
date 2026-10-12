-- Pontos de gestão nas sedes (D89–D93, 05-BACKEND §2.9). A staff cria o ponto onde está
-- (a coordenada é decidida por quem administra — D92); o líder usa o ponto para abrir o painel
-- só da própria organização. Tudo validado no servidor.

Points = {}

local list = {} -- id -> { id, org, label, x, y, z, radius }

local function isAdmin(src)
    local p = Permissions.GetProfile(src, nil)
    return p == 'staff' or p == 'emergencia'
end

function Points.Load()
    list = {}
    local rows = MySQL.query.await('SELECT `id`, `org`, `label`, `x`, `y`, `z`, `radius` FROM `sub_points` WHERE `active` = 1') or {}
    for _, r in ipairs(rows) do
        list[r.id] = { id = r.id, org = r.org, label = r.label, x = r.x + 0.0, y = r.y + 0.0, z = r.z + 0.0, radius = r.radius + 0.0 }
    end
    return #rows
end

local function broadcast()
    TriggerClientEvent('vel_uniformbag:client:points', -1, list)
end

lib.callback.register('vel_uniformbag:pointsList', function()
    return list
end)

--- Abrir o painel por um ponto: precisa estar perto e ser líder da organização (ou staff).
lib.callback.register('vel_uniformbag:openFromPoint', function(src, pointId)
    local point = list[tonumber(pointId)]
    if not point then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or #(GetEntityCoords(ped) - vector3(point.x, point.y, point.z)) > point.radius + 2.5 then return false end
    if not Permissions.GetProfile(src, point.org) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = L('panel.no_access') })
        return false
    end
    Panel.Open(src, point.org)
    return true
end)

------------------------------------------------------------------------------------------------
-- Aba Pontos do painel
------------------------------------------------------------------------------------------------

lib.callback.register('vel_uniformbag:panel:points', function(src, org)
    if not Permissions.GetProfile(src, org) then return { error = 'cmd.no_permission' } end
    local rows = MySQL.query.await(
        'SELECT `id`, `label`, `x`, `y`, `z`, `radius`, `active`, `created_at` FROM `sub_points` WHERE `org` = ? ORDER BY `id`', { org }) or {}
    for _, r in ipairs(rows) do r.active = Utils.Bool(r.active) end
    return { points = rows, canEdit = isAdmin(src) }
end)

--- Novo ponto na posição atual de quem cadastra (só staff — D92).
lib.callback.register('vel_uniformbag:panel:addPoint', function(src, org, label)
    if not isAdmin(src) then return { error = 'cmd.no_permission' } end
    local jobs = exports.qbx_core:GetJobs() or {}
    if not jobs[org] then return { error = 'cmd.org_unknown' } end
    label = type(label) == 'string' and label:gsub('[%c<>]', ''):sub(1, 80) or ''
    if #label < 2 then return { error = 'panel.label_invalid' } end

    local c = Utils.Coords(src)
    if not c then return { error = 'block.invalid_request' } end
    local data = Utils.GetPlayerData(src)
    local id = MySQL.insert.await(
        'INSERT INTO `sub_points` (`org`, `label`, `x`, `y`, `z`, `radius`, `active`, `created_by`) VALUES (?, ?, ?, ?, ?, ?, 1, ?)',
        { org, label, c.x, c.y, c.z - 0.5, 1.5, data and data.citizenid or '?' })

    Utils.Audit('admin', 'ponto_criado', { src = src, org = org, coords = c, data = { ponto = id, nome = label } })
    Points.Load()
    broadcast()
    return { ok = true, id = id }
end)

lib.callback.register('vel_uniformbag:panel:togglePoint', function(src, id, active)
    if not isAdmin(src) then return { error = 'cmd.no_permission' } end
    local row = MySQL.single.await('SELECT `org` FROM `sub_points` WHERE `id` = ?', { tonumber(id) })
    if not row then return { error = 'block.invalid_request' } end
    MySQL.update.await('UPDATE `sub_points` SET `active` = ? WHERE `id` = ?', { active and 1 or 0, tonumber(id) })
    Utils.Audit('admin', active and 'ponto_ativado' or 'ponto_desativado', { src = src, org = row.org, data = { ponto = id } })
    Points.Load()
    broadcast()
    return { ok = true }
end)

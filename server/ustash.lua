-- Baús de uniformes do próprio recurso (D223), criados no painel /adminoutfit pela staff:
-- nome, tipo (feminino/masculino) e posição atual de quem cria. Slots = quantidade de cargos da
-- organização (acompanha mudanças). Abrem só para membros da organização e já carregam a regra
-- de modelo (D215) e o abastecimento infinito (D222). Guardados no KVP do recurso (sem tabela).

UniformStash = {}

local KVP = 'uniform_stashes'
local MODELS = { mp_m_freemode_01 = true, mp_f_freemode_01 = true }
local defs = {} -- id -> { id, org, label, model, x, y, z }

local function save()
    local list = {}
    for _, d in pairs(defs) do list[#list + 1] = d end
    SetResourceKvp(KVP, json.encode(list))
end

local function gradeCount(org)
    local job = (exports.qbx_core:GetJobs() or {})[org]
    local n = 0
    for _ in pairs(job and job.grades or {}) do n = n + 1 end
    return math.max(n, 1)
end

--- Registra (ou atualiza) o baú no ox_inventory com slots = cargos da organização. Sem posição no
--- ox_inventory: quem confere se a pessoa está dentro da área é o gancho openInventory (D224).
function UniformStash.Register(d, minSlots)
    local slots = math.max(gradeCount(d.org), minSlots or 0)
    local weight = slots * 1500 * 2
    exports.ox_inventory:RegisterStash(d.id, d.label, slots, weight, nil, { [d.org] = 0 })
end

--- Está dentro da área desenhada? (polígono no plano + faixa de altura)
function UniformStash.Inside(d, pos)
    local pts = d.points
    if type(pts) ~= 'table' or #pts < 3 then
        return #(vec3(pos.x, pos.y, pos.z) - vec3(d.x, d.y, d.z)) <= 3.0
    end
    local minZ = math.huge
    for _, p in ipairs(pts) do if p.z < minZ then minZ = p.z end end
    if pos.z < minZ - 2.0 or pos.z > minZ + (d.height or 4.0) + 2.0 then return false end
    local inside, j = false, #pts
    for i = 1, #pts do
        local a, b = pts[i], pts[j]
        if ((a.y > pos.y) ~= (b.y > pos.y)) and (pos.x < (b.x - a.x) * (pos.y - a.y) / (b.y - a.y) + a.x) then
            inside = not inside
        end
        j = i
    end
    return inside
end

--- Valida a área enviada pelo desenho: 3 a 20 cantos, perto de quem desenhou, altura 1–20 m.
local function cleanArea(src, area)
    if type(area) ~= 'table' or type(area.points) ~= 'table' then return nil end
    local n = #area.points
    if n < 3 or n > 20 then return nil end
    local me = GetEntityCoords(GetPlayerPed(src))
    local pts, sx, sy, sz = {}, 0, 0, 0
    for i = 1, n do
        local p = area.points[i]
        local x, y, z = tonumber(p and p.x), tonumber(p and p.y), tonumber(p and p.z)
        if not (x and y and z) or #(vec3(x, y, z) - me) > 60.0 then return nil end
        pts[i] = { x = x, y = y, z = z }
        sx, sy, sz = sx + x, sy + y, sz + z
    end
    local h = math.min(20.0, math.max(1.0, tonumber(area.height) or 4.0))
    return pts, h, { x = sx / n, y = sy / n, z = sz / n }
end

function UniformStash.Get(id) return type(id) == 'string' and defs[id] or nil end

function UniformStash.List(org)
    local out = {}
    for _, d in pairs(defs) do if not org or d.org == org then out[#out + 1] = d end end
    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    return out
end

local function broadcast(target)
    TriggerClientEvent('vel_uniformbag:client:ustashes', target or -1, UniformStash.List())
end

function UniformStash.Load()
    local ok, list = pcall(json.decode, GetResourceKvpString(KVP) or '[]')
    for _, d in ipairs(ok and type(list) == 'table' and list or {}) do
        if type(d.id) == 'string' and MODELS[d.model] then
            defs[d.id] = d
            UniformStash.Register(d)
        end
    end
    broadcast()
    local n = 0
    for _ in pairs(defs) do n = n + 1 end
    return n
end

function UniformStash.Create(src, org, label, model, area)
    if not MODELS[model] then return nil, 'block.invalid_request' end
    local pts, height, center = cleanArea(src, area)
    if not pts then return nil, 'panel.ustash_area' end
    label = type(label) == 'string' and label:gsub('^%s+', ''):gsub('%s+$', '') or ''
    if #label < 2 or #label > 60 then return nil, 'panel.ustash_name' end
    local c = center
    local n = 1
    while defs[('vub_%s_%d'):format(org, n)] do n = n + 1 end
    local d = { id = ('vub_%s_%d'):format(org, n), org = org, label = label, model = model, x = c.x, y = c.y, z = c.z, points = pts, height = height }
    defs[d.id] = d
    save()
    UniformStash.Register(d)
    broadcast()
    return d
end

--- Redesenha a área de um baú existente (D225).
function UniformStash.SetArea(src, id, area)
    local d = defs[id]
    if not d then return false, 'cmd.stash_invalid' end
    local pts, height, center = cleanArea(src, area)
    if not pts then return false, 'panel.ustash_area' end
    d.points, d.height, d.x, d.y, d.z = pts, height, center.x, center.y, center.z
    save()
    broadcast()
    return true
end

--- Exclui o baú. Bolsas numeradas guardadas nele impedem a exclusão (não se perde rastreio).
function UniformStash.Delete(id)
    local d = defs[id]
    if not d then return false, 'cmd.stash_invalid' end
    for _, it in pairs(exports.ox_inventory:GetInventoryItems(id) or {}) do
        if it.name == Config.ItemName and it.metadata and it.metadata.bagId then return false, 'panel.ustash_has_bags' end
    end
    exports.ox_inventory:ClearInventory(id)
    defs[id] = nil
    save()
    broadcast()
    return true
end

lib.callback.register('vel_uniformbag:ustashList', function() return UniformStash.List() end)

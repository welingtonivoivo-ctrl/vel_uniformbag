-- Baús de uniformes do recurso (D223, D224): cada baú é uma ÁREA desenhada no chão; dentro dela
-- o membro da organização aperta E para abrir. O servidor confere de novo a área, o grupo e a
-- regra de modelo antes de abrir.

local zones = {}
local insideId

-- Aviso compacto dentro da área (D226).
local PROMPT_STYLE = { fontSize = '12px', padding = '4px 8px', borderRadius = '6px' }

local function clear()
    for id, zone in pairs(zones) do
        zone:remove()
        zones[id] = nil
    end
    if insideId then lib.hideTextUI() insideId = nil end
end

local function memberOf(org)
    local pd = exports.qbx_core:GetPlayerData()
    return pd and pd.job and pd.job.name == org or false
end

local function build(list)
    clear()
    for _, d in ipairs(list or {}) do
        if type(d.points) == 'table' and #d.points >= 3 then
            local points = {}
            for i, p in ipairs(d.points) do points[i] = vec3(p.x, p.y, p.z) end
            zones[d.id] = lib.zones.poly({
                points = points,
                thickness = (d.height or 4.0) * 2,
                debug = false,
                onEnter = function()
                    insideId = d.id
                    if memberOf(d.org) then
                        lib.showTextUI(L('target.ustash_key'), { position = 'left-center', icon = 'shirt', style = PROMPT_STYLE })
                    else
                        lib.showTextUI(L('target.ustash_members'), { position = 'left-center', icon = 'lock', style = PROMPT_STYLE })
                    end
                end,
                onExit = function()
                    if insideId == d.id then lib.hideTextUI() insideId = nil end
                end,
                inside = function()
                    if insideId == d.id and IsControlJustReleased(0, 38) and memberOf(d.org) then
                        exports.ox_inventory:openInventory('stash', d.id)
                    end
                end,
            })
        end
    end
end

RegisterNetEvent('vel_uniformbag:client:ustashes', build)

local function sync()
    build(lib.callback.await('vel_uniformbag:ustashList', false))
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() SetTimeout(3000, sync) end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function() SetTimeout(500, sync) end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() then SetTimeout(2500, sync) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then clear() end
end)

------------------------------------------------------------------------------------------------
-- Desenho da área (D224), no mesmo jeito do desenho de áreas da base: mirar no chão e clicar em
-- cada canto; rodinha muda a altura; Backspace desfaz; R recomeça; Enter conclui; Esc cancela.
-- Implementação própria.
------------------------------------------------------------------------------------------------

local drawing = false
local COLOR = { r = 100, g = 0, b = 230 }

local function wall(a, b, h, alpha)
    local a2, b2 = vec3(a.x, a.y, a.z + h), vec3(b.x, b.y, b.z + h)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, b2.x, b2.y, b2.z, COLOR.r, COLOR.g, COLOR.b, alpha)
    DrawPoly(b2.x, b2.y, b2.z, a2.x, a2.y, a2.z, a.x, a.y, a.z, COLOR.r, COLOR.g, COLOR.b, alpha)
    DrawPoly(b.x, b.y, b.z, a.x, a.y, a.z, b2.x, b2.y, b2.z, COLOR.r, COLOR.g, COLOR.b, alpha)
    DrawPoly(a2.x, a2.y, a2.z, b2.x, b2.y, b2.z, a.x, a.y, a.z, COLOR.r, COLOR.g, COLOR.b, alpha)
    DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 255, 255, 255, 200)
end

--- Mira da câmera no mesmo quadro (síncrona). A versão do ox_lib espera um quadro, o que fazia o
--- laço pular quadros: o bloqueio dos botões falhava (soco) e as teclas não eram lidas.
local function aim(distance)
    local from = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local cx = math.abs(math.cos(rx))
    local to = from + vec3(-math.sin(rz) * cx, math.cos(rz) * cx, math.sin(rx)) * distance
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 | 16, cache.ped, 4)
    local _, hit, coords = GetShapeTestResult(handle)
    return hit == 1 or hit == true, coords
end

local function help(points, height)
    lib.showTextUI(L('draw.help', #points, ('%.1f'):format(height)), { position = 'left-center' })
end

---@return table|nil area { points = { {x,y,z}... }, height = number }
function DrawStashArea()
    if drawing then return nil end
    drawing = true
    local points, height, result = {}, 4.0, nil
    help(points, height)

    while drawing do
        for _, c in ipairs({ 24, 25, 140, 141, 142, 200, 14, 15, 16, 17, 45 }) do DisableControlAction(0, c, true) end

        local hit, coords = aim(25.0)
        if hit and coords then
            DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.35, 0.35, 0.35, COLOR.r, COLOR.g, COLOR.b, 190, false, false, 2, false, nil, nil, false)
            DrawLine(coords.x, coords.y, coords.z, coords.x, coords.y, coords.z + height, 255, 255, 255, 200)
        end

        for i = 1, #points do
            local a, b = points[i], points[i + 1]
            if b then wall(a, b, height, 90) end
        end
        if #points >= 1 and hit and coords then wall(points[#points], coords, height, 50) end
        if #points >= 3 then wall(points[#points], points[1], height, 90) end

        local changed = false
        if hit and coords and (IsDisabledControlJustReleased(0, 24) or IsControlJustReleased(0, 38)) and #points < 20 then
            points[#points + 1] = coords; changed = true
        end
        if IsDisabledControlJustReleased(0, 15) then height = math.min(20.0, height + 0.5); changed = true end -- rodinha p/ cima
        if IsDisabledControlJustReleased(0, 14) then height = math.max(1.0, height - 0.5); changed = true end -- rodinha p/ baixo
        if IsControlJustReleased(0, 177) and #points > 0 then points[#points] = nil; changed = true end -- Backspace
        if IsDisabledControlJustReleased(0, 45) then points = {}; changed = true end -- R
        if IsControlJustReleased(0, 191) or IsControlJustReleased(0, 201) then -- Enter
            if #points >= 3 then
                result = { points = {}, height = height }
                for i, p in ipairs(points) do result.points[i] = { x = p.x, y = p.y, z = p.z } end
                drawing = false
            else
                lib.notify({ type = 'error', description = L('draw.need_three') })
            end
        end
        if IsDisabledControlJustReleased(0, 200) then drawing = false end -- Esc
        if changed then help(points, height) end
        Wait(0)
    end

    lib.hideTextUI()
    return result
end

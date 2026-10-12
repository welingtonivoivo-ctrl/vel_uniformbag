-- Tela da bolsa no cliente: animações, prévia, vigilância e troca em duas fases.
-- A bolsa fica de verdade no chão (D208); o painel abre por cima dela e fecha depois da troca.
-- O cliente nunca decide autorização; só aplica a roupa e informa o resultado (TRD §1).

Bag = {}

local session = nil -- { bagId, spot, busy, abort, data, model }
local preview = { ped = nil, token = 0 }

local function notify(key, kind, ...)
    lib.notify({ type = kind or 'error', description = L(key, ...) })
end

local function toBool(v) return v == true or v == 1 end

local function playOnce(anim)
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 8.0, -8.0, anim.duration, 0, 0, false, false, false)
    Wait(anim.duration)
    RemoveAnimDict(anim.dict)
end

local function startIdle()
    local anim = Config.Animations.idle
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 4.0, -4.0, -1, 1, 0, false, false, false)
end

local function faceSpot(spot)
    if not spot then return end
    TaskTurnPedToFaceCoord(cache.ped, spot.x, spot.y, spot.z, 600)
    Wait(600)
end

--- Caminha até ficar de frente para a bolsa, se estiver longe (imersão — pedido do dono).
--- Desiste se o jogador mexer o personagem ou o caminho travar. Retorna false se não chegou.
local function walkToSpot(spot)
    if not spot then return false end
    local target = vec3(spot.x, spot.y, spot.z)
    local pos = GetEntityCoords(cache.ped)
    if #(pos.xy - target.xy) <= Config.Approach.stopDistance + 0.3 then return true end

    local dir = (pos.xy - target.xy)
    dir = dir / #dir
    local stop = vec3(target.x + dir.x * Config.Approach.stopDistance, target.y + dir.y * Config.Approach.stopDistance, pos.z)
    local heading = (math.deg(math.atan(target.y - stop.y, target.x - stop.x)) - 90.0) % 360.0

    TaskGoStraightToCoord(cache.ped, stop.x, stop.y, stop.z, 1.0, Config.Approach.timeoutMs, heading, 0.2)
    local deadline = GetGameTimer() + Config.Approach.timeoutMs
    while GetGameTimer() < deadline do
        Wait(100)
        if #(GetEntityCoords(cache.ped).xy - stop.xy) <= 0.35 then
            ClearPedTasks(cache.ped)
            return true
        end
        -- Qualquer comando de movimento do jogador cancela a caminhada.
        if IsControlPressed(0, 30) or IsControlPressed(0, 31) or IsControlPressed(0, 22) then
            ClearPedTasks(cache.ped)
            return false
        end
    end
    ClearPedTasks(cache.ped)
    return #(GetEntityCoords(cache.ped).xy - target.xy) <= Config.MaxDistance
end

--- Restrições no cliente (D154): veículo, água, morte, algemas.
local function clientBlock()
    if cache.vehicle then return 'block.vehicle' end
    if toBool(IsPedSwimming(cache.ped)) or toBool(IsPedSwimmingUnderWater(cache.ped)) then return 'block.swimming' end
    if toBool(IsEntityDead(cache.ped)) or LocalPlayer.state.isDead or LocalPlayer.state.dead then return 'block.dead' end
    local pd = exports.qbx_core:GetPlayerData()
    local meta = pd and pd.metadata or {}
    if meta.isdead or meta.inlaststand then return 'block.dead' end
    if meta.ishandcuffed then return 'block.cuffed' end
    return nil
end

function Bag.IsOpen()
    return session ~= nil
end

------------------------------------------------------------------------------------------------
-- Prévia (D204): cópia local do personagem, não sincronizada com outros jogadores
------------------------------------------------------------------------------------------------

local function deleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

local function clearPreview()
    preview.token = preview.token + 1
    deleteEntity(preview.ped)
    preview.ped = nil
end

--- Ponto na frente da câmera, deslocado para o lado, no chão; a cópia fica virada para a câmera.
local function previewSpot()
    local camPos = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local yaw = math.rad(rot.z)
    local forward = vec3(-math.sin(yaw), math.cos(yaw), 0.0)
    local right = vec3(math.cos(yaw), math.sin(yaw), 0.0)
    local pos = camPos + forward * Config.Preview.depth + right * Config.Preview.side

    local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, false)
    local playerZ = GetEntityCoords(cache.ped).z
    -- A posição do ped fica na altura do quadril (~1 m acima do chão).
    local z = (toBool(found) and math.abs(groundZ + 1.0 - playerZ) < 3.0) and (groundZ + 1.0) or playerZ

    return vec3(pos.x, pos.y, z), (rot.z + 180.0) % 360.0
end

local function showPreview(kind, slotNo)
    local s = session
    if not s or s.busy then return end
    preview.token = preview.token + 1
    local token = preview.token

    local clothing = lib.callback.await('street_uniformbag:previewData', false, s.bagId, kind, slotNo, s.model)
    if token ~= preview.token or session ~= s or not clothing then return end

    if not preview.ped or not DoesEntityExist(preview.ped) then
        local pos, heading = previewSpot()
        local clone = ClonePed(cache.ped, false, false, true)
        if not clone or clone == 0 then return end
        SetEntityCoordsNoOffset(clone, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(clone, heading)
        FreezeEntityPosition(clone, true)
        SetEntityInvincible(clone, true)
        SetEntityCollision(clone, false, false)
        SetBlockingOfNonTemporaryEvents(clone, true)
        preview.ped = clone
    end

    if token ~= preview.token then return end
    exports.mri_Qappearance:setPedComponents(preview.ped, clothing.components)
    exports.mri_Qappearance:setPedProps(preview.ped, clothing.props)
end

------------------------------------------------------------------------------------------------
-- Sessão (painel aberto sobre a bolsa no chão)
------------------------------------------------------------------------------------------------

--- Fecha o painel. A bolsa continua no chão (D208).
local function closePanel(reasonKey)
    local s = session
    if not s then return end
    session = nil
    clearPreview()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    ClearPedTasks(cache.ped)
    lib.callback.await('street_uniformbag:close', false, s.bagId)
    if reasonKey then notify(reasonKey, 'error') end
end

--- Recolher a bolsa do chão: abaixa, pega e o item vai para o inventário (D203, D208).
function Bag.Collect(bagId)
    if session and session.busy then return end
    if session then closePanel(nil) end
    if clientBlock() then return notify(clientBlock(), 'error') end

    local spot = Ground.Spot(bagId)
    if not walkToSpot(spot) then return end
    faceSpot(spot)
    playOnce(Config.Animations.collect)
    ClearPedTasks(cache.ped)
    if lib.callback.await('street_uniformbag:collect', false, bagId) then
        notify('done.collected', 'success')
    end
end

--- Abrir a bolsa que está no chão (qualquer jogador perto — D4).
function Bag.OpenGround(bagId)
    if session then return end
    local reason = clientBlock()
    if reason then return notify(reason, 'error') end
    if not walkToSpot(Ground.Spot(bagId)) then return end
    lib.callback.await('street_uniformbag:openGround', false, bagId)
end

--- Vigia distância e estado e renova a trava enquanto o painel está aberto (D155, D156).
local function watch(s)
    CreateThread(function()
        local nextRenew = GetGameTimer() + Config.LockRenewSeconds * 1000
        while session == s do
            local reason = clientBlock()
            if not reason and s.spot
                and #(GetEntityCoords(cache.ped) - vec3(s.spot.x, s.spot.y, s.spot.z)) > Config.MaxDistance + 0.5 then
                reason = 'block.too_far_panel'
            end

            if reason then
                if s.busy then
                    s.abort = reason -- a troca em andamento desfaz com segurança
                else
                    closePanel(reason)
                    return
                end
            end

            if not s.busy then
                local idle = Config.Animations.idle
                if not IsEntityPlayingAnim(cache.ped, idle.dict, idle.clip, 3) then startIdle() end
            end

            if GetGameTimer() >= nextRenew and not s.busy then
                nextRenew = GetGameTimer() + Config.LockRenewSeconds * 1000
                if not lib.callback.await('street_uniformbag:renewLock', false, s.bagId) then
                    closePanel('block.lock_lost')
                    return
                end
            end
            Wait(250)
        end
    end)
end

local function locale()
    return {
        title = L('ui.title'), official = L('ui.official'), wearUniform = L('ui.wear_uniform'),
        noVariant = L('ui.no_variant'), slots = L('ui.slots'), free = L('ui.free'),
        storedBy = L('ui.stored_by'), wearThis = L('ui.wear_this'), incompatible = L('ui.incompatible'),
        uniformBadge = L('ui.uniform_badge'), occupied = L('ui.occupied'), collect = L('ui.collect'),
        close = L('ui.close'), fullHint = L('ui.full_hint'), confirmTitle = L('ui.confirm_title'),
        willWear = L('ui.will_wear'), willStore = L('ui.will_store'), currentOutfit = L('ui.current_outfit'),
        confirm = L('ui.confirm'), back = L('ui.back'), working = L('ui.working'), previewHint = L('ui.preview_hint'),
    }
end

RegisterNetEvent('street_uniformbag:client:open', function(data)
    if session then return end

    session = { bagId = data.bagId, spot = data.spot, data = data, model = exports.mri_Qappearance:getPedModel(cache.ped) }
    local s = session

    if data.justPlaced then
        playOnce(Config.Animations.place)
        if session ~= s then return end
    end
    faceSpot(s.spot)
    startIdle()

    SendNUIMessage({ action = 'open', data = data, playerModel = s.model, locale = locale() })
    SetNuiFocus(true, true)
    watch(s)
end)

--- Troca em duas fases (03-FLUXO §3 e §4). Depois o painel fecha e o personagem fica em pé (D208).
local function doChange(kind, slotNo)
    local s = session
    if not s or s.busy then return end
    s.busy, s.abort = true, nil
    clearPreview()
    SendNUIMessage({ action = 'busy', value = true })

    local function unbusy()
        if session ~= s then return end
        s.busy = false
        startIdle()
        SendNUIMessage({ action = 'busy', value = false })
    end

    local before = Appearance.Capture()
    local begin = lib.callback.await('street_uniformbag:beginChange', false, s.bagId, kind, slotNo, before)

    if not begin or begin.error then
        unbusy()
        return notify(begin and begin.error or 'block.invalid_request', 'error')
    end

    -- O painel some durante a troca para o jogador ver a animação.
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    ClearPedTasks(cache.ped)
    playOnce(Config.Animations.change)
    local applied = Appearance.Apply(begin.target)
    Wait(100)
    applied = applied and Appearance.Verify(begin.target) and not s.abort

    if not applied then
        Appearance.Apply(before) -- desfaz no corpo; nada foi gravado
        lib.callback.await('street_uniformbag:confirmChange', false, begin.token, false)
        local why = s.abort or 'block.apply_failed'
        s.busy = false
        closePanel(nil)
        return notify(why, 'error')
    end

    local coords = GetEntityCoords(cache.ped)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local cross = crossHash ~= 0 and GetStreetNameFromHashKey(crossHash) or ''
    if cross ~= '' then street = ('%s / %s'):format(street, cross) end

    local result = lib.callback.await('street_uniformbag:confirmChange', false, begin.token, true, street)
    if not result or not result.ok then
        Appearance.Apply(before)
        s.busy = false
        closePanel(nil)
        return notify(result and result.error or 'block.save_failed', 'error')
    end

    Appearance.Save()
    s.busy = false
    -- O servidor já liberou a trava; só fecha o painel e deixa o personagem em pé.
    if session == s then
        session = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        ClearPedTasks(cache.ped)
    end
    notify(kind == 'uniforme' and 'done.uniform' or 'done.slot', 'success')
end

RegisterNUICallback('close', function(_, cb)
    cb(true)
    if session and not session.busy then CreateThread(function() closePanel(nil) end) end
end)

RegisterNUICallback('collect', function(_, cb)
    cb(true)
    if session and not session.busy then
        local bagId = session.bagId
        CreateThread(function() Bag.Collect(bagId) end)
    end
end)

RegisterNUICallback('wearUniform', function(_, cb)
    cb(true)
    CreateThread(function() doChange('uniforme') end)
end)

RegisterNUICallback('wearSlot', function(body, cb)
    cb(true)
    local slotNo = tonumber(body and body.slot)
    if slotNo then CreateThread(function() doChange('compartimento', slotNo) end) end
end)

RegisterNUICallback('preview', function(body, cb)
    cb(true)
    local kind = body and body.kind
    if kind ~= 'uniforme' and kind ~= 'compartimento' then return end
    CreateThread(function() showPreview(kind, tonumber(body.slot)) end)
end)

RegisterNUICallback('previewEnd', function(_, cb)
    cb(true)
    clearPreview()
end)

------------------------------------------------------------------------------------------------
-- Recuperação ao carregar o personagem (03-FLUXO §4.1)
------------------------------------------------------------------------------------------------

local function recoveryCheck(delay)
    CreateThread(function()
        Wait(delay)
        local result = lib.callback.await('street_uniformbag:recoveryCheck', false)
        if result and result.clothing and Appearance.Apply(result.clothing) then
            Appearance.Save()
            notify('recovery.applied', 'inform')
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() recoveryCheck(8000) end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() and LocalPlayer.state.isLoggedIn then recoveryCheck(3000) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteEntity(preview.ped)
    if session then
        SetNuiFocus(false, false)
        ClearPedTasks(cache.ped)
    end
end)

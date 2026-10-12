-- Recuperação no cliente (D149–D151, D159): aviso ao entrar, /minharoupa, sempre com confirmação.

local busy = false

local function offer(silentIfNone)
    if busy then return end
    local pending = lib.callback.await('street_uniformbag:recoveryPending', false)
    if not pending then
        if not silentIfNone then lib.notify({ type = 'inform', description = L('recovery.none') }) end
        return
    end

    busy = true
    local answer = lib.alertDialog({
        header = L('recovery.title'),
        content = L('recovery.content', pending.reason or '-'),
        centered = true,
        cancel = true,
        labels = { confirm = L('recovery.now'), cancel = L('recovery.later') },
    })

    if answer ~= 'confirm' then
        busy = false
        return lib.notify({ type = 'inform', description = L('recovery.later_hint', Config.RecoveryCommand) })
    end

    local clothing = lib.callback.await('street_uniformbag:recoveryFetch', false, pending.id)
    if not clothing then
        busy = false
        return lib.notify({ type = 'error', description = L('recovery.failed') })
    end

    local previous = Appearance.Capture()
    if not Appearance.Apply(clothing) or not Appearance.Verify(clothing) then
        Appearance.Apply(previous) -- falhou: volta à roupa anterior e continua pendente (D150)
        busy = false
        return lib.notify({ type = 'error', description = L('recovery.failed') })
    end

    if lib.callback.await('street_uniformbag:recoveryConfirm', false, pending.id, previous) then
        Appearance.Save()
        lib.notify({ type = 'success', description = L('recovery.done') })
    else
        Appearance.Apply(previous)
        lib.notify({ type = 'error', description = L('recovery.failed') })
    end
    busy = false
end

RegisterCommand(Config.RecoveryCommand, function() CreateThread(function() offer(false) end) end, false)

RegisterNetEvent('street_uniformbag:client:recoveryPending', function()
    CreateThread(function() offer(true) end)
end)

-- Ao entrar: espera o personagem e a aparência carregarem (D149).
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(15000, function() offer(true) end)
end)

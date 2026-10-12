-- Alerta do canal próprio por emprego (D125–D131): só chega a quem o servidor escolheu.
-- Nome da rua: o enviado pelo servidor ou calculado aqui (T12); ponto temporário no mapa (D128, D158).

local blips = {}

RegisterNetEvent('street_uniformbag:client:alert', function(alert)
    if type(alert) ~= 'table' or type(alert.coords) ~= 'table' then return end
    local c = alert.coords

    local street = alert.street
    if not street or street == '' then
        local hash = GetStreetNameAtCoord(c.x, c.y, c.z)
        street = GetStreetNameFromHashKey(hash)
    end

    lib.notify({
        title = L('alert.title'),
        description = L('alert.notify', alert.uniform or '?', street or '?'),
        type = 'warning',
        duration = 10000,
    })
    PlaySoundFrontend(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false)

    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, Config.Dispatch.sprite)
    SetBlipColour(blip, Config.Dispatch.color)
    SetBlipScale(blip, Config.Dispatch.scale)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(L('alert.title'))
    EndTextCommandSetBlipName(blip)
    blips[#blips + 1] = blip

    local seconds = math.max(10, math.min(tonumber(alert.blipSeconds) or Config.DefaultBlipSeconds, 3600))
    SetTimeout(seconds * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)

-- Etapa 1 — Preparação: confere se o modelo da bolsa existe no jogo (verificação V1).
-- Só carrega o modelo para teste e o libera em seguida; nenhum objeto é criado.

-- Nesta build, alguns nativos devolvem 1/0 em vez de true/false.
local function toBool(value)
    return value == true or value == 1
end

local function checkPropModel()
    local model = joaat(Config.PropModel)
    local inCdImage = toBool(IsModelInCdimage(model))
    local isValid = toBool(IsModelValid(model))
    local loaded = false

    if inCdImage and isValid then
        local ok = pcall(lib.requestModel, model, 5000)
        loaded = ok and toBool(HasModelLoaded(model))
        SetModelAsNoLongerNeeded(model)
    end

    local key = (inCdImage and isValid and loaded) and 'prop.ok' or 'prop.missing'
    print(('[vel_uniformbag] %s'):format(L(key, Config.PropModel, GetPlayerServerId(PlayerId()), tostring(inCdImage), tostring(isValid), tostring(loaded))))

    TriggerServerEvent('vel_uniformbag:server:propCheck', inCdImage, isValid, loaded)
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end
    Wait(1000)
    checkPropModel()
end)

-- Pontos de gestão nas sedes (D89–D93): olhinho que abre o painel da organização do ponto.
-- O cliente só mostra a opção ao chefe da organização; o servidor confere de novo ao abrir.

local zones = {} -- id -> zone

local function clear()
    for id, zone in pairs(zones) do
        pcall(function() exports.ox_target:removeZone(zone) end)
        zones[id] = nil
    end
end

local function isBossOf(org)
    local pd = exports.qbx_core:GetPlayerData()
    local job = pd and pd.job
    return job ~= nil and job.name == org and job.isboss == true
end

local function build(list)
    clear()
    for id, p in pairs(list or {}) do
        local ok, zone = pcall(function()
            return exports.ox_target:addSphereZone({
                coords = vec3(p.x, p.y, p.z + 0.5),
                radius = p.radius or 1.5,
                debug = false,
                options = {
                    {
                        name = 'street_uniformbag:point:' .. id,
                        icon = 'fa-solid fa-shirt',
                        label = L('target.manage', p.label),
                        distance = 2.5,
                        canInteract = function() return isBossOf(p.org) end,
                        onSelect = function()
                            CreateThread(function() lib.callback.await('street_uniformbag:openFromPoint', false, id) end)
                        end,
                    },
                },
            })
        end)
        if ok and zone then zones[id] = zone end
    end
end

RegisterNetEvent('street_uniformbag:client:points', build)

local function sync()
    build(lib.callback.await('street_uniformbag:pointsList', false))
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() SetTimeout(3000, sync) end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() then SetTimeout(2000, sync) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then clear() end
end)

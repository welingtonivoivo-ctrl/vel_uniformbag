-- Baús de uniformes do recurso (D223): ponto de interação no local, só para membros da
-- organização. O ox_inventory confere de novo o grupo; a regra de modelo é conferida no servidor.

local zones = {}

local function clear()
    for id, zone in pairs(zones) do
        pcall(function() exports.ox_target:removeZone(zone) end)
        zones[id] = nil
    end
end

local function memberOf(org)
    local pd = exports.qbx_core:GetPlayerData()
    return pd and pd.job and pd.job.name == org or false
end

local function build(list)
    clear()
    for _, d in ipairs(list or {}) do
        local ok, zone = pcall(function()
            return exports.ox_target:addSphereZone({
                coords = vec3(d.x, d.y, d.z),
                radius = 1.2,
                debug = false,
                options = {
                    {
                        name = 'vel_uniformbag:ustash:' .. d.id,
                        icon = 'fa-solid fa-box-open',
                        label = L('target.ustash', d.label),
                        distance = 2.5,
                        canInteract = function() return memberOf(d.org) end,
                        onSelect = function() exports.ox_inventory:openInventory('stash', d.id) end,
                    },
                },
            })
        end)
        if ok and zone then zones[d.id] = zone end
    end
end

RegisterNetEvent('vel_uniformbag:client:ustashes', build)

local function sync()
    build(lib.callback.await('vel_uniformbag:ustashList', false))
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() SetTimeout(3000, sync) end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() then SetTimeout(2500, sync) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then clear() end
end)

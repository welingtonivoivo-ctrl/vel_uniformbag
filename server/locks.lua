-- Trava por bolsa (D100, D156, D183): uma pessoa por vez; renovada enquanto a tela está aberta;
-- estado 'finalizando' nunca expira nem é liberado por desconexão até a transação terminar.

Locks = {}

local held = {}      -- bagId -> { src, state = 'aberta'|'finalizando', expires, netId }
local byPlayer = {}  -- src -> bagId

local function now() return os.time() end

local function expired(lock)
    return lock.state ~= 'finalizando' and lock.expires < now()
end

--- Tenta travar a bolsa para o jogador.
---@return boolean ok, string|nil reason  ('em_uso' | 'ja_usando')
function Locks.Acquire(bagId, src)
    local current = held[bagId]
    if current and current.src ~= src and not expired(current) then
        return false, 'em_uso'
    end
    if byPlayer[src] and byPlayer[src] ~= bagId then
        return false, 'ja_usando'
    end
    held[bagId] = { src = src, state = 'aberta', expires = now() + Config.LockSeconds }
    byPlayer[src] = bagId
    return true
end

function Locks.Holds(bagId, src)
    local lock = held[bagId]
    return lock ~= nil and lock.src == src and (lock.state == 'finalizando' or not expired(lock))
end

function Locks.Renew(bagId, src)
    local lock = held[bagId]
    if not lock or lock.src ~= src or expired(lock) then return false end
    lock.expires = now() + Config.LockSeconds
    return true
end

function Locks.SetFinalizing(bagId, src, finalizing)
    local lock = held[bagId]
    if not lock or lock.src ~= src then return false end
    lock.state = finalizing and 'finalizando' or 'aberta'
    lock.expires = now() + Config.LockSeconds
    return true
end

function Locks.SetProp(bagId, src, netId)
    local lock = held[bagId]
    if lock and lock.src == src then lock.netId = netId end
end

local function removeProp(lock)
    if lock and lock.netId then
        local entity = NetworkGetEntityFromNetworkId(lock.netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end

--- Libera a trava. Em 'finalizando', só libera se `force` (fim da transação).
function Locks.Release(bagId, src, force)
    local lock = held[bagId]
    if not lock or lock.src ~= src then return false end
    if lock.state == 'finalizando' and not force then return false end
    removeProp(lock)
    held[bagId] = nil
    if byPlayer[src] == bagId then byPlayer[src] = nil end
    return true
end

function Locks.Info(bagId)
    return held[bagId]
end

function Locks.PlayerBag(src)
    return byPlayer[src]
end

--- Desconexão (D156): remove o objeto e libera, exceto durante a finalização.
function Locks.OnDrop(src)
    local bagId = byPlayer[src]
    if not bagId then return end
    local lock = held[bagId]
    if lock and lock.state == 'finalizando' then
        removeProp(lock)
        lock.netId = nil
        return
    end
    Locks.Release(bagId, src, true)
end

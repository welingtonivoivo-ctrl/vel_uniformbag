-- Roupa do personagem via API pública do mri_Qappearance (D22): capturar, aplicar, conferir, salvar.
-- Só peças de roupa e acessórios; rosto e cabelo nunca são tocados (o próprio mri_Qappearance
-- ignora os componentes 0 e 2 em modelos freemode).

Appearance = {}

local function toSet(list)
    local set = {}
    for _, v in ipairs(list) do set[v] = true end
    return set
end

local COMPONENTS = toSet(Config.ClothingComponents)
local PROPS = toSet(Config.ClothingProps)

local function qa() return exports.mri_Qappearance end

function Appearance.Capture()
    local ped = cache.ped
    local model = qa():getPedModel(ped)
    local components, props = {}, {}

    for _, c in ipairs(qa():getPedComponents(ped) or {}) do
        if COMPONENTS[c.component_id] then components[#components + 1] = c end
    end
    for _, p in ipairs(qa():getPedProps(ped) or {}) do
        if PROPS[p.prop_id] then props[#props + 1] = p end
    end

    return { model = model, components = components, props = props }
end

function Appearance.Apply(clothing)
    if type(clothing) ~= 'table' then return false end
    if clothing.model ~= qa():getPedModel(cache.ped) then return false end -- nunca troca o modelo (D64)
    qa():setPedComponents(cache.ped, clothing.components)
    qa():setPedProps(cache.ped, clothing.props)
    return true
end

local function samePiece(a, b)
    if not a or not b then return false end
    if a.collection and a.collection ~= '' and b.collection and b.collection ~= '' then
        return a.collection == b.collection and a.localDrawable == b.localDrawable and a.texture == b.texture
    end
    return a.drawable == b.drawable and a.texture == b.texture
end

--- Confere se as peças aplicadas batem com a roupa pedida (checagem de consistência no cliente).
function Appearance.Verify(clothing)
    local now = Appearance.Capture()
    if now.model ~= clothing.model then return false end

    local byId = {}
    for _, c in ipairs(now.components) do byId[c.component_id] = c end
    for _, want in ipairs(clothing.components) do
        if not samePiece(byId[want.component_id], want) then return false end
    end
    return true
end

--- Salva a aparência pelo mesmo caminho das lojas de roupa da base (D138).
function Appearance.Save()
    local full = qa():getPedAppearance(cache.ped)
    if full then
        TriggerServerEvent('illenium-appearance:server:saveAppearance', full)
    end
end

-- Captura pedida pelos comandos provisórios de cadastro (etapa 3).
lib.callback.register('vel_uniformbag:client:capture', function()
    return Appearance.Capture()
end)

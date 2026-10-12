-- Roupa (componentes + acessórios) recebida do cliente: limpeza, validação e comparação.
-- O servidor do FiveM não enxerga a roupa do ped; tudo vem do cliente e é tratado como dado
-- não confiável (D198): só passam campos numéricos esperados, nos IDs configurados.

Clothing = {}

local function toSet(list)
    local set = {}
    for _, v in ipairs(list) do set[v] = true end
    return set
end

local COMPONENTS = toSet(Config.ClothingComponents)
local PROPS = toSet(Config.ClothingProps)

local function isInt(v)
    return type(v) == 'number' and v == math.floor(v) and v >= -1 and v < 100000
end

local function cleanCollection(v)
    if type(v) ~= 'string' or #v > 64 then return nil end
    return v:match('^[%w_%-]*$') and v or nil
end

local function isSupportedModel(model)
    for _, m in ipairs(Config.SupportedModels) do
        if m == model then return true end
    end
    return false
end

Clothing.IsSupportedModel = isSupportedModel

--- Limpa a roupa vinda do cliente. Retorna nil se inválida.
---@return table|nil clothing { model, components = {..}, props = {..} }
function Clothing.Sanitize(raw)
    if type(raw) ~= 'table' then return nil end
    if type(raw.model) ~= 'string' or not isSupportedModel(raw.model) then return nil end

    local out = { model = raw.model, components = {}, props = {} }

    for _, c in pairs(type(raw.components) == 'table' and raw.components or {}) do
        if type(c) == 'table' and COMPONENTS[c.component_id] and isInt(c.drawable) and isInt(c.texture) then
            out.components[#out.components + 1] = {
                component_id = c.component_id,
                drawable = c.drawable,
                texture = c.texture,
                collection = cleanCollection(c.collection),
                localDrawable = isInt(c.localDrawable) and c.localDrawable or nil,
            }
        end
    end

    for _, p in pairs(type(raw.props) == 'table' and raw.props or {}) do
        if type(p) == 'table' and PROPS[p.prop_id] and isInt(p.drawable) and isInt(p.texture) then
            out.props[#out.props + 1] = {
                prop_id = p.prop_id,
                drawable = p.drawable,
                texture = p.texture,
                collection = cleanCollection(p.collection),
                localDrawable = isInt(p.localDrawable) and p.localDrawable or nil,
            }
        end
    end

    if #out.components == 0 then return nil end
    if #json.encode(out) > Config.MaxAppearanceSize then return nil end

    return out
end

--- Decodifica uma roupa guardada no banco.
function Clothing.Decode(text)
    if type(text) ~= 'string' then return nil end
    local ok, data = pcall(json.decode, text)
    return ok and type(data) == 'table' and data or nil
end

local function samePiece(a, b)
    if not a or not b then return false end
    if a.collection and a.collection ~= '' and b.collection and b.collection ~= '' then
        return a.collection == b.collection and a.localDrawable == b.localDrawable and a.texture == b.texture
    end
    return a.drawable == b.drawable and a.texture == b.texture
end

local function index(list, key)
    local map = {}
    for _, item in ipairs(list or {}) do map[item[key]] = item end
    return map
end

--- A roupa `worn` corresponde à versão de uniforme `variant`? Compara só as peças configuradas
--- (Config.UniformMatchComponents/Props) e o modelo (D140, D193, D196).
function Clothing.MatchesUniform(worn, variant)
    if not worn or not variant or worn.model ~= variant.model then return false end

    local wc, vc = index(worn.components, 'component_id'), index(variant.components, 'component_id')
    for _, id in ipairs(Config.UniformMatchComponents) do
        if vc[id] and not samePiece(wc[id], vc[id]) then return false end
    end

    local wp, vp = index(worn.props, 'prop_id'), index(variant.props, 'prop_id')
    for _, id in ipairs(Config.UniformMatchProps) do
        if vp[id] and not samePiece(wp[id], vp[id]) then return false end
    end

    return true
end

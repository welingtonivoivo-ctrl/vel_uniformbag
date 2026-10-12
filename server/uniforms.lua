-- Cadastro de uniformes (05-BACKEND §2.1–2.3) e regra de autorização (D135–D137).

Uniforms = {}

function Uniforms.Get(id)
    return MySQL.single.await('SELECT * FROM `sub_uniforms` WHERE `id` = ?', { id })
end

function Uniforms.GetVariant(uniformId, model)
    local row = MySQL.single.await(
        'SELECT `appearance` FROM `sub_uniform_variants` WHERE `uniform_id` = ? AND `model` = ?',
        { uniformId, model })
    return row and Clothing.Decode(row.appearance) or nil
end

function Uniforms.ListVariantModels(uniformId)
    local rows = MySQL.query.await('SELECT `model` FROM `sub_uniform_variants` WHERE `uniform_id` = ?', { uniformId }) or {}
    local models = {}
    for _, r in ipairs(rows) do models[#models + 1] = r.model end
    return models
end

--- Versões de todos os uniformes ativos de um modelo (para reconhecer farda guardada, D196).
function Uniforms.ActiveVariantsForModel(model)
    return MySQL.query.await(
        [[SELECT v.`uniform_id`, v.`appearance` FROM `sub_uniform_variants` v
          JOIN `sub_uniforms` u ON u.`id` = v.`uniform_id`
          WHERE u.`active` = 1 AND v.`model` = ?]], { model }) or {}
end

--- Qual uniforme ativo a roupa `worn` representa, se algum (D196).
function Uniforms.DetectUniform(worn)
    if not worn then return nil end
    for _, row in ipairs(Uniforms.ActiveVariantsForModel(worn.model)) do
        if Clothing.MatchesUniform(worn, Clothing.Decode(row.appearance)) then
            return row.uniform_id
        end
    end
    return nil
end

--- O personagem está autorizado a usar o uniforme? Emprego e graduação atuais do QBox (D9, D135–D137).
---@return boolean authorized, string|nil jobName, number|nil grade
function Uniforms.IsAuthorized(src, uniform)
    local data = Utils.GetPlayerData(src)
    local job = data and data.job
    if not job or not uniform then return false end

    local grade = Utils.JobGrade(job)
    if job.name ~= uniform.org or grade == nil then
        return false, job.name, grade
    end

    if uniform.auth_mode == 'faixa' then
        if uniform.grade_min == nil or grade < uniform.grade_min then return false, job.name, grade end
        if uniform.grade_max ~= nil and grade > uniform.grade_max then return false, job.name, grade end
        return true, job.name, grade
    end

    local row = MySQL.scalar.await(
        'SELECT 1 FROM `sub_uniform_grades` WHERE `uniform_id` = ? AND `grade` = ?', { uniform.id, grade })
    return row ~= nil, job.name, grade
end

--- Graduações reais de um emprego no QBox, lidas na hora (D202).
function Uniforms.JobGrades(org)
    local jobs = exports.qbx_core:GetJobs()
    local job = jobs and jobs[org]
    if not job or type(job.grades) ~= 'table' then return nil end
    local grades = {}
    for level in pairs(job.grades) do grades[#grades + 1] = tonumber(level) end
    table.sort(grades)
    return grades, job.label
end

--- Cria um uniforme (cadastro mínimo da etapa 3; o painel completo chega na etapa 4).
---@param spec table { org, name, mode = 'lista'|'faixa', grades = {..} | min, max }
---@return number|nil id, string|nil errorKey
function Uniforms.Create(src, spec)
    local validGrades = Uniforms.JobGrades(spec.org)
    if not validGrades then return nil, 'cmd.org_unknown' end

    local valid = {}
    for _, g in ipairs(validGrades) do valid[g] = true end

    if spec.mode == 'faixa' then
        if not spec.min or not valid[spec.min] then return nil, 'cmd.grade_invalid' end
        if spec.max and (not valid[spec.max] or spec.max < spec.min) then return nil, 'cmd.grade_invalid' end
    else
        if not spec.grades or #spec.grades == 0 then return nil, 'cmd.grade_invalid' end
        for _, g in ipairs(spec.grades) do
            if not valid[g] then return nil, 'cmd.grade_invalid' end
        end
    end

    local data = Utils.GetPlayerData(src)
    local author = data and data.citizenid or 'console'

    local id = MySQL.insert.await(
        'INSERT INTO `sub_uniforms` (`org`, `name`, `auth_mode`, `grade_min`, `grade_max`, `created_by`) VALUES (?, ?, ?, ?, ?, ?)',
        { spec.org, spec.name, spec.mode, spec.mode == 'faixa' and spec.min or nil, spec.mode == 'faixa' and spec.max or nil, author })

    if spec.mode == 'lista' then
        for _, g in ipairs(spec.grades) do
            MySQL.insert.await('INSERT IGNORE INTO `sub_uniform_grades` (`uniform_id`, `grade`) VALUES (?, ?)', { id, g })
        end
    end

    Utils.Audit('admin', 'uniforme_criado', { src = src, org = spec.org, uniformId = id, data = spec })
    return id
end

--- Grava (ou substitui) a versão do uniforme para o modelo da roupa capturada (D57–D59).
function Uniforms.SaveVariant(src, uniformId, clothing)
    local data = Utils.GetPlayerData(src)
    MySQL.query.await(
        [[INSERT INTO `sub_uniform_variants` (`uniform_id`, `model`, `appearance`, `captured_by`) VALUES (?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE `appearance` = VALUES(`appearance`), `captured_by` = VALUES(`captured_by`)]],
        { uniformId, clothing.model, json.encode(clothing), data and data.citizenid or 'console' })

    local uniform = Uniforms.Get(uniformId)
    Utils.Audit('admin', 'versao_uniforme_gravada', { src = src, org = uniform and uniform.org, uniformId = uniformId, data = { model = clothing.model } })
end

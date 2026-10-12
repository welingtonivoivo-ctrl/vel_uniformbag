-- Migração versionada e idempotente (TRD §3). Roda ao iniciar o recurso.
-- Só cria o que falta; nunca apaga nem altera dados existentes.

Database = {
    Ready = false,
    Version = 0,
}

local function log(msg)
    print('^5[street_uniformbag]^7 ' .. msg)
end

local function currentVersion()
    return MySQL.scalar.await('SELECT COALESCE(MAX(`version`), 0) FROM `sub_schema_version`') or 0
end

local function countTables()
    local placeholders = {}
    for i = 1, #Schema.Tables do placeholders[i] = '?' end

    local found = MySQL.query.await(
        ('SELECT TABLE_NAME AS name FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN (%s)')
            :format(table.concat(placeholders, ',')),
        Schema.Tables
    ) or {}

    local present = {}
    for _, row in ipairs(found) do present[row.name] = true end

    local missing = {}
    for _, name in ipairs(Schema.Tables) do
        if not present[name] then missing[#missing + 1] = name end
    end

    return #found, missing
end

function Database.Migrate()
    local ok, err = pcall(function()
        MySQL.query.await(Schema.VersionTable)

        local version = currentVersion()
        local target = #Schema.Migrations

        if version >= target then
            log(L('db.up_to_date', version))
        end

        for v = version + 1, target do
            for _, sql in ipairs(Schema.Migrations[v]) do
                MySQL.query.await(sql)
            end
            MySQL.insert.await('INSERT IGNORE INTO `sub_schema_version` (`version`) VALUES (?)', { v })
            log(L('db.migrated', v))
        end

        Database.Version = currentVersion()

        local count, missing = countTables()
        if #missing > 0 then
            error(L('db.missing_tables', table.concat(missing, ', ')))
        end
        log(L('db.tables_ok', count, #Schema.Tables, Database.Version))
    end)

    Database.Ready = ok
    if not ok then
        log('^1' .. L('db.failed', tostring(err)) .. '^7')
    end
    return ok
end

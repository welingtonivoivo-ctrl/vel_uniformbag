-- Esquema do banco (05-BACKEND §2). Cada versão é uma lista de comandos idempotentes
-- (CREATE TABLE IF NOT EXISTS). Nunca DROP nem ALTER destrutivo (TRD §3).
-- Datas em DATETIME (sem o limite de 2038 do TIMESTAMP), pois a auditoria é permanente (D161).

Schema = {}

Schema.VersionTable = [[
CREATE TABLE IF NOT EXISTS `sub_schema_version` (
    `version`    INT NOT NULL,
    `applied_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]]

Schema.Migrations = {
    -- Versão 1: as 13 tabelas do sistema (a 14ª, sub_schema_version, é criada antes).
    [1] = {
        [[
CREATE TABLE IF NOT EXISTS `sub_uniforms` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `org`        VARCHAR(60) NOT NULL,
    `name`       VARCHAR(100) NOT NULL,
    `auth_mode`  ENUM('lista','faixa') NOT NULL,
    `grade_min`  SMALLINT NULL,
    `grade_max`  SMALLINT NULL,
    `active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(60) NOT NULL,
    `updated_by` VARCHAR(60) NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_org` (`org`, `active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_uniform_grades` (
    `uniform_id` INT UNSIGNED NOT NULL,
    `grade`      SMALLINT NOT NULL,
    PRIMARY KEY (`uniform_id`, `grade`),
    CONSTRAINT `fk_grades_uniform` FOREIGN KEY (`uniform_id`) REFERENCES `sub_uniforms` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_uniform_variants` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uniform_id`  INT UNSIGNED NOT NULL,
    `model`       VARCHAR(40) NOT NULL,
    `appearance`  LONGTEXT NOT NULL CHECK (JSON_VALID(`appearance`)),
    `captured_by` VARCHAR(60) NOT NULL,
    `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_variant` (`uniform_id`, `model`),
    CONSTRAINT `fk_variants_uniform` FOREIGN KEY (`uniform_id`) REFERENCES `sub_uniforms` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_issue_batches` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `idempotency_key` CHAR(36) NOT NULL,
    `org`             VARCHAR(60) NOT NULL,
    `uniform_id`      INT UNSIGNED NOT NULL,
    `stash_id`        VARCHAR(80) NOT NULL,
    `requested`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `delivered`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `failed`          SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `unit_cost`       INT UNSIGNED NOT NULL DEFAULT 0,
    `status`          ENUM('em_andamento','concluido','parcial','falhou') NOT NULL DEFAULT 'em_andamento',
    `requested_by`    VARCHAR(60) NOT NULL,
    `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `finished_at`     DATETIME NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_idempotency` (`idempotency_key`),
    KEY `idx_org_time` (`org`, `created_at`),
    CONSTRAINT `fk_batches_uniform` FOREIGN KEY (`uniform_id`) REFERENCES `sub_uniforms` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_bags` (
    `bag_id`             CHAR(12) NOT NULL,
    `uniform_id`         INT UNSIGNED NOT NULL,
    `org`                VARCHAR(60) NOT NULL,
    `batch_id`           INT UNSIGNED NOT NULL,
    `status`             ENUM('em_estoque','em_circulacao','desconhecida','falha_emissao') NOT NULL,
    `location_type`      VARCHAR(20) NULL,
    `location_id`        VARCHAR(80) NULL,
    `version`            INT UNSIGNED NOT NULL DEFAULT 0,
    `flagged_duplicate`  TINYINT(1) NOT NULL DEFAULT 0,
    `issued_by`          VARCHAR(60) NOT NULL,
    `issued_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_withdrawn_by`  VARCHAR(60) NULL,
    `last_withdrawn_at`  DATETIME NULL,
    `last_activity_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_activity_kind` VARCHAR(30) NULL,
    PRIMARY KEY (`bag_id`),
    KEY `idx_org_status` (`org`, `status`),
    KEY `idx_uniform` (`uniform_id`),
    KEY `idx_status_activity` (`status`, `last_activity_at`),
    CONSTRAINT `fk_bags_uniform` FOREIGN KEY (`uniform_id`) REFERENCES `sub_uniforms` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_bags_batch` FOREIGN KEY (`batch_id`) REFERENCES `sub_issue_batches` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_bag_slots` (
    `bag_id`              CHAR(12) NOT NULL,
    `slot_no`             TINYINT UNSIGNED NOT NULL,
    `model`               VARCHAR(40) NOT NULL,
    `appearance`          LONGTEXT NOT NULL CHECK (JSON_VALID(`appearance`)),
    `stored_by_citizenid` VARCHAR(60) NOT NULL,
    `stored_by_name`      VARCHAR(100) NOT NULL,
    `stored_at`           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `uniform_id`          INT UNSIGNED NULL,
    PRIMARY KEY (`bag_id`, `slot_no`),
    CONSTRAINT `fk_slots_bag` FOREIGN KEY (`bag_id`) REFERENCES `sub_bags` (`bag_id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_slots_uniform` FOREIGN KEY (`uniform_id`) REFERENCES `sub_uniforms` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_wearing` (
    `citizenid`     VARCHAR(60) NOT NULL,
    `bag_id`        CHAR(12) NOT NULL,
    `uniform_id`    INT UNSIGNED NOT NULL,
    `org`           VARCHAR(60) NOT NULL,
    `authorized`    TINYINT(1) NOT NULL,
    `job_name`      VARCHAR(60) NOT NULL,
    `job_grade`     SMALLINT NOT NULL,
    `state`         ENUM('ativo','pendente') NOT NULL DEFAULT 'ativo',
    `since`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_check_at` DATETIME NULL,
    PRIMARY KEY (`citizenid`),
    KEY `idx_bag` (`bag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_org_settings` (
    `org`                VARCHAR(60) NOT NULL,
    `alert_enabled`      TINYINT(1) NOT NULL DEFAULT 0,
    `alert_mode`         ENUM('psdispatch','jobnotify','ambos') NOT NULL DEFAULT 'psdispatch',
    `alert_job_types`    VARCHAR(255) NULL,
    `alert_job_names`    VARCHAR(500) NULL,
    `alert_onduty_only`  TINYINT(1) NOT NULL DEFAULT 1,
    `alert_blip_seconds` SMALLINT UNSIGNED NOT NULL DEFAULT 120,
    `alert_code`         VARCHAR(10) NULL,
    `alert_priority`     TINYINT NULL,
    `log_categories`     VARCHAR(500) NULL,
    `default_stash_id`   VARCHAR(80) NULL,
    `item_image`         VARCHAR(60) NULL,
    `updated_by`         VARCHAR(60) NULL,
    `updated_at`         DATETIME NULL,
    PRIMARY KEY (`org`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_points` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `org`        VARCHAR(60) NOT NULL,
    `label`      VARCHAR(80) NOT NULL,
    `x`          DECIMAL(10,3) NOT NULL,
    `y`          DECIMAL(10,3) NOT NULL,
    `z`          DECIMAL(10,3) NOT NULL,
    `radius`     DECIMAL(4,2) NOT NULL DEFAULT 1.50,
    `active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` VARCHAR(60) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_org` (`org`, `active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_audit` (
    `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `created_at`      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `category`        VARCHAR(30) NOT NULL,
    `action`          VARCHAR(60) NOT NULL,
    `org`             VARCHAR(60) NULL,
    `bag_id`          CHAR(12) NULL,
    `uniform_id`      INT UNSIGNED NULL,
    `actor_citizenid` VARCHAR(60) NULL,
    `actor_name`      VARCHAR(100) NULL,
    `x`               DECIMAL(10,3) NULL,
    `y`               DECIMAL(10,3) NULL,
    `z`               DECIMAL(10,3) NULL,
    `data`            LONGTEXT NULL CHECK (`data` IS NULL OR JSON_VALID(`data`)),
    `discord_status`  ENUM('nao_aplica','pendente','enviado','falhou') NOT NULL DEFAULT 'nao_aplica',
    PRIMARY KEY (`id`),
    KEY `idx_bag` (`bag_id`, `created_at`),
    KEY `idx_org_cat` (`org`, `category`, `created_at`),
    KEY `idx_actor` (`actor_citizenid`, `created_at`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_incidents` (
    `id`         CHAR(36) NOT NULL,
    `kind`       ENUM('vestir','mudanca_cargo') NOT NULL,
    `bag_id`     CHAR(12) NOT NULL,
    `uniform_id` INT UNSIGNED NOT NULL,
    `org`        VARCHAR(60) NOT NULL,
    `citizenid`  VARCHAR(60) NOT NULL,
    `char_name`  VARCHAR(100) NOT NULL,
    `job_before` VARCHAR(80) NULL,
    `job_after`  VARCHAR(80) NULL,
    `x`          DECIMAL(10,3) NOT NULL,
    `y`          DECIMAL(10,3) NOT NULL,
    `z`          DECIMAL(10,3) NOT NULL,
    `channels`   VARCHAR(500) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    KEY `idx_org_time` (`org`, `created_at`),
    KEY `idx_bag` (`bag_id`),
    KEY `idx_char` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_recoveries` (
    `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid`           VARCHAR(60) NOT NULL,
    `model`               VARCHAR(40) NOT NULL,
    `appearance`          LONGTEXT NOT NULL CHECK (JSON_VALID(`appearance`)),
    `reason`              VARCHAR(500) NOT NULL,
    `created_by`          VARCHAR(60) NOT NULL,
    `created_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `status`              ENUM('aguardando','concluida','cancelada') NOT NULL DEFAULT 'aguardando',
    `previous_appearance` LONGTEXT NULL CHECK (`previous_appearance` IS NULL OR JSON_VALID(`previous_appearance`)),
    `applied_at`          DATETIME NULL,
    `source_audit_id`     BIGINT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    KEY `idx_char_status` (`citizenid`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
CREATE TABLE IF NOT EXISTS `sub_operations` (
    `token`             CHAR(36) NOT NULL,
    `bag_id`            CHAR(12) NOT NULL,
    `slot_no`           TINYINT UNSIGNED NULL,
    `citizenid`         VARCHAR(60) NOT NULL,
    `kind`              ENUM('vestir_uniforme','vestir_compartimento') NOT NULL,
    `state`             ENUM('iniciada','concluida','revertida') NOT NULL DEFAULT 'iniciada',
    `before_appearance` LONGTEXT NOT NULL CHECK (JSON_VALID(`before_appearance`)),
    `target_appearance` LONGTEXT NOT NULL CHECK (JSON_VALID(`target_appearance`)),
    `bag_version`       INT UNSIGNED NOT NULL,
    `created_at`        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `finished_at`       DATETIME(3) NULL,
    `saved_at`          DATETIME(3) NULL,
    `restored_at`       DATETIME(3) NULL,
    PRIMARY KEY (`token`),
    KEY `idx_char_state` (`citizenid`, `state`),
    KEY `idx_state` (`state`),
    CONSTRAINT `fk_operations_bag` FOREIGN KEY (`bag_id`) REFERENCES `sub_bags` (`bag_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
    },
}

-- Tabelas esperadas após a última versão (usado na conferência pós-migração).
Schema.Tables = {
    'sub_schema_version', 'sub_uniforms', 'sub_uniform_grades', 'sub_uniform_variants',
    'sub_issue_batches', 'sub_bags', 'sub_bag_slots', 'sub_wearing', 'sub_org_settings',
    'sub_points', 'sub_audit', 'sub_incidents', 'sub_recoveries', 'sub_operations',
}

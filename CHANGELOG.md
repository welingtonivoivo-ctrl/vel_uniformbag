# Changelog

## [0.2.0] — 2026-10-12 — Etapa 2 (dados e permissões)

### Adicionado
- Migração versionada e idempotente: 14 tabelas `sub_*` com 8 chaves estrangeiras (`server/db/schema.lua`, `server/db/migrations.lua`).
- Perfis no servidor: emergência (ACE `street_uniformbag.admin`), staff (permissão do mri_Qadmin via natives ACE), líder (chefe do próprio job) — `server/permissions.lua`.
- Registro da permissão "Gerenciar Bolsas de Uniformes" no mri_Qadmin, refeito automaticamente quando ele reinicia.
- Comando de diagnóstico só no console: `uniformbag_perfil <id> [organização]`.

### Verificado (base local)
- Migração aplicada uma vez e repetida 2× sem erro nem duplicação.
- Permissão visível no editor de grupos do mri_Qadmin.
- Líder: reconhecido só no próprio job; perde o acesso ao deixar de ser chefe; job criado no painel do bossmenu funciona sem alterar código.
- Staff: reconhecida pelo grupo do mri_Qadmin; negada com o mri_Qadmin parado (falha fechada); volta ao religar.

## [0.1.0] — 2026-10-12 — Etapa 1 (preparação)

### Adicionado
- Estrutura inicial do recurso (`fxmanifest.lua`, `shared/`, `server/`, `client/`, `web/`).
- Configuração centralizada com todos os limites aprovados (`shared/config.lua`).
- Textos em pt-BR (`shared/locale.lua`).
- Verificação, ao iniciar, das dependências obrigatórias e opcionais, do item no ox_inventory e da cor de identidade.
- Verificação no cliente do modelo da bolsa `reh_prop_reh_bag_outfit_01a`, com resultado no console do servidor.
- Planejamento aprovado em `docs/` (D1–D200).

### Verificado
- Recurso sobe sem erros na base local; 5 dependências obrigatórias e 5 opcionais iniciadas.
- Modelo da bolsa existe, é válido e carrega no jogo (V1).

### Corrigido
- Resultado de natives (`1`/`0`) convertido para booleano antes de enviar ao servidor; o servidor registra relatórios em formato inesperado em vez de descartá-los em silêncio.

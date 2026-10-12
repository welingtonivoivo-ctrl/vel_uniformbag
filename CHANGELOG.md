# Changelog

## [0.4.0] — 2026-10-12 — Nome neutro para distribuição (D210)

### Alterado
- Recurso renomeado de `street_uniformbag` para **`vel_uniformbag`**: pasta, eventos, permissões ACE (`vel_uniformbag.manage` / `vel_uniformbag.admin`), convars de webhook (`vel_uniformbag_webhook_<org>` / `vel_uniformbag_webhook_admin`) e export do item (`vel_uniformbag.useBag`).
- Botão "Abrir loja de roupas" do painel abre o menu normal das lojas do mri_Qappearance, com o preço das lojas (D211).
- Nome da bolsa no inventário é só o nome do uniforme; bolsas em estoque são renomeadas ao iniciar (D212).
- Bolsas novas entram no baú empilhadas por uniforme e ganham número de série no primeiro uso (D213).
- Painel: excluir uniformes sem bolsas entregues; versões masculina e feminina separadas, cada uma com seu botão (D214).
- Painel: aba "Baús" com regra só masculino / só feminino por baú (D215) e botão para limpar as bolsas de um baú (D216).
- Removida a marca da cidade (autor, descrição, README, tutorial e documentos). `#6400E6` passa a ser só a cor padrão quando o servidor não define `mri:color`.

### Atenção ao atualizar
- No `items.lua` do ox_inventory, trocar o export do item `uniform_bag` para `vel_uniformbag.useBag`.
- No `server.cfg`, renomear as convars de webhook.
- No mri_Qadmin, marcar a permissão nova no grupo da staff (a antiga deixa de valer).
- No `items.lua`, o item `uniform_bag` passa a `stack = true` (D213).
- Item `uniform_bag`, tabelas `sub_*` e dados existentes não mudam.

## [0.3.0] — 2026-10-12 — Etapas 3 e 4 (bolsa e painel)

### Adicionado
- Bolsa de uniforme no jogo: bolsa real no chão, prévia da roupa, troca e retorno das roupas civis, alerta de uso indevido.
- Painel de gestão (`/adminoutfit`, aba Plugins do mri_Qadmin e pontos nas sedes): uniformes, emissão, bolsas, alertas e logs, pontos, auditoria e recuperação.
- Logs no Discord por webhook em convar privada; tutorial em `docs/TUTORIAL-DISCORD.md`.

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

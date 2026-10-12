# Changelog

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

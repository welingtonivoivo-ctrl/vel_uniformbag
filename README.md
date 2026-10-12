# vel_uniformbag — Sistema de Bolsas de Uniformes

Recurso para servidores **FiveM / QBox** para bolsas físicas de uniforme: emitidas pelas organizações, trocam a roupa do personagem pela farda oficial do cargo, guardam as roupas civis em compartimentos e registram alertas e auditoria de uso indevido.

> **Situação:** etapa 1 (preparação). Ainda sem funcionalidades para o jogador.

## Documentação

O planejamento aprovado está em [`docs/`](docs):

| Documento | Conteúdo |
|---|---|
| `00-DECISOES.md` | Registro de decisões (D1–D198) |
| `01-PRD.md` | Requisitos do produto |
| `02-TRD.md` | Requisitos técnicos |
| `03-FLUXO.md` | Fluxos do sistema |
| `04-DESIGN.md` | Briefing de design |
| `05-BACKEND.md` | Esquema do banco |
| `06-PLANO.md` | Plano de implementação em seis etapas |

## Dependências

Obrigatórias: `ox_lib`, `oxmysql`, `qbx_core`, `ox_inventory`, `mri_Qappearance`.
Opcionais: `mri_Qadmin` (painel da staff), `ps-dispatch` (alertas), `mri_Qbossmenu` (baús), `mri_Qinteract` (pontos nas sedes).

## Instalação

1. A pasta precisa se chamar exatamente `vel_uniformbag`, dentro de `resources/[meus_scripts]/`.
2. `ensure vel_uniformbag` depois das dependências.
3. Webhooks do Discord e a ACE de emergência ficam **somente** no `server.cfg` do servidor (convars privadas), nunca neste repositório.

## Configuração

Todos os limites ficam em `shared/config.lua`.

# vel_uniformbag — Sistema de Bolsas de Uniformes

Recurso para servidores **FiveM / QBox** com bolsas físicas de uniforme. As organizações mantêm as bolsas nos próprios baús, a bolsa troca a roupa do personagem pela farda oficial do cargo, guarda as roupas civis em compartimentos e registra alertas e auditoria de uso indevido.

> **Situação (0.4.1):** etapas 1 a 4 concluídas e instaladas na cidade. A etapa 5 (qualidade) teve a revisão de código feita; falta o roteiro de testes em jogo. Veja `docs/06-PLANO.md` → "Situação das etapas".

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/MANUAL.md`](docs/MANUAL.md) | **Manual de uso** para staff e líderes (comece por aqui) |
| [`docs/TUTORIAL-DISCORD.md`](docs/TUTORIAL-DISCORD.md) | Como ligar os logs no Discord |
| `docs/00-DECISOES.md` | Registro de decisões (D1–D229) |
| `docs/01-PRD.md` | Requisitos do produto |
| `docs/02-TRD.md` | Requisitos técnicos |
| `docs/03-FLUXO.md` | Fluxos do sistema |
| `docs/04-DESIGN.md` | Briefing de design |
| `docs/05-BACKEND.md` | Esquema do banco |
| `docs/06-PLANO.md` | Plano de implementação e situação de cada etapa |

## Dependências

Obrigatórias: `ox_lib`, `oxmysql`, `qbx_core`, `ox_inventory`, `mri_Qappearance`.
Opcionais: `mri_Qadmin` (permissão e aba Plugins), `ps-dispatch` (alertas), `mri_Qbossmenu` (baús das organizações), `mri_Qinteract` (pontos nas sedes e bolsa no chão).

## Instalação

1. A pasta precisa se chamar exatamente **`vel_uniformbag`**.
2. Acrescente o item ao `ox_inventory/data/items.lua` (faça backup antes):

   ```lua
   ['uniform_bag'] = {
       label = 'Bolsa de Uniforme',
       weight = 1500,
       stack = true,
       close = true,
       consume = 0,
       description = 'Bolsa de uniforme oficial. Use para trocar de roupa.',
       server = { export = 'vel_uniformbag.useBag' },
   },
   ```

3. No `server.cfg`, depois das dependências: `ensure vel_uniformbag`.
4. Reinicie o servidor. As tabelas `sub_*` são criadas sozinhas no primeiro início (migração idempotente).
5. No **mri_Qadmin → Perms**, marque a permissão **"Gerenciar Bolsas de Uniformes"** (`vel_uniformbag.manage`) no grupo da staff.
6. Opcional: os logs no Discord são configurados por convars privadas no `server.cfg` (veja o tutorial). Webhooks **nunca** ficam no código nem no repositório.
7. Opcional (emergência, sem mri_Qadmin): `add_ace identifier.license:XXXX vel_uniformbag.admin allow` no `server.cfg`.

## Configuração

Todos os limites ficam em `shared/config.lua`: compartimentos por bolsa (`Slots`), distância, preço da bolsa extra (`ReplacementPrice`), acessórios que nunca entram na farda (`UniformStripProps`), comando de recuperação (`RecoveryCommand`), dias para inatividade e o código do alerta no ps-dispatch.

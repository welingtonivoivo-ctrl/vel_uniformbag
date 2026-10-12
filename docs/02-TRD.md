# 02 — TRD: Requisitos Técnicos

Versão: 1.1 (consolidada, para aprovação geral) — 2026-10-12
Base investigada: `C:\Users\ivo\Desktop\base_trabalho\base_trabalho` (desenvolvimento). Destino: VPS `C:\street\nova_streer` (implantação, etapa 6).
Toda dependência abaixo foi **verificada na base local**; nada foi presumido.

## 1. Ambiente de execução

| Camada | Conteúdo |
|---|---|
| **server** (Lua 5.4) | Autoridade de tudo: permissões, autorização de uniforme, estado das bolsas e compartimentos, travas de concorrência, emissão, auditoria, alertas, webhooks. |
| **client** (Lua 5.4) | Objeto temporário da bolsa, animações, leitura/aplicação da aparência via mri_Qappearance, abertura da NUI, pontos de interação nas sedes. Nunca decide autorização. |
| **shared** | Configuração (limites, tempos, modelos de ped suportados, mapeamento de componentes), textos pt-BR. |
| **NUI** | HTML + CSS + JavaScript **sem etapa de build** (arquivos estáticos), duas telas: "Bolsa" (uso) e "Painel" (gestão). Cor lida da convar `mri:color`. |

### Dependências verificadas

| Recurso | Versão na base | Papel | Obrigatória |
|---|---|---|---|
| ox_lib | 3.50.0 | callbacks, notificações, utilitários | Sim |
| oxmysql | 2.14.3 | banco | Sim |
| qbx_core | 1.24.1 (conferido em execução na etapa 1) | jogador, empregos, graduações, `isboss`, eventos de emprego, ACE | Sim |
| ox_inventory | 3.2.0 | item, metadados, baús, hooks | Sim |
| mri_Qappearance | 1.10.0 | ler/aplicar/salvar aparência (provides `illenium-appearance`) | Sim |
| mri_Qadmin | 1.35.0 | permissão (`RegisterPermissions`, `HasPerms`) e aba de plugin (`RegisterPlugin`) | Não (falha fechada) |
| mri_Qinteract | 1.2.2 | API `ox_target` (provides `ox_target`) para os pontos das sedes | Sim (para pontos) |
| ps-dispatch | 2.1.7 | entrega do alerta de uso indevido | Não (sem ele, só auditoria) |
| mri_Qbossmenu | 1.0.0 | listar baús das organizações (`GetManagedDefinition`) | Não (há configuração manual) |
| MariaDB | 13.0 local / 12.3 VPS | banco | Sim |

### Configuração centralizada (`shared/config.lua`) — D160
| Chave | Padrão | Origem |
|---|---|---|
| `Slots` | 3 | D44, D53 |
| `MaxDistance` | 3.0 m | D155 |
| `LockSeconds` | 60 | D156 |
| `MaxBagsPerBatch` | 20 | D157 |
| `DefaultBlipSeconds` | 120 (sobrescrito por organização) | D158 |
| `RecoveryCommand` | `minharoupa` | D159 |
| `InactiveDays` | 30 | D163 |
| `InactiveCheckHours` | 6 (também roda ao iniciar o recurso) | D165 |
| `SupportedModels` | `mp_m_freemode_01`, `mp_f_freemode_01` (outros só por configuração explícita) | D68 |
| `ItemName` / `PropModel` | `uniform_bag` / `reh_prop_reh_bag_outfit_01a` | D117, D96 |
Webhooks e ACE ficam fora deste arquivo (convars privadas e server.cfg).

### Nome e versionamento (D167–D169)
- Nome único em tudo: `street_uniformbag` — pasta `resources/[meus_scripts]/street_uniformbag`, `fxmanifest`, prefixos de eventos/callbacks (`street_uniformbag:*`), export do item (`street_uniformbag.useBag`), convars (`street_uniformbag_webhook_*`), ACE (`street_uniformbag.admin`/`.manage`) e repositório GitHub privado `welingtonivoivo-ctrl/street_uniformbag`.
- `.gitignore` mínimo: `*.log`, `*.bak`, `*.tmp`, `*.sql`, `*.zip`, `.env*`, `backup*/`, `node_modules/`, `.vscode/`, `secrets*`, `*.cfg` (nenhum arquivo de configuração privada vai ao repositório). O repositório leva só código, `config.lua` sem segredos, `docs/`, `README.md`, `CHANGELOG.md` e `art/` (fonte `.blend`, script Python do Blender que gera os renders, PNGs finais — D178). `art/` não é carregada pelo FiveM (fora do `fxmanifest`).
- Ferramenta externa de produção (não é dependência de execução): Blender oficial, instalado só na etapa 3 com autorização (D176).

## 2. Framework e integrações

| Necessidade | Recurso/API confirmada | Uso |
|---|---|---|
| Jogador e emprego | `exports.qbx_core:GetPlayer(src)` → `PlayerData.job.name`, `.grade.level`, `.isboss`, `.type`, `.onduty` | Autorização no momento do uso (D9) |
| Estado do personagem | `PlayerData.metadata.isdead`, `.inlaststand`, `.ishandcuffed` (QBox, servidor); statebag `Player(src).state.isDead` (ars_ambulancejob); `cache.vehicle` e `IsPedSwimming` (cliente) | Restrições de uso (D154) |
| Lista de cargos | `exports.qbx_core:GetJobs()` (inclui os cargos sincronizados pelo bossmenu) | Seleção de graduações no cadastro |
| Mudança de emprego | Eventos de servidor `QBCore:Server:OnJobUpdate (src, job)` e `qbx_core:server:onGroupUpdate (src, name, grade?)` | Reavaliação (D34, D41) |
| Permissão admin | Registro: `exports.mri_Qadmin:RegisterPlugin({ ..., requiredPerms, permDefs })` (ou `RegisterPermissions`). Verificação: **natives ACE do FiveM** (`IsPlayerAceAllowed`, `IsPrincipalAceAllowed`) — o mri_Qadmin **não exporta** `HasPerms` (verificado na etapa 1, D199) | Permissão "Gerenciar Bolsas de Uniformes" (D79) |
| ACE de emergência | `IsPlayerAceAllowed(src, 'street_uniformbag.admin')` | D82 |
| Aba no mri_Qadmin | `exports.mri_Qadmin:RegisterPlugin({ id, label, icon, resource, htmlPath, requiredPerms, permDefs })` | D88 |
| Aparência (cliente) | `exports.mri_Qappearance:getPedAppearance(ped)`, `setPedComponents`, `setPedProps`, `getPedModel` | Captura e aplicação |
| Persistência da aparência | evento `illenium-appearance:server:saveAppearance` (mesmo caminho das lojas de roupa) | Manter a roupa após reconexão |
| Inventário | `ox_inventory` exports `AddItem`, `RemoveItem`, `GetSlot`, `SetMetadata`, `CanCarryItem`, `Search`, `GetInventory`, `registerHook` (`createItem`, `swapItems`, `usingItem`) | Item, emissão, rastreio |
| Uso do item | `data/items.lua` do ox_inventory com `server = { export = 'street_uniformbag.useBag' }` | Gatilho de uso (D119) |
| Imagem por organização | metadado `image` (nome do arquivo em `ox_inventory/web/images`, sem extensão), mecanismo já usado pelo próprio ox_inventory em `modules/items/server.lua`. Nome validado no servidor: `^[a-z0-9_]{1,60}$`, sem `/`, `\`, `..` ou extensão; arquivo precisa existir (`LoadResourceFile('ox_inventory', 'web/images/<nome>.png')`); inválido ou ausente ⇒ `uniform_bag` | D121, D174 |
| Baús da organização | `exports.mri_Qbossmenu:GetManagedDefinition(nome, tipo)` → `stashes[]` (IDs registrados no ox_inventory); ou ID informado manualmente | Destino da emissão (D26) |
| Interação | API `ox_target` (`addSphereZone`), atendida pelo mri_Qinteract | Pontos das sedes (D89) |
| Notificação | `lib.notify` (ox_lib) | Mensagens pt-BR |
| Alerta (canal ps-dispatch) | evento de servidor `ps-dispatch:server:notify` disparado **pelo servidor**, `jobs` = tipos de emprego configurados | D5, D124 |
| Alerta (canal próprio) | `TriggerClientEvent` só para os jogadores calculados no servidor (nome do emprego na lista + regra de serviço); cliente mostra `lib.notify` e um blip temporário | D125–D131 |
| Discord | `PerformHttpRequest` (nativo) | Auditoria (D70) |
| Cor/logo | convars `mri:color` (padrão `#6400E6`) e `mri:logo` | D108, D109 |

## 3. Banco de dados

- MariaDB via oxmysql, **consultas sempre parametrizadas**.
- Tabelas próprias com prefixo `sub_` (street uniform bag), detalhadas em `05-BACKEND.md`. Nenhuma tabela de terceiros é alterada (D20, D22).
- Criação por **migração versionada idempotente** (`CREATE TABLE IF NOT EXISTS` + tabela `sub_schema_version`), sem DROP/ALTER destrutivo.
- Roupas dos compartimentos ficam em **tabela ligada ao ID da bolsa**; o item guarda só o ID e metadados leves (I2 confirmada, D187).
- Integridade referencial por chaves estrangeiras, sem cascata a partir da bolsa (D188). Banco é a autoridade; metadados do item são ressincronizados por `SetMetadata` a cada atividade confirmada (D190).

## 4. Autenticação e permissões

| Perfil | Como é identificado (servidor) |
|---|---|
| Staff | Permissão `street_uniformbag.manage` concedida pelos grupos do mri_Qadmin, conferida com natives ACE pelos mesmos caminhos que o mri_Qadmin usa: `IsPlayerAceAllowed(src, nó)`, principal do personagem `char:<citizenid>`, principais de emprego `job.<nome>` / `job.<nome>.<grau>` e o bypass explícito `qadmin.master`. **Não** herda o acesso automático de `god`/`admin` (D82, D199). Só vale com o mri_Qadmin iniciado (D87). |
| Emergência | ACE `street_uniformbag.admin` (`add_ace` explícito no server.cfg) |
| Líder | `PlayerData.job.name == organização` **e** `PlayerData.job.isboss == true` |
| Usuário da bolsa | Qualquer jogador com o item (sem permissão) |

- mri_Qadmin parado/erro (`GetResourceState('mri_Qadmin') ~= 'started'`) → perfil staff **negado** (D87); só a ACE de emergência continua valendo.
- Identidade do personagem: `citizenid` do QBox.
- Cada callback/evento de servidor revalida perfil e escopo da organização (D84).

## 5. Comunicação

| Canal | Nome | Direção | Validação |
|---|---|---|---|
| Export servidor (uso do item) | `useBag` | ox_inventory → servidor | slot real do item no inventário do jogador; bolsa sem trava |
| Callback | `street_uniformbag:openBag` | cliente → servidor | retorna dados da bolsa só para quem está com ela e com a trava |
| Callback | `street_uniformbag:beginChange` | cliente → servidor | valida compatibilidade, espaço, duplicidade e autorização **antes** (D66); grava a operação `iniciada` no diário `sub_operations` com token (D182) |
| Callback | `street_uniformbag:confirmChange` | cliente → servidor | token + resultado da aplicação; servidor grava em transação (D51) |
| Callback | `street_uniformbag:cancelChange` | cliente → servidor | marca a operação como `revertida` e libera a trava (exceto em `finalizando`, D156) |
| Callbacks | `street_uniformbag:panel:*` (listar, salvar uniforme, emitir, auditoria, configurações, pontos, recuperação) | NUI → cliente → servidor | perfil + escopo em todas |
| Evento servidor→cliente | `street_uniformbag:client:*` (abrir NUI, objeto, cancelar) | servidor → cliente | — |
| NUI | `fetch('https://street_uniformbag/...')` | NUI → cliente | cliente só repassa ao servidor |

Sincronização: o objeto temporário é criado pelo cliente de quem usa como **objeto de rede** e removido no encerramento; o servidor registra o netId para remoção em caso de queda (D98, D99).

## 6. Segurança

| Risco | Medida |
|---|---|
| Evento forjado | Nenhum evento de servidor confia em dados do cliente para autorização; tudo por callback com revalidação. Rate limit por jogador. |
| Bolsa usada sem tê-la | Servidor confere o slot e o `bagId` no inventário do jogador a cada passo. |
| Uso simultâneo | Trava em memória por `bagId` (um dono por vez) + coluna `version` com atualização condicional no banco. |
| Perda de roupa | Ordem: valida → registra no diário `sub_operations` → aplica no cliente → confirma → grava em transação. Sem confirmação, nada muda; operação interrompida é revertida com a aparência anterior do diário (D182). Troca no mesmo compartimento é `UPDATE` da linha, nunca apagar e recriar (D180). |
| Contornar a verificação de farda pela troca | Compartimento guarda `uniform_id` quando a roupa é farda — decidido no servidor por "farda em uso" **ou** por coincidência das peças com versões de uniforme cadastradas (D184, D196); vestir dele passa pela autorização. |
| Confirmação de aparência vinda do cliente | Limite assumido (D198): o servidor não vê o ped. Mitigações: a aparência guardada é a capturada no `beginChange` e fica no diário; checagem de formato/tamanho no servidor; marcação de farda no servidor (D196). Um cliente adulterado só consegue afetar a própria aparência; aparências não são itens econômicos. |
| Alerta visível a terceiros | ps-dispatch entrega o alerta a todos os clientes e filtra no cliente (comportamento dele, não alterado). Por isso o alerta leva só o necessário (uniforme, local, código), nunca citizenid. O canal próprio envia só aos destinatários calculados no servidor. |
| Duplicação de itens | **Correção (D191):** o hook `createItem` não bloqueia criação (só altera metadados, `ox_inventory/modules/items/server.lua:224-234`). Medidas reais: a emissão grava cada `bagId` no banco **antes** do `AddItem`; o hook marca como inválida toda bolsa criada por outro recurso (`resource ~= 'street_uniformbag'`) ou sem `bagId` reservado; bolsa inválida/desconhecida não tem efeito (D190). Emissão com chave de idempotência. Duplicidade: no uso e em cada movimentação, se o inventário atual difere do último registrado sem transferência registrada, o servidor confere o inventário anterior (se carregado) com `Search`; mesma `bagId` nos dois ⇒ `flagged_duplicate = 1`, uso bloqueado, auditoria `duplicacao` (D189). Inventário anterior não carregado (jogador offline) ⇒ registra "localização divergente" sem bloquear — detecção não exaustiva (D198). |
| Emissão não autorizada | Só pelo painel, com perfil validado; limites por lote configuráveis. |
| Webhook exposto | URLs só em convars de servidor (`set`, nunca `setr`); nunca enviadas à NUI nem ao repositório (D76). |
| SQL injection | Só consultas parametrizadas. |
| Dados pessoais | Discord recebe citizenid e nome do personagem, nunca identificadores de conta (licença, Discord, IP). |
| Alerta bloqueado pelo infrator | Alerta disparado pelo servidor com coordenadas lidas no servidor. |

## 7. Decisões técnicas

| # | Decisão | Motivo | Alternativas | Consequência |
|---|---|---|---|---|
| T1 | Recurso novo, sem código do qs-outfitbag | Núcleo criptografado e licença (D1) | Adaptar o qs-outfitbag | Mais código próprio, total controle |
| T2 | Roupas em tabela, item só com ID (I2 confirmada, D187) | Tamanho dos dados; detecção de duplicação; histórico e recuperação | Tudo nos metadados | Depende do banco; requer consistência transacional |
| T3 | Confirmação em duas fases (begin/confirm) **com diário persistente** `sub_operations` | Não perder roupa (D51, D182); sobreviver a desconexão e reinício | Tokens só em memória | Uma tabela a mais; reconciliação ao iniciar e ao carregar o personagem |
| T4 | NUI estática sem build | Simplicidade de manutenção | React/Vite | Interface feita à mão, mas sem toolchain |
| T5 | Alerta via `ps-dispatch:server:notify` no servidor | Não depende do cliente do infrator | Export `CustomAlert` (cliente) | Nome da rua não disponível no servidor (resolvido em T12) |
| T14 | Hook `createItem` usado para **marcar** (não bloquear) bolsas criadas fora da emissão | API real do ox_inventory (D191) | Alterar o ox_inventory | Bolsa indevida existe no inventário, mas sem efeito |
| T15 | Detecção de duplicidade só em pontos de contato (uso e movimentação) | Barato e sem varrer inventários (D189, D165) | Varredura periódica de todos os inventários | Detecção não exaustiva, documentada (D198) |
| T6 | Líder = `isboss` do QBox | bossmenu sem API pública de permissão | Ler tabelas internas do bossmenu | Permissões finas do bossmenu não são consideradas |
| T7 | Item cadastrado em `ox_inventory/data/items.lua` | Único meio de definir itens no ox_inventory | — | Altera arquivo de **configuração** (não código) de terceiro, autorizado na C2 (D117–D123) |
| T10 | Alertas por **adaptadores de canal** (`AlertChannel`: `psdispatch`, `jobnotify`), com orquestrador que monta a ocorrência uma vez e a entrega a cada canal ativo | D124–D134: canais combináveis, troca futura de dispatch sem mexer no núcleo | Chamar o ps-dispatch direto do núcleo | Um módulo a mais; testes por canal |
| T11 | Anti-duplicação calculada no servidor: destinatários do ps-dispatch = jogadores com `job.type` na lista da organização **e** `onduty` (dados do QBox no servidor); excluídos do canal próprio | D127 | Deduplicar no cliente | Depende de a regra do ps-dispatch continuar igual; coberta por teste |
| T12 | Nome da rua calculado no **cliente de quem recebe** (`GetStreetNameAtCoord`) e ponto no mapa temporário (blip removido após tempo configurado) | D128 | Calcular no cliente do infrator | Rua é informativa; coordenadas continuam vindo do servidor |
| T9 | Emissão gratuita, com **ponto de extensão** `IssueCostPolicy` (hoje sempre retorna custo 0) e campo reservado `unit_cost` no lote | D114–D116: cobrança futura sem refatorar | Integrar ps-banking já | Nenhuma dependência financeira nesta versão |
| T13 | Inatividade por coluna `last_activity_at` + rotina periódica com uma única consulta indexada | D163–D165: barato e sobrevive a reinícios (estado no banco) | Verificar bolsas uma a uma / timers por bolsa | Classificação pode atrasar até 6 h — aceitável por ser só administrativa |
| T8 | Reavaliação pelos eventos do QBox + escuta passiva de `illenium-appearance:server:saveAppearance` (registrada também com `RegisterNetEvent` no `street_uniformbag`, sem alterar o mri_Qappearance) + conferência do corpo via callback ao cliente na mudança de cargo | D138–D143 | Só uma das duas fontes | Matriz de decisão D141; resposta do cliente nunca encerra registro sozinha |

## 8. Limitações conhecidas

1. **ps-dispatch filtra por TIPO de emprego e só para quem está em serviço, no cliente.** O canal ps-dispatch usa tipos de emprego; o canal próprio (`jobnotify`) usa nomes reais de empregos do QBox (D124–D134). A anti-duplicação (D127) reproduz no servidor a regra atual do ps-dispatch; se uma atualização dele mudar essa regra, pode haver alerta duplicado ou faltante para alguém até o ajuste — coberto por teste a cada atualização. O alerta do ps-dispatch chega a todos os clientes antes do filtro (D198).
2. O servidor não confirma visualmente a aparência; a confirmação de aplicação vem do cliente (com checagem de consistência no cliente). Um cliente adulterado poderia confirmar sem aplicar — o efeito máximo é a pessoa ficar com a roupa errada no próprio corpo; nenhum dado de outro jogador é perdido; aparências não são itens econômicos (D198).
3. Retiradas e transferências só são detectáveis quando passam pelo ox_inventory (hook `swapItems`, que cobre arrastar entre inventários, dropar, pegar do chão e o "dar item" — `giveItem` chama o hook, verificado em `modules/inventory/server.lua:2550`). **Não** são detectadas como atividade (D164): itens removidos/adicionados direto por exports de outros scripts (`RemoveItem`/`AddItem` — ex.: apreensão, roubo scriptado, limpeza de inventário ao morrer, comandos de admin). Nesses casos a bolsa pode ficar "Desconhecida/Inativa" mesmo existindo; isso não é tratado como perda.
4. **Aparência real (D144):** o servidor do FiveM não lê as peças de roupa do personagem; toda leitura vem do cliente. O salvamento de aparência também é enviado pelo cliente (mesmo modelo de confiança das lojas de roupa da base). Scripts que trocam roupa **sem salvar** não são percebidos pelo monitoramento e podem gerar registros "pendente de verificação" na mudança de cargo.
5. **Bloqueio de criação de item:** o ox_inventory não permite bloquear a criação de um item por hook; bolsas criadas fora da emissão ficam sem efeito (D191).
6. **Duplicidade:** detectada só quando a bolsa é usada ou movimentada pelo ox_inventory e o inventário anterior está carregado; não há garantia de detectar toda duplicação (D189, D198).
7. **Natives devolvem 1/0 (etapa 1, D200):** nesta build, natives como `IsModelInCdimage`, `IsModelValid` e `HasModelLoaded` devolveram o número `1` em vez de `true`. Todo resultado de native usado em decisão (ex.: `IsPedSwimming`, checagens de modelo) passa por conversão explícita para booleano no cliente, e o servidor valida o tipo do que recebe.

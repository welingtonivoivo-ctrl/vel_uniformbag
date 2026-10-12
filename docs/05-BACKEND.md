# 05 — Esquema do Back-end

Versão: 1.1 (consolidada, para aprovação geral) — 2026-10-12
Banco: MariaDB (oxmysql). Prefixo das tabelas: `sub_`. Charset `utf8mb4`. Nenhuma tabela de terceiros é alterada.
**Ajustes técnicos da etapa 2 (D201):** (1) colunas de data/hora usam `DATETIME` em vez de `TIMESTAMP` — o `TIMESTAMP` do MariaDB para em 2038, e a auditoria é permanente (D161); (2) colunas JSON (`LONGTEXT`) recebem `CHECK (JSON_VALID(...))`; (3) `sub_operations` ganhou `restored_at` (quando a aparência anterior foi reaplicada após reversão, §2.13). A implementação está em `server/db/schema.lua`.

## 1. Dados

| Tipo | Entidades |
|---|---|
| Persistentes de organização | uniformes, versões por modelo, graduações autorizadas, configurações da organização, pontos de gestão |
| Persistentes de bolsa | bolsas, compartimentos, lotes de emissão, diário de trocas (`sub_operations`) |
| Persistentes de personagem | farda em uso |
| Administrativos | auditoria, ocorrências, recuperações, versão do esquema |
| Temporários (memória do servidor) | travas por bolsa, anti-duplicação de alertas, fila de envio ao Discord — nada que, perdido num reinício, cause perda de roupa (o diário é persistente, D182) |
| No item do ox_inventory (metadados) | `bagId`, `uniformId`, `org`, `label`, `description`, `image` (D121) e, só em bolsas criadas fora da emissão, `invalid = true` (D191) — identificação e apresentação; **a autoridade é o banco**, e os metadados são ressincronizados a cada atividade (D190) |

Os dados de uniforme e compartimentos pertencem à **identidade da bolsa** (`bag_id`), não ao personagem que a possui (D187).

## 2. Tabelas

### 2.1 `sub_uniforms` — uniforme oficial
| Campo | Tipo | Obrig. | Observação |
|---|---|---|---|
| id | INT UNSIGNED AUTO_INCREMENT | sim | PK |
| org | VARCHAR(60) | sim | nome do emprego no QBox |
| name | VARCHAR(100) | sim | |
| auth_mode | ENUM('lista','faixa') | sim | `lista` = graduações específicas (`sub_uniform_grades`); `faixa` = mínima/máxima (D135) |
| grade_min | SMALLINT | não | obrigatório no modo `faixa` |
| grade_max | SMALLINT | não | opcional no modo `faixa`; NULL = sem teto; deve ser ≥ grade_min |
| active | TINYINT(1) | sim | padrão 1 |
| created_by / updated_by | VARCHAR(60) | sim/não | citizenid ou `staff:<citizenid>` |
| created_at / updated_at | TIMESTAMP | sim | |
Índices: `idx_org (org, active)`.

### 2.2 `sub_uniform_grades` — graduações autorizadas (só no modo `lista`)
| Campo | Tipo | Obrig. |
|---|---|---|
| uniform_id | INT UNSIGNED | sim (FK → sub_uniforms.id, ON DELETE CASCADE) |
| grade | SMALLINT | sim |
PK: `(uniform_id, grade)`.

### 2.3 `sub_uniform_variants` — versão por modelo de ped
| Campo | Tipo | Obrig. | Observação |
|---|---|---|---|
| id | INT UNSIGNED AUTO_INCREMENT | sim | PK |
| uniform_id | INT UNSIGNED | sim | FK → sub_uniforms.id, CASCADE |
| model | VARCHAR(40) | sim | `mp_m_freemode_01`, `mp_f_freemode_01` ou modelo configurado (D68) |
| appearance | LONGTEXT (JSON) | sim | componentes e props |
| captured_by | VARCHAR(60) | sim | |
| updated_at | TIMESTAMP | sim | |
Único: `uq_variant (uniform_id, model)`.

### 2.4 `sub_bags` — bolsas emitidas
| Campo | Tipo | Obrig. | Observação |
|---|---|---|---|
| bag_id | CHAR(12) | sim | PK, ex.: `UB-7K3QX9MD` (aleatório criptográfico, conferido contra colisão) |
| uniform_id | INT UNSIGNED | sim | FK → sub_uniforms.id (sem CASCADE: bolsa preserva histórico) |
| org | VARCHAR(60) | sim | |
| batch_id | INT UNSIGNED | sim | FK → sub_issue_batches.id |
| status | ENUM('em_estoque','em_circulacao','desconhecida','falha_emissao') | sim | |
| location_type / location_id | VARCHAR(20) / VARCHAR(80) | não | último lugar conhecido (stash/player/drop) |
| version | INT UNSIGNED | sim | controle de concorrência dos compartimentos |
| flagged_duplicate | TINYINT(1) | sim | padrão 0; 1 = uso bloqueado até a staff liberar (D189) |
| issued_by / issued_at | VARCHAR(60) / TIMESTAMP | sim | |
| last_withdrawn_by / last_withdrawn_at | VARCHAR(60) / TIMESTAMP | não | |
| last_activity_at | TIMESTAMP | sim | última **atividade confirmada** (D164); padrão = `issued_at` |
| last_activity_kind | VARCHAR(30) | não | `emissao`, `retirada`, `transferencia`, `devolucao`, `uso` |
Índices: `idx_org_status (org, status)`, `idx_uniform (uniform_id)`, `idx_status_activity (status, last_activity_at)` (rotina de inatividade e filtro do painel).
Status `desconhecida` = "Desconhecida/Inativa" (D163): só classificação administrativa; nenhuma outra coluna muda.

### 2.5 `sub_bag_slots` — compartimentos
| Campo | Tipo | Obrig. |
|---|---|---|
| bag_id | CHAR(12) | sim (FK → sub_bags.bag_id, ON DELETE RESTRICT) |
| slot_no | TINYINT UNSIGNED | sim (1..`Config.Slots`) |
| model | VARCHAR(40) | sim |
| appearance | LONGTEXT (JSON) | sim |
| stored_by_citizenid | VARCHAR(60) | sim |
| stored_by_name | VARCHAR(100) | sim |
| stored_at | TIMESTAMP | sim |
| uniform_id | INT UNSIGNED | não (FK → sub_uniforms.id) — preenchido pelo servidor quando a roupa guardada é farda oficial: havia "farda em uso" ao guardar **ou** as peças coincidem com uma versão de uniforme ativa (D184, D196); vesti-la passa pela autorização |
PK: `(bag_id, slot_no)`. Compartimento livre = linha inexistente.
`appearance` guarda a aparência completa retornada pelo mri_Qappearance (componentes, props, drawable/texture, modelo) — nunca parcial (D181). A troca do compartimento K é um `UPDATE` da mesma linha dentro da transação, nunca `DELETE` + `INSERT` separados.

### 2.6 `sub_issue_batches` — lotes de emissão
| Campo | Tipo | Obrig. |
|---|---|---|
| id | INT UNSIGNED AUTO_INCREMENT | sim (PK) |
| idempotency_key | CHAR(36) | sim (único) |
| org / uniform_id / stash_id | VARCHAR(60) / INT / VARCHAR(80) | sim |
| requested / delivered / failed | SMALLINT UNSIGNED | sim |
| unit_cost | INT UNSIGNED | sim (padrão 0; reservado para cobrança futura, D116 — nesta versão sempre 0) |
| status | ENUM('em_andamento','concluido','parcial','falhou') | sim |
| requested_by | VARCHAR(60) | sim |
| created_at / finished_at | TIMESTAMP | sim / não |

### 2.7 `sub_wearing` — farda em uso
| Campo | Tipo | Obrig. |
|---|---|---|
| citizenid | VARCHAR(60) | sim (PK) |
| bag_id / uniform_id / org | CHAR(12) / INT / VARCHAR(60) | sim |
| authorized | TINYINT(1) | sim |
| job_name / job_grade | VARCHAR(60) / SMALLINT | sim (cargo usado na última avaliação) |
| state | ENUM('ativo','pendente') | sim (`pendente` = verificação inconclusiva, D141) |
| since | TIMESTAMP | sim |
| last_check_at | TIMESTAMP | não |

### 2.8 `sub_org_settings` — configurações por organização
| Campo | Tipo | Obrig. | Observação |
|---|---|---|---|
| org | VARCHAR(60) | sim | PK |
| alert_enabled | TINYINT(1) | sim | padrão 0 (nada é enviado sem configuração — D13) |
| alert_mode | ENUM('psdispatch','jobnotify','ambos') | sim | padrão `psdispatch` (D126) |
| alert_job_types | VARCHAR(255) (JSON) | não | tipos para o ps-dispatch, ex.: `["leo"]` |
| alert_job_names | VARCHAR(500) (JSON) | não | empregos do canal próprio, ex.: `["pmesp","rota"]` (D125) |
| alert_onduty_only | TINYINT(1) | sim | canal próprio só para quem está em serviço; padrão 1 (D130) |
| alert_blip_seconds | SMALLINT UNSIGNED | sim | duração do ponto no mapa; padrão 120 (`Config.DefaultBlipSeconds`, D158); marca o local do uso, sem seguir o jogador |
| alert_code / alert_priority | VARCHAR(10) / TINYINT | não | |
| log_categories | VARCHAR(500) (JSON) | não | categorias ativas no Discord |
| default_stash_id | VARCHAR(80) | não | baú padrão da emissão |
| item_image | VARCHAR(60) | não | nome da imagem do item da organização; vazio, inválido ou arquivo inexistente = `uniform_bag` (padrão roxa); validado no servidor antes de gravar (D121, D174) |
| updated_by / updated_at | VARCHAR(60) / TIMESTAMP | não | |
O endereço do webhook **não** fica no banco: fica na convar privada `street_uniformbag_webhook_<org>` / `street_uniformbag_webhook_admin` (D76).

### 2.9 `sub_points` — pontos de gestão
| Campo | Tipo | Obrig. |
|---|---|---|
| id | INT UNSIGNED AUTO_INCREMENT | sim (PK) |
| org / label | VARCHAR(60) / VARCHAR(80) | sim |
| x, y, z | DECIMAL(10,3) | sim |
| radius | DECIMAL(4,2) | sim (padrão 1.5) |
| active | TINYINT(1) | sim |
| created_by / created_at | VARCHAR(60) / TIMESTAMP | sim |

### 2.10 `sub_audit` — auditoria
| Campo | Tipo | Obrig. |
|---|---|---|
| id | BIGINT UNSIGNED AUTO_INCREMENT | sim (PK) |
| created_at | TIMESTAMP(3) | sim |
| category | VARCHAR(30) | sim (`emissao`, `retirada`, `transferencia`, `devolucao`, `troca`, `uso_indevido`, `mudanca_cargo`, `pendente_verificacao`, `admin`, `recuperacao`, `duplicacao`, `sistema`) |
| action | VARCHAR(60) | sim |
| org / bag_id / uniform_id | VARCHAR(60) / CHAR(12) / INT | não |
| actor_citizenid / actor_name | VARCHAR(60) / VARCHAR(100) | não |
| x, y, z | DECIMAL(10,3) | não |
| data | LONGTEXT (JSON) | não (cargo anterior/atual, aparência recuperável etc.) |
| discord_status | ENUM('nao_aplica','pendente','enviado','falhou') | sim |
Índices: `idx_bag (bag_id, created_at)`, `idx_org_cat (org, category, created_at)`, `idx_actor (actor_citizenid, created_at)`.

### 2.11 `sub_incidents` — ocorrências de uso indevido (D132)
| Campo | Tipo | Obrig. |
|---|---|---|
| id | CHAR(36) | sim (PK, UUID) |
| kind | ENUM('vestir','mudanca_cargo') | sim |
| bag_id / uniform_id / org | CHAR(12) / INT / VARCHAR(60) | sim |
| citizenid / char_name | VARCHAR(60) / VARCHAR(100) | sim |
| job_before / job_after | VARCHAR(80) | não (cargo anterior/atual) |
| x, y, z | DECIMAL(10,3) | sim |
| channels | VARCHAR(500) (JSON) | sim (ex.: `{"psdispatch":"enviado","jobnotify":"sem_destinatarios"}`) |
| created_at | TIMESTAMP(3) | sim |
Índices: `idx_org_time (org, created_at)`, `idx_bag (bag_id)`, `idx_char (citizenid)`.

### 2.12 `sub_recoveries` — recuperações administrativas (D146–D153)
| Campo | Tipo | Obrig. |
|---|---|---|
| id | INT UNSIGNED AUTO_INCREMENT | sim (PK) |
| citizenid | VARCHAR(60) | sim (beneficiado) |
| model | VARCHAR(40) | sim |
| appearance | LONGTEXT (JSON) | sim (roupa a restaurar) |
| reason | VARCHAR(500) | sim |
| created_by / created_at | VARCHAR(60) / TIMESTAMP | sim |
| status | ENUM('aguardando','concluida','cancelada') | sim |
| previous_appearance | LONGTEXT (JSON) | não (aparência antes da aplicação, para reversão) |
| applied_at | TIMESTAMP | não |
| source_audit_id | BIGINT UNSIGNED | não (registro de auditoria de origem) |
Índice: `idx_char_status (citizenid, status)`.
Regras: só o próprio `citizenid` aplica; transição `aguardando → concluida` por `UPDATE ... WHERE id = ? AND status = 'aguardando'` (impede aplicação duplicada); cancelamento só pela staff, com auditoria.

### 2.13 `sub_operations` — diário de trocas (D182, D197)
| Campo | Tipo | Obrig. |
|---|---|---|
| token | CHAR(36) | sim (PK) |
| bag_id / slot_no | CHAR(12) (FK → sub_bags, RESTRICT) / TINYINT | sim / não |
| citizenid | VARCHAR(60) | sim |
| kind | ENUM('vestir_uniforme','vestir_compartimento') | sim |
| state | ENUM('iniciada','concluida','revertida') | sim |
| before_appearance | LONGTEXT (JSON) | sim (roupa no corpo antes) |
| target_appearance | LONGTEXT (JSON) | sim (roupa a vestir) |
| bag_version | INT UNSIGNED | sim (versão da bolsa no início) |
| created_at / finished_at | TIMESTAMP(3) | sim / não |
| saved_at | TIMESTAMP(3) | não (chegada do `saveAppearance` do jogador após a conclusão, D197) |
| restored_at | DATETIME(3) | não (aparência anterior reaplicada ao jogador após a reversão, D201) |
Índice: `idx_char_state (citizenid, state)`.
Regras: `iniciada` gravada no `beginChange`; `confirmChange` faz, na mesma transação, compartimento + versão da bolsa + farda em uso + `state = 'concluida'` (`WHERE token = ? AND state = 'iniciada'`, impede repetição). Ao iniciar o recurso: todas as `iniciada` ⇒ `revertida`. Quando o personagem carrega: se houver operação dele revertida e ainda não reaplicada, o cliente recebe `before_appearance`; se houver `concluida` sem `saved_at`, reaplica `target_appearance`. Registros ficam no banco como parte do histórico (auditoria permanente, D161).

### 2.14 `sub_schema_version`
| Campo | Tipo |
|---|---|
| version | INT (PK) |
| applied_at | TIMESTAMP |

## 3. Propriedade dos dados

| Dado | Pertence a | Consultar | Criar | Editar | Excluir |
|---|---|---|---|---|---|
| Uniformes e versões | organização | líder (própria), staff | líder (própria), staff | líder (própria), staff | **desativar** apenas (histórico preservado) |
| Bolsas | organização emissora | líder (própria), staff | líder/staff (emissão) | só o sistema | nunca |
| Compartimentos | a bolsa | quem está usando a bolsa (só a lista), staff | o sistema (troca) | o sistema (troca) | o sistema, só quando a roupa é vestida (sai do compartimento) ou trocada (D180); nunca descarte (D192); staff não apaga — a recuperação cria registro separado (D146) |
| Diário de trocas | a bolsa | staff | sistema | sistema (estado) | nunca (D161) |
| Farda em uso | personagem | staff | sistema | sistema | sistema |
| Configurações/pontos | organização | líder (própria), staff | líder (própria), staff | líder (própria), staff | desativar |
| Auditoria | administração | líder (própria org), staff | sistema | ninguém | ninguém — permanente (D161) |

## 4. Regras de segurança

- Servidor é a autoridade de todas as operações; o cliente nunca grava diretamente.
- Identidade: `citizenid` do QBox obtido no servidor a partir do `source`.
- Cargos: emprego e graduação atuais no QBox no momento da operação.
- Propriedade da bolsa: o `bagId` precisa estar num slot do inventário do jogador em cada passo.
- Concorrência: trava por bolsa em memória + `UPDATE sub_bags SET version = version + 1 WHERE bag_id = ? AND version = ?` dentro de transação com as mudanças de compartimento; se nenhuma linha mudar, operação recusada.
- Trava (D156): `Config.LockSeconds` (60), renovada enquanto a tela está aberta; estados `aberta → finalizando → livre`; em `finalizando` a trava **não expira** nem é liberada por desconexão até a transação terminar (sucesso ou reversão). Erros relevantes vão para o log do servidor e para `sub_audit` (D160).
- Emissão: lote acima de `Config.MaxBagsPerBatch` (20) é recusado no servidor (D157).
- Repetição de eventos: token de operação de uso único; alertas com chave anti-duplicação (bolsa + personagem + token).
- Emissão: chave de idempotência por lote; a bolsa é gravada no banco **antes** do `AddItem`; o hook `createItem` **não bloqueia** (limite do ox_inventory, D191) — ele marca `invalid = true` em toda `uniform_bag` criada por outro recurso ou sem `bagId` reservado, e essa bolsa não tem efeito (D190).
- Duplicação (D189): em cada uso/movimentação, se o inventário atual difere do último registrado sem transferência registrada, o servidor confere o inventário anterior (se carregado); mesma `bagId` nos dois ⇒ `flagged_duplicate = 1`, uso bloqueado, auditoria `duplicacao`; só a staff libera, com motivo. Inventário anterior não carregado ⇒ auditoria "localização divergente", sem bloqueio. Nenhum conjunto é copiado: as cópias apontam para as mesmas linhas.
- Integridade referencial (D188): `sub_bags.uniform_id` → `sub_uniforms` (RESTRICT); `sub_bag_slots.bag_id` → `sub_bags` (RESTRICT); `sub_operations.bag_id` → `sub_bags` (RESTRICT); uniformes e bolsas nunca são excluídos (só desativados/classificados).
- Consultas sempre parametrizadas.
- Dados pessoais: só citizenid e nome do personagem; nada de licença, Discord ou IP.

## 5. Ciclo de vida

| Dado | Criação | Atualização | Arquivamento | Exclusão |
|---|---|---|---|---|
| Uniforme | cadastro no painel | edição | `active = 0` | nunca (preserva vínculo das bolsas) |
| Bolsa | emissão | uso/rastreio (atualiza `last_activity_at`) | status `desconhecida` após `Config.InactiveDays` (30) sem atividade confirmada; volta a `em_circulacao`/`em_estoque` na próxima atividade (D163) | nunca |
| Compartimento | troca confirmada | troca confirmada (`UPDATE` da mesma linha, D180) | — | só quando a roupa é vestida sem que outra entre no lugar (roupa atual era o uniforme desta bolsa, D193) |
| Diário de trocas | `beginChange` | `confirmChange` / reversão / `saved_at` | — | nunca |
| Farda em uso | vestir uniforme | mudança de cargo | — | ao tirar a farda pela bolsa ou ao detectar que não está mais no corpo |
| Auditoria | cada evento | `discord_status` | futuro, administrativo (D162) — não implementado na v1 | **nunca automática** (D161) |

Rotina de inatividade (D165): ao iniciar o recurso e a cada 6 h, `UPDATE sub_bags SET status = 'desconhecida' WHERE status = 'em_circulacao' AND last_activity_at < NOW() - INTERVAL ? DAY` (usa `idx_status_activity`); cada bolsa reclassificada gera auditoria `sistema` (`inativa`), e o retorno gera `sistema` (`reativada`). Bolsas `em_estoque` não ficam inativas: estão num baú conhecido.
Arquivamento futuro (D162): tabela `sub_audit` já é append-only com `id` sequencial e `created_at` indexado, o que permite mover faixas antigas para `sub_audit_archive` numa versão futura, só por ação administrativa.

Recuperação após falha: operações só gravam em transação; reinício do recurso limpa travas em memória e reconcilia o diário `sub_operations` (revertendo as `iniciada`, D182); envios ao Discord pendentes são reenviados.

## 6. Migrações

- **Alterações:** apenas criação das tabelas `sub_*` (versão 1). Nenhuma alteração em tabelas existentes.
- **Compatibilidade:** não há dados anteriores deste sistema; nada a migrar do qs-outfitbag (a tabela dele não existe na base).
- **Backup:** antes de aplicar na VPS, dump do banco `street` (somente leitura do banco atual).
- **Reversão:** parar o recurso; as tabelas `sub_*` podem permanecer sem efeito. Remover tabelas só com autorização explícita (destrutivo).
- **Riscos de perda:** nenhum sobre dados existentes, pois nada existente é alterado.
- **Versionamento (D169):** o repositório `street_uniformbag` contém só os arquivos de migração (estrutura); nunca dumps, dados de jogadores, senhas do banco ou backups do `items.lua`.
- **Fora das tabelas (autorizado na C2, D117–D123):** entrada do item `uniform_bag` em `ox_inventory/data/items.lua` e imagens PNG em `ox_inventory/web/images`. Procedimento: (1) conferir que `uniform_bag` não existe; (2) backup verificável (hash) do `items.lua`; (3) acrescentar só o bloco do item; (4) validar a sintaxe (o ox_inventory sobe sem erro e o item aparece); (5) testar. **Reversão:** restaurar o `items.lua` do backup e remover as imagens adicionadas. Imagens: só as quatro aprovadas (D170, D175), copiadas apenas na base local após a autorização geral; os originais (PNG, `.blend` e script) ficam em `street_uniformbag/art/` no repositório (D178).

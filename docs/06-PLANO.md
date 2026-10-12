# 06 — Plano de Implementação

Versão: 1.1 (consolidada, para aprovação geral) — 2026-10-12
Ambiente de desenvolvimento e testes: base local `base_trabalho` (banco local `base_trabalho`). A VPS só é tocada na etapa 6, com autorização.
Versionamento: repositório privado `welingtonivoivo-ctrl/vel_uniformbag`, primeira publicação só após autorização (regra 15.4, D167–D169).
**Autorizações:** a aprovação geral deste planejamento **não** autoriza nenhuma etapa. Cada etapa começa só com sua autorização expressa; ações sensíveis dentro dela (publicar no GitHub, instalar o Blender, alterar o `items.lua`, copiar imagens, criar tabelas, mexer na VPS) pedem autorização própria no momento. O servidor local é iniciado/reiniciado **por você** (instalador MRI); eu não inicio o FXServer.

## Etapa 1 — Preparação
- **Objetivo:** estrutura do recurso, dependências confirmadas em execução, repositório.
- **Arquivos:** `fxmanifest.lua`, `shared/config.lua` (todas as chaves do TRD §1), `shared/locale.lua`, `server/main.lua` (vazio funcional), `client/main.lua`, `web/` (esqueleto), `.gitignore`, `README.md`, `CHANGELOG.md`.
- **Dependências:** ox_lib, oxmysql, qbx_core, ox_inventory, mri_Qappearance, mri_Qinteract (pontos); opcionais mri_Qadmin, ps-dispatch, mri_Qbossmenu.
- **Criado:** recurso que inicia sem erros e registra no log as dependências encontradas; verificação em jogo de que o modelo `reh_prop_reh_bag_outfit_01a` existe (`IsModelInCdimage`) — senão, propor alternativa (D96).
- **Resultado esperado:** `ensure vel_uniformbag` sobe limpo no servidor local.
- **Aceitação:** zero erros no console do servidor e do cliente; modelo confirmado ou alternativa apresentada.
- **Testes:** você sobe o servidor local; eu leio `fxserver.log` e o log do cliente.
- **Riscos:** baixo. **Reverter:** remover a pasta do recurso.
- **Git (D167–D169):** (1) `gh repo view welingtonivoivo-ctrl/vel_uniformbag` para confirmar que não existe; (2) `git init` na pasta `vel_uniformbag`, `.gitignore` conforme TRD; (3) conferir a lista de arquivos preparados (sem segredos, backups, logs, dumps); (4) **só com sua autorização da primeira publicação:** criar o repositório **privado** e enviar o primeiro commit em pt-BR. Sem force push. Nada na VPS.

## Etapa 2 — Dados e permissões
- **Objetivo:** tabelas, permissões, perfis.
- **Arquivos:** `server/db/migrations.lua`, `server/db/*.lua` (acesso por tabela), `server/permissions.lua`.
- **Criado:** migração v1 (14 tabelas `sub_*` do `05-BACKEND.md`, incluindo o diário `sub_operations`, com chaves estrangeiras sem cascata a partir da bolsa — D188), idempotente; registro da permissão "Gerenciar Bolsas de Uniformes" no mri_Qadmin; ACE `vel_uniformbag.admin`; função única `GetProfile(src, org)` → staff / emergência / líder / nenhum.
- **Resultado:** tabelas criadas no banco **local** (com sua autorização); perfis corretos.
- **Aceitação:** migração roda 2× sem erro nem duplicação; permissão aparece em Perms; líder só obtém a própria organização; mri_Qadmin parado ⇒ staff negada (falha fechada).
- **Testes:** reiniciar o recurso; alternar a permissão de um grupo no mri_Qadmin; parar o mri_Qadmin e repetir.
- **Riscos:** médio (permissões). Mitigação: testes negativos obrigatórios.
- **Reverter:** parar o recurso; tabelas locais podem ser removidas (banco local de testes, com autorização).

## Etapa 3 — Funcionalidade principal
- **Objetivo:** item, cadastro mínimo, emissão, uso da bolsa (vestir uniforme e roupa guardada), autorização, alerta, imagens.
- **Arquivos:** `server/bags.lua`, `server/uniforms.lua`, `server/issue.lua`, `server/change.lua` (duas fases + diário), `server/integrity.lua` (invalidez, duplicidade, ressincronização de metadados), `server/alerts.lua`, `client/bag.lua`, `client/appearance.lua`, `web/bag.*`, `art/`; entrada do item em `ox_inventory/data/items.lua` (com backup, C2).
- **Alertas:** orquestrador de ocorrências + adaptador `psdispatch` nesta etapa; adaptador `jobnotify` (canal próprio, anti-duplicação, rua e ponto temporário) na etapa 4.
- **Criado:**
  - item "Bolsa de Uniforme" (procedimento do `05-BACKEND.md` §6: conferir, backup com hash, só o bloco, validar);
  - imagens (D170–D179): (a) pedir autorização específica e instalar o Blender oficial de `blender.org`; (b) modelar a bolsa por script e renderizar as quatro versões em `art/`; (c) apresentar; (d) ajustar até a aprovação ou, se a qualidade não for atingida, apresentar resultado e alternativas; (e) só então copiar para a base local;
  - hook `createItem` marcando bolsas criadas fora da emissão como inválidas (D191); emissão em lote com idempotência e bolsa gravada antes do `AddItem`;
  - tela "Bolsa" com o uniforme oficial separado dos compartimentos (D195) e confirmação "vestir / guardar" (D185);
  - operação em duas fases com diário persistente, trava com estado `finalizando`, versão da bolsa, recuperação §4.1 do FLUXO (D182, D197);
  - compatibilidade por modelo; classificação regular/indevido; marcação de farda no servidor (D196); alerta via ps-dispatch; auditoria em banco; bloqueio de bolsa duplicada (D189).
- **Resultado:** ciclo completo vestir/tirar funcionando, com rastreio básico.
- **Aceitação:** critérios 1, 2, 3, 4, 6, 7, 8 e 10 do PRD (seção 7, contados na ordem em que aparecem) passam.
- **Testes:** dois clientes locais (Cliente Principal e Segundo Cliente):
  - uso regular, uso indevido, compartimentos cheios, incompatibilidade de modelo, uso simultâneo, desconexão no meio;
  - `/giveitem uniform_bag` ⇒ bolsa "Não reconhecida", sem efeito, auditada (D191);
  - limites da C7: usar morto, em última chance, algemado, em veículo e nadando; afastar-se 3 m+; expirar a trava; desconectar durante a finalização; emitir 21 bolsas (recusar);
  - I1 (D186): com 3 compartimentos cheios, vestir cada um e conferir que a roupa anterior ficou exatamente no mesmo compartimento, com todas as peças e texturas; "Vestir uniforme" desabilitado com tudo cheio (D192); forçar erro na aplicação, cancelar na confirmação, desconectar e reiniciar o recurso entre `begin` e `confirm` (roupa anterior restaurada, nada perdido nem duplicado); concluir e desconectar antes do salvamento (reaplicação ao voltar, D197);
  - farda: guardar uma farda e vesti-la de novo sem autorização (ocorrência); guardar como "civil" uma roupa idêntica a uma farda cadastrada (marcada como farda, D196); compartimento incompatível (recusado no servidor);
  - integridade (D187–D190): bolsa roubada/dropada/no baú/após reinício mantém os compartimentos; simular duplicidade (mesma `bagId` em dois inventários carregados) ⇒ bloqueio + auditoria; liberar pela staff.
- **Riscos:** alto (aparência e dados). Mitigação: duas fases, diário, transação, testes de falha.
- **Reverter:** desativar o recurso; restaurar `items.lua` do backup; remover as imagens copiadas.

## Etapa 4 — Funcionalidades complementares
- **Objetivo:** painel completo, pontos, reavaliação, rastreio, Discord, recuperação.
- **Arquivos:** `server/panel.lua`, `server/points.lua`, `server/reevaluate.lua`, `server/tracking.lua`, `server/discord.lua`, `server/recovery.lua`, `client/points.lua`, `web/panel.*`.
- **Portas do Painel:** aba de plugin no mri_Qadmin (staff), pontos nas sedes (líderes) e comando **`/adminoutfit`** (só staff, D205); botão **"Abrir loja de roupas"** gratuito, só roupas (D206). Os comandos provisórios da etapa 3 (`/ubag_*`) saem quando o painel estiver pronto.
- **Criado:** abas Uniformes (versões M/F), Emissão, Estoque (inclui filtro "Duplicadas" e "Liberar bolsa"), Alertas e logs, Pontos, Auditoria, Recuperação; registro do plugin no mri_Qadmin; pontos das sedes (coordenadas apresentadas para aprovação, D92); reavaliação por eventos do QBox; hook `swapItems`; adaptador `jobnotify`; fila de envio ao Discord com reenvio; rotina de inatividade.
- **Resultado:** sistema completo conforme o PRD.
- **Aceitação:** critérios 5, 9, 11 e 12 do PRD passam; mesma interface nas duas portas.
- **Testes (D145):** troca pela bolsa, loja de roupas, guarda-roupa residencial, vestiário, desconexão, reconexão e mudança de cargo — cada um verificando a matriz D141; promoção/rebaixamento/demissão com farda no corpo; Discord desligado; troca de mãos (dar, dropar, pegar, baú); recuperação (D146–D153): registro offline, aviso após carregamento, restaurar agora/depois, `/minharoupa`, falha na aplicação, aplicar duas vezes, outro personagem tentando aplicar; inatividade (C8) com `InactiveDays` reduzido; anti-duplicação de alertas com jogador que recebe pelos dois canais.
- **Riscos:** médio. **Reverter:** desativar o recurso.

## Etapa 5 — Qualidade e segurança
- **Objetivo:** corrigir erros, provar permissões e robustez.
- **Testes:** roteiro completo dos critérios do PRD; testes negativos de permissão (líder de outra organização, jogador comum chamando callbacks, NUI forjada); repetição rápida de eventos; reinício do recurso no meio de uma troca; desempenho (resmon do recurso abaixo de 0,05 ms ocioso).
- **Aceitação:** todos os critérios do PRD aprovados por você em teste na base local.
- **Reverter:** n/a (correções versionadas no Git).

## Etapa 6 — Implantação na VPS (somente com autorização)
- **Objetivo:** levar à cidade com segurança.
- **Passos:** dump do banco `street`; backup de `ox_inventory/data/items.lua` da VPS; copiar o recurso e as imagens aprovadas; acrescentar a entrada do item; configurar convars privadas (webhooks) e `add_ace` de emergência no server.cfg (com backup e autorização); reinício por você via MRI/txAdmin; validação em produção com roteiro curto.
- **Reverter:** remover o recurso e a entrada do item (restaurar backup); tabelas `sub_*` permanecem inertes.

---

# Conferência final dos seis documentos (2026-10-12)

## A. Contradições encontradas e como foram tratadas
1. Briefing original ("verifica se pertence à organização antes de usar") × D4 (qualquer um usa) → a verificação **classifica** o uso, não bloqueia (D11).
2. "Roupa fica na bolsa" × compartimentos cheios → troca no mesmo compartimento (I1, D180–D186).
3. D47 ("impede guardar nova roupa com tudo cheio") × D180 ("troca funciona com tudo cheio") → **não há conflito**: são operações diferentes, esclarecidas em D192 sem alterar nenhuma das duas.
4. D13/D19 "destinatário configurável" × ps-dispatch filtrar por tipo → canal próprio por nome de emprego (C3, D124–D134).
5. D16 "respeitar permissões do bossmenu" × bossmenu sem API pública → líder = `isboss` (T6).
6. **TRD dizia que o hook `createItem` bloqueia a criação; o código do ox_inventory mostra que não** (só altera metadados). Corrigido como **decisão técnica nova** (D191): bolsa criada fora da emissão fica sem efeito — o critério do PRD já previa "bloqueados **ou** ficam sem efeito". Nenhuma decisão de produto mudou.
7. D4 (qualquer um usa) × bloqueio de bolsa duplicada (I2) → bloqueio de **integridade**, não de propriedade (D189).

## B. Funcionalidades presentes em um documento e ausentes em outro
- Nenhuma após a revisão: todas as funcionalidades do PRD §4.1 e as regras de I1/I2 têm fluxo (03), tela (04), dados (05) e etapa com teste (06).

## C. Decisões de produto
- C1–C10.1, I1 e I2: **todas resolvidas** (D114–D198). Nenhuma pergunta de produto em aberto.

## D. Verificações técnicas durante a implementação (não são decisões de produto)
| # | Verificação | Etapa | Se falhar |
|---|---|---|---|
| V1 | Modelo `reh_prop_reh_bag_outfit_01a` existe no jogo (`IsModelInCdimage`) | 1 | **Concluída 2026-10-12:** existe, é válido e carrega (D200) |
| V2 | Repositório `vel_uniformbag` ainda não existe na conta | 1 | **Concluída 2026-10-12:** não existe (consulta `gh repo view`, nada criado) |
| V3 | Assinaturas exatas de `RegisterPermissions`/`HasPerms`/`RegisterPlugin` em execução | 1–2 | **Concluída 2026-10-12:** `HasPerms` não é exportado; verificação por natives ACE (D199). Em execução: permissão aparece em Perms, staff reconhecida pelo grupo God, negada com o mri_Qadmin parado, re-registrada quando ele reinicia |
| V4 | Formato exato do retorno de `getPedAppearance` (para guardar aparência completa e comparar peças) | 3 | Ajustar o mapeamento em `config.lua` |
| V5 | Chegada de `illenium-appearance:server:saveAppearance` a um segundo ouvinte (`RegisterNetEvent` no nosso recurso) | 3 | Plano B: confirmação de salvamento pelo nosso próprio callback após o `save` |
| V6 | Payload aceito por `ps-dispatch:server:notify` disparado pelo servidor | 3 | Ajustar o adaptador `psdispatch` (D134) |
| V7 | Estrutura do `swapItems` (origem/destino, tipos de inventário) e `Search` em inventário de outro jogador/baú | 3–4 | Reduzir a detecção ao que a API permitir e documentar (D198) |
| V8 | Statebag `isDead` do ars_ambulancejob visível no servidor | 3 | Usar só os metadados do QBox (`isdead`/`inlaststand`). *Código confere: o ars replica o statebag (`set(..., true)`); teste em execução na etapa 3.* |
| V9 | Sedes reais de Polícia, Hospital e Mecânica e suas coordenadas | 4 | Apresentar para aprovação antes de criar pontos (D92) |
| V10 | Blender oficial instalável e render com alfa a 256 × 256 com qualidade aceitável | 3 | Mostrar o resultado e alternativas, sem troca silenciosa (D179) |

## E. Conferência de segurança (pedida na consolidação)
| Ponto | Situação no planejamento |
|---|---|
| Permissões de staff e líder validadas no servidor | Sim: `GetProfile` em todo callback; falha fechada sem mri_Qadmin; líder só a própria organização (D84, D87, D93). |
| Uso indevido visível, auditado e comunicado | Sim: a roupa é aplicada; ocorrência com ID único, auditoria, Discord e canais configurados (D11, D132). |
| Alertas sem duplicação indevida | Anti-duplicação no servidor (D127, D143), **dependente da regra atual do ps-dispatch** — ver E.1. |
| Compatibilidade M/F e modelos personalizados | Pelo modelo real do ped; personalizados só com configuração explícita; nunca converte (D57–D69). |
| Integridade de roupas e compartimentos | Duas fases + diário persistente + transação + `UPDATE` da mesma linha + versão + trava (D180–D186, D192–D197). |
| Duplicação de itens | Bolsa gravada antes do item; criação externa sem efeito (D191); duplicidade detectada em pontos de contato e bloqueada (D189) — **não exaustiva**, ver E.3. |
| Recuperação administrativa | Excepcional, motivo obrigatório, confirmação do jogador, sem duplicidade, auditada (D146–D153). |
| Desconexões e reinícios | Diário `sub_operations` + reconciliação ao iniciar e ao carregar o personagem (FLUXO §4.1). |
| APIs públicas de QBox, ox_inventory, mri_Qappearance, mri_Qadmin, mri_Qbossmenu, ps-dispatch | Só exports, eventos e hooks públicos listados no TRD §2. |
| Código protegido de terceiros | Nenhum alterado. Única alteração fora do recurso: `items.lua` (arquivo de configuração) e imagens em `web/images`, autorizadas na C2. |
| Sistema de drop existente | Não substituído: o objeto temporário não é drop; descartar usa o drop do ox_inventory (D102). |

### Riscos residuais (sem garantias que a arquitetura não cumpre — D198)
1. **Confirmação de aparência vem do cliente.** O servidor do FiveM não enxerga a roupa do ped. Cliente adulterado pode confirmar sem aplicar ou mentir sobre a roupa atual; o efeito fica restrito à própria aparência (aparência não é item econômico). Mitigações: diário, validação de formato, marcação de farda no servidor (D196).
2. **ps-dispatch:** entrega o alerta a todos os clientes e filtra no cliente; um cliente adulterado pode ler alertas que não eram para ele. A anti-duplicação reproduz a regra atual do ps-dispatch; uma atualização dele pode exigir ajuste (teste a cada atualização).
3. **Detecção de duplicidade e rastreio** dependem do que passa pelo ox_inventory e de o inventário anterior estar carregado; não detectam tudo. Movimentações feitas por outros scripts via `AddItem`/`RemoveItem` não aparecem como atividade.
4. **Roupa trocada fora da bolsa sem salvar** (scripts de terceiros) não é percebida e gera "pendente de verificação" (D144).
5. Cliente adulterado sempre pode mudar a própria roupa visualmente fora da bolsa; o sistema audita o que passa pela bolsa.

## F. Fora do escopo aprovado
- Nada do plano excede o PRD. Arquivamento de auditoria e cobrança por emissão ficam para versões futuras (D116, D162).

## G. Impedimentos para a etapa 1
- **Nenhuma contradição técnica comprovada impede a etapa 1.** A única afirmação técnica incorreta encontrada (bloqueio pelo `createItem`) foi corrigida sem impacto no produto (D191). As verificações V1–V10 são normais de implementação e têm plano para o caso de falha.

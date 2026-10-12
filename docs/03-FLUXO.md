# 03 — Fluxo do Sistema

Versão: 1.1 (consolidada, para aprovação geral) — 2026-10-12

Dois conceitos que não se confundem (D192, D195):
- **Uniforme oficial da bolsa** = modelo de referência permanente do cadastro (ligado por `uniform_id`); nunca vai para compartimento, nunca é consumido.
- **Compartimentos** = cópias completas de roupas do personagem. *Guardar nova roupa* exige compartimento livre; *trocar por roupa existente* usa o mesmo compartimento.

## 1. Entradas

| Entrada | Quem | Condição |
|---|---|---|
| Usar o item **"Bolsa de Uniforme"** no inventário | Qualquer jogador | Ter o item; bolsa não estar em uso por outra pessoa; não estar morto/incapacitado, algemado/imobilizado, em veículo ou nadando — checado antes e durante (D154) |
| Comando **`/minharoupa`** | O próprio personagem | Ter recuperação "Aguardando aplicação" em seu nome (D159) |
| Aba **"Bolsas de Uniformes"** em Plugins do mri_Qadmin | Staff | Permissão `street_uniformbag.manage` ou ACE de emergência |
| **Ponto de gestão** na sede (olhinho) | Líder | `isboss` na organização do ponto; ponto ativo |

## 2. Telas

### 2.1 Tela "Bolsa" (uso)
- **Cabeçalho:** nome do uniforme, organização, ID curto da bolsa.
- **Cartão Uniforme oficial:** versão compatível com o personagem ou aviso "Sem versão para seu personagem". Botão **Vestir uniforme**.
- **Lista de compartimentos (1..N):** para cada um: "Livre" ou nome de quem guardou + data; selo "Incompatível com seu personagem" quando for o caso. Botão **Vestir esta roupa** (desabilitado se incompatível).
- **Rodapé:** contador "X de N compartimentos ocupados"; botão **Fechar**.

### 2.2 Tela "Painel" (gestão)
Abas visíveis conforme o perfil:
1. **Uniformes** — lista por organização; criar/editar: nome; **modo de autorização** — chave "Também permitir graduações superiores": desligada → caixas de seleção das graduações (lista real do emprego); ligada → seletores "Graduação mínima" (obrigatória) e "Graduação máxima" (opcional) (D135–D137); captura da **versão masculina** e da **versão feminina** ("Usar roupa que estou vestindo"), ativo/inativo.
2. **Emissão** — escolher uniforme, quantidade, baú de destino; botão **Emitir**; resultado por bolsa.
3. **Estoque** — por uniforme: emitidas, no baú, em circulação, desconhecidas/inativas; filtros por estado, organização, ID e última atividade confirmada; buscar bolsa por ID e ver histórico completo, inclusive de bolsas inativas (D166).
4. **Alertas e logs** — ativar/desativar alerta; modo (só ps-dispatch / só notificação própria / ambos); tipos de emprego do ps-dispatch; empregos específicos do canal próprio (lista real do QBox); "só funcionários em serviço" (canal próprio); tempo do ponto no mapa; categorias de log para o Discord; situação do webhook ("configurado" / "não configurado", sem mostrar o endereço).
5. **Pontos** — listar, criar ("usar minha posição atual"), editar, ativar/desativar.
6. **Auditoria** — filtros por organização, bolsa, personagem, categoria, período.
7. **Recuperação** *(só staff)* — restaurar roupa de um personagem a partir de um registro de auditoria, com motivo obrigatório.

Líder vê as abas 1–6 restritas à própria organização. Staff vê todas as organizações e a aba 7.

## 3. Caminho principal — vestir o uniforme

1. **Acesso:** jogador usa o item → ox_inventory chama `useBag` no servidor.
2. **Validação (servidor):** item está no inventário do jogador; `bagId` existe no banco e não está marcado como inválido (D190) nem duplicado (D189); conferência de localização (se o inventário anterior registrado ainda tiver a mesma bolsa ⇒ duplicidade); personagem apto (D154); bolsa sem trava → cria trava (jogador, bolsa, 60 s renováveis); ressincroniza metadados do item e registra atividade (D164, D190).
3. **Interação (cliente):** animação de agachar e soltar a bolsa; cria o objeto temporário ao lado; abre a tela "Bolsa" com os dados enviados pelo servidor (compatibilidade calculada pelo modelo real do ped).
4. **Escolha:** "Vestir uniforme".
5. **Pré-checagem (servidor, `beginChange`):** versão compatível existe; há compartimento livre **ou** a roupa atual já é este uniforme segundo o registro "farda em uso" do servidor (D193); calcula autorização pelo emprego atual; recebe a aparência atual capturada pelo cliente, valida formato/tamanho e grava o diário `sub_operations` (`iniciada`, token, aparência atual, uniforme alvo, versão da bolsa) (D182).
6. **Processamento (cliente):** toca a animação nativa, aplica a versão do uniforme (`setPedComponents`/`setPedProps`), confere os componentes aplicados.
7. **Confirmação (servidor, `confirmChange`):** trava passa a `finalizando` (não expira, D156); transação única: roupa anterior no compartimento livre (marcada como farda se D196 indicar), versão da bolsa +1, registro "farda em uso", diário `concluida`, auditoria. Se não autorizado: ocorrência de uso indevido (alerta + Discord), depois da transação.
8. **Resultado:** cliente salva a aparência pelo caminho da base (`saveAppearance`); o servidor registra no diário que o salvamento chegou (D197); notificação "Uniforme vestido."; bolsa recolhida, objeto removido, trava liberada.

## 4. Caminho principal — vestir roupa guardada (tirar a farda)

Passos 1–3 iguais. Escolha "Vestir esta roupa" no compartimento K.
- **Pré-checagem:** conjunto K compatível com o modelo; se a roupa atual **não** for o uniforme desta bolsa (decisão do servidor, D193), ela será guardada **no próprio compartimento K** (troca segura, I1 confirmada — D180), **inclusive com os 3 compartimentos cheios**. Se o conjunto K estiver marcado como farda oficial, calcula a autorização como em "vestir uniforme" (D184). Grava a operação no diário `sub_operations` (estado `iniciada`, com a aparência atual e a de K).
- **Confirmação visual (D185):** antes de aplicar, a tela mostra "Você vai vestir: [roupa K — guardada por X em data]" e "Será guardada no compartimento K: [roupa atual / farda Y]"; botões **Confirmar troca** / **Voltar**.
- **Processamento:** captura a roupa atual, animação, aplica o conjunto K, confere.
- **Confirmação:** transação — compartimento K recebe a roupa atual (ou fica livre, se ela era o uniforme); "farda em uso" é encerrada se a roupa atual era este uniforme, ou aberta se K era farda; ocorrência se K era farda não autorizada; diário passa a `concluida`; auditoria. Nenhum alerta quando K não é farda (D56).
- **Recuperação (D182):** se houver erro, cancelamento, desconexão ou reinício entre `iniciada` e `concluida`, a operação é **revertida**: nada mudou no banco, e o cliente recebe de volta a aparência anterior gravada no diário (na hora ou ao reconectar). Se o banco já confirmou e só o salvamento da aparência falhou, ao reconectar o servidor reaplica a aparência registrada como resultado. Nunca as duas roupas somem nem ficam duplicadas.
- **Resultado:** `saveAppearance` (registrado no diário, D197); notificação "Roupa trocada."; encerramento.

### 4.1 Recuperação de operação interrompida (vale para as seções 3 e 4) — D182, D197
| Momento da interrupção | Estado no diário | O que o sistema faz |
|---|---|---|
| Antes do `beginChange` | nenhum | Nada a recuperar. |
| Entre `beginChange` e `confirmChange` (erro, cancelamento, desconexão, reinício, item removido) | `iniciada` | Marca `revertida`; banco intacto; o cliente reaplica a aparência anterior do diário — na hora, ou quando o personagem carregar de novo. |
| Durante a transação do `confirmChange` | `iniciada` (transação não gravou) ou `concluida` (gravou) | Banco é atômico: ou tudo, ou nada. Segue a linha correspondente. |
| Depois do `confirmChange`, sem salvamento confirmado | `concluida`, sem `saved_at` | Ao carregar o personagem, reaplica a aparência alvo e solicita o salvamento. |
| Concluída e salva | `concluida`, com `saved_at` | Nada a fazer. |
Ao iniciar o recurso, todas as operações `iniciada` viram `revertida` (o jogador recebe a aparência anterior ao carregar). Nunca as duas roupas somem e nenhuma é duplicada.

## 5. Caminhos alternativos

| Situação | Comportamento |
|---|---|
| Cancelar / ESC / Fechar | Nenhuma alteração; objeto removido; trava liberada. |
| Compartimentos cheios ao vestir o uniforme (*guardar nova roupa*) | Botão desabilitado com aviso "Todos os compartimentos estão ocupados. Vista uma das roupas guardadas para trocar." (D47, D192). Vestir roupa guardada continua disponível (D180). |
| Bolsa marcada como duplicada | Uso recusado: "Esta bolsa está bloqueada para verificação da administração." Auditoria `duplicacao` (D189). |
| Bolsa não reconhecida (criada fora da emissão / ID desconhecido) | Uso recusado: "Bolsa não reconhecida." Auditoria (D190, D191). |
| Conjunto incompatível | Selo "Incompatível com seu personagem"; botão desabilitado; servidor também recusa em `beginChange`. |
| Sem versão do uniforme para o modelo | Aviso "Este uniforme ainda não tem versão para seu personagem." |
| Bolsa em uso por outra pessoa | Notificação "Esta bolsa está sendo usada por outra pessoa." |
| Afastar-se mais de 3 m do objeto / morrer / ficar incapacitado / ser algemado / entrar em veículo / nadar durante a interação | Cancelamento automático e seguro; nenhuma roupa apagada, nenhum item duplicado, objeto removido (D154, D155). |
| Trava expirando | Renovada enquanto a tela está aberta; **nunca** liberada durante a finalização de uma troca (D156). |
| Desconexão antes da confirmação | Nada gravado nos compartimentos; diário `revertida`; trava liberada; objeto removido pelo servidor. A bolsa real segue as regras do inventário (D104). |
| Desconexão após aplicar e antes de confirmar | Nada gravado nos compartimentos; diário `revertida`; ao voltar, o personagem recebe a aparência anterior do diário (§4.1). Nenhuma roupa perdida. |
| Item removido do inventário durante a troca (roubo/drop) | `confirmChange` recusa (item não está mais com o jogador); cliente restaura a aparência anterior; diário `revertida`. |
| Falha ao aplicar a aparência | Cliente restaura a aparência anterior e informa falha; diário `revertida`. |
| Reinício do recurso no meio | Ao iniciar: diário `iniciada` ⇒ `revertida`; travas em memória zeradas; §4.1. |
| Recurso de aparência indisponível | Uso da bolsa bloqueado com aviso "Sistema de roupas indisponível no momento." |
| Banco indisponível | Uso bloqueado com aviso; nada alterado. |
| ps-dispatch indisponível | Uso continua; ocorrência gravada em auditoria e Discord. |
| Discord indisponível | Uso continua; log fica no banco marcado "não enviado" (D77). |

## 6. Fluxos de gestão

### 6.1 Cadastrar/atualizar uniforme
Abrir painel → aba Uniformes → Novo/Editar → escolher organização (líder: fixa) → nome → modo de autorização (graduações específicas **ou** faixa mínima/máxima, com os cargos reais do emprego; servidor recusa graduação inexistente ou máxima menor que a mínima) → **vestir a roupa no personagem** → "Usar roupa que estou vestindo" (grava a versão do modelo atual: masculino ou feminino) → Salvar. Servidor valida perfil, escopo e dados; auditoria "Uniforme criado/alterado". Bolsas já emitidas passam a aplicar a versão atualizada (vínculo por ID do uniforme — modelo de referência, D195); roupas já guardadas nos compartimentos não mudam.

### 6.2 Emitir bolsas
Aba Emissão → uniforme → quantidade (1..limite) → baú (lista da organização) → Emitir. Servidor: valida perfil e escopo; cria lote com chave de idempotência; para cada bolsa: gera `bagId` e **grava a bolsa no banco antes**, verifica espaço no baú, `AddItem` com metadados, registra sucesso ou falha (falha ⇒ status `falha_emissao`, nenhum item órfão). Resultado: "8 de 10 bolsas emitidas; 2 falharam: baú sem espaço." Auditoria "Emissão".

### 6.3 Configurar alertas, logs e pontos
Abas Alertas/Pontos; servidor valida e grava; auditoria "Configuração alterada". Pontos novos usam a posição atual de quem cadastra, que deve estar no local aprovado (D92).

### 6.3.1 Resolver bolsa duplicada (staff) — D189
Aba Estoque → filtro "Duplicadas" → ver histórico e localizações registradas → após investigar (e, se for o caso, remover a cópia indevida pelos meios normais do ox_inventory/administração), **Liberar bolsa** com motivo obrigatório. Auditoria `duplicacao` (`resolvida`). O sistema nunca apaga itens nem copia conjuntos.

### 6.4 Recuperação administrativa (staff) — D146–D153
1. **Registro (staff):** aba Recuperação → buscar personagem (online ou offline) → escolher a aparência a recuperar (registro de auditoria ou compartimento) → **motivo obrigatório** → confirmar. Servidor grava a recuperação com status **"Aguardando aplicação"** e auditoria "Recuperação registrada" (autor, beneficiado, data, hora, motivo). Nenhuma bolsa ou inventário é alterado.
2. **Aviso ao jogador:** quando o personagem estiver carregado (QBox + mri_Qappearance prontos), notificação "A administração restaurou uma roupa sua." com **Restaurar agora** / **Restaurar depois**. Se já estiver online no momento do registro, o aviso aparece na hora.
3. **Restaurar agora:** servidor confere que a recuperação é do personagem e está pendente (trava contra duplicidade) → cliente guarda a aparência atual, aplica a recuperada, confere → confirma → servidor marca **"Concluída"** e registra a aparência anterior (para reversão) → cliente salva a aparência pelo caminho da base → atualiza "farda em uso" (D153).
4. **Falha na aplicação:** cliente restaura a aparência guardada; recuperação continua "Aguardando aplicação".
5. **Restaurar depois:** nada muda; o aviso volta na próxima entrada, e o jogador pode abrir a recuperação pendente quando quiser pelo comando **`/minharoupa`**, que só mostra as recuperações do próprio personagem (D159).

## 7. Reavaliação por mudança de cargo

1. QBox dispara `QBCore:Server:OnJobUpdate` / `qbx_core:server:onGroupUpdate`.
2. Servidor procura "farda em uso" do personagem. Se não houver: fim.
3. Calcula a autorização nova. Compara com o estado gravado:
   - não autorizado → autorizado: atualiza estado, sem alerta (D43);
   - sem mudança de estado: nada (D38, D39);
   - autorizado → não autorizado: segue para o passo 4.
4. **Conferência do corpo (D140, D141):** servidor pede ao cliente a comparação das peças de roupa atuais com a versão do uniforme (só componentes/acessórios de roupa, conforme o modelo), com tempo limite.
   - confirma a farda no corpo → **ocorrência** (bolsa, organização, uniforme, cargo anterior e atual, data, hora, coordenadas) (D35);
   - nega, sem salvamento de aparência que comprove a troca, ou sem resposta → auditoria **"pendente de verificação"**, sem alerta e sem encerrar o registro (D141, D142).
5. Eventos repetidos com o mesmo cargo são ignorados.
6. "Farda em uso" é encerrada quando o personagem tira a farda pela bolsa, ou quando um **salvamento de aparência** (loja, guarda-roupa, vestiário, criador) mostra roupa diferente da farda (D139).

## 7.1 Entrega de uma ocorrência de uso indevido

1. Servidor monta a ocorrência uma única vez: ID único, bolsa, uniforme, organização, personagem, cargo, horário, coordenadas lidas no servidor (D132).
2. Lê a configuração da organização: modo (`psdispatch` / `jobnotify` / `ambos`), tipos de emprego do ps-dispatch, nomes de empregos do canal próprio, "só em serviço" (D126, D130).
3. Canal ps-dispatch: dispara `ps-dispatch:server:notify` com os tipos configurados.
4. Canal próprio: calcula no servidor os destinatários (nome do emprego na lista + regra de serviço), **removendo** quem já recebe pelo ps-dispatch (D127); envia só para eles.
5. Cliente do destinatário: notificação "Uso irregular de farda — [uniforme] — [rua]" e ponto temporário no mapa no local da ocorrência (D128).
6. Resultado de cada canal (enviado / falhou / sem destinatários) gravado na ocorrência; falha não afeta a troca e não é reenviada automaticamente (D133).

## 8. Retirada e circulação (rastreio)

Hook `swapItems` do ox_inventory, filtrado no item "Bolsa de Uniforme":
- baú da organização → jogador: auditoria **"Retirada"** (quem retirou);
- jogador → jogador / jogador → chão / chão → jogador / jogador → baú: auditoria **"Transferência"** / **"Devolução"**;
- estado da bolsa: `em_estoque` (em baú de organização) ou `em_circulacao`; última localização (tipo + ID do inventário) atualizada a cada movimentação, usada na conferência de duplicidade (D189);
- metadados do item ressincronizados a partir do banco (D190);
- toda movimentação acima, a retirada, a emissão e o uso da bolsa atualizam a **última atividade confirmada** (D164); entrar no servidor **não** conta;
- sem atividade confirmada por 30 dias (configurável), a bolsa em circulação vira **"Desconhecida/Inativa"** — só no painel; ela continua funcionando normalmente e volta a "Em circulação" na próxima atividade (D163). Nenhuma reposição é feita.

## 9. Primeiro acesso

- Hook `createItem`: qualquer `uniform_bag` criada por outro recurso (ex.: `/giveitem`) recebe marca de inválida e fica sem efeito, com auditoria (D191). O drop, a morte e os baús continuam sendo os do ox_inventory/base — nada é substituído (D102).

- Imagem do item: organização sem `item_image` usa a bolsa padrão roxa; ao salvar outra imagem no painel (aba Alertas e logs / configurações), o servidor valida o nome e a existência do arquivo; bolsas emitidas depois usam a nova imagem, e as já emitidas são atualizadas na próxima atividade (D174).
- Nova organização com imagem própria: rodar o script de `art/` com a cor e o símbolo dela, aprovar o render, copiar o PNG para `ox_inventory/web/images` e informar o nome no painel — sem alterar o núcleo (D178).
- Instalação: a pasta deve se chamar exatamente `street_uniformbag` (igual ao repositório, D167); clonar o repositório já cria a pasta certa em `resources/[meus_scripts]/`.

- Na primeira partida: migrações criam as tabelas; permissão registrada no mri_Qadmin; aba de plugin registrada.
- Organizações começam **sem** uniformes, pontos, destinatários de alerta e categorias de log ativas, exceto as essenciais.
- O painel mostra um guia curto na aba Uniformes vazia: "1. Vista o uniforme. 2. Clique em Usar roupa que estou vestindo. 3. Escolha as graduações e salve."

# 01 — PRD: Sistema de Bolsas de Uniformes

Versão: 1.1 (consolidada, para aprovação geral) — 2026-10-12
Decisões de origem: `00-DECISOES.md` (D1–D198).

## 1. Identificação

| Campo | Valor |
|---|---|
| Nome do sistema | Sistema de Bolsas de Uniformes — Street Roleplay |
| Nome técnico | `street_uniformbag` (D14) — também o nome da pasta do recurso e do repositório GitHub privado (D167) |
| Descrição em uma frase | Bolsas físicas de uniforme, emitidas pelas organizações, que trocam a roupa do personagem pela farda oficial do cargo e guardam as roupas civis em compartimentos, com alerta e auditoria de uso indevido. |
| Objetivo principal | Dar às organizações (Polícia, Hospital, Mecânica e futuras) uniformes oficiais por cargo, cadastrados sem editar código, entregues em bolsas rastreáveis que podem circular, ser perdidas ou roubadas no RP, com fiscalização automática do uso indevido. |

## 2. Público

| Quem | Acesso |
|---|---|
| Funcionários das organizações | Retiram bolsas do baú da organização e as usam para vestir a farda do seu cargo. |
| Líderes das organizações (`isboss` no QBox) | Gerenciam uniformes, emitem bolsas, configuram alertas, logs e pontos **da própria organização** (D16, D83). |
| Staff com a permissão "Gerenciar Bolsas de Uniformes" | Gerencia **todas** as organizações, consulta auditoria e executa recuperação administrativa (D79, D80). |
| Administradores principais | Acesso de emergência por ACE específica, configurada explicitamente (D82). |
| Qualquer jogador | Pode usar uma bolsa que esteja com ele (encontrada, recebida ou roubada) (D4, D49). |
| Corporações destinatárias de alerta | Recebem ocorrências de uso indevido conforme a configuração de cada organização (D13, D19). |

Necessidades: vestir a farda certa rapidamente em qualquer lugar; não perder a roupa civil; controlar quem tem farda de cada cargo; saber quando alguém usa farda indevidamente.

## 3. Problema

- **Hoje:** o `qs-outfitbag` (Quasar) é um guarda-roupa pessoal, ligado ao personagem e não à bolsa; o núcleo é criptografado; integra com `qs-appearance`, inexistente na base; não persiste a troca; não tem cargos, gênero, estoque, rastreio nem auditoria.
- **Limitações:** não há como entregar fardas oficiais por cargo, nem fiscalizar uso indevido, nem rastrear bolsas que circulam no RP.
- **Problema resolvido:** uniformes oficiais por organização, cargo e modelo de personagem, emitidos em bolsas rastreáveis, com fiscalização e auditoria.

## 4. Primeira versão

### 4.1 Funcionalidades obrigatórias (por prioridade)

1. **Item bolsa** no ox_inventory com ID único e vínculo a um uniforme oficial (D2, D25, D101), com **imagem exclusiva por organização** (Polícia, Hospital, Mecânica; padrão roxa `#6400E6` para as demais), criadas para o projeto em modelo visual único com acabamento 3D, trocáveis pelo painel sem alterar código; produzidas no Blender a partir de um modelo 3D original (D121, D122, D170–D179).
2. **Uso da bolsa**: bolsa física temporária no chão, interface com o uniforme e os compartimentos, animação nativa, troca de roupa (D94–D97).
3. **Compartimentos** de roupas civis (padrão 3, configurável), sem sobrescrever nem apagar automaticamente (D44–D53).
4. **Compatibilidade de modelo** (masculino/feminino), com uniforme em duas versões e roupas incompatíveis visíveis mas bloqueadas (D57–D69).
5. **Validação de autorização** pelo cargo atual no QBox (D8–D10), sem impedir o uso (D11).
6. **Alerta de uso indevido** com coordenadas a cada uso, para os destinatários configurados da organização, por **ps-dispatch**, **notificação própria por emprego** (nomes reais do QBox, com nome da rua e ponto temporário no mapa) ou **ambos**, sem duplicar para a mesma pessoa; cada ocorrência com ID único (D5, D12, D13, D124–D134).
7. **Reavaliação automática** em promoção, rebaixamento, transferência ou demissão (D34–D43).
8. **Cadastro de uniformes** pelo painel: capturar a roupa vestida, escolher organização, nome, cargos, regra de hierarquia e modelo (D14–D23, D57–D60).
9. **Emissão de bolsas** em lote para o baú da organização, com controle de estoque e proteção contra duplicação (D24–D33).
10. **Auditoria** em banco e Discord (por organização + canal geral), com categorias configuráveis (D70–D78).
11. **Permissões**: permissão própria no mri_Qadmin, ACE de emergência, líder restrito à própria organização (D79–D87).
12. **Acesso ao painel**: aba "Bolsas de Uniformes" no mri_Qadmin (staff) e pontos nas sedes (líderes), mesma interface (D88–D93).
13. **Recuperação administrativa excepcional** de roupas por falha técnica, com motivo obrigatório e auditoria; funciona com o personagem offline; o jogador confirma ("Restaurar agora" / "Restaurar depois") antes de qualquer mudança na roupa (D7, D146–D153).
14. **Identidade visual** MRI com `#6400E6` (D106–D113).

### 4.2 Funcionalidades opcionais (se couberem sem risco)

- Rótulo amigável no item (nome do uniforme e organização) exibido no inventário.
- Filtros e busca na consulta de auditoria.

### 4.3 Excluídas da primeira versão

- Guarda-roupa genérico ou armazenamento de roupas arbitrárias fora dos compartimentos da bolsa.
- Geração de bolsas por interação com guarda-roupa (D29) e reposição automática de bolsas perdidas (D30).
- Bloqueio da bolsa por dono e transferência automática de roupas ao mudar de mãos (D4).
- Conversão de roupas entre modelos e alteração do modelo do personagem (D63, D64).
- Remoção automática da farda em caso de uso indevido ou mudança de cargo (D11, D37).
- Modelos personalizados de personagem sem configuração explícita (D68).
- Criação automática de pontos em coordenadas não aprovadas (D92).
- Qualquer reutilização de código do qs-outfitbag (D1, D105).
- Cobrança por emissão de bolsas e integração com o ps-banking (D114, D116).

## 5. Regras de negócio

### 5.1 Uso da bolsa
- Qualquer pessoa com a bolsa pode usá-la (D4).
- Só uma pessoa usa a mesma bolsa por vez (D100).
- **Uniforme oficial da bolsa**: é o modelo de referência permanente do cadastro, nunca guardado em compartimento nem consumido ao ser vestido (D44, D195).
- **Vestir o uniforme** (= *guardar nova roupa*): exige compartimento livre para guardar a roupa atual, exceto se a roupa atual já for o uniforme desta bolsa, conforme o registro do servidor (D46, D48, D193). Com todos os compartimentos ocupados, a ação é impedida com mensagem (D47, D192).
- **Vestir roupa guardada** (= *trocar por roupa existente*): veste exatamente o conjunto. A roupa atual é preservada: se for o uniforme desta bolsa, não ocupa compartimento; se não for, entra no compartimento que acabou de ser liberado, na mesma operação (troca segura — I1 confirmada, D180). Funciona mesmo com todos os compartimentos ocupados; nada é apagado e cada aparência é guardada por inteiro (D181). Se a roupa guardada for uma farda oficial, vesti-la passa pela mesma verificação de autorização (D184).
- A roupa só sai do compartimento depois de confirmada a aplicação da aparência; o jogador vê o que será vestido e o que será guardado e confirma (D51, D185, D194). Não existe descarte de roupa (D192).
- Troca interrompida (erro, cancelamento, desconexão, reinício) é revertida ou concluída com segurança, sem perda nem duplicação (D182, D197).
- Roupas e uniforme incompatíveis com o modelo do personagem não podem ser vestidos (D60, D62, D65); isso não bloqueia os demais conjuntos (D69).

### 5.2 Autorização e uso indevido
- **Uniforme autorizado** para o personagem quando o emprego atual no QBox é a organização do uniforme **e** a graduação atual atende ao modo do uniforme (D135–D137):
  - **Graduações específicas** ("Também permitir graduações superiores" desativada): a graduação atual está entre as selecionadas.
  - **Faixa de graduações** (opção ativada): graduação atual ≥ mínima e, se houver máxima, ≤ máxima (extremos incluídos). Ex.: mínima 2 e máxima 3 → só 2 e 3.
  - As graduações vêm dos cargos reais da organização no QBox.
- **Uso indevido**: vestir o **uniforme oficial** sem autorização (D8). Vestir roupa civil guardada nunca é uso indevido (D56).
- O uso indevido **não impede** vestir (D11). Gera ocorrência: alerta ao destinatário configurado, auditoria e Discord (D5).
- Alerta a **cada** vestida indevida, sem duplicar a mesma ação (D12).
- **Mudança de cargo** com a farda da bolsa no corpo: alerta só na transição de autorizado para não autorizado **e** com a farda confirmada no corpo (D35, D38, D39, D141); promoção que regulariza não gera alerta (D43); a farda não é removida (D37).
- **Troca fora da bolsa** (loja, guarda-roupa, vestiário): o salvamento da roupa encerra o registro "farda em uso" (D139). Sem evidência confiável, a situação vira **"pendente de verificação"** na auditoria, nunca uma acusação automática (D141).

### 5.3 Hierarquia e permissões de gestão
- Staff com a permissão: todas as organizações (D80).
- Líder (`isboss`): só a própria organização (D16).
- ACE de emergência: acesso total, só se configurada explicitamente (D82).
- Toda validação no servidor; falha do mri_Qadmin não concede acesso (D84, D87).

### 5.4 Estoque e emissão
- Bolsas só existem por emissão autorizada, em lote, depositadas no baú da organização (D24, D26, D29).
- Bolsa perdida/roubada não é reposta automaticamente (D30).
- Registro de quem emitiu e de quem retirou, quando detectável (D27).
- **Auditoria permanente**, sem exclusão automática; histórico disponível mesmo para bolsas perdidas, roubadas ou inativas (D161, D162).
- Bolsa sem atividade confirmada por 30 dias (configurável) aparece como **"Desconhecida/Inativa"** no painel — só classificação: continua usável, nada é apagado, nada é reposto, e volta a "Em circulação" na próxima atividade. Entrar no servidor não conta como atividade (D163, D164).

### 5.5 Situações especiais
- Bolsa roubada/perdida: conjuntos continuam nela; o antigo dono não recupera automaticamente (D3, D7).
- Falha técnica com perda de roupa: recuperação administrativa excepcional, com auditoria (D7). Nunca para roubo ou consequências normais do RP (D152).
- Desconexão/morte durante a troca: interação encerrada com segurança; a bolsa real segue as regras normais do inventário (D99, D104).
- A bolsa não pode ser usada por personagem morto/incapacitado, algemado, em veículo ou nadando, e a troca é cancelada se ele se afastar mais de 3 m (D154, D155).
- Bolsa duplicada por exploit: detectada quando a mesma bolsa aparece em dois inventários, marcada, **bloqueada para uso** até a staff resolver, com auditoria; os conjuntos nunca são copiados (D55, D189).
- Bolsa não reconhecida (criada fora da emissão, ID desconhecido): fica sem efeito, com auditoria (D190, D191).
- Os dados da bolsa (uniforme e compartimentos) pertencem à **bolsa**, não a quem a possui, e ficam no banco ligados ao seu ID (D187, D188).

### 5.6 Regras financeiras
- **Emissão gratuita** na primeira versão: nada é debitado do caixa da organização e não há integração com o ps-banking (D114).
- Emissão só por líder autorizado ou staff com a permissão, com limite por lote configurável e auditoria de cada lote (D115).
- A arquitetura fica preparada para cobrança futura por emissão, que **não** faz parte desta versão (D116).

## 6. Histórias de uso

1. Como **sargento da Polícia**, quero retirar uma bolsa do baú e vesti-la em qualquer lugar, para entrar em serviço com a farda do meu cargo.
2. Como **funcionário**, quero tirar a farda usando a mesma bolsa, para voltar exatamente à roupa que eu estava usando.
3. Como **líder da Mecânica**, quero vestir o uniforme no meu personagem e salvá-lo como oficial do cargo "Mecânico", para padronizar a equipe sem pedir ajuda à staff.
4. Como **líder**, quero cadastrar a versão feminina do uniforme, para que as funcionárias também possam usá-lo.
5. Como **líder**, quero emitir 10 bolsas do uniforme de "Aprendiz" para o baú, para que os novos funcionários tenham fardas.
6. Como **líder**, quero ver quantas bolsas foram emitidas, quantas estão no baú e quantas circulam, para controlar o estoque.
7. Como **ladrão**, quero vestir a farda de uma bolsa roubada, para me passar por policial — sabendo que isso pode gerar um alerta.
8. Como **policial em serviço**, quero receber o alerta com a localização quando alguém vestir uma farda indevidamente, para agir no RP.
9. Como **líder**, quero ser alertado quando um funcionário demitido continuar fardado, para resolver a situação.
10. Como **staff**, quero consultar o histórico de uma bolsa pelo ID, para investigar denúncias.
11. Como **staff**, quero devolver a roupa de um jogador que a perdeu por falha técnica, com registro em auditoria.
12. Como **personagem feminino**, quero ver as roupas masculinas da bolsa marcadas como incompatíveis, para não estragar minha aparência.

## 7. Critérios de sucesso

- Vestir e tirar a farda com a mesma bolsa devolve exatamente a roupa anterior, inclusive após reconexão.
- Nenhuma roupa guardada é apagada ou sobrescrita sem ação explícita, em nenhum cenário testado (cheio, simultâneo, desconexão no meio, reinício do recurso no meio — D186).
- Com os 3 compartimentos cheios, vestir a roupa do compartimento K deixa a roupa anterior exatamente no compartimento K.
- Uso indevido gera alerta com coordenadas para o destinatário configurado e registro em banco/Discord; uso regular não gera alerta.
- Mudança de cargo gera alerta somente na transição que torna a farda irregular.
- Emissão de N bolsas cria exatamente N itens com IDs únicos no baú, ou registra a falha sem criar itens órfãos.
- Itens de bolsa criados fora da emissão (ex.: comando de dar item) ficam sem efeito e geram auditoria (o ox_inventory não permite bloquear a criação — D191).
- Bolsa duplicada é detectada no uso/movimentação e bloqueada até a staff resolver; nenhum conjunto é clonado.
- Líder não consegue ver nem alterar outra organização; staff sem a permissão não acessa.
- Personagem incompatível não consegue aplicar conjunto incompatível.
- Falha do Discord não interrompe o uso.
- Bolsa parada além do prazo vira "Desconhecida/Inativa" sem perder nada e volta a "Em circulação" ao ser movida ou usada; o histórico dela continua consultável.

**Primeira versão concluída** quando todos os critérios acima passarem nos testes da etapa 5 do plano, na base local, e o dono aprovar.

## 8. Dúvidas em aberto

Nenhuma decisão de produto em aberto (conferência C1–C10.1, I1 e I2 encerrada). Verificações técnicas da implementação estão listadas no `06-PLANO.md`.

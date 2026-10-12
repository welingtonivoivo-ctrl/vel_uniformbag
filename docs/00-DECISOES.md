# Registro de decisões — Sistema de Bolsas de Uniformes

Nome técnico: `vel_uniformbag` (D210; antes `street_uniformbag`, D14, D167).
Este registro alimenta os seis documentos (01-PRD a 06-PLANO). **Entrevista e conferência encerradas em 2026-10-12** (D1–D198); D199–D200 são ajustes técnicos registrados na etapa 1. Nenhuma decisão de produto pendente.
Nenhuma alteração na VPS, no banco ou na base local foi feita no planejamento.
Regra de edição: decisões aprovadas não são reescritas; esclarecimentos e correções técnicas entram como **novas** decisões e o item original recebe um aviso "→ ver Dxxx".

## Decisões tomadas

| # | Data | Decisão | Origem |
|---|------|---------|--------|
| D1 | 2026-10-11 | Criar recurso novo e independente em `[meus_scripts]`. Do qs-outfitbag aproveitar apenas ideias e animações nativas do GTA (`clothingtie`, `clothingshirt`); o núcleo dele é criptografado e não será reutilizado nem contornado. Usar mri_Qappearance (roupas), ox_inventory (item) e os cargos reais dos empregos. | Diagnóstico + briefing |
| D2 | 2026-10-11 | A bolsa é um **objeto físico** (item do ox_inventory), retirada do guarda-roupa ou baú da organização e transportável para qualquer lugar da cidade. | Resposta 1 |
| D3 | 2026-10-11 | **Opção C — bolsa física transferível, com preservação das roupas.** Os conjuntos (uniforme e roupa anterior) ficam armazenados **na própria bolsa** e continuam nela se a bolsa for perdida, entregue, dropada ou roubada. | Resposta 2 |
| D4 | 2026-10-11 | **Qualquer jogador** que tiver a bolsa pode usar os uniformes e as roupas civis armazenadas, mesmo sem pertencer à organização. **Sem bloqueio por proprietário** e **sem transferência automática** das roupas para outro armazenamento ao mudar de mãos. | Resposta 2 |
| D5 | 2026-10-11 | Uso indevido da farda gera **alerta policial com coordenadas a cada nova utilização** e **log de auditoria no Discord**. | Resposta 2 |
| D6 | 2026-10-11 | Cada bolsa tem **ID único** e **histórico** de emissão, utilização e transferência (quando detectáveis). | Resposta 2 |
| D7 | 2026-10-11 | O dono que perde a bolsa **não recupera automaticamente** os conjuntos. O sistema preserva a integridade da aparência do personagem e prevê **recuperação administrativa excepcional** para falhas técnicas, **com auditoria**. | Resposta 2 |

| D8 | 2026-10-11 | **Uso indevido (Opção B)** ocorre quando o personagem: (1) não pertence à organização do uniforme; (2) pertence, mas não tem a graduação/permissão exigida por aquele uniforme; (3) foi demitido ou rebaixado e continua usando farda para a qual não tem mais autorização. | Resposta 3 |
| D9 | 2026-10-11 | A validação consulta o **cargo atual no QBox** no servidor, no momento do uso, sem confiar apenas nos metadados da bolsa. | Resposta 3 |
| D10 | 2026-10-11 | A autorização segue as regras **configuradas em cada uniforme**. Graduação superior **não** autoriza automaticamente um uniforme exclusivo de outra graduação, salvo se isso estiver configurado no uniforme. | Resposta 3 |
| D11 | 2026-10-11 | Uso indevido **não impede** vestir: a roupa é aplicada e o sistema gera a ocorrência, o log no Discord e a auditoria. | Resposta 3 |
| D12 | 2026-10-11 | O alerta ocorre **a cada vez** que o uniforme é vestido indevidamente, com a localização daquele uso, evitando apenas eventos duplicados da mesma ação. | Resposta 3 |
| D13 | 2026-10-11 | O **destinatário dos alertas é configurável por organização** (Polícia, Hospital, Mecânica e futuras). Nada é enviado automaticamente à central policial sem essa configuração. | Resposta 3 |

| D14 | 2026-10-11 | **Cadastro próprio de uniformes (Opção A)** dentro do `street_uniformbag`, independente das tabelas internas do mri_Qbossmenu. Nome técnico `street_uniformbag` adotado. → ver D210. | Resposta 4 |
| D15 | 2026-10-11 | Reaproveitar componentes de interface, menus, notificações e permissões da base quando compatíveis, sem duplicar funcionalidades. | Resposta 4 |
| D16 | 2026-10-11 | **Permissões de gestão:** administradores autorizados gerenciam todas as organizações; líderes gerenciam só os uniformes da própria organização, respeitando as permissões reais do QBox e, se houver integração pública adequada, do bossmenu. | Resposta 4 |
| D17 | 2026-10-11 | **Cadastro:** o responsável veste o uniforme e salva a aparência atual como modelo oficial, escolhendo organização, nome, cargo(s)/graduação(ões) autorizadas, gênero/modelo e demais configurações. | Resposta 4 |
| D18 | 2026-10-11 | **Hierarquia explícita por uniforme:** "exclusivo da graduação" ou "também graduações superiores". Nunca presumido. | Resposta 4 |
| D19 | 2026-10-11 | Destinatários dos alertas configuráveis **por organização** dentro do sistema. | Resposta 4 |
| D20 | 2026-10-11 | Uniformes e regras em **estruturas próprias** do `street_uniformbag`. | Resposta 4 |
| D21 | 2026-10-11 | Interface administrativa simples, em pt-BR; líderes não editam arquivos nem código. | Resposta 4 |
| D22 | 2026-10-11 | **Não modificar** mri_Qbossmenu nem mri_Qappearance; usar apenas suas APIs públicas. | Resposta 4 |
| D23 | 2026-10-11 | Uniformes vinculados às bolsas **por organização e cargo**, mantendo identificação e histórico individual de cada bolsa. | Resposta 4 |

| D24 | 2026-10-11 | **Emissão por estoque (Opção A):** bolsas emitidas pelo painel do `street_uniformbag` por líder autorizado ou administrador, que escolhe organização, uniforme, cargo e quantidade. | Resposta 5 |
| D25 | 2026-10-11 | Cada bolsa emitida recebe **ID único**, metadados próprios e vínculo com o uniforme oficial. | Resposta 5 |
| D26 | 2026-10-11 | Bolsas emitidas são **depositadas no baú da organização** via ox_inventory; funcionários retiram normalmente pelo inventário, respeitando as permissões do baú. | Resposta 5 |
| D27 | 2026-10-11 | Registrar separadamente **quem emitiu** e **quem retirou**, quando tecnicamente possível. | Resposta 5 |
| D28 | 2026-10-11 | Controle de estoque e histórico: consultar emitidas, no baú e em circulação, conforme os dados disponíveis. | Resposta 5 |
| D29 | 2026-10-11 | **Sem geração infinita** por interação com guarda-roupa; reposição só por nova emissão autorizada. | Resposta 5 |
| D30 | 2026-10-11 | Bolsas perdidas/roubadas **não são substituídas automaticamente**; nova emissão pelo responsável. | Resposta 5 |
| D31 | 2026-10-11 | Bolsas continuam **transferíveis e utilizáveis por terceiros** (D3, D4). | Resposta 5 |
| D32 | 2026-10-11 | Proteções contra emissão duplicada, falha no depósito no baú e criação não autorizada de itens. | Resposta 5 |
| D33 | 2026-10-11 | Se a integração com o baú tiver limitação, **documentar e propor solução antes de implementar**. | Resposta 5 |

| D34 | 2026-10-11 | **Reavaliação automática (Opção B)** em promoção, rebaixamento, transferência ou demissão: o sistema acompanha a farda da bolsa que o personagem está usando e verifica de novo a autorização. | Resposta 6 |
| D35 | 2026-10-11 | Se a farda em uso deixar de ser autorizada, gera **ocorrência de uso indevido** com: ID da bolsa, organização, uniforme, cargo anterior e atual, data, horário e coordenadas no momento da mudança. | Resposta 6 |
| D36 | 2026-10-11 | A ocorrência vai ao destinatário configurado da organização, mais auditoria e Discord. | Resposta 6 |
| D37 | 2026-10-11 | **Não remove a farda, não bloqueia movimento, não altera a aparência** (resolução no RP). | Resposta 6 |
| D38 | 2026-10-11 | Alerta só em **mudança efetiva** que torne a farda irregular; nada por sincronização de emprego, reconexão ou evento duplicado. | Resposta 6 |
| D39 | 2026-10-11 | Já irregular + nova mudança de cargo: nova ocorrência **só se houver nova transição relevante de autorização**. | Resposta 6 |
| D40 | 2026-10-11 | Vestir de novo indevidamente pela bolsa gera novo alerta (D12). | Resposta 6 |
| D41 | 2026-10-11 | Detectar mudanças de emprego pelos **eventos/mecanismos públicos do QBox**; se necessário, **registro persistente do uniforme em uso**, ligado ao personagem e à bolsa. | Resposta 6 |
| D42 | 2026-10-11 | Vale para Polícia, Hospital, Mecânica e futuras, com as regras individuais de cada uniforme. | Resposta 6 |
| D43 | 2026-10-11 | Promoção que torne a farda autorizada **não gera alerta**. | Resposta 6 |

| D44 | 2026-10-11 | **Vários compartimentos (Opção B):** cada bolsa tem 1 uniforme oficial permanente (fora dos compartimentos) e, inicialmente, **até 3 compartimentos** para roupas civis. | Resposta 7 |
| D45 | 2026-10-11 | Cada roupa armazenada guarda: aparência completa, personagem que guardou e data do armazenamento. | Resposta 7 |
| D46 | 2026-10-11 | Vestir o uniforme guarda a roupa atual em compartimento **livre**, sem sobrescrever nada. | Resposta 7 |
| D47 | 2026-10-11 | Com os 3 compartimentos ocupados, o sistema **impede** guardar nova roupa. **Nunca** substitui ou apaga automaticamente. → ver D192 (esclarecimento: vale para *guardar nova roupa*; trocar por roupa existente segue D180). | Resposta 7 |
| D48 | 2026-10-11 | Selecionar roupa guardada veste exatamente aquele conjunto. A roupa atual é preservada: se for o uniforme oficial da bolsa, não ocupa compartimento; senão precisa de espaço **ou** de uma troca segura sem perda de dados. → ver D180, D193. | Resposta 7 |
| D49 | 2026-10-11 | Quem estiver com a bolsa (ex.: Pedro, após roubar de João) pode vestir a farda e as roupas guardadas. | Resposta 7 |
| D50 | 2026-10-11 | A bolsa mostra lista organizada de compartimentos ocupados e livres, com identificação dos conjuntos. | Resposta 7 |
| D51 | 2026-10-11 | A roupa só sai do compartimento **depois de confirmada** a aplicação correta da aparência. → ver D194. | Resposta 7 |
| D52 | 2026-10-11 | Nenhuma operação apaga/sobrescreve roupa de outro personagem sem ação explícita e autorizada. → ver D194. | Resposta 7 |
| D53 | 2026-10-11 | Limite de compartimentos **configurável**. | Resposta 7 |
| D54 | 2026-10-11 | Todos os dados ficam **vinculados ao ID único da bolsa**, após roubo, transferência, drop, baú ou reinício. → ver D187–D190, D195. | Resposta 7 |
| D55 | 2026-10-11 | Validações contra duplicação, perda de roupas e operações simultâneas. | Resposta 7 |
| D56 | 2026-10-11 | Alerta só ao vestir o **uniforme oficial** sem autorização; vestir roupa civil guardada **não** gera alerta de fardamento. | Resposta 7 |

| D57 | 2026-10-11 | **Uniforme com versões masculina e feminina (Opção B)**, cadastradas separadamente, ligadas ao mesmo uniforme, organização e cargo. | Resposta 8 |
| D58 | 2026-10-11 | Ao usar a bolsa, o sistema identifica o **modelo real do ped** e escolhe automaticamente a versão compatível. | Resposta 8 |
| D59 | 2026-10-11 | Líder/administrador cadastra as duas versões pelo painel, capturando a roupa vestida no personagem usado para o cadastro. | Resposta 8 |
| D60 | 2026-10-11 | Só uma versão cadastrada: disponível para quem é compatível; para incompatível, mensagem explicativa e aplicação impedida. | Resposta 8 |
| D61 | 2026-10-11 | Roupas civis guardadas preservam o modelo de personagem para o qual foram criadas. | Resposta 8 |
| D62 | 2026-10-11 | Roupas civis incompatíveis continuam **visíveis** com o rótulo "Incompatível com seu personagem", mas não podem ser vestidas. | Resposta 8 |
| D63 | 2026-10-11 | **Nunca** converter roupas entre masculino e feminino. | Resposta 8 |
| D64 | 2026-10-11 | **Nunca** alterar o modelo/gênero do personagem para permitir o uso. | Resposta 8 |
| D65 | 2026-10-11 | A validação usa o **modelo real do ped** e a compatibilidade das peças, não só o gênero registrado no banco. | Resposta 8 |
| D66 | 2026-10-11 | Verificações **antes** de iniciar a troca: operação incompatível não mexe na roupa atual nem nos dados da bolsa. | Resposta 8 |
| D67 | 2026-10-11 | Novos uniformes e organizações sem mudar essas regras. | Resposta 8 |
| D68 | 2026-10-11 | Modelos personalizados de personagem só são compatíveis com **configuração explícita e validada** para aquele modelo. | Resposta 8 |
| D69 | 2026-10-11 | A incompatibilidade de um conjunto **não bloqueia** o acesso aos demais conjuntos compatíveis da bolsa; a bolsa continua transferível e utilizável por qualquer jogador. | Resposta 8 |

| D70 | 2026-10-11 | **Logs por organização + canal geral (Opção B):** cada organização pode ter seu webhook de auditoria; a administração tem um webhook geral com os eventos importantes de todas. | Resposta 9 |
| D71 | 2026-10-11 | Eventos auditados: emissão, retiradas identificáveis, trocas de roupa, uso indevido, alterações administrativas, devoluções, recuperações e outros relevantes. | Resposta 9 |
| D72 | 2026-10-11 | Cada log traz: ID da bolsa, organização, personagem, ação, data, horário e localização quando aplicável. | Resposta 9 |
| D73 | 2026-10-11 | Alertas operacionais de uso indevido seguem para o dispatch/destinatário configurado; os webhooks **não substituem** esses alertas. | Resposta 9 |
| D74 | 2026-10-11 | Categorias de log podem ser **ativadas/desativadas** para o Discord, sem afetar os registros essenciais no banco. | Resposta 9 |
| D75 | 2026-10-11 | Organização sem webhook: eventos ficam no banco e podem ir ao canal geral, se configurado. | Resposta 9 |
| D76 | 2026-10-11 | Webhooks em **configuração privada do servidor**; nunca no código, na interface do jogador ou no GitHub. | Resposta 9 |
| D77 | 2026-10-11 | Falha do Discord **não impede** o uso das bolsas nem causa perda de dados. | Resposta 9 |
| D78 | 2026-10-11 | Novas organizações e canais sem mudanças estruturais no código. | Resposta 9 |

| D79 | 2026-10-11 | **Permissão própria no mri_Qadmin (Opção B):** registrar a permissão "Gerenciar Bolsas de Uniformes", configurável na seção Perms, para autorizar grupos específicos da staff. **API pública confirmada:** export `RegisterPermissions(perms, categoryDef)` (documentado em `mri_Qadmin/PERMISSIONS.md`) e verificação via `HasPerms`/`CheckPerms`. | Resposta 10 |
| D80 | 2026-10-11 | Essa permissão permite gerenciar uniformes e bolsas de **todas** as organizações, emitir bolsas, consultar auditorias e executar operações administrativas autorizadas. | Resposta 10 |
| D81 | 2026-10-11 | Não modificar arquivos, tabelas internas ou código do mri_Qadmin para forçar a integração. | Resposta 10 |
| D82 | 2026-10-11 | **Permissão de emergência por ACE específica** do FiveM, configurada explicitamente no servidor; nenhum grupo recebe acesso irrestrito sem configuração. | Resposta 10 |
| D83 | 2026-10-11 | Líderes continuam restritos à própria organização (D16). | Resposta 10 |
| D84 | 2026-10-11 | **Toda verificação de permissão no servidor**; a interface não contorna validações. | Resposta 10 |
| D85 | 2026-10-11 | Ações administrativas importantes (emissão, alteração de uniformes, recuperações excepcionais) vão para a auditoria. | Resposta 10 |
| D86 | 2026-10-11 | Sem API adequada, não criar integração frágil: documentar e propor alternativa ACE. *(Não necessário: API confirmada.)* | Resposta 10 |
| D87 | 2026-10-11 | Ausência ou falha do mri_Qadmin **não concede** acesso administrativo (falha fechada; só a ACE de emergência continua valendo). | Resposta 10 |

| D88 | 2026-10-11 | **Duas portas, uma interface (Opção B).** Staff: entrada **"Bolsas de Uniformes"** na seção Plugins do mri_Qadmin via `RegisterPlugin` (API pública confirmada e documentada no `mri_Qadmin/README.md`; a aba carrega a página NUI do próprio recurso via `resource` + `htmlPath`, e aceita `requiredPerms`/`permDefs`). Só staff com a permissão de D79 acessa; vê todas as organizações. | Resposta 11 |
| D89 | 2026-10-11 | Líderes: **pontos interativos nas sedes**, pelo sistema de interação da base (API `ox_target`, que nesta base é fornecida pelo **mri_Qinteract**), configuráveis por coordenadas. Inicialmente Polícia, Hospital e Mecânica. Líder acessa só a própria organização. Sem comando no acesso normal. | Resposta 11 |
| D90 | 2026-10-11 | Os dois acessos abrem **exatamente a mesma interface**; as funções variam conforme as permissões verificadas no servidor. Nada de dois sistemas administrativos. Interface 100% pt-BR. | Resposta 11 |
| D91 | 2026-10-11 | Pontos de gerenciamento podem ser cadastrados, editados, ativados/desativados e adicionados para organizações futuras. | Resposta 11 |
| D92 | 2026-10-11 | **Não criar pontos em coordenadas presumidas:** identificar as sedes reais e pedir aprovação das localizações antes. | Resposta 11 |
| D93 | 2026-10-11 | A interação verifica organização e permissões do personagem; tudo validado no servidor; sem modificar o mri_Qadmin; a ausência do painel não libera acesso. | Resposta 11 |

| D94 | 2026-10-11 | **Bolsa física no chão durante a troca (Opção A)**, com código próprio e recursos nativos do FiveM. | Resposta 12 |
| D95 | 2026-10-11 | Ao usar o item, o personagem coloca temporariamente uma bolsa física no chão, próxima a ele; depois abre a interface com o uniforme oficial e os compartimentos. | Resposta 12 |
| D96 | 2026-10-11 | Modelo preferido `reh_prop_reh_bag_outfit_01a`, **se confirmado** disponível e utilizável independentemente da Quasar. Achado: o qs-outfitbag **não** faz *stream* desse modelo (não há pasta `stream`), o que indica asset do próprio GTA; confirmar no jogo (build 3751) durante a etapa 1. | Resposta 12 |
| D97 | 2026-10-11 | Troca de roupa com animações nativas do GTA; ao finalizar/cancelar, remover o objeto e devolver o controle. | Resposta 12 |
| D98 | 2026-10-11 | Objeto visível aos jogadores próximos, com sincronização adequada, sem objetos permanentes. | Resposta 12 |
| D99 | 2026-10-11 | Desconexão, morte, cancelamento, afastamento ou erro: encerrar a interação com segurança e remover o objeto temporário. | Resposta 12 |
| D100 | 2026-10-11 | Impedir uso simultâneo da mesma bolsa e duplicação do objeto temporário. | Resposta 12 |
| D101 | 2026-10-11 | A bolsa continua sendo item real do ox_inventory, com ID único e metadados persistentes. | Resposta 12 |
| D102 | 2026-10-11 | O objeto temporário **não é** o drop do inventário. Descartar a bolsa usa **só** o sistema de drop da base, com o objeto padrão e os metadados preservados. | Resposta 12 |
| D103 | 2026-10-11 | O objeto temporário não é coletável nem permite duplicação ou roubo por interação indevida. | Resposta 12 |
| D104 | 2026-10-11 | Desconexão/morte durante a troca: a bolsa real segue as regras normais de inventário, morte e drop da base; nunca é criada ou destruída artificialmente. | Resposta 12 |
| D105 | 2026-10-11 | Nada de código proprietário/protegido do qs-outfitbag; só modelos disponíveis e mecanismos próprios ou públicos. | Resposta 12 |

| D106 | 2026-10-11 | **Identidade visual da MRI (Opção A)**, cor principal de referência **`#6400E6`** (cor da VPS), considerada a cor oficial de referência do Street Roleplay para este projeto. → ver D210. | Resposta 13 |
| D107 | 2026-10-11 | Estilo de referência: mri_Qadmin e mri_Qbossmenu — fundo escuro, organização clara, destaques em roxo. | Resposta 13 |
| D108 | 2026-10-11 | Ler a cor da convar `mri:color` quando viável; padrão `#6400E6` se ausente. **Não** fixar `#9400E6` (valor da base local). | Resposta 13 |
| D109 | 2026-10-11 | Usar o logotipo já configurado no servidor quando acessível e adequado (na VPS: convar `mri:logo`). | Resposta 13 |
| D110 | 2026-10-11 | Mesma aparência no painel aberto pelo mri_Qadmin e pelos pontos das sedes. | Resposta 13 |
| D111 | 2026-10-11 | Interface responsiva, legível, com hierarquia, ícones, mensagens claras e animações discretas; tudo em pt-BR. | Resposta 13 |
| D112 | 2026-10-11 | Cores de status: verde (sucesso), amarelo (aviso), vermelho (erro); roxo como identidade. | Resposta 13 |
| D113 | 2026-10-11 | Não alterar a identidade global dos recursos MRI; personalização só no `street_uniformbag`. Não copiar arquivos proprietários de interface da MRI; interface própria visualmente compatível. | Resposta 13 |

| D114 | 2026-10-11 | **C1 — Emissão gratuita (Opção A)** na primeira versão: nada é debitado do caixa das organizações; **sem integração com o ps-banking**. | Conferência C1 |
| D115 | 2026-10-11 | Só líderes autorizados e staff com a permissão emitem; limite máximo **por lote, configurável**; cada bolsa com ID único e registro individual; auditoria de toda emissão (quem, organização, quantidade, data, hora); depósito no estoque da organização. | Conferência C1 |
| D116 | 2026-10-11 | Arquitetura **preparada** para cobrança futura por emissão (ponto de extensão no serviço de emissão e campo reservado no lote), **sem implementar** cobrança agora. Nenhuma geração automática/ilimitada por funcionários comuns. | Conferência C1 |

| D117 | 2026-10-11 | **C2 — Autorizado** cadastrar o item `uniform_bag` em `ox_inventory/data/items.lua`, **primeiro só na base local**, durante a implementação aprovada. | Conferência C2 |
| D118 | 2026-10-11 | Antes de alterar: **backup verificável** do `items.lua`; verificar se o item já existe (sem duplicar); acrescentar **só** o bloco do item, preservando tudo o que existe; validar a sintaxe e testar o item na base local. | Conferência C2 |
| D119 | 2026-10-11 | Uso pela integração oficial de itens utilizáveis do ox_inventory (`server.export`), confirmada no `items.lua` de exemplo da base. | Conferência C2 |
| D120 | 2026-10-11 | Metadados individuais da bolsa: ID único, organização, uniforme associado e demais dados definidos. | Conferência C2 |
| D121 | 2026-10-11 | **Imagens exclusivas por organização** (Polícia, Hospital, Mecânica; futuras com imagem padrão até terem a sua). Solução confirmada: metadado `image` por bolsa (o ox_inventory usa o mesmo mecanismo internamente em `modules/items/server.lua`), com arquivos PNG em `ox_inventory/web/images`. *Requisito novo trazido na C2; não havia sido registrado antes.* | Conferência C2 |
| D122 | 2026-10-11 | Imagens **próprias**, fundo transparente, compatíveis com o inventário. | Conferência C2 |
| D123 | 2026-10-11 | VPS **não** é alterada agora; a mudança do `items.lua` em produção depende de autorização específica na etapa 6. Alterações documentadas, com procedimento de reversão. | Conferência C2 |

| D124 | 2026-10-11 | **C3 — ps-dispatch + notificação própria por emprego (Opção B).** ps-dispatch gera a ocorrência com coordenadas e marcação no mapa. | Conferência C3 |
| D125 | 2026-10-11 | Destinatários específicos pelos **nomes reais dos empregos no QBox** (ex.: `pmesp`, `rota`), por organização. | Conferência C3 |
| D126 | 2026-10-11 | Cada organização escolhe o modo: **só ps-dispatch**, **só notificação própria** ou **ambos**. | Conferência C3 |
| D127 | 2026-10-11 | Sem duplicação: quem já recebe pelo ps-dispatch não recebe a notificação própria equivalente, quando isso puder ser identificado de forma confiável. Solução: o servidor calcula quem recebe pelo ps-dispatch (tipo de emprego configurado + em serviço, dados do QBox no servidor) e exclui essas pessoas do canal próprio. | Conferência C3 |
| D128 | 2026-10-11 | Notificação própria com **nome da rua** (calculado no cliente de quem recebe) e **ponto temporário no mapa** no local onde a farda foi vestida; sem rastreamento contínuo. | Conferência C3 |
| D129 | 2026-10-11 | Polícia pode alertar corporações específicas, sem obrigação de alertar todo o tipo `leo`. Hospital, Mecânica e futuras configuram os próprios destinatários; nada vai à Polícia por presunção. | Conferência C3 |
| D130 | 2026-10-11 | Serviço ativo: ps-dispatch mantém sua regra; na notificação própria, **configurável** "só em serviço", usando o `onduty` real do QBox. | Conferência C3 |
| D131 | 2026-10-11 | Destinatários validados **no servidor**; nada vindo do cliente define permissões ou destinatários. | Conferência C3 |
| D132 | 2026-10-11 | Cada ocorrência tem **ID único** e registro com bolsa, uniforme, personagem, horário, coordenadas e **canais usados** (e resultado de cada um). | Conferência C3 |
| D133 | 2026-10-11 | Canal indisponível: registrar a falha sem afetar a troca; **sem reenvio automático** que gere duplicatas. | Conferência C3 |
| D134 | 2026-10-11 | Integração **modular**: canais de alerta como adaptadores intercambiáveis (ps-dispatch, notificação própria, futuros), sem reescrever o núcleo. | Conferência C3 |

| D135 | 2026-10-12 | **C4 — Dois modos de autorização por uniforme (Opção B).** **Modo "Graduações específicas"** (opção "Também permitir graduações superiores" desativada): só as graduações selecionadas (uma ou várias). **Modo "Faixa de graduações"** (opção ativada): graduação **mínima** obrigatória e **máxima** opcional, extremos incluídos; sem máxima = mínima e todas acima, pela hierarquia real da organização. Refina D10/D18. | Conferência C4 |
| D136 | 2026-10-12 | Os dois modos **não se misturam**; a interface mostra claramente qual está em uso. | Conferência C4 |
| D137 | 2026-10-12 | Graduações validadas pelos **cargos reais do QBox** de cada organização (sem presumir estrutura comum); fora da autorização = troca permitida + ocorrência de uso indevido; vale para todas as organizações; validação no servidor. | Conferência C4 |

| D138 | 2026-10-12 | **C5 — Monitoramento combinado (Opção C):** escutar, sem alterar, o salvamento de aparência do mri_Qappearance (`illenium-appearance:server:saveAppearance`, confirmado na base: o cliente envia a aparência e o servidor grava) **e** conferir a roupa atual na mudança de cargo. | Conferência C5 |
| D139 | 2026-10-12 | Aparência salva diferente da farda registrada → encerra o registro "farda em uso" (evidência confiável de troca legítima). | Conferência C5 |
| D140 | 2026-10-12 | Na mudança de cargo com registro ativo, conferir se o personagem ainda veste o uniforme, comparando **só componentes e acessórios de roupa** do uniforme, considerando o modelo (sem rosto, cabelo, tatuagens etc.). | Conferência C5 |
| D141 | 2026-10-12 | **Matriz de decisão na mudança de cargo:** (a) conferência confirma a farda no corpo e a nova situação é irregular → **ocorrência**; (b) farda retirada confirmada por salvamento de aparência → registro já encerrado, **sem alerta**; (c) cliente diz que não está fardado mas **não houve** salvamento que comprove a troca, ou não respondeu → **"pendente de verificação"** na auditoria, sem acusação e sem encerramento silencioso. | Conferência C5 |
| D142 | 2026-10-12 | Não confiar só no cliente: a resposta do cliente nunca cancela sozinha um registro; serve para confirmar o alerta (a) ou para marcar pendência (c). | Conferência C5 |
| D143 | 2026-10-12 | Sem alertas duplicados nem verificações desnecessárias (verificação só com registro ativo e mudança efetiva de autorização). | Conferência C5 |
| D144 | 2026-10-12 | Documentar as limitações de verificar a aparência real no FiveM (scripts que trocam roupa sem salvar geram pendências). | Conferência C5 |
| D145 | 2026-10-12 | Testes obrigatórios: troca pela bolsa, loja de roupas, guarda-roupa residencial, vestiário, desconexão, reconexão e mudança de cargo. | Conferência C5 |

| D146 | 2026-10-12 | **C6 — Recuperação para personagem offline (Opção A, com confirmação do jogador).** Staff autorizada registra a recuperação; sem bolsa física, sem criar bolsas e sem alterar inventários. | Conferência C6 |
| D147 | 2026-10-12 | Motivo **obrigatório**; registra administrador, personagem beneficiado, data, horário e dados de auditoria. | Conferência C6 |
| D148 | 2026-10-12 | Recuperação persistente com status **"Aguardando aplicação"**. | Conferência C6 |
| D149 | 2026-10-12 | Ao entrar, o sistema espera o carregamento completo do personagem e do mri_Qappearance e mostra uma **notificação**: "Restaurar agora" ou "Restaurar depois". Nunca aplica automaticamente. | Conferência C6 |
| D150 | 2026-10-12 | "Restaurar agora": guarda a aparência atual para reversão, aplica a recuperada e **salva só após confirmação de sucesso**; em falha, mantém pendente e preserva a aparência anterior. "Restaurar depois": continua pendente, acessível depois, sem perda de dados. | Conferência C6 |
| D151 | 2026-10-12 | Recuperação **exclusiva** do personagem beneficiado (validação no servidor); sem aplicação duplicada; conclusão registrada. | Conferência C6 |
| D152 | 2026-10-12 | Uso **excepcional**: falhas técnicas ou situações justificadas pela staff; **nunca** para devolver roupas perdidas por roubo ou consequências normais do RP. | Conferência C6 |
| D153 | 2026-10-12 | Após a recuperação, atualizar o estado "farda em uso" (encerrar ou ajustar), evitando alertas falsos futuros. | Conferência C6 |

| D154 | 2026-10-12 | **C7 — Limites operacionais aprovados com ajustes.** (1) Bolsa bloqueada se morto/incapacitado, algemado/imobilizado, em veículo ou nadando — verificado antes de iniciar e durante a operação. Fontes confirmadas: QBox `metadata.isdead`, `metadata.inlaststand`, `metadata.ishandcuffed` (servidor) + statebag `isDead` do ars_ambulancejob; veículo/água no cliente. | Conferência C7 |
| D155 | 2026-10-12 | (2) Afastar-se **mais de 3 m** do objeto temporário cancela com segurança: sem apagar roupas, sem duplicar itens, sem objeto abandonado. | Conferência C7 |
| D156 | 2026-10-12 | (3) Trava inicial de **60 s**, renovada enquanto a interação está ativa, **configurável**; liberada em desconexão, cancelamento ou expiração; **nunca liberada durante a finalização de uma troca** (controle de estado + recuperação de falhas). | Conferência C7 |
| D157 | 2026-10-12 | (4) Até **20 bolsas por lote**, configurável; cada bolsa com ID único, registro e auditoria. | Conferência C7 |
| D158 | 2026-10-12 | (5) Marcador do alerta por **120 s**, configurável por organização; marca o local do uso, sem acompanhar o jogador. | Conferência C7 |
| D159 | 2026-10-12 | (6) Recuperação pendente: aviso a cada entrada **e** comando **`/minharoupa`**, só para o próprio personagem, sem acesso a roupas de terceiros, sempre com confirmação do jogador. | Conferência C7 |
| D160 | 2026-10-12 | Todos os limites centralizados na configuração do `street_uniformbag`; cancelamentos/desconexões nunca causam perda de roupa; sem alterar ox_inventory ou mri_Qappearance; erros relevantes registrados para diagnóstico; comportamentos validados em teste antes da implantação. | Conferência C7 |
| D161 | 2026-10-12 | **C8 — Opção A.** Auditoria **permanente**: nenhuma exclusão automática de emissão, retirada, transferência, troca, uso indevido, alertas, recuperação e demais operações relevantes. Preserva bolsa, personagem, organização, administrador (quando houver), data/hora e dados de investigação, mesmo após a bolsa ser perdida, roubada, abandonada ou ficar inativa. | Conferência C8 |
| D162 | 2026-10-12 | Índices e consultas paginadas para desempenho; estrutura preparada para **arquivamento administrativo futuro**, sem exclusão automática nesta versão. | Conferência C8 |
| D163 | 2026-10-12 | Bolsa sem **atividade confirmada** há **30 dias** (configurável) é classificada como **"Desconhecida/Inativa"** — só administrativa: não exclui bolsa, uniformes, roupas, compartimentos, metadados nem histórico; não bloqueia uso; não altera propriedade nem localização; não gera reposição automática. Nova atividade legítima ⇒ volta automaticamente a "Em circulação". | Conferência C8 |
| D164 | 2026-10-12 | Atividade confirmada = só o que o sistema detecta com segurança: movimentações pelo hook `swapItems` do ox_inventory (inclui dar — `giveItem` dispara o hook, verificado —, dropar, pegar, baú), retirada do baú, uso da bolsa, emissão. **Entrar no servidor não conta.** Ausência de atividade **não** é prova de perda. Limitações no TRD §8. | Conferência C8 |
| D165 | 2026-10-12 | Estados alterados só no servidor; classificação por rotina periódica leve (uma consulta indexada, sem varredura contínua); rastreabilidade mantida em falhas/reinícios. | Conferência C8 |
| D166 | 2026-10-12 | Painel: filtros por Em circulação, Desconhecidas/Inativas, organização, ID individual e última atividade confirmada; bolsas desconhecidas seguem consultáveis. | Conferência C8 |
| D167 | 2026-10-12 | **C9 — Opção A.** Repositório GitHub **privado** `street_uniformbag` (conta `welingtonivoivo-ctrl`), mesmo nome da pasta `resources/[meus_scripts]/street_uniformbag`; mesmo nome em todas as referências internas, configurações, documentação e integrações. Proibido `street-uniformbag` e renomear a pasta. → ver D210. | Conferência C9 |
| D168 | 2026-10-12 | Criação do repositório **só na etapa 1**, após aprovação geral do planejamento **e** autorização da primeira publicação; antes, verificar se `street_uniformbag` já existe na conta (evitar duplicidade). | Conferência C9 |
| D169 | 2026-10-12 | Nada sensível no GitHub (credenciais, tokens, webhooks, senhas, dumps, dados de jogadores, config privada da VPS); `.gitignore` exclui temporários, backups, logs e arquivos sensíveis; conferência do conteúdo preparado antes de cada envio. Nenhuma alteração na VPS nessa etapa. | Conferência C9 |
| D170 | 2026-10-12 | **C10 — Opção A.** Imagens próprias criadas para o projeto: padrão roxa `#6400E6` (identidade Street) + Polícia (azul-escuro, escudo), Hospital (vermelho, símbolo médico), Mecânica (laranja, chave/ferramenta). Nada copiado do qs-outfitbag ou de recursos comerciais. | Conferência C10 |
| D171 | 2026-10-12 | Todas seguem o **mesmo modelo visual**; mudam só cor, símbolo e detalhes de identificação. | Conferência C10 |
| D172 | 2026-10-12 | Acabamento profissional: estilo 3D, boa iluminação, detalhes definidos, aparência de item de jogo; PNG com fundo transparente, 256 × 256 px (compatível com o ox_inventory), boa qualidade e arquivo leve. | Conferência C10 |
| D173 | 2026-10-12 | **Honestidade sobre ferramentas:** se o ambiente não tiver ferramenta à altura, informar a limitação e propor alternativa para aprovação; nunca afirmar que imagens foram criadas sem gerar os arquivos. | Conferência C10 |
| D174 | 2026-10-12 | Organizações futuras recebem imagem própria **só por configuração** (campo `item_image` no painel), sem mexer no núcleo; sem imagem ⇒ padrão roxa automaticamente; troca de imagem sem alterar código, com validação do nome (só `[a-z0-9_]`, até 60 caracteres, sem caminhos, sem extensão, arquivo precisa existir em `ox_inventory/web/images`). | Conferência C10 |
| D175 | 2026-10-12 | Criação das imagens faz parte da **implementação** (etapa 3), não do planejamento; apresentadas para aprovação **antes** de entrar na base; cópia para `ox_inventory/web/images` só na base local e após a autorização geral (regra C2). Verificação do ambiente (2026-10-12): só Node.js instalado; **sem** Blender, ImageMagick, Inkscape, Python nem gerador de imagens por IA — ver C10.1. | Conferência C10 |
| D176 | 2026-10-12 | **C10.1 — Opção A: Blender.** Instalação **só na etapa 3**, após a aprovação geral **e** autorização específica para instalar; somente a versão oficial de `blender.org`, sem instaladores de terceiros. A escolha não autoriza instalação imediata. | Conferência C10.1 |
| D177 | 2026-10-12 | **Um único modelo 3D original** de bolsa (alça, zíper, costuras, etiqueta, iluminação adequada); quatro renders — padrão roxa `#6400E6`, Polícia azul-escura/escudo, Hospital vermelha/símbolo médico, Mecânica laranja/chave ou ferramenta — com **exatamente** o mesmo formato, enquadramento, perspectiva e proporções; mudam só cores e identificação. | Conferência C10.1 |
| D178 | 2026-10-12 | PNG com fundo **realmente transparente** (canal alfa), luz e sombras apropriadas, 256 × 256 px. Guardar o `.blend` e os scripts de geração no repositório (`art/`) para reproduzir e criar versões de organizações futuras. Nenhum modelo, textura ou arte protegida de terceiros. | Conferência C10.1 |
| D179 | 2026-10-12 | Quatro imagens apresentadas para aprovação **antes** de integrar ao inventário. Se a modelagem automatizada não atingir a qualidade, **não substituir silenciosamente** por imagens inferiores: mostrar o resultado e as alternativas. | Conferência C10.1 |
| D180 | 2026-10-12 | **I1 confirmada — troca segura no mesmo compartimento.** Com os 3 compartimentos ocupados, o jogador pode vestir **qualquer** roupa guardada; a roupa atual vai para o compartimento de onde a escolhida saiu. Exemplo aprovado: de farda, escolhe a civil do compartimento 2 ⇒ civil no corpo, farda no compartimento 2. (Vestir o **uniforme da bolsa** com tudo cheio continua impedido — D47 —, pois não há compartimento de onde a roupa sai.) | Conferência I1 |
| D181 | 2026-10-12 | Nenhuma roupa apagada, descartada ou sobrescrita sem preservação; cada aparência guardada por inteiro (componentes, acessórios/props, variações, texturas, modelo e metadados necessários para restaurar). | Conferência I1 |
| D182 | 2026-10-12 | Troca **transacional com controle de estado**: aparência nova confirmada como aplicada antes de concluir; **diário de operações persistente** no banco (`sub_operations`) para que erro, cancelamento, desconexão ou reinício permitam concluir ou reverter com segurança, sem perda nem duplicação. | Conferência I1 |
| D183 | 2026-10-12 | Uma operação por bolsa por vez (trava D156 + versão); roupa incompatível com o modelo (M/F) não pode ser selecionada nem aplicada. | Conferência I1 |
| D184 | 2026-10-12 | **A troca não contorna a verificação de farda:** se a roupa guardada no compartimento for uma farda oficial (registrada em "farda em uso" ao ser guardada), vesti-la a partir do compartimento passa pela mesma autorização e, se indevida, gera ocorrência — uso visual permitido, ocorrência registrada (D11). | Conferência I1 |
| D185 | 2026-10-12 | Interface mostra claramente **o que será vestido** e **o que será guardado** no compartimento antes de confirmar. | Conferência I1 |
| D186 | 2026-10-12 | Testes com 3 compartimentos cheios, incluindo falha, cancelamento, desconexão e reinício no meio da troca. | Conferência I1 |
| D187 | 2026-10-12 | **I2 confirmada.** Roupas em **tabelas próprias do MariaDB** ligadas ao **ID único da bolsa**; o item do ox_inventory carrega só `bagId` e metadados leves (`uniformId`, `org`, `label`, `description`, `image`). Os dados pertencem à **identidade da bolsa**, não ao personagem que a possui; a bolsa segue totalmente transferível (D3, D4). | Consolidação final |
| D188 | 2026-10-12 | Persistência após transferência, roubo, drop, baú e reinício; **integridade referencial** por chaves estrangeiras (bolsa → uniforme, compartimento → bolsa, diário → bolsa) sem exclusão em cascata a partir da bolsa; operações críticas transacionais; dados versionados (`sub_bags.version`). | Consolidação final |
| D189 | 2026-10-12 | **Duplicidade:** detectada quando a mesma bolsa aparece em dois inventários (verificação no uso e nas movimentações, conferindo o inventário anterior registrado). Bolsa marcada fica **bloqueada para uso** com aviso, até a staff resolver no painel (ação auditada). **Nunca** se cria cópia dos conjuntos; as cópias compartilham os mesmos compartimentos do banco. Não contradiz D4: o bloqueio é de integridade, não de propriedade. | Consolidação final |
| D190 | 2026-10-12 | **Banco é a autoridade;** metadados do item são cópia de apresentação, ressincronizados (`SetMetadata`) a cada atividade confirmada. Item com `bagId` desconhecido, ausente ou marcado como inválido **não tem efeito** (uso recusado com aviso) e gera auditoria. | Consolidação final |
| D191 | 2026-10-12 | **Correção técnica (não muda produto):** o hook `createItem` do ox_inventory **não bloqueia** a criação; só pode alterar metadados (verificado em `ox_inventory/modules/items/server.lua:224-234`). Assim, bolsa criada fora da emissão (ex.: `/giveitem`) recebe metadado de invalidez pelo hook e **fica sem efeito** (D190), com auditoria — atendendo ao critério do PRD "bloqueados **ou** ficam sem efeito". O TRD que dizia "bloqueia" foi corrigido. | Consolidação final |
| D192 | 2026-10-12 | **Esclarecimento de D47 × D180** (duas operações distintas): (a) **guardar nova roupa** — vestir o uniforme da bolsa exige compartimento livre e é impedido com tudo cheio (D47 permanece); (b) **trocar por roupa já guardada** — funciona com tudo cheio, pela troca no mesmo compartimento (D180). Não existe descarte automático nem manual de roupa. | Consolidação final |
| D193 | 2026-10-12 | **Esclarecimento de D48:** "a roupa atual é o uniforme desta bolsa" é decidido **no servidor**, pelo registro "farda em uso" (mesmo `uniform_id` da bolsa), nunca por afirmação do cliente. Nesse caso a roupa não ocupa compartimento; farda de **outro** uniforme vai para o compartimento marcada como farda (D184). | Consolidação final |
| D194 | 2026-10-12 | **Esclarecimento de D51/D52:** compartimentos só mudam na transação do `confirmChange`, depois da confirmação de aplicação; a "ação explícita" de D52 é o **Confirmar troca** da tela D185, feito por quem usa a bolsa. | Consolidação final |
| D195 | 2026-10-12 | **Esclarecimento de D44/D54:** o uniforme oficial da bolsa é **permanente como modelo de referência** (cadastro `sub_uniforms`/`sub_uniform_variants`, ligado por `uniform_id`); nunca é guardado em compartimento nem "consumido" ao ser vestido; editar o cadastro atualiza todas as bolsas daquele uniforme. Compartimentos guardam **cópias completas** das roupas do personagem. | Consolidação final |
| D196 | 2026-10-12 | **Marcação de farda no servidor:** ao guardar uma roupa, o servidor marca o compartimento como farda se houver "farda em uso" **ou** se as peças de roupa coincidirem com alguma versão de uniforme ativa cadastrada (comparação de dados feita no servidor). Mitiga um cliente que tente esconder farda como roupa civil. | Consolidação final |
| D197 | 2026-10-12 | **Confirmação de salvamento:** o diário registra quando o `saveAppearance` do jogador chega após a troca; troca concluída sem salvamento confirmado é reaplicada ao reconectar. | Consolidação final |
| D198 | 2026-10-12 | **Limites de segurança assumidos (sem garantias falsas):** (1) aplicação de aparência é confirmada pelo cliente — cliente adulterado afeta só a própria aparência, e aparência não é item econômico; (2) ps-dispatch envia o alerta a todos os clientes e filtra no cliente — o conteúdo do alerta pode ser visto por cliente adulterado e a anti-duplicação depende da regra atual do ps-dispatch; (3) detecção de duplicidade e rastreio dependem do que passa pelo ox_inventory — não é exaustiva; (4) cliente adulterado pode sempre mudar a própria roupa visualmente fora da bolsa; o sistema garante auditoria do que passa pela bolsa. | Consolidação final |

| D199 | 2026-10-12 | **Ajuste técnico da etapa 1 (V3), aprovado pelo dono:** o mri_Qadmin não exporta `HasPerms` (só `RegisterPermissions`, `RegisterPlugin` e outros). A permissão de staff é conferida com natives ACE do FiveM pelos mesmos caminhos do mri_Qadmin (jogador, `char:<citizenid>`, `job.<nome>[.<grau>]`, bypass `qadmin.master`), **sem** herdar o acesso automático de `god`/`admin` (respeita D82) e só com o mri_Qadmin iniciado (D87). Nenhum código do mri_Qadmin é chamado ou alterado. | Etapa 1 |
| D200 | 2026-10-12 | **Achado técnico da etapa 1:** natives de modelo devolveram `1` em vez de `true` nesta build; todo resultado de native usado em decisão é convertido explicitamente para booleano, e o servidor valida tipos recebidos. V1 confirmada: `reh_prop_reh_bag_outfit_01a` existe e carrega no jogo. | Etapa 1 |

| D201 | 2026-10-12 | **Ajuste técnico da etapa 2:** datas em `DATETIME` (o `TIMESTAMP` termina em 2038 e a auditoria é permanente); colunas JSON com `CHECK (JSON_VALID)`; `sub_operations.restored_at` para controlar a reaplicação da aparência após reversão (D182). Nenhuma decisão de produto alterada. | Etapa 2 |

| D202 | 2026-10-12 | **Organizações sempre dinâmicas (confirmado com o dono na etapa 2):** nenhuma organização fixa no código; os jobs criados no painel Jobs do mri_Qbossmenu são enviados ao QBox (`CreateJobs`, `mri_Qbossmenu/modules/server/runtime.lua:352`) e o `street_uniformbag` lê `exports.qbx_core:GetJobs()` **no momento de abrir o painel** (nunca uma lista guardada desde o início), para incluir jobs criados com o servidor ligado. Líder continua sendo o cargo de chefe do job (D16/T6, opção A mantida). Gangues ficam fora desta versão. | Etapa 2 |

| D203 | 2026-10-12 | **Bolsa no chão durante toda a sessão (pedido do dono no teste da etapa 3; refina D95/D97/D99):** enquanto a tela está aberta o personagem fica em animação contínua mexendo na bolsa; ao vestir, animação de vestir; depois da troca a bolsa **continua no chão** e a tela continua aberta; botão **"Recolher bolsa"** (também ESC): o personagem se abaixa, pega a bolsa e o objeto some. Cancelamentos de segurança (D154/D155) continuam removendo o objeto na hora. | Etapa 3 |
| D204 | 2026-10-12 | **Prévia ao passar o mouse:** ao passar o mouse sobre o uniforme oficial ou um compartimento compatível, aparece ao lado do personagem uma **cópia local** dele vestida com aquela roupa, visível só para quem usa a bolsa; some ao tirar o mouse. Código próprio (a prévia do qs-outfitbag é criptografada e a do mri_Qemotes não é pública; nada é copiado — D105, D113). Dados da prévia só para quem está com a bolsa travada. | Etapa 3 |
| D205 | 2026-10-12 | **Comando `/adminoutfit` (opção A):** terceira porta para o mesmo Painel (D90), **só para staff** com "Gerenciar Bolsas de Uniformes" ou ACE de emergência; líderes continuam pelos pontos das sedes. Painel completo, sem necessidade de comandos no F8/chat: cadastrar uniforme pela roupa atual, escolher organização e cargos, abas com as bolsas de cada organização. Refina D88–D90. Construído na **etapa 4** (opção A da ordem). | Pedido do dono |
| D206 | 2026-10-12 | **Loja de roupas no painel (opção A):** botão "Abrir loja de roupas" no Painel abre o editor do mri_Qappearance pela API pública `startPlayerCustomization`, **gratuito**, **só roupas e acessórios** (sem rosto, cabelo, tatuagem); ao confirmar, salva como uma loja normal; ao cancelar, nada muda. Etapa 4. | Pedido do dono |
| D207 | 2026-10-12 | **Ordem mantida (opção A):** terminar os ajustes D203/D204 e os testes da etapa 3 (alerta, uso indevido, falhas) com os comandos provisórios; o painel completo com `/adminoutfit` e a loja chega na etapa 4. **Bolsa comum para cidadãos (opção A):** item separado, roupas pessoais, 3 espaços iniciais e espaço extra comprado com coins — planejada (entrevista, documentos, aprovação) **logo depois de concluir a etapa 3 e antes da etapa 4**, para o painel já nascer contemplando as duas bolsas. | Pedido do dono |

| D208 | 2026-10-12 | **Bolsa de verdade no chão (opção A do dono; substitui D102/D103 e ajusta D99/D155/D203):** usar o item tira a bolsa do inventário e a coloca **no chão**, gravada no banco (`sub_ground_bags`) com posição; **qualquer jogador** perto pode **abrir** (D4) ou **recolher** (vai para o inventário de quem recolheu — inclusive outra pessoa, como no RP). Depois da troca o painel fecha e o personagem fica em pé; a bolsa só sai do chão quando alguém recolhe. Persistente: **não some com o tempo nem com reinício** (o objeto é recriado). **Motivo técnico de não usar o drop do ox_inventory:** drops sem uso são apagados após `inventory:cleartime` (5 min nesta base) e não sobrevivem a reinício — a bolsa esquecida sumiria com as roupas. Soltar a bolsa pelo inventário continua usando o drop normal do ox_inventory. Afastar-se mais de 3 m fecha só o painel (a bolsa fica). | Teste da etapa 3 |

| D209 | 2026-10-12 | **Caminhar até a bolsa (pedido do dono):** ao escolher "Abrir bolsa" ou "Recolher bolsa" a distância, o personagem caminha até ficar de frente para a bolsa (`Config.Approach`) e só então anima; qualquer comando de movimento do jogador ou caminho travado cancela sem alterar nada. Teste do dono confirmou: roupas guardadas e aplicadas corretamente, nada perdido, bolsa volta ao inventário ao recolher e permanece no chão quando deixada. | Etapa 3 |
| D210 | 2026-10-12 | **Recurso distribuível, sem marca da cidade (pedido do dono):** o nome técnico passa de `street_uniformbag` para **`vel_uniformbag`** (pasta, eventos, permissão `vel_uniformbag.manage`/`.admin`, convars `vel_uniformbag_webhook_<org>`/`_admin`, export `vel_uniformbag.useBag`, repositório GitHub). "Street Roleplay" sai do autor, README, tutorial e documentos; `#6400E6` vira só a cor padrão quando o servidor não define `mri:color`. Item `uniform_bag`, tabelas `sub_*` e dados não mudam. | Dono, 2026-10-12 |

### Interpretações (todas confirmadas)
- **I1 — CONFIRMADA em 2026-10-12 (D180–D186, esclarecida em D192–D194).** Troca segura no mesmo compartimento, numa única operação, depois de confirmada a aplicação. Nada é apagado.
- **I2 — CONFIRMADA em 2026-10-12 (D187–D191).** Roupas em tabela do banco ligada ao ID da bolsa; o item carrega só o ID e dados leves.

## Achados técnicos (para o TRD)

- **ps-dispatch 2.1.7** está na base local. O alerta pode ser criado **pelo servidor**, disparando o evento `ps-dispatch:server:notify` com os dados montados no próprio servidor (destinatários em `alert.recipientList`, coordenadas lidas no servidor). Assim o alerta **não depende do cliente de quem cometeu o uso indevido**, que poderia bloqueá-lo. O export `CustomAlert` é só do lado do cliente. Limitação: o nome da rua é calculado no cliente; no servidor será preciso outra fonte ou omitir. *(Resolvido na C3/T12: a rua é calculada no cliente de quem recebe.)*
- **ox_inventory** permite depositar itens com metadados em um baú registrado pelo servidor (`AddItem` no ID do baú) e detectar retiradas/transferências por *hooks* do inventário; a viabilidade exata com os baús do bossmenu será confirmada no TRD.

- **Permissões administrativas disponíveis na base:** (1) ACE do FiveM/QBox — `exports.qbx_core:HasPermission(source, 'admin')`, com `group.admin` definido em `permissions.cfg`; (2) sistema de permissões do **mri_Qadmin** — exports públicos `HasPerms`, `CheckPerms`, `RegisterPermissions`, além de `RegisterPlugin`/`OpenPluginForPlayer` para telas dentro do painel do mri_Qadmin.

- **ps-dispatch filtra destinatários por TIPO de emprego** (`PlayerData.job.type`, ex.: `leo`, `ems`, `mechanic`), não pelo nome do emprego, e só para quem está **em serviço** (`client/main.lua`, `isJobValid` e `IsOnDuty`). O alerta é enviado a todos os clientes e filtrado no cliente.
- **mri_Qbossmenu não expõe API pública de permissão de líder.** Exports públicos relevantes: `GetManagedDefinition` / `GetManagedDefinitions` (incluem os baús de cada organização). Líder = `isboss` do QBox.
- **Eventos de emprego do QBox (servidor):** `QBCore:Server:OnJobUpdate (source, job)` e `qbx_core:server:onGroupUpdate (source, groupName, grade?)`.
- **Hooks do ox_inventory disponíveis:** `buyItem`, `craftItem`, `createItem`, `openInventory`, `openShop`, `swapItems`, `usingItem`.
- **Persistência de aparência da base:** evento de servidor `illenium-appearance:server:saveAppearance` (mri_Qappearance), que grava a aparência enviada pelo cliente.

## Impacto das decisões no briefing original

- O briefing previa "verifica se pertence à organização e possui o cargo autorizado" antes de usar. Com D4, essa verificação **não bloqueia o uso**: ela passa a definir se o uso é **regular** ou **indevido** (D5).

## Pendências da entrevista (todas resolvidas)

- P1. ~~Resolvida~~ (D8, D12, D13; canal e conteúdo na C3, D124–D134).
- P2. ~~Resolvida~~ (D70–D78).
- P3. ~~Resolvida~~ (D8, D34–D43).
- P8. ~~Resolvida~~ (D44–D56; ver I1 e I2).
- P9. ~~Resolvida~~ (D57–D69).
- P10. ~~Resolvida~~ (D79–D87).
- P11. ~~Resolvida~~ (D88–D93). Verificação técnica da implementação (não é decisão de produto): levantar as sedes reais de Polícia, Hospital e Mecânica e submeter as coordenadas à aprovação (D92).
- P12. ~~Resolvida~~ (D94–D105).
- P13. ~~Resolvida~~ (D106–D113).

- P4. ~~Resolvida~~ (D14–D22; sem API pública de líder no bossmenu ⇒ `isboss`, T6).
- P5. ~~Resolvida~~ (D17: gênero/modelo escolhido no cadastro).
- P6. ~~Resolvida~~ (D24–D33; baú escolhido na emissão, com padrão por organização — `default_stash_id`).
- P7. ~~Resolvida~~ (D14: `street_uniformbag`).

Conferência C1–C10.1, I1 e I2: todas resolvidas. **Nenhuma decisão de produto em aberto.**

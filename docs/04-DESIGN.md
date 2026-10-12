# 04 — Briefing de Design

Versão: 1.1 (consolidada, para aprovação geral) — 2026-10-12
Decisões: D106–D113, D154–D159, D166, D170–D179, D185, D189–D192. Valores marcados como **(proposta)** não são identidade oficial: com a aprovação geral do planejamento passam a valer como padrão inicial, ajustáveis na revisão visual da etapa 3.

## 1. Identidade

- **Público:** jogadores e lideranças de organizações de RP; staff.
- **Três palavras:** sóbrio, organizado, institucional.
- **Referências aprovadas:** painéis do mri_Qadmin e do mri_Qbossmenu (fundo escuro, destaques em roxo) (D107).
- **Cor padrão:** `#6400E6`, usada só quando o servidor não define `mri:color` (D106 → ver D210). Logotipo: o configurado no servidor (convar `mri:logo` na VPS), quando disponível (D109).
- A interface é **própria**, visualmente compatível com a MRI, sem copiar arquivos dela (D113).
- Arquivos da interface (`web/`) e imagens das bolsas são versionados no repositório privado `vel_uniformbag` (D167); logotipo e cor vêm das convars do servidor, nunca de arquivo privado no repositório.

## 2. Cores

| Papel | HEX | Origem |
|---|---|---|
| Principal | `#6400E6` | D106 — lida da convar `mri:color`, com este valor como padrão (D108) |
| Principal (hover) | `#7A1FFF` | (proposta) derivada da principal, +10% de luz |
| Secundária | `#2A1A4A` | (proposta) roxo escuro para cartões selecionados |
| Destaque | `#B794FF` | (proposta) roxo claro para selos e links |
| Fundo | `#0F0F14` | (proposta) quase preto |
| Superfície (cartões) | `#17171F` | (proposta) |
| Borda | `#2A2A35` | (proposta) |
| Texto principal | `#F2F2F7` | (proposta) |
| Texto secundário | `#9A9AAE` | (proposta) |
| Sucesso | `#22C55E` | D112 (verde) — tom (proposta) |
| Aviso | `#EAB308` | D112 (amarelo) — tom (proposta) |
| Erro | `#EF4444` | D112 (vermelho) — tom (proposta) |

Se `mri:color` vier com outro valor, os tons de hover/secundária/destaque são recalculados a partir dele.

## 3. Tipografia (proposta)

- Fonte: **Inter** servida junto com o recurso (arquivo local, sem carregar da internet); alternativa do sistema: `Segoe UI, sans-serif`.
- Títulos: 20 px, peso 700. Subtítulos: 15 px, peso 600. Texto: 13–14 px, peso 400. Rótulos: 11 px, maiúsculas, peso 600, espaçamento 0,04 em. Mensagens/notificações: 13 px.

## 4. Componentes

- **Botões:** primário (fundo principal, texto branco), secundário (contorno principal), perigo (vermelho). Altura 36 px; estado desabilitado com 40% de opacidade e cursor bloqueado.
- **Campos:** fundo superfície, borda 1 px, foco com borda principal.
- **Cartões:** compartimentos e uniformes; cartão selecionado com fundo secundário e borda principal.
- **Tabelas:** auditoria e estoque, linhas zebradas leves, cabeçalho fixo, paginação.
- **Menus:** abas horizontais no Painel.
- **Modo de autorização (D136):** chave "Também permitir graduações superiores"; abaixo dela aparece **só** o controle do modo ativo (caixas de graduação **ou** seletores mínima/máxima) e um resumo em texto, ex.: "Autorizado para: Sargento e Tenente".
- **Confirmação de troca (D185):** antes de aplicar, painel com dois blocos lado a lado — "Você vai vestir" (compartimento K, quem guardou, data; selo "Farda oficial" se for o caso) e "Será guardada no compartimento K" (roupa atual; selo "Farda" se for farda); botões **Confirmar troca** (primário) e **Voltar** (secundário). Compartimento incompatível fica com o botão desabilitado e o selo "Incompatível com seu personagem" (D183).
- **Modais:** confirmação de emissão, recuperação (com campo de motivo obrigatório) e exclusão; para o jogador, modal "Roupa restaurada pela administração" com pré-visualização em texto (motivo, data) e botões **Restaurar agora** (primário) / **Restaurar depois** (secundário); o mesmo modal reabre pelo comando `/minharoupa` (D159).
- **Avisos de bloqueio (D154–D157):** notificação curta (`lib.notify`), sem abrir tela: "Você não pode usar a bolsa agora" (morto, algemado, em veículo, nadando), "Você se afastou da bolsa — troca cancelada, nada foi alterado", "Esta bolsa está em uso", "Limite de 20 bolsas por lote".
- **Tela "Bolsa" — separação visual (D195):** o cartão **Uniforme oficial** fica no topo, com estilo próprio (borda principal e rótulo "Modelo oficial da bolsa"); os **compartimentos** ficam abaixo, numerados, como cartões de roupa guardada. Com todos cheios, o botão **Vestir uniforme** fica desabilitado com a dica "Vista uma das roupas guardadas para trocar" (D192).
- **Selos:** "Livre", "Ocupado", "Farda" (compartimento com farda guardada, D184), "Incompatível com seu personagem", "Uso irregular", "Em estoque", "Em circulação", "Desconhecida/Inativa" (cinza, com dica "Sem atividade confirmada há X dias — não significa perda"), "Bloqueada — verificação" (vermelho, bolsa duplicada, D189), "Não reconhecida" (bolsa inválida, D190).
- **Filtros do Estoque (D166):** estado (inclui "Duplicadas"), organização (só staff), campo de ID, intervalo de "última atividade confirmada"; coluna "Última atividade" com data e tipo.
- **Liberar bolsa duplicada (só staff):** modal com histórico de localizações, campo de motivo obrigatório e botão **Liberar bolsa** (perigo).
- **Notificações:** as da base (`lib.notify`), em pt-BR. Alerta próprio de uso irregular: título "Uso irregular de farda", corpo com uniforme e rua, cor de aviso; ponto no mapa temporário (ícone de alerta, cor de aviso), removido automaticamente (D128).
- **Ícones:** Lucide (mesma família usada pelos plugins do mri_Qadmin), servidos junto com o recurso.

### Imagens do item no inventário (D121, D122)
- Uma imagem por organização: `uniform_bag_police.png`, `uniform_bag_ems.png`, `uniform_bag_mechanic.png` (nomes finais conforme os empregos reais), mais `uniform_bag.png` como padrão para organizações sem imagem própria.
- PNG com fundo transparente, 256 × 256 px, leve (abaixo de 100 KB), estilo coerente com os demais ícones do inventário.
- Imagens **próprias**, sem copiar imagens, modelos ou elementos do qs-outfitbag ou de outros recursos comerciais (D170, D173).
- **Modelo visual único (C10, D171):** mesma bolsa (mesmo formato, ângulo de 3/4, alça, zíper e etiqueta frontal), mudando só cor, símbolo e detalhes:
  | Arquivo | Cor principal | Símbolo |
  |---|---|---|
  | `uniform_bag.png` (padrão) | roxo `#6400E6` (padrão) | bolsa estilizada, sem marca de cidade (D210) |
  | `uniform_bag_police.png` | azul-escuro | escudo |
  | `uniform_bag_ems.png` | vermelho | símbolo médico (cruz) |
  | `uniform_bag_mechanic.png` | laranja | chave/ferramenta |
- **Acabamento (D172):** aparência de item de jogo em estilo 3D — volume, luz principal de cima/esquerda, sombra de contato suave, brilho no zíper e fivelas, textura de tecido sutil; nada de ícone chapado.
- Organizações sem imagem configurada usam `uniform_bag.png` automaticamente (D174).
- **Produção (C10.1, D176–D179):** Blender oficial (`blender.org`), instalado só na etapa 3 com autorização específica. Um modelo 3D original (alça, zíper, costuras, etiqueta), câmera e luzes fixas; quatro renders que trocam só material e símbolo; PNG 256 × 256 com canal alfa real. Fonte `.blend` e script de geração guardados em `art/` para organizações futuras. Aprovação das quatro imagens antes da integração; se a qualidade não for atingida, apresentar o resultado e alternativas, sem troca silenciosa.

## 5. Organização

- Espaçamento base 8 px; bordas 1 px; arredondamento 10 px nos cartões, 8 px nos botões.
- Tela "Bolsa": painel lateral direito, 420 px de largura, altura até 80% da tela; o personagem fica visível à esquerda.
- Tela "Painel": centralizada, até 1100 × 720 px; dentro do mri_Qadmin, ocupa a área da aba.
- Hierarquia: título → cartão principal → lista → ações.
- Responsividade: legível de 1280 × 720 a 2560 × 1440; abaixo de 1366 px de largura, as tabelas viram listas.

## 6. Estados

| Estado | Apresentação |
|---|---|
| Carregando | esqueleto (blocos cinza pulsando) + botões desabilitados |
| Sucesso | notificação verde + atualização da lista |
| Erro | notificação vermelha com motivo em linguagem simples |
| Vazio | ilustração simples + texto de orientação (ex.: guia de primeiro cadastro) |
| Desabilitado | 40% de opacidade + dica ao passar o mouse |
| Sem conexão com o servidor | faixa amarela "Sem resposta do servidor. Tente novamente." |
| Sem permissão | tela "Você não tem permissão para acessar este painel." e fechamento |

## 7. Experiência no FiveM

- Foco: NUI com cursor só enquanto aberta; **ESC** fecha qualquer tela; fechar sempre libera foco e cancela operação pendente.
- Nunca abrir a tela sem ação do jogador; não deixar NUI invisível capturando o foco (lição do incidente do painel de cargos).
- Durante a troca, controles de movimento bloqueados só pelo tempo da animação.
- Sem laços contínuos na NUI; atualizações só por evento. Imagens leves (sem PNGs de vários MB como os do qs-outfitbag).
- Toda interface e mensagem em português brasileiro (D111).
- Nota de compatibilidade: efeitos de desfoque (*backdrop-filter*) serão evitados ou terão alternativa com fundo sólido, porque há relato de transparência indevida de NUI em placas AMD (PC do dono).

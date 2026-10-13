# Manual de uso — vel_uniformbag

Guia prático para **staff** e **líderes de organização**. Para instalar, veja o `README.md`.

## Quem faz o quê

| Perfil | Como ganha acesso | O que pode fazer |
|---|---|---|
| **Staff** | Grupo do mri_Qadmin com "Gerenciar Bolsas de Uniformes" | Tudo, em todas as organizações. Cria baús de uniformes e teleporta até eles. |
| **Emergência** | ACE `vel_uniformbag.admin` no `server.cfg` | O mesmo da staff (para quando o mri_Qadmin estiver fora do ar). |
| **Líder** | Cargo com "chefe" (`isboss`) na própria organização | Só a própria organização: uniformes, bolsas, alertas, regras dos baús e auditoria. |
| **Jogador** | — | Retira a bolsa no baú da organização e usa a bolsa. |

## Abrir o painel

- **Staff:** comando **`/adminoutfit`** ou **mri_Qadmin → Plugins → Bolsas de Uniformes**.
- **Líder:** no **ponto da sede** da organização (criado na aba Pontos).

O painel lembra a última organização e aba usadas.

## Passo a passo para pôr uma organização para funcionar

1. **Uniformes → Novo uniforme:** dê um nome (ex.: "Farda Operacional") e escolha os cargos que podem usar: uma **lista** de cargos ou uma **faixa** (do cargo X para cima).
2. **Gravar a roupa:** vista a farda no seu personagem e clique em **Gravar masculino** ou **Gravar feminino**. Cada botão só aceita o personagem do modelo certo. O relógio e a pulseira nunca entram na farda.
   - Algum acessório ficou estranho? Na própria versão, clique no acessório para **retirá-lo da farda**.
   - **Vestir para conferir** mostra a farda no seu personagem.
3. **Baús → Criar baú de uniformes** (staff): fique no vestiário, dê um nome, escolha **Feminino** ou **Masculino** e **desenhe a área no chão**:
   - mire no chão e clique em cada canto (ou aperte **E**);
   - a rodinha do mouse muda a altura;
   - **Backspace** desfaz o último canto, **R** recomeça, **Enter** conclui e **Esc** cancela.
4. Pronto: o baú passa a ter **sempre uma bolsa de cada uniforme** daquele sexo (**abastecimento infinito**). Quando alguém retira, outra aparece.

> Já usa os baús do mri_Qbossmenu? Na aba **Baús**, cada baú pode ser marcado como **Só masculino** ou **Só feminino**, ou ser **convertido** em baú de uniformes com área desenhada.

## Como o jogador usa

1. Entra na área do baú de uniformes e aperta **E** (aparece "[E] Guarda-roupas"). Só membros da organização abrem.
2. Retira a bolsa: **uma por vez**. A primeira bolsa do jogador é **grátis**; as próximas custam o valor de `ReplacementPrice` (padrão R$ 3000, banco e depois dinheiro). Devolver a bolsa ao baú da organização libera de novo a retirada grátis.
3. Usa a bolsa no inventário: ela vai para o chão na frente dele e abre a tela da bolsa.
   - **Vestir uniforme:** a roupa que ele está usando vai para um compartimento e ele veste a farda do cargo.
   - **Compartimentos:** vestir de volta uma roupa civil guardada.
4. Para guardar a bolsa, use **Recolher** na bolsa do chão.

Qualquer pessoa pode usar uma bolsa (ex.: roubada). Quando quem usa não tem o cargo autorizado, o uso é **indevido**: a roupa é aplicada, mas gera **alerta** para a organização e entra na auditoria.

## Abas do painel

| Aba | Para quê |
|---|---|
| **Uniformes** | Criar, editar, gravar versões masculina/feminina, retirar acessórios, excluir. Uniforme com bolsas em uso é **desativado** em vez de apagado, para não perder o rastreio. |
| **Bolsas** | Todas as bolsas numeradas da organização, onde estão e o histórico de cada uma. O filtro **Duplicadas** mostra bolsas bloqueadas por suspeita de cópia. |
| **Alertas e logs** | Liga o alerta de uso indevido: ps-dispatch (por tipo de emprego), aviso próprio (por emprego), ou os dois. Também define quanto tempo o ponto fica no mapa e o que vai para o Discord. |
| **Pontos** | Pontos nas sedes onde o líder abre o painel. |
| **Baús** | Baús de uniformes (criar, redesenhar a área, excluir, teleportar) e regras dos baús do mri_Qbossmenu. **Limpar bolsas** tira só as bolsas de uniforme vazias; bolsas que guardam roupa de alguém ficam. |
| **Auditoria** | Tudo o que aconteceu, com filtros por categoria, bolsa e pessoa. |
| **Recuperação** | Devolver uma roupa a um personagem (motivo obrigatório; o jogador confirma). |

## Recuperar roupa

- Se uma troca for interrompida (queda, reinício), o sistema **restaura sozinho** a roupa anterior quando o jogador volta.
- A staff pode criar uma recuperação na aba **Recuperação**. O jogador recebe o aviso e escolhe **Restaurar agora** ou **Restaurar depois**; depois, usa **`/minharoupa`**.

## Dúvidas comuns

- **"O baú não abre":** confira se a pessoa é da organização, se está dentro da área desenhada e se o sexo do personagem bate com o baú.
- **"A bolsa diz Não reconhecida":** bolsa criada fora do sistema (ex.: `/giveitem`). Ela não tem efeito, de propósito.
- **"Apareceu uma marca no pulso":** relógio de pacote de roupas. Ele é retirado da farda automaticamente; se for outro acessório, retire na versão do uniforme.
- **Mudou os cargos da organização?** O baú de uniformes acompanha sozinho (slots = número de cargos).

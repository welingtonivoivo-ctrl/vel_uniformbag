Tutorial do Sistema de Bolsas de Uniformes — pronto para colar no Discord.
Cada bloco entre as linhas "✂️ MENSAGEM X/8" é UMA mensagem (todas abaixo de 2000 caracteres).
Copie só o texto entre as linhas de corte (sem as linhas ✂️).

✂️ ──────────── MENSAGEM 1/8 ────────────

# 👜 Sistema de Bolsas de Uniformes

As organizações (Polícia, Hospital, Mecânica e as próximas) agora entregam a **farda oficial em bolsas**.

**Como funciona, em resumo:**
- A liderança/staff **cadastra o uniforme** de cada cargo e **emite bolsas** para o baú da organização.
- O funcionário **pega a bolsa no baú**, coloca no chão e **veste a farda** em qualquer lugar.
- A roupa que ele estava usando fica **guardada dentro da bolsa** (até 3 roupas).
- Para tirar a farda, é só abrir a bolsa de novo e **vestir a roupa guardada**.

**Importante:**
- A bolsa é um **item de verdade**: pode ser entregue, perdida ou **roubada** — e as roupas guardadas vão junto com ela.
- Qualquer pessoa pode vestir a farda de uma bolsa, **mas** se não for do cargo certo, a polícia recebe um **alerta de uso irregular** com a localização.

⚠️ *O sistema está em fase final de testes. Avisaremos quando estiver liberado na cidade.*

✂️ ──────────── MENSAGEM 2/8 ────────────

## 🎒 Como usar a bolsa (todos os jogadores)

**1. Colocar no chão**
Abra o inventário e **use** o item **"Bolsa de Uniforme"**. O personagem coloca a bolsa no chão e o painel abre.

**2. Escolher a roupa**
- **Vestir uniforme** → veste a farda oficial da bolsa. A roupa atual vai para um compartimento livre.
- **Vestir esta roupa** → veste uma roupa guardada. A roupa que você está usando fica no mesmo compartimento.
- **Passe o mouse** sobre uma roupa para ver uma **prévia** do seu personagem vestido com ela.

**3. Depois de trocar**
O painel fecha e a **bolsa continua no chão**. Para mexer nela de novo, use o **olhinho** (interação) na bolsa:
- **Abrir bolsa de uniforme** → abre o painel de novo.
- **Recolher bolsa** → o personagem pega a bolsa e ela volta para o inventário.

Se você estiver longe, o personagem **caminha até a bolsa** sozinho.

✂️ ──────────── MENSAGEM 3/8 ────────────

## 📌 Regras e cuidados

- **Não esqueça a bolsa no chão!** Qualquer jogador pode recolher uma bolsa esquecida — e leva as roupas que estão dentro. A bolsa **não some sozinha**, nem quando o servidor reinicia.
- **Compartimentos:** cada bolsa guarda até **3 roupas**. Se os 3 estiverem cheios, você ainda pode **trocar** por uma roupa guardada, mas não dá para vestir a farda até liberar um espaço.
- **Nenhuma roupa é apagada** automaticamente.
- **Roupas masculinas e femininas** não se misturam: roupa incompatível com o seu personagem aparece marcada e não pode ser vestida.
- **Não dá para usar a bolsa** estando morto, caído, algemado, dentro de veículo ou na água.
- Se você se **afastar mais de 3 metros**, o painel fecha (a bolsa continua no chão).
- **Bolsas criadas por comando** (fora do sistema) não funcionam.
- **Bolsa duplicada por bug** é bloqueada para análise da staff.

✂️ ──────────── MENSAGEM 4/8 ────────────

## 🚨 Uso irregular de farda (Polícia e organizações)

Quando alguém veste uma farda **sem ter o cargo autorizado** (não é da organização, foi rebaixado, foi demitido…):
- A farda **é vestida normalmente** (o sistema não impede — a situação é resolvida no RP).
- Sai um **alerta de "Uso irregular de farda"** para quem a organização configurou, com o **local no mapa** e o **nome da rua**.
- O alerta pode chegar pelo **ps-dispatch** (para todos os empregos de um tipo, ex.: polícia em serviço) e/ou por **notificação própria** (só para empregos escolhidos, ex.: só a PMESP).
- Cada vez que alguém vestir indevidamente, sai um **novo alerta**.
- Tudo fica registrado na **auditoria** (quem, qual bolsa, quando e onde).

✂️ ──────────── MENSAGEM 5/8 ────────────

## 🛠️ Painel da staff — `/adminoutfit`

Comando **só para a staff** com a permissão **"Gerenciar Bolsas de Uniformes"** (mri_Qadmin → Perms → categoria *Bolsas de Uniformes*).
No topo do painel, escolha a **Organização** (lista os jobs criados no bossmenu).

**Aba Uniformes — cadastrar uma farda:**
1. Clique em **Abrir loja de roupas** (gratuita, só roupas) e monte a farda no seu personagem.
2. Clique em **Novo uniforme** e dê um nome (ex.: *Farda Sargento*).
3. Escolha os cargos:
   - caixinhas = **só os cargos marcados**; ou
   - marque **"Também permitir graduações superiores"** e escolha a graduação **mínima** (e máxima, se quiser).
4. Clique em **Salvar**.
5. Clique em **Usar roupa que estou vestindo** → grava a versão do seu modelo.
6. Para a **versão feminina**, use um personagem feminino vestido com a farda e repita o passo 5.

Você pode **editar**, **desativar** ou **remover versões** a qualquer momento.

✂️ ──────────── MENSAGEM 6/8 ────────────

## 📦 Painel — Emissão e Bolsas

**Aba Emissão:**
1. Escolha o **uniforme** (só aparecem os que têm versão gravada).
2. Escolha a **quantidade** (até 20 por vez).
3. Escolha o **baú** da organização (os baús criados no bossmenu aparecem sozinhos).
4. Clique em **Emitir bolsas**. Cada bolsa recebe um **ID único** (ex.: `UB-7K3QX9MD`).

**Aba Bolsas:**
- Mostra todas as bolsas da organização: **em estoque**, **em circulação**, **no chão**, **desconhecidas** (sem movimento há 30 dias) e **duplicadas**.
- Use o **filtro** e a **busca por ID**.
- **Clique numa bolsa** para ver o **histórico completo** e o que está guardado nos compartimentos.

✂️ ──────────── MENSAGEM 7/8 ────────────

## ⚙️ Painel — Alertas, Auditoria e Recuperação

**Aba Alertas e logs** (por organização):
- Liga/desliga o alerta e escolhe **como chega**: só ps-dispatch, só notificação própria ou os dois.
- **Tipos de emprego** (ps-dispatch) e **empregos específicos** (notificação própria).
- **Só quem estiver em serviço**, **tempo do ponto no mapa**, **código do alerta**, imagem da bolsa e baú padrão.

**Aba Auditoria:**
Tudo o que aconteceu (emissões, trocas, usos irregulares, recuperações…), com filtro por categoria, bolsa e personagem. **Nada é apagado.**

**Aba Recuperação** (só staff):
Para devolver uma roupa **perdida por falha técnica** — **nunca** por roubo ou consequência do RP.
1. Busque o personagem pelo nome ou citizenid.
2. Escolha **qual roupa devolver**.
3. Escreva o **motivo** (obrigatório) e clique em **Registrar recuperação**.

✂️ ──────────── MENSAGEM 8/8 ────────────

## ♻️ Para o jogador que recebeu uma recuperação

Quando a staff registra uma recuperação para você, aparece a janela **"Roupa restaurada pela administração"**:
- **Restaurar agora** → a roupa é aplicada na hora.
- **Restaurar depois** → nada muda agora. Quando quiser, use o comando **`/minharoupa`**.

O aviso também aparece **ao entrar no servidor**, enquanto houver roupa para restaurar.

## 🔜 Em breve
- **Líderes** das organizações vão gerenciar uniformes e bolsas pelos **pontos nas sedes** (olhinho).
- Painel também pela aba **Plugins** do mri_Qadmin.
- **Logs no Discord** por organização.
- Imagens próprias das bolsas de cada organização.

Dúvidas? Chame a staff. 💜

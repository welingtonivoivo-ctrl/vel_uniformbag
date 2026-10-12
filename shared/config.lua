-- Configuração centralizada do vel_uniformbag (TRD §1, D160).
-- Webhooks e ACE NÃO ficam aqui: webhooks em convars privadas
-- (vel_uniformbag_webhook_<org> / _admin) e ACE no server.cfg (D76, D82).

Config = {}

-- Compartimentos de roupa por bolsa (D44, D53)
Config.Slots = 3

-- Distância máxima do objeto temporário antes de cancelar a troca, em metros (D155)
Config.MaxDistance = 3.0

-- Trava da bolsa em segundos, renovada enquanto a interação está ativa (D156)
Config.LockSeconds = 60

-- Máximo de bolsas por lote de emissão (D157)
Config.MaxBagsPerBatch = 20

-- Retirada do baú (D220): uma por vez; 1 retirada grátis por jogador (devolver ao baú devolve a
-- grátis); as demais custam este valor (banco; se faltar, dinheiro).
Config.ReplacementPrice = 3000

-- Duração padrão do ponto do alerta no mapa, em segundos; cada organização pode sobrescrever (D158)
Config.DefaultBlipSeconds = 120

-- Comando para abrir recuperações pendentes do próprio personagem (D159)
Config.RecoveryCommand = 'minharoupa'

-- Dias sem atividade confirmada até a bolsa ser classificada como "Desconhecida/Inativa" (D163)
Config.InactiveDays = 30

-- Intervalo da rotina de inatividade, em horas; também roda ao iniciar o recurso (D165)
Config.InactiveCheckHours = 6

-- Modelos de personagem suportados; outros só por configuração explícita (D68)
Config.SupportedModels = {
    'mp_m_freemode_01',
    'mp_f_freemode_01',
}

-- Item do ox_inventory e modelo do objeto temporário (D117, D96)
Config.ItemName = 'uniform_bag'
Config.PropModel = 'reh_prop_reh_bag_outfit_01a'

-- Imagem padrão da bolsa (D174)
Config.DefaultItemImage = 'uniform_bag'

-- Cor de identidade quando a convar mri:color não estiver definida (D108)
Config.DefaultColor = '#6400E6'

-- Peças de roupa guardadas e aplicadas (IDs de componente do GTA).
-- 0 (rosto) e 2 (cabelo) nunca entram: uma roupa guardada não troca o rosto de quem veste.
Config.ClothingComponents = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
Config.ClothingProps = { 0, 1, 2, 6, 7 }

-- Peças usadas para reconhecer uma farda vestida (D140, D193, D196).
-- Máscara, mochila, colete e emblemas variam no RP e não entram na comparação.
Config.UniformMatchComponents = { 3, 4, 6, 8, 11 }
Config.UniformMatchProps = {}

-- Tamanho máximo aceito para uma aparência enviada pelo cliente, em caracteres JSON
Config.MaxAppearanceSize = 20000

-- Intervalo em que o cliente renova a trava enquanto a bolsa está aberta, em segundos
Config.LockRenewSeconds = 20

-- Animações nativas do GTA (D1, D97)
-- place: soltar a bolsa · idle: mexendo na bolsa enquanto a tela está aberta (D203)
-- change: vestindo a roupa · collect: abaixar e pegar a bolsa de volta (D203)
Config.Animations = {
    place   = { dict = 'random@domestic', clip = 'pickup_low', duration = 1200 },
    idle    = { dict = 'anim@heists@money_grab@duffel', clip = 'loop' },
    change  = { dict = 'clothingshirt', clip = 'try_shirt_positive_d', duration = 2500 },
    collect = { dict = 'random@domestic', clip = 'pickup_low', duration = 1200 },
}

-- Caminhar até a bolsa no chão antes de abrir/recolher (D209)
Config.Approach = {
    stopDistance = 0.7, -- para a esta distância da bolsa, de frente para ela
    timeoutMs = 6000,   -- desiste se não chegar neste tempo
}

-- Prévia da roupa ao passar o mouse (D204): cópia local do personagem, só na tela de quem usa.
-- A cópia aparece na frente da câmera, no lado esquerdo da tela (o painel fica à direita),
-- virada para a câmera, sem encostar no personagem.
Config.Preview = {
    depth = 2.6,   -- metros à frente da câmera
    side = -1.3,   -- metros para o lado (negativo = esquerda da tela)
}

-- Alerta pelo ps-dispatch (D124). O tempo do ponto vem de alert_blip_seconds da organização.
Config.Dispatch = {
    code = '10-31',
    codeName = 'uniformbag',
    icon = 'fas fa-user-secret',
    priority = 1,
    sprite = 366,
    color = 1,
    scale = 1.0,
    radius = 0,
}

-- Mensagens de diagnóstico extras no console
Config.Debug = false

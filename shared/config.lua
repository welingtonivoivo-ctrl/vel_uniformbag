-- Configuração centralizada do street_uniformbag (TRD §1, D160).
-- Webhooks e ACE NÃO ficam aqui: webhooks em convars privadas
-- (street_uniformbag_webhook_<org> / _admin) e ACE no server.cfg (D76, D82).

Config = {}

-- Compartimentos de roupa por bolsa (D44, D53)
Config.Slots = 3

-- Distância máxima do objeto temporário antes de cancelar a troca, em metros (D155)
Config.MaxDistance = 3.0

-- Trava da bolsa em segundos, renovada enquanto a interação está ativa (D156)
Config.LockSeconds = 60

-- Máximo de bolsas por lote de emissão (D157)
Config.MaxBagsPerBatch = 20

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

-- Mensagens de diagnóstico extras no console
Config.Debug = false

-- Textos em português brasileiro (D111). Novos textos entram aqui, nunca fixos no código.

Locale = {
    ['startup.ok']           = 'Recurso iniciado (versão %s).',
    ['startup.dep_ok']       = 'Dependência %s: iniciada (versão %s).',
    ['startup.dep_missing']  = 'Dependência obrigatória %s: %s.',
    ['startup.opt_ok']       = 'Integração opcional %s: iniciada (versão %s).',
    ['startup.opt_missing']  = 'Integração opcional %s: %s (funcionalidade relacionada ficará desativada).',
    ['startup.item_missing'] = 'Item "%s" ainda não cadastrado no ox_inventory (previsto para a etapa 3).',
    ['startup.item_ok']      = 'Item "%s" encontrado no ox_inventory.',
    ['startup.color']        = 'Cor de identidade: %s (%s).',
    ['prop.ok']              = 'Modelo da bolsa "%s" disponível no jogo (cliente %s): em CD image = %s, válido = %s, carregado = %s.',
    ['prop.missing']         = 'Modelo da bolsa "%s" NÃO disponível no jogo (cliente %s): em CD image = %s, válido = %s, carregado = %s.',
}

---@param key string
---@return string
function L(key, ...)
    local text = Locale[key] or key
    if select('#', ...) > 0 then
        return text:format(...)
    end
    return text
end

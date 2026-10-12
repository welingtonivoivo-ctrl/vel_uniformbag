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
    ['db.up_to_date']        = 'Banco: esquema já está na versão %s; nada a criar.',
    ['db.migrated']          = 'Banco: migração para a versão %s aplicada.',
    ['db.tables_ok']         = 'Banco: %s de %s tabelas presentes (esquema versão %s).',
    ['db.missing_tables']    = 'tabelas ausentes após a migração: %s',
    ['db.failed']            = 'Banco: falha na migração — o recurso ficará sem operar até corrigir: %s',
    ['perm.qadmin_absent']   = 'mri_Qadmin não está iniciado: permissão de staff não registrada e acesso de staff negado (falha fechada).',
    ['perm.registered']      = 'Permissão "%s" registrada no editor de grupos do mri_Qadmin.',
    ['perm.register_failed'] = 'Falha ao registrar a permissão no mri_Qadmin: %s',
    ['perm.manage_label']    = 'Gerenciar Bolsas de Uniformes',
    ['perm.manage_desc']     = 'Gerenciar uniformes e bolsas de todas as organizações, emitir bolsas, consultar auditorias e recuperações.',
    ['perm.category_label']  = 'Bolsas de Uniformes',
    ['perm.diag_usage']      = 'Uso: uniformbag_perfil <id do jogador online> [organização]',
    ['perm.diag_result']     = 'Perfil do jogador %s para a organização "%s": %s (emergência=%s, staff=%s, líder=%s; mri_Qadmin=%s; emprego=%s, chefe=%s)',
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

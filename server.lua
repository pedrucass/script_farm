--- feito por altvdopedro


local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

local cfg = module(GetCurrentResourceName(), "config")

-- Checa permissão do jogador para a profissão
function src.checkPermission(profissao)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    local profissaoCfg = cfg.profissoes[profissao]
    if profissaoCfg then
        local permission = profissaoCfg.permission
        return vRP.hasPermission(user_id, permission)
    end

    return false
end

-- Entrega os itens da profissão ao jogador com quantidade aleatória
function src.entregarItens(profissao)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    local profissaoCfg = cfg.profissoes[profissao]
    if not profissaoCfg then
        print("[FARM] Profissão inválida: " .. profissao)
        return
    end

    for _, itemData in pairs(profissaoCfg.itens) do
        local item = itemData.nome
        local minq = itemData.quantidade.min
        local maxq = itemData.quantidade.max
        local quantidade = math.random(minq, maxq)

        -- Remove verificação de peso, pois o sistema usa inventário próprio
        vRP.giveInventoryItem(user_id, item, quantidade)
        TriggerClientEvent("Notify", source, "check", "Você recebeu <b>"..quantidade.."x "..item.."</b>.")
    end
end
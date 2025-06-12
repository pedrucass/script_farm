--- feito por altvdopedro


local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

local cfg = module(GetCurrentResourceName(), "config")

local farmando = false
local pos = 1
local blip = nil
local profissao_atual = nil

-- Thread para detectar início do farm
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)

        if not farmando then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for profissao, dados in pairs(cfg.profissoes) do
                local dist = #(vec3(dados.inicio[1], dados.inicio[2], dados.inicio[3]) - coords)
                if dist <= 10.0 then
                    DrawMarker(27, dados.inicio[1], dados.inicio[2], dados.inicio[3]-0.97, 0,0,0,0,0,0,1.0,1.0,1.0,255,42,29,100,0,0,0,1)

                    if dist <= 2.0 then
                        DrawText3D(dados.inicio[1], dados.inicio[2], dados.inicio[3], "~w~[~r~FARM - "..profissao.."~w~]\nPressione ~g~[E] ~w~para iniciar.")

                        if IsControlJustPressed(0, 38) then
                            local temPermissao = vSERVER.checkPermission(profissao)
                            if temPermissao then
                                farmando = true
                                profissao_atual = profissao
                                pos = 1
                                marcarPonto(dados.rotas[pos])
                                TriggerEvent("Notify", "check", "Você iniciou sua rota, vá até o destino marcado no mini-mapa.")
                            else
                                TriggerEvent("Notify", "vermelho", "Você não possui permissão para realizar essa ação!")
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Thread para execução da rota e coleta
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)

        if farmando and profissao_atual then
            local dados = cfg.profissoes[profissao_atual]
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local destino = dados.rotas[pos]
            local dist = #(vec3(destino[1], destino[2], destino[3]) - coords)

            if dist <= 10.0 then
                DrawMarker(27, destino[1], destino[2], destino[3]-0.97, 0,0,0,0,0,0,1.0,1.0,1.0,255,42,29,100,0,0,0,1)

                if dist <= 2.0 then
                    DrawText3D(destino[1], destino[2], destino[3], "~w~Pressione ~g~[E] ~w~para coletar.")

                    if IsControlJustPressed(0, 38) then
                        -- Animação de coleta
                        RequestAnimDict("amb@world_human_gardener_plant@female@base")
                        while not HasAnimDictLoaded("amb@world_human_gardener_plant@female@base") do
                            Citizen.Wait(10)
                        end
                        TaskPlayAnim(ped, "amb@world_human_gardener_plant@female@base", "base_female", 8.0, -8.0, 3000, 0, 0)

                        -- Pede item pro servidor
                        vSERVER.entregarItens(profissao_atual)

                        -- Próximo ponto da rota
                        pos = pos + 1
                        if pos > #dados.rotas then
                            pos = 1
                        end
                        marcarPonto(dados.rotas[pos])
                    end
                end
            end
        end
    end
end)

-- Thread para parar farmar com F7
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        if farmando then

            drawTxt ("~r~PRESSIONE ~r~F7 ~r~SE DESEJA ~r~FINALIZAR~r~ A ROTA",4,0.500,0.905,0.45,255,255,255,200)
            drawTxt ("~g~VÁ ATÉ O ~g~DESTINO~g~ PARA COLETAR OS ~g~ITENS",4,0.500,0.93,0.45,255,255,255,200)

            if IsControlJustPressed(0, 168) then
                farmando = false
                pos = 1
                profissao_atual = nil
                if blip then
                    RemoveBlip(blip)
                    blip = nil
                end
                TriggerEvent("Notify", "important", "Você finalizou sua rota!")
            end
        end
    end
end)

-- Função para criar blip na rota
function marcarPonto(coords)
    if blip then
        RemoveBlip(blip)
    end
    blip = AddBlipForCoord(coords[1], coords[2], coords[3])
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.7)
    SetBlipAsShortRange(blip, false)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Ponto de coleta")
    EndTextCommandSetBlipName(blip)
end

-- Função para texto 3D
function DrawText3D(x, y, z, text)
    local onScreen,_x,_y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextFont(4)
        SetTextScale(0.5, 0.5)
        SetTextColour(255, 255, 255, 215)
        SetTextCentre(1)
        SetTextDropshadow(1, 1, 1, 1, 255)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Função para texto simples na tela
function drawTxt(text,font,x,y,scale,r,g,b,a)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r,g,b,a)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x,y)
end

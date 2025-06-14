local nuiVisible = true        -- pusula açık
local allHudVisible = true     -- tüm HUD (pusula, radar, hız, player info vs.)
local hudUiVisible = false     -- switch menü açık
local showPlayerInfo = true    -- player bilgileri için kontrol değişkeni
local radarVisible = false     -- radarın görünürlük durumu
local seatbeltOn = false       -- Emniyet kemeri takılı değil
local wasInCar = false         -- Arabadaydı

-- HUD menüsünü aç/kapat
RegisterCommand("hud", function()
    hudUiVisible = not hudUiVisible
    SetNuiFocus(hudUiVisible, hudUiVisible)
    SendNUIMessage({
        type = "toggleUi",
        state = hudUiVisible
    })
end)

-- Menü kapatma (Backspace)
RegisterNUICallback("closeUi", function(_, cb)
    hudUiVisible = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "toggleUi", state = false })
    cb({})
end)

-- HUD switch (tüm göstergeleri kontrol eder)
RegisterNUICallback("toggleHud", function(data, cb)
    allHudVisible = data.enabled
    nuiVisible = data.enabled
    showPlayerInfo = not data.hidePlayerInfo

    SendNUIMessage({
        show = data.enabled,
        showHud = data.enabled
    })

    cb({})
end)

-- Radarın HUD switch ile kapanmasını sağlar
CreateThread(function()
    while true do
        Wait(0)
        DisplayRadar(radarVisible)
    end
end)

-- Araç dışındayken radarı kapat
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        
        if veh ~= 0 and allHudVisible then
            if not radarVisible then
                radarVisible = true
                DisplayRadar(true)
            end
        else
            if radarVisible then
                radarVisible = false
                DisplayRadar(false)
            end
        end
    end
end)

-- Sadece pusulayı aç/kapat
RegisterNUICallback("togglePusula", function(data, cb)
    nuiVisible = data.enabled
    cb({})
end)

-- Saat formatlayıcı
local function getGameTime()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    return string.format("%02d:%02d", hour, minute)
end

-- Pusula yön çevirici
local function getDirectionFromHeading(heading)
    local directions = {
        "K", "KD", "D", "GD", "G", "GB", "B", "KB", "K"
    }
    local index = math.floor((heading + 22.5) / 45.0) + 1
    return directions[index]
end

-- Emniyet kemeri
CreateThread(function()
    while true do
        Wait(0)
        local player = PlayerPedId()
        local veh = GetVehiclePedIsIn(player, false)

        -- Oyuncu araçtayken B tuşuna basınca kemeri tak/çıkar
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == player then
            if IsControlJustReleased(0, 29) then -- B tuşu
                seatbeltOn = not seatbeltOn
                if seatbeltOn then
                    --
                else
                    --
                end
                SendNUIMessage({ seatbelt = seatbeltOn })
            end

            if seatbeltOn then
                DisableControlAction(0, 75, true)  -- Çıkış (F)
                DisableControlAction(27, 75, true) -- Alternatif çıkış
            end

            wasInCar = true
        elseif wasInCar then
            seatbeltOn = false
            SendNUIMessage({ seatbelt = false })
            wasInCar = false
        end
    end
end)

-- HUD: Hız, vites, kemer göstergesi
CreateThread(function()
    while true do
        Wait(200)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if allHudVisible and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local speed = math.floor(GetEntitySpeed(veh) * 3.6)
            local rawGear = GetVehicleCurrentGear(veh)
            local gear = "N"

            if rawGear == 0 then
                gear = "R"
            elseif rawGear == 1 then
                if speed > 5 then
                    gear = "1"
                else
                    gear = "N"
                end
            else
                gear = tostring(rawGear - 1)
            end

            SendNUIMessage({
                showHud = true,
                speed = speed,
                gear = gear,
                seatbeltOn = seatbeltOn,
                playerName = playerName,
                playerId = playerId,
                gameTime = gameTime
            })
        else
            SendNUIMessage({ showHud = false })
        end
    end
end)

-- Pusula ve konum
CreateThread(function()
    while true do
        Wait(500)
        if allHudVisible and nuiVisible then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local zone = GetNameOfZone(coords.x, coords.y, coords.z)
            local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local street = GetStreetNameFromHashKey(streetHash)
            local zoneName = GetLabelText(zone)
            local direction = getDirectionFromHeading(heading)

            SendNUIMessage({
                show = true,
                direction = direction,
                street = street,
                zone = zoneName
            })
        else
            SendNUIMessage({ show = false })
        end
    end
end)

-- Player bilgileri ve saat
CreateThread(function()
    while true do
        Wait(1000)
        if allHudVisible and showPlayerInfo then
            local playerId = GetPlayerServerId(PlayerId())
            local playerName = GetPlayerName(PlayerId())
            local gameTime = getGameTime()

            SendNUIMessage({
                playerName = playerName,
                playerId = playerId,
                gameTime = gameTime,
                showPlayerInfo = true
            })
        else
            SendNUIMessage({ showPlayerInfo = false })
        end
    end
end)

-- GTA'nın kendi HUD öğelerini kapatma
CreateThread(function()
    while true do
        Wait(0)
        if allHudVisible then
            HideHudComponentThisFrame(1) -- Wanted Stars
            HideHudComponentThisFrame(2) -- Weapon Icon
            HideHudComponentThisFrame(3) -- Cash
            HideHudComponentThisFrame(4) -- MP Cash
            HideHudComponentThisFrame(6) -- Vehicle Name
            HideHudComponentThisFrame(7) -- Area Name
            HideHudComponentThisFrame(8) -- Vehicle Class
            HideHudComponentThisFrame(9) -- Street Name
            HideHudComponentThisFrame(13) -- Cash Change
            HideHudComponentThisFrame(14) -- Reticle
            HideHudComponentThisFrame(17) -- Save Game
            HideHudComponentThisFrame(20) -- Weapon Stat
        end
    end
end)

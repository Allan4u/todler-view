local isToddler = false
local TODDLER_HEIGHT_THRESHOLD = 1.3 -- Tinggi (meter) di bawah ini dianggap toddler/anak kecil

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        -- Deteksi Berdasarkan Tinggi (Real-time Automatic Detection)
        -- Mengukur jarak dari kaki (PH_L_Foot/PH_R_Foot) ke kepala (SKEL_Head)
        local headPos = GetPedBoneCoords(playerPed, 31086, 0.0, 0.0, 0.0) -- SKEL_Head
        local footPos = GetEntityCoords(playerPed) -- Dasar kaki
        
        local height = headPos.z - footPos.z

        -- Jika tinggi ped di bawah threshold, anggap toddler
        if height > 0.1 and height < TODDLER_HEIGHT_THRESHOLD then
            if not isToddler then
                isToddler = true
                -- print("Toddler Detected! Height: " .. height)
            end
        else
            if isToddler then
                isToddler = false
                -- print("Adult Detected! Height: " .. height)
            end
        end

        Citizen.Wait(1000) -- Cek setiap 1 detik untuk optimasi
    end
end)

local povCam = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isToddler and GetFollowPedCamViewMode() == 4 then
            local playerPed = PlayerPedId()
            local headPos = GetPedBoneCoords(playerPed, 31086, 0.0, 0.0, 0.0) -- SKEL_Head
            
            if not DoesCamExist(povCam) then
                povCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                SetCamActive(povCam, true)
                RenderScriptCams(true, false, 0, true, true)
                
                -- Memaksa First Person agar tidak glitchy saat transisi
                SetFollowPedCamViewMode(4)
            end

            -- Update posisi kamera tepat di mata
            -- Kita beri sedikit offset Y (maju) agar tidak melihat bagian dalam kepala ped
            local forwardVector = GetEntityForwardVector(playerPed)
            local camPos = headPos + (forwardVector * 0.05)
            
            SetCamCoord(povCam, camPos.x, camPos.y, camPos.z)
            
            -- Rotasi mengikuti pergerakan mouse/gameplay cam
            local gameplayRot = GetGameplayCamRot(2)
            SetCamRot(povCam, gameplayRot.x, gameplayRot.y, gameplayRot.z, 2)
            
            -- Sync heading ped dengan kamera saat bergerak
            if IsControlPressed(0, 32) or IsControlPressed(0, 33) or IsControlPressed(0, 34) or IsControlPressed(0, 35) then
                SetEntityHeading(playerPed, gameplayRot.z)
            end
        else
            if DoesCamExist(povCam) then
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(povCam, false)
                povCam = nil
            end
        end
    end
end)

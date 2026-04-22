local isToddler = false
local TODDLER_HEIGHT_THRESHOLD = 1.3
local povCam = nil

-- Thread 1: Deteksi Real-time Tinggi Karakter
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local headPos = GetPedBoneCoords(playerPed, 31086, 0.0, 0.0, 0.0) -- SKEL_Head
        local footPos = GetEntityCoords(playerPed)
        local height = headPos.z - footPos.z

        if height > 0.1 and height < TODDLER_HEIGHT_THRESHOLD then
            isToddler = true
        else
            isToddler = false
        end
        Citizen.Wait(1000)
    end
end)

-- Thread 2: Logika Kamera (POV & Third Person Adjustment)
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        
        if isToddler then
            sleep = 0
            local playerPed = PlayerPedId()
            local viewMode = GetFollowPedCamViewMode()

            -- 1. First Person (ViewMode 4)
            if viewMode == 4 then
                local headPos = GetPedBoneCoords(playerPed, 31086, 0.0, 0.0, 0.0)
                
                if not DoesCamExist(povCam) then
                    povCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                    SetCamActive(povCam, true)
                    RenderScriptCams(true, false, 0, true, true)
                end

                local forwardVector = GetEntityForwardVector(playerPed)
                local camPos = headPos + (forwardVector * 0.05)
                
                SetCamCoord(povCam, camPos.x, camPos.y, camPos.z)
                local gameplayRot = GetGameplayCamRot(2)
                SetCamRot(povCam, gameplayRot.x, gameplayRot.y, gameplayRot.z, 2)

                -- Sync heading ped saat bergerak
                if IsControlPressed(0, 32) or IsControlPressed(0, 33) or IsControlPressed(0, 34) or IsControlPressed(0, 35) then
                    SetEntityHeading(playerPed, gameplayRot.z)
                end

            -- 2. Third Person Adjustment (ViewMode 0, 1, 2)
            else
                if DoesCamExist(povCam) then
                    RenderScriptCams(false, false, 0, true, true)
                    DestroyCam(povCam, false)
                    povCam = nil
                end

                -- Mengatur tinggi kamera third person agar lebih rendah (sejajar anak kecil)
                -- Kita gunakan offset untuk menurunkan target kamera
                SetGameplayCamRelativeVerticalAngle(0.0, 1.0) 
                
                -- Tips: GTA V secara native akan mengikuti ped, 
                -- tapi kita bisa memaksa FOV sedikit lebih lebar agar terlihat lebih proporsional untuk anak kecil
                if viewMode ~= 4 then
                    -- Kamu bisa tambahkan logika penyesuaian zoom di sini jika perlu
                end
            end

            -- Menangani tombol 'V' (INPUT_NEXT_CAMERA)
            -- Kita pastikan transisi antar mode lancar saat jadi toddler
            if IsControlJustPressed(0, 0) then -- 0 adalah ID untuk tombol V (Next Camera)
                -- Game secara otomatis mengganti ViewMode, thread ini akan mendeteksinya di loop berikutnya
            end
        else
            -- Jika bukan toddler, pastikan semua kamera kembali normal
            if DoesCamExist(povCam) then
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(povCam, false)
                povCam = nil
            end
            sleep = 1000
        end
        
        Citizen.Wait(sleep)
    end
end)

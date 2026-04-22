local isToddler = false
local TODDLER_HEIGHT_THRESHOLD = 1.3
local povCam = nil
local toddlerBoneZOffset = 0.0
local playerId = PlayerId()

Citizen.CreateThread(function()
    local toddlerConfirmCount = 0
    local lastPed = nil
    local smoothBoneOffset = 0.0  

    while true do
        local playerPed = PlayerPedId()
        
        if playerPed ~= lastPed then
            toddlerConfirmCount = 0
            lastPed = playerPed
            smoothBoneOffset = 0.0
        end

        if DoesEntityExist(playerPed) then
            local minDim, maxDim = GetModelDimensions(GetEntityModel(playerPed))
            local modelHeight = maxDim.z - minDim.z

            local headPos = GetPedBoneCoords(playerPed, 31086, 0.0, 0.0, 0.0)
            local footPos = GetPedBoneCoords(playerPed, 14201, 0.0, 0.0, 0.0)
           
            local boneHeight = #(headPos - footPos)

            local isScrunched = IsPedInAnyVehicle(playerPed, false) 
                             or IsPedDucking(playerPed) 
                             or IsPedRagdoll(playerPed) 
                             or IsEntityInWater(playerPed) 
                             or IsPedFalling(playerPed)
                             or GetEntitySpeed(playerPed) > 3.0
            
            local detectedHeight = 99.0 
            
            if (modelHeight > 0.1 and modelHeight < TODDLER_HEIGHT_THRESHOLD) then
                detectedHeight = modelHeight 
            elseif not isScrunched then
                detectedHeight = boneHeight  
            else

            end

            if detectedHeight > 0.1 and detectedHeight < TODDLER_HEIGHT_THRESHOLD then
                toddlerConfirmCount = math.min(toddlerConfirmCount + 1, 3)
            elseif not isScrunched then
                toddlerConfirmCount = math.max(toddlerConfirmCount - 1, 0)
            end

            if toddlerConfirmCount >= 2 then
                isToddler = true
                local boneZ = GetPedBoneCoords(playerPed, 11816, 0.0, 0.0, 0.0).z
                local baseZ = GetEntityCoords(playerPed).z
                local rawOffset = boneZ - baseZ

                if smoothBoneOffset == 0.0 then
                    smoothBoneOffset = rawOffset
                else
                    smoothBoneOffset = smoothBoneOffset + (rawOffset - smoothBoneOffset) * 0.3
                end
                toddlerBoneZOffset = smoothBoneOffset

            elseif toddlerConfirmCount <= 1 then
                isToddler = false
            end
        end
        Citizen.Wait(500)
    end
end)


Citizen.CreateThread(function()
    local math_rad = math.rad
    local math_sin = math.sin
    local math_cos = math.cos
    local math_abs = math.abs

    local lastRot      = { x = 0.0, z = 0.0 }
    local lastViewMode = -1
    local lastPedX, lastPedY, lastPedZ = 0.0, 0.0, 0.0

    local smoothTargetZ  = 0.0
    local smoothTargetZReady = false

    while true do
        local sleep = 500

        if isToddler then
            sleep = 0
            local playerPed = PlayerPedId()

            if IsPlayerFreeAiming(playerId) or IsPedAimingFromCover(playerPed) then
                if povCam then
                    RenderScriptCams(false, false, 0, true, true)
                    DestroyCam(povCam, false)
                    povCam = nil
                    smoothTargetZReady = false
                end
                sleep = 100
            else
                local viewMode = GetFollowPedCamViewMode()

                if viewMode == 4 then
                    if povCam then
                        RenderScriptCams(false, false, 0, true, true)
                        DestroyCam(povCam, false)
                        povCam = nil
                        smoothTargetZReady = false
                    end
                else
                    if not povCam then
                        povCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                        SetCamActive(povCam, true)
                        RenderScriptCams(true, false, 0, true, true)
                        lastViewMode = -1
                        smoothTargetZReady = false
                        local c = GetEntityCoords(playerPed)
                        lastPedX, lastPedY, lastPedZ = c.x, c.y, c.z
                    end

                    local rot     = GetGameplayCamRot(2)
                    local pCoords = GetEntityCoords(playerPed)

                    -- [FIX] Hitung targetZ dulu, lalu smooth HANYA Z-nya
                    local rawTargetZ = pCoords.z + toddlerBoneZOffset + 0.4

                    if not smoothTargetZReady then
                        smoothTargetZ = rawTargetZ
                        smoothTargetZReady = true
                    else
                        smoothTargetZ = smoothTargetZ + (rawTargetZ - smoothTargetZ) * 0.15
                    end

                    local rotChanged  = math_abs(rot.x - lastRot.x) > 0.05
                                     or math_abs(rot.z - lastRot.z) > 0.05
                    local viewChanged = viewMode ~= lastViewMode
                    local dx = pCoords.x - lastPedX
                    local dy = pCoords.y - lastPedY
                    local dz = pCoords.z - lastPedZ
                    local pedMoved = (dx*dx + dy*dy + dz*dz) > 0.0001

                    local zChanged = math_abs(smoothTargetZ - (lastPedZ + toddlerBoneZOffset + 0.4)) > 0.001

                    if rotChanged or viewChanged or pedMoved or zChanged then
                        lastRot.x    = rot.x
                        lastRot.z    = rot.z
                        lastViewMode = viewMode
                        lastPedX     = pCoords.x
                        lastPedY     = pCoords.y
                        lastPedZ     = pCoords.z

                        local radX = math_rad(rot.x)
                        local radZ = math_rad(rot.z)
                        local cosX = math_cos(radX)

                        local dirX = -math_sin(radZ) * cosX
                        local dirY =  math_cos(radZ) * cosX
                        local dirZ =  math_sin(radX)

                        local targetX = pCoords.x
                        local targetY = pCoords.y
                        local targetZ = smoothTargetZ

                        local maxDist = 2.0
                        if viewMode == 1 then maxDist = 3.5
                        elseif viewMode == 2 then maxDist = 5.0 end

                        local camPosX = targetX - (dirX * maxDist)
                        local camPosY = targetY - (dirY * maxDist)
                        local camPosZ = targetZ - (dirZ * maxDist)

                        local ray = StartShapeTestRay(
                            targetX, targetY, targetZ,
                            camPosX, camPosY, camPosZ,
                            1, playerPed, 0
                        )
                        local _, hit, endCoords = GetShapeTestResult(ray)

                        if hit == 1 then
                            camPosX = endCoords.x + (dirX * 0.2)
                            camPosY = endCoords.y + (dirY * 0.2)
                            camPosZ = endCoords.z + (dirZ * 0.2)
                        end

                        SetCamCoord(povCam, camPosX, camPosY, camPosZ)
                        SetCamRot(povCam, rot.x, 0.0, rot.z, 2)
                        SetCamFov(povCam, GetGameplayCamFov())
                    end
                end
            end
        else
            if povCam then
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(povCam, false)
                povCam = nil
            end
            smoothTargetZReady = false
            sleep = 1000
        end

        Citizen.Wait(sleep)
    end
end)
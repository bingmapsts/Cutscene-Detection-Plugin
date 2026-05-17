local interval = 0.2
local timeLeft = interval
local shouldRotateInMenu = true
local aimMethod = 1
local oldIsInCutscene = false
local pitchSetCounter = 0
local lastPitch = nil
local isRotationOffsetSet = false
local rotationOffset = UEVR_Vector3f.new()
local settings = json.load_file('CutsceneAndMenuDetection.json') or {}

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	timeLeft = timeLeft - delta

	if timeLeft > 0 then
		return
	end

	timeLeft = interval
	local playerController = uevr.api:get_player_controller(0)

	if not playerController then
		return
	end

	if not playerController.AcknowledgedPawn then
		handleCutscene(true)
		return
	end

	local isInCutscene = isCutsceneCamera(playerController)
	local isInMenu = isMenuOpened(playerController)

	handleCutscene(isInCutscene or isInMenu, isInMenu, playerController)
end)

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state.Gamepad.wButtons & XINPUT_GAMEPAD_START ~= 0 and
		state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0 and
		state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0 then
		uevr.params.vr.get_rotation_offset(rotationOffset)
		isRotationOffsetSet = true
    end
end)

function isCutsceneCamera(playerController)
	if playerController.PlayerCameraManager and
	    playerController.PlayerCameraManager.ViewTarget and
	    playerController.PlayerCameraManager.ViewTarget.Target then
			local className = tostring(playerController.PlayerCameraManager.ViewTarget.Target:get_class():get_fname())
			return string.find(className, 'CameraActor') or string.find(className, 'CineCam')
   end

   return false
end

function isAnyPropertyTrue(object, dictionary)
	if not object then
		return false
	end

	for key,value in pairs(dictionary) do
		if key == 'properties' then
			if isAnyPropertyTrue(object, value) then
				return true
			end
		elseif type(value) == 'table' then
			if isAnyPropertyTrue(object[key], value) then
				return true
			end
		elseif object[value] then
			return true
		end
	end

	return false
end

function isMenuOpened(playerController)
	return settings.menu and settings.menu.playerController and isAnyPropertyTrue(playerController, settings.menu.playerController)
end

function handleCutscene(isInCutscene, isInMenu, playerController)
	if oldIsInCutscene == isInCutscene then
		if isInMenu and settings.menu.forcePitchToZero and pitchSetCounter < 2 then
			setPitch(playerController)
		end

		return
	end

	oldIsInCutscene = isInCutscene

	if isInCutscene then
		if not isInMenu then
			UEVR_UObjectHook.set_disabled(true)
			uevr.params.vr.set_decoupled_pitch_enabled(false)
		end

		uevr.params.vr.set_aim_method(0)

		if not isInMenu or shouldRotateInMenu then
			if isRotationOffsetSet then
				uevr.params.vr.set_rotation_offset(rotationOffset)
			else
				uevr.params.vr.recenter_view()
			end
		end

		if isInMenu and settings.menu.forcePitchToZero then
			lastPitch = nil
			pitchSetCounter = 0
			setPitch(playerController)
		end
	else
		UEVR_UObjectHook.set_disabled(false)
		uevr.params.vr.set_aim_method(aimMethod)
		uevr.params.vr.set_decoupled_pitch_enabled(true)
	end
end

function setPitch(playerController)
	if playerController.PlayerCameraManager and
		playerController.PlayerCameraManager.ViewTarget then
		local pov = playerController.PlayerCameraManager.ViewTarget.POV

		if pov and (pov.Rotation.Pitch < -5 or pov.Rotation.Pitch > 5) then
			if lastPitch ~= nil and math.abs(lastPitch - pov.Rotation.Pitch) < 1 then
				pitchSetCounter = pitchSetCounter + 1
				local rotation = playerController:GetControlRotation()
				rotation.Pitch = 0

				playerController:SetControlRotation(rotation)
			else
				lastPitch = pov.Rotation.Pitch
			end
		end
	end
end

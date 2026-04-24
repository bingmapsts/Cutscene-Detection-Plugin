local interval = 0.2
local timeLeft = interval
local shouldRotateInMenu = true
local originalAimMethod = 1
local oldIsInCutscene = false
local isRotationOffsetSet = false
local rotationOffset = UEVR_Vector3f.new()
local settings = json.load_file('CutsceneDetection.json') or {}

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

	local isInCutscene = isCutsceneCamera(playerController)
	local isInMenu = isMenuOpened(playerController)

	handleCutscene(isCutsceneCamera(playerController) or isInMenu, isInMenu)
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
			local className = tostring(playerController.PlayerCameraManager.ViewTarget.Target:get_fname())
			return string.find(className, 'CameraActor') or string.find(className, 'CineCam')
   end

   return false
end

function isMenuOpened(playerController)
	if settings.PlayerControllerProperties then
		for i = 1, #settings.PlayerControllerProperties do
			local item = settings.PlayerControllerProperties[i]

			if playerController[item] then
				return true
			end
		end
	end

	if settings.PlayerControllerSubclasses then
		for key,value in pairs(settings.PlayerControllerSubclasses) do
			if playerController[key] then
				for j = 1, #value do
					if playerController[key][value[j]] then
						return true
					end
				end
			end
		end
	end

	return false
end

function handleCutscene(isInCutscene, isInMenu)
	if oldIsInCutscene == isInCutscene then
		return
	end

	oldIsInCutscene = isInCutscene

	if isInCutscene then
		if not isInMenu then
			UEVR_UObjectHook.set_disabled(true)
			uevr.params.vr.set_decoupled_pitch_enabled(false)
		end

		originalAimMethod = uevr.params.vr.get_aim_method()
		uevr.params.vr.set_aim_method(0)

		if not isInMenu or shouldRotateInMenu then
			if isRotationOffsetSet then
				uevr.params.vr.set_rotation_offset(rotationOffset)
			else
				uevr.params.vr.recenter_view()
			end
		end
	else
		UEVR_UObjectHook.set_disabled(false)
		uevr.params.vr.set_aim_method(originalAimMethod)
		uevr.params.vr.set_decoupled_pitch_enabled(true)
	end
end
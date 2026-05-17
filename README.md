The plugin/script does the following during a cutscene:
1) Disables ObjectHook
2) Sets Aim to Game
3) Disables decoupled pitch

The plugin/script sets Aim to Game when a menu is opened. Menu flags need to be setuped for each game separetly in CutsceneAndMenuDetection.json file.  


How to use:
1) Download & copy CutsceneDetection.lua file to
```
%AppData%\UnrealVRMod\{GAME_EXE_NAME}\scripts
```
2) If the data folder contains a folder with name of a game then download & copy CutsceneAndMenuDetection.json to
```
%AppData%\UnrealVRMod\{GAME_EXE_NAME}\data
```
3) You can setup front position for cutscenes by simultaneously pressing:  
Start (Menu) + Left Bumper (LB) + Right Bumper (RB)  
The script will rotate the screen to this position during a cutscene. This is usefull when you move your head and a cutscene suddenly appears. Otherway, the script will recenter the view.  
You can change this combination in on_xinput_get_state. All buttons are here: https://docs.uevr.io/plugins/lua/thirdparty/XInput.html
4) You can disable menu rotation by changing  
shouldRotateInMenu = true  
to  
shouldRotateInMenu = false  
It only happens if there is CutsceneDetection.json file for a game.
5) You can remove manipulation with decoupled pitch by removing the following lines:  
uevr.params.vr.set_decoupled_pitch_enabled(false)  
uevr.params.vr.set_decoupled_pitch_enabled(true)
6) You can change the aiming method by changing  
aimMethod = 1  
to any value:  
GAME = 0  
HEAD = 1  
RIGHT_CONTROLLER = 2  
LEFT_CONTROLLER = 3  
TWO_HANDED_RIGHT = 4  
TWO_HANDED_LEFT = 5  


{GAME_EXE_NAME} is a name of an executable file of a game.

The video proof:  
https://www.youtube.com/watch?v=4ryPbnoErYg  
_recorded with the old version in dll file_

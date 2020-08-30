local gameModeManager = {}

function RegisterGameMode(name, mode)
    gameModeManager[name] = mode
end

function SetCurrentGameMode(name, sharedState, shouldInit)
    if currentMode ~= nil then
        currentMode:TransitionOut()
    end

    currentMode = gameModeManager[name]
    if currentMode == nil then
        print("INVALID MODE NAME: "..name)
    end

    currentMode:TransitionIn()

    globalState.mode = currentMode.modeName
    currentMode:SetExternalState(globalState, sharedState)
    if shouldInit ~= nil and shouldInit == true then
        currentMode:Init()
    end
end

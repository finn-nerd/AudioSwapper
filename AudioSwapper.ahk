; =========================
; Config
; =========================
IniFile := A_ScriptDir "\settings.ini"
SoundExe := "Dependencies\SoundVolumeView.exe"
global Dev1, Dev2, Nick1, Nick2, SwapHotkey, toggle


; =========================
; Tray
; =========================
Menu, Tray, Tip, Audio Swapper
Menu, Tray, Icon, Dependencies\icon.ico
Menu, Tray, Click, 1   ; left click

OnMessage(0x404, "TrayClick") ; tray notify


; =========================
; Load settings
; =========================
IniRead, Dev1, %IniFile%, Audio, Device1
IniRead, Dev2, %IniFile%, Audio, Device2
IniRead, Nick1, %IniFile%, Audio, Nick1, Device 1
IniRead, Nick2, %IniFile%, Audio, Nick2, Device 2
IniRead, SwapHotkey, %IniFile%, Hotkeys, Swap, F14

toggle := false


; =========================
; Hotkey
; =========================

; Assign hotkey to SwapAudio routine
if (SwapHotkey != "")
    Hotkey, %SwapHotkey%, SwapAudio, On

SwapAudio() {
    desired := !toggle ; what we want to try
    target := desired ? Dev1 : Dev2 ; device to swap to
    nickname := desired ? Nick1 : Nick2

    result := SetDevice(target)

    if (result == 0) {
        toggle := desired ; commit on success
    }

    if (result == 2) { ; device is already set
        target := !desired ? Dev1 : Dev2 ; flip desired device
        nickname := !desired ? Nick1 : Nick2
        result := SetDevice(target) ; attempt to swap again
        if (result == 0)
            toggle := !desired
    }

    ; Otherwise leave toggle unchanged (result == 1)
    ; Device was not found, so we will keep attempting that device

    ; Show tooltip based on result
    ShowSwapTooltip(result, nickname)
}


; =========================
; Functions
; =========================
SetDevice(device) {
    global SoundExe
    devices := GetAudioDevices()

    ; Check that desired device exists
    found := false
    for _, d in devices {
        if (d = device) {
            found := true
            break
        }
    }
    if (!found)
        return 1 ; device not found

    ; Check if the requested device is already set and in use
    currDevices := GetCurrentDevices()
    alreadySet := true
    for i, d in currDevices {
        d := Trim(d, "`r`n")  ; remove trailing newline and carriage return
        found := InStr(d, device) > 0
        if !found
            alreadySet := false
    }
    if (alreadySet)
        return 2

    ; Otherwise, set new default devices
    Run, %SoundExe% /SetDefault "%device%" 1,, Hide
    Run, %SoundExe% /SetDefault "%device%" 2,, Hide

    return 0
}

GetCurrentDevices() {
    tempFile := A_Temp "\audio.txt"
    RunWait, %ComSpec% /C "Dependencies\GetDefaultAudio.exe > ""%tempFile%""", , Hide
    FileRead, output, %tempFile%
    lines := StrSplit(output, "`n")
    devices := []
    for i, d in lines {
        d := Trim(d, "`r`n")
        if (d != "")  ; skip empty lines
            devices.Push(d)
    }
    return devices
}

ShowSwapTooltip(result, device) {
    SetTimer, RemoveToolTip, Off ; kill any existing tooltip

    if (result == 0) ; successful set
        ToolTip, Audio → %device%
    else if (result == 1) ; other device not found
        ToolTip, Device %device% was not found
    else if (result == 2) ; current device was already set
        ToolTip, Device %device% is already set
    
    SetTimer, RemoveToolTip, -1500
}

HotkeyToHuman(hk) {
    mods := ""
    key := hk

    ; Remove modifiers from the key string and accumulate human-readable text
    if InStr(key, "^") {
        mods .= "Ctrl + "
        StringReplace, key, key, ^,, All
    }
    if InStr(key, "!") {
        mods .= "Alt + "
        StringReplace, key, key, !,, All
    }
    if InStr(key, "+") {
        mods .= "Shift + "
        StringReplace, key, key, +,, All
    }
    if InStr(key, "#") {
        mods .= "Win + "
        StringReplace, key, key, #,, All
    }

    ; Convert remaining key to uppercase
    StringUpper, key, key

    return mods key
}

TrayClick(wParam, lParam) {
    if (lParam = 0x202) ; WM_LBUTTONUP
        ShowSettingsGui()
}

RemoveToolTip:
    ToolTip
return


; =========================
; Settings GUI
; =========================
ShowSettingsGui() {
    ; Disable hotkey
    global SwapHotkey
    if (SwapHotkey != "")
        Hotkey, %SwapHotkey%, SwapAudio, Off

    global Dev1, Dev2, Nick1, Nick2, SwapHotkey, HotkeyDisplay

    devices := GetAudioDevices()
    list := ""
    for i, d in devices
        list .= d "|"

    ; Device 1
    Gui, Settings:New, +AlwaysOnTop
    Gui, Add, Text,, Device 1
    Gui, Add, DropDownList, vDev1 w320, %list%
    Gui, Add, Edit, vNick1 w320, %Nick1%

    ; Device 2
    Gui, Add, Text,, Device 2
    Gui, Add, DropDownList, vDev2 w320, %list%
    Gui, Add, Edit, vNick2 w320, %Nick2%

    ; Hotkey display
    Gui, Add, Text, vHotkeyDisplay w200, % "Hotkey`n(Current: " HotkeyToHuman(SwapHotkey) ")"
    Gui, Add, Hotkey, vNewHotkey w200

    Gui, Add, Button, gSaveSettings w80, Save
    Gui, Show,, Audio Swapper

    ; Set the drop-down selections
    GuiControl, ChooseString, Dev1, %Dev1%
    GuiControl, ChooseString, Dev2, %Dev2%
    GuiControl,, HotkeyDisplay, % "Hotkey`n(Current: " HotkeyToHuman(SwapHotkey) ")"
}

SaveSettings:
    Gui, Submit

    IniWrite, %Dev1%, %IniFile%, Audio, Device1
    IniWrite, %Dev2%, %IniFile%, Audio, Device2
    IniWrite, %Nick1%, %IniFile%, Audio, Nick1
    IniWrite, %Nick2%, %IniFile%, Audio, Nick2

    if (SwapHotkey != "") ; turn off old hotkey
        Hotkey, %SwapHotkey%, SwapAudio, Off
    if (NewHotkey != "" && NewHotkey != "None") { ; set new hotkey
        SwapHotkey := NewHotkey
        IniWrite, %SwapHotkey%, %IniFile%, Hotkeys, Swap
    }
    if (SwapHotkey != "") ; re-enable hotkey
        Hotkey, %SwapHotkey%, SwapAudio, On

    Gui, Hide
return

SettingsGuiClose:
    if (SwapHotkey != "")
        Hotkey, %SwapHotkey%, SwapAudio, On
    Gui, Hide
return


; =========================
; Device collection
; =========================
GetAudioDevices() {
    global SoundExe
    tmp := A_Temp "\devices.txt"
    list := ""

    RunWait, %ComSpec% /c %SoundExe% /stab "%tmp%", , Hide

    Loop, Read, %tmp%
    {
        if (A_Index = 1)
            continue

        cols := StrSplit(A_LoopReadLine, A_Tab)

        if (cols[2] = "Device" && cols[3] = "Render") {
            name := Trim(cols[4])
            list .= name "|"
        }
    }

    ; DEDUPE HERE
    Sort, list, U D|

    ; Convert back to array
    devices := []
    for _, name in StrSplit(list, "|")
        if (name != "")
            devices.Push(name)

    return devices
}

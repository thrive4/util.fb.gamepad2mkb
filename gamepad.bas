' simulate windows mouse and keyboard with windows os api
' SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS 
'0 disable joystick & gamecontroller input events when the application is in the background
'1 enable joystick & gamecontroller input events when the application is in the background
'default joystick (and gamecontroller) events are not enabled when the application is in the background.

' init gamepad
Dim As SDL_GameController Ptr controller = NULL
dim runningamepad    as boolean = false
dim buttondowntime   as long
dim buttonuptime     as long
dim runningamepademu as boolean = false

' load gamepad
controller = SDL_GameControllerOpen(0)
If (controller = NULL) Then
    logentry("warning", "unable to open gamepad - sdl error: " & *SDL_GetError())
else
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1")
    logentry("notice", "gamepad detected " & *SDL_GameControllerName(controller))
end if

' possible fix for unrecognized gamepad https://github.com/gabomdq/SDL_GameControllerDB
'SDL_GameControllerAddMappingsFromFile("gamecontrollerdb.txt")
Dim As ZString Ptr map = SDL_GameControllerMapping(controller)

' for debug
'Print *SDL_GameControllerName(controller)
'print *map
'sleep 3000

'simulate a key press gamepademu for games and apps windows only regardless of active or focused window
' via https://www.freebasic.net/forum/viewtopic.php?p=38761&hilit=SendInput#p38761 by MichaelW
Sub sendkeyb(bVk As Byte, btstate as boolean)

    if bvk <> 0 then
        dim ki(0 to 1) as INPUT_
        ki(0).type          = INPUT_KEYBOARD
        ki(0).ki.dwFlags    = 1
        ki(1).ki.dwFlags    = KEYEVENTF_KEYUP
        ' special case for directional keys, they do not work with keybd_event
        select case bVk
            case 27
                ki(0).ki.wVk        = VK_LEFT
                ki(1).ki.wVk        = VK_LEFT
            case 26
                ki(0).ki.wVk        = VK_RIGHT
                ki(1).ki.wVk        = VK_RIGHT
            case 24
                ki(0).ki.wVk        = VK_UP
                ki(1).ki.wVk        = VK_UP
            case 25
                ki(0).ki.wVk        = VK_DOWN
                ki(1).ki.wVk        = VK_DOWN
            case 16 ' faux escape sendinput has issues with escape (ascii 27)
                if btstate then
                    keybd_event(0, MapVirtualKey(VK_ESCAPE, 0), KEYEVENTF_SCANCODE, 0)
                else
                    keybd_event(0, MapVirtualKey(VK_ESCAPE, 0), KEYEVENTF_SCANCODE Or KEYEVENTF_KEYUP, 0)
                end if    
                exit sub
            case else
                if btstate then
                    keybd_event(0, MapVirtualKey(bVk, 0), KEYEVENTF_SCANCODE, 0)
                else
                    keybd_event(0, MapVirtualKey(bVk, 0), KEYEVENTF_SCANCODE Or KEYEVENTF_KEYUP, 0)
                end if    
                exit sub
        end select
        SendInput(2, @ki(0), sizeof(ki))
    end if

End Sub

' bind buttons to main loop
function buttoninput(button as integer, event as SDL_Event) as boolean
    select case as const button
        ' buttons
        'SDL_CONTROLLER_BUTTON_INVALID = -1
        case SDL_CONTROLLER_BUTTON_A
            ' simulate key event with sdl only works within running proces
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_RETURN
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_B
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_M
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_X
            'nop    
        case SDL_CONTROLLER_BUTTON_Y
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_BACKSPACE
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_BACK
            'event.type = SDL_KEYDOWN
            'event.key.keysym.sym = SDLK_ESCAPE
            'SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_GUIDE
            'event.type = SDL_KEYDOWN
            'event.key.keysym.sym = SDLK_TAB
            'SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_START
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_M
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_LEFTSTICK
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_COMMA
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_RIGHTSTICK
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_PERIOD
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_RIGHTSHOULDER
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_END
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_LEFTSHOULDER
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_HOME
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_DPAD_UP
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_UP
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_DPAD_DOWN
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_DOWN
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_DPAD_LEFT
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_LEFT
            SDL_PushEvent(@event)
        case SDL_CONTROLLER_BUTTON_DPAD_RIGHT
            event.type = SDL_KEYDOWN
            event.key.keysym.sym = SDLK_RIGHT
            SDL_PushEvent(@event)
    end select
    return true
end function

' init gamepad emu
Dim lsx         As Single
Dim lsy         As Single
Dim rsx         As Single
Dim rsy         As Single
Dim cnt         As Integer

' init mouse
type mouseinit
    deadzone    as single = 0.20
    mouseacc    as single = 0.10
    mouseaccx   as single = 0
    mouseaccy   as single = 0
    vpoint      as Point
end type
dim axis2mouse as mouseinit

type mapaxis2key
    axissta(1 to 8) as boolean
    axisdir(1 to 8) as boolean
    axislab(1 to 8) as string
    axisbtt(1 to 8) as string
    axisval(1 to 8) as byte
end type
dim gpmapaxis2key as mapaxis2key

with gpmapaxis2key
    .axisbtt(1) = "lstick_right_2key"
    .axisdir(1) = false
    .axisbtt(2) = "lstick_left_2key"
    .axisdir(2) = false
    .axisdir(2) = false
    .axisbtt(3) = "lstick_up_2key"
    .axisbtt(4) = "lstick_down_2key"
    .axisdir(4) = false
    .axisbtt(5) = "rstick_right_2key"
    .axisdir(5) = false
    .axisbtt(6) = "rstick_left_2key"
    .axisdir(6) = false
    .axisbtt(7) = "rstick_up_2key"
    .axisdir(7) = false
    .axisbtt(8) = "rstick_down_2key"
    .axisdir(8) = false
end with

' ghetto button and function mapping
type mapo
    bt(0 to 2047)       as string
    lb(0 to 2047)       as string
    vl(0 to 2047)       as ubyte
    mapversion          as integer = 1.0
    settimerduration    as long    = 1.5
    settimeron          as string  = "btback"
    axl2mouse           as boolean = false
    axr2mouse           as boolean = false
    deadzone            as single  = 0.20
    showbuttonpress     as boolean = false
end type
dim gpmap as mapo

' init map to readable generic button name
gpmap.bt(SDL_CONTROLLER_BUTTON_A)               = "bta"
gpmap.bt(SDL_CONTROLLER_BUTTON_B)               = "btb"
gpmap.bt(SDL_CONTROLLER_BUTTON_X)               = "btx"
gpmap.bt(SDL_CONTROLLER_BUTTON_Y)               = "bty"
gpmap.bt(SDL_CONTROLLER_BUTTON_BACK)            = "btback"
gpmap.bt(SDL_CONTROLLER_BUTTON_GUIDE)           = "btguide"
gpmap.bt(SDL_CONTROLLER_BUTTON_START)           = "btstart"
gpmap.bt(SDL_CONTROLLER_BUTTON_LEFTSTICK)       = "btlstick"
gpmap.bt(SDL_CONTROLLER_BUTTON_RIGHTSTICK)      = "btrstick"
gpmap.bt(SDL_CONTROLLER_BUTTON_LEFTSHOULDER)    = "btlshoulder"
gpmap.bt(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER)   = "btrshoulder"
gpmap.bt(SDL_CONTROLLER_AXIS_TRIGGERLEFT + 100) = "btrtrigger"
gpmap.bt(SDL_CONTROLLER_AXIS_TRIGGERRIGHT+ 100) = "btltrigger"
gpmap.bt(SDL_CONTROLLER_BUTTON_DPAD_UP)         = "btdpup"
gpmap.bt(SDL_CONTROLLER_BUTTON_DPAD_DOWN)       = "btdpdown"
gpmap.bt(SDL_CONTROLLER_BUTTON_DPAD_LEFT)       = "btdpleft"
gpmap.bt(SDL_CONTROLLER_BUTTON_DPAD_RIGHT)      = "btdpright"

' todo needs better handling of key codes
function convertbutton(sim as string) as integer
    dim dummy as string
    select case true
        case instr(sim, "key up") > 0
            return 24
        case instr(sim, "key down") > 0
            return 25
        case instr(sim, "key right") > 0
            return 26
        case instr(sim, "key left") > 0
            return 27
        case instr(sim, "key space") > 0
            return 32
        case instr(sim, "key escape") > 0
            return 16 ' faux escape
        case instr(sim, "key return") > 0
            return 13
        case instr(sim, "key") > 0
            dummy = mid(sim, instr(sim, "key") + 4)
            return asc(ucase(dummy))
        case instr(sim, "mouse left") > 0
            dummy = mid(sim, instr(sim, "key") + 4)
            return asc(dummy)
        case instr(sim, "mouse right") > 0
            dummy = mid(sim, instr(sim, "key") + 4)
            return asc(dummy)
    end select
    return 0
end function

' get mappings gamepad to mouse keyboard from .mke file
function getgamepadini(inifile as string, byref gpmap as mapo, byref gpmapaxis2key as mapaxis2key) as boolean
    ' init app by overwrite by commandline or config file .ini
    dim itm     as string
    dim inikey  as string
    dim inival  as string
    dim f       as integer
    if FileExists(inifile) = false then
        logentry("error", inifile + "file does not excist")
    else 
        f = readfromfile(inifile)
        Do Until EOF(f)
            Line Input #f, itm
            if instr(1, itm, "=") > 1 then
                inikey = trim(mid(itm, 1, instr(1, itm, "=") - 2))
                inival = trim(mid(itm, instr(1, itm, "=") + 2, len(itm)))
                if inival <> "" then
                    select case inikey
                        case "mapversion"
                            gpmap.mapversion = val(inival)
                        case "settimerduration"
                            gpmap.settimerduration = val(inival)
                        case "settimeron"
                            gpmap.settimeron = inival
                        case "deadzone"
                            gpmap.deadzone = csng(inival)
                        case "lstick_left_2key"
                            gpmapaxis2key.axislab(1) = inival
                            gpmapaxis2key.axisval(1) = convertbutton(inival)
                        case "lstick_right_2key"
                            gpmapaxis2key.axislab(2) = inival
                            gpmapaxis2key.axisval(2) = convertbutton(inival)
                        case "lstick_up_2key"
                            gpmapaxis2key.axislab(3) = inival
                            gpmapaxis2key.axisval(3) = convertbutton(inival)
                        case "lstick_down_2key"
                            gpmapaxis2key.axislab(4) = inival
                            gpmapaxis2key.axisval(4) = convertbutton(inival)
                        case "rstick_left_2key"
                            gpmapaxis2key.axislab(5) = inival
                            gpmapaxis2key.axisval(5) = convertbutton(inival)
                        case "rstick_right_2key"
                            gpmapaxis2key.axislab(6) = inival
                            gpmapaxis2key.axisval(6) = convertbutton(inival)
                        case "rstick_up_2key"
                            gpmapaxis2key.axislab(7) = inival
                            gpmapaxis2key.axisval(7) = convertbutton(inival)
                        case "rstick_down_2key"
                            gpmapaxis2key.axislab(8) = inival
                            gpmapaxis2key.axisval(8) = convertbutton(inival)
                        case "lstick2mouse"
                            gpmap.axl2mouse = cbool(inival)
                        case "rstick2mouse"
                            gpmap.axr2mouse = cbool(inival)
                        case "SDL_CONTROLLER_BUTTON_A"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_A) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_A) = inival
                        case "SDL_CONTROLLER_BUTTON_B"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_B) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_B) = inival
                        case "SDL_CONTROLLER_BUTTON_X"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_X) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_X) = inival
                        case "SDL_CONTROLLER_BUTTON_Y"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_Y) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_Y) = inival
                        case "SDL_CONTROLLER_BUTTON_BACK"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_BACK) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_BACK) = inival
                        case "SDL_CONTROLLER_BUTTON_GUIDE"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_GUIDE) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_GUIDE) = inival
                        case "SDL_CONTROLLER_BUTTON_START"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_START) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_START) = inival
                        case "SDL_CONTROLLER_BUTTON_LEFTSTICK"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_LEFTSTICK) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_LEFTSTICK) = inival
                        case "SDL_CONTROLLER_BUTTON_RIGHTSTICK"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_RIGHTSTICK) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_RIGHTSTICK) = inival
                        case "SDL_CONTROLLER_BUTTON_LEFTSHOULDER"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_LEFTSHOULDER) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_LEFTSHOULDER) = inival
                        case "SDL_CONTROLLER_BUTTON_RIGHTSHOULDER"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER) = inival
                        case "SDL_CONTROLLER_AXIS_TRIGGERLEFT"
                            gpmap.vl(SDL_CONTROLLER_AXIS_TRIGGERLEFT + 100) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_AXIS_TRIGGERLEFT + 100) = inival
                        case "SDL_CONTROLLER_AXIS_TRIGGERRIGHT"
                            gpmap.vl(SDL_CONTROLLER_AXIS_TRIGGERRIGHT + 100) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_AXIS_TRIGGERRIGHT + 100) = inival
                        case "SDL_CONTROLLER_BUTTON_DPAD_UP"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_DPAD_UP) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_DPAD_UP) = inival
                        case "SDL_CONTROLLER_BUTTON_DPAD_DOWN"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_DPAD_DOWN) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_DPAD_DOWN) = inival
                        case "SDL_CONTROLLER_BUTTON_DPAD_LEFT"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_DPAD_LEFT) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_DPAD_LEFT) = inival
                        case "SDL_CONTROLLER_BUTTON_DPAD_RIGHT"
                            gpmap.vl(SDL_CONTROLLER_BUTTON_DPAD_RIGHT) = convertbutton(inival)
                            gpmap.lb(SDL_CONTROLLER_BUTTON_DPAD_RIGHT) = inival
                    end select
                end if
                'print inikey + " - " + inival
            end if    
        loop
        close(f)
        logentry("notice", "applied gamepadmap " + inifile)    
    end if    
end function

' simulate mouse pointer movement or keyboard with stick left and right
sub axis(byref axis2mouse as mouseinit, byref axisx as single, byref axisy as single, curscreenh as integer)
    ' set acceleration
    if axis2mouse.mouseaccx < curscreenh / 135 then
        axis2mouse.mouseaccx += axis2mouse.mouseacc * abs(axisx)
    end if
    if axis2mouse.mouseaccy < curscreenh / 135 then
        axis2mouse.mouseaccy += axis2mouse.mouseacc * abs(axisy)
    end if
        
    ' windows api for mousepointer regardless of active or focused window
    select case axisx
        case is < -axis2mouse.deadzone 
            select case axisy 
                case is < -axis2mouse.deadzone
                    SetCursorPos(axis2mouse.vpoint.x - axis2mouse.mouseaccx,_
                                 axis2mouse.vpoint.y - axis2mouse.mouseaccy)
                case is > axis2mouse.deadzone
                    SetCursorPos(axis2mouse.vpoint.x - axis2mouse.mouseaccx,_
                                 axis2mouse.vpoint.y + axis2mouse.mouseaccy)
                case else
                    SetCursorPos(axis2mouse.vpoint.x - axis2mouse.mouseaccx, axis2mouse.vpoint.y)
            end select
        case is > axis2mouse.deadzone
            select case axisy
                case is < -axis2mouse.deadzone
                    SetCursorPos(axis2mouse.vpoint.x + axis2mouse.mouseaccx,_
                                 axis2mouse.vpoint.y - axis2mouse.mouseaccy)
                case is > axis2mouse.deadzone
                    SetCursorPos(axis2mouse.vpoint.x + axis2mouse.mouseaccx,_
                                 axis2mouse.vpoint.y + axis2mouse.mouseaccy)
                case else
                    SetCursorPos(axis2mouse.vpoint.x + axis2mouse.mouseaccx, axis2mouse.vpoint.y)
            end select                            
        case else
            'stick movement up and down
            select case axisy
                case is < -axis2mouse.deadzone
                    SetCursorPos(axis2mouse.vpoint.x, axis2mouse.vpoint.y - axis2mouse.mouseaccy)
                case is > axis2mouse.deadzone
                    SetCursorPos(axis2mouse.vpoint.x, axis2mouse.vpoint.y + axis2mouse.mouseaccy)
            end select
    end select
end sub

function axis2key (axisanddir as integer, ax as single, byref gpmapaxis2key as mapaxis2key) as single

    if gpmapaxis2key.axisdir(axisanddir) then
        if gpmapaxis2key.axislab(axisanddir) <> "" then
            gpmapaxis2key.axissta(axisanddir) = true
            sendkeyb(gpmapaxis2key.axisval(axisanddir), gpmapaxis2key.axissta(axisanddir))
            ax = 0
        end if
    else
        if gpmapaxis2key.axissta(axisanddir) then
            gpmapaxis2key.axissta(axisanddir) = false
            sendkeyb(gpmapaxis2key.axisval(axisanddir), gpmapaxis2key.axissta(axisanddir))
        end if
    end if
    return ax

end function

function mouseclick(byref axis2mouse as mouseinit, button as string, press as boolean) as boolean

    select case button
        case "mouse left"
            if press then
                mouse_event(MOUSEEVENTF_LEFTDOWN, axis2mouse.vpoint.x, axis2mouse.vpoint.y, 0, 0)
                sdl_delay(10)
            else
                mouse_event(MOUSEEVENTF_LEFTUP, axis2mouse.vpoint.x, axis2mouse.vpoint.y, 0, 0)
            end if
        case "mouse right"
            if press then
                mouse_event(MOUSEEVENTF_RIGHTDOWN, axis2mouse.vpoint.x, axis2mouse.vpoint.y, 0, 0)
                sdl_delay(10)
            else
                mouse_event(MOUSEEVENTF_RIGHTUP, axis2mouse.vpoint.x, axis2mouse.vpoint.y, 0, 0)
            end if
    end select

    return true    

end function

' simulate windows mouse and keyboard with windows os api
' by thrive4 july 2023

#include once "SDL2/SDL.bi"
' simulate windows mouse and keyboard
#Include once "windows.bi"
#include once "utilfile.bas"
#include once "gamepad.bas"
#cmdline "app.rc"

' switch paddefinition via .mke file if available
dim paddefinition as string = "none"
dim dummy         as string = ""
dim fileext       as string = ""
dim filetypes     as string = ".mke"
dim imagefolder   as string

'init sdl
dim event            as SDL_Event
dim runningmain      as boolean = true
If (SDL_Init(SDL_INIT_VIDEO) = not NULL) Then
    logentry("error", "sdl2 video could not be initlized error: " + *SDL_GetError())
    SDL_Quit()
else
    ' app does not use sdl audio
    SDL_QuitSubSystem(SDL_INIT_AUDIO)
    ' render scale quality: 0 point, 1 linear, 2 anisotropic
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0")
End If

If (SDL_Init(SDL_INIT_GAMECONTROLLER) = not NULL) Then
    logentry("warning", "sdl2 gamecontroller could not be initlized error: " + *SDL_GetError())
End If

dim screenwidth         As integer  = 320
dim screenheight        As integer  = 280
dim shared curscreenw   as integer
dim shared curscreenh   as integer
Dim As SDL_Window Ptr glass
Dim As SDL_Texture Ptr texture
ScreenInfo curscreenw, curscreenh


glass = SDL_CreateWindow("gamepad", 100, 100, screenwidth, screenheight, SDL_WINDOW_MINIMIZED)
SDL_SetWindowResizable(glass, sdl_false)
SDL_ShowCursor(SDL_ENABLE)
if (glass = NULL) Then
    logentry("error", "sdl2 could not create window")
    SDL_Quit()
End If

' renderer
Dim As SDL_Renderer Ptr renderer = SDL_CreateRenderer(glass, -1, null)
if (renderer = NULL) Then
    logentry("error", "sdl2 could not create render")
    SDL_Quit()
End If

' load gamepad
controller = SDL_GameControllerOpen(0)
If (controller = NULL) Then
    logentry("warning", "unable to open gamepad - sdl error: " & *SDL_GetError())
else
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1")
    ' SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS
    '0 disable joystick & gamecontroller input events when the application is in the background
    '1 enable joystick & gamecontroller input events when the application is in the background
    'default joystick (and gamecontroller) events are not enabled when the application is in the background.
    logentry("notice", "gamepad detected " & *SDL_GameControllerName(controller))
end if

' possible fix for unrecognized gamepad https://github.com/gabomdq/SDL_GameControllerDB
'SDL_GameControllerAddMappingsFromFile("gamecontrollerdb.txt")
'Dim As ZString Ptr map = SDL_GameControllerMapping(controller)
' for debug
'Print *SDL_GameControllerName(controller)
'print *map
'sleep 3000

function lerp(lstart as single, lend as single, lstep as single) as single
    return (1 - lstep) * lstart + lstep * lend
end function

' init app with config file if present conf.ini
dim itm     as string
dim inikey  as string
dim inival  as string
dim inifile as string = exepath + "\conf\conf.ini"
dim f       as integer
if FileExists(inifile) = false then
    logentry("error", inifile + " file does not excist")
else 
    f = readfromfile(inifile)
    Do Until EOF(f)
        Line Input #f, itm
        if instr(1, itm, "=") > 1 then
            inikey = trim(mid(itm, 1, instr(1, itm, "=") - 2))
            inival = trim(mid(itm, instr(1, itm, "=") + 2, len(itm)))
            if inival <> "" then
                select case inikey
                    case "locale"
                        locale = inival
                    case "usecons"
                        usecons = inival
                    case "logtype"
                        logtype = inival
                    case "showbuttonpress"
                        gpmap.showbuttonpress = cbool(inival)
                    case "paddefinition"
                        paddefinition = inival
                end select
            end if
            'print inikey + " - " + inival
        end if    
    loop
    close(f)    
end if

' parse commandline for options overides conf.ini settings
select case command(1)
    case "/?", "-man"
        displayhelp(locale)
        logentry("terminate", "normal termination " + appname)
end select

' get media
imagefolder = command(1)
if instr(command(1), ".") <> 0 then
    fileext = lcase(mid(command(1), instrrev(command(1), ".")))
    if instr(1, filetypes, fileext) = 0 and instr(1, ".mke", fileext) = 0 then
        print command(1) + " file type not supported"
        end
    end if
    if FileExists(exepath + "\" + command(1)) = false then
        if FileExists(imagefolder) then
            'nop
        else
            print imagefolder + " does not excist or is incorrect"
            end
        end if
    else
        imagefolder = exepath + "\" + command(1)
        paddefinition = mid(imagefolder, instrrev(imagefolder, "\")+ 1, len(imagefolder) - instrrev(imagefolder, "\") - 4)
    end if
else
    ' paddefinition via conf.ini
    imagefolder = exepath + "\conf\" + paddefinition + ".mke"
end if

' main
print imagefolder
getgamepadini(imagefolder, gpmap, gpmapaxis2key)

' todo make more consistent
axis2mouse.deadzone = gpmap.deadzone
print "using map: " + space(len("current gamepad") - 9) + paddefinition
print "deadzone:  " + space(len("current gamepad") - 9) & axis2mouse.deadzone

while runningmain

    ' windows api for mousepointer regardless of active or focused window
    GetCursorPos(@axis2mouse.vpoint)

    ' gamepad axis handeld by sdl can deal with xinput / dinput toggle
    lsx = lerp(0, SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTX),  32767 * 0.000000001)
    lsy = lerp(0, SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTY),  32767 * 0.000000001)
    rsx = lerp(0, SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTX), 32767 * 0.000000001)
    rsy = lerp(0, SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTY), 32767 * 0.000000001)

    ' get deadzone per axis
    ' lstick_left_2keyaw
    gpmapaxis2key.axisdir(1) = iif (lsx < -axis2mouse.deadzone, true, false)
    ' lstick_right_2key
    gpmapaxis2key.axisdir(2) = iif (lsx > axis2mouse.deadzone, true, false)
    '  lstick_up_2key
    gpmapaxis2key.axisdir(3) = iif (lsy < -axis2mouse.deadzone, true, false)
    ' lstick_down_2key
    gpmapaxis2key.axisdir(4) = iif (lsy > axis2mouse.deadzone, true, false)
    ' rstick_left_2key
    gpmapaxis2key.axisdir(5) = iif (rsx < -axis2mouse.deadzone, true, false)
    ' rstick_right_2key
    gpmapaxis2key.axisdir(6) = iif (rsx > axis2mouse.deadzone, true, false)
    ' rstick_up_2key
    gpmapaxis2key.axisdir(7) = iif (rsy < -axis2mouse.deadzone, true, false)
    ' rstick_down_2key
    gpmapaxis2key.axisdir(8) = iif (rsy > axis2mouse.deadzone, true, false)
    
    ' reset acceleration
    if gpmapaxis2key.axisdir(1) = false and gpmapaxis2key.axisdir(2) = false and _
       gpmapaxis2key.axisdir(3) = false and gpmapaxis2key.axisdir(4) = false and _
       gpmapaxis2key.axisdir(5) = false and gpmapaxis2key.axisdir(6) = false and _
       gpmapaxis2key.axisdir(7) = false and gpmapaxis2key.axisdir(8) = false then
                axis2mouse.mouseaccx = 0
                axis2mouse.mouseaccy = 0
    end if

    ' axis mapped to aw
    ' lstick_left_2key
    lsx = axis2key(1, lsx, gpmapaxis2key)
    ' lstick_right_2key
    lsx = axis2key(2, lsx, gpmapaxis2key)
    '  lstick_up_2key
    lsy = axis2key(3, lsy, gpmapaxis2key)
    ' lstick_down_2key
    lsy = axis2key(4, lsy, gpmapaxis2key)
    ' rstick_left_2key
    rsx = axis2key(5, rsx, gpmapaxis2key)
    ' rstick_right_2key
    rsx = axis2key(6, rsx, gpmapaxis2key)
    ' rstick_up_2key
    rsy = axis2key(7, rsy, gpmapaxis2key)
    ' rstick_down_2key
    rsy = axis2key(8, rsy, gpmapaxis2key)

    ' left axis mapped to mouse pointer
    if gpmap.axl2mouse then
        if gpmapaxis2key.axisdir(1) or gpmapaxis2key.axisdir(2) or _
           gpmapaxis2key.axisdir(3) or gpmapaxis2key.axisdir(4) then
            axis(axis2mouse, lsx, lsy, curscreenh)
        end if
    end if

    ' right axis mapped to mouse pointer
    if gpmap.axr2mouse then
        if gpmapaxis2key.axisdir(5) or gpmapaxis2key.axisdir(6) or _
           gpmapaxis2key.axisdir(7) or gpmapaxis2key.axisdir(8) then
            ' dinput
            axis(axis2mouse, rsx, rsy, curscreenh)
        end if
    end if

    ' note polling on sdlevent is necessary otherwise there is no ouput
    while SDL_PollEvent(@event) <> 0
        ' basic window interaction
        select case event.type
            case SDL_KEYDOWN and event.key.keysym.sym = SDLK_ESCAPE
                runningmain = False
            case SDL_WINDOWEVENT and event.window.event = SDL_WINDOWEVENT_CLOSE
                runningmain = False     
            case SDL_CONTROLLERBUTTONDOWN
                buttondowntime = SDL_GetTicks()
                if instr(gpmap.lb(event.cbutton.button), "mouse") > 0 then
                    mouseclick(axis2mouse, gpmap.lb(event.cbutton.button), true)
                else
                    sendkeyb(gpmap.vl(event.cbutton.button), true)
                end if
            case SDL_CONTROLLERBUTTONUP
                buttonuptime  = SDL_GetTicks()
                if instr(gpmap.lb(event.cbutton.button), "mouse") > 0 then
                    mouseclick(axis2mouse, gpmap.lb(event.cbutton.button), false)
                else
                    sendkeyb(gpmap.vl(event.cbutton.button), false)
                end if
                ' debug
                if gpmap.showbuttonpress then
                    if (buttonuptime - buttondowntime) * 0.001 > gpmap.settimerduration and gpmap.settimeron = gpmap.bt(event.cbutton.button) then
                        print "timer button " + gpmap.settimeron + " hold for " & gpmap.settimerduration
                    else
                        print gpmap.lb(event.cbutton.button) + " " + gpmap.bt(event.cbutton.button) + " duration " & (buttonuptime - buttondowntime) * 0.001
                    end if
                end if
                buttonuptime = 0
                buttondowntime = 0
            case SDL_CONTROLLERAXISMOTION
                ' triggers range from 0 to 32767
                if event.caxis.axis = SDL_CONTROLLER_AXIS_TRIGGERLEFT then
                    if event.caxis.value > 1000 then
                        buttondowntime = SDL_GetTicks()
                        if instr(gpmap.lb(event.caxis.axis + 100), "mouse") > 0 then
                            mouseclick(axis2mouse, gpmap.lb(event.caxis.axis + 100), true)
                        else
                            sendkeyb(gpmap.vl(event.caxis.axis + 100), true)
                        end if
                    end if
                    if event.caxis.value < 999 then
                        buttonuptime  = SDL_GetTicks()
                        if instr(gpmap.lb(event.caxis.axis + 100), "mouse") > 0 then
                            mouseclick(axis2mouse, gpmap.lb(event.caxis.axis + 100), false)
                        else
                            sendkeyb(gpmap.vl(event.caxis.axis + 100), false)
                        end if
                        if gpmap.showbuttonpress then
                            print "triggerleft duration " & (buttonuptime - buttondowntime) * 0.001
                        end if
                        buttonuptime = 0
                        buttondowntime = 0
                    end if
                end if
                if  event.caxis.axis = SDL_CONTROLLER_AXIS_TRIGGERRIGHT then
                    if event.caxis.value > 1000 then
                        buttondowntime = SDL_GetTicks()
                        if instr(gpmap.lb(event.caxis.axis + 100), "mouse") > 0 then
                            mouseclick(axis2mouse, gpmap.lb(event.caxis.axis + 100), true)
                        else
                            sendkeyb(gpmap.vl(event.caxis.axis + 100), true)
                        end if
                    end if
                    if event.caxis.value < 999 then
                        buttonuptime  = SDL_GetTicks()
                        if instr(gpmap.lb(event.caxis.axis + 100), "mouse") > 0 then
                            mouseclick(axis2mouse, gpmap.lb(event.caxis.axis + 100), false)
                        else
                            sendkeyb(gpmap.vl(event.caxis.axis + 100), false)
                        end if
                        if gpmap.showbuttonpress then
                            print "triggerright duration " & (buttonuptime - buttondowntime) * 0.001
                        end if
                        buttonuptime = 0
                        buttondowntime = 0
                    end if
                end if
            case SDL_CONTROLLERDEVICEADDED
                SDL_free(map)
                SDL_GameControllerClose(controller)
                controller = SDL_GameControllerOpen(0)
                print "current gamepad: " & *SDL_GameControllerName(controller)
                logentry("notice", "switched to game controller: " & *SDL_GameControllerName(controller))
                map = SDL_GameControllerMapping(controller)
        end select
    wend

    ' use sdl_delay to keep cpu usage low needs low value with gamepads < 20 ms
    SDL_Delay(10)

wend

' Free all resources allocated by SDL
SDL_DestroyRenderer(renderer)
SDL_DestroyWindow(glass)
SDL_free(map)
SDL_GameControllerClose(controller)
SDL_Quit()

logentry("terminate", "normal termination " + appname)

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
dim locale        as string = "en"

'init sdl
dim event            as SDL_Event
dim runningmain      as boolean = true
If (SDL_Init(SDL_INIT_VIDEO) = not NULL) Then
    logentry("error", "sdl2 video could not be initlized error: " + *SDL_GetError())
    SDL_Quit()
else
    ' app does not use sdl audio
    SDL_QuitSubSystem(SDL_INIT_AUDIO)
    SDL_QuitSubSystem(SDL_INIT_HAPTIC)
    ' render scale quality: 0 point, 1 linear, 2 anisotropic
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0")
    ' filter non used events
    SDL_EventState(SDL_FINGERMOTION,    SDL_IGNORE)
    SDL_EventState(SDL_FINGERDOWN,      SDL_IGNORE)
    SDL_EventState(SDL_FINGERUP,        SDL_IGNORE)
    SDL_EventState(SDL_MULTIGESTURE,    SDL_IGNORE)
    SDL_EventState(SDL_DOLLARGESTURE,   SDL_IGNORE)
    SDL_EventState(SDL_JOYBALLMOTION,   SDL_IGNORE)
    SDL_EventState(SDL_DROPFILE,        SDL_IGNORE)

' still linked to SDL_CONTROLLER
    'SDL_EventState(SDL_JOYAXISMOTION,   SDL_IGNORE)
    'SDL_EventState(SDL_JOYHATMOTION,    SDL_IGNORE)
    'SDL_EventState(SDL_JOYBUTTONDOWN,   SDL_IGNORE)
    'SDL_EventState(SDL_JOYBUTTONUP,     SDL_IGNORE)
    'SDL_EventState(SDL_JOYDEVICEADDED,  SDL_IGNORE)
    'SDL_EventState(SDL_JOYDEVICEREMOVED,SDL_IGNORE)
End If

If (SDL_Init(SDL_INIT_GAMECONTROLLER) = not NULL) Then
    logentry("fatal", "sdl2 gamecontroller could not be initlized error: " + *SDL_GetError())
End If

dim screenwidth         As integer  = 320
dim screenheight        As integer  = 280
dim shared curscreenw   as integer
dim shared curscreenh   as integer

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
    return (1.0f - lstep) * lstart + lstep * lend
end function

' init app with config file if present conf.ini
dim itm     as string
dim inikey  as string
dim inival  as string
dim inifile as string = exepath + "\conf\conf.ini"
dim f       as long
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

' verify locale otherwise set default
select case locale
    case "en", "es", "de", "fr", "nl"
        ' nop
    case else
        logentry("error", "unsupported locale " + locale + " applying default setting")
        locale = "en"
end select

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
axis2mouse.deadzone    = gpmap.deadzone * 0.002f
axis2mouse.acceleratex = gpmap.acceleratex
axis2mouse.acceleratey = gpmap.acceleratey
dim ax2mdzk as single  = axis2mouse.deadzone * 4.5f
'print "using map: " + space(len("current gamepad") - 9) + paddefinition
'print "deadzone:  " + space(len("current gamepad") - 9) & axis2mouse.deadzone
readuilabel(exepath + "\conf\" + locale + "\menu.ini")
getuilabelvalue("using map", paddefinition)
getuilabelvalue("deadzone" , str(axis2mouse.deadzone))
while runningmain
    ' todo use to get deadzones both sticks
    'print SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTX)
    'print SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTX)

    ' windows api for mousepointer regardless of active or focused window
    GetCursorPos(@axis2mouse.vpoint)

    ' gamepad axis handeld by sdl can deal with xinput / dinput toggle
    lsx = lerp(0, SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTX),  0.000032767f)
    lsy = lerp(0, SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTY),  0.000032767f)
    rsx = lerp(0, SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTX), 0.000032767f)
    rsy = lerp(0, SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTY), 0.000032767f)
    ' start polling left and right stick if axis value is larger than sdl deadzone
    if rsx * rsx + rsy * rsy > axis2mouse.deadzone or lsx * lsx + lsy * lsy > axis2mouse.deadzone then
        ' get deadzone per axis
        ' lstick_left_2keyaw
        gpmapaxis2key.axisdir(1) = iif (lsx < -ax2mdzk, true, false)
        ' lstick_right_2key
        gpmapaxis2key.axisdir(2) = iif (lsx >  ax2mdzk, true, false)
        '  lstick_up_2key
        gpmapaxis2key.axisdir(3) = iif (lsy < -ax2mdzk, true, false)
        ' lstick_down_2key
        gpmapaxis2key.axisdir(4) = iif (lsy >  ax2mdzk, true, false)
        ' rstick_left_2key
        gpmapaxis2key.axisdir(5) = iif (rsx < -ax2mdzk, true, false)
        ' rstick_right_2key
        gpmapaxis2key.axisdir(6) = iif (rsx >  ax2mdzk, true, false)
        ' rstick_up_2key
        gpmapaxis2key.axisdir(7) = iif (rsy < -ax2mdzk, true, false)
        ' rstick_down_2key
        gpmapaxis2key.axisdir(8) = iif (rsy >  ax2mdzk, true, false)
        
        ' left axis mapped to mouse pointer or keys
        if gpmap.axl2mouse then
            axis(axis2mouse, lsx, lsy, "left")
        else
            ' lstick_left_2key
            lsx = axis2key(1, lsx, gpmapaxis2key)
            ' lstick_right_2key
            lsx = axis2key(2, lsx, gpmapaxis2key)
            '  lstick_up_2key
            lsy = axis2key(3, lsy, gpmapaxis2key)
            ' lstick_down_2key
            lsy = axis2key(4, lsy, gpmapaxis2key)
        end if

        ' right axis mapped to mouse pointer or keys
        if gpmap.axr2mouse then
            axis(axis2mouse, rsx, rsy, "right")
        else
            ' rstick_left_2key
            rsx = axis2key(5, rsx, gpmapaxis2key)
            ' rstick_right_2key
            rsx = axis2key(6, rsx, gpmapaxis2key)
            ' rstick_up_2key
            rsy = axis2key(7, rsy, gpmapaxis2key)
            ' rstick_down_2key
            rsy = axis2key(8, rsy, gpmapaxis2key)
        end if
    end if
    ' reset acceleration
    if rsx * rsx + rsy * rsy < axis2mouse.deadzone then
        axis2mouse.mouseaccrx = 0
        axis2mouse.mouseaccry = 0
    end if
    if lsx * lsx + lsy * lsy < axis2mouse.deadzone then
        axis2mouse.mouseacclx = 0
        axis2mouse.mouseaccly = 0
    end if

    ' note polling on sdlevent is necessary otherwise there is no ouput
    while SDL_PollEvent(@event) <> 0
        select case event.type
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
            ' only used for left and right triggers range from 0 to 32767
            case SDL_CONTROLLERAXISMOTION
                if event.caxis.axis = SDL_CONTROLLER_AXIS_TRIGGERLEFT then
                    if event.caxis.value > 1000 then
                        buttondowntime = SDL_GetTicks()
                        if instr(gpmap.lb(event.caxis.axis + 100), "mouse") > 0 then
                            mouseclick(axis2mouse, gpmap.lb(event.caxis.axis + 100), true)
                            ' prevent stutter todo timing issue needs more thought
                            sdl_delay(200)
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
                            ' prevent stutter todo timing issue needs more thought
                            sdl_delay(200)
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
                'print "current gamepad: " & *SDL_GameControllerName(controller)
                getuilabelvalue("current gamepad" , "" + *SDL_GameControllerName(controller))
                logentry("notice", "switched to game controller: " & *SDL_GameControllerName(controller))
                map = SDL_GameControllerMapping(controller)
        end select
    wend

    ' use sdl_delay to keep cpu usage low needs low value with gamepads < 20 ms
    SDL_Delay(10)

wend

' Free all resources allocated by SDL
SDL_free(map)
SDL_GameControllerClose(controller)
SDL_Quit()

logentry("terminate", "normal termination " + appname)

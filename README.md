## gamepad2mkb
basic mouse and keyboard emulator via gamepad\
written in freebasic and sdl2\
a specific key can be used for timed actions example\
settimerduration    = 2.5\
settimeron          = btback

## usage
gamepad2mkb.exe "path to file"\
if no file is specified then defaults to no emulation\
\
or specify a path via \conf\conf.ini
[gamepad map]\
' location mke\
paddefinition = conf\<filename>.mke

## requirements
sdl2 (32bit) v2.24.2.0\
https://github.com/libsdl-org/SDL/releases

## performance
windows 7 / windows 10(1903)\
ram usage ~5MB / 5MB\
handles   ~148 / ~200\
threads   ~6   / ~10\
cpu       ~0%  / ~0%\
tested on intel i5-6600T
## navigation
esc                                 : close application
## mapping explained
regular keys:     a-Z and 0 - 1\
example = key a, key 0, etc\
special keys:     return, escape\
example = key escape, key return\
directional keys: up, down, left right\
example = key up, key down\
mouse buttons: mouse left, mouse right\
example = mouse left
\
mapping axis\
example map axis left to key:\
lstick_left_2key = key a\
mousemovement can be mapped / unmapped via:\
lstick2mouse        = true\
or\
lstick2mouse        = false\

## example .mke structure
[general]\
mapversion          = 1.0\
settimerduration    = 2.5\
settimeron          = btback
deadzone            = 0.4

[joystick01]\
lstick_left_2key    =\
lstick_right_2key   =\
lstick_up_2key      =\
lstick_down_2key    =\
rstick_left_2key    =\
rstick_right_2key   =\
rstick_up_2key      =\
rstick_down_2key    =\
lstick2mouse        = true\
rstick2mouse        = true\
SDL_CONTROLLER_BUTTON_A                 = mouse left\
SDL_CONTROLLER_BUTTON_B                 = key h\
SDL_CONTROLLER_BUTTON_X                 = mouse right\
SDL_CONTROLLER_BUTTON_Y                 = key i\
SDL_CONTROLLER_BUTTON_BACK              = key return\
SDL_CONTROLLER_BUTTON_GUIDE             = \
SDL_CONTROLLER_BUTTON_START             = key escape\
SDL_CONTROLLER_BUTTON_LEFTSTICK         = \
SDL_CONTROLLER_BUTTON_RIGHTSTICK        = \
SDL_CONTROLLER_BUTTON_LEFTSHOULDER      = \
SDL_CONTROLLER_BUTTON_RIGHTSHOULDER     = \
SDL_CONTROLLER_AXIS_TRIGGERLEFT         = mouse right\
SDL_CONTROLLER_AXIS_TRIGGERRIGHT        = mouse left\
SDL_CONTROLLER_BUTTON_DPAD_UP           = key up\
SDL_CONTROLLER_BUTTON_DPAD_DOWN         = key down\
SDL_CONTROLLER_BUTTON_DPAD_LEFT         = key left\
SDL_CONTROLLER_BUTTON_DPAD_RIGHT        = key right

## internal readable button labels (used for settimeron)
' init map to readable generic button name\
gpmap.bt(SDL_CONTROLLER_BUTTON_A)               = "bta"\
gpmap.bt(SDL_CONTROLLER_BUTTON_B)               = "btb"\
gpmap.bt(SDL_CONTROLLER_BUTTON_X)               = "btx"\
gpmap.bt(SDL_CONTROLLER_BUTTON_Y)               = "bty"\
gpmap.bt(SDL_CONTROLLER_BUTTON_BACK)            = "btback"\
gpmap.bt(SDL_CONTROLLER_BUTTON_GUIDE)           = "btguide"\
gpmap.bt(SDL_CONTROLLER_BUTTON_START)           = "btstart"\
gpmap.bt(SDL_CONTROLLER_BUTTON_LEFTSTICK)       = "btlstick"\
gpmap.bt(SDL_CONTROLLER_BUTTON_RIGHTSTICK)      = "btrstick"\
gpmap.bt(SDL_CONTROLLER_BUTTON_LEFTSHOULDER)    = "btlshoulder"\
gpmap.bt(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER)   = "btrshoulder"\
gpmap.bt(SDL_CONTROLLER_AXIS_TRIGGERLEFT + 100) = "btrtrigger"\
gpmap.bt(SDL_CONTROLLER_AXIS_TRIGGERRIGHT+ 100) = "btltrigger"\
gpmap.bt(SDL_CONTROLLER_BUTTON_DPAD_UP)         = "btdpup"\
gpmap.bt(SDL_CONTROLLER_BUTTON_DPAD_DOWN)       = "btdpdown"\
gpmap.bt(SDL_CONTROLLER_BUTTON_DPAD_LEFT)       = "btdpleft"\
gpmap.bt(SDL_CONTROLLER_BUTTON_DPAD_RIGHT)      = "btdpright"



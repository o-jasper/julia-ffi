#  Jasper den Ouden 02-08-2012
# Placed in public domain.

draw_funs_lib = load_so("sdl_bad_utils/sdl_event.so")

@get_c_fun draw_funs_lib auto mouse_x()::Int32
@get_c_fun draw_funs_lib auto mouse_y()::Int32
@get_c_fun draw_funs_lib auto poll_event()::Int32

function flush_events(quit_exit::Bool)
  while true
    pol = poll_event()
    if pol == SDL_EVENTS_DONE
      return
    end
    if pol == SDL_QUIT && quit_exit
      exit()
    end
  end
end
flush_events() = flush_events(true)

#@get_c_fun_list draw_funs_lib begin
#  mouse_x()::Int32
#  mouse_y()::Int32
#  poll_event()::Int32
#end

const SDL_ID_FAILED = 1024

const SDL_MOUSE_MOTION = 1028

const SDL_MOUSE_LEFT = 1025
const SDL_MOUSE_RIGHT = 1026
const SDL_MOUSE_MIDDLE = 1027

#Le non-asci keys.
const SDLK_PAUSE = 1029
const SDLK_ESCAPE = 1040
const SDLK_KP0 = 1030
const SDLK_KP1 = 1031
const SDLK_KP2 = 1032
const SDLK_KP3 = 1033
const SDLK_KP4 = 1034
const SDLK_KP5 = 1035
const SDLK_KP6 = 1036
const SDLK_KP7 = 1037
const SDLK_KP8 = 1038;
const SDLK_KP9 = 1039
const SDLK_KP_PERIOD = 1041
const SDLK_KP_DIVIDE = 1042
const SDLK_KP_MINUS = 1043
const SDLK_KP_PLUS = 1044;
const SDLK_KP_ENTER = 1045
const SDLK_KP_EQUALS = 1046
const SDLK_UP = 1047
const SDLK_DOWN = 1048
const SDLK_RIGHT = 1049
const SDLK_LEFT = 1050
const SDLK_INSERT = 1051
const SDLK_HOME = 1052
const SDLK_END = 1053
const SDLK_PAGEUP = 1054
const SDLK_PAGEDOWN = 1055
const SDLK_F1 = 1056
const SDLK_F2 = 1057
const SDLK_F3 = 1058
const SDLK_F4 = 1059
const SDLK_F5 = 1060
const SDLK_F6 = 1061
const SDLK_F7 = 1062
const SDLK_F8 = 1063
const SDLK_F9 = 1064
const SDLK_F10 = 1065
const SDLK_F11 = 1066
const SDLK_F12 = 1067
const SDLK_F13 = 1068
const SDLK_F14 = 1069
const SDLK_F15 = 1070
const SDLK_NUMLOCK = 1071
const SDLK_CAPSLOCK = 1072
const SDLK_SCROLLOCK = 1073
const SDLK_RSHIFT = 1074
const SDLK_LSHIFT = 1075
const SDLK_RCTRL = 1076
const SDLK_LCTRL = 1077
const SDLK_RALT = 1078
const SDLK_LALT = 1079
const SDLK_RMETA = 1080
const SDLK_LMETA = 1081
const SDLK_LSUPER = 1082
const SDLK_RSUPER = 1083
const SDLK_MODE = 1084
const SDLK_HELP = 1085
const SDLK_PRINT = 1086
const SDLK_SYSREQ = 1087
const SDLK_BREAK = 1088
const SDLK_MENU = 1089
const SDLK_POWER = 1090
const SDLK_EURO = 1091

const SDL_QUIT = 1100
const SDL_VIDEORESIZE = 1101
const SDL_VIDEOEXPOSE = 1102
const SDL_SYSWMEVENT = 1103

const SDL_EVENTS_DONE = 0

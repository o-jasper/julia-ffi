//  Jasper den Ouden 02-08-2012
// Placed in public domain.

#include <SDL/SDL.h>

struct { int x,y; } mouse_pos;

int mouse_x(){ return mouse_pos.x; }
int mouse_y(){ return mouse_pos.y; }

int mouse_index(int bb)
{ switch(bb)
    { case SDL_BUTTON_LEFT:   return 1025;
      case SDL_BUTTON_RIGHT:  return 1026;
      case SDL_BUTTON_MIDDLE: return 1027;
    }
}

enum
  { _MOUSE_MOTION = 1028,
    _ID_FAILED = 1024,
  };

int key_index(int keysym)
{
  switch(keysym)
    { case SDLK_PAUSE:  return 1029;
      case SDLK_ESCAPE: return 1040;
      case SDLK_KP0: return 1030;
      case SDLK_KP1: return 1031;
      case SDLK_KP2: return 1032;
      case SDLK_KP3: return 1033;
      case SDLK_KP4: return 1034;
      case SDLK_KP5: return 1035;
      case SDLK_KP6: return 1036;
      case SDLK_KP7: return 1037;
      case SDLK_KP8: return 1038; 
      case SDLK_KP9: return 1039;
      case SDLK_KP_PERIOD: return 1041;
      case SDLK_KP_DIVIDE: return 1042;
      case SDLK_KP_MINUS:  return 1043;
      case SDLK_KP_PLUS:   return 1044; 
      case SDLK_KP_ENTER:  return 1045;
      case SDLK_KP_EQUALS: return 1046;
      case SDLK_UP: return 1047;
      case SDLK_DOWN: return 1048;
      case SDLK_RIGHT: return 1049;
      case SDLK_LEFT: return 1050;
      case SDLK_INSERT: return 1051;
      case SDLK_HOME: return 1052;
      case SDLK_END: return 1053;
      case SDLK_PAGEUP: return 1054;
      case SDLK_PAGEDOWN: return 1055;
      case SDLK_F1: return 1056;
      case SDLK_F2: return 1057;
      case SDLK_F3: return 1058;
      case SDLK_F4: return 1059;
      case SDLK_F5: return 1060;
      case SDLK_F6: return 1061;
      case SDLK_F7: return 1062;
      case SDLK_F8: return 1063;
      case SDLK_F9: return 1064;
      case SDLK_F10: return 1065;
      case SDLK_F11: return 1066;
      case SDLK_F12: return 1067;
      case SDLK_F13: return 1068;
      case SDLK_F14: return 1069;
      case SDLK_F15: return 1070;
      case SDLK_NUMLOCK: return 1071;
      case SDLK_CAPSLOCK: return 1072;
      case SDLK_SCROLLOCK: return 1073;
      case SDLK_RSHIFT: return 1074;
      case SDLK_LSHIFT: return 1075;
      case SDLK_RCTRL: return 1076;
      case SDLK_LCTRL: return 1077;
      case SDLK_RALT: return 1078;
      case SDLK_LALT: return 1079;
      case SDLK_RMETA: return 1080;
      case SDLK_LMETA: return 1081;
      case SDLK_LSUPER: return 1082;
      case SDLK_RSUPER: return 1083;
      case SDLK_MODE: return 1084;
      case SDLK_HELP: return 1085;
      case SDLK_PRINT: return 1086;
      case SDLK_SYSREQ: return 1087;
      case SDLK_BREAK: return 1088;
      case SDLK_MENU: return 1089;
      case SDLK_POWER: return 1090;
      case SDLK_EURO: return 1091; 
      default: return (keysym > 0 && keysym < 256) ? keysym : 0;
    }
}
//Returns 0 for no currentpolled event, 
// -1, 'nothing to say' (for _some_ reason)
int poll_event()
{
  SDL_Event event;
  if( SDL_PollEvent(&event) )
    {
      switch(event.type)
	{
        case SDL_MOUSEMOTION:
	  mouse_pos.x = event.button.x;
	  mouse_pos.y = event.button.y;
	  return _MOUSE_MOTION;
	case SDL_MOUSEBUTTONDOWN: 
	  return +mouse_index(event.button.button);
	case SDL_MOUSEBUTTONUP: 
	  return -mouse_index(event.button.button);
        case SDL_KEYDOWN:
	  return +key_index(event.key.keysym.sym);
        case SDL_KEYUP:
	  return -key_index(event.key.keysym.sym);
          break;
	case SDL_QUIT:
	  return 1100;
	case SDL_VIDEORESIZE:
	  return 1101;
	case SDL_VIDEOEXPOSE:
	  return 1102;
	case SDL_SYSWMEVENT:
	  return 1103;
	default: //NOTE: just mousedown atm.
	  return _ID_FAILED;
	}
    }
  return 0;
}

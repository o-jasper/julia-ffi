
#Just tests some gl drawing and showing where the cursor is as such.
load("util/util.jl")
load("util/get_c.jl")

load("autoffi/gl.jl")
load("ffi_extra/gl.jl")

load("sdl_bad_utils/sdl_bad_utils.jl")

import OJasper_Util.*
import SDL_BadUtils.*
import AutoFFI_GL.*
import FFI_Extra_GL.*

function run_this ()
    screen_width = 640
    screen_height = 640
    init_stuff()
    
    mx(i) = -1 + 2*i/screen_width
    my(j) = +1 - 2*j/screen_width
    mx()  = mx(mouse_x())
    my()  = my(mouse_y())
    
    p,r = [0,0], 0.04
    last_t = time()
    
    v = [0,0]
    while true
        cur_t = time() #Move it.
        p += 0.1*v*(cur_t-last_t)
        last_t = cur_t
        
        @with glprimitive(GL_TRIANGLES) begin
            glcolor(1,1,1)
            glvertex(-1,-1) #Triangle thing.
            glvertex(-1,1)
            glvertex(1,0)
            
            glcolor(0,0,1) #Moving thingy.
            glvertex(p[1]-0.3*r, p[2]-r*0.3)
            glvertex(p[1]+0.3*r, p[2]-r*0.3)
            glvertex(p[1],       p[2]+r)
            
            glcolor(1,0,0) #Cursor.
            glvertex(mx(),my())
            glvertex(mx()+0.1,my())
            glvertex(mx(),my()+0.1)
        end
        finalize_draw()
        #flush_events()
        while true
            poll = poll_event() 
            @case poll begin
                SDL_QUIT        : exit()
                SDL_EVENTS_DONE : break
            end
            v+= @case poll begin #Move around a thing.
                SDLK_RIGHT | int('d') : [1,0]
                SDLK_LEFT  | int('a') : [-1,0]
                SDLK_UP    | int('w') : [0,1]
                SDLK_DOWN  | int('s') : [0,-1]

                -SDLK_RIGHT | -int('d') : [-1,0]
                -SDLK_LEFT  | -int('a') : [1,0]
                -SDLK_UP    | -int('w') : [0,-1]
                -SDLK_DOWN  | -int('s') : [0,1]
                default : [0,0]
            end
        end
    end
end

run_this()


#Just tests some gl drawing and showing where the cursor is as such.

load("util/load_so.j")
load("util/util.j")
load("util/get_c.j")

load("autoffi/gl.j")
load("ffi_extra/gl.j")

load("sdl_bad_utils/sdl_bad_utils.j")

function run_this ()
  screen_width = 640
  screen_height = 640
  init_stuff()

  mx(i) = -1 + 2*i/screen_width
  my(j) = 1 - 2*j/screen_width
  mx()  = mx(mouse_x())
  my()  = my(mouse_y())

  while true
    glcolor(1.0,1.0,1.0)
    @with glprimitive(GL_TRIANGLES) begin
      glvertex(-1,-1)
      glvertex(-1,1)
      glvertex(1,0)
      glcolor(1.0,0.0,0.0)
      glvertex(mx(),my())
      glvertex(mx()+0.1,my())
      glvertex(mx(),my()+0.1)
    end
    finalize_draw()
    flush_events()
  end
end

run_this()

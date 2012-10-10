
Note that it is sortah called 'bad utils' for a reason. They were
convenient-ish when the parser didn't want to parse the SDL header file.
But i hope it will, and then i might replace it.

# sdl_bad_utils functions:

### init_stuff(w=640,h=640)::Int32
Initiate a window, including opengl.
### finalize_draw()::Int32

    SDL_GL_SwapBuffers(); //Bit limited!
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glLoadIdentity(); 


### mouse_x()::Int32, mouse_y()::Int32
Returns mouse position *as* `Int32`

### poll_event()::Int32
Returns next event as `Int32`, most events exist as `const` values.
(like all the `SDLK_..`s) 

### flush_events(quit_exit_p = true)
Flush all the comments, for instance for if you don't care. 
Optionally exit on that signal.

# gl_sdl_load_img.j
Loads images, and (possibly)enters them into opengl.
Requires `ffi_extra/gl.j`.

### sdl_free_surface(pointer::Ptr)
Assumes the `pointer` contains an `SDL_Surface` and frees it.

### IMG_Load(file::String)::Ptr
Loads an image from a file.

### gl_sdl_load_img(surf::Ptr, format, w,h, prepare=false)
Takes a SDL surface and returns a `GLuint` turning it into a GL surface.
If `prepare` is true, it does `glenable({GL_TEXTURE_2D,GL_BLEND})`

### gl_sdl_load_img(file::String, format::Integer, w=-1,h=-1,prepare=true)
Same, but reads an image from a file(using `IMG_Load`) gets in into GL, and 
then frees it.(with `sdl_free_surface`)

`w==-1` and `h==-1` indicate to use the image width/height itself.

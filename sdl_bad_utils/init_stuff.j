#  Jasper den Ouden 02-08-2012
# Placed in public domain.

stuff_lib = load_so("sdl_bad_utils/init_stuff.so") #TODO

@get_c_fun stuff_lib auto init_stuff(Int32,Int32)::Int32
init_stuff() = init_stuff(640,640)

@get_c_fun stuff_lib auto finalize_draw()::Int32

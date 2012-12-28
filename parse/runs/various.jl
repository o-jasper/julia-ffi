#NOTE: might aswell be under mess/

load("treekenize.jl")
using Treekenize
load("util/util.jl")
using OJasper_Util

load("Options.jl")
load("util/get_c.jl")
load("c_parse.jl")

load("pprint.jl")
using PrettyPrint

load("c_ffi.jl")


function gl_type_namer(name)
    i,j = search("$name", "PROC") #Dont know what these are supposed to mean.
    return (i>0 || j>0) ? nothing : name
end
gl_fun_namer(name,args) = symbol(lowercase("$name"))

info = FFI_Info("", @options fun_namer = gl_fun_namer type_namer = gl_type_namer)
gl_opts = (@options info = info)
   

#TODO handle 'doesnt belong' better.
#ffi_header("/usr/lib/gcc/x86_64-unknown-linux-gnu/4.7.1/include/stddef.h", gl_opts)
#ffi_header("GL/glext.h", gl_opts)
ffi_header("GL/gl.h", gl_opts)

# ffi_header("GL/glu.h", gl_opts) #TODO GLUnurbs issue; handle plain structs better.

#TODO assertion failed: Referring to nonexistent type? __fsid_t
#ffi_header("SDL/SDL.h", @options) 

#nova_opts = (@options info = FFI_Info("",@options) mention_files=true)
#ffi_nova(file) = ffi_header(file, nova_opts)
#
#map((file::String)->ffi_header("libnova/$file.h", nova_opts), 
#    ["ln_types", "utility", "libnova",
#     "aberration","dynamical_time","jupiter","neptune","proper_motion",
#     "transform",  "airmass",       "earth",  "nutation",
#     "refraction", "uranus",         "angular_separation","elliptic_motion",
#     "parabolic_motion","rise_set", "apparent_position","heliocentric_time",
#     "lunar", "parallax", "saturn", "venus", "asteroid", "hyperbolic_motion",
#     "mars", "pluto", "sidereal_time", "vsop87", "comet", "julian_day",
#     "mercury", "precession", "solar"])
#
#ffi_header("GL/freeglut_std.h", gl_opts)

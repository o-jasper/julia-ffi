
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

gl_opts = (@options info = 
   FFI_Info("", @options fun_namer = gl_fun_namer type_namer = gl_type_namer))


ffi_header("GL/gl.h", gl_opts)
# ffi_header("GL/glu.h", gl_opts) #TODO GLUnurbs issue; handle structs better.

#ffi_header("GL/freeglut_std.h", gl_opts)

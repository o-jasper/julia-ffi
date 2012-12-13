
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

ffi_header("GL/gl.h", 
@options fun_namer = (name,args)->symbol(lowercase("$name")) type_namer = gl_type_namer)

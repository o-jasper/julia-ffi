
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

@with s=open("autoffi/gl.jl", "w") begin
    to_pprint("test/gl.h.e",s,
              @options on_file = "GL/gl.h" lib_file = "libGL" module_name = "AutoFFI_GL")
end

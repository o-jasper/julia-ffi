
load("treekenize.jl")
import Treekenize.*
load("util/util.jl")
import OJasper_Util.*

load("options.jl")
load("util/get_c.jl")
load("c_parse.jl")

load("c_ffi.jl")

to_expr(str) = c_parse_top(stream_from_string(str))
to_ffi(str) = ffi_top(to_expr(str), FFI_Info(:gllib))

to_pprint(str) = pprint(to_ffi(str))

function to_pprint(to::IOStream, n::Integer)
    info = FFI_Info(:gllib)
    @with s = open("test/gl.h.e") for i=1:n
        pprint(to, ffi_top(c_parse_top(s), info))
        println(to)
    end
    return info
end
to_pprint(n::Integer) = to_pprint(stdout_stream,n)

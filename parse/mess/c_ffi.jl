
load("treekenize.jl")
import Treekenize.*
load("util/util.jl")
import OJasper_Util.*

load("options.jl")
load("util/get_c.jl")
load("c_parse.jl")

load("c_ffi.jl")

testc(str) = pprint(ffi_top(c_parse_top(stream_from_string(str)), FFI_Info(:gllib)))
function testc(to::IOStream, n::Integer)
    info = FFI_Info(:gllib)
    @with s = open("test/gl.h.e") for i=1:n
        pprint(to, ffi_top(c_parse_top(s), info))
        println(to)
    end
    return info
end
testc(n::Integer) = testc(stdout_stream,n)

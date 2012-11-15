
load("treekenize.jl")
import Treekenize.*
load("util/util.jl")
import OJasper_Util.*

load("options.jl")
load("util/get_c.jl")
load("c_parse.jl")

load("c_ffi.jl")

to_cexpr(str::String) = c_parse_top(stream_from_string(str))
to_cexpr(str) = c_parse_top(str)

to_ffi(str) = ffi_top(to_cexpr(str), FFI_Info(:gllib))

to_pprint(str) = pprint(to_ffi(str))

function to_something(from::IOStream, try_cnt::Integer, what::Function)
    try_n=0
    @with s = open("test/gl.h.e") while try_n<try_cnt
        got = c_parse_top(s)
        if isequal(got, nothing)
            try_n+=1
        else
            try_n=0
             what(got)
        end
    end
end
to_cexpr(to::IOStream, try_cnt::Integer) = 
    @collect to_something(to,try_cnt, collect_non_nothing)
function to_ffi(to::IOStream, try_cnt::Integer)
    info = FFI_Info(:gllib)
    @collect begin
        fun(x) = collect_non_nothing(ffi_top(x,info))
        to_something(to,try_cnt,fun)
    end
end

function to_pprint(to::IOStream, try_cnt::Integer)
    info = FFI_Info(:gllib,"GL/gl.h")
    function fun(x)
        ffi = ffi_top(x, info)
        if !isequal(ffi, nothing)
            pprint(to, ffi)
            println(to)
        end
    end
    to_something(to,try_cnt, fun)
    return info
end
to_pprint(n::Integer) = to_pprint(stdout_stream,n)

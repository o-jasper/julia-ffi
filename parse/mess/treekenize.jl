
load("treekenize.jl")
import Treekenize.*

load("util/util.jl")
import OJasper_Util.*

function test(str)
    s= ConvenientStream(stream_from_string(str))
    println(treekenize(s, {(",", :comma, nothing), ("(",")")},"\n", 10,1))
end

test("a,b,c (d e f,g) )")


function test2(str)
    s= ConvenientStream(stream_from_string(str))
    println(treekenize(s, {("left", "right"), ("ska", :ska,nothing)},
                       "\n", 10,5))
end

test2("a,b,c left d e f,g rightrightleftleftrorightrightskaleftkitten")

load("c_parse.jl")

testc(str) = c_parse_top(stream_from_string(str))

##testc("sqr(x,y+z,q)")
#
function testc(n::Integer)
    list = {}
    @with s = open("test/gl.h.e") for i=1:n
        push(list, c_parse_top(s))
    end
    return list
end

println(testc("void* function_with(Type* pointers);")) 
println(testc("extern __attribute__ ((visibility(\"default\"))) Uint8 SDL_GetAppState(void);"))


println(testc("extern unsigned long long int gnu_dev_makedev (unsigned int __major,
            unsigned int __minor)
     __attribute__ ((__nothrow__ , __leaf__)) __attribute__ ((__const__));"))

println(testc("typedef struct __pthread_internal_list
       {
         struct __pthread_internal_list __prev;
         struct __pthread_internal_list __next;
       } __pthread_list_t;"))
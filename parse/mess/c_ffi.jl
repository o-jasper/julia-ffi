
load("treekenize.jl")
using Treekenize
load("util/util.jl")
using OJasper_Util

require("Options")
load("util/get_c.jl")
load("c_parse.jl")

load("pprint.jl")
using PrettyPrint

load("c_ffi.jl")

test(x) = to_cexpr(stream_from_string(x), 10, (x,y)-> println(y))

test("typedef struct
  {
    unsigned long int __val[(1024 / (8 * sizeof (unsigned long int)))];
  } __sigset_t;")

println("----")
test("static __inline unsigned int
__bswap_32 (unsigned int __bsx)
{
  return __builtin_bswap32 (__bsx);
}
# 107 \"/usr/include/bits/byteswap.h\" 3 4")

test("typedef int int8_t __attribute__ ((__mode__ (__QI__)));")

test("typedef void ( * PFNGLMULTIMODEDRAWELEMENTSIBMPROC) (const GLenum *mode, const GLsizei *count, GLenum type, const GLvoid* const *indices, GLsizei primcount, GLint modestride);")

test("# 8975 \"/usr/include/GL/glext.h\" 3 4
typedef void ( * PFNGLCOLORPOINTERLISTIBMPROC) (GLint size, GLenum type, GLint stride, const GLvoid* *pointer, GLint ptrstride);")
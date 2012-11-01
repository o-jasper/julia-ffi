load("test/skip_white.jl")

import OJasper_Util.*
import CHeader.*

case(str) = @with s = stream_from_string(str) println(parse_top(s))

case("char kitten;")
case("int x(a,b);")

# => {kitten::TokType({char})}


#case("void glClearIndex( GLfloat c );")

#@with s = open("test/gl.h.e", "r") parse_top(s)
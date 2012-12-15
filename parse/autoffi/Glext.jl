#Autogenerated, parameters: 

module Glext

#Autogenerated module of /usr/include/GL/glext.h
module Glext
using Base, GetC

#Load library.

lib=dlopen("libglext")
macro g(name, c_fun) #Makes stuff shorter.
    :(@get_c_fun lib $name $c_fun)
end

#AutoFFI body.

export ptrdiff_t
typealias ptrdiff_t Int64

export size_t
typealias size_t Uint64

export wchar_t
typealias wchar_t Int32

export __gwchar_t
typealias __gwchar_t Int32

export imaxdiv_t
type imaxdiv_t
  quot::Int64
  rem::Int64
  nothing
end

end #module Glext

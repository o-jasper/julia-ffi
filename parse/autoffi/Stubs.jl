##Autogenerated module of /usr/include/gnu/stubs.h
module Stubs
using Base, GetC

#Load library.

lib=dlopen("libstubs")
macro g(name, c_fun) #Makes stuff shorter.
    :(@get_c_fun lib $name $c_fun)
end

#AutoFFI body.


end #module Stubs

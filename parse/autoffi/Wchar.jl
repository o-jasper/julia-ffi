#Autogenerated, parameters: 

module Wchar

#Autogenerated module of /usr/include/bits/wchar.h
module Wchar
using Base, GetC

#Load library.

lib=dlopen("libwchar")
macro g(name, c_fun) #Makes stuff shorter.
    :(@get_c_fun lib $name $c_fun)
end

#AutoFFI body.


end #module Wchar

#
#  Copyright (C) 02-10-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

#Turns the C 'tree' into julia-ffi-ing code.

function julia_ize_types(types)
  len = length(types)
  assert( len>0 ) #No type..?
  function last_tp(got,i)
    assert( len==i )
    return got
  end
  @case types[1] begin
    :char  | :int8_t  : last_tp(Int8, 1)
    :short | :int16_t : last_tp(Int16,1)
    :int   | :int32_t : last_tp(Int32,1)
    :long  | :int64_t : last_tp(Int64,1) #TODO long can be repeated..
    
    :uint8_t  : last_tp(Uint8, 1)
    :uint16_t : last_tp(Uint16,1)
    :uint32_t : last_tp(Uint32,1)
    :uint64_t : last_tp(Uint64,1) #TODO long can be repeated..
    
    :float  : last_tp(Float32,1)
    :double : last_tp(Float64,1)
    
    :void   : last_tp(Void,1)

    :ptr    : Ptr{julia_ize_types(types[2:])}
    
    if :const | :volatile | :inline
      julia_ize_types(types[2:]) #Consts are ignored atm.
    end
    if :unsigned 
      if len == 1
        return Uint32
      end
      @case types[2] begin
        :char   : last_tp(Uint8,2)
        :short  : last_tp(Uint16,2)
        :int    : last_tp(Uint32,2)
        :long   : last_tp(Uint64,2)
        default : error("looks like invalid unsigned type.")
      end
    end
    if default #None of those..
      
    end
  end
end

#Makes a type_name_hook that runs after the julia one.
julia_ized_type_name_hook(fun) = ((types) -> fun(julia_ize_types(types)))

#fun_name_hook that prepends/appends something.
# (can be combined with other hooks of course)
mark_funs(list, mark_prepend::String, mark_append::String) =
   ((fun_name_sym) -> contains(list, fun_name_sym) ?
                      symbol("$mark_prepend$fun_name_sym$mark_append") :
                      fun_name_sym)
mark_funs(list, mark_prepend::String) = mark_funs(list, mark_prepend,"")

type JuliaFFI
  lib_name::Symbol # Name of library variable.
  
 #You can replace these with a function to determine the Julia name as
 # dependent on the C name.
  fun_name_hook::Function
  type_hook::Function
  var_name_hook::Function

 #Receives toplevel stuff, can return anything. Return `nothing` to ignore
 # something.
  top_hook::Function 
  #lib_extra_name::Symbol # Name of library created for extra access.
end

JuliaFFI(lib_name::Symbol) =
    JuliaFFI(output, lib_name,
             identity, julia_ize_types, identity, identity)

#Receive a variable.
function ffi(by::JuliaFFI, var::TokVar)
  #Currently does nothing.
# TODO possibly make it an reader and accessor.
end

#Function.
function ffi(by::JuliaFFI, fun::TokFun)
  args = {fun.name}
  for a in fun.args
    push(args, by.type_hook(a.symbols))
  end
  return :(@get_c_fun $(by.lib_name) $(by.fun_name_hook(fun.name))
           $(Expr(call, args, by.type_hook(fun.ret_tp.symbols))))
end

# type definition
function ffi(by::JuliaFFI, tpdef::TokTypeDef)
  #TODO abstract type
  tokvar = tpdef.val
  #TODO look for and remove any struct.
  #TODO if struct inside, possibly make reader, accessor.
  :(typealias $(by.var_name_hook(tokvar.name)) $(by.type_hook(tokvar.tp)))
end

#function ffi(by::JuliaFFI, fun::TokStruct)
#function ffi(by::JuliaFFI, fun::TokEnum)

print_ffi_1(output::IOStream, by::JuliaFFI, stream::ConvenientStream) = 
    write(output, "$(ffi(by, parse_toplevel_1(stream)))\n")

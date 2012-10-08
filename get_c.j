#
#  Copyright (C) 11-07-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

#TODO how to make a :: symbol
const _of_type_sym = symbol("::")

const _error_third_must_be_in_form = "Third argument must be in form 
`function(Type1,Type2,argument::Type3 ..etc..)::ReturnType`"

#Defines a function using dlsym to obtain a function from dlsym.
macro get_c_fun (dlopen_lib, to_name, from_fun)
  assert(isa(to_name,Symbol), "The function must be 'assigned' to a symbol,\
 :auto to name it after the C name. Have non-symbol $to_name")
  assert(isa(from_fun,Expr), _error_third_must_be_in_form)
  assert( from_fun.head == _of_type_sym, "Return type not specified!\
 $_error_third_must_be_in_form" )
  assert( from_fun.args[1].head == :call, 
      "Not sure i may define functions on $(from_fun.args[1].head)" )
  c_name = from_fun.args[1].args[1]
  if to_name == :auto #Just use the C function name.
    to_name = c_name
  end
  arguments = #Whine about stuff done wrong. Convert arguments if needed.
    map(function (arg)
          if isa(arg, Symbol) #Just symbols are taken as types.
            arg=  Expr(_of_type_sym,{gensym(),arg},Any) #Gensym their argument
          end 
          assert(isa(arg,Expr), "$arg is not an expression; can't have `Any`\
 types at this point.")
          assert(arg.head== _of_type_sym, "Argument expression $arg is not a\
 type specifier (expect `var::type`")
          return arg
        end, from_fun.args[1].args[2:])
# Get info out of arguments of `from_fun`
  argument_names = map(function (arg) arg.args[1] end, arguments)
  return_type = from_fun.args[2]
  input_types = map(function (arg) arg.args[2] end, arguments)
# Construct the result.
  body = quote 
    $(Expr(:ccall, 
           cat(1, {:(dlsym($dlopen_lib, #Really needs to be a quote.
                           $(Expr(:quote,{c_name},Any)))), 
                   return_type, Expr(:tuple,input_types,Any)},
               argument_names), Any))
  end
  ret= Expr(:function,
            {Expr(:call, cat(1,{to_name},argument_names),Any), body},
            Any)
  return esc(ret)
end

#TODO magic gensym replacing dlopen_lib... how..
#Get_c fun, but in such a way that doing many doesnt require that much 
# repetition. 
macro get_c_fun_list (dlopen_lib, functions)
  assert( functions.head == :block, 
         "Not a block(which is begin..end) instead a: $(functions.head) " )
  lib = dlopen_lib
  assert( isa(lib, Symbol) )
  function handle (fun)
    if isa(fun,Expr) #Ask them why there is a LineNumberNode?
      if is(fun.head, _of_type_sym)
        Expr(:macrocall, {:get_c_fun,lib,:auto,fun}, Any)
      else if is(fun.head, :cell1d)
        Expr(:macrocall, {get_c_fun,lib,fun.args[1],
                          fun,args[2]}, Any)
        else #TODO warranted warning, better?
          assert( is(fun.head, :line),"Found some weird shit in macro, giving\
 an error, because otherwise this could be more nasty. (Any commas etc that\
  don't belong?)")
        end
      end
    end
  end
  blocklist = map(handle, functions.args)
  quote
    $lib = $dlopen_lib
    $(Expr(:block, blocklist,Any))
  end
end


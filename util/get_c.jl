#  Jasper den Ouden 05-12-2012
# Placed in public domain.

module GetC

using Base, OJasper_Util

export find_so_file_path, load_so
export @get_c_fun

#----no more module stuff.

#Loads a so, and checks if it exists, if not user probably didn't run make.
find_so_file_path(so_file::String) = find_file_from_dirs(so_file, LOAD_PATH)

#dlopens using `find_so_file` to locate the file.
load_so(so_file::String) =
    dlopen(find_so_file_path(so_file))

#TODO how to make a :: symbol
const _of_type_sym = symbol("::")

const _error_third_must_be_in_form = "Third argument must be in form 
`function(Type1,Type2,argument::Type3 ..etc..)::ReturnType`"

said_warnings = Dict{String, Bool}() #Note: shitty and one-off
function warn_once(warning::String)
    if !has(said_warnings, warning)
        println(warning)
        println(" (shown once per julia run)")
        assign(said_warnings, true,warning)
    end
end

#Defines a function using dlsym to obtain a function from dlsym.
macro get_c_fun(lib, to_name, from_fun)
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
  c_sym = Expr(:quote,{c_name},Any)
  fetching = nothing
  if isa(lib, Symbol) #TODO change things elsewhere so this can be removed.
      warn_once("Old style of getting foreign call. Depreciated.")
      fetching = :(dlsym($lib, $c_sym))
  else #Proper way.
#      assert( isa(lib, String) || #TODO quotenode confusion.
#              isa(lib, Expr) && lib.head == symbol("quote") )
      fetching = :($c_sym, $lib)
  end
  body = quote 
    $(Expr(:ccall, 
           cat(1, {fetching,
                   return_type, Expr(:tuple,input_types,Any)},
               argument_names), Any))
  end
  ret= Expr(:function,
            {Expr(:call, cat(1,{to_name},argument_names),Any), body},
            Any)
  return esc(ret)
end

end #module GetC

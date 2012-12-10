#  Jasper den Ouden 24-09-2012
# Placed in public domain.

module OJasper_Util
#Utilities
# NOTE/TODO: 
# * At least some of these have better alternatives in standard libs?
# * With the ones that don't, do...
using Base

export isnothing,
       @with,no_longer_with, 
       stream_from_string,find_index,
       last,thelast,butlast
export @case_of, @case,@cond,
       @compose, 
       @collect

export find_file_from_dirs

#----no more module stuff.

#Similar to `find_in_path`, but that function seems to look in /src/ too.
# `is_file_readable` giving me trouble with nonexistant directories.
function find_file_from_dirs(name::String, dir_list::Array)
    name[1] == '/' && return realpath(name)
    isfile(name) && return realpath(name)
    for prefix in dir_list
#     base = name #TODO more like `find_in_path`
#        path = strcat(prefix,"/",base,"/src/",name) #Was in `find_in_path`, 
# doesnt make sense to me. Also, `stat` doesnt like it.
#        is_file_readable(path) && return realpath(path)
        path = strcat(prefix,"/",name)
        is_file_readable(path) && return realpath(path)
    end
    return realpath(name)
end


#Depreciated. TODO remove.
isnothing(thing) = isequal(thing,nothing)

#Make and set a (local) variable and clean up transparently other.
# Abstraction leak: doesn't clean up if returning in middle.
# (Need unwind-protect)
macro with(setting, body)
  w_var = isa(setting,Expr) && is(setting.head,symbol("="))
 #Make a variable if none given.
  setting = w_var ? setting : :($(gensym()) = $setting) 
  assert(length(setting.args)==2, "Cannot set more than one thing at a time.
 (incorrect number of arguments in Expr of setting; $(length(setting.args)))")
  ret= gensym()
  return esc(quote 
              local $setting
              $ret = $body
              no_longer_with($(setting.args[1]), $ret)
             end)
end
#If ret not input argument, defaults to return it.
function no_longer_with{T,With}(with::With, ret::T) 
  no_longer_with(with)
  return ret
end

no_longer_with(stream::IOStream) = close(stream) #!

#Makes a stream with a string.
function stream_from_string(string::String)
  s = memio(length(string))
  write(s, string)
  seek(s,0) #Need to seek to start.
  return s
end
string_from_stream() = memio() #Which is a IOStream, which has a (todo name it

#Find an index that `is` the same.(TODO doesn't already exist?)
function find_index{T}(arr::Array{T,1},find::T)
  for i = 1:length(arr)
    if is(arr[i],find)
      return i
    end
  end
  return 0
end

last(v) = v[length(v)]
thelast(v, n::Integer) = v[1+length(v)-n:]
thelast(v)             = thelast(v,1)
butlast(v, n::Integer) = v[1:length(v)-n]
butlast(v) = butlast(v,1)

#'Case of something'. #TODO elseif? (layout in Julia is annoying..)
macro case_of(value, of, clauses) 
  assert(is(clauses.head, :block))
  var = gensym()
  function case_fun(clause_1, clauses)
    if isa(clause_1, Expr)
      if is(clause_1.head, :line)
        return isempty(clauses) ? :nothing : case_fun(clauses[1],clauses[2:])
      end
      assert( is(clause_1.head, :if) || is(clause_1.head, symbol(":") ),
              "Improper clause, just `if` and `:` have $clause_1" )
      assert(length(clause_1.args) == 2, 
             "Improper clause ; wrong number of args TODO improveme")
      if is(clause_1.args[1], :default)
        return clause_1.args[2]
      else #NOTE/TODO this cond stuff is done slightly off due to 
           # Julia dealing with `+` vs `||` and such inconsistently.
        function cond_of_raw(input) #Can only be a 'bare value'
          Expr(:call, {of, var, input}, Any)
        end
        function cond_of(val::Expr) #Can also be a list of values.
          if val.head== :call && val.args[1]== :|
            Expr(:||, map(cond_of, val.args[2:]), Any)
          else
            cond_of_raw(val)
          end
        end
        cond_of(val) = cond_of_raw(val)

        return :($(cond_of(clause_1.args[1])) ? $(clause_1.args[2]) :
                 $(isempty(clauses) ? :nothing : #Continue if needed.
                                      case_fun(clauses[1],clauses[2:])))
      end
    else
      isempty(clauses) ? :nothing : case_fun(clauses[1],clauses[2:])
    end
  end
  return esc(quote
    $var = $(value)
    $(case_fun(clauses.args[1], clauses.args[2:]))
  end)
end
#Run the clause with the value `isequal` to the given value, clauses are in 
# a `begin ... end` block, each clause may be `if value body... end` or
# `value : body...`
#(use `case_of` for something else than `isequal`) 
macro case(value, clauses)
  esc(:(@case_of $value isequal $clauses))
end    
#Runs first clause to be true. Clauses written identically as `case`
macro cond(clauses) #TODO it whines?
  esc(:(@case_of true && $clauses))
end
#Written as `cond`, but instead each condition that is true is executed, not
# just the first.
macro each_cond(clauses)
  assert(is(clauses.head, :block), "Not a block.")
  function when_clause (c)
    if !isa(c,Expr)
      return :nothing
    end
    assert( is(c.head, symbol(":")), "Clause Expr not `:`")
    assert( length(c.args)==2, "Clause Expr has wrong number of arguments." )
    :($(c.args[1]) ? $(c.args[2]) : nothing)
  end
  return esc(Expr(:block, map(when_clause, clauses.args),Any))
end

#Composes functions. 
macro compose(args...)
    assert(isa(args, Tuple))
    call(list, x) = (isempty(list) ? x : Expr(:call,{list[1],call(list[2:],x)},Any))
    return :(x -> $(call(args,:x)))
end
#TODO curry,rcurry

#Convenient way to make a collector. 
#NOTE: to use or not too... saves symbols, but also a dependency/unfamliar?
macro collect(args...)
    assert(isa(args, Tuple))
    assert(length(args)<=3)
    
    fun(a::())            = (gensym(),:collect, :nothing)
    fun(a::(Expr,))       = (gensym(),:collect, a[1])
    fun(a::(Symbol,Expr)) = (a[1],:collect, a[2])
    fun(a::(Symbol,Symbol,Expr)) = a

    list_var,collect_fun,body = fun(args)
    non_nothing_fun = symbol("$(collect_fun)_non_nothing")
    return esc(quote
        $list_var = {}
        $(Expr(:call, {collect_fun,:x},Any)) = push($list_var,x)
        $(Expr(:call, {non_nothing_fun,:x},Any)) = push($list_var,x)
        $(Expr(:call, {non_nothing_fun,:(x::Nothing)},Any)) = $list_var
        $body
        $list_var
    end)
end

end #module JasperUtil
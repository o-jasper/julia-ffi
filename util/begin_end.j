#
#  Copyright (C) 02-09-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

#NOTE: in development extra much(actually basically everything here is...)

#Macro that allows you to write stuff as a function, and it will turn it into
# stuff with $(name)_begin(context..), $(name)_end(context..),
# $(name)_enter_first(context, ..., # $(name)_enter(context,...)

# Depends on util/util.j (@case)

do_to_dict = ObjectIdDict()

#Flattens the whole thing, returns (sortah raw) stuff for @begin_end
function begin_end_fun(context, caller::Symbol, expr::Expr)
  do_to = get(do_to_dict, caller, nothing) #TODO move it.
  assert(!is(do_to,nothing), "`begin_end` mode $caller is not defined")

  if expr.head == :block
    ret = {}
    for a in expr.args
      push(ret, begin_end_fun(context, caller, a))
    end
    return  Expr(:block, ret,Any)
  end
#NOTE/TODO taking apart the expression slight too confusing.
# make a @destructure_expr in util/util.j
#This indicates that the thing has attributes `tag(attributes)(stuff,in,it)`
  has_attributes = (expr.head== symbol(".")) 
 #Top is the expression with the name, and if it has_attributes, those as 
 # arguments
  top = (has_attributes ? expr.args[1] : expr) 
  assert( isa(top, Expr) )
  assert(isa(top,Expr) && top.head == :call)
  name = top.args[1]
  args = (has_attributes ? (expr.args[2].head==:tuple ? 
                            expr.args[2].args : {expr.args[2]})
                         : expr.args[2:])
  #Makes the macrocall that provides the functionality this needs.
 mk_mcall(which,input)  = 
      Expr(:macrocall, {caller, esc(name), which,context, input}, Any)
  
  begin_ret = gensym()
  the_begin = :($begin_ret = 
                $(mk_mcall(:b, has_attributes ? top.args[2] : nothing)))
  the_middle = {}
#TODO probably won't want to do it with everything...
  function push_a(a::Expr)
    if a.head!=:call || !contains(do_to, a.args[1])
      push(the_middle,a)  #Not one of the things with begin-end.
    else
      append!(the_middle, begin_end_fun(context,caller, a))
    end
  end
  push_a(a)       = push(the_middle, mk_mcall(:m,a))
  for a in args[2:]
    push_a(a)
  end
  the_end = mk_mcall(:e, begin_ret)
  return cat(1, {the_begin}, the_middle, {the_end})
end

#Allows stuff like HTML or XML to be used with
macro begin_end(context, caller, expr)
  assert(isa(expr,Expr), "$expr is not an expression, begin_end does not\
 make sense.")
  context_var = gensym()
  mk_mcall(which,input)  = 
      Expr(:macrocall, {caller, nothing, which,nothing,input}, Any)
  quote 
    $context_var = $(mk_mcall(:beb, context))
#context_begin($context)# TODO
   #If block given, becomes list of them appended.
    $(Expr(:block, begin_end_fun(context_var, caller, expr), Any))
    $(mk_mcall(:bee, context_var))
  end
end

#List of html stuff.
const html_sym_list = {
:a,:abbr,:acronym,:address,:applet,:are,
:b,:bas,:basefon,:bdo,:big,:blockquote,:body,:b,:button,
:caption,:center,:cite,:code,:co,:colgroup,
:dd,:del,:dfn,:dir,:div,:dl,:dt,
:em,
:fieldset,:font,:form,:fram,:frameset,
:h1,:head,:h,:html,
:i,:iframe,:im,:inpu,:ins,
:kbd,
:label,:legend,:li,:lin,
:map,:menu,:met,
:noframes,:noscript,
:object,:ol,:optgroup,:option,
:p,:para,:pre,
:q,
:s,:samp,:script,:select,:small,:span,:strike,:strong,:style,:sub,:sup,
:table,:tbody,:td,:textarea,:tfoot,:th,:thead,:title,:tr,:tt,
:u,:ul,
:var,
:xmp}
#Add stuff allowed for html.
assign(do_to_dict, html_sym_list, :html_caller)

#IOstreams are ok as contexts as themselves.
html_context_init(io::IOStream) = io
html_context_finish(io::IOStream) = nothing #User has ownership of stream.

#Direct stream implementation of (basic)html.
html_begin(context_stream::IOStream, name::String,args::Nothing) = #!
    write(context_stream,"<$name>")
html_begin(context_stream::IOStream, name::String,args) = #!
    write(context_stream,"<$name $args>")
html_middle(context_stream::IOStream,input) =
    write(context_stream, "$input")
function html_middle(context_stream::IOStream,input::Symbol)
#  assert( contains({},input), "Don't recognize") #TODO check it..
  write(context_stream, "<$input />")
end
html_end(context_stream::IOStream, name::String) =
    write(context_stream, "$</$name>")
#TODO could make it indent with an object made with a stream+something.

macro html_caller(name,which, context, input)
  return esc(@case which begin
               :beb : :(html_context_init($input))
               :bee : :(html_context_finish($input))
               :b   : :(html_begin($context,$("$name"),$input))
               :m   : :(html_middle($context,$input))
               :e   : :(html_end($context,$("$name")))
      end)
end

macro html(context, expr)
  return :(@begin_end $context html_caller $expr)
end

#TODO try it...

type HtmlContext
  stream::IOStream #OStream?
  owns::Bool
  indent::String #TODO Actually implement.
end

HtmlContext(stream::IOStream, owns::Bool) =
    HtmlContext(stream,owns,"  ")

html_context_init(file::String) = 
    HtmlContext(open(file,"w"), true)

function space_string(n::Integer) #TODO better.
  str = ""
  for i= 1:n
    str = "$str "
  end
  return str
end

html_context_init(with::(String,String)) = 
    HtmlContext(open(with[1],"w"), true, with[2])
html_context_init(with::(String,Integer)) =
    HtmlContext(with[1],true, space_string(with[2]))

html_context_init(with::(IOStream,Bool)) =
    HtmlContext(with[1],with[2])
html_context_init(with::(IOStream,Bool,String)) =
    HtmlContext(with[1],with[2], with[3])
html_context_init(with::(IOStream,Bool,Integer)) =
    HtmlContext(with[1],with[2], space_string(with[3]))

html_context_init(context::HtmlContext) = context
html_context_finish(context::HtmlContext) = 
    context.owns ? close(context.stream) : nothing

#
#  Copyright (C) 01-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

module Treekenize

import Base.*

export treekenize, TExpr #Function for making trees itself.
#Each element needs these to know what to do.
export el_head, el_start,el_end,el_seeker

#Some extra transformations.(might move to other module)
export infix_syms, combine_heads

export ConvenientStream

# --- end module stuff

type ConvenientStream #TODO not quite the right place to put this.
    stream::IOStream
    line::String
    line_n::Int32
end
ConvenientStream(stream::IOStream) = ConvenientStream(stream,"",int32(0))
#Pass on @with duties.
no_longer_with(cs::ConvenientStream) = no_longer_with(cs.stream)

#TODO counting newlines shouldn't be too hard..
function forward(cs::ConvenientStream, n::Integer)
    if n>length(cs.line)
        cs.line = readline(cs.stream)[n-length(cs.line):]
    else
        cs.line = cs.line[n+1:]
    end
    return nothing
end
function readline(cs::ConvenientStream)
    cs.line_n += 1
    cs.line = "$(cs.line)$(readline(cs.stream))"
end

type TExpr
    head
    body
end

#
treekenize(stream::ConvenientStream, seeker::Nothing, end_str,
           limit_n::Integer, max_len::Integer) = end_str
function treekenize(stream::ConvenientStream, seeker::Function, end_str,
                    limit_n::Integer, max_len::Integer)
    new_seeker = seeker(stream,end_str)
    return treekenize(stream, new_seeker, el_end(new_seeker),
                      limit_n,max_len)
end

#Turns a stream into a tree of stuff.
function treekenize(stream::ConvenientStream, seeker::Array, end_str,
                    limit_n::Integer, max_len::Integer)
    list = {}
    n=0
    readline(stream)
    while n< limit_n
        pick = nothing
        min_s = typemax(Int32)
        min_e = 0
        search_str = stream.line
        for el in seeker
            s,e = search(search_str, el_start(el))
            if s!=0 && s< min_s
                pick = el
                min_s = s
                min_e = e
                if min_s+max_len < length(search_str)
                    search_str =  search_str[1:min_s+max_len]
                end
            end
        end
        s,e = search(search_str, end_str)

        if s!=0 && s<min_s #Ended before starting symbol.
            n=0
            if s>1
                push(list, search_str[1:s-1])
            end
            stream.line = stream.line[e:]
            return list #Go up a level.
        elseif pick==nothing #got nothing.
            n+=1
            readline(stream)
        else #Got new branch.
            n=0
            if min_s>1
                push(list, stream.line[1:min_s-1]) #Push what is here.
            end
            stream.line = stream.line[min_e:] #Skip to it.
           #Push branch.
            push(list, TExpr(el_head(pick),
                             treekenize(stream, el_seeker(seeker,pick),
                                        el_end(pick), 
                                        limit_n, max_len)))
        end
    end
    #TODO failed to end everything, this is potentially an error!
    #Which line failed?
    return list
end

treekenize(stream::IOStream, seeker::Array, end_str,
           limit_n::Integer, max_len::Integer) = 
    treekenize(ConvenientStream(stream), seeker, end_str, limit_n,max_len)

el_head{T}(el::T) = el_start(el)

#Some basic elements.
el_start{End,Seeker}(el::(String,End,Seeker))  = el[1]
el_end{End,Seeker}(el::(String,End,Seeker))    = el[2]
el_seeker{End,Seeker}(got, el::(String,End,Seeker)) = el[3]

el_start(el::(String,String))      = el[1]
el_end(el::(String,String))        = el[2]
el_seeker(got,el::(String,String)) = got

## Some basic transformations to apply afterward.

qualifies(w, x)           = isequal(w,x)
qualifies(w::Array, x)    = contains(w,x)
qualifies(w::Function, x) = w(x)

type All end
qualifies(w::Type{All}, x) = true

#Remove any duplicates in sequence.
function remove_sequential_duplicates(list, which)
    list = {}
    for i = 1:length(list)-1
        if !(qualifies(which,list[i]) && isequal(list[i],list[i+1]))
            push(list, list[i])
        end
    end
    push(list, list[length(list)])
    return list
end
remove_sequential_duplicates(list) = remove_sequential_duplicates(list,All)

function remove_from()

end

#Detect infix and prefix notation. Symbols are in-order.
infix_syms(thing, symbols) = thing
function infix_syms(str::String, symbols)
    if isempty(symbols)
        return str
    end
    name,head = (isa(symbols[1],Tuple) ? symbols[1] : (symbols[1],symbols[1]))
    list = split(str,name)
    return infix_syms(length(list)>1 ? 
                      (head==nothing ? list : TExpr(head,list)) : str,
                      symbols[2:])
end
infix_syms{T}(list::Array{T,1}, symbols) =
    map((el)->infix_syms(el,symbols), list)

function infix_syms(tree::TExpr, symbols)
    if !isa(tree.body, Array)
        return tree
    end
    list = {}
    for el in tree.body
        push(list, infix_syms(el,symbols))
    end
    return TExpr(tree.head,list)
end

function combine_heads{T}(in_list::Array{T,1}, symbols)
    list = {}
    for el in in_list
        if isa(el, TExpr) && contains(symbols, el.head)
            append!(list, el.body)
        else
            push(list, el)
        end
    end
    return list
end

function combine_heads(tree::TExpr, symbols)
    list = {}
    for el in tree.body
        push(list, isa(el,TExpr) ? combine_heads(el, symbols) : el)
    end
    if contains(symbols, tree.head)
        list = combine_heads(list, symbols)
        return TExpr(symbols[1], list)
    end
    return TExpr(tree.head,list)
end

end #module Treekenize

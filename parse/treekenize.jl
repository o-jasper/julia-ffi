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
export none_incorrect
#Each element needs these to know what to do.
export el_head, el_start,el_end,el_seeker

#Some extra transformations.(might move to other module)
#export infix_syms, combine_heads,remove_heads, remove_heads_1

export ConvenientStream

# --- end module stuff

type ConvenientStream #TODO not quite the right place to put this.
    stream::IOStream
    line::String
    line_n::Int64
end
ConvenientStream(stream::IOStream) = ConvenientStream(stream,"",int64(0))
#Pass on @with duties.
no_longer_with(cs::ConvenientStream) = no_longer_with(cs.stream)

#TODO add counting newlines to ConvenientStream.
#function forward(cs::ConvenientStream, n::Integer)
#    if n+1>=length(cs.line)
#        readline(cs)
#    end
#    cs.line = cs.line[n+1:]
#    return nothing
#end
function readline(cs::ConvenientStream)
    cs.line_n += 1
    cs.line = "$(cs.line)$(readline(cs.stream))"
end

type TExpr
    head
    body
end

treekenize(stream::ConvenientStream, seeker::Nothing, end_str,
           limit_n::Integer, max_len::Integer) = end_str
function treekenize(stream::ConvenientStream, seeker::Function, end_str,
                    limit_n::Integer, max_len::Integer)
    new_seeker = seeker(stream,end_str)
    return treekenize(stream, new_seeker, el_end(new_seeker),
                      limit_n,max_len)
end

type IncorrectEnd
    initial_n::Int64 #Where it started.
    incorrect_n::Int64 #Where it ended with an incorrect ending symbol.
    
    correct_end
    got
end

#TODO some bug, seems to mysteriously skipping over the info i need. 
#Printing all that is skipped doesnt show it, nothing else is using the stream...

#Turns a stream into a tree of stuff.
function treekenize(stream::ConvenientStream, which::(Array,Array), end_str,
                    limit_n::Integer, max_len::Integer)
    seeker,not_incorrect = which
    list = {}
    n=0
    initial_n = stream.line_n
    readline(stream)
    while n< limit_n
        pick = nothing
        min_s = typemax(Int64)
        min_e = 0
        search_str = copy(stream.line) #Not really needed(presumably..)
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
        search_str = search_str[1:s-1] #Warning about this guy.
        assert(s==0 || s<e)
      #Look for spurious enders.
        for el in not_incorrect
            s2,e2 = search(search_str, el)
            #Shouldnt be inside subtree, that might be allowed.
            if s2!=0 && min_e!=0 && s2<min_s 
                throw(IncorrectEnd(initial_n, stream.line_n, end_str, el))
            end
        end
        
        if s!=0 && s<min_s #Ended before some subtree starting symbol.
            n=0
            if s>1
                push(list, search_str) #[1:s-1] (already done)
            end
#            println(e, '|',stream.line[1:e],'|')
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
#            println(min_e, '|',stream.line[1:min_e],'|')
            stream.line = stream.line[min_e:] #Skip to it.
           #Push branch.
            push(list, TExpr(el_head(pick),
                             treekenize(stream, el_seeker(which,pick),
                                        el_end(pick), 
                                        limit_n, max_len)))
        end
    end
    #TODO failed to end everything, this is potentially an error!
    #Which line failed?
    error("How did i get here?")
    return list
end

treekenize(stream::IOStream, which::(Array,Array), end_str,
           limit_n::Integer, max_len::Integer) = 
    treekenize(ConvenientStream(stream), which, end_str, limit_n,max_len)

#not_incorrect defaults to not checking anything.
treekenize{T}(thing::T, seeker::Array, end_str, 
              limit_n::Integer, max_len::Integer) =
    treekenize(thing, (seeker,{}), end_str, limit_n,max_len)

#If _all_ the given seekers may not be present incorrectly, this tries to
# make the list to detect it.
function none_incorrect(seeker::Array)
    list = {}
    for el in seeker
        if isa(el,Tuple) && length(el)>=2 && isa(el[2],String)
            push(list, el[2])
        end
    end
    return list
end

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

function remove_heads_1{T}(in_list::Array{T,1}, head_symbols)
    list = {}
    for el in in_list
        if isa(el, TExpr) && contains(head_symbols, el.head)
            append!(list, el.body)
        else
            push(list, el)
        end
    end
    return list
end
#Remove heads of given kinds
function remove_heads(tree::TExpr, head_symbols)
    list = {}
    for el in tree.body
        push(list, remove_heads(el, head_symbols))
    end
    list = remove_heads_1(list, head_symbols)
    return TExpr(tree.head, list)
end
remove_heads{T}(tree::Array{T,1}, symbols) =
    remove_heads_1(map(el->remove_heads(el,symbols), tree), symbols)
remove_heads(tree, symbols) = tree

#Put heads of given kinds together.
function combine_heads(tree::TExpr, head_symbols) 
    list = {}
    for el in tree.body
        push(list, isa(el,TExpr) ? combine_heads(el, head_symbols) : el)
    end
    if contains(head_symbols, tree.head)
        list = remove_heads_1(list, head_symbols)
        return TExpr(head_symbols[1], list)
    end
    return TExpr(tree.head,list)
end
combine_heads(tree, symbols) = map(el->combine_heads(el,symbols),tree)

end #module Treekenize

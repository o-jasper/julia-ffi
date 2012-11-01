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

export treekenize #Function for making trees itself.
#Each element needs these to know what to do.
export el_head, el_start,el_end,el_seeker

#Some extra transformations.(might move to other module)
export remove_sequential_duplicates, infix_syms

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

#
treekenize(stream::ConvenientStream, seeker::Nothing, end_str,
           limit_n::Integer, max_len::Integer, head) = end_str
function treekenize(stream::ConvenientStream, seeker::Function, end_str,
                    limit_n::Integer, max_len::Integer, head)
    new_seeker,head = seeker(stream,end_str)
    return {head, treekenize(stream, new_seeker, el_end(new_seeker),
                             limit_n,max_len, nothing)}
end

treekenize(stream::ConvenientStream, seeker::Array, end_str,
           limit_n::Integer, max_len::Integer) = 
    treekenize(stream, seeker, end_str, limit_n,max_len, :top)

#Turns a stream into a tree of stuff.
function treekenize(stream::ConvenientStream, seeker::Array, end_str,
                    limit_n::Integer, max_len::Integer, head)
    list = {head}
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
        s,e = search(stream.line, end_str)
        if s!=0 && s<min_s #Ended before starting symbol.
            n=0
            if s>1
                push(list, stream.line[1:s-1])
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
            push(list, treekenize(stream, el_seeker(seeker,pick),
                                  el_end(pick), 
                                  limit_n, max_len, el_head(pick)))
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
function remove_sequential_duplicates(tree, which)
    list = {}
    for i = 1:length(tree)-1
        if !(qualifies(which,tree[i]) && isequal(tree[i],tree[i+1]))
            push(list, tree[i])
        end
    end
    push(list, tree[length(tree)])
    return list
end
remove_sequential_duplicates(tree) = remove_sequential_duplicates(tree,All)

#Detect infix and prefix notation. Symbols are in-order.
infix_syms_list(str::String, symbols::Array) =
    !isempty(symbols) ? infix_syms_list(split(str,symbols[1]), symbols[2:]) :
                        str

infix_syms_list(list::Array{String,1}, symbols::Array) =
    !isempty(symbols) ? map((el) -> infix_syms_list(el, symbols), list)
                        list

#Does it recursively
infix_syms(tree, symbols) = infix_syms_list(tree,symbols
infix_syms(tree::Array, symbols) = map((el) -> infix_syms(el,symbols), tree)

end #module Treekenize

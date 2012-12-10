#
#  Copyright (C) 01-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

module Treekenize

using Base
import Base.readline

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

function forward(cs::ConvenientStream, n::Integer)
#    print("|",cs.line[1:n])
    cs.line = cs.line[n:]
end
function readline(cs::ConvenientStream)
    cs.line_n += 1
    add_line = readline(cs.stream)
#    print(add_line, "|")
    cs.line = "$(cs.line)$add_line"
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
                assert( length(search_str) == s-1 )
                push(list, search_str) #[1:s-1] (already done)
            end
            forward(stream, e)
            return list #Go up a level.
        elseif pick==nothing #got nothing.
            n+=1
            readline(stream)
        else #Got new branch.
            n=0
            if min_s>1
                push(list, stream.line[1:min_s-1]) #Push what is here.
            end
            forward(stream, min_e)
           #Push branch.
            push(list, TExpr(el_head(pick),
                             treekenize(stream, el_seeker(which,pick),
                                        el_end(pick), 
                                        limit_n, max_len)))
        end
    end
    #TODO failed to end everything, this is potentially an error!
    # Problem is that i dont see a good way to check if it is eof.. (no mention)
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

#Infix on TExprs is heads
texpr_infix(thing, heads) = thing
texpr_infix(tree::TExpr, heads) = TExpr(tree.head, texpr_infix(tree.body))

function texpr_infix(tree::Array, heads)
    #TODO
end

end #module Treekenize
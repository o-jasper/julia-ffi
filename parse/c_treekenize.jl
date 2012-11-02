#
#  Copyright (C) 01-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

import OJasper_Util.*

bin_el(str::String,sym::Symbol) = (str,sym,nothing)
bin_el(str::String) = bin_el(str,symbol(str))

c_treekenizer_set =
    {("/*", "*/"),("//", "\n"),("#","\n"),
     ("(",")"),("[","]"),  #Order matters!
#     bin_el(";"), #Not this one, it is where treekenize stops on.
#     bin_el(","), bin_el(";"),  #Not these, infixing does it from strings.
#     bin_el(" ", :white), bin_el("\t", :white),bin_el("\n", :white),
#     bin_el("+"), bin_el("-"), bin_el("*"),bin_el("/"),
#     bin_el("||"),bin_el("&&"),bin_el("!"),
#     bin_el("|"), bin_el("&"), bin_el("~"),
     bin_el(":"), bin_el("case")}

#The later, the higher the precidence.
c_infixes = [" ","\t","\n", ",",
             "!","||","&&",
             "~","|", "&", "|",
             "+","-", "/", "*"]

function c_treekenize(s::ConvenientStream, try_n::Integer)
    tree = treekenize(s, c_treekenizer_set, ";", try_n,2)
    tree = infix_syms(tree, c_infixes)
    #TODO should have to do it twice..
    tree = combine_heads(tree, [" ","\t","\n"]) 
    tree = combine_heads(tree, [" ","\t","\n"])
    return tree
end

function encode_type{T}(arr::Array{T,1})
    #TODO map..
    
end

function encode(tree::TExpr)
    @case tree.head begin
        if "#" | "//" | "/*" #Comments and macros currently ignored
        end
    end
end
function encode{T}(arr::Array{T,1})
    if isempty(arr)
        return nothing
    end
    @case arr[1] begin
        if "typedef"
            assert( length(arr)>=3 )
            :(typealias $(last(arr)) $(encode_type(arr[2:length(arr)-1])))
        end
        if ""
            encode(arr[2:])
        end
        if "__attribute__" #(hmm may want it..)
            encode(arr[3:])
        end
        if default #(that is a keyword)
            if isa(arr[1], TExpr)
                return quote
                    $(encode(arr[1]))
                    $(encode(arr[2:]))
                end
            end
            #Assume it is a type.
            for i = 2:length(arr)
                if isa(arr[i], TExpr)
                    if arr[i].head=="("
                        Expr(symbol(arr[1]), .., encode_type(arr[1:i-1]))
                    end
                end
            end
        end
    end
end
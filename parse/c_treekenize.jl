#
#  Copyright (C) 01-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

#NOTE: extra messy

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
c_infixes = [" ","\t","\n", ",", "=",
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
c_treekenize(s::IOStream, try_n::Integer) = 
    c_treekenize(ConvenientStream(s), try_n)
#TODO `encode` is poor naming..

function encode_number_type(arr, signed,unsigned,long)
    assert( !(signed && unsigned) )
    if isempty(arr)
        assert(!signed)
        return unsigned ? Uint32 : error("Invalid number")
    end
    @case arr[1] begin
        if "float" | "double"
            assert(!signed || !unsigned || !long)
            return arr[1]=="float" ? Float32 : Float64
        end
        "unsigned" : encode_number_type(arr[2:], signed,true,long)
        "signed"   : encode_number_type(arr[2:], true,unsigned,long)
        "char"  : (unsigned ? Uint8 : Int8)
        "short" : (unsigned ? Uint16 : Int16)
        "int"   : (unsigned ? Uint32 : Int32)
        if "long" 
            if length(arr)==1 
                return long ? (unsigned ? Uint128 : Int128) : 
                              (unsigned ? Uint64 : Int64)
            end
            assert( !long || arr[2]=="int" )
            encode_number_type(arr, signed,unsigned, true)
        end
        default : error("Invalid signed")
    end
end

function encode_type{T}(arr::Array{T,1})
    #TODO map..
    if isempty(arr)
        return arr
    end
    @case arr[1] begin
        if "const" | "extern" | "inline"
            encode_type(arr[2:])
        end
        if "signed" | "unsigned" | "char" | "short" | "int" | "long" |
            "float" | "double"
            encode_number_type(arr, false,false,false)
        end
        "int8_t" : Int8 #More straightforward integer types.
        "int16_t" : Int16
        "int32_t" : Int32
        "int64_t" : Int64
        "int128_t" : Int128

        "uint8_t" : Uint8
        "uint16_t" : Uint16
        "uint32_t" : Uint32
        "uint64_t" : Uint64
        "uint128_t" : Uint128
        
        default : arr
    end
end

function encode(tree::TExpr)
    @case tree.head begin
        if "#" | "//" | "/*" #Comments and macros currently ignored
        end
    end
end

type Dunno
    what
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
        if "" | "struct" #TODO some of these
            encode(arr[2:])
        end
        if "__attribute__" #(hmm may want it..)
            encode(arr[3:])
        end
        if default #(that is a keyword)
            l = last(arr)
            if !isa(l, TExpr)
                return Dunno(arr)
            end
            @case l.head begin
                if "("
                    
                end
                if "{"
                    
                end
            end
            
            #Assume it is a type.
            for i = 2:length(arr)
                if isa(arr[i], TExpr)
                    if arr[i].head=="("
                        @case arr[i-1] begin
                            ""
                        return {symbol(arr[1-1]), arr[i].body, 
                                encode_type(arr[1:i-2])}
                    end
                end
            end
        end
    end
end

encode(s::ConvenientStream) = encode(c_treekenize(s, 10))
encode(s::IOStream) = encode(c_treekenize(s, 10))
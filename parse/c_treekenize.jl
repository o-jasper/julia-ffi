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
     ("(",")"),("[","]"),("{","}"),  #Order matters!
#     bin_el(";"), #Not this one, it is where treekenize stops on.
#     bin_el(","), bin_el(";"),  #Not these, infixing does it from strings.
#     bin_el(" ", :white), bin_el("\t", :white),bin_el("\n", :white),
#     bin_el("+"), bin_el("-"), bin_el("*"),bin_el("/"),
#     bin_el("||"),bin_el("&&"),bin_el("!"),
#     bin_el("|"), bin_el("&"), bin_el("~"),
     bin_el(":"), bin_el("case")}

#The later, the higher the precidence.
c_infixes = [" ","\t","\n", ";", ",", "=",
             "!","||","&&",
             "~","|", "&", "|",
             "+","-", "/", "*"]

function c_treekenize(s::ConvenientStream, try_n::Integer)
    tree = treekenize(s, c_treekenizer_set, ";", try_n,2)
    tree = infix_syms(tree, c_infixes)
    tree = remove_heads(tree, [" ","\t","\n"])
    tree = remove_isequal(tree, "")
    return tree
end
c_treekenize(s::IOStream, try_n::Integer) = 
    c_treekenize(ConvenientStream(s), try_n)
#TODO `encode` is poor naming..

function encode_int_type(arr, signed,unsigned,long)
    assert( !(signed && unsigned) )
    if isempty(arr)
        assert(!signed)
        return unsigned ? Uint32 : error("Invalid number")
    end
    cont_at(i) = encode_int_type(arr[i:], signed,unsigned,long)
    @case arr[1] begin
        "__attribute__" : continue_at(3)
        "__restrict"    : continue_at(2)
        "unsigned" : encode_int_type(arr[2:], signed,true,long)
        "signed"   : encode_int_type(arr[2:], true,unsigned,long)
        "char"  : (unsigned ? Uint8 : Int8)
        "short" : (unsigned ? Uint16 : Int16)
        "int"   : (unsigned ? Uint32 : Int32)
        if "long" 
            if length(arr)==1 
                return long ? (unsigned ? Uint128 : Int128) : 
                              (unsigned ? Uint64 : Int64)
            end
            assert( !long || arr[2]=="int" || arr[2]=="long", arr)
            encode_int_type(arr[2:], signed,unsigned, true)
        end
        default : error("Invalid signed")
    end
end

type CStruct
    name::String
    body
end
type CUnion
    name::String
    entries::Dict{String,Any}
end

encode_type(str::String) = str

function remove_isequal(arr, eql)
    new_arr = {}
    for el in arr
        if !isequal(el,eql)
            push(new_arr,el)
        end
    end
    return new_arr
end

encode_type{T}(arr::Array{T,1}) = encode_type(arr, true)
function encode_type{T}(arr::Array{T,1}, cleanup::Bool)
    #TODO map..
    if isempty(arr)
        return arr
    end
    if cleanup
        arr = remove_isequal(arr,"")
    end
    
    function structlike_start()
        name,body_expr = isa(arr[2],String) ? (arr[2],arr[3]) : ("",arr[2])
        assert(isa(body_expr, TExpr), arr)
        assert(body_expr.head=="{")
        return  name,remove_isequal(body_expr.body, "")
    end
    
    @case arr[1] begin
        "__attribute__" : encode_type(arr[3:],false)
        "__restrict"    : encode_type(arr[2:],false)
        if "const" | "extern" | "inline"
            encode_type(arr[2:])
        end
        if "signed" | "unsigned" | "char" | "short" | "int" | "long"
            encode_int_type(arr, false,false,false)
        end
        "float" : Float32
        "double" : Float64
        
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
        
        "void" : Void
        
        if "struct" | "union"
            name,body = structlike_start()
            if isempty(body)
                return CStruct(name,{})
            end
            assert(body[1].head==";", (arr,body)) #Must be separated by those.
            return @case arr[1] begin
                "struct" : CStruct(name, map(encode, body[1].body))
                "union"  : CUnion(name,  map(encode, body[1].body))
            end
        end
        if "enum"
            name,body = structlike_start()
            if isempty(body)
                return CEnum(name,{})
            end
            entries = Dict{String,Any}()
            handle_entry(entry::String) = assign(entries, entry,:unknown) #!
            function handle_entry(entry::TExpr)
                assert(entry.head == "=" && length(entry.body)==2)
                assign(entries, entry.body[1],entry.body[2])
            end
            
            if isa(body[1], String) || body[1].head=="="
                handle_entry(body[1])
            else
                assert(body[1].head==",")
                map(handle_entry, body[1].body)
            end
            return CEnum(name, entries)
        end
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
type CExpr
    name
    args
    tp
end

type CVarType
    var
    tp
end

type CTypedef
    name
    tp
end

type CPointer
    cnt::Integer
    tp
end

function encode_args{T}(arr::Array{T,1})
    handle_var(var) = CVarType(last(var), encode_type(butlast(var)))
    function handle_var(var::TExpr)
        assert(var.head=="*", var) #Pointers, apparently.
        body = var.body
        assert(last(body)!="")
        i = length(body)-1
        while i>=1
            if body[i]!=""
                break
            end
            i-=1
        end
        cnt = 1 + length(body)-1 - i
        while i>=1 #No more empty ones.
            assert(body[i]!="")
            i-=1
        end
        return CVarType(last(var), CPointer(cnt,encode_type(butlast(body))))
    end
    
    #Toplevel comma. (Multiple items)
    if isa(arr[1], TExpr) && !(arr[1].head=="*")
        if arr[1].head==" "
            return encode_args(arr[1].body)
        end
        assert(length(arr)==1 && arr[1].head==",", arr)
        return map(handle_var, arr[1].body)
    elseif length(arr)==1
        assert(arr[1]=="void")
        return {}
    end
    return {handle_var(arr)}
end

encode{T}(arr::Array{T,1}) = encode(arr,true)
function encode{T}(arr::Array{T,1}, cleanup)
    if isempty(arr)
        return nothing
    end
    if cleanup
        arr = remove_isequal(arr, "")
    end
    last_el = last(arr)
    if arr[1]== "typedef"
        assert( length(arr)>=3 )
        return CTypedef(last_el, encode_type(arr[2:length(arr)-1]))
    end
    if isa(last_el, TExpr) && last_el.head=="("
        i = length(arr)-1
        name = arr[i]
        if name == "__attribute__" #Dont want these at end, try again.
            new_arr = append!(copy(arr[i:]), arr[1:i-1])
            return encode(new_arr,false)
        end
        assert(name!="")
        type_arr = arr[1:i-1]
        return CExpr(name, encode_args(last_el.body), encode_type(type_arr))
    elseif isa(last_el, String)
        CVarType(last_el,encode_type(butlast(arr)))
    end
end

encode(s::ConvenientStream) = encode(c_treekenize(s, 10))
encode(s::IOStream) = encode(c_treekenize(s, 10))

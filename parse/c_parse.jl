#
#  Copyright (C) 05-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

#TODO still bug, somehow eating ')' into symbols??

import OJasper_Util.*

bin_el(str::String,sym::Symbol) = (str,sym,nothing)
bin_el(str::String) = bin_el(str,symbol(str))

c_treekenizer_set =
    {("/*", "*/"),("//", "\n"),("#","\n"),
     ("(",")"),("[","]"),("{","}"),  #Order matters!
#     bin_el(";"), #Not this one, it is where treekenize stops on.
#Not these, infixing does it from strings.
#     bin_el(","), bin_el(";"),  
#     bin_el(" ", :white), bin_el("\t", :white),bin_el("\n", :white),
#     bin_el("+"), bin_el("-"), bin_el("*"),bin_el("/"),
#     bin_el("||"),bin_el("&&"),bin_el("!"),
#     bin_el("|"), bin_el("&"), bin_el("~"),
     bin_el(":"), bin_el("case")}

c_parse_top(s::IOStream) = c_parse_top(ConvenientStream(s))
c_parse_top(s::ConvenientStream) =
    c_parse_top(treekenize(s, c_treekenizer_set, ";", 10,2))

#TODO many utility-like functions..

function remove_isequal(arr, eql)
    new_arr = {}
    for el in arr
        if !isequal(el,eql)
            push(new_arr,el)
        end
    end
    return new_arr
end

function split_on_any(str::String, what)
    k=0
    list = Array(String,0)
    for i = 1:length(str)
        if contains(what,str[i])
            if k < i-1
                push(list, str[k+1:i-1])
            end
            k = i
        end
    end
    push(list, str[k+1:])
    return list
end
#Everything element that is a string is `split` with the argument `what`,
# and the whole thing is flattened.
function split_flatten{T}(arr::Array{T,1}, what)
    list = {} 
    for el in arr
        if isa(el,String)
            for el in split_on_any(el,what)
                if el!=""
                    push(list,el)
                end
            end
        else
            push(list,el)
        end
    end
    return list
end
#'Infix-notation' by producing a list of lists, where the lists were
# delimited by substrings in any strings in there.
function infix(arr::Array{Any,1}, what)
    list,cur = {},{}
    for el in arr
        if isa(el,String)
            here = copy(el)
            while !isempty(here)
                i,j = search(here, what)
                if i==0 #None found, add it whole to current.
                     push(cur,here)
                     break
                else #Found one, add to current, push to list, start new one.
                     push(cur, here[1:i-1])
                     push(list, cur)
                     cur = {}
                     here = here[j:]
                end
            end
        else
            push(cur,el)
        end
    end
    (!isempty(cur) ? push(list,cur) : nothing) #!
    return list
end
#Splits, but puts the thing splitted with in the list.
function split_pointers(arr::Array{Any,1}, split_on) 
    list = {}
    maypush(el) = (el!="" ? push(list,el) : nothing)
    for el in arr
        if isa(el, String)
            s = split(el, split_on)
            maypush(s[1])
            for se in s[2:]
                push(list, split_on)
                maypush(se)
            end
        else
            push(list,el)
        end
    end
    return list
end

function c_parse_int_type(arr, signed,unsigned,long)
    assert( !(signed && unsigned) )

    int_now() = @case long begin 
        0       : (unsigned ? Uint32  : Int32)
        1       : (unsigned ? Uint64  : Int64)
        2       : (unsigned ? Uint128 : Int128)
        default : error("Cant make integer longer.")
    end

    if isempty(arr)
        assert(!signed && unsigned)
        return int_now()
    end
    cont_at(i) = c_parse_int_type(arr[i:], signed,unsigned,long)
    
    @case arr[1] begin
        "__attribute__" : continue_at(3)
        "__restrict"    : continue_at(2)
        "unsigned" : c_parse_int_type(arr[2:], signed,true,long)
        "signed"   : c_parse_int_type(arr[2:], true,unsigned,long)
        "char"  : (unsigned ? Uint8 : Int8)
        "short" : (unsigned ? Uint16 : Int16)
        "int"   : int_now()
        if "long" 
            if length(arr)==1 
                return int_now()
            end
            assert( long==0 || arr[2]=="int" || arr[2]=="long", arr)
            c_parse_int_type(arr[2:], signed,unsigned, long+1)
        end
        default : error("Invalid int")
    end
end

type CExpr
    name
    args
    tp
end

type CStruct
    name::Symbol
    body
end
type CUnion
    name::Symbol
    body
end
type CPointer
    tp
    cnt::Int8
end
type CArr
    tp
    len::Int64
end

CPointer(tp,cnt::Integer) = CPointer(tp,int8(cnt))

type CVarType
    var
    tp
end

type CTypedef
    name
    tp
end

function c_parse_type(arr::Array{Any,1})
    if isempty(arr)
        return arr
    end
    while true
        @case arr[1] begin
            if "__attribute__"
                error("__attribute__ should have been stripped at this point.")
            end
            "__restrict" | "const" | "extern" | "inline" : (arr = arr[2:])
            default : break
        end
    end
    while length(arr)>=2 && arr[length(arr)-1]=="__attribute__"
        arr = butlast(arr,2)
    end
    if isempty(arr)
        return arr
    end
    
    i=length(arr) #Count pointers
    while i>=1
        if arr[i]!="*" 
            break
        end
        arr[i]=""
        i-=1
    end
    assert(i!=0)
    ptr_cnt = length(arr)-i
    arr = remove_isequal(arr, "")
    
    result = @case arr[1] begin
        if "signed" | "unsigned" | "char" | "short" | "int" | "long"
            c_parse_int_type(arr, false,false,0)
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
            
            i,name = (isa(arr[2], String) ? (3,symbol(arr[2])) : 
                                            (2,:unnamed))
            retval(body) = (arr[1]=="struct" ? CStruct(name,body) : 
                                               CUnion(name,body))

            struct = (i<= length(arr) ? arr[i] : :reference)
            if isa(struct, TExpr)
                assert(struct.head=="{")
                pass_arr = infix(struct.body, ";")
                retval(remove_isequal(map(c_parse_top, pass_arr), {}))
            else
                retval(struct)
            end
        end
        #TODO enums!
        default : arr
    end
    return ptr_cnt>0 ? CPointer(result,ptr_cnt) : result
end

function c_parse_args{T}(arr::Array{T,1})
    arr = infix(split_flatten(arr, " \t\n"), ",")
    if length(arr)==1 && length(arr[1])==1
        assert(arr[1][1]=="void")
        return {}
    else
        return map(c_parse_top, arr)
    end
end

type CAttribute
    visibility::Symbol
    noreturn_p::Bool
    const_p::Bool
    full
    thing
end
CAttribute() = CAttribute(:unknown,false,false, nothing,nothing)

function strip_attribute(arr)
    list = {}
    attr = CAttribute()
    i=1
    while i <= length(arr)
        if arr[i]=="__attribute__"
            here = arr[i+1]
            attr.full = here
            if isa(here, TExpr)
                assert( here.head=="(" && length(here.body)==1 &&
                        here.body[1].head=="(" )
                barr = here.body[1].body
                for j = 1:length(barr) in
                    @case barr[j] begin
                        if "visibility" 
                            assert(isa(barr[j+1], TExpr))
                            assert(length(barr[j+1].body)==1)
                            el= barr[j+1].body[1]
                            assert(isa(el, String) && el[1]=='"' && last(el)=='"')
                            attr.visibility = symbol(butlast(el)[2:])
                        end
                        "noreturn" : (attr.noreturn_p = true)
                        "const"    : (attr.const_p = true)
                        #"format" #Not sure if to 
                    end
                end
            end
            i+=2
        else
            push(list, arr[i])
            i+=1;
        end
    end
    return list, attr
end

type CHash #TODO bad name.
    note
    thing
end

function c_parse_top{T}(arr::Array{T,1})
    arr = split_flatten(arr, " \t\n")
    while !isempty(arr) && isa(arr[1], TExpr)
        assert(contains(["#","//","/*"], arr[1].head))
        if arr[1].head=="#"
            return CHash(arr[1],c_parse_top(arr[2:]))
        end
        arr = arr[2:]
    end
    if isempty(arr)
        return
    end
    assert(isa(arr[1],String), arr)
    arr = split_pointers(arr, "*")
    last_el = last(arr)
        
    if arr[1]=="typedef"
        return CTypedef(last_el, c_parse_type(arr[2:length(arr)-1]))
    end
    if isa(last_el, TExpr) 
        if last_el.head=="("
            i = length(arr)-1
            name = arr[i]
            if name == "__attribute__" #Dont want these at end, try again.
                new_arr = append!(copy(arr[i:]), arr[1:i-1])
                return c_parse_top(new_arr)
            end
            assert(name!="")
            type_arr,attr = strip_attribute(arr[1:i-1])
            attr.thing = CExpr(name, c_parse_args(last_el.body), c_parse_type(type_arr))
            return (isequal(attr.full, nothing) ? attr.thing : attr)
        elseif last_el.head=="[" #TODO more robust..
            pre_last = arr[length(arr)-1]
            assert(isa(pre_last,String))
            assert(length(last_el.body)==1 && isa(last_el.body[1],String) ||
                   isempty(last_el.body))
            return CVarType(symbol(pre_last), 
                            CArr(c_parse_type(butlast(arr,2)),
                                 isempty(last_el.body) ? 0 : parse_int(last_el.body[1])))
        end
    elseif isa(last_el, String)
        if length(arr)==2 && arr[1]=="struct"
            return CStruct(symbol(last_el), :reference)
        end
        return CVarType(symbol(last_el),c_parse_type(butlast(arr)))
    end
    error("Ended up here $arr $last_el")
end

#
#  Copyright (C) 12-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

import Base.*, OptionsMod.*
import GetC.*

type FFI_Info #info on how to FFI
    lib::Symbol #Variable with library.
    
    fun_namer
    
    tp_aliasses::Dict{Symbol,Any}
end
function FFI_Info(lib::Symbol, opts::Options) 
    @defaults opts namer = :auto
    return FFI_Info(lib, namer, Dict{Symbol,Any}())
end
FFI_Info(lib::Symbol) = FFI_Info(lib, @options)

fun_namer(namer::Symbol,   name::Symbol,args) = namer #There indicators belong to @get_c
fun_namer(namer::Function, name::Symbol,args) = namer(name,args)

#Allows you to tell it to not whine about an alias.
#function manual_alias(info::FFI_Info, name::Symbol, tp)
#    
#end
#manual_alias(info::FFI_Info, name::Symbol) = manual_alias(info,name, :manual_alias)

function ffi_top(expr::CTypedef, info)
    if !isa(expr.name,String) #TODO what is it?
        return nothing
    end
    name = symbol(expr.name)
    if isa(expr.tp, CStruct)
        
    end
    tp   = ffi_type(expr.tp, info)
    assign(info.tp_aliasses, tp, name) #Record it.
    return :(typealias $name $tp)
end
function ffi_top(expr::CExpr, info)
    name = symbol(expr.name)
    arglist = {name}
    for el in expr.args
        push(arglist, ffi_arg(el,info))
    end
    return :(@get_c_fun $(info.lib) $(fun_namer(info.fun_namer,name,arglist)) $(Expr(:call, arglist,Any))::$(ffi_type(expr.tp, info)))
end

ffi_arg(var::CVarType, info) = Expr(symbol("::"), {var.var, ffi_type(var.tp, info)},Any)

ffi_top(expr::CVarType, info) = nothing #Not doing globals at the moment.
#ffi_top(expr::CStruct) #Need a convention for these?
#ffi_top(expr::CUnion
#ffi_top(expr::CEnum)

ffi_type(tp::BitsKind, info) = tp #Already there(it figured it out itself)
function ffi_type(tp::UnionKind, info)
    assert(tp==Void)
    return tp
end
function ffi_type(tp::CPointer, info)
    ptr(tp,n) = (n>0 ? ptr(:(Ptr{$tp}), n-1) : tp)
    return ptr(ffi_type(tp.tp,info), tp.cnt)
end
#TODO
ffi_type(tp::CArr,info) = :(Ptr{$(ffi_type(tp.tp,info))})

function ffi_type(tp::CStruct, info)
    if isa(tp.body, Symbol)
        assert( tp.body== :reference )
        return :TODO_refer_to_struct #explicit mention that it is a struct.
    end
    list = {} #List of elements in there.
    for component in tp.body
        assert(isa(component, CVarType))
        push(list, Expr(symbol("::"), {component.var, ffi_type(component.tp, info)}, Any))
    end
    return Expr(symbol("type"), {tp.name, Expr(:block, list,Any)}, Any)
end

function ffi_type{T}(tp::Array{T,1}, info)
    assert( length(tp)==1 ) #Know no reason otherwise would happen.
    name = symbol(tp[1])
    assert( has(info.tp_aliasses, name), "Referrering to nonexistent type? $name")
    return name
end

#pretty print
function pprint(to::IOStream, e::Expr)
    name,args = (e.head==:call ? (e.args[1],e.args[2:]) : (e.head, e.args))
    @case name begin
        if symbol("typealias")
            tp = args[2]
            if tp.head==symbol("type") #TODO move this logic to 
                write(to, "type $(tp.args[1])\n")
#                assert( isa(tp.args[2], Expr) && tp.head==:block )
                for component in tp.args[2].args
                    write(to, "  ")
                    pprint(to, component)
                    write(to, "\n")
                end
                write(to, "end\n")
            else
                write(to, "typealias")
                for a in args
                    write(to," ")
                    pprint(to, a)
                end
                write(to,"\n")
            end
        end
        if :macrocall
            pprint(to,args[1])
            for a in args[2:]
                write(to," ")
                pprint(to,a)
            end
            write(to,"\n")
        end
        if symbol("type")
            #TODO
        end
        if symbol("::")
            pprint(to, args[1])
            write(to, "::")
            pprint(to, args[2])
        end
        if name
            pprint(to, name)
            write(to, "(")
            if !isempty(args)
                pprint(to,args[1])
                for a in args[2:]
                    write(to,",")
                    pprint(to,a)
                end
            end
            write(to,")")
        end
        default : error("Dont know what to do with head $name")
        
    end
    return nothing
end
pprint{T}(to::IOStream, thing::T) = print(to,thing)
pprint{T}(thing::T) = pprint(stdout_stream, thing)
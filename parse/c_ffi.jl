#
#  Copyright (C) 16-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

#TODO make it a module, export needed stuff.

using Base, OptionsMod
using GetC, PrettyPrint

#TODO more user control.
type FFI_Info #info on how to FFI
    lib_var::Symbol #Variable with library.
    on_file::String
    
    opts_fun::Function
#    fun_namer
#    file_namer
#    lib_namer
#    module_namer
    
    follow_unseen::Bool
    seen_files::Dict{String,Bool} #Which files have been seen.
    tp_aliasses::Dict{Symbol,Any}
    
    only_visibility
end
function FFI_Info(on_file::String, opts::Options)
    @defaults opts lib_var = :lib
    @defaults opts fun_namer = :auto only_visibility= {:default}
    @defaults opts follow_unseen = false

#    @defaults opts file_namer = (file)->"autoffi/$(basename(file)).jl"
#    @defaults opts lib_namer  = function (file)
#        name = split(basename(file), ".")[1] #TODO better.
#        return "lib$name"
#    end
#    @defaults opts module_namer = function(file)
#        name = split(basename(file), ".")[1] #TODO better.
#        return uppercase(name[1:2]) * name[2:] #NOTE: probably user will have to look..
#    end
    return FFI_Info(lib_var, on_file, 
                    fun_namer,file_namer,lib_namer,module_namer,
                    follow_unseen, Dict{String,Bool}(), 
                    Dict{Symbol,Any}(), 
                    only_visibility)
end
FFI_Info(on_file::String) = FFI_Info(on_file, @options)

fun_namer(namer::Symbol,   name::Symbol,args) = namer #There indicators belong to @get_c
fun_namer(namer::Function, name::Symbol,args) = namer(name,args)

#Allows you to tell it to not whine about an alias.
#function manual_alias(info::FFI_Info, name::Symbol, tp)
#    
#end
#manual_alias(info::FFI_Info, name::Symbol) = manual_alias(info,name, :manual_alias)

ffi_top{T}(expr::T, info) = ffi_pretop(expr,info)
function ffi_top(chash::CHash, info)
    expr = chash.note
    assert(contains(["#", "//", "/*"], expr.head) && 
           length(expr.body)==1 && isa(expr.body[1],String), expr)
    list = split(expr.body[1], "\"", true)
#    Are they always in the correct format for this? 
# TODO assert integer, filename, integer,integer
    src_file = list[2]
  #Read files not seen before.(if enabled.
    if info.follow_unseen && isfile(src_file) && !get(info.seen_files, src_file, false) 
        assign(info.seen_files, true, src_file)
        _ffi_header(src_file, info)
    end   
    return ffi_top(chash.thing, info)
end

function ffi_pretop(expr::CTypedef, info)
    name = expr.name
    if isa(expr.tp, CStruct)
        struct_elements = 
            Expr(:block, isequal(expr.tp.body, :reference) ? 
                           {} : map((el)->ffi_pretop(el,info), expr.tp.body),
                 Any)
        return Expr(symbol("type"), {name, struct_elements}, Any)
    else
        tp = ffi_type(expr.tp, info)
        assign(info.tp_aliasses, tp, name) #Record it.
        return :(typealias $name $tp)
    end
end
function ffi_pretop(expr::CExpr, info)
    name = symbol(expr.name)
    arglist = {name}
    for el in expr.args
        push(arglist, ffi_arg(el,info))
    end
    return :(@get_c_fun $(info.lib_var) $(fun_namer(info.fun_namer,name,arglist)) $(Expr(:call, arglist,Any))::$(ffi_type(expr.tp, info)))
end

ffi_arg(var::CVarType, info) = Expr(symbol("::"), {var.var, ffi_type(var.tp, info)},Any)

ffi_pretop(expr::CVarType, info) = 
    ffi_arg(expr,info)
ffi_pretop(expr::CStruct, info)  = 
    ffi_pretop(CTypedef(symbol("struct_$(expr.name)"),expr), info)
#ffi_pretop(expr::CUnion
#ffi_pretop(expr::CEnum)

ffi_pretop(expr::Nothing,info) = nothing

function ffi_pretop(expr::CAttribute, info)
    assert(!isequal(expr.full,nothing))
    if contains(info.only_visibility, expr.visibility) || isempty(info.only_visibility)
        return ffi_pretop(expr.thing, info)
    end
end

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

function ffi_type(tp::CFunPtr, info)
    :(FunPtr{$(tp.args), $(tp.ret), $(tp.level)})
end

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
#    assert( length(tp)==1, tp ) #Know no reason otherwise would happen.
    name = symbol(tp[1])
    assert( has(info.tp_aliasses, name), "Referring to nonexistent type? $name")
    return name
end

#To FFI code in data from.
function to_ffi{T}(from::T, info::FFI_Info, try_cnt::Integer)
    @collect begin
        fun(stream, x) = collect_non_nothing(ffi_top(x,info))
        to_cexpr(from,try_cnt,fun)
    end
end
to_ffi{T}(from::T, info::FFI_Info) = to_ffi(from, info, default_try_cnt)

#Inspect the thing and export the relevant symbol.
function find_exported(stream, thing)
    assert(isa(thing,Expr))
    args = thing.args
    @case thing.head begin
        if :macrocall
            assert(args[1] == symbol("@get_c_fun"), thing)
            return (args[3] == :auto ? args[4].args[1].args[1] : args[3])
        end
        if symbol("typealias") | symbol("type")
            return args[1]
        end
        default : error("I dont like eating $thing (bug)
at $stream")
    end
end

#To (via ffi)pretty printed.
function to_pprint{T}(from::T,info::FFI_Info, to::IOStream, try_cnt::Integer)
    function fun(stream, x)
        ffi = ffi_top(x, info)
        if !isequal(ffi, nothing)
            println(to, "export $(find_exported(stream, ffi))")
            pprint(to, ffi)
            println(to)
        end
    end
    to_cexpr(from,try_cnt, fun)
    return info
end

function to_pprint{T}(from::T,to::IOStream, opts::Options)
    @defaults opts on_file = "" try_cnt = default_try_cnt
    assert(on_file!="")
    @defaults opts lib_var = :lib
    @defaults opts lib_file = "$lib_var" 
    @defaults opts module_name = symbol(split(lib_file,".")[1])
    @defaults opts info = FFI_Info(on_file, opts)
    
    #TODO module name. #lib_var=$lib_var
    println(to, "#Autogenerated, parameters: 
# on_file=$on_file try_cnt=$try_cnt 
# lib_file=$lib_file module_name=$module_name

#Autogenerated module of $on_file.
module $module_name
import Base.*, GetC.*

#Load library.\n")
    pprint(to, :($lib_var = dlopen($lib_file)))

    println(to, "\n#AutoFFI body.")
    to_pprint(from,info, to, try_cnt)
    println(to, "end #module $module_name")
end
to_pprint{T}(from::T,to::String, opts::Options) = #File version.
    @with s = open(to,"w") to_pprint(from,s, opts)
to_pprint{T}(from::T, opts::Options) = #Stdout version.
    to_pprint(from, stdout_stream, opts)

#TODO want to read stdout from parallel program, this is incredibly crude.
function stream_from_cmd(cmd::Cmd)
    stream_from_string(readall(cmd))
end

#pprint that only does anything if file exists and not already read according to dictionary.
#TODO merge with to_pprint?
function _ffi_header(file::String, info, to::IOStream, 
                     module_name,lib_var, lib_file)
    on_file = info.on_file

    println(to, "#Autogenerated, parameters: 

module $module_name

#Autogenerated module of $file
module $module_name
import Base.*, GetC.*

#Load library.\n")
    pprint(to, :($lib_var = dlopen($lib_file)))

    @with from = stream_from_cmd(`gcc -E $of_file`) begin
        info.on_file = file
        to_pprint(from,info,to, default_try_cnt)
    end

    println(to, "\n#AutoFFI body.")
    to_pprint(from,info, to, try_cnt)
    
    println(to, "\nend #module $module_name")

    info.on_file = on_file #todo
end

function _ffi_header(file::String, info, to_file::String)
    @with to = open(to_file, "w") begin
        _ffi_header(file,info,to, 
                    info.module_namer(file),
                    info.lib_namer(file), info.lib_namer(file))
    end
end
_ffi_header(file::String, info) = _ffi_header(file,info, info.file_namer(file))

first_upper(s::String) = "$(uppercase(s[1]))$(s[2:])"

#Also detects header.
function ffi_header(file::String, opts::Options)
    @defaults opts on_file = file try_cnt = default_try_cnt
    assert(on_file!="")
    @defaults opts lib_var = :lib
    name = split(basename(file),".")[1]
    
    @defaults opts lib_file = "$lib$name"
    @defaults opts module_name = symbol(first_upper(name))
    @defaults opts info = FFI_Info(on_file, opts)

    @defaults opts to_file = info.file_namer(file)
    
    file = (file[1]=='/' ? file : "/usr/include/$file")
    @with to = open(to_file,"w") begin
        ffi_header(file, info,to, 
                   module_name,lib_var,lib_file)
    end
end
ffi_header(file::String) = ffi_header(file, @options)
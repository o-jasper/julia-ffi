# Copyright (c) 2012 Jasper den Ouden, under the MIT license, 
# see doc/mit.txt from the project directory.

#TODO make it a module, export needed stuff.

using Base, OptionsMod
using GetC, PrettyPrint

type FFI_FileInfo
    deps::Array{String,1}
    module_name::Symbol

    #TODO element count and determining if systems are 'boring'?
    
    seen_cnt::Int32
    element_cnt::Int32

    opts::Options
end
FFI_FileInfo(module_name::Symbol, opts::Options) =
    FFI_FileInfo(Array(String,0), module_name, int32(0),int32(0), opts)
FFI_FileInfo(module_name::Symbol) = FFI_FileInfo(module_name, @options)

type FFI_Info #info on how to FFI
    lib_var::Symbol #Variable with library.
    on_file::FFI_FileInfo
    on_file_name::String
    
#    thing_mod::Function #TODO hook on entire entries.
    fun_namer::Function
    type_namer::Function
    opts_fun::Function
    
    implied_files::Bool #Whether to do dependencies.
    mention_files::Bool #Whether to stdout the files as seen,
    
    seen_files::Dict{String,FFI_FileInfo} #Which files have been seen.
    tp_aliasses::Dict{Symbol,Any} 
    
    assert_seen::Bool #Assert things inputted have already been declared.
    ffi_p::Bool #TODO .. what did this do?
    only_visibility #Has to do with a declaration of visibility in the C header.

    seen_cnt_limit::Int32 #How often to look at a file.
end

first_upper(s::String) = "$(uppercase(s[1]))$(s[2:])"
#TODO  /usr/lib/gcc/x86_64-unknown-linux-gnu/4.7.1/include/stdint.h vs
#      /usr/include/stdint.h
default_module_namer(file::String) = 
    symbol(first_upper(split(last(split(file,"/")),".")[1]))

function ensure_file_info(info::FFI_Info, file::String)
    if has(info.seen_files, file)
        return ref(info.seen_files,file)
    else
        opts = info.opts_fun(file)
        @defaults opts module_name = default_module_namer(file)
        file_info = FFI_FileInfo(module_name,opts)
        assign(info.seen_files, file_info, file)
        file_info.deps = determine_deps(file)
        return file_info
    end
end

function FFI_Info(on_file::String, opts::Options) #TODO 'derive' from underlying FFI_Info.
    @defaults opts lib_var = :lib only_visibility= {:default} assert_seen=true
    @defaults opts fun_namer = (name,args)->name
    @defaults opts type_namer = identity
    @defaults opts implied_files = true mention_files = true
    @defaults opts opts_fun = ((file)->@options)
    
    return FFI_Info(lib_var, FFI_FileInfo(:its_a_bug), on_file,
                    fun_namer,type_namer, opts_fun,
                    implied_files,mention_files, Dict{String,FFI_FileInfo}(),
                    Dict{Symbol,Any}(),
                    assert_seen,true,only_visibility, int32(1))
end
FFI_Info(on_file::String) = FFI_Info(on_file, @options)

#
function ffi_top{T}(expr::T, info) 
    if info.ffi_p
        info.on_file.element_cnt += 1
        return ffi_pretop(expr,info) 
    end
end

function ffi_top(chash::CHash, info)
    expr = chash.note
    assert(contains(["#", "//", "/*"], expr.head) && 
           length(expr.body)==1 && isa(expr.body[1],String), expr)
    
    list = split(expr.body[1], "\"", true)
    if length(list)==1
        return
    end
#    Are they always in the correct format for this? 
# TODO assert integer, filename, integer,integer
    src_file = list[2]
    if expr.head=="#" && ends_with(src_file, ".h") #Some stuff from other files.
        info.ffi_p = (src_file == info.on_file_name)
    end
    
  #Read files not seen before.(if enabled.
    if !has(info.seen_files, src_file)
        #TODO assert nonexistent if that is the thing to do..
        ensure_file_info(info, src_file)
    end
    at_file = ref(info.seen_files,src_file) #TODO to determine_deps
    if info.implied_files && isfile(src_file) && 
       at_file.seen_cnt < info.seen_cnt_limit

        @set_options at_file.opts info = info #TODO ..
        ffi_header(src_file, at_file.opts)
    end   
    return ffi_top(chash.thing, info)
end

function ffi_pretop(expr::CTypedef, info)
    name = expr.name
    julia_name = info.type_namer(name)
    if is(julia_name, nothing)
        return nothing #Rejected.
    elseif isa(expr.tp, CStruct)
        struct_elements = 
            Expr(:block, isequal(expr.tp.body, :reference) ? 
                           {} : map((el)->ffi_pretop(el,info), expr.tp.body),
                 Any)
        return Expr(symbol("type"), {julia_name, struct_elements}, Any)
    else
        tp = ffi_type(expr.tp, info)
        assign(info.tp_aliasses, (julia_name,tp), name) #Record it.
        return :(typealias $julia_name $tp)
    end
end
function ffi_pretop(expr::CExpr, info)
    name = symbol(expr.name)
    arglist = {name}
    for el in expr.args
        push(arglist, ffi_arg(el,info))
    end
    julia_name = info.fun_namer(name,arglist)
    if is(julia_name, nothing)
        return nothing #Rejected.
    end
    return :(@g $julia_name $(Expr(:call, arglist,Any))::$(ffi_type(expr.tp, info)))
end

ffi_arg(var::CVarType, info) = 
    Expr(symbol("::"), {var.var, ffi_type(var.tp, info)},Any)

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
#TODO (what?)
ffi_type(tp::CArr,info) = :(Ptr{$(ffi_type(tp.tp,info))})

function ffi_type(tp::CFunPtr, info)
    #TODO get rid of CVarType..
    args = {}
    for a in tp.args #Convert argument types.
        assert(isa(a, CVarType))
        push(args, ffi_type((isa(a.tp,Array) && isempty(a.tp)) ? 
                            {a.var} : a.tp, info))
    end
    return :(FunPtr{$(args), $(tp.ret), $(tp.level)})
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

function ffi_type(tp::Array, info)
#    assert( length(tp)==1, tp ) #Know no reason otherwise would happen.
    name = symbol(tp[1])
    if has(info.tp_aliasses, name)
        julia_name,tp = get(info.tp_aliasses, name, nothing)
        return julia_name
    else
        assert( !info.assert_seen, "Referring to nonexistent type? $name" )
        return name
    end
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
function find_exported(stream, thing::Expr)
    args = thing.args
    @case thing.head begin
        if :macrocall
            assert(args[1] == symbol("@g"), thing)
            return (args[3] == :auto ? args[3].args[1].args[1] : args[2])
        end
        if symbol("typealias") | symbol("type")
            return args[1]
        end
        default : error("I dont like eating $thing (bug)
at $stream")
    end
end
find_exported(stream,thing) = println((:wut_find_exported,thing))

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
to_pprint{T}(from::T,info::FFI_Info, to::IOStream) = 
    to_pprint(from,info, default_try_cnt)

#TODO want to read stdout from parallel program, this is incredibly crude.
function stream_from_cmd(cmd::Cmd)
    stream_from_string(readall(cmd))
end

#Determine dependencies.
determine_deps(thing,b) = Array(String,0)
function determine_deps(chash::CHash)
    list = split(chash.note.body[1], "\"", true)
    if length(list)==1 || !isfile(list[2])
        return Array(String,0)
    end
    ret = Array(String,0)
    push(ret, list[2])
    return ret
end

function determine_deps(file::String, try_cnt)
    if isfile(file)
        @with from = stream_from_cmd(`gcc -E $file`) determine_deps(from,file, try_cnt)
    else
        Array(String,0)
    end
end

function determine_deps(stream::IOStream,file::String, try_cnt)
    list = Array(String,0)
    function fun(stream, x) 
        for el in determine_deps(x)
            if !contains(list, el) && el!=file
                push(list,el)
            end
        end
        return nothing
    end
    to_cexpr(stream,try_cnt,fun)
    return list
end
determine_deps(file) = determine_deps(file, default_try_cnt)

#Raw header maker.
function _ffi_header(file::String, info, to::IOStream,
                     lib_var, lib_file, try_cnt)
    on_file_name = info.on_file_name
    on_file = info.on_file
    module_name = on_file.module_name

#TODO ... using other defintions too.. but dont know them on time..
    print(to, "##Autogenerated module of $file
module $module_name
using Base, GetC")
    module_deps = on_file.deps
    if !isempty(module_deps) #Other dependencies.
        module_name_of(file::String) = ensure_file_info(info,file).module_name
        print(to, "\nusing $(module_name_of(module_deps[1]))")
        for el in module_deps[2:]
            print(to, ", $(module_name_of(el))")
        end
    end
    println(to,"\n\n#Load library.\n")
    pprint(to, :($lib_var = dlopen($lib_file)))
    println(to, "\nmacro g(name, c_fun) #Makes stuff shorter.
    :(@get_c_fun $lib_var \$name \$c_fun)
end") #TODO exporting it aswel even better.

    println(to, "\n#AutoFFI body.\n")

    assert(isfile(file))
    @with from = stream_from_cmd(`gcc -E $file`) begin
        info.on_file_name = file
        info.on_file = ref(info.seen_files, file)
        to_pprint(from,info,to, default_try_cnt)
    end
    
    println(to, "\nend #module $module_name")

    info.on_file_name = on_file_name #todo
    info.on_file = on_file
end

#Also detects header.
function ffi_header(file::String, opts::Options)
    @defaults opts on_file = file try_cnt = default_try_cnt
    assert(on_file!="")
    @defaults opts lib_var = :lib
    name = split(basename(file),".")[1]
    
    @defaults opts lib_file = "lib$name"
    
    @defaults opts info = assert(false) #FFI_Info(on_file, opts)
    info.on_file_name = on_file #Hrmm.

    file = (file[1]=='/' ? file : "/usr/include/$file") #Absolute or from /usr/include.
    info.on_file = ensure_file_info(info, file)
    info.on_file_name = file

    info.on_file.seen_cnt += 1
    if info.mention_files #Mention file and number of times seen.
        println(file," (",info.on_file.seen_cnt,")")
    end
    
    @defaults opts to_file = "autoffi/$(info.on_file.module_name).jl"
    
    @with to = open(to_file,"w") begin
        _ffi_header(file, info,to,lib_var,lib_file, try_cnt)
    end
end

ffi_header(file::String) = ffi_header(file, @options)
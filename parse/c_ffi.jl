# Copyright (c) 2013 Jasper den Ouden, under the MIT license, 
# see doc/mit.txt from the project directory.

#TODO make it a module, export needed stuff.

using Base, OptionsMod
using GetC, PrettyPrint

type FFI_FileInfo
    path::String

    deps::Array{String,1}
    module_name::Symbol

    #TODO element count and determining if systems are 'boring'?
    
    seen_cnt::Int32
    element_cnt::Int32

    opts::Options #Options applied here.
end
FFI_FileInfo(path, module_name::Symbol, opts::Options) =
    FFI_FileInfo(path, Array(String,0), module_name, int32(0),int32(0), opts)
FFI_FileInfo(path, module_name::Symbol) = 
    FFI_FileInfo(path, module_name, @options)

type FFI_Info #info on how to FFI
    seen_files::Dict{String,FFI_FileInfo} #Which files have been seen.
    tp_aliasses::Dict{Symbol,Any} 
end

FFI_Info() =
    FFI_Info(Dict{String,FFI_FileInfo}(), Dict{Symbol,Any}())

typealias FFI_Stuff (FFI_Info,Options)

macro stuffdefaults(things)
    assert(isa(things,Expr) && things.head== :cell1d,
           "Invalid @stuffdefaults entry; $things")
    list = {}
    for arg in things.args
        assert(isa(arg, Symbol))
        push(list, :($arg = $(symbol("default_$arg"))))
    end
    esc(:(@defaults stuff[2] $(list...)))
end

first_upper(s::String) = "$(uppercase(s[1]))$(s[2:])"
#TODO  /usr/lib/gcc/x86_64-unknown-linux-gnu/4.7.1/include/stdint.h vs
#      /usr/include/stdint.h

default_type_namer(x)        = x #Which is identity
default_fun_namer(name,args) = name
default_opts_fun(file)       = @options file=file
default_module_namer(file::String) = 
    symbol(first_upper(split(last(split(file,"/")),".")[1]))
default_to_file_namer(module_name) = "autoffi/$module_name.jl"

default_lib_var = :lib #Variable set to library value.
#Has to do with a declaration of visibility in the C header.
default_only_visibility= {:default} 
default_assert_seen=true #Assert things inputted have already been declared.
default_implied_files = true #Whether to do dependencies.
default_mention_files = true #Whether to stdout the files as seen
default_seen_cnt_limit = 1 #How often to look at a file.

#
default_file = ""
#default_try_cnt = #Somewhere else.(think c_parse)
default_lib_var = :lib

default_ignore_particular = Dict{String,Bool}()
default_ignore_start = ["/usr/lib/", "/usr/include/bits/"] 

on_file(stuff::FFI_Stuff, file::String) = get(stuff[1].seen_files, file, nothing)

function ensure_file_info(stuff::FFI_Stuff, file::String)
    info,stuff_opts = stuff
    if has(info.seen_files, file)
        return ref(info.seen_files,file)
    else
        @stuffdefaults {opts_fun}
        opts = opts_fun(file) #Many things like namings determined here.
        @defaults opts module_name = default_module_namer(file)
        file_info = FFI_FileInfo(file, module_name,opts)
        assign(info.seen_files, file_info, file)
        println(file)
        file_info.deps = determine_deps(file,stuff)
        return file_info
    end
end

function ffi_top{T}(expr::T, stuff::FFI_Stuff) 
    @stuffdefaults {file}
    on_file(stuff,file).element_cnt += 1
    return ffi_pretop(expr,stuff)
end

function may_ffi_header(src_file::String, stuff::FFI_Stuff)
    @stuffdefaults {implied_files, seen_cnt_limit, file }
    info,opts  = stuff
  #Read files not seen before.(if enabled.)
    assert( has(info.seen_files, src_file), 
           "Bug: Didnt see file in determining dependencies? File: $src_file" )
    at_file = ref(info.seen_files, src_file) 

    file_info = on_file(stuff,file)
    if (implied_files && isfile(src_file) && 
        at_file.seen_cnt < seen_cnt_limit &&
        src_file != file_info.path)
        
        ffi_header(stuff[1],at_file.opts)
    end
end

function ffi_top(chash::CHash, stuff::FFI_Stuff)
    expr = chash.note
    assert(contains(["#", "//", "/*"], expr.head) && 
           length(expr.body)==1 && isa(expr.body[1],String), expr)
    
    list = split(expr.body[1], "\"", true)
    src_file = list[2]
    if length(list)==1 || !isfile(list[2])
        return ffi_top(chash.thing, stuff)
    end
    may_ffi_header(src_file, stuff)
    
    return ffi_top(chash.thing, stuff)
end

function ffi_pretop(expr::CTypedef, stuff::FFI_Stuff)
    info,opts = stuff
    name = expr.name
    @stuffdefaults {type_namer}
    julia_name = type_namer(name)
    if is(julia_name, nothing)
        return nothing #Rejected.
    elseif isa(expr.tp, CStruct)
        struct_elements = 
            Expr(:block, isequal(expr.tp.body, :reference) ? 
                           {} : map((el)->ffi_pretop(el,stuff), expr.tp.body),
                 Any)
        return Expr(symbol("type"), {julia_name, struct_elements}, Any)
    else
        tp = ffi_type(expr.tp, stuff)
        assign(info.tp_aliasses, (julia_name,tp), name) #Record it.
        return :(typealias $julia_name $tp)
    end
end

function ffi_pretop(expr::CExpr, stuff::FFI_Stuff)
    name = symbol(expr.name)
    arglist = {name}
    for el in expr.args
        push(arglist, ffi_arg(el,stuff))
    end
    @stuffdefaults {fun_namer}
    julia_name = fun_namer(name,arglist)
    if is(julia_name, nothing)
        return nothing #Rejected.
    end
    return :(@g $julia_name $(Expr(:call, arglist,Any))::$(ffi_type(expr.tp, stuff)))
end

ffi_arg(var::CVarType, stuff::FFI_Stuff) = 
    Expr(symbol("::"), {var.var, ffi_type(var.tp, stuff)},Any)

ffi_pretop(expr::CVarType, stuff::FFI_Stuff) = 
    ffi_arg(expr,stuff)
ffi_pretop(expr::CStruct, stuff::FFI_Stuff)  = 
    ffi_pretop(CTypedef(symbol("struct_$(expr.name)"),expr), stuff)
#ffi_pretop(expr::CUnion
#ffi_pretop(expr::CEnum)

ffi_pretop(expr::Nothing, stuff::FFI_Stuff) = nothing

function ffi_pretop(expr::CAttribute, stuff::FFI_Stuff)
    assert(!isequal(expr.full,nothing))
    @stuffdefaults {only_visibility}
    if contains(only_visibility, expr.visibility) || isempty(only_visibility)
        return ffi_pretop(expr.thing, stuff)
    end
end

#Already there(it figured it out itself)
ffi_type(tp::BitsKind, stuff::FFI_Stuff) = tp 
function ffi_type(tp::UnionKind, stuff::FFI_Stuff)
    assert(tp==Void)
    return tp
end
function ffi_type(tp::CPointer, stuff::FFI_Stuff)
    ptr(tp,n) = (n>0 ? ptr(:(Ptr{$tp}), n-1) : tp)
    return ptr(ffi_type(tp.tp,stuff), tp.cnt)
end
#TODO (what?)
ffi_type(tp::CArr, stuff::FFI_Stuff) = :(Ptr{$(ffi_type(tp.tp,stuff))})

function ffi_type(tp::CFunPtr, stuff::FFI_Stuff)
    #TODO get rid of CVarType..
    args = {}
    for a in tp.args #Convert argument types.
        assert(isa(a, CVarType))
        push(args, ffi_type((isa(a.tp,Array) && isempty(a.tp)) ? 
                            {a.var} : a.tp, stuff))
    end
    return :(FunPtr{$(args), $(tp.ret), $(tp.level)})
end

function ffi_type(tp::CStruct, stuff::FFI_Stuff)
    if isa(tp.body, Symbol)
        assert( tp.body== :reference )
        return :TODO_refer_to_struct #explicit mention that it is a struct.
    end
    list = {} #List of elements in there.
    for component in tp.body
        assert(isa(component, CVarType))
        push(list, Expr(symbol("::"), 
                        {component.var, ffi_type(component.tp, stuff)}, Any))
    end
    return Expr(symbol("type"), {tp.name, Expr(:block, list,Any)}, Any)
end

function ffi_type(tp::Array, stuff::FFI_Stuff)
#    assert( length(tp)==1, tp ) #Know no reason otherwise would happen.
    name = symbol(tp[1])
    info,opts = stuff
    if has(info.tp_aliasses, name)
        julia_name,tp = get(info.tp_aliasses, name, nothing)
        return julia_name
    else
        @stuffdefaults {assert_seen, file}
        assert( !assert_seen, "Referring to nonexistent type? $name
at $file" )
        return name
    end
end

#To FFI code in data from.
function to_ffi{T}(from::T, stuff::FFI_Stuff, try_cnt::Integer)
    @collect begin
        fun(stream, x) = collect_non_nothing(ffi_top(x,stuff))
        to_cexpr(from,try_cnt,fun)
    end
end
to_ffi{T}(from::T, stuff::FFI_Stuff) = to_ffi(from, stuff, default_try_cnt)

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
function to_pprint{T}(from::T,stuff::FFI_Stuff, to::IOStream, try_cnt::Integer)
    function fun(stream, x)
        ffi = ffi_top(x, stuff)
        if !isequal(ffi, nothing)
            println(to, "export $(find_exported(stream, ffi))")
            pprint(to, ffi)
            println(to)
        end
    end
    to_cexpr(from,try_cnt, fun)
    #return stuff
end
to_pprint{T}(from::T,stuff::FFI_Stuff, to::IOStream) = 
    to_pprint(from,stuff, default_try_cnt)

#TODO want to read stdout from parallel program, this is incredibly crude.
function stream_from_cmd(cmd::Cmd)
    stream_from_string(readall(cmd))
end

function ignore_file_p(file::String, stuff::FFI_Stuff)
    @stuffdefaults {ignore_particular, ignore_start}
    if !get(ignore_particular, file, false)
        return true
    end
    for el in ignore_start
        if begins_with(file,el)
            return true
        end
    end
    return false
end

gcc_E(file::String, stuff::FFI_Stuff) =
    (ignore_file_p(file,stuff) ? stream_from_string("") : 
                                 stream_from_cmd(`gcc -E $file`))

#Determine dependencies.
determine_deps(thing,stuff::FFI_Stuff) = determine_deps(thing, stuff,default_try_cnt)
determine_deps(thing,stuff::FFI_Stuff,cnt) = Array(String,0)

function determine_deps(chash::CHash, stuff::FFI_Stuff, try_cnt)
    list = split(chash.note.body[1], "\"", true)
    if length(list)==1 || !isfile(list[2])
        return Array(String,0)
    end
    ret = Array(String,0) #TODO rather use `?` notation.
    src_file = list[2]

    info,opts = stuff
    ensure_file_info(stuff, src_file)
    at_file = ref(info.seen_files, src_file) #TODO to determine_deps
    
    if at_file.element_cnt > 0
        push(ret, src_file)
    end
    append!(ret, determine_deps(chash.thing, stuff, try_cnt))
    return ret
end

function determine_deps(file::String, stuff::FFI_Stuff, try_cnt)
    if isfile(file)
        @with from = gcc_E(file,stuff) determine_deps(from,file, stuff, try_cnt)
    else
        Array(String,0)
    end
end

function determine_deps(stream::IOStream,file::String, stuff::FFI_Stuff, try_cnt)
    list = Array(String,0)
    function fun(stream, x) 
        for el in determine_deps(x, stuff)
            if !contains(list, el) && el!=file
                push(list,el)
            end
        end
        return nothing
    end
    to_cexpr(stream,try_cnt,fun)
    return list
end

#Raw header maker.
function _ffi_header(file::String, stuff::FFI_Stuff, to::IOStream,
                     lib_var, lib_file, try_cnt)
    @stuffdefaults {file}
    file_info = on_file(stuff,file)
    module_name = file_info.module_name

#TODO ... using other defintions too.. but dont know them on time..
    print(to, "##Autogenerated module of $file
module $module_name
using Base, GetC")
    module_deps = file_info.deps
    if !isempty(module_deps) #Other dependencies.
        module_name_of(file::String) = ensure_file_info(stuff,file).module_name
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
    @with from = gcc_E(file,stuff) to_pprint(from,stuff,to, default_try_cnt)

    println(to, "\nend #module $module_name")
end

glob_info = FFI_Info()

#Also detects header.
function ffi_header(info::FFI_Info, opts::Options)
    stuff = (info,opts)
    @stuffdefaults {file, try_cnt, lib_var, to_file_namer, mention_files}

    @defaults opts lib_var = :lib
    name = split(basename(file),".")[1]
    
    @defaults opts lib_file = "lib$name"
  #Absolute or from /usr/include.
    file = (file[1]=='/' ? file : "/usr/include/$file") 
    @set_options opts file = file
    
    file_info = ensure_file_info(stuff, file)
    file_info.seen_cnt += 1
    
#    @defaults opts to_file = "autoffi/$(file_info.module_name).jl"
    if mention_files #Mention file and number of times seen,
        println("$file $(file_info.element_cnt,file_info.seen_cnt)")
    end    
    @with to = open(to_file_namer(file_info.module_name),"w") begin
        _ffi_header(file, stuff,to,lib_var,lib_file, try_cnt)
    end
end
#Defaults use a single info structure.
ffi_header(opts::Options) = ffi_header(glob_info,opts)

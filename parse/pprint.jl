# Copyright (c) 2012 Jasper den Ouden, under the MIT license, 
# see doc/mit.txt from the project directory.

#'Pretty printing' made to produce autoFFI files. (It isn't quite right 
# for more general use at the moment.
module PrettyPrint

using Base, OJasper_Util

export pprint, pprint_separted

#--- no more module stuff.

#Pretty prints separated by some symbol with stuff to write before and after.
function pprint_separated(to::IOStream, list, sep, before,after)
    write(to, before)
    if !isempty(list)
        pprint(to, list[1])
        for el in list[2:]
            write(to, sep)
            pprint(to, el)
        end
    end
    write(to, after)
end

#Pretty print.
function pprint(to::IOStream, e::Expr)
    name,args = (e.head,e.args)
    @case name begin
        symbol("typealias") : pprint_separated(to, args, " ", "typealias ","\n")
        :macrocall          : pprint_separated(to, args, " ","","\n")
        symbol("type")      : pprint_separated(to, args[2].args, 
                                               "\n  ","type $(args[1])\n  ","\nend")
        symbol("::") | symbol("=") :  #NOTE: not robust with precidence!
            pprint_separated(to, args, "$name", "","")
        if :curly
            pprint(to, args[1])
            pprint_separated(to, args[2:], ", ", "{","}")
        end
        if :call
            pprint(to, args[1])
            pprint_separated(to, args[2:], ", ", "(",")")
        end
        default : error("Dont know what to do with head $name")
    end
    return nothing
end
pprint(to::IOStream, thing::String) = print(to,"\"$thing\"")
#Void makes more sense for the purpose of C FFI.
pprint(to::IOStream, thing::UnionKind) = 
    (thing==None ? write(to,"Void") : print(to,thing))
pprint{T}(to::IOStream, thing::T) = print(to,thing)

pprint{T}(thing::T) = pprint(stdout_stream, thing)

end #module PrettyPrint

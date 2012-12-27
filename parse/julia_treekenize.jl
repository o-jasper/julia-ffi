# Copyright (c) 2012 Jasper den Ouden, under the MIT license, 
# see doc/mit.txt from the project directory.

#NOTE: dont take it too seriously at this point.(untested, incomplete etc.)

bin_el(str::String,sym::Symbol) = (str,sym,nothing)
bin_el(str::String) = bin_el(str,symbol(str))

julia_treekenizer_set =
    {("(",")"),("[","]"),("{","}").  #Order matters!
     ("@", "\n"),("#","\n"), bin_el(";"),
     ("begin","end"), ("function","end"),("let","end"), ("type","end"),
     ("quote","end"),
     ("typealias", "\n"), ("@", "\n")
#     bin_el(","), bin_el(";"), 
#     bin_el(" ", :white), bin_el("\t", :white),bin_el("\n", :white),
#     bin_el("+"), bin_el("-"), bin_el("*"),bin_el("/"),
#     bin_el("||"),bin_el("&&"),bin_el("!"),
#     bin_el("|"), bin_el("&"), bin_el("~"),
     }

#The later, the higher the precidence.
julia_infixes = [",", ":",
                 "!","||","&&",
                 "~","|", "&", "|",
                 "+","-", "/", "*", "^"]

function julia_treekenize(s::ConvenientStream, try_n::Integer)
    tree = treekenize(s, julia_treekenizer_set, "\n", try_n,2)
    infix_syms(tree, julia_infixes)
end

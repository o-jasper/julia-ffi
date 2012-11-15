#
#  Copyright (C) 01-11-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

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

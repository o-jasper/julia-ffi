#
#  Copyright (C) 31-10-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

bin_el(str::String,sym::Symbol) = (str,sym,nothing)
bin_el(str::String) = bin_el(str,symbol(str))

c_treekenizer_set =
    {("(",")"),  #Order matters!
     ("/*", "*/"),("//", "\n"),("#","\n"),
     bin_el(","), bin_el(";"), 
     bin_el(" ", :white), bin_el("\t", :white),bin_el("\n", :white),
     bin_el("+"), bin_el("-"), bin_el("*"),bin_el("/"),
     bin_el("||"),bin_el("&&"),bin_el("!"),
     bin_el("|"), bin_el("&"), bin_el("~"),
     bin_el(":"), bin_el("case")}

function c_treekenize(s::ConvenientStream, try_n::Integer)
    tree = treekenize(s, c_treekenizer_set, "\n", try_n,2)
    tree = remove_sequential_duplicates(tree,:white)
    
end

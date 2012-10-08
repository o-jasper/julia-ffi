# Jasper den Ouden  17-09-2012
#Placed in public domain.

#dlmwrite, but with arbitrary iterator.
function dlmwrite_iter{Iterable}(to::IOStream, iterable::Iterable, 
                                 delim::String,line_delim::String)
  for el in iterable
    c,iter_state = next(el,start(el))
    write(to, "$c")
    while !done(el,iter_state)
      c,iter_state = next(el,iter_state)
      write(to, "$delim$c")
    end
    write(to, line_delim)
  end
end

dlmwrite_iter{Iterable}(to::String, iterable::Iterable, 
                        delim::String,line_delim::String) =
    @with stream = open(to,"w") dlmwrite_iter(stream,iterable,
                                              delim,line_delim)
#With default string.
dlmwrite_iter{To,Iterable}(to::To,iterable::Iterable, delim::String) =
    dlmwrite_iter(to,iterable, delim,"\n")
dlmwrite_iter{To,Iterable}(to::To,iterable::Iterable) =
    dlmwrite_iter(to,iterable, "\t")

#This one is intended to allow people to provide a default `dlmwrite_any` that
# isn't based on an iterator. It defaults to the iterator one.
dlmwrite_any{To,Thing}(to::To, thing::Thing, 
                       delim::String,line_delim::String) =
    dlmwrite_iter(to,thing, delim,line_delim)

dlmwrite_any{To,Thing}(to::To, thing::Thing, delim::String) =
    dlmwrite_any(to,thing,delim,"\n")
dlmwrite_any{To,Thing}(to::To, thing::Thing) = dlmwrite_any(to,thing,"\t")

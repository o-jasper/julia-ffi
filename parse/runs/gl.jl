load("runs/load.jl")

function gl_type_namer(name)
    i,j = search("$name", "PROC") #Dont know what these are supposed to mean.
    return (i>0 || j>0) ? nothing : name
end
gl_fun_namer(name,args) = symbol(lowercase("$name"))

ffi_header(@options file="GL/gl.h")

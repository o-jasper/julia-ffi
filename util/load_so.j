
#Loads a so, and checks if it exists, if not user probably didn't run make.

function find_so_file_path(so_file::String)
  ret = nothing
  try
    ret = find_in_path(so_file)
  catch
    error("\n.so file seems missing, did you run make?
File in question: $so_file
(alternatively, didn't compile otherwise, the file wasn't available from
your directory.)\n")
  end
  return ret
end

load_so(so_file::String) =
    dlopen(find_so_file_path(so_file))

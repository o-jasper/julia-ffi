load("util/util.j")
load("util/tabbed_data.j")

#Random tabbed file into stream.
function make_tabbed_file(stream::IOStream, 
                          max_depth::Integer, len::Integer,
                          deepen_prob::Number, tab::String,tabstr::String)
  list = {}
  for i = 1:len
    val = rand()
    write(stream, "$tabstr$val\n")
    if i>1 && max_depth!=1 && rand()<deepen_prob #Probability deepening it.
      push(list, make_tabbed_file(stream, max_depth-1,len, deepen_prob,
                                  tab,"$tabstr$tab"))
      enqueue(last(list), "$val\n")
    else
      push(list,"$val\n")
    end
  end
  return list
end
make_tabbed_file{T}(stream::T, max_depth::Integer, len::Integer,
                    deepen_prob::Number, tab::String) =
    make_tabbed_file(stream, max_depth,len,deepen_prob,tab, "")
make_tabbed_file{T}(stream::T, max_depth::Integer, len::Integer,
                    deepen_prob::Number) =
    make_tabbed_file(stream, max_depth,len,deepen_prob,"\t")

#Random tabbed file into file
function make_tabbed_file(file::String,
                          max_depth::Integer, len::Integer,
                          deepen_prob::Number, tab::String,tabstr::String)
  @with stream=open(file,"w") begin
    make_tabbed_file(stream,max_depth,len,deepen_prob, tab,tabstr)
  end
end

function test(silent::Bool)
  maysay(say) = (silent ? nothing : println(say))
  maysay("Generate file(TODO memio)")
  file = "/tmp/tabbed_data_test"
  tree = make_tabbed_file(file, 4,4, 0.5)
  maysay(tree)
  maysay("Reading")
  read_tree = read_tabbed_file(file)[2:]
  maysay("read it;")
  maysay(read_tree)
  assert(isequal(tree,read_tree), 
         "The read tree is not equal to the written tree.(failure)")
end

for i = 1:20
  test(true)
end

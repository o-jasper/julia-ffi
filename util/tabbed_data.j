#  Jasper den Ouden 02-08-2012
# Placed in public domain.

module TabbedData

import Base.* 
import OJasper_Util.*

export read_tabbed_data

#----no more module stuff.

#Read data from a file that indicate nestedness with tabs.
function read_tabbed_data(stream::IOStream, tab::String)
  line = ""
  list = {""} #List of read data.
  while !eof(stream)
    line = readline(stream)
    push_at = list
    while begins_with(line,tab) #Figure out level of tabs.
      line = line[1+length(tab):]
      if isa(last(push_at), String)
        push_at[length(push_at)] = {last(push_at)}
      end
      push_at = last(push_at)
    end
    push(push_at, line)
  end
  return list
end
const tabbed_data_default_tab = "\t"
read_tabbed_data{T}(stream::T) = 
    read_tabbed_data(stream,tabbed_data_default_tab)

#TODO: uhm, why `_file` ?
read_tabbed_data(file::String, tab::String) =
    @with s=open(file,"r") read_tabbed_data(s, tab)

end #module TabbedData
#
#  Copyright (C) 01-10-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

load("util/util.j")
load("parse/c_header.jl")

#Generates randomly whitespaced and commented stuff.
function generate_for_skip_white(crud_len, x)
  stream = memio()
  function gen_crud()
    @case randi(8) begin
      1 : "//$(rand())\n"
      2 : "#$(rand())\n"
      3 : "/*$(rand())*/"
      4 : "/*$(rand())\n$(rand())*/"
      5 : "/*$(rand())\n*/"
      6 : " "
      7 : "\t"
      8 : "\n"
    end
  end
  for n = 1:crud_len
    write(stream, gen_crud())
  end
  write(stream,"$x") #Value to retrieve.
  for n = 1:crud_len #More crud.
    write(stream, gen_crud())
  end
  seek(stream,0) #Back to the start.
  return stream
end
#Tests the line handle using generated crud.
function test_skip_white(crud_len)
  x = rand()
  @with stream = ConvenientStream(generate_for_skip_white(crud_len,x)) begin
    skip_white(stream) #Hopefully skips crud.
    i,j = search(stream.line, [' ', '\n', '\t', '#','\n','/'])
    y = parse_float(stream.line[1:i-1])
    if x!=y
      println("$x != $y")
    end
  end
end

for n = 1:100
  test_skip_white(10)
end
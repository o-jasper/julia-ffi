#
#  Copyright (C) 31-10-2012 Jasper den Ouden.
#
#  This is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#

# Parses preprocessed C header files (perhaps upgrade to C)
module CHeader

import Base.*
import OJasper_Util.*

export ConvenientStream, skip_white
export MExpr, MStruct
export parse_top_1, parse_top

# --- end module stuff

type ConvenientStream #TODO not quite the right place to put this.
  stream::IOStream
  line::String
end
ConvenientStream(stream::IOStream) = ConvenientStream(stream,"")
#Pass on @with duties.
no_longer_with(cs::ConvenientStream) = no_longer_with(cs.stream)

#TODO counting newlines shouldn't be too hard..
function forward(cs::ConvenientStream, n::Integer)
  if n>length(cs.line)
    cs.line = readline(cs.stream)[n-length(cs.line):]
  else
    cs.line = cs.line[n+1:]
  end
  return nothing
end
readline(cs::ConvenientStream) = (cs.line = readline(cs.stream)) #!

#Skip to the line containing the given object sequence.
function get_to_line_with{W}(in::ConvenientStream, with::W)
  line = in.line
  while true
    i,j = search(in.line, with)
    if i==0 && j==0
      readline(in)
    else #Found it.
      forward(in, j-1) #(in.line = line[j:])
      return nothing
    end
  end
end
#Skips comments, whitespace. TODO rename to skip_white or such
function skip_white(in::ConvenientStream)
    next_up(str) = begins_with(in.line, str)
    n=0
    while true
        if isempty(in.line) || contains(" \t\n", in.line[1]) #Skip whitespace.
            forward(in, 1)
        elseif next_up("//") || next_up("#") #Skip whole lines.
            readline(in)
        elseif next_up("/*") #Skip to end of comment.
            get_to_line_with(in,"*/",)
        else #Not a comment or any such, return.
            return nothing
        end
    end
end

type MStruct
  what::Symbol
  name::Symbol
  members::Any
end

function char_pos(str::String, chars)
    for j = 1:length(str)
        if contains(chars, str[j])
            return j
        end
    end
    return length(str)
end

function parse_structlike(in::ConvenientStream, what::Symbol)
  list = {}
  pushif(x) = (isempty(x) ? nothing : push(list,x)) #!
  skip_white(in)
  name = :ignore
  if in.line[1]!='{'
      j = char_pos(in.line, [' ','\n','\t','{','/'])-1
      if j>1 
          name = symbol(in.line[1:j])
      end
      forward(in,j)
      skip_white(in)
      if in.line[1]!='{' #Not a declaration of the whole thing.
          return MStruct(name,:mention)
      end
  end
  while in.line[1]!='}'
    got,end_ch = parse_top_1(in)
    assert(end_ch==';')
    pushif(got)
    skip_white(in)
  end
  forward(in,1) #Get over the '}'
  return MStruct(what, name, list)
end

type MExpr
    head::Symbol
    args::Array{Any,1}
end
#Parses argument lists.
function parse_tuple(in::ConvenientStream) 
    list = {}
    while true
        got,end_ch = parse_top_1(in)
        if end_ch==')' #Indicates done with tuple.
            if !isempty(got)
                push(list, got)
            end
            return list
        end
        push(list, got)
      #Must be this to indicate next element
        assert(end_ch==',', (in,end_ch)) 
        skip_white(in)
    end
end

#Parses various toplevel things.
function parse_top_1(in::ConvenientStream)
    list = {}
    args_list = {}
    skip_white(in)
    j = 1
    println(:i)
    while true     
        function forw()
            forward(in,j)
            skip_white(in)
            j=1
        end
        function push_cur()
            if j==1
                forw()
                return
            end
            j-=1 #Get rid of the stopper
            str = in.line[1:j]
            forw()
            if str == "struct"
                push(list, parse_structlike(in, :struct))
            elseif str == "union"
                push(list, parse_structlike(in, :union))
            elseif str == "enum"
                push(list, parse_structlike(in, :enum))
            elseif length(str)>0
                push(list, symbol(str))
            end
        end
        next_up(chars...) = contains(chars, in.line[j])
        
        #TODO infix and unary operators.
        if j>length(in.line) || next_up(' ', '\t', '/', '{')
            push_cur()
            continue
        elseif next_up('(')
            name = symbol(in.line[1:j-1])
            forw()
            push(list, MExpr(name, parse_tuple(in)))
            continue
        elseif next_up(';',')',',') #Latter only as tuple.
            end_ch = in.line[j]
            println((in.line, end_ch))
            push_cur()
#            forward(in,1)
            println(:e)
            return (list, end_ch)
        end
        j+=1
    end
end

function eof(stream::IOStream) #TODO Hrmmm
  i = position(stream)
  seek_end(stream)
  if i == position(stream) #TODO terrible.
    return true
  end
  seek(stream, i)
  return false
end

function parse_top(in::ConvenientStream)
  list = {}
  while !eof(in.stream)
    got = parse_top_1(in)
    push(list, got)
  end
  return list
end

parse_top(in::IOStream) = parse_top(ConvenientStream(in))
parse_top(file::String) =
    @with stream = open(file, "r") parse_top(stream)

end #module CHeader
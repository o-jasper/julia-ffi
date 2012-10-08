#  Jasper den Ouden 02-08-2012
# Placed in public domain.

#TODO explain what it does.

type ByIndexNode{T}
  index::Int16
  thing::T
end

#wish i had setf-functions.

function get_index{T}(list::Array{ByIndexNode{T},1}, i::Int16, if_not::T)
  for el = list
    if el.index==i
      return el.thing
    end
  end
  return if_not
end

get_index{T}(list::Array{ByIndexNode{T},1}, i::Integer, if_not::T) =
    get_index(list, int16(i), if_not)

function set_index{T}(to::T, list::Array{ByIndexNode{T},1}, i::Int16)
  for el = list
    if el.index==i
      el.thing = to
      return nothing
    end
  end
  push(list, ByIndexNode(i,to))
  return nothing
end

set_index{T}(to::T, list::Array{ByIndexNode{T},1}, i::Integer) = 
    set_index(to,list,int16(i))

type ByIndex{T}
  arr::Array{T,1} #Direct indices.
  list::Array{ByIndexNode{T},1} #Key-value pairs
end

BuIndex{T}() = ByIndex{T}(Array(T,0),Array(ByIndexNode{T},0))

function get_index{T}(bi::ByIndex{T}, i::Int16, if_not::T)
  if i< length(bi.arr)
    bi.arr[i]
  else
    get_index(bi.list,i, if_not)
  end
end

get_index{T}(bi::ByIndex{T}, i::Integer, if_not::T) =
    get_index(bi, int16(i), if_not)

function set_index{T}(to::T, bi::ByIndex{T}, i::Int16)
  if i<= length(bi.arr)
    bi.arr[i] = to
  else
    set_index(to, bi.list,i)
  end
  return nothing
end

set_index{T}(to::T, bi::ByIndex{T}, i::Integer) = set_index(to, bi, int16(i))

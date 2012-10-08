# Jasper den Ouden  16-09-2012
#Placed in public domain.

#Expanding arrays with arbitrary setting of indices.

#A reshape that works. (until the julia one starts working again..)
function working_reshape{T}(arr::Array{T,1}, newlen::Integer)
  assert( length(arr) < newlen )
  ret = Array(T, newlen)
  for i = 1:length(arr)
    ret[i] = arr[i]
  end
  return ret
end

type ExpandingArray{T}
  start::Int64
  arr::Array{T,1}
end

ExpandingArray(T, start::Integer) = 
   ExpandingArray(int64(start),Array(T,0))
ExpandingArray(T) = ExpandingArray(T,0)

zero{T}(tp::Type{ExpandingArray{T}}) = ExpandingArray(T)

function ref{T,I<:Integer}(a::ExpandingArray{T}, i::I) 
  j = i - a.start
  return (j < 1 || j>length(a.arr)) ? zero(T) : a.arr[j]
end

el_cnt{T}(arr::ExpandingArray{T}) = length(arr.arr)

function assign{T,I<:Integer}(a::ExpandingArray{T}, to::T, i::I, 
                              overshoot::Float64)
  len = length(a.arr)
  if len == 0 #Just start the array there.
    a.start = i-1
    a.arr = [to]
    return a.arr[1]
  end
  j = i - a.start    
  if j<1 #Doesn't go low enough. #TODO overshoot on the small end.
    add_len = 1 - j
    a.arr = working_reshape(a.arr, len + add_len)
    for k = len+1:length(a.arr) #Zero the new elements.
      a.arr[k] = zero(T)
    end
    a.arr = circshift(a.arr, add_len) #Move the data.
    a.start -= add_len #It starts earlier now.
    j = add_len + j
  elseif j>len #Doesn't go high enough.
    a.arr = working_reshape(a.arr, max(j, int(j*overshoot)))
    for k = (len+1):length(a.arr) #Zero the new elements.
      a.arr[k] = zero(T)
    end
  end
  a.arr[j]= to
  return a.arr[j]
end
assign{T,I<:Integer}(a::ExpandingArray{T}, to::T, i::I) = assign(a,to,i,1.5)

min{T}(arr::ExpandingArray{T}) = min(arr.arr)
max{T}(arr::ExpandingArray{T}) = max(arr.arr)

#Minimum and maximum index.
min_i{T}(arr::ExpandingArray{T}) = arr.start+1
max_i{T}(arr::ExpandingArray{T}) = arr.start+ length(arr.arr)

#Iterator without index.
indexless_iter{T}(a::ExpandingArray{T}) = a.arr
#Iterator that doesn't miss any indexes in between.(Here just the regular one)
continuous_iter{T}(a::ExpandingArray{T}) = a
continuous_iter{T}(a::Array{T,1}) = a

#Iterator that also gives you the index.
start{T}(a::ExpandingArray{T}) = int64(1)
done{T}(a::ExpandingArray{T}, i::Int64) = (i >= length(a.arr))
next{T}(a::ExpandingArray{T}, i::Int64) = ((a.start + i,a.arr[i]), i+1)

#2d Version.
type ExpandingArray2d{T}
  arr::ExpandingArray{ExpandingArray{T}}
end

ExpandingArray2d(T::Type) =
    ExpandingArray2d(ExpandingArray(ExpandingArray{T}))
zero{T}(arr2d::ExpandingArray2d{T}) = ExpandingArray2d(T)
#Total number of elements.
function el_cnt{T}(arr::ExpandingArray2d{T})
  sum = 0
  for el in indexless_iter(arr.arr)
    sum += el_cnt(el)
  end
  return sum
end

#Iterating it. (TODO better way of passing the features of a member..?)
start{T}(arr::ExpandingArray2d{T}) = start(arr.arr)
done{T,State}(arr::ExpandingArray2d{T},s::State) = done(arr.arr,s)
next{T,State}(arr::ExpandingArray2d{T},s::State) = next(arr.arr,s)

ref{T,I<:Integer}(a::ExpandingArray2d{T}, i::I,j::I) = a.arr[i][j]
function assign{T,I<:Integer}(a::ExpandingArray2d{T}, to::T, i::I,j::I) 
  k = i - a.arr.start
  if k<1 || k> length(a.arr.arr) #Doesn't exist yet, create.
    a.arr[i] = ExpandingArray(j-1,[to]) #(assign will make it on that side)
    return to
  end
  return( a.arr.arr[k][j] = to ) #Exists, you can use it to set.
end

indexless_iter{T}(a::ExpandingArray2d{T}) = a.arr.arr

#Minimum and maximum index.
min_i{T}(arr::ExpandingArray2d{T}) = min_i(arr.arr)
max_i{T}(arr::ExpandingArray2d{T}) = max_i(arr.arr)

function min_j{T}(arr::ExpandingArray2d{T}) 
  j = typemax(Int64)
  for el in indexless_iter(arr.arr)
    j = min(j, min_i(el))
  end
  return (j==typemax(Int64) ? 0 : j) #TODO not good solution!
end
function max_j{T}(arr::ExpandingArray2d{T}) 
  j = typemin(Int64)
  for el in indexless_iter(arr.arr)
    j = max(j, max_i(el))
  end
  return (j==typemin(Int64) ? 0 : j)
end

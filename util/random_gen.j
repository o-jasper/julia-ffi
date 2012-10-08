#  Jasper den Ouden 02-08-2012
# Placed in public domain.

function pick_random(list::Vector)
  assert( !isempty(list), "Can't pick randomly from empty list." )
  return list[randi(length(list))]
end

#Generate n unique values upto given integer.
# NOTE should be equivalent to `randperm(upto)[1:n]` ?
function n_unique_below(n::Integer, upto::Integer)
  assert(n<=upto, "Don't exist $n integers below $upto.")
  list = Array(Int64,0)
  for i=1:n
    x= randi(1+upto-i)
    while contains(list,x)
      x = mod(x+1,upto)
      assert( x<=upto )
    end
    push(list,x)
  end
  return list
end

function all_adjacent(arr::Array{Bool,2}, x::Number,y::Number)
  w,h = size(arr)
  look_at(i,j) = (i<1 || i>=w || j<1 || j>=h ? false : arr[i,j])
  i,j = (floor(x),floor(y))
  return look_at(i-1,j) && look_at(i+1,j) &&
         look_at(i,j-1) && look_at(i,j+1)
end

function non_surrounded_grid(n::Integer, w::Integer,h::Integer)
  arr = Array(Bool, w,h)
  for k = 1:n
    i,j = (randi(w), randi(h))
    if !all_adjacent(arr, i,j)
      arr[i,j] = true
    end
  end
  return arr
end

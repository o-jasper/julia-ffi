
load("util/ExpandingArray.j")

function test1d(cnt::Integer, fr::Integer,to::Integer, arr)
  dict = {int64(0) => int64(0)} #Dictionary on one side.
  function set_i(i,to)
    dict[i] = to
    arr[i]  = to
    if to!=arr[i] || to!=get(dict,i,0)
      println("Immediately afterwards incorrect at $i; 
  dict: $(dict[i]) array: $(arr[i]) set: $to")
    end
  end
#Set randomly
  for n = 1:cnt
    set_i(fr + randi(to-fr), fr + randi(to-fr))
  end
#Check it.
  for i = fr:to
    d = get(dict, i,0)
    a = arr[i]
    if d != a
      println("Afterwards incorrect at $i; dict: $d array: $a")
    end
  end
#Now test iteration.
  for el in arr
    i,v = el
    d = get(dict, i,0)
    if d != v
      println("Iterated yielded incorrect value at $i; dict: $d iter: $v")
    end
  end
end
#TODO a bit repetitious..(it is just testing code though..)
function test2d(cnt::Integer, n::Integer, arr)
  dict = {(int64(0),int64(0)) => int64(0)} #Dictionary on one side.
  function set_i(i,j,to)
    dict[(i,j)] = to
    arr[i,j]  = to
    if to!=arr[i,j] || to!=get(dict,(i,j),0)
      println("Immediately afterwards incorrect at $i; 
  dict: $(dict[i]) array: $(arr[i]) set: $to")
    end
  end
#Set randomly
  for n = 1:cnt
    set_i(randi(2*n)-int(n),randi(2*n)-int(n), randi(n))
  end
#Check it.
  for i = 1:n
    for j = 1:n
      d = get(dict, (i,j),0)
      a = arr[i,j]
      if d != a
        println("Afterwards incorrect at $i; dict: $d array: $a")
      end
    end
  end
end

test1d(100, -100,100, ExpandingArray(Int64))
test2d(100, 100, ExpandingArray2d(Int64))
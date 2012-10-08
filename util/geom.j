#  Jasper den Ouden 02-08-2012
# Placed in public domain.

dist(a,b) = dist(pos(a),pos(b))
dist(a::Vector,b::Vector)    = norm(a-b)
distsqr(a,b) = dist(a,b)^2

#Returns parameter at which the lines cross.
function line2d_cross_param (r,u,v)
  det = u[1]*v[2] - u[2]*v[1]
  return ((v[2]*r[1] - u[1]*r[2])/det, (u[1]*r[1] - v[2]*r[2])/det)
end
line2d_cross_param(a,b, c,d) = line2d_cross_param(a - c, b - a, d - c)

function line2d_cross_p (r,u,v)
  lambda,mu = line2d_cross_param(r,u,v)
  return 0 <= lambda <= 1 && 0 <= mu <= 1
end
line2d_cross_p(a,b, c,d) = line2d_cross_p(a - c, b - a, d - c)

function test_line2d_cross_param (a,b, c,d)
  lambda,mu = line2d_cross_param(a,b, c,d)
  va = a + (b-a)*lambda
  vb = c + (d-c)*mu
  assert( va == vb, "No match $va $vb" )
end
function test_line2d_cross_param (cnt)
  for n = 1:cnt
    test_line2d_cross_param(randn(2),randn(2),randn(2),randn(2))
  end
end

in_range(x::Number, from::Number,to::Number) = (from<=x && x<=to)

function in_range(pos::Vector, from::Vector, to::Vector)
  assert( length(pos)==length(from) && length(pos) == length(to) )
  for i= 1:length(pos)
    if !in_range(pos[i], from[i],to[i])
      return false
    end
  end
  return true
end

in_range(x::Number,y::Number, fx::Number,fy::Number,tx::Number,ty::Number) =
    in_range(x,fx,tx) && in_range(y,fy,ty)

function in_range(x::Number,y::Number, range::(Number,Number,Number,Number))
  fx,fy,tx,ty = range
  return in_range(x,y, fx,fy,tx,ty)
end

function map_to_range(x::Number,y::Number, 
                      range::(Number,Number,Number,Number))
  fx,fy,tx,ty = range
  return map_to_range(x,y, fx,fy,tx,ty)
end
map_to_range (x::Number,y::Number, 
              fx::Number,fy::Number,tx::Number,ty::Number) =
    ((x-fx)/(tx-fx), (y-fy)/(ty-fy))

#Random generation.
rand_range(from::Number, to::Number) = from + (to-from)*rand()
function rand_range(from::Vector, to::Vector)
  assert( length(from) == length(to) )
  ret= Array(Float64,0)
  for i= 1:length(from)
    push(ret,rand_range(from[i],to[i]))
  end
  return ret
end

function rand_in_circle(radius_from::Number, radius_to::Number)
  angle = rand()*2*pi
  return [cos(angle),sin(angle)]*rand_range(radius_from,radius_to)
end

rand_in_circle(radius::Number) = rand_in_circle(0,radius)

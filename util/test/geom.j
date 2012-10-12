#TODO currently fails.

load("util/geom.j")

import Geom.*

function test_line2d_cross_param (a,b, c,d)
  lambda,mu = line2d_cross_param(a,b, c,d)
  va = a + (b-a)*lambda
  vb = c + (d-c)*mu
  assert( va == vb, "No match $va $vb" )
end
function test_line2d_cross_param (cnt)
  for n = 1:cnt
    println(n)
    test_line2d_cross_param(randn(2),randn(2),randn(2),randn(2))
  end
end

test_line2d_cross_param(100)

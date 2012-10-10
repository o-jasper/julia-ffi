#  Jasper den Ouden 02-08-2012
# Placed in public domain.

#Handy stuff to make use of Julia features.
#Probably best to stay similar to cl-opengl.

#Macro to conveniently also support tupled arguments.(TODO probably move elsewhere)
macro also_tuple(of, to)
  function getwhich(given::Expr)
    if given.head == symbol(":")
      assert( length(given.args) <=2 )
      return given.args[1]:given.args[2]
    end
    if given.head == :tuple
      return given.args
    end
    error("Invalid specification of the lengths of tuples: $to
Should be a tuple or range.") #TODO this could be better.
  end
  getwhich(given::Integer) = {given}
  ret = {}
#  nT(n) = map((i->(:T)), 1:n)
  for n = getwhich(to)
    push(ret, 
         Expr(:function,
#TODO templated it earlier, but unequal argument types make that not work.
#                   {Expr(:call, {Expr(:curly, {of,:T}, Any),
#                                 Expr(symbol("::"),
#                                      {:x,Expr(:tuple,nT(n),Any)},Any)},Any),
              {Expr(:call, 
                    {of, Expr(symbol("::"),
                              {:x,Expr(:tuple, map(i->(:Any), 1:n), Any)},
                              Any)},Any),
               Expr(:call,cat(1,{of},map((i)->:(x[$i]), 1:n)), Any)},
              Any))
  end
  return esc(Expr(:block,ret, Any))
end

#Overloading stuff
#Vertices
glvertex(i::Integer,j::Integer) = glvertex2i(i,j)
glvertex(i::Integer,j::Integer,k::Integer) = glvertex3i(i,j,k)
glvertex(i::Integer,j::Integer,k::Integer,l::Integer) = glvertex3i(i,j,k,l)

glvertex(x::Number,y::Number) = glvertex2d(x,y)
glvertex(x::Number,y::Number,z::Number) = glvertex3d(x,y,z)
glvertex(x::Number,y::Number,z::Number,w::Number) = glvertex4d(x,y,z,w)

@also_tuple glvertex 2:4

function glvertex{T}(v::Array{T,1})
  if length(v)==3
    return glvertex(v[1],v[2],v[3])
  end
  if length(v)==2
    return glvertex(v[1],v[2])
  end
  if length(v)==4
    return glvertex(v[1],v[2],v[3],v[4])
  end
end

#Texture coordinates
gltexcoord(i::Integer,j::Integer) = gltexcoord2i(i,j)
gltexcoord(i::Integer,j::Integer,k::Integer) = gltexcoord3i(i,j,k)
gltexcoord(i::Integer,j::Integer,k::Integer,l::Integer) = 
    gltexcoord3i(i,j,k,l)

gltexcoord(x::Number,y::Number) = gltexcoord2d(x,y)
gltexcoord(x::Number,y::Number,z::Number) = gltexcoord3d(x,y,z)
gltexcoord(x::Number,y::Number,z::Number,w::Number) = gltexcoord4d(x,y,z,w)
@also_tuple gltexcoord 2:4

glnormal(x::Number,y::Number,z::Number) = glnormal3d(x,y,z)
#glnormal(i::Integer,j::Integer,k::Integer) = glnormal3b(i,j,k)
@also_tuple glnormal 2:4

glcolor(r::Number,g::Number,b::Number) = glcolor3f(r,g,b)
glcolor(r::Number,g::Number,b::Number,a::Number) = glcolor4f(r,g,b,a)
@also_tuple glcolor 3:4

glcolorb(r::Integer,g::Integer,b::Integer) = glcolor3b(r,g,b)
glcolorb(r::Integer,g::Integer,b::Integer,a::Integer) = glcolor4b(r,g,b,a)
@also_tuple glcolorb 3:4

glscale(x::Number,y::Number,z::Number) = glscaled(x,y,z)
glscale(x::Number,y::Number) = glscaled(x,y,1)
glscale(s::Number) = glscaled(s,s,s)
@also_tuple glscale 1:3

gltranslate(x::Number,y::Number,z::Number) = gltranslated(x,y,z)
gltranslate(x::Number,y::Number) = gltranslated(x,y,0)
@also_tuple gltranslate 2:3

glrotate(angle::Number, nx::Number,ny::Number,nz::Number) =
    glrotated(angle, nx,ny,nz)
glrotate(angle::Number) = glrotated(angle,0,0,1)
glrotate(angle::Number, n::(Number,Number,Number)) =
    glrotate(angle, n[1],n[2],n[3])
#Damn degrees.
glrotate_r(angle::Number) = glrotate(angle*180/pi)
glrotate_r(angle::Number, nx::Number,ny::Number,nz::Number) = 
    glrotate(angle*180/pi, nx,ny,nz)
glrotate_r(angle::Number, n::(Number,Number,Number)) = 
    glrotate(angle*180/pi, n)

#Enabling lists of stuff.
type _GlEnable
  things::Vector
end

function glenable(things::Vector)
  for thing in things
    glenable(thing)
  end
  return _GlEnable(things)
end
glenable(things...) = glenable(things)
#Disabling lists of stuff
function gldisable(things::Vector)
  for thing in things
    gldisable(thing)
  end
end
gldisable(things...) = gldisable(things)

no_longer_with(enabled::_GlEnable) = gldisable(enabled.things) #!

#The whole `begin` ... `end` structures are rather bad for the savings from the 
# macros below.. 

#NOTE: if you `return` or something in the middle it won't end of course!
# (no `cl:unwind-protect`)

#glbegin for use _with_ @with
#TODO will want to upgrade that so glbegin can be used directly.
type _GlPrimitive
end
function glprimitive(primitive)
  glbegin(primitive)
  return _GlPrimitive()
end
no_longer_with(p::_GlPrimitive) = glend() #!

type _GlPushed
end
#glpushmatrix for with @with #TODO will want upgrade.
function glpushed() 
  glpushmatrix()
  return _GlPushed()
end
no_longer_with(p::_GlPushed) = glpopmatrix() #!

#More functions
function unit_frame()
  glloadidentity()
  gltranslate(-1,-1)
  glscale(2)
end
#Map the given range to the unit range.
function unit_frame_from(fx::Number,fy::Number,tx::Number,ty::Number)
  assert( fx!=tx && fy!=ty, "There might be a division by zero here.." )
  glscale(1/(tx-fx),1/(ty-fy))
  gltranslate(-fx,-fy)
end

typealias Vector2 Union((Number,Number),Vector) #(just for here)

unit_frame_from(fr::Vector2, to::Vector2) =
    unit_frame_from(fr[1],fr[2], to[1],to[2])
@also_tuple unit_frame_from 2,4

#Map the unit range to the given range.
function unit_frame_to(fx::Number,fy::Number,tx::Number,ty::Number)
  gltranslate(fx,fy)
  glscale(tx-fx, ty-fy)
end
unit_frame_to(fr::Vector2, to::Vector2) = 
    unit_frame_to(fr[1],fr[2], to[1],to[2])
@also_tuple unit_frame_from 2,4

#Rectangle vertices (in QUADS, LINE_LOOP-able style)
function rect_vertices(fx::Number,fy::Number,tx::Number,ty::Number)
  glvertex(fx,fy)
  glvertex(fx,ty)
  glvertex(tx,ty)
  glvertex(tx,fy)
end
rect_vertices(fr::Vector2, to::Vector2) = 
    rect_vertices(fr[1],fr[2], to[1],to[2])
@also_tuple rect_vertices 2,4

vertices_rect_around(x::Number,y::Number, r::Number) = 
    rect_vertices(x-r,y-r, x+r, y+r)

vertices_rect_around(pos::Vector2, r::Number) = 
   vertices_rect_around(pos[1],pos[2],r)

@also_tuple vertices_rect_around 2:3
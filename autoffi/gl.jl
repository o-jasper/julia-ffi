#Autogenerated, parameters: 
# on_file=GL/gl.h try_cnt=32 lib_var=gl
# lib_file=libGL module_name=AutoFFI_GL

#Autogenerated module of GL/gl.h.
#module AutoFFI_GL
import Base.*, GetC.*, AutoFFI_Helper.*

#Load library.

gl=dlopen("libGL")
#AutoFFI body.
@e typealias GLenum Uint32

@e typealias GLboolean Uint8

@e typealias GLbitfield Uint32

@e typealias GLvoid Void

@e typealias GLbyte Int8

@e typealias GLshort Int16

@e typealias GLint Int32

@e typealias GLubyte Uint8

@e typealias GLushort Uint16

@e typealias GLuint Uint32

@e typealias GLsizei Int32

@e typealias GLfloat Float32

@e typealias GLclampf Float32

@e typealias GLdouble Float64

@e typealias GLclampd Float64

@e @get_c_fun gl auto glClearIndex(c::GLfloat)::Void

@e @get_c_fun gl auto glIndexMask(mask::GLuint)::Void

@e @get_c_fun gl auto glBlendFunc(sfactor::GLenum, dfactor::GLenum)::Void

@e @get_c_fun gl auto glFrontFace(mode::GLenum)::Void

@e @get_c_fun gl auto glLineStipple(factor::GLint, pattern::GLushort)::Void

@e @get_c_fun gl auto glPolygonStipple(mask::Ptr{GLubyte})::Void

@e @get_c_fun gl auto glEdgeFlagv(flag::Ptr{GLboolean})::Void

@e @get_c_fun gl auto glGetClipPlane(plane::GLenum, equation::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glEnable(cap::GLenum)::Void

@e @get_c_fun gl auto glEnableClientState(cap::GLenum)::Void

@e @get_c_fun gl auto glGetBooleanv(pname::GLenum, params::Ptr{GLboolean})::Void

@e @get_c_fun gl auto glGetIntegerv(pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glPopAttrib()::Void

@e @get_c_fun gl auto glPopClientAttrib()::Void

@e @get_c_fun gl auto glGetError()::GLenum

@e @get_c_fun gl auto glFlush()::Void

@e @get_c_fun gl auto glClearDepth(depth::GLclampd)::Void

@e @get_c_fun gl auto glDepthRange(near_val::GLclampd, far_val::GLclampd)::Void

@e @get_c_fun gl auto glClearAccum(red::GLfloat, green::GLfloat, blue::GLfloat, alpha::GLfloat)::Void

@e @get_c_fun gl auto glMatrixMode(mode::GLenum)::Void

@e @get_c_fun gl auto glFrustum(left::GLdouble, right::GLdouble, bottom::GLdouble, top::GLdouble, near_val::GLdouble, far_val::GLdouble)::Void

@e )::GLsizei
@e @get_c_fun gl auto glPushMatrix()::Void

@e @get_c_fun gl auto glLoadMatrixd(m::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glRotated(angle::GLdouble, x::GLdouble, y::GLdouble, z::GLdouble)::Void

@e @get_c_fun gl auto glScaled(x::GLdouble, y::GLdouble, z::GLdouble)::Void

@e @get_c_fun gl auto glIsList(list::GLuint)::GLboolean

@e @get_c_fun gl auto glNewList(list::GLuint, mode::GLenum)::Void

@e @get_c_fun gl auto glCallLists(n::GLsizei, type::GLenum, lists::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glBegin(mode::GLenum)::Void

@e @get_c_fun gl auto glVertex2d(x::GLdouble, y::GLdouble)::Void

@e @get_c_fun gl auto glVertex3d(x::GLdouble, y::GLdouble, z::GLdouble)::Void

@e @get_c_fun gl auto glVertex4d(x::GLdouble, y::GLdouble, z::GLdouble, w::GLdouble)::Void

@e @get_c_fun gl auto glVertex2dv(v::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glVertex3dv(v::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glVertex4dv(v::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glNormal3b(nx::GLbyte, ny::GLbyte, nz::GLbyte)::Void

@e @get_c_fun gl auto glNormal3bv(v::Ptr{GLbyte})::Void

@e @get_c_fun gl auto glIndexd(c::GLdouble)::Void

@e @get_c_fun gl auto glIndexdv(c::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glColor3b(red::GLbyte, green::GLbyte, blue::GLbyte)::Void

@e @get_c_fun gl auto glColor3ub(red::GLubyte, green::GLubyte, blue::GLubyte)::Void

@e )::GLbyte
@e @get_c_fun gl auto glColor4d(red::GLdouble, green::GLdouble, blue::GLdouble, alpha::GLdouble)::Void

@e )::GLint
@e @get_c_fun gl auto glColor4s(red::GLshort, green::GLshort, blue::GLshort, alpha::GLshort)::Void

@e )::GLuint
@e @get_c_fun gl auto glColor4us(red::GLushort, green::GLushort, blue::GLushort, alpha::GLushort)::Void

@e @get_c_fun gl auto glColor3dv(v::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glColor3uiv(v::Ptr{GLuint})::Void

@e @get_c_fun gl auto glColor4fv(v::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glColor4usv(v::Ptr{GLushort})::Void

@e @get_c_fun gl auto glTexCoord1i(s::GLint)::Void

@e @get_c_fun gl auto glTexCoord2i(s::GLint, t::GLint)::Void

@e @get_c_fun gl auto glTexCoord3i(s::GLint, t::GLint, r::GLint)::Void

@e @get_c_fun gl auto glTexCoord4i(s::GLint, t::GLint, r::GLint, q::GLint)::Void

@e @get_c_fun gl auto glTexCoord1iv(v::Ptr{GLint})::Void

@e @get_c_fun gl auto glTexCoord2iv(v::Ptr{GLint})::Void

@e @get_c_fun gl auto glTexCoord3iv(v::Ptr{GLint})::Void

@e @get_c_fun gl auto glTexCoord4iv(v::Ptr{GLint})::Void

@e @get_c_fun gl auto glRasterPos2f(x::GLfloat, y::GLfloat)::Void

@e @get_c_fun gl auto glRasterPos3f(x::GLfloat, y::GLfloat, z::GLfloat)::Void

@e @get_c_fun gl auto glRasterPos4f(x::GLfloat, y::GLfloat, z::GLfloat, w::GLfloat)::Void

@e @get_c_fun gl auto glRasterPos2fv(v::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glRasterPos3fv(v::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glRasterPos4fv(v::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glRectd(x1::GLdouble, y1::GLdouble, x2::GLdouble, y2::GLdouble)::Void

@e @get_c_fun gl auto glRectdv(v1::Ptr{GLdouble}, v2::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glVertexPointer(size::GLint, type::GLenum, stride::GLsizei, ptr::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glColorPointer(size::GLint, type::GLenum, stride::GLsizei, ptr::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glTexCoordPointer(size::GLint, type::GLenum, stride::GLsizei, ptr::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glGetPointerv(pname::GLenum, params::Ptr{Ptr{GLvoid}})::Void

@e @get_c_fun gl auto glDrawElements(mode::GLenum, count::GLsizei, type::GLenum, indices::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glShadeModel(mode::GLenum)::Void

@e )::GLfloat
@e @get_c_fun gl auto glLightiv(light::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glGetLightiv(light::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glLightModelfv(pname::GLenum, params::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glMaterialfv(face::GLenum, pname::GLenum, params::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glColorMaterial(face::GLenum, mode::GLenum)::Void

@e @get_c_fun gl auto glPixelZoom(xfactor::GLfloat, yfactor::GLfloat)::Void

@e @get_c_fun gl auto glPixelTransferf(pname::GLenum, param::GLfloat)::Void

@e @get_c_fun gl auto glPixelMapuiv(map::GLenum, mapsize::GLsizei, values::Ptr{GLuint})::Void

@e @get_c_fun gl auto glGetPixelMapfv(map::GLenum, values::Ptr{GLfloat})::Void

@e )::GLfloat
@e @get_c_fun gl auto glReadPixels(x::GLint, y::GLint, width::GLsizei, height::GLsizei, format::GLenum, type::GLenum, pixels::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glDrawPixels(width::GLsizei, height::GLsizei, format::GLenum, type::GLenum, pixels::Ptr{GLvoid})::Void

@e )::GLsizei
@e @get_c_fun gl auto glStencilFunc(func::GLenum, ref::GLint, mask::GLuint)::Void

@e @get_c_fun gl auto glClearStencil(s::GLint)::Void

@e @get_c_fun gl auto glTexGend(coord::GLenum, pname::GLenum, param::GLdouble)::Void

@e @get_c_fun gl auto glTexGenfv(coord::GLenum, pname::GLenum, params::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glGetTexGeniv(coord::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glTexEnvfv(target::GLenum, pname::GLenum, params::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glTexParameterf(target::GLenum, pname::GLenum, param::GLfloat)::Void

@e @get_c_fun gl auto glTexParameteriv(target::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glGetTexParameteriv(target::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glGetTexLevelParameteriv(target::GLenum, level::GLint, pname::GLenum, params::Ptr{GLint})::Void

@e )::GLint
@e @get_c_fun gl auto glTexImage2D(target::GLenum, level::GLint, internalFormat::GLint, width::GLsizei, height::GLsizei, border::GLint, format::GLenum, type::GLenum, pixels::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glGetTexImage(target::GLenum, level::GLint, format::GLenum, type::GLenum, pixels::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glGenTextures(n::GLsizei, textures::Ptr{GLuint})::Void

@e @get_c_fun gl auto glPrioritizeTextures(n::GLsizei, textures::Ptr{GLuint}, priorities::Ptr{GLclampf})::Void

@e )::GLuint
@e @get_c_fun gl auto glIsTexture(texture::GLuint)::GLboolean

@e )::GLsizei
@e @get_c_fun gl auto glTexSubImage2D(target::GLenum, level::GLint, xoffset::GLint, yoffset::GLint, width::GLsizei, height::GLsizei, format::GLenum, type::GLenum, pixels::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glCopyTexImage1D(target::GLenum, level::GLint, internalformat::GLenum, x::GLint, y::GLint, width::GLsizei, border::GLint)::Void

@e @get_c_fun gl auto glCopyTexImage2D(target::GLenum, level::GLint, internalformat::GLenum, x::GLint, y::GLint, width::GLsizei, height::GLsizei, border::GLint)::Void

@e @get_c_fun gl auto glCopyTexSubImage1D(target::GLenum, level::GLint, xoffset::GLint, x::GLint, y::GLint, width::GLsizei)::Void

@e @get_c_fun gl auto glCopyTexSubImage2D(target::GLenum, level::GLint, xoffset::GLint, yoffset::GLint, x::GLint, y::GLint, width::GLsizei, height::GLsizei)::Void

@e @get_c_fun gl auto glMap1d(target::GLenum, u1::GLdouble, u2::GLdouble, stride::GLint, order::GLint, points::Ptr{GLdouble})::Void

@e )::GLint
@e @get_c_fun gl auto glMap2d(target::GLenum, u1::GLdouble, u2::GLdouble, ustride::GLint, uorder::GLint, v1::GLdouble, v2::GLdouble, vstride::GLint, vorder::GLint, points::Ptr{GLdouble})::Void

@e )::GLfloat
@e @get_c_fun gl auto glGetMapdv(target::GLenum, query::GLenum, v::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glEvalCoord1f(u::GLfloat)::Void

@e @get_c_fun gl auto glEvalCoord2d(u::GLdouble, v::GLdouble)::Void

@e @get_c_fun gl auto glMapGrid1d(un::GLint, u1::GLdouble, u2::GLdouble)::Void

@e @get_c_fun gl auto glMapGrid2f(un::GLint, u1::GLfloat, u2::GLfloat, vn::GLint, v1::GLfloat, v2::GLfloat)::Void

@e @get_c_fun gl auto glEvalPoint2(i::GLint, j::GLint)::Void

@e @get_c_fun gl auto glFogf(pname::GLenum, param::GLfloat)::Void

@e @get_c_fun gl auto glFogiv(pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glFeedbackBuffer(size::GLsizei, type::GLenum, buffer::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glInitNames()::Void

@e @get_c_fun gl auto glPopName()::Void

@e @get_c_fun gl auto glTexImage3D(target::GLenum, level::GLint, internalFormat::GLint, width::GLsizei, height::GLsizei, depth::GLsizei, border::GLint, format::GLenum, type::GLenum, pixels::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glTexSubImage3D(target::GLenum, level::GLint, xoffset::GLint, yoffset::GLint, zoffset::GLint, width::GLsizei, height::GLsizei, depth::GLsizei, format::GLenum, type::GLenum, pixels::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glCopyTexSubImage3D(target::GLenum, level::GLint, xoffset::GLint, yoffset::GLint, zoffset::GLint, x::GLint, y::GLint, width::GLsizei, height::GLsizei)::Void

@e )::GLsizei
@e @get_c_fun gl auto glColorSubTable(target::GLenum, start::GLsizei, count::GLsizei, format::GLenum, type::GLenum, data::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glColorTableParameteriv(target::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glCopyColorSubTable(target::GLenum, start::GLsizei, x::GLint, y::GLint, width::GLsizei)::Void

@e @get_c_fun gl auto glGetColorTable(target::GLenum, format::GLenum, type::GLenum, table::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glGetColorTableParameteriv(target::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glBlendColor(red::GLclampf, green::GLclampf, blue::GLclampf, alpha::GLclampf)::Void

@e @get_c_fun gl auto glResetHistogram(target::GLenum)::Void

@e @get_c_fun gl auto glGetHistogramParameterfv(target::GLenum, pname::GLenum, params::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glMinmax(target::GLenum, internalformat::GLenum, sink::GLboolean)::Void

@e @get_c_fun gl auto glGetMinmax(target::GLenum, reset::GLboolean, format::GLenum, types::GLenum, values::Ptr{GLvoid})::Void

@e )::GLfloat
@e @get_c_fun gl auto glGetMinmaxParameteriv(target::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e )::GLvoid
@e @get_c_fun gl auto glConvolutionFilter2D(target::GLenum, internalformat::GLenum, width::GLsizei, height::GLsizei, format::GLenum, type::GLenum, image::Ptr{GLvoid})::Void

@e )::GLfloat
@e @get_c_fun gl auto glConvolutionParameterfv(target::GLenum, pname::GLenum, params::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glConvolutionParameteriv(target::GLenum, pname::GLenum, params::Ptr{GLint})::Void

@e @get_c_fun gl auto glCopyConvolutionFilter2D(target::GLenum, internalformat::GLenum, x::GLint, y::GLint, width::GLsizei, height::GLsizei)::Void

@e )::GLenum
@e @get_c_fun gl auto glGetConvolutionParameterfv(target::GLenum, pname::GLenum, params::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glSeparableFilter2D(target::GLenum, internalformat::GLenum, width::GLsizei, height::GLsizei, format::GLenum, type::GLenum, row::Ptr{GLvoid}, column::Ptr{GLvoid})::Void

@e )::GLenum
@e @get_c_fun gl auto glActiveTexture(texture::GLenum)::Void

@e @get_c_fun gl auto glCompressedTexImage2D(target::GLenum, level::GLint, internalformat::GLenum, width::GLsizei, height::GLsizei, border::GLint, imageSize::GLsizei, data::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glCompressedTexSubImage2D(target::GLenum, level::GLint, xoffset::GLint, yoffset::GLint, width::GLsizei, height::GLsizei, format::GLenum, imageSize::GLsizei, data::Ptr{GLvoid})::Void

@e @get_c_fun gl auto glMultiTexCoord1d(target::GLenum, s::GLdouble)::Void

@e @get_c_fun gl auto glMultiTexCoord1fv(target::GLenum, v::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glMultiTexCoord1s(target::GLenum, s::GLshort)::Void

@e @get_c_fun gl auto glMultiTexCoord2dv(target::GLenum, v::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glMultiTexCoord2i(target::GLenum, s::GLint, t::GLint)::Void

@e @get_c_fun gl auto glMultiTexCoord2sv(target::GLenum, v::Ptr{GLshort})::Void

@e @get_c_fun gl auto glMultiTexCoord3f(target::GLenum, s::GLfloat, t::GLfloat, r::GLfloat)::Void

@e @get_c_fun gl auto glMultiTexCoord3iv(target::GLenum, v::Ptr{GLint})::Void

@e @get_c_fun gl auto glMultiTexCoord4d(target::GLenum, s::GLdouble, t::GLdouble, r::GLdouble, q::GLdouble)::Void

@e @get_c_fun gl auto glMultiTexCoord4fv(target::GLenum, v::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glMultiTexCoord4s(target::GLenum, s::GLshort, t::GLshort, r::GLshort, q::GLshort)::Void

@e @get_c_fun gl auto glLoadTransposeMatrixd(m::Ptr{GLdouble})::Void

@e @get_c_fun gl auto glMultTransposeMatrixf(m::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glActiveTextureARB(texture::GLenum)::Void

@e @get_c_fun gl auto glMultiTexCoord1fvARB(target::GLenum, v::Ptr{GLfloat})::Void

@e @get_c_fun gl auto glMultiTexCoord2dARB(target::GLenum, s::GLdouble, t::GLdouble)::Void

@e @get_c_fun gl auto glMultiTexCoord2ivARB(target::GLenum, v::Ptr{GLint})::Void

@e @get_c_fun gl auto glMultiTexCoord3fARB(target::GLenum, s::GLfloat, t::GLfloat, r::GLfloat)::Void

@e @get_c_fun gl auto glMultiTexCoord3svARB(target::GLenum, v::Ptr{GLshort})::Void

@e @get_c_fun gl auto glMultiTexCoord4iARB(target::GLenum, s::GLint, t::GLint, r::GLint, q::GLint)::Void

@e @get_c_fun gl auto glGetProgramRegisterfvMESA(target::GLenum, len::GLsizei, name::Ptr{GLubyte}, v::Ptr{GLfloat})::Void

@e typealias GLeglImageOES Ptr{Void}

module AutoFFI_GL
end #module AutoFFI_GL

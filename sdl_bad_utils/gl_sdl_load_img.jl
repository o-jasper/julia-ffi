#  Jasper den Ouden 16-08-2012
# Placed in public domain.

module GL_SDL_LoadImg
#Loading images int GL and/or SDL.

using Base, GetC, AutoFFI_GL

export sdl_free_surface, sdl_load_img, gl_sdl_load_img
export IMG_Load, sdl_surface_w,sdl_surface_h

#----no more module stuff.

#@get_c_fun :libSDL sdl_free_surface SDL_FreeSurface(ptr::Ptr)::Void
@get_c_fun :libSDL sdl_free_surface SDL_FreeSurface(ptr::Ptr)::Void

IMG_Load(file::String) =
    ccall((:IMG_Load, :libSDL_image), Ptr,(Ptr{Uint8},), bytestring(file))

gl_sdl_load_img_lib = load_so("sdl_bad_utils/gl_sdl_load_img.so")

@get_c_fun gl_sdl_load_img_lib auto gl_sdl_load_img(index::GLuint, 
                                                    surface::Ptr,
                                                    format::GLenum, 
                                                    w::Int32,h::Int32)::GLuint

function gl_sdl_load_img(surf::Ptr, format::Integer, w::Integer,h::Integer, 
                         prepare::Bool)
    if prepare
        glenable({GL_TEXTURE_2D, GL_BLEND})
    end
    val = ccall(dlsym(gl_sdl_load_img_lib, :gl_sdl_load_img),
                GLuint, (Ptr,GLenum,GLint,GLint), 
                surf, convert(GLenum, format), w,h)
    if prepare
        gldisable({GL_TEXTURE_2D, GL_BLEND})
    end
    return val
end
#Cant use @get_c_fun due to it not supporting String conversion yet.
function gl_sdl_load_img(file::String, format::Integer, w::Integer,h::Integer,
                         prepare::Bool)
    surf = IMG_Load(file)
    val = gl_sdl_load_img(surf, format, w,h, prepare)
    sdl_free_surface(surf)
    return val
end

gl_sdl_load_img(img, format::Integer, w::Integer,h::Integer) = #!
    gl_sdl_load_img(img, format, w,h, true)

gl_sdl_load_img(img, format::Integer) = #!
    gl_sdl_load_img(img, format, -1,-1)
gl_sdl_load_img(img) = #!
    gl_sdl_load_img(img, -1)

@get_c_fun gl_sdl_load_img_lib auto sdl_surface_w(surf::Ptr)::Int32
@get_c_fun gl_sdl_load_img_lib auto sdl_surface_h(surf::Ptr)::Int32

# NOTE: DOESN'T WORK
#@get_c_fun gl_sdl_load_img_lib auto combine_w_alpha(surf::Ptr,alpha::Ptr,way::Uint32)::Ptr

end #module GL_SDL_LoadImg
//  Jasper den Ouden 16-08-2012
// Placed in public domain.


#include <GL/gl.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <assert.h>

void texture_enter_gl(GLuint index, SDL_Surface* surf,
		      GLenum format, int w,int h)
{
  if( w<0 ){ w= surf->w; } //Use existing size if none specifically given.
  if( h<0 ){ h= surf->h; }

  glBindTexture(GL_TEXTURE_2D, index);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//TODO not always 4..
  glTexImage2D(GL_TEXTURE_2D, 0, surf->format->Amask ? 4 : 3, w,h, 0, 
	       format==-1 ? (surf->format->Amask ? GL_RGBA : GL_RGB) : format,
	       GL_UNSIGNED_BYTE, surf->pixels);
}
//TODO expand? if file ends with _rgb.(png|jpg), 
// look for an ending with _a.(png|jpg), if so, combine them.
GLuint gl_sdl_load_img(SDL_Surface* surf, GLenum format, GLint w,GLint h)
{
  if( surf==NULL ){ return 0; } //Failure.
  GLuint index = 0;
  glGenTextures(1, &index); //Get an index.
  texture_enter_gl(index, surf, format, w,h);
  return index;
}
//NOTE: DOESN'T WORK
//Loads with alpha. Note that a SDL_Surface may also have an alpha as plain.(
// (Actually making such a surface is what it does,
SDL_Surface* combine_w_alpha(SDL_Surface* surf,SDL_Surface* alpha, unsigned way)
{ 
  assert( surf->w == alpha->w );
  assert( surf->h == alpha->h );
  
  assert( surf->format->BytesPerPixel==3 );
  assert( alpha->format->BytesPerPixel==3 );

  SDL_Surface* n = (SDL_Surface*)malloc(sizeof(SDL_Surface));
  n->flags = 0;
//The format. (little annoying to fill..)
  n->format = (SDL_PixelFormat*)malloc(sizeof(SDL_PixelFormat));
  memcpy(n->format, surf->format, sizeof(SDL_PixelFormat)); //Should do all RGB stuff.
  n->format->palette = NULL;
  n->format->BytesPerPixel = 4; //One more byte.(adding alpha)
  n->format->BitsPerPixel = 8*n->format->BytesPerPixel;
  n->format->Amask = 0x000000ff; //Set up alpha.
  n->format->Aloss = 0;
  n->format->Ashift = 3*8;
  n->format->colorkey = 0;
  n->format->alpha = 0;
  
  n->w = surf->w; n->h = surf->h; //Width, and height
  int w= n->w, h= n->h;
  n->pitch = 4*surf->w;
  n->pixels = malloc(n->pitch*surf->h); //Pixel data.
  n->clip_rect.x=0; n->clip_rect.y=0;
  n->clip_rect.w= w; n->clip_rect.h=h;
  n->refcount = 0;
//Now to finally actually do stuff..
  unsigned char* na= (unsigned char*)n->pixels;
  unsigned char* sa= (unsigned char*)surf->pixels;
  unsigned char* aa= (unsigned char*)alpha->pixels;
  for( int j=0 ; j< h ; j++ )
    { for( int i=0 ; i< w ; i++ )
	{
	  unsigned char* nc= na + 4*i + j*n->pitch;
	  unsigned char* sc= sa + 3*i + j*surf->pitch;
	  unsigned char* ac= aa + 3*i + j*alpha->pitch;
	  nc[0] = sa[0]; nc[1] = sa[1]; nc[2] = sa[2];
	  switch(way/4)
	    { case 0: nc[3] = (ac[0] + ac[1] + ac[2])/3; break; //Average it.
	      case 1: nc[3] = ac[0]; break; //Red.
	      case 2: nc[3] = ac[1]; break; //Blue.
	      case 3: nc[3] = ac[2]; break; //Green.
	    }
	}
    }
  if( way&1 ){ SDL_FreeSurface(surf); }
  if( way&2 ){ SDL_FreeSurface(alpha); }
  return n;
}

int sdl_surface_w(SDL_Surface* surf)
{ return surf->w; }
int sdl_surface_h(SDL_Surface* surf)
{ return surf->h; }

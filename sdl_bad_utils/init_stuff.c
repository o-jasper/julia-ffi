//  Jasper den Ouden 02-08-2012
// Placed in public domain.

const int True = 1, False= 0;

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#include <GL/gl.h>
#include <GL/glu.h>
#include <SDL/SDL.h>

int reference_block() //Block drawn to give absolute reference somewhat.
{
  glColor3f(1,1,1);
  glPushMatrix();
    glScalef(0.5,0.5,1);
    glBegin( GL_QUADS );
      glVertex3f(  1.0f,  1.0f,  0.0f );
      glVertex3f( -1.0f,  1.0f,  0.0f );
      glVertex3f( -1.0f, -1.0f,  0.0f );
      glVertex3f(  1.0f, -1.0f,  0.0f );
    glEnd();
  glPopMatrix();
}

int screen_width = 640, screen_height = 640;
short screen_bpp = 16;

SDL_Surface *surface;
int videoFlags=0;

// function to reset our viewport after a window resize.
void resize_window(int w, int h)
{
  glViewport( 0, 0, (GLsizei)w, (GLsizei)h);
  glMatrixMode( GL_PROJECTION );
  glLoadIdentity();
  glMatrixMode( GL_MODELVIEW );
  // Reset The View
  glLoadIdentity(); //TODO hmm actually need to correct aspect ratio.
}

// general OpenGL initialization function.
void init_gl()
{
  // Set the background black.
  glClearColor(0,0,0,0);
  glDisable(GL_DEPTH_TEST);
}

int init_stuff(int screen_width,int screen_height)
{
  //  SDL_Event event;
  const SDL_VideoInfo *videoInfo;
  if ( SDL_Init( SDL_INIT_VIDEO ) < 0 )
    { fprintf( stderr, "Video initialization failed: %s\n",
	       SDL_GetError() ); }
  videoInfo = SDL_GetVideoInfo();
  if ( !videoInfo )
    { fprintf( stderr, "Video query failed: %s\n", SDL_GetError() ); }
  // the flags to pass to SDL_SetVideoMode.
  videoFlags  = SDL_OPENGL          // Enable OpenGL in SDL.
              | SDL_GL_DOUBLEBUFFER // Enable double buffering.
              | SDL_HWPALETTE       // Store the palette in hardware.
              | SDL_RESIZABLE;      // Enable window resizing.
// Check stuff.
  if ( videoInfo->hw_available )
    videoFlags |= SDL_HWSURFACE;
  else
    videoFlags |= SDL_SWSURFACE;
  if ( videoInfo->blit_hw )
    videoFlags |= SDL_HWACCEL;
  SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
  surface = SDL_SetVideoMode( screen_width, screen_height, screen_bpp,
			      videoFlags );
// Verify there is a surface.
  if ( !surface )
    { fprintf( stderr,  "Video mode set failed: %s\n", SDL_GetError() ); }
// initialize OpenGL.
  init_gl();
// resize the initial window.
  resize_window( screen_width, screen_height );
}

int finalize_draw ()
{
  SDL_GL_SwapBuffers();
  glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
  glLoadIdentity(); 
}

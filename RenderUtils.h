 /*
 *  RenderUtils.h
 *  GLExample
 *
 *  Created by  on 8/15/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "SDL/SDL.h"
#include "SDL/SDL_opengl.h"
#include <Foundation/Foundation.h>

//vars
NSMutableDictionary* textureDictionary;
GLuint glGlobalLastTexID;
GLfloat* glGlobalLastSpriteVertices;
static GLubyte glGlobalSpriteIndexOrder[]={0,1,2,3};

//functions
GLuint LoadTexture(SDL_Surface* spriteImage, NSString *key);
void ShowAlertBox(NSString *title, NSString *message, id *view);

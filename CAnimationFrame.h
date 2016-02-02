 //
//  CAnimationFrame.h
//  GLExample
//
//  Created by  on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#include <Foundation/Foundation.h>
#include "SDL/SDL_opengl.h"

@interface CAnimationFrame : NSObject {
	@public
	int clipx;
	int clipy;
	int clipw;
	int cliph;
	GLubyte red;
	GLubyte green;
	GLubyte blue;
	GLubyte alpha;
	float angle;
	float scale_x;
	float scale_y;
	int type;
	double duration;
	NSString* animation;

	//for clip type only
	GLfloat* spriteVertices;
	GLfloat* spriteTexcoords;
	boolean isOptimized;
}
/*
@property boolean isOptimized;
@property (retain) NSString* animation;
@property int type;
@property double duration;
@property int clipx;
@property int clipy;
@property int clipw;
@property int cliph;
@property GLubyte red;
@property GLubyte green;
@property GLubyte blue;
@property GLubyte alpha;
@property float angle;
@property float scale_x;
@property float scale_y;
@property GLfloat* spriteVertices;
@property GLfloat* spriteTexcoords;
*/
- (id) initWithType:(NSString*)type:(double)duration;

@end

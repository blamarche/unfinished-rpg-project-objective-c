 //
//  CAnimationFrame.m
//  GLExample
//
//  Created by  on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CAnimationFrame.h"
#define true YES
#define false NO
#define bool boolean

@implementation CAnimationFrame
/*
@synthesize clipx;
@synthesize clipy;
@synthesize clipw;
@synthesize cliph;
@synthesize red;
@synthesize green;
@synthesize blue;
@synthesize alpha;
@synthesize angle;
@synthesize scale_x;
@synthesize scale_y;
@synthesize type;
@synthesize duration;
@synthesize animation;
@synthesize spriteVertices;
@synthesize spriteTexcoords;
@synthesize isOptimized;
*/
- (id) initWithType:(NSString*)ftype:(double)fduration
{
	self=[super init];
	
	self->isOptimized=false;
	if ([ftype compare:@"clip"]==NSOrderedSame){
		self->type = 1;
		self->spriteVertices = malloc(sizeof(GLfloat)*8);
		self->spriteTexcoords = malloc(sizeof(GLfloat)*8);
	}
	else if ([ftype compare:@"alpha"]==NSOrderedSame)
		self->type = 2;
	else if ([ftype compare:@"overlay"]==NSOrderedSame)
		self->type = 3;
	else if ([ftype compare:@"rotate"]==NSOrderedSame)
		self->type = 4;
	else if ([ftype compare:@"scale"]==NSOrderedSame)
		self->type = 5;
	else if ([ftype compare:@"animation"]==NSOrderedSame)
		self->type = 6;
	else if ([ftype compare:@"collision"]==NSOrderedSame)
		self->type = 7;
		
	self->duration=fduration;
	
	return self;
}

@end

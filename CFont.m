 //
//  CFont.m
//  GLExample
//
//  Created by  on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSprite.h"
#import "CFont.h"
#define true YES
#define false NO
#define bool boolean

@implementation CFont
/*
@synthesize sprite;
@synthesize startchar;
*/
- (id) initWithFile:(NSString*) imgfile : (int)startingChar
{
	self = [super init];
	
	self->sprite = [[CSprite alloc] initWithFile:imgfile];
	frame = [[CAnimationFrame alloc] initWithType:@"clip" : 0];
	
	[self->sprite setOverlayWithRed:255 :255 :255 :255];
	
	charw = self->sprite->width/16;
	charh = self->sprite->height/16;
	self->startchar = startingChar;
	int i;
	for ( i=0; i<256; i++)
	{
		int cx=i%16;
		int cy=i/16;
		
		float scx=(float)cx*charw/(float)self->sprite->width;
		float scy=(float)cy*charh/(float)self->sprite->height;
		float scw=(float)charw/(float)self->sprite->width;
		float sch=(float)charh/(float)self->sprite->height;
		float scx2=scx+scw;
		float scy2=scy+sch;
		
		spriteTexcoords[i][0] = scx;
		spriteTexcoords[i][1] = scy;
		spriteTexcoords[i][2] = scx2;
		spriteTexcoords[i][3] = scy;
		spriteTexcoords[i][4] = scx;
		spriteTexcoords[i][5] = scy2;
		spriteTexcoords[i][6] = scx2;
		spriteTexcoords[i][7] = scy2;
	}
	
	frame->spriteVertices[0] = 0;
	frame->spriteVertices[1] = 0;
	frame->spriteVertices[2] = charw;
	frame->spriteVertices[3] =0;
	frame->spriteVertices[4] = 0;
	frame->spriteVertices[5] = charh;
	frame->spriteVertices[6] =charw;
	frame->spriteVertices[7] = charh;
	
	return self;
}

- (void) renderStringAt:(int)x:(int)y:(NSString*) toRender:(int)spacing:(int)charoffset
{
	const char * st = [toRender cStringUsingEncoding:NSASCIIStringEncoding];
	int i;
	for (i = 0; i<[toRender length]; i++)
	{
		char c = st[i];
		unsigned int asc = (unsigned int)c - self->startchar + charoffset;
		
		frame->spriteTexcoords[0] = spriteTexcoords[asc][0];
		frame->spriteTexcoords[1] = spriteTexcoords[asc][1];
		frame->spriteTexcoords[2] = spriteTexcoords[asc][2];
		frame->spriteTexcoords[3] = spriteTexcoords[asc][3];
		frame->spriteTexcoords[4] = spriteTexcoords[asc][4];
		frame->spriteTexcoords[5] = spriteTexcoords[asc][5];
		frame->spriteTexcoords[6] = spriteTexcoords[asc][6];
		frame->spriteTexcoords[7] = spriteTexcoords[asc][7];

		sprite->x = (i*spacing)+x;
		sprite->y = y;
		[self->sprite setRenderAreaWithFrame:frame];
		[self->sprite render:false];
	}
}

- (void) setColorWithRed:(int)red: (int) green: (int) blue: (int) alpha
{
	[self->sprite setOverlayWithRed:red :green :blue :alpha];
}

@end

 //
//  CFont.m
//  GLExample
//
//  Created by  on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSprite.h"
#import "CTileSheet.h"
#define true YES
#define false NO
#define bool boolean

@implementation CTileSheet

- (id) initWithFile:(NSString*) imgfile : (int)tileSize
{
	self = [super init];

	self->sprite = [[CSprite alloc] initWithFile:imgfile];
	frame = [[CAnimationFrame alloc] initWithType:@"clip" : 0];

	//[self->sprite setOverlayWithRed:255 :255 :255 :255];

	tilew = self->sprite->width/tileSize;
	tileh = self->sprite->height/tileSize;
	self->tileSize = tileSize;
	int i;

	double tw=((double)tileSize-0.0)/(double)self->sprite->width;
	double th=((double)tileSize-0.0)/(double)self->sprite->height;

	for ( i=0; i<tilew*tileh; i++)
	{
		int cx=i%tilew;
		int cy=i/tileh;

		float scx=(double)(cx*tileSize)/(double)self->sprite->width;
		float scy=(double)(cy*tileSize)/(double)self->sprite->height;
		float scw=tw;
		float sch=th;
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
	frame->spriteVertices[2] = tileSize;
	frame->spriteVertices[3] =0;
	frame->spriteVertices[4] = 0;
	frame->spriteVertices[5] = tileSize;
	frame->spriteVertices[6] =tileSize;
	frame->spriteVertices[7] = tileSize;

	return self;
}

- (void) renderTileAtIndex:(int)index:(int)x:(int)y:(int)z:(bool)usePerspective:(float)td_angle_x:(float)td_angle_y:(bool)isCube
{
	sprite->z = z;
	frame->spriteTexcoords[0] = spriteTexcoords[index][0];
	frame->spriteTexcoords[1] = spriteTexcoords[index][1];
	frame->spriteTexcoords[2] = spriteTexcoords[index][2];
	frame->spriteTexcoords[3] = spriteTexcoords[index][3];
	frame->spriteTexcoords[4] = spriteTexcoords[index][4];
	frame->spriteTexcoords[5] = spriteTexcoords[index][5];
	frame->spriteTexcoords[6] = spriteTexcoords[index][6];
	frame->spriteTexcoords[7] = spriteTexcoords[index][7];

	if (isCube && usePerspective)
	{
		[self->sprite setRenderAreaWithFrame:frame];

		sprite->x = x;
		sprite->y = y;
		sprite->z = z+self->tileSize;
		sprite->td_angle_x = 90;
		sprite->td_angle_y = 0;
		[self->sprite render:usePerspective];

		sprite->x = x;
		sprite->y = y;
		sprite->z = z+self->tileSize;
		sprite->td_angle_x = 90;
		sprite->td_angle_y = 90;
		[self->sprite render:usePerspective];

		sprite->x = x+self->tileSize;
		sprite->y = y;
		sprite->z = z+self->tileSize;
		sprite->td_angle_x = 90;
		sprite->td_angle_y = 90;
		[self->sprite render:usePerspective];

		sprite->x = x;
		sprite->y = y+self->tileSize;
		sprite->z = z+self->tileSize;
		sprite->td_angle_x = 90;
		sprite->td_angle_y = 0;
		[self->sprite render:usePerspective];

		sprite->x = x;
		sprite->y = y;
		sprite->z = self->tileSize + z;
		sprite->td_angle_x = 0;
		sprite->td_angle_y = 0;
		//[self->sprite render:usePerspective];
	}
	else
	{
		sprite->x = x;
		sprite->y = y;
		sprite->td_angle_x = td_angle_x;
		sprite->td_angle_y = td_angle_y;
		[self->sprite setRenderAreaWithFrame:frame];
		[self->sprite render:usePerspective];
	}
}

/*
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
*/

- (void) setColorWithRed:(int)red: (int) green: (int) blue: (int) alpha
{
	[self->sprite setOverlayWithRed:red :green :blue :alpha];
}

@end

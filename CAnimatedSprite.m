 //
//  CAnimatedSprite.m
//  GLExample
//
//  Created by  on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CAnimatedSprite.h"
#include "SDL/SDL.h"
#include "SDL/SDL_opengl.h"
#define true YES
#define false NO

@implementation CAnimatedSprite
/*
@synthesize frame;
@synthesize sprite;
@synthesize animations;
@synthesize lastTime;
*/
- (id) initWithSprite:(CSprite*)_sprite
{
	self = [super init];
	
	self->sprite=_sprite;
	self->animations=[[NSMutableDictionary alloc] initWithCapacity:3];
	self->frame=0;
	
	return self;
}

- (void) optimizeAnimations
{
	NSEnumerator* animenum = [self->animations objectEnumerator];
	CAnimation* anim;
	while (anim = [animenum nextObject])
	{
		int j;
		for (j = 0;j<[anim->frames count]; j++)
		{
			CAnimationFrame* cframe = [anim->frames objectAtIndex:j];
			if (cframe->type==1)
			{
				float scx=(float)cframe->clipx/(float)self->sprite->width;
				float scy=(float)cframe->clipy/(float)self->sprite->height;
				float scw=(float)cframe->clipw/(float)self->sprite->width;
				float sch=(float)cframe->cliph/(float)self->sprite->height;
				float scx2=scx+scw;
				float scy2=scy+sch;
				cframe->spriteTexcoords[0] = scx;
				cframe->spriteTexcoords[1] = scy;
				cframe->spriteTexcoords[2] = scx2;
				cframe->spriteTexcoords[3] = scy;
				cframe->spriteTexcoords[4] = scx;
				cframe->spriteTexcoords[5] = scy2;
				cframe->spriteTexcoords[6] = scx2;
				cframe->spriteTexcoords[7] = scy2;
				
				float scaleWidth = cframe->clipw;
				float scaleHeight = cframe->cliph;
				cframe->spriteVertices[0] = -1.0f*scaleWidth/2.0f;
				cframe->spriteVertices[1] = -1.0f*scaleHeight/2.0f;
				cframe->spriteVertices[2] = scaleWidth/2.0f;
				cframe->spriteVertices[3] =-1.0f*scaleHeight/2.0f;
				cframe->spriteVertices[4] = -1.0f*scaleWidth/2.0f;
				cframe->spriteVertices[5] = scaleHeight/2.0f;
				cframe->spriteVertices[6] =scaleWidth/2.0f;
				cframe->spriteVertices[7] = scaleHeight/2.0f;
				cframe->isOptimized=true;
			}
		}
	}
}

- (void) shareAnimationsWith:(CAnimatedSprite*)otherSprite
{
	self->animations=otherSprite->animations;
	[self setCurrentAnimation:[otherSprite getCurrentAnimation]: false];
	self->frame=otherSprite->frame;
}

- (void) addAnimationsFromFile:(NSString*)filepath:(boolean)doOptimize
{
	NSString* fullpath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"] stringByAppendingString:filepath];
	
	NSError* err;
	NSString* fileString = [NSString stringWithContentsOfFile:fullpath];
		
	NSArray* lines = [fileString componentsSeparatedByString:@"\n"];
	
	NSString* thisanim = @"";
	NSString* firstanim = @"";
	NSString* line = @"";
	
	CAnimation* animObj;
	int i;
	for ( i=0; i<[lines count]; i++)
	{
		line = [(NSString*)[lines objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if ([line length]>0)
		{
			unichar firstchar	= [line characterAtIndex:0];
			if (firstchar==':'){
				thisanim = [line substringFromIndex:1];
				if ([firstanim compare:@""]==NSOrderedSame)
					firstanim = thisanim;
				
				CAnimation* tmpanim = [[CAnimation alloc] init];
				[self->animations setObject:tmpanim forKey:thisanim];
				animObj = [self->animations objectForKey:thisanim];
			} else if (firstchar =='!'){
				//macro
				
				
			} else if (firstchar != '#' && [line length]>0){
				NSString* type = [line substringToIndex:[line rangeOfString:@"="].location];
				line = [line substringFromIndex:[line rangeOfString:@"="].location+1];
				NSArray* params = [line componentsSeparatedByString:@","];
				int iduration = [(NSString*)[params objectAtIndex:0] intValue];
				double duration = (double)iduration/1000.0;
				
				CAnimationFrame* thisframe = [animObj addFrame: type : duration];
				
				switch (thisframe->type)
				{
					case 1:	//clip
						thisframe->clipx=[(NSString*)[params objectAtIndex:1] intValue];
						thisframe->clipy=[(NSString*)[params objectAtIndex:2] intValue];
						thisframe->clipw=[(NSString*)[params objectAtIndex:3] intValue];
						thisframe->cliph=[(NSString*)[params objectAtIndex:4] intValue];				
						break;					
					case 2:	//alpha
						thisframe->alpha = [(NSString*)[params objectAtIndex:1] intValue];
						break;					
					case 3:	//overlay
						thisframe->red=[(NSString*)[params objectAtIndex:1] intValue];
						thisframe->green=[(NSString*)[params objectAtIndex:2] intValue];
						thisframe->blue=[(NSString*)[params objectAtIndex:3] intValue];
						break;					
					case 4:	//rotate
						thisframe->angle = [(NSString*)[params objectAtIndex:1] intValue];
						break;					
					case 5:	//scale
						thisframe->scale_x = [(NSString*)[params objectAtIndex:1] floatValue];
						thisframe->scale_y = [(NSString*)[params objectAtIndex:2] floatValue];
						break;
					case 6:	//animation
						thisframe->animation = (NSString*) [params objectAtIndex:1] ;
						break;		
					case 7:	//collision
						thisframe->scale_x = [(NSString*)[params objectAtIndex:1] floatValue];
						thisframe->scale_y = [(NSString*)[params objectAtIndex:2] floatValue];
						break;
				}
			}
		}
	}
	
	[self setCurrentAnimation:firstanim:false];
	
	if (doOptimize)
		[self optimizeAnimations];
}

- (NSString*) getCurrentAnimation
{
	return currentAnimationName;
}

- (void) setCurrentAnimation:(NSString*)animationName:(boolean)preAnimate
{
	currentAnimationName=animationName;
	currentAnimation=(CAnimation*)[animations objectForKey:animationName];
	self->frame=0;
	
	lastTime=0;
	//if (preAnimate)
		while (![self animate:(double)SDL_GetTicks()/1000.0:true]);
	//else
	//	[self animate:CFAbsoluteTimeGetCurrent():true];
}

- (void) updateSprite
{
	CAnimationFrame* thisframe=[currentAnimation frameAt:self->frame];
	switch (thisframe->type)
	{
		case 1:		//clip	
			if (thisframe->isOptimized)
				[sprite setRenderAreaWithFrame:thisframe];
			else
				[sprite setRenderArea:thisframe->clipx :thisframe->clipy :thisframe->clipw :thisframe->cliph];
			break;
		case 2:		//alpha
			[sprite setOverlayWithRed:-1 :-1 :-1 :thisframe->alpha];
			break;
		case 3:		//overlay
			[sprite setOverlayWithRed:thisframe->red :thisframe->green :thisframe->blue :-1];
			break;
		case 4:		//rotate
			sprite->angle = thisframe->angle;
			break;
		case 5:		//scale
			[sprite setScale:thisframe->scale_x :thisframe->scale_y];
			break;
		case 6:		//animation
			[self setCurrentAnimation:thisframe->animation :true];
			break;
		case 7:		//collision scale
			[sprite setCollisionScale:thisframe->scale_x :thisframe->scale_y];
			//sprite->collision_scale_x=thisframe->scale_x;
			//sprite->collision_scale_y=thisframe->scale_y;
			break;
	}
}

- (boolean) getIsDead
{
	return self->sprite->isdead;
}

- (void) setIsEnabled:(boolean)isenable
{
	self->sprite->enabled = isenable;
}

- (boolean) nextFrame
{
	self->frame=self->frame+1;	
	if (self->frame>=[currentAnimation->frames count]) 
	{
		self->frame=0;
		return true;
	}
	return false;
}

- (boolean) animate:(double)currentTime:(boolean)forceNext
{
	if (!self->sprite->enabled && !forceNext)
		return false;
	
	boolean retval =false;		
	while (currentTime-lastTime > [currentAnimation frameAt:self->frame]->duration ||
		forceNext || [currentAnimation frameAt:self->frame]->duration <= 0)
	{
		double lastdur = [currentAnimation frameAt:self->frame]->duration;
		if (!retval)
			retval = [self nextFrame];
		else
			[self nextFrame];
				
		if ([currentAnimation frameAt:self->frame]->type==6)
		{
			[self updateSprite];
			break;	
		}
		
		[self updateSprite];
		
		if (forceNext){
			lastTime=currentTime;
			break;
		}
		else
			lastTime+=lastdur;
	}
	
	return retval;
}

- (int) getLayer
{
	return sprite->layer;
}

- (void) render:(boolean)usePerspective
{
	[sprite render:usePerspective];
}

@end

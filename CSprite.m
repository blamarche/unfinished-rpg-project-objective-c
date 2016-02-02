 //
//  CSprite.m
//  GLExample
//
//  Created by  on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "CSprite.h"
#import "RenderUtils.h"
#include "SDL/SDL.h"
#include "SDL/SDL_opengl.h"
#include "SDL/SDL_image.h"
#define true YES
#define false NO
#define bool boolean

@implementation CSprite
/*
@synthesize isdead;
@synthesize enabled;
@synthesize layer;
@synthesize positionMode;
@synthesize showShadow;
@synthesize shadowAlpha;
@synthesize shadowOffsetX;
@synthesize shadowOffsetY;
@synthesize shadow_scale_x;
@synthesize shadow_scale_y;
@synthesize collision_scale_x;
@synthesize collision_scale_y;
@synthesize collision_xoff;
@synthesize collision_yoff;

@synthesize width;
@synthesize height;
@synthesize scaleWidth;
@synthesize scaleHeight;
@synthesize texID;
@synthesize imageFile;
@synthesize x;
@synthesize y;
@synthesize z;
@synthesize vector_x;
@synthesize vector_y;
@synthesize angle;
@synthesize parameters;
*/

- (id) initWithFile:(NSString*) imgfile 
{
	self = [super init];
	
	//SDL_Surface* spriteImage =  SDL_LoadBMP([imgfile cString]);	
	SDL_Surface* spriteImageTmp =  IMG_Load([imgfile cString]);
	SDL_Surface* spriteImage = SDL_DisplayFormatAlpha(spriteImageTmp);
	SDL_FreeSurface(spriteImageTmp);

	self->width = spriteImage->w;
	self->height = spriteImage->h;
	
	self->texID = LoadTexture(spriteImage, imgfile);
	SDL_FreeSurface(spriteImage);

	self->imageFile = imgfile;
	self->z=0;
	self->td_angle_x = 0.0f;
	self->td_angle_y = 0.0f;

	self->positionMode=0; //centered
	self->enabled=true;
	self->isdead=false;
	
	self->showShadow=false;
	self->shadowAlpha=120;
	self->shadowOffsetX=10;
	self->shadowOffsetY=10;
	self->shadow_scale_x=1.0f;
	self->shadow_scale_y=1.0f;
	
	spriteTexcoords[0] = 0.0f; 
	spriteTexcoords[1] = 0.0f;
	spriteTexcoords[2] = 1.0f;
	spriteTexcoords[3] = 0.0f;
	spriteTexcoords[4] = 0.0f;
	spriteTexcoords[5] = 1.0f;
	spriteTexcoords[6] = 1.0f;
	spriteTexcoords[7] = 1.0f;
		
	colorOverlay[0]=255;
	colorOverlay[1]=255;
	colorOverlay[2]=255;
	colorOverlay[3]=255;
	
	self->scaleWidth = width;
	self->scaleHeight = height;
	
	spriteVertices[0] = -1.0f*scaleWidth/2.0f;
	spriteVertices[1] = -1.0f*scaleWidth/2.0f;
	spriteVertices[2] = scaleWidth/2.0f;
	spriteVertices[3] =-1.0f*scaleWidth/2.0f;
	spriteVertices[4] = -1.0f*scaleWidth/2.0f;
	spriteVertices[5] = scaleWidth/2.0f;
	spriteVertices[6] =scaleWidth/2.0f;
	spriteVertices[7] = scaleWidth/2.0f;
	
	[self setScale:1.0f :1.0f];
	[self setCollisionScale:1.0f :1.0f];
	self->parameters = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void) setCollisionScale:(float)sx:(float)sy
{
	self->collision_scale_x=sx;
	self->collision_scale_y=sy;
	
	collision_xoff = (self->scaleWidth*self->collision_scale_x/2);
	collision_yoff = (self->scaleHeight*self->collision_scale_y/2);
}

-(void) setScale:(float)sx:(float)sy
{
	scale_x=sx;
	scale_y=sy;
}

- (void) setRenderArea:(int)xp : (int)yp : (int)w : (int)h
{	
	float scx=(float)xp/(float)self->width;
	float scy=(float)yp/(float)self->height;
	float scw=(float)w/(float)self->width;
	float sch=(float)h/(float)self->height;
	float scx2=scx+scw;
	float scy2=scy+sch;
	spriteTexcoords[0] = scx;
	spriteTexcoords[1] = scy;
	spriteTexcoords[2] = scx2;
	spriteTexcoords[3] = scy;
	spriteTexcoords[4] = scx;
	spriteTexcoords[5] = scy2;
	spriteTexcoords[6] = scx2;
	spriteTexcoords[7] = scy2;

	if (self->scaleWidth!=w || self->scaleHeight!=h)
	{
		self->scaleWidth = w;
		self->scaleHeight = h;
		spriteVertices[0] = -1.0f*scaleWidth/2.0f;
		spriteVertices[1] = -1.0f*scaleHeight/2.0f;
		spriteVertices[2] = scaleWidth/2.0f;
		spriteVertices[3] =-1.0f*scaleHeight/2.0f;
		spriteVertices[4] = -1.0f*scaleWidth/2.0f;
		spriteVertices[5] = scaleHeight/2.0f;
		spriteVertices[6] =scaleWidth/2.0f;
		spriteVertices[7] = scaleHeight/2.0f;
		[self setCollisionScale:self->collision_scale_x :self->collision_scale_y];
	}
}

- (void) setRenderAreaWithFrame:(CAnimationFrame*)cframe
{
	spriteTexcoords[0] = cframe->spriteTexcoords[0];
	spriteTexcoords[1] = cframe->spriteTexcoords[1];
	spriteTexcoords[2] = cframe->spriteTexcoords[2];
	spriteTexcoords[3] = cframe->spriteTexcoords[3];
	spriteTexcoords[4] = cframe->spriteTexcoords[4];
	spriteTexcoords[5] = cframe->spriteTexcoords[5];
	spriteTexcoords[6] = cframe->spriteTexcoords[6];
	spriteTexcoords[7] = cframe->spriteTexcoords[7];

	spriteVertices[0]=cframe->spriteVertices[0];
	spriteVertices[1]=cframe->spriteVertices[1];
	spriteVertices[2]=cframe->spriteVertices[2];
	spriteVertices[3]=cframe->spriteVertices[3];
	spriteVertices[4]=cframe->spriteVertices[4];
	spriteVertices[5]=cframe->spriteVertices[5];
	spriteVertices[6]=cframe->spriteVertices[6];
	spriteVertices[7]=cframe->spriteVertices[7];
	
	if (self->scaleWidth!=cframe->clipw||self->scaleHeight!=cframe->cliph)
	{
		self->scaleWidth=cframe->clipw;
		self->scaleHeight=cframe->cliph;
		[self setCollisionScale:self->collision_scale_x :self->collision_scale_y];
	}
}

- (void) setOverlayWithRed:(int)red: (int) green: (int) blue: (int) alpha
{
	if (red!=-1)
		colorOverlay[0]=red;
	if (green!=-1)
		colorOverlay[1]=green;
	if (blue!=-1)
		colorOverlay[2]=blue;
	if (alpha!=-1)
		colorOverlay[3]=alpha;
}

- (bool) getIsDead
{
	return self->isdead;
}

- (void) setIsEnabled:(bool)isenable
{
	self->enabled = isenable;
}

- (float) getScaleX
{
	return scale_x;
}

- (float) getScaleY
{
	return scale_y;
}

- (void) render:(bool)usePerspective
{	
	if (self->enabled && self->texID!=0)
	{		
		float xpos, ypos,zpos;
		zpos=self->z;
		switch(self->positionMode){
			case 0:
				xpos=self->x;
				ypos=self->y;
				break;			
			case 1:
				xpos=self->x+(self->scaleWidth*scale_x/2.0f);
				ypos=self->y+(self->scaleHeight*scale_y/2.0f);
				break;
			default:
				xpos=self->x;
				ypos=self->y;
				break;
		}
		
		if (glGlobalLastSpriteVertices != &spriteVertices[0])
		{
			glVertexPointer(2, GL_FLOAT, 0, spriteVertices);
			glGlobalLastSpriteVertices = &spriteVertices[0];
		}
		
		//SHADOW
		if (self->showShadow)
		{
			glPushMatrix();
			//glDisable(GL_DEPTH_TEST);
			
			if (glGlobalLastTexID!=self->texID){
				glBindTexture(GL_TEXTURE_2D, self->texID);
				glGlobalLastTexID=self->texID;
			}
			
			glTexCoordPointer(2, GL_FLOAT, 0, spriteTexcoords);
			//glEnableClientState(GL_TEXTURE_COORD_ARRAY);	
		
			glColor4ub(1,1,1,self->shadowAlpha);

			if (usePerspective)
			{
				glTranslatef(xpos+self->shadowOffsetX,zpos,ypos+self->shadowOffsetY);
				glRotatef(90, 1.0f, 0.0f, 0.0f);
				glRotatef(self->td_angle_x, 1.0f, 0.0f, 0.0f);
				glRotatef(self->td_angle_y, 0.0f, 1.0f, 0.0f);
			}else{
				glTranslatef(xpos+self->shadowOffsetX,ypos+self->shadowOffsetY, 0);
			}			
			
			glRotatef(self->angle, 0.0f, 0.0f, 1.0f);
			glScalef(scale_x*shadow_scale_x, scale_y*shadow_scale_y, 1.0f);
		
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			//glEnable(GL_DEPTH_TEST);
			glPopMatrix();
		}
		
		//MAIN SPRITE
		glPushMatrix();
		if (glGlobalLastTexID!=self->texID){
			glBindTexture(GL_TEXTURE_2D, self->texID);
			glGlobalLastTexID=self->texID;
		}
	
		glTexCoordPointer(2, GL_FLOAT, 0, spriteTexcoords);
		//glEnableClientState(GL_TEXTURE_COORD_ARRAY);	
	
		glColor4ub(colorOverlay[0],colorOverlay[1],colorOverlay[2],colorOverlay[3]);	
		if (usePerspective)
		{
			glTranslatef(xpos, zpos, ypos);
			glRotatef(90, 1.0f, 0.0f, 0.0f);
			glRotatef(self->td_angle_x, 1.0f, 0.0f, 0.0f);
			glRotatef(self->td_angle_y, 0.0f, 1.0f, 0.0f);
		}else{
			glTranslatef(xpos,ypos, 0);
		}
		glRotatef(self->angle, 0.0f, 0.0f, 1.0f);
		if (scale_x!=1.0f || scale_y!=1.0f)
			glScalef(scale_x, scale_y, 1.0f);
		
		//glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);						
		glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_BYTE, glGlobalSpriteIndexOrder);
		glPopMatrix();		
	}
}

- (bool) collidesWith:(CSprite*)otherSprite
{	
	int r1left, r1top, r2left, r2top, r1bottom, r1right, r2bottom, r2right;
	r1left = self->x - self->collision_xoff;
	r1right = self->x + self->collision_xoff;
	r1top = self->y - self->collision_yoff;
	r1bottom = self->y + self->collision_yoff;
	r2left = otherSprite->x - otherSprite->collision_xoff;
	r2right = otherSprite->x + otherSprite->collision_xoff;
	r2top = otherSprite->y - otherSprite->collision_yoff;
	r2bottom = otherSprite->y + otherSprite->collision_yoff;
	
	return !(r2left>r1right || r2right < r1left || r2top > r1bottom || r2bottom < r1top);
	 
	/*
	int dx=(self.x-otherSprite.x);
	int dy=(self.y-otherSprite.y);
	int dist_sq = dx*dx + dy*dy;
	int r_sq = self.collision_xoff*self.collision_xoff+otherSprite.collision_xoff*otherSprite.collision_xoff;
	return ( dist_sq <  r_sq );
	 */
}

- (bool) collidesWithPoint:(int)cx:(int)cy
{
	int r1left, r1top, r1bottom, r1right;
	r1left = self->x - self->collision_xoff;
	r1right = self->x + self->collision_xoff;
	r1top = self->y - self->collision_yoff;
	r1bottom = self->y + self->collision_yoff;
	
	return !(cx>r1right || cx < r1left || cy > r1bottom || cy < r1top);
}

- (bool) collidesWithRect:(int)r2left:(int)r2top:(int)r2right:(int)r2bottom
{
	int r1left, r1top, r1bottom, r1right;
	r1left = self->x - self->collision_xoff;
	r1right = self->x + self->collision_xoff;
	r1top = self->y - self->collision_yoff;
	r1bottom = self->y + self->collision_yoff;
	
	return !(r2left>r1right || r2right < r1left || r2top > r1bottom || r2bottom < r1top);
}

- (int) getLayer
{
	return self->layer;
}

- (bool) animate:(double)currentTime:(bool)forceNext
{
	return false;
}

- (int) getParamInt:(NSString*)paramname
{
	NSString* s= [self->parameters objectForKey:paramname];
	if (s!=nil)
		return [s intValue];
	else
		return 0;
}

- (void) setParamInt:(NSString*)paramname:(int)val
{
	[self->parameters setObject:[NSString stringWithFormat:@"%d",val] forKey:paramname];	
}

- (float) getParamFloat:(NSString*)paramname
{
	NSString* s= [self->parameters objectForKey:paramname];
	if (s!=nil)
		return [s floatValue];
	else
		return 0.0f;
}

- (double) getParamDouble:(NSString*)paramname
{
	NSString* s= [self->parameters objectForKey:paramname];
	if (s!=nil)
		return [s doubleValue];
	else
		return 0.0;
}

- (void) setParamFloat:(NSString*)paramname:(float)val
{
	[self->parameters setObject:[NSString stringWithFormat:@"%f",val] forKey:paramname];	
}

- (void) setParamDouble:(NSString*)paramname:(double)val
{
	[self->parameters setObject:[NSString stringWithFormat:@"%f",val] forKey:paramname];	
}

@end

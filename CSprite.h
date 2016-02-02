 //
//  CSprite.h
//  GLExample
//
//  Created by  on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#include <Foundation/Foundation.h>
#include "SDL/SDL_opengl.h"
#import "CAnimationFrame.h"

@interface CSprite : NSObject {
	@public
	int width;
	int height;
	float x;
	float y;
	float z;
	float vector_x;	//pixels per second
	float vector_y;	//pixels per second
	float scale_x;
	float scale_y;
	float collision_scale_x;
	float collision_scale_y;
	float collision_yoff;
	float collision_xoff;
	float scaleWidth;
	float scaleHeight;
	float angle;
	float td_angle_y; //3d
	float td_angle_x; //3d
	GLuint texID;
	NSString* imageFile;

	boolean showShadow;
	int shadowAlpha;
	int shadowOffsetX;
	int shadowOffsetY;
	float shadow_scale_x;
	float shadow_scale_y;

	GLfloat spriteVertices[8];
	GLfloat spriteTexcoords[8];
	GLubyte colorOverlay[4];

	int layer;
	int positionMode;	//0 - centered, 1 - topleft
	boolean enabled;
	boolean isdead;

	NSMutableDictionary* parameters;
}
/*
@property bool isdead;
@property bool enabled;
@property int layer;
@property int positionMode;
@property bool showShadow;
@property int shadowAlpha;
@property int shadowOffsetX;
@property int shadowOffsetY;
@property float shadow_scale_x;
@property float shadow_scale_y;
@property float collision_scale_x;
@property float collision_scale_y;
@property float collision_xoff;
@property float collision_yoff;

@property (retain) NSMutableDictionary* parameters;
@property float scaleWidth;
@property float scaleHeight;
@property float x;
@property float y;
@property float z;
@property float vector_x;
@property float vector_y;
@property float angle;
@property int width;
@property int height;
@property GLuint texID;
@property (retain) NSString* imageFile;
*/
- (id) initWithFile:(NSString*) imgfile;
- (boolean) getIsDead;
- (void) setIsEnabled:(boolean)isenable;
- (void) setOverlayWithRed:(int)red: (int) green: (int) blue: (int) alpha;
- (void) setScale:(float)sx:(float)sy;
- (void) setCollisionScale:(float)sx:(float)sy;
- (void) setRenderArea:(int)xp : (int)yp : (int)w : (int)h;
- (void) render:(boolean)usePerspective;
- (float) getScaleX;
- (float) getScaleY;
- (void) setRenderAreaWithFrame:(CAnimationFrame*)cframe;
- (boolean) animate:(double)currentTime:(boolean)forceNext;
- (boolean) collidesWith:(CSprite*)otherSprite;
- (boolean) collidesWithRect:(int)r2left:(int)r2top:(int)r2right:(int)r2bottom;
- (boolean) collidesWithPoint:(int)cx:(int)cy;
- (int) getParamInt:(NSString*)paramname;
- (void) setParamInt:(NSString*)paramname:(int)val;
- (float) getParamFloat:(NSString*)paramname;
- (double) getParamDouble:(NSString*)paramname;
- (void) setParamDouble:(NSString*)paramname:(double)val;
- (void) setParamFloat:(NSString*)paramname:(float)val;
- (int) getLayer;
@end


 //
//  CFont.h
//  GLExample
//
//  Created by  on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSprite.h"
#define true YES
#define false NO
#define bool boolean

@interface CTileSheet : NSObject {
	@public
	GLfloat spriteVertices[8];
	GLfloat spriteTexcoords[4096][8];
	GLubyte colorOverlay[4];

	CSprite* sprite;
	CAnimationFrame* frame;
	int tileSize;
	int tilew;
	int tileh;
}

- (id) initWithFile:(NSString*) imgfile : (int)tileSize;
//- (void) renderStringAt:(int)x:(int)y:(NSString*) toRender:(int)spacing:(int)charoffset;
- (void) renderTileAtIndex:(int)index:(int)x:(int)y:(int)z:(bool)usePerspective:(float)td_angle_x:(float)td_angle_y:(bool)isCube;
- (void) setColorWithRed:(int)red: (int) green: (int) blue: (int) alpha;

@end

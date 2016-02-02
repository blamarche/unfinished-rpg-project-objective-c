 //
//  CFont.h
//  GLExample
//
//  Created by  on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSprite.h"

@interface CFont : NSObject {
	@public
	GLfloat spriteVertices[8];
	GLfloat spriteTexcoords[256][8];
	GLubyte colorOverlay[4];

	CSprite* sprite;
	CAnimationFrame* frame;
	int startchar;
	int charw;
	int charh;
}
/*
@property(retain) CSprite* sprite;
@property int startchar;
*/
- (id) initWithFile:(NSString*) imgfile : (int)startingChar;
- (void) renderStringAt:(int)x:(int)y:(NSString*) toRender:(int)spacing:(int)charoffset;
- (void) setColorWithRed:(int)red: (int) green: (int) blue: (int) alpha;

@end

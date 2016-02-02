//
//  CAnimatedSprite.h
//  GLExample
//
//  Created by  on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CAnimation.h"
#import "CAnimationFrame.h"
#import "CSprite.h"

@interface CAnimatedSprite : NSObject {
	@public
	CSprite* sprite;
	NSMutableDictionary* animations;
	double lastTime;

	NSString* currentAnimationName;
	CAnimation* currentAnimation;
	int frame;
}
/*
@property int frame;
@property double lastTime;
@property (retain) CSprite* sprite;
@property (retain) NSMutableDictionary* animations;
*/
- (id) initWithSprite:(CSprite*)_sprite;
- (boolean) getIsDead;
- (void) setIsEnabled:(boolean)isenable;
- (NSString*) getCurrentAnimation;
- (void) setCurrentAnimation:(NSString*)animationName:(boolean)preAnimate;
- (void) updateSprite;
- (boolean) animate:(double)currentTime:(boolean)forceNext;
- (void) render:(boolean)usePerspective;
- (boolean) nextFrame; //return true if animation looped
- (void) addAnimationsFromFile:(NSString*)filepath:(boolean)doOptimize;
- (void) shareAnimationsWith:(CAnimatedSprite*)otherSprite;
- (void) optimizeAnimations;
- (int) getLayer;

@end

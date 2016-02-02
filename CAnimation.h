 //
//  CAnimation.h
//  GLExample
//
//  Created by  on 8/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CAnimationFrame.h"

@interface CAnimation : NSObject {
	@public
	NSMutableArray* frames;
}

//@property (retain) NSMutableArray* frames;

- (CAnimationFrame*) frameAt:(int)index;
- (id) init;
- (CAnimationFrame*) addFrame: (NSString*)type:(double)duration;

@end

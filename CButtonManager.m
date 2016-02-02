 //
//  CButtonManager.m
//  GLExample
//
//  Created by  on 8/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CButtonManager.h"
#import "CSprite.h"
#define true YES
#define false NO

@implementation CButtonManager

- (id) init
{
	self = [super init];
	buttonSprites = [[NSMutableDictionary alloc] initWithCapacity:5];
	return self;
}

- (CSprite*) addButton:(CSprite*)buttonsprite:(NSString*)buttonName:(int)x:(int)y:(int)clickableWidth:(int)clickableHeight:(int)buttonGroup
{
	[buttonSprites setObject:buttonsprite forKey:buttonName];
	[buttonsprite->parameters setObject:[NSString stringWithFormat:@"%d",clickableWidth] forKey:@"clickableWidth"];
	[buttonsprite->parameters setObject:[NSString stringWithFormat:@"%d",clickableHeight] forKey:@"clickableHeight"];
	[buttonsprite->parameters setObject:[NSString stringWithFormat:@"%d",buttonGroup] forKey:@"buttonGroup"];
	[buttonsprite->parameters setObject:buttonName forKey:@"buttonName"];
	buttonsprite->x = x;
	buttonsprite->y = y;
	
	return buttonsprite;
}

- (void) renderButtons:(int)buttonGroup
{
	NSEnumerator* enumer = [buttonSprites objectEnumerator];
	CSprite* button;
	while (button = [enumer nextObject])
	{
		int group = [[button->parameters objectForKey:@"buttonGroup"] intValue];
		if (group==buttonGroup)
			[button render:false];
	}
}

- (CSprite*) handleClick:(int)x:(int)y:(int)buttonGroup
{
	NSEnumerator* enumer = [buttonSprites objectEnumerator];
	CSprite* button;
	while (button = [enumer nextObject])
	{
		int group = [[button->parameters objectForKey:@"buttonGroup"] intValue];
		int cwidth = [[button->parameters objectForKey:@"clickableWidth"] intValue];
		int cheight = [[button->parameters objectForKey:@"clickableHeight"] intValue];
		if (group==buttonGroup)
		{
			int x1,x2,y1,y2;					
			int swhalf = cwidth/2.0f;
			int shhalf =cheight/2.0f;
			x1=button->x - swhalf;
			x2=button->x+swhalf;
			y1=button->y-shhalf;
			y2=button->y+shhalf;
			
			if (x>=x1 && x<=x2 && y>=y1 && y<=y2)
				return button;
		}
	}
		
	return nil;
}

@end

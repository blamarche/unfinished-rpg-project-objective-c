 /*
 *  TrigArrays.m
 *  GLExample
 *
 *  Created by  on 8/15/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import "TrigArrays.h"
#import <math.h>

void InitTrigArrays()
{
	int i;
	for ( i=0; i<360; i++)
	{
		float rad = ((float)i) * (3.1415f / 180.0f);
		
		__fcos[i] = cos(rad);
		__fsin[i] = sin(rad);
		__ftan[i] = tan(rad);
	}
}

int WrapDegrees(int deg)
{
	//return ((deg % 360) + 360) % 360;
	if (deg>=0)
		return deg % 360;
	else
		return deg % 360+360;
}

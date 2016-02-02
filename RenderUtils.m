 /*
 *  RenderUtils.m
 *  GLExample
 *
 *  Created by  on 8/15/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <Foundation/Foundation.h>
#include "RenderUtils.h"
#include "SDL/SDL.h"
#include "SDL/SDL_opengl.h"



void ShowAlertBox(NSString *title, NSString *message, id *view){
	/*UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[[title stringByAppendingString:@"\n--------\n"] stringByAppendingString:message] delegate:nil cancelButtonTitle:nil destructiveButtonTitle:@"OK" otherButtonTitles:nil];
	sheet.actionSheetStyle=UIActionSheetStyleDefault;
	[sheet showInView:view];
	[sheet release];*/
}

void FreeTexture(GLuint texid, NSString* key)
{
	if (!textureDictionary){
		textureDictionary=[[NSMutableDictionary alloc] initWithCapacity:10];
	}

	if ([textureDictionary objectForKey:key]!=nil){
		[textureDictionary removeObjectForKey:key];
	}

	GLuint tex[1];
	tex[0]=texid;
	glDeleteTextures(1, &tex); 
}

GLuint LoadTexture(SDL_Surface* spriteImage, NSString *key)
{
	if (!textureDictionary){
		textureDictionary=[[NSMutableDictionary alloc] initWithCapacity:10];
	}

	if ([textureDictionary objectForKey:key]!=nil){
		return [[textureDictionary objectForKey:key] unsignedIntValue];
	}

	if(spriteImage) {
		//CGContextRef spriteContext;
		GLuint spriteTexture;
		int width = spriteImage->w;
		int height = spriteImage->h;

		/*
		// Allocated memory needed for the bitmap context
		spriteData = (GLubyte *) malloc(width * height * 4);
		// Uses the bitmatp creation function provided by the Core Graphics framework.
		spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
		// After you create the context, you can draw the sprite image to the context.
		CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), spriteImage);
		// You don't need the context at this point, so you need to release it to avoid memory leaks.
		CGContextRelease(spriteContext);
		*/

		// Use OpenGL ES to generate a name for the texture.
		glGenTextures(1, &spriteTexture);
		// Bind the texture name.
		glBindTexture(GL_TEXTURE_2D, spriteTexture);
		// Speidfy a 2D texture image, provideing the a pointer to the image data in memory
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S , GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T , GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R , GL_CLAMP_TO_EDGE);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, spriteImage->pixels);

		[textureDictionary setObject:[NSNumber numberWithUnsignedInt:spriteTexture] forKey:key];
		glGlobalLastTexID = spriteTexture;
		glGlobalLastSpriteVertices=NULL;
		return spriteTexture;
	}
	return 0;
}

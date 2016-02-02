 /*
 *  GlobalEnums.h
 *  GLExample
 *
 *  Created by  on 8/14/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#define bool boolean
#define true YES
#define false NO


/* ENUMS */
enum GAME_STATE {
	GS_INGAME,
	GS_GETINPUT,
	GS_PAUSE
};

enum INPUT_STATE {
	IS_NAME,
	IS_SAVELEVEL,
	IS_LOADLEVEL,
	IS_NONE
};

enum EDITOR_STATE {
	ES_HIDDEN,
	ES_EDIT,
	ES_TILES
};

enum EDITOR_TILE_STATE {
	ETS_GROUND,
	ETS_3D1,
	ETS_OVER1,
	ETS_3D2,
	ETS_OVER2,
	ETS_FLATWALL,
	ETS_FLATWALL2,
	ETS_CHEST,
	ETS_EXIT,
	ETS_BLOCKED,
	ETS_GROUNDALT,
	ETS_FLATWALLALT,
	ETS_NPC,
	ETS_MONSTER,
	ETS_LAST
};


#define LEVEL_SIZE 100
#define MAX_ROOM_SIZE 30
#define MAX_ROOMS 20
#define MAX_ROOM_TRIES 100

#define MINIMAP_MODE


/* GLOBALS */
SDL_Surface			*screen;
NSAutoreleasePool	*autoPool;
unsigned long		keys[SDLK_LAST];

int					gEditorTileState = ETS_GROUND;
int					gEditorTileIndex = 0;
int					gEditorTileOffset = 0;
int					gEditorState = ES_HIDDEN;

short				gLevel[ETS_LAST][LEVEL_SIZE][LEVEL_SIZE];
short				gRoom[ETS_LAST][MAX_ROOM_SIZE][MAX_ROOM_SIZE];
int					gDungeon;

int					gGameState;
bool				gQuitGame = false;
int					gScreenWidth = 320;
int					gScreenHeight = 480;
int					gWindowWidth = 480;
int					gWindowHeight = 720;
bool				gPerspectiveOn;
float				gFrustLeft,gFrustRight,gFrustBot,gFrustTop,gFrustNear,gFrustFar;

int					gTileSize = 48;
int					gZoomLevel = -250;

double				gTimeDiff;
double				gLastTick;
bool				gTickIsEven;
double				gEvenTickTimeDiff;
bool				gShowGroundAlt=false;
bool				gShowFlatwallAlt=false;

CTileSheet			*gTiles;
CAnimatedSprite		*background;
CAnimatedSprite		*player;
CAnimatedSprite		*ui;
CFont				*gFont;

NSString			*debugLine;

NSString			*inputPrompt = @"";
NSString			*inputString = @"";
bool				gInputFinished = false;
int					gInputState = IS_NONE;

bool				gMouseDown;
bool				gMouseDownR;
int					gMouseX;
int					gMouseY;

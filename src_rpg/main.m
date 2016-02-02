/*
	RPG
	TODO: Dungeon creation
	-Choose from preset rooms for a given tileset. Randomly place them throughout large map grid (ensure no overlap)
	-Store location of each room, then make each room have two hallways to its nearest rooms on the map, some hallways are locked
	-Rooms store monster types that can spawn there
	-Any key can unlock any hallway that is locked
	-Any monster can drop a key
	-Furthest room from start room should have special treasure + special boss for tileset
	-Random monsters per-room based on room parameters

*/

#import <Foundation/Foundation.h>
#include "SDL/SDL.h"
#include "SDL/SDL_mixer.h"
#include "SDL/SDL_opengl.h"
#import "../RenderUtils.h"
#import "../CSprite.h"
#import "../CAnimatedSprite.h"
#import "../CFont.h"
#import "../CButtonManager.h"
#import "../CTileSheet.h"
#import "../TrigArrays.h"
#import "GlobalEnums.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>


#define RANDOM_SEED() srand(time(NULL))
#define RANDOM_INT(__MIN__,__MAX__) ((__MIN__)+rand() % ((__MAX__+1)-(__MIN__)))

void PollKeys();

//FUNCTIONS
bool DoesBoxCollide(int r1left, int r1top, int r1right, int r1bottom, int r2left, int r2top, int r2right, int r2bottom)
{
	return !(r2left>r1right || r2right < r1left || r2top > r1bottom || r2bottom < r1top);
}

bool IsPointInBox(int x, int y, int r2left, int r2top, int r2right, int r2bottom)
{
	return !(x<r2left || x>r2right || y<r2top || y>r2bottom);
	//return !(r2left>r1right || r2right < r1left || r2top > r1bottom || r2bottom < r1top);
}

void ClearInput()
{
	gInputState = IS_NONE;
	gInputFinished = false;
	inputString = @"";
	inputPrompt = @"";
}

void GetInput(int inputState, NSString* prompt)
{
	gInputState = inputState;
	gInputFinished = false;
	inputString = @"";
	inputPrompt = prompt;
	[ui setCurrentAnimation:@"GetInput" :false];
}

void LoadTiles()
{
	if (gTiles!=nil)
	{
		FreeTexture(gTiles->sprite->texID, gTiles->sprite->imageFile);
		RELEASE(gTiles->sprite);
		RELEASE(gTiles);
	}

	gTiles = [[CTileSheet alloc] initWithFile:[NSString stringWithFormat:@"./%d/tiles.png", gDungeon] : gTileSize];
	gTiles->sprite->showShadow=false;
	gTiles->sprite->shadowOffsetX = 0;
	gTiles->sprite->shadowOffsetY = 16;
	gTiles->sprite->shadowAlpha = 255;
	gTiles->sprite->shadow_scale_x = 1.0;
	gTiles->sprite->shadow_scale_y = 1.0;
}

void LoadBackground()
{

	if (background!=nil)
	{
		FreeTexture(background->sprite->texID, background->sprite->imageFile);
		RELEASE(background->sprite);

		background->sprite = [[CSprite alloc] initWithFile:[NSString stringWithFormat:@"./%d/background.png",gDungeon]];
		[background setCurrentAnimation:[NSString stringWithFormat:@"%d",gDungeon] :true];
	}
	else{
		background = [[CAnimatedSprite alloc] initWithSprite:[[CSprite alloc] initWithFile:[NSString stringWithFormat:@"./%d/background.png",gDungeon]]];
		[background addAnimationsFromFile:@"background.ani":true];
		[background setCurrentAnimation:[NSString stringWithFormat:@"%d",gDungeon] :true];
	}

	background->sprite->z = -10;
	background->sprite->positionMode =0;
	background->sprite->x = 0;
	background->sprite->y = 0;
}

void LoadGraphics()
{
	LoadTiles();
	LoadBackground();

	player = [[CAnimatedSprite alloc] initWithSprite:[[CSprite alloc] initWithFile:@"player.png"]];
	[player addAnimationsFromFile:@"player.ani":true];
	[player setCurrentAnimation:@"Up" :false ];
	player->sprite->x = 0;//gScreenWidth/2;
	player->sprite->y = 0;//gScreenHeight/2;
	player->sprite->showShadow=true;
	player->sprite->shadowOffsetX = 7;
	player->sprite->shadowOffsetY = -1;
	player->sprite->shadowAlpha = 180;
	player->sprite->shadow_scale_x = 0.9;
	player->sprite->shadow_scale_y = 0.5;
	player->sprite->td_angle_x = 85;
	player->sprite->td_angle_y = 0;
	player->sprite->z = 24;
	player->sprite->positionMode = 1;

	ui = [[CAnimatedSprite alloc] initWithSprite:[[CSprite alloc] initWithFile:@"interface.png"]];
	[ui addAnimationsFromFile:@"interface.ani":true];
	[ui setCurrentAnimation:@"InGame" :false ];
	ui->sprite->x = 0;//gScreenWidth/2;
	ui->sprite->y = gScreenHeight-183;
	ui->sprite->showShadow=false;
	ui->sprite->positionMode = 1;

	gFont = [[CFont alloc] initWithFile:@"font-bold.png" : 32];
	[gFont setColorWithRed:200 :200 :200 :255];
	gFont->sprite->showShadow=true;
	gFont->sprite->shadowOffsetX=2;
	gFont->sprite->shadowOffsetY=2;
	gFont->sprite->shadowAlpha=120;
}

void RoomToLevel(int xoff, int yoff, int width, int height)
{
	if (width<=0 || height<=0)
		return;

	if (width>MAX_ROOM_SIZE)
		width=MAX_ROOM_SIZE;
	if (height>MAX_ROOM_SIZE)
		height=MAX_ROOM_SIZE;

	for (int i = 0; i<ETS_LAST; i++)
		for (int x=0; x<width; x++)
			for (int y=0; y<height; y++)
				if (x+xoff < LEVEL_SIZE && y+yoff < LEVEL_SIZE)
					gLevel[i][x+xoff][y+yoff]=gRoom[i][x][y];
}

void LevelToRoom()
{
	for (int i = 0; i<ETS_LAST; i++)
		for (int x=0; x<MAX_ROOM_SIZE; x++)
			for (int y=0; y<MAX_ROOM_SIZE; y++)
				gRoom[i][x][y]=gLevel[i][x][y];
}

void ClearRoom()
{
	for (int i = 0; i<ETS_LAST; i++)
		for (int x = 0; x<MAX_ROOM_SIZE; x++)
			for (int y = 0; y<MAX_ROOM_SIZE; y++)
				gRoom[i][x][y] = -1;
}

void SaveRoom(NSString* dest)
{
	NSData* room = [NSData dataWithBytes:&gRoom length:sizeof(gRoom) ];
	[room writeToFile:dest atomically:NO];
}

void LoadRoom(NSString* source)
{
	ClearRoom();
	NSData* room = [NSData dataWithContentsOfFile:source];
	[room getBytes:&gRoom];
}

int GetRoomWidth()
{
	for (int x = MAX_ROOM_SIZE-1; x>=0; x--)
		for (int y = MAX_ROOM_SIZE-1; y>=0; y--)
			for (int i = 0; i<ETS_LAST; i++)
				if (gRoom[i][x][y] >= 0)
					return x+1;
}

int GetRoomHeight()
{
	for (int y = MAX_ROOM_SIZE-1; y>=0; y--)
		for (int x = MAX_ROOM_SIZE-1; x>=0; x--)
			for (int i = 0; i<ETS_LAST; i++)
				if (gRoom[i][x][y] >= 0)
					return y+1;
}

void ClearLevel()
{
	for (int i = 0; i<ETS_LAST; i++)
		for (int x = 0; x<LEVEL_SIZE; x++)
			for (int y = 0; y<LEVEL_SIZE; y++)
				gLevel[i][x][y] = -1;
}

void GenerateLevel()
{
	ClearLevel();
	for (int x = 0; x<LEVEL_SIZE; x++)
		for (int y = 0; y<LEVEL_SIZE; y++)
			gLevel[ETS_BLOCKED][x][y] = 0;

	int rooms[MAX_ROOMS][6]; //0-x, 1-y, 2-w, 3-h,
	for (int i=0; i<MAX_ROOMS; i++)
	{
		rooms[i][0]=-1;
		rooms[i][1]=-1;
		rooms[i][2]=0;
		rooms[i][3]=0;
	}

	bool done=false;
	int room=0;

	while (!done)
	{
		room++;
		if (room >= MAX_ROOMS)
			break;
		if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"./%d/%d.dat",gDungeon,room]])
			break;

		LoadRoom([NSString stringWithFormat:@"./%d/%d.dat",gDungeon,room]);

		bool overlap = true;
		int roomwidth=GetRoomWidth();
		int roomheight=GetRoomHeight();
		int x,y,try=0;
		while (overlap) //check for overlap with other rooms
		{
			if (try > MAX_ROOM_TRIES)
				break;

			x=RANDOM_INT(0,LEVEL_SIZE-roomwidth-1);
			y=RANDOM_INT(0,LEVEL_SIZE-roomheight-1);
			if (room==1)	//first room
				break;

			overlap = false;
			for (int r = 0; r < room-1; r++)
			{
				if (DoesBoxCollide(x,y,roomwidth+x,roomheight+y,rooms[r][0]-2,rooms[r][1]-2,rooms[r][0]+rooms[r][2]+4,rooms[r][1]+rooms[r][3]+4))
				{
					try++;
					overlap=true;
					break;
				}
			}
		}

		if (try<20)
		{
			int i;
			for (i=0; i<MAX_ROOMS; i++)
				if (rooms[i][0]==-1)
					break;

			rooms[i][0]=x;
			rooms[i][1]=y;
			rooms[i][2]=roomwidth;
			rooms[i][3]=roomheight;

			printf("%d: %d, %d  w: %d h: %d\n",room,x,y,roomwidth,roomheight);

			RoomToLevel(x, y, roomwidth, roomheight);
			ClearRoom();
		}
		else
		{
			printf("%d: out of tries\n",room);
			ClearRoom();
		}
	}

	int totalrooms;
	for (totalrooms=0; totalrooms<MAX_ROOMS; totalrooms++)
		if (rooms[totalrooms][0]==-1)
			break;

	if (totalrooms > 0)
	{
		int px, py;
		px = (rooms[0][0]*gTileSize) + ((rooms[0][2]/2.0f)*gTileSize);
		py = (rooms[0][1]*gTileSize) + ((rooms[0][3]/2.0f)*gTileSize);
		player->sprite->x=px;
		player->sprite->y=py;
		debugLine = [NSString stringWithFormat:@"player: %d, %d \n",px,py];

		//scramble room order
		for (int i=0; i<MAX_ROOMS*2; i++)
		{
			int r = RANDOM_INT(0,totalrooms);
			int r2 = RANDOM_INT(0,totalrooms);

			if (r>=totalrooms)
				r=totalrooms-1;
			if (r2>=totalrooms)
				r2=totalrooms-1;

			int x,y,w,h;
			x=rooms[r][0];
			y=rooms[r][1];
			w=rooms[r][2];
			h=rooms[r][3];

			rooms[r][0] = rooms[r2][0];
			rooms[r][1] = rooms[r2][1];
			rooms[r][2] = rooms[r2][2];
			rooms[r][3] = rooms[r2][3];

			rooms[r2][0]=x;
			rooms[r2][1]=y;
			rooms[r2][2]=w;
			rooms[r2][3]=h;

			//printf("%d swap with %d\n", r,r2);
		}

		//connect rooms to the next room in the list (path generation)
		bool islast=false;
		for (int r=0; r<totalrooms; r++)
		{
			if (rooms[r][0]>=0)
			{
				int r2=r+1;
				if (r==totalrooms-1 || rooms[r+1][0]==-1){
					islast=true;
					r2=0;
				}

				//create path
				printf("%d path to %d\n", r,r2);
				int cx = -1;//rooms[r][0];
				int cy = -1;//rooms[r][1];
				int dx = -1;//rooms[r2][0];
				int dy = -1;//rooms[r2][1];

				//scan for entrance coords
				while (cx<0 && cy<0)
				{
					for (int x = 0; x<rooms[r][2]; x++)
						if (gLevel[ETS_BLOCKED][x+rooms[r][0]][rooms[r][1]]==-1 && RANDOM_INT(0,1)==0)
						{
							cx=x+rooms[r][0];
							cy=rooms[r][1];
						}

					for (int x = 0; x<rooms[r][2]; x++)
						if (gLevel[ETS_BLOCKED][x+rooms[r][0]][rooms[r][1]+rooms[r][3]-1]==-1 && RANDOM_INT(0,1)==0)
						{
							cx=x+rooms[r][0];
							cy=rooms[r][1]+rooms[r][3]-1;
						}

					for (int y = 0; y<rooms[r][3]; y++)
						if (gLevel[ETS_BLOCKED][rooms[r2][0]][y+rooms[r][1]]==-1 && RANDOM_INT(0,1)==0)
						{
							cy=y+rooms[r][1];
							cx=rooms[r][0];
						}

					for (int y = 0; y<rooms[r][3]; y++)
						if (gLevel[ETS_BLOCKED][rooms[r][0]+rooms[r][2]-1][y+rooms[r][1]]==-1 && RANDOM_INT(0,1)==0)
						{
							cy=y+rooms[r][1];
							cx=rooms[r][0]+rooms[r][2]-1;
						}
				}

				//scan for dest coords
				while (dx<0 && dy<0)
				{
					for (int x = 0; x<rooms[r2][2]; x++)
						if (gLevel[ETS_BLOCKED][x+rooms[r2][0]][rooms[r2][1]]==-1 && RANDOM_INT(0,1)==0)
						{
							dx=x+rooms[r2][0];
							dy=rooms[r2][1];
						}

					for (int x = 0; x<rooms[r2][2]; x++)
						if (gLevel[ETS_BLOCKED][x+rooms[r2][0]][rooms[r2][1]+rooms[r2][3]-1]==-1 && RANDOM_INT(0,1)==0)
						{
							dx=x+rooms[r2][0];
							dy=rooms[r2][1]+rooms[r2][3]-1;
						}

					for (int y = 0; y<rooms[r2][3]; y++)
						if (gLevel[ETS_BLOCKED][rooms[r2][0]][y+rooms[r2][1]]==-1 && RANDOM_INT(0,1)==0)
						{
							dy=y+rooms[r2][1];
							dx=rooms[r2][0];
						}

					for (int y = 0; y<rooms[r2][3]; y++)
						if (gLevel[ETS_BLOCKED][rooms[r2][0]+rooms[r2][2]-1][y+rooms[r2][1]]==-1 && RANDOM_INT(0,1)==0)
						{
							dy=y+rooms[r2][1];
							dx=rooms[r2][0]+rooms[r2][2]-1;
						}
				}
				printf("s: %d, %d - e: %d, %d\n\n",cx-rooms[r][0],cy-rooms[r][1],dx-rooms[r2][0],dy-rooms[r2][1]);

				//create path map
				short path[LEVEL_SIZE][LEVEL_SIZE];
				for (int i=0; i<LEVEL_SIZE; i++)
					for (int j=0; j<LEVEL_SIZE; j++)
						path[i][j] = -2; //"unassigned"

				for (int i=0; i<totalrooms; i++)
				{
					for (int x=rooms[i][0]; x<rooms[i][0]+rooms[i][2]; x++)
						for (int y=rooms[i][1]; y<rooms[i][1]+rooms[i][3]; y++)
							path[x][y]=-1; //"wall"
				}
				path[dx][dy]=-2; //so it doesnt think it is a wall
				path[cx][cy]=0; //so it doesnt think it is unassigned

				//weight the map
				int curstep = 0;
				bool found = true;
				while (found)
				{
					found = false;
					for (int x=0; x<LEVEL_SIZE; x++)
						for (int y=0; y<LEVEL_SIZE; y++)
						{
							if (path[x][y]==curstep)
							{
								found=true;

								int yabove = y-1;
								int xleft = x-1;
								int xright = x+1;
								int ybelow = y+1;

								if (yabove>=0 && path[x][yabove]==-2)
									path[x][yabove]=curstep+1;
								if (ybelow<LEVEL_SIZE && path[x][ybelow]==-2)
									path[x][ybelow]=curstep+1;
								if (xleft>=0 && path[xleft][y]==-2)
									path[xleft][y]=curstep+1;
								if (xright<LEVEL_SIZE && path[xright][y]==-2)
									path[xright][y]=curstep+1;
							}
						}

					curstep++;
				}

				/*
				for (int x=0;x<LEVEL_SIZE;x++){
					printf("\n");
					for (int y=0;y<LEVEL_SIZE;y++)
						printf("%4d ", path[x][y]);
				}
				*/

				//now start counting backwards from endpoint and removing walls
				curstep = path[dx][dy];
				int thisx=dx, thisy=dy;
				while (curstep>1)
				{
					int choosex, choosey;

					int yabove = thisy-1;
					int xleft = thisx-1;
					int xright = thisx+1;
					int ybelow = thisy+1;

					if (path[thisx][yabove]==curstep-1){
						choosex = thisx;
						choosey = yabove;
					}else if (path[thisx][ybelow]==curstep-1){
						choosex = thisx;
						choosey = ybelow;
					}else if (path[xleft][thisy]==curstep-1){
						choosex = xleft;
						choosey = thisy;
					}else if (path[xright][thisy]==curstep-1){
						choosex = xright;
						choosey = thisy;
					}

					gLevel[ETS_BLOCKED][choosex][choosey]=-1;
					gLevel[ETS_GROUND][choosex][choosey]=0;
					gLevel[ETS_3D1][choosex][choosey]=-1;
					gLevel[ETS_OVER1][choosex][choosey]=-1;

					if (choosey-1 >=0 && gLevel[ETS_3D1][choosex][choosey-1]==-1 && gLevel[ETS_GROUND][choosex][choosey-1]==-1){
						gLevel[ETS_3D1][choosex][choosey-1]=1;
						gLevel[ETS_OVER1][choosex][choosey-1]=2;
					}

					if (choosey+1 <LEVEL_SIZE && gLevel[ETS_3D1][choosex][choosey+1]==-1 && gLevel[ETS_GROUND][choosex][choosey+1]==-1){
						gLevel[ETS_3D1][choosex][choosey+1]=1;
						gLevel[ETS_OVER1][choosex][choosey+1]=2;
					}

					if (choosey-1 >=0 && choosex-1 >=0 && gLevel[ETS_3D1][choosex-1][choosey-1]==-1 && gLevel[ETS_GROUND][choosex-1][choosey-1]==-1){
						gLevel[ETS_3D1][choosex-1][choosey-1]=1;
						gLevel[ETS_OVER1][choosex-1][choosey-1]=2;
					}

					if (choosey-1 >=0 && choosex+1 < LEVEL_SIZE && gLevel[ETS_3D1][choosex+1][choosey-1]==-1 && gLevel[ETS_GROUND][choosex+1][choosey-1]==-1){
						gLevel[ETS_3D1][choosex+1][choosey-1]=1;
						gLevel[ETS_OVER1][choosex+1][choosey-1]=2;
					}

					if (choosex-1 >=0 && choosey+1 < LEVEL_SIZE && gLevel[ETS_3D1][choosex-1][choosey+1]==-1 && gLevel[ETS_GROUND][choosex-1][choosey+1]==-1){
						gLevel[ETS_3D1][choosex-1][choosey+1]=1;
						gLevel[ETS_OVER1][choosex-1][choosey+1]=2;
					}

					if (choosey+1 < LEVEL_SIZE && choosex+1 < LEVEL_SIZE && gLevel[ETS_3D1][choosex+1][choosey+1]==-1 && gLevel[ETS_GROUND][choosex+1][choosey+1]==-1){
						gLevel[ETS_3D1][choosex+1][choosey+1]=1;
						gLevel[ETS_OVER1][choosex+1][choosey+1]=2;
					}

					if (choosex-1 >=0 && gLevel[ETS_3D1][choosex-1][choosey]==-1 && gLevel[ETS_GROUND][choosex-1][choosey]==-1){
						gLevel[ETS_3D1][choosex-1][choosey]=1;
						gLevel[ETS_OVER1][choosex-1][choosey]=2;
					}

					if (choosex+1 < LEVEL_SIZE && gLevel[ETS_3D1][choosex+1][choosey]==-1 && gLevel[ETS_GROUND][choosex+1][choosey]==-1){
						gLevel[ETS_3D1][choosex+1][choosey]=1;
						gLevel[ETS_OVER1][choosex+1][choosey]=2;
					}

					thisx = choosex;
					thisy = choosey;

					curstep--;
				}
			}
			if (islast)
				break;
		}
	}
}

void InitEnvironment()
{
	// Slightly different SDL initialization
	if ( SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0 ) {
		printf("Unable to initialize SDL: %s\n", SDL_GetError());
		return;
	}

	if(Mix_OpenAudio(22050, AUDIO_S16SYS, 1, 1024) != 0) {
		printf("Unable to initialize audio: %s\n", Mix_GetError());
		exit(1);
	}
	Mix_AllocateChannels(16);

	SDL_Init(SDL_INIT_TIMER);
	SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 ); // *new*

	screen = SDL_SetVideoMode( gWindowWidth, gWindowHeight, 32, SDL_OPENGL ); // *changed*
	if ( !screen ) {
		printf("Unable to set video mode: %s\n", SDL_GetError());
		return;
	}

	SDL_WM_SetCaption("Loading... please wait.",0);

	//init gl params
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glViewport( 0, 0, gWindowWidth, gWindowHeight );

	InitTrigArrays();
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glEnable(GL_TEXTURE_2D);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);	// Set a blending function to use
	glEnable(GL_BLEND);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);

	glEnable(GL_LIGHTING);
	glEnable(GL_COLOR_MATERIAL);
	glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);

	float global_ambient[] = { 0.01f, 0.01f, 0.01f, 1.0f };
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, global_ambient);

	int two = 2;
	glLightModelfv(GL_LIGHT_MODEL_TWO_SIDE, &two);
	glShadeModel(GL_SMOOTH);

	float ambientLight[] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float diffuseLight[] = { 1.0f, 1.0f, 1.0f, 1.0f };

	glLightfv(GL_LIGHT0, GL_AMBIENT, ambientLight);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuseLight);

	float att = 0.00f;
	glLightf(GL_LIGHT0, GL_CONSTANT_ATTENUATION, att);
	att = 0.0f;//0.015f;
	glLightf(GL_LIGHT0, GL_LINEAR_ATTENUATION, att);
	att = 0.00005f;
	glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, att);

	glEnable(GL_LIGHT0);
	//glEnable(GL_NORMALIZE);
}

void InitGame(bool firstTime)
{
	if (firstTime)
	{
		RANDOM_SEED();

		debugLine = @"";
		gMouseDown = false;
		gPerspectiveOn = true;

		autoPool = [NSAutoreleasePool new];

		//init keys
		int x=0;
		for (int i=0; i<SDLK_LAST; i++)
    		keys[i]=0;

		//printf("pre-clear room/level\n");
		ClearRoom();
		ClearLevel();
		//printf("cleared room/level\n");

		InitEnvironment();
		//printf("done init env\n");
	}

	gGameState = GS_INGAME;
	gLastTick = (double)SDL_GetTicks()/1000.0;
	gDungeon=1;

	if (firstTime)
	{
		LoadGraphics();

		//gl frustrum values
		float tleft, tright, tbot, ttop, tnear, tfar;
		tnear=0.01f;
		tfar=1000.0f;
		ttop = tan(3.1415f/2.0f * 0.5f)*tnear;
		tbot = -ttop;
		tleft = 0.666667 * tbot; //0.666666 == aspect ratio of iphone screen
		tright = 0.666667 * ttop;
		gFrustLeft=tleft; gFrustRight=tright;gFrustBot=tbot;gFrustTop=ttop;gFrustNear=tnear;gFrustFar=tfar;
	}

	//printf("pre-generate level\n");
	GenerateLevel();

	//printf("done init\n");
}

void DrawEditor()
{
	int playertx = player->sprite->x / gTileSize;
	int playerty = player->sprite->y / gTileSize;

	//RENDER NOW
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_LIGHTING);
	if (gEditorState == ES_EDIT)
	{
		glPushMatrix();

#ifdef MINIMAP_MODE
		glScalef(0.2f,0.2f,1.0f);
		int xrange=35, yrange=55;
		//glScalef(0.05f,0.05f,1.0f);
		//int xrange=150, yrange=150;
#else
		int xrange=8, yrange=16;
#endif

		glTranslatef(-player->sprite->x, -player->sprite->y, 0);


		gTiles->sprite->showShadow=false;

		//ground
		[gTiles->sprite setScale:1.0 :1.0];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
			{
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_GROUND][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_GROUND][tx][ty] :tx*gTileSize :ty*gTileSize :0 :gPerspectiveOn :0 :0 :false];
				if (gShowGroundAlt && tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_GROUNDALT][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_GROUNDALT][tx][ty] :tx*gTileSize :ty*gTileSize :0 :gPerspectiveOn :0 :0 :false];
			}


		gTiles->sprite->showShadow=true;
		gTiles->sprite->shadowOffsetX = 2;
		gTiles->sprite->shadowOffsetY = 2;
		gTiles->sprite->shadowAlpha = 100;
		gTiles->sprite->shadow_scale_x = 1.0;
		gTiles->sprite->shadow_scale_y = 1.0;

		//flat wall
		[gTiles->sprite setScale:0.8 :0.8];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (gShowFlatwallAlt && tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALLALT][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_FLATWALLALT][tx][ty] :tx*gTileSize+5 :ty*gTileSize+5 :0 :gPerspectiveOn :0 :0 :false];
				else if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALL][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_FLATWALL][tx][ty] :tx*gTileSize+5 :ty*gTileSize+5 :0 :gPerspectiveOn :0 :0 :false];

		//3d1
		[gTiles->sprite setScale:0.8 :0.8];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_3D1][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_3D1][tx][ty] :tx*gTileSize+5 :ty*gTileSize+5 :0 :gPerspectiveOn :0 :0 :false];

		//overlay1
		[gTiles->sprite setOverlayWithRed:255 :255 :255 :120];
		[gTiles->sprite setScale:0.8 :0.8];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_OVER1][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx][ty] :tx*gTileSize+5 :ty*gTileSize+5 :0 :gPerspectiveOn :0 :0 :false];

		//flatwall2
		[gTiles->sprite setOverlayWithRed:255 :255 :255 :255];
		[gTiles->sprite setScale:0.6 :0.6];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALL2][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_FLATWALL2][tx][ty] :tx*gTileSize+10 :ty*gTileSize+10 :0 :gPerspectiveOn :0 :0 :false];

		//3d2
		[gTiles->sprite setOverlayWithRed:255 :255 :255 :255];
		[gTiles->sprite setScale:0.6 :0.6];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_3D2][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_3D2][tx][ty] :tx*gTileSize+10 :ty*gTileSize+10 :0 :gPerspectiveOn :0 :0 :false];

		//overlay2
		[gTiles->sprite setOverlayWithRed:255 :255 :255 :120];
		[gTiles->sprite setScale:0.6 :0.6];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_OVER2][tx][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER2][tx][ty] :tx*gTileSize+10 :ty*gTileSize+10 :0 :gPerspectiveOn :0 :0 :false];

		//blocked
		[gFont->sprite setOverlayWithRed:255 :0 :0 :180];
		[gFont->sprite setScale:2.0 :1.5];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_BLOCKED][tx][ty] > -1)
					[gFont renderStringAt:tx*gTileSize+8 :ty*gTileSize+13 :@"X" :9 :0];
		[gFont->sprite setOverlayWithRed:255 :255 :255 :255];
		[gFont->sprite setScale:1.0 :1.0];

		//chest
		[gFont->sprite setOverlayWithRed:0 :255 :0 :180];
		[gFont->sprite setScale:2.0 :1.5];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_CHEST][tx][ty] > -1)
					[gFont renderStringAt:tx*gTileSize+8 :ty*gTileSize+13 :@"C" :9 :0];
		[gFont->sprite setOverlayWithRed:255 :255 :255 :255];
		[gFont->sprite setScale:1.0 :1.0];

		//exit
		[gFont->sprite setOverlayWithRed:0 :0 :255 :180];
		[gFont->sprite setScale:2.0 :1.5];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_EXIT][tx][ty] > -1)
					[gFont renderStringAt:tx*gTileSize+8 :ty*gTileSize+13 :@"E" :9 :0];
		[gFont->sprite setOverlayWithRed:255 :255 :255 :255];
		[gFont->sprite setScale:1.0 :1.0];

		//npc
		[gFont->sprite setOverlayWithRed:255 :0 :255 :180];
		[gFont->sprite setScale:2.0 :1.5];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_NPC][tx][ty] > -1)
					[gFont renderStringAt:tx*gTileSize+8 :ty*gTileSize+13 :@"N" :9 :0];
		[gFont->sprite setOverlayWithRed:255 :255 :255 :255];
		[gFont->sprite setScale:1.0 :1.0];

		//monster
		[gFont->sprite setOverlayWithRed:0 :255 :255 :180];
		[gFont->sprite setScale:2.0 :1.5];
		for (int tx=playertx-xrange; tx<playertx+xrange; tx++)
			for (int ty=playerty-yrange; ty<playerty+yrange; ty++)
				if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_MONSTER][tx][ty] > -1)
					[gFont renderStringAt:tx*gTileSize+8 :ty*gTileSize+13 :@"M" :9 :0];
		[gFont->sprite setOverlayWithRed:255 :255 :255 :255];
		[gFont->sprite setScale:1.0 :1.0];

		//reset tiles sprite
		[gTiles->sprite setScale:1.0 :1.0];
		gTiles->sprite->showShadow=false;
		[gTiles->sprite setOverlayWithRed:255 :255 :255 :255];


		//[player->sprite render:false];
		glPopMatrix();
	}
	else if (gEditorState == ES_TILES)
	{
		glPushMatrix();
		glTranslatef(0, -gTileSize * gEditorTileOffset, 0);

		for (int y=0; y<442; y++)
		{
			if (gEditorTileIndex == y)
			{
				glTranslatef(0, gTileSize * gEditorTileOffset, 0);
				[gTiles renderTileAtIndex:y :96 :0 :0 :gPerspectiveOn :0 :0 :false];
				glTranslatef(0, -gTileSize * gEditorTileOffset, 0);

				[gTiles renderTileAtIndex:y :15 :y*gTileSize :0 :gPerspectiveOn :0 :0 :false];
			}
			else
				[gTiles renderTileAtIndex:y :0 :y*gTileSize :0 :gPerspectiveOn :0 :0 :false];
		}
		glPopMatrix();
		[gFont renderStringAt:96 :60 :[NSString stringWithFormat:@"Index: %d", gEditorTileIndex] :9 :0];
	}

	if (gInputState!=IS_NONE)
		[ui->sprite render:false];

	[gFont renderStringAt:5 :5 :debugLine :9 :0];

	glEnable(GL_LIGHTING);
	glEnable(GL_DEPTH_TEST);
}

void DrawGame()
{
	glClear(GL_DEPTH_BUFFER_BIT);

	glTranslatef(-(player->sprite->x)+gScreenWidth/2-24, 0, -(player->sprite->y)+gScreenHeight/2-24);

	glDisable(GL_LIGHTING);
	[background->sprite render:gPerspectiveOn];
	glEnable(GL_LIGHTING);

	int playertx = player->sprite->x / gTileSize;
	int playerty = player->sprite->y / gTileSize;

	gTiles->sprite->showShadow=false;
	for (int tx=playertx-7; tx<playertx+7; tx++)
		for (int ty=playerty-7; ty<playerty+7; ty++)
		{
			//ground layer
			if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_GROUND][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_GROUND][tx][ty] :tx*gTileSize :ty*gTileSize :0 :gPerspectiveOn :0 :0 :false];
			if (gShowGroundAlt && tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_GROUNDALT][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_GROUNDALT][tx][ty] :tx*gTileSize :ty*gTileSize :0.001f :gPerspectiveOn :0 :0 :false];

			//3d walls
			if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_3D1][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_3D1][tx][ty] :tx*gTileSize :ty*gTileSize :0 :gPerspectiveOn :0 :0 :true];

			if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_3D2][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_3D2][tx][ty] :tx*gTileSize :ty*gTileSize :gTileSize :gPerspectiveOn :0 :0 :true];
		}

	//draw monsters, chests, etc

	//above player
	for (int tx=playertx-7; tx<playertx+7; tx++)
		for (int ty=playerty-7; ty<=playerty; ty++)
		{
			//flat wall
			if (gShowFlatwallAlt && tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALLALT][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_FLATWALLALT][tx][ty] :tx*gTileSize :ty*gTileSize+gTileSize/2 :gTileSize :gPerspectiveOn :90 :0 :false];
			else if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALL][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_FLATWALL][tx][ty] :tx*gTileSize :ty*gTileSize+gTileSize/2 :gTileSize :gPerspectiveOn :90 :0 :false];

			//flat wall2
			if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALL2][tx][ty] > -1){
				if ( ty-1 >= 0 && gLevel[ETS_OVER1][tx][ty-1] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx][ty-1] :tx*gTileSize :(ty-1)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
				if (ty-1 >= 0 && tx-1 >= 0 && gLevel[ETS_OVER1][tx-1][ty-1] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx-1][ty-1] :(tx-1)*gTileSize :(ty-1)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
				if (ty-1 >= 0 && tx+1 < LEVEL_SIZE && gLevel[ETS_OVER1][tx+1][ty-1] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx+1][ty-1] :(tx+1)*gTileSize :(ty-1)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
				if (tx-1 >= 0 && gLevel[ETS_OVER1][tx-1][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx-1][ty] :(tx-1)*gTileSize :(ty)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
				if (tx+1 < LEVEL_SIZE && gLevel[ETS_OVER1][tx+1][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx+1][ty] :(tx+1)*gTileSize :(ty)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];

				[gTiles renderTileAtIndex:gLevel[ETS_FLATWALL2][tx][ty] :tx*gTileSize :ty*gTileSize+gTileSize/2 :gTileSize*2 :gPerspectiveOn :90 :0 :false];
			}
		}

	//draw player
	float position[] = { player->sprite->x+24, gTileSize, player->sprite->y+26, 1.0f };
	glLightfv(GL_LIGHT0, GL_POSITION, position);
	[player->sprite render:gPerspectiveOn];

	//below player
	for (int tx=playertx-7; tx<playertx+7; tx++)
		for (int ty=playerty+1; ty<=playerty+7; ty++)
		{
			//flat wall
			if (gShowFlatwallAlt && tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALLALT][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_FLATWALLALT][tx][ty] :tx*gTileSize :ty*gTileSize+gTileSize/2 :gTileSize :gPerspectiveOn :90 :0 :false];
			else if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALL][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_FLATWALL][tx][ty] :tx*gTileSize :ty*gTileSize+gTileSize/2 :gTileSize :gPerspectiveOn :90 :0 :false];

			//flat wall 2
			if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_FLATWALL2][tx][ty] > -1){
				if ( ty-1 >= 0 && gLevel[ETS_OVER1][tx][ty-1] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx][ty-1] :tx*gTileSize :(ty-1)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
				if (ty-1 >= 0 && tx-1 >= 0 && gLevel[ETS_OVER1][tx-1][ty-1] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx-1][ty-1] :(tx-1)*gTileSize :(ty-1)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
				if (ty-1 >= 0 && tx+1 < LEVEL_SIZE && gLevel[ETS_OVER1][tx+1][ty-1] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx+1][ty-1] :(tx+1)*gTileSize :(ty-1)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
				if (tx-1 >= 0 && gLevel[ETS_OVER1][tx-1][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx-1][ty] :(tx-1)*gTileSize :(ty)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
				if (tx+1 < LEVEL_SIZE && gLevel[ETS_OVER1][tx+1][ty] > -1)
					[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx+1][ty] :(tx+1)*gTileSize :(ty)*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];

				[gTiles renderTileAtIndex:gLevel[ETS_FLATWALL2][tx][ty] :tx*gTileSize :ty*gTileSize+gTileSize/2 :gTileSize*2 :gPerspectiveOn :90 :0 :false];
			}
		}

	for (int tx=playertx-7; tx<playertx+7; tx++)
		for (int ty=playerty-7; ty<playerty+7; ty++)
		{
			//overlay 1
			if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_OVER1][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_OVER1][tx][ty] :tx*gTileSize :ty*gTileSize :gTileSize :gPerspectiveOn :0 :0 :false];
			//overlay 2
			if (tx >= 0 && ty >= 0 && tx < LEVEL_SIZE && ty < LEVEL_SIZE && gLevel[ETS_OVER2][tx][ty] > -1)
				[gTiles renderTileAtIndex:gLevel[ETS_OVER2][tx][ty] :tx*gTileSize :ty*gTileSize :gTileSize*2 :gPerspectiveOn :0 :0 :false];
		}

	[player->sprite setOverlayWithRed:50 :50 :50 :5];
	glDisable(GL_DEPTH_TEST);
	player->sprite->showShadow=false;
	[player->sprite render:gPerspectiveOn];
	player->sprite->showShadow=true;
	glEnable(GL_DEPTH_TEST);
	[player->sprite setOverlayWithRed:255 :255 :255 :255];

	if (gPerspectiveOn)
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(0.0f, gScreenWidth, gScreenHeight, 0.0f, -1.0f, 1.0f);
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
	}

	glDisable(GL_LIGHTING);
	[ui->sprite render:false];

	if (gInputState == IS_NONE){
		[gFont renderStringAt:60 :gScreenHeight-183+22 :@"102/124" :9 :0];
		[gFont renderStringAt:60 :gScreenHeight-183+40 :@"50/61" :9 :0];
		[gFont renderStringAt:67 :gScreenHeight-183+86 :@"9" :9 :0];
		[gFont renderStringAt:67 :gScreenHeight-183+109 :@"5" :9 :0];
		[gFont renderStringAt:67 :gScreenHeight-183+127 :@"7" :9 :0];
		[gFont renderStringAt:70 :gScreenHeight-183+151 :@"2" :9 :0];
	}

	[gFont renderStringAt:5 :5 :debugLine :9 :0];
	glEnable(GL_LIGHTING);
}

void DrawScreen()
{
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	if (gPerspectiveOn)
	{
		glFrustum(gFrustLeft, gFrustRight, gFrustBot, gFrustTop, gFrustNear, gFrustFar);
		glRotatef(80.0f, 1.0f, 0.0f, 0.0f);
		glTranslatef(-gScreenWidth/2,gZoomLevel,-gScreenHeight*0.80);

		if (keys[SDLK_z]>0){
			glRotatef(-10.0f, 0.0f, 1.0f, 0.0f);
			glTranslatef(40.0f, 0.0f, -20.0f);
		}
		else if (keys[SDLK_x]>0){
			glRotatef(10.0f, 0.0f, 1.0f, 0.0f);
			glTranslatef(-40.0f, 0.0f, 20.0f);
		}
	}
	else
		glOrtho(0.0f, gScreenWidth, gScreenHeight, 0.0f, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glClear(GL_COLOR_BUFFER_BIT);

	if (gEditorState == ES_HIDDEN)
		DrawGame();
	else
		DrawEditor();

	if (gInputState != IS_NONE){
		glDisable(GL_LIGHTING);
		[gFont renderStringAt:20 :gScreenHeight-143 :inputPrompt :9 :0];
		[gFont renderStringAt:60 :gScreenHeight-93 :[NSString stringWithFormat:@"%@%c", inputString, '_'] :9 :0];
		glEnable(GL_LIGHTING);
	}

	SDL_GL_SwapBuffers();
}

void DoPlayerInput()
{
	//key input
	if (gInputState != IS_NONE)
	{
		if (!gInputFinished) {
			for (int i=0; i<SDLK_LAST; i++)
			{
				char c = (char)i;
				if (keys[i]==1 && isalnum(c)) {
					inputString = [NSString stringWithFormat:@"%@%c", inputString, c];
				}
				else if (keys[i] % 4 == 1 && i==SDLK_BACKSPACE)
				{
					NSString* tmpstring = inputString;
					if ([tmpstring length] > 0 )
						tmpstring = [inputString substringToIndex: [inputString length]-1];
					inputString = [NSString stringWithFormat:@"%@", tmpstring];
				}
			}

			if (gMouseDown && gMouseY > gScreenHeight - 150 || keys[SDLK_RETURN]==1)
			{
				gInputFinished = true;
				[ui setCurrentAnimation:@"InGame" :false];
				gMouseDown=false;
			}
		}
		else	//HANDLE THE INPUT RESULT HERE
		{
			if ([inputString length] > 0)
			{
				if (gInputState == IS_SAVELEVEL)
				{
					LevelToRoom();
					SaveRoom([NSString stringWithFormat:@"./%d/%@.dat",gDungeon,inputString]);
					debugLine=@"SAVED";
				}
				else if (gInputState == IS_LOADLEVEL)
				{
					LoadRoom([NSString stringWithFormat:@"./%d/%@.dat",gDungeon,inputString]);
					RoomToLevel(0, 0, MAX_ROOM_SIZE, MAX_ROOM_SIZE);
					debugLine=@"LOADED";
				}
			}

			ClearInput();
		}
	}
	else
	{
		if (keys[SDLK_r]==1){
			player->sprite->x=0;
			player->sprite->y=0;
		}

		if (keys[SDLK_1]==1){
			gDungeon=1;
			debugLine=@"DUNGEON 1";
			LoadTiles();
			LoadBackground();
		}
		if (keys[SDLK_2]==2){
			gDungeon=2;
			debugLine=@"DUNGEON 2";
			LoadTiles();
			LoadBackground();
		}
		if (keys[SDLK_3]==3){
			gDungeon=3;
			debugLine=@"DUNGEON 3";
			LoadTiles();
			LoadBackground();
		}

		if (keys[SDLK_e]==1)
		{
			if (gEditorState == ES_HIDDEN)
			{
				gPerspectiveOn = false;
				gEditorState = ES_EDIT;
				glDisable(GL_LIGHTING);
				//player->sprite->x = 0;
				//player->sprite->y = 0;
			}
			else
			{
				gPerspectiveOn = true;
				gEditorState = ES_HIDDEN;
				glEnable(GL_LIGHTING);
				//player->sprite->x = 0;
				//player->sprite->y = 0;
			}
		}

		if (keys[SDLK_TAB]==1 && gEditorState != ES_HIDDEN)
			if (gEditorState == ES_EDIT)
				gEditorState = ES_TILES;
			else if (gEditorState == ES_TILES)
				gEditorState = ES_EDIT;

		if (gEditorState != ES_TILES)	//GAME INPUT
		{
			if (keys[SDLK_UP]>0)
			{
				player->sprite->y-=32;
				if (keys[SDLK_UP]==1)
					[player setCurrentAnimation:@"Up" :false];
			}
			if (keys[SDLK_DOWN]>0)
			{
				player->sprite->y+=32;
				if (keys[SDLK_DOWN]==1)
					[player setCurrentAnimation:@"Down" :false];
			}
			if (keys[SDLK_LEFT]>0)
			{
				player->sprite->x-=32;
				if (keys[SDLK_LEFT]==1)
					[player setCurrentAnimation:@"Left" :false];
			}
			if (keys[SDLK_RIGHT]>0)
			{
				player->sprite->x+=32;
				if (keys[SDLK_RIGHT]==1)
					[player setCurrentAnimation:@"Right" :false];
			}

			if (keys[SDLK_MINUS]==1)
				gZoomLevel -= 10;
			if (keys[SDLK_EQUALS]==1)
				gZoomLevel += 10;

			if (gEditorState != ES_HIDDEN)
			{
				bool etschanged=false;
				if (keys[SDLK_F1]==1){
					gEditorTileState-=1;
					etschanged=true;
				}
				if (keys[SDLK_F2]==1){
					gEditorTileState+=1;
					etschanged=true;
				}

				if (gEditorTileState == ETS_LAST)
					gEditorTileState = 0;
				else if (gEditorTileState < 0)
					gEditorTileState = ETS_LAST-1;

				if (etschanged)
					switch(gEditorTileState)
					{
						case ETS_GROUND:
						debugLine = @"ETS_GROUND"; break;
						case ETS_3D1:
						debugLine = @"ETS_3D1"; break;
						case ETS_OVER1:
						debugLine = @"ETS_OVER1"; break;
						case ETS_3D2:
						debugLine = @"ETS_3D2"; break;
						case ETS_OVER2:
						debugLine = @"ETS_OVER2"; break;
						case ETS_FLATWALL:
						debugLine = @"ETS_FLATWALL"; break;
						case ETS_FLATWALL2:
						debugLine = @"ETS_FLATWALL2"; break;
						case ETS_CHEST:
						debugLine = @"ETS_CHEST"; break;
						case ETS_EXIT:
						debugLine = @"ETS_EXIT"; break;
						case ETS_BLOCKED:
						debugLine = @"ETS_BLOCKED"; break;
						case ETS_GROUNDALT:
						debugLine = @"ETS_GROUNDALT"; break;
						case ETS_FLATWALLALT:
						debugLine = @"ETS_FLATWALLALT"; break;
						case ETS_NPC:
						debugLine = @"ETS_NPC"; break;
						case ETS_MONSTER:
						debugLine = @"ETS_MONSTER"; break;
					}

				if (keys[SDLK_s]==1){
					//SaveLevel(@"./level.dat");
					GetInput(IS_SAVELEVEL, @"Enter the room # to save:");
					//debugLine = @"SAVED";
				}
				if (keys[SDLK_l]==1){
					//LoadLevel(@"./level.dat");
					GetInput(IS_LOADLEVEL, @"Enter the room # to load:");
					//debugLine = @"LOADED";
				}
				if (keys[SDLK_c]==1){
					ClearLevel();
					ClearRoom();
					debugLine = @"CLEARED";
					player->sprite->x=0;
					player->sprite->y=0;
				}
				if (keys[SDLK_g]==1){
					debugLine = @"GENERATED";
					GenerateLevel();

				}
			}
		}
		else if (gEditorState == ES_TILES)
		{
			if (keys[SDLK_UP]>0)
			{
				gEditorTileOffset-=1;
				if (gEditorTileOffset < 0)
					gEditorTileOffset=0;
			}
			if (keys[SDLK_DOWN]>0)
			{
				gEditorTileOffset+=1;
				if (gEditorTileOffset > 1000)
					gEditorTileOffset=1000;
			}
			if (keys[SDLK_PAGEUP]==1)
			{
				gEditorTileOffset-=10;
				if (gEditorTileOffset < 0)
					gEditorTileOffset=0;
			}
			if (keys[SDLK_PAGEDOWN]==1)
			{
				gEditorTileOffset+=10;
				if (gEditorTileOffset > 1000)
					gEditorTileOffset=1000;
			}
		}

		//mouse input
		if (gMouseDown || gMouseDownR)
		{
			if (gEditorState == ES_HIDDEN)	//GAME INPUT
			{
				if (gMouseY < gScreenHeight-183)
				{
					int x,y;
					x = gMouseX - gScreenWidth/2;
					y = gMouseY - ((gScreenHeight-183)/2);

					float vecx, vecy;
					vecx = (float)x / (gScreenWidth/2.0f);
					vecy = (float)y / ((gScreenHeight-183)/2.0f);

					//move player and check walls
					float tmpx, tmpy;
					int tilex, tiley, tilex2, tiley2;
					bool yesx = true, yesy = true;

					tmpx = player->sprite->x + 2.0f * vecx;
					tmpy = player->sprite->y + 2.0f * vecy;

					tilex = (tmpx+(float)gTileSize*0.32f) / gTileSize;
					tilex2 = (tmpx+(float)gTileSize*0.68f) / gTileSize;

					tiley = (tmpy+(float)gTileSize*0.32f) / gTileSize;
					tiley2 = (tmpy+(float)gTileSize*0.68f) / gTileSize;

					if (tilex < 0 || tiley < 0 || gLevel[ETS_BLOCKED][tilex][tiley] >= 0){
						yesx=false;
						yesy=false;
					}
					else if (tilex2 < 0 || tiley < 0 || gLevel[ETS_BLOCKED][tilex2][tiley] >= 0){
						yesx=false;
						yesy=false;
					}
					else if (tilex < 0 || tiley2 < 0 || gLevel[ETS_BLOCKED][tilex][tiley2] >= 0){
						yesx=false;
						yesy=false;
					}
					else if (tilex2 < 0 || tiley2 < 0 || gLevel[ETS_BLOCKED][tilex2][tiley2] >= 0){
						yesx=false;
						yesy=false;
					}

					if (yesx)
						player->sprite->x=tmpx;
					if (yesy)
						player->sprite->y=tmpy;

					//animate
					NSString *anim=@"";
					if (fabs(vecx) > fabs(vecy))
					{
						if (vecx < 0.0f)
							anim = @"Left";
						else if (vecx > 0.0f)
							anim = @"Right";
					}
					else
					{
						if (vecy < 0.0f)
							anim = @"Up";
						else if (vecy > 0.0f)
							anim = @"Down";
					}

					if ([anim compare:[player getCurrentAnimation]]!=NSOrderedSame)
						[player setCurrentAnimation:anim :false];
				}
			}
			else	// EDITOR INPUT
			{
				if (gEditorState == ES_EDIT)
				{
					int tx,ty;
					tx = (gMouseX + player->sprite->x) / gTileSize;
					ty = (gMouseY + player->sprite->y) / gTileSize;
					debugLine = [NSString stringWithFormat:@"mx: %d, my: %d, tx: %d, ty: %d", gMouseX, gMouseY, tx, ty];
					if (gMouseDown)
				 		gLevel[gEditorTileState][tx][ty] = gEditorTileIndex;
					else if (gMouseDownR)
						gLevel[gEditorTileState][tx][ty] = -1;
				}
				else if (gEditorState == ES_TILES)
				{
					int ty;
					ty = (gMouseY + (gTileSize*gEditorTileOffset)) / gTileSize;
					debugLine = [NSString stringWithFormat:@"mx: %d, my: %d, ty: %d", gMouseX, gMouseY, ty];
					if (gMouseDown)
						gEditorTileIndex = ty;
				}
			}
		}
	}
}

void GameTick()
{
	double current = (double)SDL_GetTicks()/1000.0;
	gTimeDiff = current - gLastTick;
	gTickIsEven = !gTickIsEven;
	if (gTickIsEven) //disable eventick
		gEvenTickTimeDiff += gTimeDiff;
	else
		gEvenTickTimeDiff = gTimeDiff;

	//animate
	if (gMouseDown)
		[player animate:current :false];
	[ui animate:current :false];
	[background animate:current :false];

	int evensecond = ((int)(current*2.5)) % 2;
	gShowGroundAlt = (evensecond == 1);
	evensecond = ((int)(current*1.5)) % 2;
	gShowFlatwallAlt = (evensecond == 1);

	DoPlayerInput();
	if (player->sprite->x < 0.0)
		player->sprite->x = 0;
	if (player->sprite->y < 0.0)
		player->sprite->y = 0;
	background->sprite->x = player->sprite->x;
	background->sprite->y =  player->sprite->y;

	DrawScreen(current);

	gLastTick = current;
}

void PollKeys()
{
    Uint8* keyState = SDL_GetKeyState(NULL);
    for (int i=0; i<SDLK_LAST; i++)
    {
        if (keyState[i])
            keys[i]++;
        else
            keys[i]=0;
    }

	SDL_Event keyevent;    //The SDL event that we will poll to get events.
	while (SDL_PollEvent(&keyevent))   //Poll our SDL key event for any keystrokes.
	{
		if (keyevent.type == SDL_QUIT){
			gQuitGame=true;
			return;
		}
		else if (keyevent.type == SDL_MOUSEBUTTONDOWN){
			gMouseX = keyevent.button.x * ((float)gScreenWidth / (float)gWindowWidth);
            gMouseY = keyevent.button.y * ((float)gScreenHeight / (float)gWindowHeight);

			if (keyevent.button.button==SDL_BUTTON_LEFT)
				gMouseDown = true;
			else if (keyevent.button.button==SDL_BUTTON_RIGHT)
				gMouseDownR = true;
		}
		else if (keyevent.type == SDL_MOUSEMOTION){
			gMouseX = keyevent.button.x * ((float)gScreenWidth / (float)gWindowWidth);
            gMouseY = keyevent.button.y * ((float)gScreenHeight / (float)gWindowHeight);
		}
		else if (keyevent.type == SDL_MOUSEBUTTONUP) {
			gMouseX = keyevent.button.x * ((float)gScreenWidth / (float)gWindowWidth);
            gMouseY = keyevent.button.y * ((float)gScreenHeight / (float)gWindowHeight);

			if (keyevent.button.button==SDL_BUTTON_LEFT)
				gMouseDown = false;
			else if (keyevent.button.button==SDL_BUTTON_RIGHT)
				gMouseDownR = false;
		}
	}
}

int main(int argc, char *argv[])
{
	InitGame(true);
    SDL_WM_SetCaption("RPG - Copyright 2008 DracSoft",0);

	while (true)
    {
		if (!gQuitGame)
		{
			PollKeys();
            if (keys[SDLK_ESCAPE]==1){
				gQuitGame=true;
			}

			GameTick();
			SDL_Delay(17);
		}
		else
			break;
	}

	SDL_Quit();
	return 0;
}

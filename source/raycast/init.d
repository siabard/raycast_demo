module raycast.init;

import std.math;
import std.conv;
import std.algorithm;
import std.stdio;

import bindbc.sdl;

/// RayCast 에 필요한 기본 값을 설정하는 곳

enum PROJECTION_WIDTH = 320;
enum PROJECTION_HEIGHT = 200;

enum TILE_SIZE = 64;
enum WALL_HEIGHT = 64;

enum FOV = 60;

enum ANGLE60    = PROJECTION_WIDTH;
enum ANGLE30    = to!int(floor( ANGLE60 / 2.0f));
enum ANGLE15    = to!int(floor( ANGLE30 / 2.0f));
enum ANGLE90    = to!int(floor( ANGLE30 * 3.0f));
enum ANGLE180   = to!int(floor( ANGLE90 * 2.0f));
enum ANGLE270   = to!int(floor( ANGLE90 * 3.0f));
enum ANGLE360   = ANGLE60 * 6;
enum ANGLE0     = 0;
enum ANGLE5     = to!int(floor( ANGLE30 / 6.0f));
enum ANGLE10    = ANGLE5 * 2;
enum ANGLE45    = ANGLE15 * 3;

enum DISTANCE_TO_PROJECTION = 277; // 160 / tan(30 deg)

enum MAP_WIDTH = 12;
enum MAP_HEIGHT = 12;

enum DEBUG = false;

enum MAP1 = 
  "WWWWWWWWWWWW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOWOWOOW" ~
  "WOOWOOWOWOOW" ~
  "WOOWOOWOWOOW" ~
  "WOOWOOWOWOOW" ~
  "WOOWOOWOWOOW" ~
  "WOOWOOWOWOOW" ~
  "WOOWOOWOWOOW" ~ 
  "WOOWWWWOWOOW" ~
  "WOOOOOOOOOOW" ~
  "WWWWWWWWWWWW";

enum MAP2 = 
  "WWWWWWWWWWWW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WWWWWWWWWWWW";

enum MAP3 = 
  "WWWWWWWWWWWW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOOOOW" ~
  "WOOOOOOOWOOW" ~
  "WOOWOWOOWOOW" ~
  "WOOWOWWOWOOW" ~
  "WOOWOOWOWOOW" ~
  "WOOOWOWOWOOW" ~
  "WOOOWOWOWOOW" ~
  "WOOOWWWOWOOW" ~
  "WOOOOOOOOOOW" ~
  "WWWWWWWWWWWW";

class RayCastWindow {
  SDL_Renderer* renderer;


  float[] g_tangent  = [];
  float[] g_sine     = [];
  float[] g_cosine   = [];
  float[] g_isine    = [];
  float[] g_icosine  = [];
  float[] g_itangent = [];
  float[] g_fish     = [];
  float[] g_xstep    = [];
  float[] g_ystep    = [];

  float player_x = 0;
  float player_y = 0;
  int player_arc = 0;
  float player_distance_to_projection_plane = 0;
  float player_height = 0;
  float player_speed = 0;
  float project_plane_y_center = 0;

  // keep player coordinates in the overhead map
  float player_map_x = 0;
  float player_map_y = 0;
  float minimap_width = 0;

  // movement flag
  bool key_up = false;
  bool key_down = false;
  bool key_left = false;
  bool key_right = false;

  // 2차원 맵
  string map;
  
  this(SDL_Renderer* renderer) {
    this.renderer = renderer;
    
    this.player_x = 100.0f;
    this.player_y = 160.0f;
    this.player_arc = ANGLE5 + ANGLE5;
    this.player_distance_to_projection_plane = 277.0f; // 160 / tan(30 degree) = 277
    this.player_height = 32.0f;
    this.player_speed  = 16.0f;

    // Screen 높이의 절반 
    this.project_plane_y_center = PROJECTION_HEIGHT / 2.0f;
    
  }

  void init_table() {
    int i;
    float radian;

    this.g_sine.length     = ANGLE360 + 1;
    this.g_isine.length    = ANGLE360 + 1;
    this.g_cosine.length   = ANGLE360 + 1;
    this.g_icosine.length  = ANGLE360 + 1;
    this.g_tangent.length  = ANGLE360 + 1;
    this.g_itangent.length = ANGLE360 + 1;
    this.g_fish.length     = ANGLE360 + 1;
    this.g_xstep.length    = ANGLE360 + 1;
    this.g_ystep.length    = ANGLE360 + 1;

    for(i = 0; i <= ANGLE360; i++) {
      // radian 값에 따른 값을 머리 설정한다.
      // 0.0001 을 더하는 것은 90도, 180도, 270도, 360도 등에서 0이나 무한대가 발생하는 것을 막기 위해서다.
      radian = pix2rad(to!float(i)) + 0.0001f;
      this.g_sine[i] = sin(radian);
      this.g_cosine[i] = cos(radian);
      this.g_tangent[i] = tan(radian);
      this.g_isine[i] = 1.0 / this.g_sine[i];
      this.g_icosine[i] = 1.0 / this.g_cosine[i];
      this.g_itangent[i] = 1.0 / this.g_tangent[i];


      // Next we crate a table to speed up wall lookups.
      // 
      //  You can see that the distance between walls are the same
      //  if we know the angle
      //  _____|_/next xi______________
      //       |
      //  ____/|next xi_________   slope = tan = height / dist between xi's
      //     / |
      //  __/__|_________  dist between xi = height/tan where height=tile size
      // old xi|
      //                  distance between xi = x_step[view_angle];


      this.g_xstep[i] = TILE_SIZE / this.g_tangent[i];
      this.g_ystep[i] = TILE_SIZE * this.g_tangent[i];

      // 왼쪽
      if (i >= ANGLE90 && i < ANGLE270) {
	if(this.g_xstep[i] > 0) {
	  this.g_xstep[i] = -this.g_xstep[i];
	}
      } else {
	// 오른쪽
	if(this.g_xstep[i] < 0) {
	  this.g_xstep[i] = -this.g_xstep[i];
	}
      }

      // 아래쪽
      if (i >= ANGLE0 && i < ANGLE180) {
	if(this.g_ystep[i] < 0) {
	  this.g_ystep[i] = -this.g_ystep[i];
	}
      } else {
	// 위쪽
	if(this.g_ystep[i] > 0) {
	  this.g_ystep[i] = -this.g_ystep[i];
	}
      }			
    } //  for(i = 0; i <= ANGLE360; i++)

    // Create table for FISHBOWL distortion
    for(i = -ANGLE30; i <= ANGLE30; i++) {
      radian = pix2rad( to!float(i));
      
      this.g_fish[i + ANGLE30] = 1.0f / cos(radian);

    } //for(i >= -ANGLE30; i <= ANGLE30; i++)
    // End of fixing FISHBOWL distortion

    this.map = MAP3;

  } // void init_table;


  void draw_overhead_map() {
    this.minimap_width = 5.0f;
    
    ubyte r, g, b, a;
    for(int row = 0; row < MAP_HEIGHT; row++) {
      for(int col = 0; col < MAP_WIDTH; col++) {
	// white color
	r = 255;
	g = 255;
	b = 255;
	a = 255;

	if(this.map[row * MAP_WIDTH + col] == 'W') {
	  // black color
	  r = 80; 
	  g = 80;
	  b = 80;
	}

	SDL_Rect rect = {
	x: to!int(PROJECTION_WIDTH + (col * this.minimap_width)), 
	y: to!int(row * this.minimap_width),
	w: to!int( this.minimap_width),
	h: to!int( this.minimap_width)
	};

	SDL_SetRenderDrawColor(this.renderer, r, g, b, a);
	SDL_RenderFillRect(this.renderer, &rect);
      }
    }

    this.player_map_x = PROJECTION_WIDTH + (this.player_x * this.minimap_width / TILE_SIZE);
    this.player_map_y = this.player_y * this.minimap_width / TILE_SIZE;
    
  } // void draw_overhead_map

  void draw_background() {
    // color of sky
    ubyte r = 255;

    int increment = 1;

    int row = 0;
    for(row = 0; row < PROJECTION_HEIGHT / 2; row += increment) {
      SDL_SetRenderDrawColor(this.renderer, r, 125, 225, 255);
      SDL_RenderDrawLine(this.renderer, 0, row, PROJECTION_WIDTH, row);
      r -= increment;
    }

    // color of ground 
    r = 22;
    for(; row < PROJECTION_HEIGHT; row += increment) {
      SDL_SetRenderDrawColor(this.renderer, r, 20, 20, 255);
      SDL_RenderDrawLine(this.renderer, 0, row, PROJECTION_WIDTH, row);
      r += increment;
    }

  } // end of draw_background

  void draw_ray_on_overhead_map(int x, int y) {
    // draw line from the player position to the positon where the ray
    // intersect with wall

    SDL_SetRenderDrawColor(this.renderer, 0, 255, 0, 255);
    SDL_RenderDrawLine(this.renderer, 
		       to!int(this.player_map_x), 
		       to!int(this.player_map_y), 
		       to!int(PROJECTION_WIDTH + (x * this.minimap_width) / TILE_SIZE),
		       to!int(y * this.minimap_width / TILE_SIZE));
  } // end of draw_ray_on_overhead_map

  void draw_player_POV_on_overhead_map() {
    SDL_SetRenderDrawColor(this.renderer, 255, 0, 0, 255);
    SDL_RenderDrawLine(this.renderer, 
		       to!int(this.player_map_x),
		       to!int(this.player_map_y),
		       to!int(this.player_map_x + this.g_cosine[ this.player_arc ] * 10),
		       to!int(this.player_map_y + this.g_sine[ this.player_arc ] * 10));
      
  } // draw_player_POV_on_overhead_map

  void  draw_raycast() {
    int vertical_grid = 0;
    int horizontal_grid = 0;

    int dist_to_next_vertical_grid = 0;
    int dist_to_next_horizontal_grid = 0;
    
    float x_intersection = 0;
    float y_intersection = 0;
    
    float dist_to_next_x_intersection = 0;
    float dist_to_next_y_intersection = 0;

    int x_grid_index = 0;  // current cell that the ray is in
    int y_grid_index = 0;

    float dist_to_vertical_grid_being_hit = 0; // distance of the x and y ray intersections from the viewpoint
    float dist_to_horizontal_grid_being_hit = 0;

    int cast_arc, cast_column = 0;
    
    cast_arc = this.player_arc;
    
    // field of view is 60 degree with the point of view (player's direction in the middle)
    // 30  30
    //    ^
    //  \ | /
    //   \|/
    //    v
    // we will trace the rays starting from the leftmost ray
    cast_arc -= ANGLE30;

    if(cast_arc < 0) {
      cast_arc = ANGLE360 + cast_arc;
    }

    for(cast_column= 0; cast_column < PROJECTION_WIDTH; cast_column++ ) {
      // Ray is between 0 to 180 degree (1,2 사분면)
      
      // Ray 가 아랫쪽을 향할 때
      if (cast_arc > ANGLE0 && cast_arc < ANGLE180) {
	// truncuate then add to get the coordinate of the FIRST grid (horizontal
	// wall) that is in front of the player (this is in pixel unit)
	// ROUNDED DOWN
	
	horizontal_grid = to!int(floor( this.player_y / TILE_SIZE)) * TILE_SIZE + TILE_SIZE;

	// 다음 수평벽과의 거리 
	dist_to_next_horizontal_grid = TILE_SIZE;
	float x_temp = this.g_itangent[ cast_arc ] * (horizontal_grid - this.player_y);

	// we can get the vertical distance to that wall by
	// (horizontalGrid-playerY)
	// we can get the horizontal distance to that wall by
	// 1/tan(arc)*verticalDistance
	// find the x interception to that wall

	x_intersection = x_temp + this.player_x;

      } else {
	// RAY가 위쪽을 향할 때
	horizontal_grid = to!int(floor( this.player_y / TILE_SIZE)) * TILE_SIZE;
	dist_to_next_horizontal_grid = -TILE_SIZE;

	float x_temp = this.g_itangent[ cast_arc ] * ( horizontal_grid - this.player_y);
	
	x_intersection = x_temp + this.player_x;

	horizontal_grid--;
	
	if(DEBUG) {}
	  
      } // end of if (cast_arc > ANGLE0 && cast_arc < ANGLE180)

      // 수평 벽확인하기
      // Ray가 왼쪽이나 오른쪽을 직접보는 경우만 무시함. 
      if( cast_arc == ANGLE0 || cast_arc == ANGLE180) {
	dist_to_horizontal_grid_being_hit = float.max;
      } else {
	// RAY를 수평 벽에 부딪힐때까지 이동함
	dist_to_next_x_intersection = this.g_xstep[ cast_arc ];
	while( true ) {
	  x_grid_index = to!int(floor( x_intersection / TILE_SIZE ));
	  y_grid_index = horizontal_grid / TILE_SIZE;
	  int map_index = y_grid_index * MAP_WIDTH + x_grid_index;


	  // map 영역 보는 거리 제약 
	  if (x_grid_index >= MAP_WIDTH || y_grid_index >= MAP_HEIGHT || 
	      x_grid_index < 0 || y_grid_index < 0) {
	    dist_to_horizontal_grid_being_hit = float.max;
	    break;
	  } else if (this.map[map_index] != 'O') {
	    // grid 가 빈공간이 아니면 중지
	    dist_to_horizontal_grid_being_hit = ( x_intersection - this.player_x ) * this.g_icosine[ cast_arc ];
	    break;
	  } else {
	    // 그 외의 경우에는 다음 그리드로 계속 진행한다. 
	    x_intersection += dist_to_next_x_intersection;
	    horizontal_grid += dist_to_next_horizontal_grid;
	  }
	}
      } // end of if( cast_arc == ANGLE0 || cast_arc == ANGLE100)

          
      // RAY가 오른쪽으로 향함 
      if (cast_arc < ANGLE90 || cast_arc > ANGLE270) {
	vertical_grid = TILE_SIZE + to!int(floor(this.player_x / TILE_SIZE)) * TILE_SIZE;
	dist_to_next_vertical_grid = TILE_SIZE;

	float y_temp = this.g_tangent[ cast_arc ] * ( vertical_grid - this.player_x);
	y_intersection = y_temp + this.player_y;
      } else {
	// RAY가 왼쪽으로 향함 
	vertical_grid = to!int(floor(this.player_x / TILE_SIZE)) * TILE_SIZE;
	dist_to_next_vertical_grid = -TILE_SIZE;
	float y_temp = this.g_tangent[ cast_arc ] * (vertical_grid - this.player_x);
	y_intersection = y_temp + this.player_y;
	vertical_grid--;
      } // end of  if (cast_arc < ANGLE90 || cast_arc > ANGLE270) 

      // 수직으로 발사되는 경우 
      if (cast_arc == ANGLE90 || cast_arc == ANGLE270) {
	dist_to_vertical_grid_being_hit = float.max;
      } else {
	dist_to_next_y_intersection = this.g_ystep[cast_arc];
	while( true) {
	  // 현재 검사할 map 위치 계산
	  x_grid_index = vertical_grid / TILE_SIZE;
	  y_grid_index = to!int(floor(y_intersection / TILE_SIZE));

	  int map_index = y_grid_index * MAP_WIDTH + x_grid_index;

	  if ((x_grid_index >= MAP_WIDTH) ||
	      (y_grid_index >= MAP_HEIGHT) ||
	      x_grid_index < 0 || y_grid_index < 0) {
	    dist_to_vertical_grid_being_hit = float.max;
	    break;
	  } else if (this.map[ map_index ] != 'O') {
	    dist_to_vertical_grid_being_hit = (y_intersection - this.player_y) * this.g_isine[ cast_arc ];
	    break;
	  } else {
	    y_intersection += dist_to_next_y_intersection;
	    vertical_grid += dist_to_next_vertical_grid;
	  }
	} // end of while
      } // end of if (cast_arc == ANGLE90 || cast_arc == ANGLE270) 

      // DRAW WALL SLICE
      float scale_factor = 0;
      float dist = 0;
      float top_of_wall = 0; // used to computer the top and bottom of the silver
      float bottom_of_wall = 0; // will be the starting point of floor and celling 

      // determine which ray strikes a closer wall.
      // if yray distance to the wall is closer, the y_distance will be shorter than the x_distance

      if( dist_to_horizontal_grid_being_hit < dist_to_vertical_grid_being_hit) {
	// the next function call (draw_ray_on_map()) is not a part of raycasting rendering part.
	// it just draws the ray on the overhead map to illustrate the raycasting process
	
	this.draw_ray_on_overhead_map(to!int(x_intersection), horizontal_grid);
	dist = dist_to_horizontal_grid_being_hit;
      
      } else {
	// else we use xray instread (meaning the vertical wall is closer than the horizontal wall)
	// the next function call (draw_ray_on_map()) is not a part of raycasting rendering part.
	// it just draws the ray on the overhead map to illustrate the raycasting process
	this.draw_ray_on_overhead_map(vertical_grid, to!int(y_intersection));
	dist = dist_to_vertical_grid_being_hit;

      }  // end of if( dist_to_horizontal_grid_being_hit < dist_to_vertical_grid_being_hit) 

      // correct distance (compensate for the fishbowl effect)
      dist /= this.g_fish[ cast_column ];

      // projected wall height / wall height = player_dist_to_projection_plane / dist
      float projected_wall_height = WALL_HEIGHT * this.player_distance_to_projection_plane / dist;
      bottom_of_wall = this.project_plane_y_center + (projected_wall_height * 0.5 );
      top_of_wall = this.project_plane_y_center - (projected_wall_height * 0.5);

      if (top_of_wall < 0) {
	top_of_wall = 0;
      }

      if (bottom_of_wall >= PROJECTION_HEIGHT) {
	bottom_of_wall = PROJECTION_HEIGHT - 1;
      }

      // add simple shading so that farther wall slices appear darker;
      // 850 is arbitary value of the farthest distance.

      dist = floor(dist);
      ubyte color = to!ubyte(255 - min(max(0, (dist / 750.0) * 255.0), 255));
      
      SDL_SetRenderDrawColour(this.renderer, color, color, color, 255);
      SDL_Rect dst = {x: cast_column, y: to!int(top_of_wall), w: 1, h: to!int((bottom_of_wall - top_of_wall) + 1 ) };
      SDL_RenderFillRect(this.renderer, &dst);
      
      // TRACE THE NEXT RAY
      cast_arc += 1;
      if(cast_arc >= ANGLE360) {
	cast_arc -= ANGLE360;
      }
    } // end of for(cast_column= 0; cast_column < PROJECTION_WIDTH; cast_coumn++ )

  } // end of void draw_raycast


  void render() {
    this.draw_overhead_map();
    this.draw_background();
    this.draw_raycast();
    this.draw_player_POV_on_overhead_map();
    
  }

  void update(ulong dt) {
    float delta_time = dt / 1000.0f;

    if(this.key_left) {

      this.player_arc -= to!int(ANGLE180 * delta_time);
      if(this.player_arc < ANGLE0) {
	this.player_arc += ANGLE360;
      }
    }

    if(this.key_right) {

      this.player_arc += to!int(ANGLE180 * delta_time);
      if(this.player_arc > ANGLE360) {
	this.player_arc -= ANGLE360;
      }
    }

    float player_x_dir = this.g_cosine[ this.player_arc ] ;
    float player_y_dir = this.g_sine[   this.player_arc ];

    if(this.key_up) {
      this.player_x += round( player_x_dir + this.player_speed * delta_time );
      this.player_y += round( player_y_dir + this.player_speed * delta_time );
    }

    if(this.key_down) {
      this.player_x -= round( player_x_dir + this.player_speed * delta_time );
      this.player_y -= round( player_y_dir + this.player_speed * delta_time );
    }

  }

} // end of class

/**
 *
 * pix2rad : convert pixel to radian
 * Radian <-> Degreee 라기 보다는 Projection 영역의 폭을 기준으로하는
 * 조금 변경된 공식임
 * 말하자면 1 픽셀당 몇 라디안인지 계산함 
 * PI ( 180도) 는 320픽셀이 FOV 60도를 감안하면 960픽셀에 준함
 */


float pix2rad(float pixel) {
  import std.math;

  return pixel * PI / ANGLE180; 
}

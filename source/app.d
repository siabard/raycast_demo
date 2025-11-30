module main;

import std.stdio;

import bindbc.sdl;
import bindbc.common;
import bindbc.loader;

import raycast.init;

int main()
{
  auto ret = loadSDL();
  auto img_ret = loadSDLImage();

  if(ret != sdlSupport && img_ret != sdlImageSupport) {
    writeln("SDL / SDL_Image is not ready!");
    return 1;
  }


  // SDL 초기화 루틴 
  int sdlInited = SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
  IMG_Init(IMG_INIT_PNG | IMG_INIT_JPG);

  if(sdlInited != 0) {
    writeln("SDL2 system cannot be initialized.");
    return 1;
  }

  // SDL Window / SDL Renderer

  SDL_Window* window;
  SDL_Renderer* renderer;

  window = SDL_CreateWindow(
			    "RayCasting...", 
			    SDL_WINDOWPOS_UNDEFINED, 
			    SDL_WINDOWPOS_UNDEFINED,
			    400,
			    200,
			    SDL_WINDOW_SHOWN );
  renderer = SDL_CreateRenderer(
				window, -1, 
				SDL_RENDERER_ACCELERATED | 
				SDL_RENDERER_PRESENTVSYNC | 
				SDL_RENDERER_TARGETTEXTURE);


  // Game Loop
  SDL_Event event;
  bool is_running = true;

  RayCastWindow raywin = new RayCastWindow(renderer);
  ulong last_tick = SDL_GetTicks64();
  ulong current_tick = SDL_GetTicks64();
  ulong dt = 0;
  raywin.init_table();

  while(is_running) {
    
    dt = current_tick - last_tick;
    last_tick = current_tick;
    
    while(SDL_PollEvent(&event)) {

      if(event.type == SDL_QUIT) {
	is_running = false;
      } else if(event.type == SDL_KEYDOWN) {
	
	switch(event.key.keysym.scancode) {
	case SDL_SCANCODE_W:
	  raywin.key_up = true;
	  break;
	case SDL_SCANCODE_A:
	  raywin.key_left = true;
	  break;
	case SDL_SCANCODE_S:
	  raywin.key_down = true;
	  break;
	case SDL_SCANCODE_D:
	  raywin.key_right = true;
	  break;
	default:
	  break;
	}
      } else if(event.type == SDL_KEYUP) {
	switch(event.key.keysym.scancode) {
	case SDL_SCANCODE_W:
	  raywin.key_up = false;
	  break;
	case SDL_SCANCODE_A:
	  raywin.key_left = false;
	  break;
	case SDL_SCANCODE_S:
	  raywin.key_down = false;
	  break;
	case SDL_SCANCODE_D:
	  raywin.key_right = false;
	  break;
	default:
	  break;
	}
      }
      
    }
    
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);
    

    raywin.update(dt);
    raywin.render();
    
    SDL_RenderPresent(renderer);

    current_tick = SDL_GetTicks64();
  }
  


  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);

  IMG_Quit();
  SDL_Quit();

  return 0;
}

module main;

import std.stdio;

import bindbc.sdl;
import bindbc.common;
import bindbc.loader;

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
			    320,
			    200,
			    SDL_WINDOW_SHOWN );
  renderer = SDL_CreateRenderer(
				window, -1, 
				SDL_RENDERER_ACCELERATED | 
				SDL_RENDERER_PRESENTVSYNC | 
				SDL_RENDERER_TARGETTEXTURE);


  // Game Loop
  


  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);

  IMG_Quit();
  SDL_Quit();

  return 0;
}

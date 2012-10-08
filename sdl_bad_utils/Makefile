compile: init_stuff.so sdl_event.so gl_sdl_load_img.so
default: compile

clean:
	rm -f init_stuff.so sdl_event.so gl_sdl_load_img.so

#Auch weakness.
gnarly-non-existant-file:
	echo ''
test: gnarly-non-existant-file
	cd test;\
	make test;

init_stuff.so: init_stuff.c
	gcc -shared init_stuff.c -fPIC \
	    -o init_stuff.so -std=c99 -lGL -lm `sdl-config --cflags --libs`;

sdl_event.so: sdl_event.c
	gcc -shared sdl_event.c -fPIC \
	    -o sdl_event.so -std=c99 -lGL -lm `sdl-config --cflags --libs`;

gl_sdl_load_img.so: gl_sdl_load_img.c
	gcc -shared gl_sdl_load_img.c -fPIC \
	    -o gl_sdl_load_img.so -std=c99 -lGL -l SDL_image -lm \
	    `sdl-config --cflags --libs`;


default: all

all: sdl_bad_utils_

sdl_bad_utils_: #Otherwise it will try do stuff to the directory.
	cd sdl_bad_utils; make

test_all:
	cd util/test; make

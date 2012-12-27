
# C parser
The main current goal is to parse C headers and generate FFI from it, but hopefully it will 
do better.

It is licensed under the MIT license, see `doc/mit.txt` from project base directory.

## Important bits of the API:

TODO

## Notes

* This is somewhat stupid because it negates code up from(but not including) treekenize,
  but using stuff in `/usr/include/clang-c/Index.h` might be/have been better.

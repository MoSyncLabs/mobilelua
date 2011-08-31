// These functions are already defined as macros
// in the MoSync API and in order not get compile
// errors, we only use this declarations in the binding
// definitions used by tolua, not in the actual C-code.
// This file is never included in any C-code.

MAExtent EXTENT(int x, int y);
int EXTENT_X(MAExtent extent);
int EXTENT_Y(MAExtent extent);


/*
 * Copyright (c) 2011 MoSync AB
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

// This file contains function declarations for use with tolua.
// The functions defined here are add-ons to the MoSync syscalls,
// to eanble to do things like manipulating memory from Lua.

// SysScaleImage scaling types.
#define SCALETYPE_NEAREST_NEIGHBOUR 1
#define SCALETYPE_BILINEAR 2

/**
 * Scale an image the the specified width and height.
 *
 * @param sourceImage The source image (left untouched).
 * @param sourceRect part of source image to scale, may be NULL.
 * @param scaledImagePlaceholder Handle that will refer to the
 * scaled image.
 * @param scaledImageWidth The width of the scaled image.
 * @param scaledImageHeight The height of the scaled.
 *
 * @return 1 on success, 0 on error (not enough memory to
 * create destination image).
 */
int SysImageScale(MAHandle sourceImage, MARect* sourceRect, MAHandle destImagePlaceholder, int scaledImageWidth, int scaledImageHeight, int scaleType);

/**
 * Scale an image proportionally by a scale factor.
 *
 * @param sourceImage The source image (left untouched).
 * @param sourceRect part of source image to scale, may be NULL.
 * @param scaledImagePlaceholder Handle that will refer to the
 * scaled image.
 * @param scaleFactor The scale factor.
 *
 * @return 1 on success, 0 on error (not enough memory to
 * create destination image).
 */
int SysImageScaleProportionally(MAHandle sourceImage, MARect* sourceRect, MAHandle destImagePlaceholder, double scaleFactor, int scaleType);

// Font and text support.

void* SysTextCreate(int fontHandle);
void SysTextDelete(void* textObj);
void SysTextSetString(void* textObj, char* str);
void SysTextSetLineSpacing(void* textObj, int lineSpacing);
int SysTextGetStringSize(void* textObj, int extent);
void SysTextDrawString(void* textObj, int x, int y, int extent);

/**
 * Allocate data.
 */
void* SysAlloc(int size);

/**
 * Free allocated data.
 * This function is used to free allocated data, and
 * also data structures like Events, Points and Rects.
 */
void SysFree(void* buffer);

// Buffer of type void*
int SysBufferGetInt(void* buffer, int offset);
void SysBufferSetInt(void* buffer, int offset, int value);
int SysBufferGetByte(void* buffer, int offset);
void SysBufferSetByte(void* buffer, int offset, int value);

/**
 * This function is implemented in LuaEngine.cpp.
 * This declaration is here for documentation purposes only.
 */
//void SysBufferToString(void* buffer);

// MAEvent
MAEvent* SysEventCreate();
int SysEventGetType(MAEvent* event);
int SysEventGetKey(MAEvent* event);
int SysEventGetNativeKey(MAEvent* event);
uint SysEventGetCharacter(MAEvent* event);
int SysEventGetX(MAEvent* event);
int SysEventGetY(MAEvent* event);
int SysEventGetState(MAEvent* event);
MAHandle SysEventGetConnHandle(MAEvent* event);
int SysEventGetConnOpType(MAEvent* event);
int SysEventGetConnResult(MAEvent* event);
int SysEventGetTextBoxResult(MAEvent* event);
int SysEventGetTextBoxLength(MAEvent* event);
void* SysEventGetData(MAEvent* event);

// MAPoint2d
MAPoint2d* SysPointCreate();
int SysPointGetX(MAPoint2d* point);
int SysPointGetY(MAPoint2d* point);
void SysPointSetX(MAPoint2d* point, int x);
void SysPointSetY(MAPoint2d* point, int y);

// MARect
MARect* SysRectCreate();
int SysRectGetLeft(MARect* rect);
int SysRectGetTop(MARect* rect);
int SysRectGetWidth(MARect* rect);
int SysRectGetHeight(MARect* rect);
void SysRectSetLeft(MARect* rect, int left);
void SysRectSetTop(MARect* rect, int top);
void SysRectSetWidth(MARect* rect, int width);
void SysRectSetHeight(MARect* rect, int height);

// SMACopyData
MACopyData* SysCopyDataCreate(MAHandle dst, int dstOffset, MAHandle src, int srcOffset, int size);

// Screen functions.
void SysScreenSetColor(int red, int green, int blue);
void SysScreenDrawText(const char* text, int x, int y, void* font);

// String functions.

/**
 * Convert a char string to a wchar string.
 * It is the responsibility of the caller to deallocate the
 * returned string with SysFree.
 */
void* SysStringCharToWideChar(const char* str);

/**
 * Convert a wchar string to a char string.
 * In C it is the responsibility of the caller to deallocate the
 * returned string with SysFree. When called from Lua, a Lua string
 * will be returned.
 * Conversion only supports basic 256 char set.
 */
char* SysStringWideCharToChar(const void* wstr);

/**
 * Helper method that reads a text string from resource file.
 * In C it is the responsibility of the caller to deallocate the
 * returned string with SysFree. When called from Lua, a Lua string
 * will be returned.
 */
char* SysLoadStringResource(MAHandle handle);

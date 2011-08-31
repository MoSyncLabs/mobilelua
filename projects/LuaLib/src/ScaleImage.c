/* Copyright (C) 2009 Mobile Sorcery AB

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2, as published by
the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the Free
Software Foundation, 59 Temple Place - Suite 330, Boston, MA
02111-1307, USA.
*/

#include <ma.h>
#include <mavsprintf.h>
#include "inc/ScaleImage.h"

#define RED(x)			(((x)&0x00ff0000)>>16)
#define GREEN(x)		(((x)&0x0000ff00)>>8)
#define BLUE(x)			(((x)&0x000000ff))
#define ALPHA(x)		(((x)&0xff000000)>>24)
#define RGBA(r,g,b,a)	 ((((a)&0xff)<<24)| \
						 (((r)&0xff)<<16)| \
						 (((g)&0xff)<<8)| \
						 (((b)&0xff)));

static void nearestNeighbourScale(
	int* dst,
	int dwidth,
	int dheight,
	int dpitch,
	int* src,
	int swidth,
	int sheight,
	int spitch)
{
	int deltax = (swidth<<16)/dwidth;
	int deltay = (sheight<<16)/dheight;
	int x = 0;
	int u;
	int v = 0;
	int* src_scan;

	while (dheight)
	{
		x = dwidth;
		u = 0;
		src_scan = &src[(v>>16)*spitch];

		while (x > 0)
		{
			switch (x & 0x3)
			{
				case 0:
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					x-=4;
					break;

				case 3:
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					x-=3;
					break;

				case 2:
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					x-=2;
					break;

				case 1:
					*dst++ = src_scan[(u>>16)];
					u+=deltax;
					x-=1;
					break;
			 }
		}
		dst+=-dwidth+dpitch;
		--dheight;
		v+=deltay;
	}
}

static void bilinearScale(
	int* dst,
	int dwidth,
	int dheight,
	int dpitch,
	int* src,
	int swidth,
	int sheight,
	int spitch)
{
	int deltax = (swidth<<16)/dwidth;
	int deltay = (sheight<<16)/dheight;

	int x = 0;
	int u;
	int v = 0;
	int* src_scan;

	while (dheight)
	{
		x = dwidth;
		u = 0;
		src_scan = &src[(v>>16)*spitch];

		while (x)
		{
			// get bilinear filtered value
	//		int frac_x = (u-(u&0xffff0000));
	//		int frac_y = (v-(v&0xffff0000));
			int frac_x = 0xffff-(u&0xffff);
			int frac_y = (v&0xffff);

			int pos = (u>>16);

			int tl_r = RED(src_scan[pos]);
			int tl_g = GREEN(src_scan[pos]);
			int tl_b = BLUE(src_scan[pos]);
			int tl_a = ALPHA(src_scan[pos]);

			int bl_r = RED(src_scan[pos+spitch]);
			int bl_g = GREEN(src_scan[pos+spitch]);
			int bl_b = BLUE(src_scan[pos+spitch]);
			int bl_a = ALPHA(src_scan[pos+spitch]);

			tl_r = ((tl_r)*frac_x + (RED(src_scan[pos+1]))*(0xffff-frac_x))>>16;
			tl_g = ((tl_g)*frac_x + (GREEN(src_scan[pos+1]))*(0xffff-frac_x))>>16;
			tl_b = ((tl_b)*frac_x + (BLUE(src_scan[pos+1]))*(0xffff-frac_x))>>16;
			tl_a = ((tl_a)*frac_x + (ALPHA(src_scan[pos+1]))*(0xffff-frac_x))>>16;

			bl_r = ((bl_r)*frac_x + (RED(src_scan[pos+spitch+1]))*(0xffff-frac_x))>>16;
			bl_g = ((bl_g)*frac_x + (GREEN(src_scan[pos+spitch+1]))*(0xffff-frac_x))>>16;
			bl_b = ((bl_b)*frac_x + (BLUE(src_scan[pos+spitch+1]))*(0xffff-frac_x))>>16;
			bl_a = ((bl_a)*frac_x + (ALPHA(src_scan[pos+spitch+1]))*(0xffff-frac_x))>>16;


			//tl_r += (((RED(src_scan[pos+1])-tl_r)*frac_x)>>16);
			//tl_g += (((GREEN(src_scan[pos+1])-tl_g)*frac_x)>>16);
			//tl_b += (((BLUE(src_scan[pos+1])-tl_b)*frac_x)>>16);
			//tl_a += (((ALPHA(src_scan[pos+1])-tl_a)*frac_x)>>16);

			//bl_r += (((RED(src_scan[pos+spitch+1])-bl_r)*frac_x)>>16);
			//bl_g += (((GREEN(src_scan[pos+spitch+1])-bl_g)*frac_x)>>16);
			//bl_b += (((BLUE(src_scan[pos+spitch+1])-bl_b)*frac_x)>>16);
			//bl_a += (((ALPHA(src_scan[pos+spitch+1])-bl_a)*frac_x)>>16);

			*dst = RGBA(
				tl_r + (((bl_r-tl_r)*frac_y)>>16),
				tl_g + (((bl_g-tl_g)*frac_y)>>16),
				tl_b + (((bl_b-tl_b)*frac_y)>>16),
				tl_a + (((bl_a-tl_a)*frac_y)>>16)
				);

			u+=deltax;

			--x;
			++dst;
		}
		dst+=-dwidth+dpitch;
		--dheight;
		v+=deltay;
	}
}

/**
 * Scale an image, either by width and height or by a scale factor.
 *
 * @param sourceImage The source image (left untouched).
 * @param sourceRect part of source image to scale, may be NULL.
 * @param scaledImagePlaceholder Handle that will refer to the
 * scaled image.
 * @param scaledImageWidth The width of the scaled image.
 * @param scaledImageHeight The height of the scaled.
 * @param scaleFactor The scale factor. Will be used if
 * both scaledImageWidth and caledImageHeight are zero.
 *
 * @return 1 on success, 0 on error (not enough memory to
 * create destination image).
 */
static int imageScaleHelper(
	MAHandle sourceImage,
	MARect* sourceRect,
	MAHandle scaledImagePlaceholder,
	int scaledImageWidth,
	int scaledImageHeight,
	double scaleFactor,
	int scaleType)
{
	// Get image dimensions.
	MARect tempRect;
	MAExtent imageDims = maGetImageSize(sourceImage);
	int imageWidth = EXTENT_X(imageDims);
	int imageHeight = EXTENT_Y(imageDims);

	// Allocate image data. Allocate one extra colum/row of pixels
	// that might be on overflow in bilinear scaling.
	int* imageData = (int*) malloc(sizeof(int)*(imageWidth+1)*(imageHeight+1));
	// Check that allocation worked.
	if (NULL == imageData)
	{
		return 0; // Error.
	}

	// If sourceRect is NULL, we use the whole image area.
	if (!sourceRect) {
		tempRect.left = 0;
		tempRect.top = 0;
		tempRect.width = imageWidth;
		tempRect.height = imageHeight;
		sourceRect = &tempRect;
	}

	// Copy image pixels to pixel array.
	maGetImageData(sourceImage, imageData, sourceRect, imageWidth+1);

	// Pad edges by copying last column/row to the extra column/row.
	if (scaleType == SCALETYPE_BILINEAR)
	{
		int i;
		for (i = 0; i < imageWidth; ++i)
		{
			imageData[i+((imageWidth+1)*imageHeight)] =
				imageData[i+((imageWidth+1)*(imageHeight-1))];
		}

		int j;
		for (j = 0; j < imageHeight; ++j)
		{
			imageData[imageWidth+((imageWidth+1)*j)] =
				imageData[(imageWidth-1)+((imageWidth+1)*j)];
		}
	}

	// Compute scaled size.
	if (0 == scaledImageWidth && 0 == scaledImageHeight)
	{
		int scale = (int)(scaleFactor*65536.0);
		scaledImageWidth = ((imageWidth*scale)>>16);
		scaledImageHeight = ((imageHeight*scale)>>16);
	}

	// Allocate scaled image data.
	int* scaledImageData = (int*) malloc(sizeof(int)*scaledImageWidth*scaledImageHeight);
	// Check that allocation worked.
	if (NULL == scaledImageData)
	{
		free(imageData);
		return 0; // Error.
	}

	// Do the scaling.
	switch (scaleType)
	{
		case SCALETYPE_BILINEAR:
			bilinearScale(
				scaledImageData,
				scaledImageWidth,
				scaledImageHeight,
				scaledImageWidth,
				imageData,
				imageWidth,
				imageHeight,
				imageWidth+1);
			break;

		case SCALETYPE_NEAREST_NEIGHBOUR:
			nearestNeighbourScale(
				scaledImageData,
				scaledImageWidth,
				scaledImageHeight,
				scaledImageWidth,
				imageData,
				imageWidth,
				imageHeight,
				imageWidth+1);
			break;
	}

	// Create scaled image.
	int result = maCreateImageRaw(
		scaledImagePlaceholder,
		scaledImageData,
		EXTENT(scaledImageWidth, scaledImageHeight),
		1);

	// Delete temporary image data.
	free(imageData);
	free(scaledImageData);

	if (RES_OUT_OF_MEMORY == result)
	{
		return 0; // Error.
	}
	else
	{
		return 1; // Success.
	}
}

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
int SysImageScale(
	MAHandle sourceImage,
	MARect* sourceRect,
	MAHandle scaledImagePlaceholder,
	int scaledImageWidth,
	int scaledImageHeight,
	int scaleType)
{
	return imageScaleHelper(
		sourceImage,
		sourceRect,
		scaledImagePlaceholder,
		scaledImageWidth,
		scaledImageHeight,
		0.0,
		scaleType);
}

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
int SysImageScaleProportionally(
	MAHandle sourceImage,
	MARect* sourceRect,
	MAHandle scaledImagePlaceholder,
	double scaleFactor,
	int scaleType)
{
	return imageScaleHelper(
		sourceImage,
		sourceRect,
		scaledImagePlaceholder,
		0,
		0,
		scaleFactor,
		scaleType);
}

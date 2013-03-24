//
//  UIImage+TCSImageRepresentativeColors.m
//  vinylogue
//
//  Created by Christopher Trott on 3/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "UIImage+TCSImageRepresentativeColors.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation UIImage (TCSImageRepresentativeColors)

// Derived from http://www.markj.net/iphone-uiimage-pixel-color/

/*
 * Calculate the average color of all colors within the mid bounds of brightness
 * Loop through colors again:
 *  Average the colors that are within a certain bounds of the previous average and put that in one bin
 *  Average the colors outside those bounds and put that in another bin
 * Calculate the Y brightness of each color and also calculate a contrasting color to that.
 */
 
- (RACTuple *)getRepresentativeColors{
	UIColor *primaryColor, *secondaryColor, *averageColor, *textColor, *textShadowColor;
	CGImageRef inImage = self.CGImage;
	// Create off screen bitmap context to draw the image into. Format ARGB is 4 bytes for each pixel: Alpa, Red, Green, Blue
	CGContextRef cgctx = [[self class] createARGBBitmapContextFromImage:inImage];
	if (cgctx == NULL) { return nil; /* error */ }
  
  size_t w = CGImageGetWidth(inImage);
	size_t h = CGImageGetHeight(inImage);
	CGRect rect = {{0,0},{w,h}};
  
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextDrawImage(cgctx, rect, inImage);
  
	// Now we can get a pointer to the image data associated with the bitmap
	// context.
	unsigned char* data = CGBitmapContextGetData(cgctx);
  
  int x, y; // counters
  int offset;
  double alpha, red, green, blue, brightness;
  double tAlpha = 0, tRed = 0, tGreen = 0, tBlue = 0, tColorsInSet = 0; // total running average;
  double pAlpha = 0, pRed = 0, pGreen = 0, pBlue = 0, pColorsInSet = 0; // primary color running average;
  double sAlpha = 0, sRed = 0, sGreen = 0, sBlue = 0, sColorsInSet = 0; // secondary color running average;
	BOOL dAlpha, dRed, dGreen, dBlue; // store for difference between avg and pixel
  static double maxColorValueDifference = 0.35;
  double textGray, textShadowGray;
  
  if (data != NULL) {
    for (x = 0; x < w; x++){
      for (y = 0; y < h; y++){
        //offset locates the pixel in the data from x,y.
        //4 for 4 bytes of data per pixel, w is width of one row of data.
        offset = 4*((w*round(y))+round(x));
        alpha = data[offset] / 255.0;
        red = data[offset+1] / 255.0;
        green = data[offset+2] / 255.0;
        blue = data[offset+3] / 255.0;
        brightness = 0.299*red + 0.587*green + 0.114*blue;
        
        // exclude too bright and too dark
        if ((brightness > 0.05) && (brightness < 0.95)){
          tRed += red;
          tGreen += green;
          tBlue += blue;
          tAlpha += alpha;
          tColorsInSet++;
        }
      }
    }
    
    tRed /= MAX(tColorsInSet, 1.0);
    tGreen /= MAX(tColorsInSet, 1.0);
    tBlue /= MAX(tColorsInSet, 1.0);
    tAlpha /= MAX(tColorsInSet, 1.0);
    
    for (x = 0; x < w; x++){
      for (y = 0; y < h; y++){
        offset = 4*((w*round(y))+round(x));
        alpha = data[offset] / 255.0;
        red = data[offset+1] / 255.0;
        green = data[offset+2] / 255.0;
        blue = data[offset+3] / 255.0;
        brightness = 0.299*red + 0.587*green + 0.114*blue;
        
        // exclude too bright and too dark
        if ((brightness > 0.05) && (brightness < 0.95)){
          // does the color fall inside our bounds?
          dAlpha = fabs(tAlpha - alpha) < maxColorValueDifference;
          dRed = fabs(tRed - red) < maxColorValueDifference;
          dGreen = fabs(tGreen - green) < maxColorValueDifference;
          dBlue = fabs(tBlue - blue) < maxColorValueDifference;
          
          if (dAlpha && dRed && dGreen && dBlue){
            pRed += red;
            pGreen += green;
            pBlue += blue;
            pAlpha += alpha;
            pColorsInSet++;
          }else{
            sRed += red;
            sGreen += green;
            sBlue += blue;
            sAlpha += alpha;
            sColorsInSet++;
          }
        }
      }
    }
    
    pRed /= MAX(pColorsInSet, 1.0);
    pGreen /= MAX(pColorsInSet, 1.0);
    pBlue /= MAX(pColorsInSet, 1.0);
    pAlpha /= MAX(pColorsInSet, 1.0);
    
    sRed /= MAX(sColorsInSet, 1.0);
    sGreen /= MAX(sColorsInSet, 1.0);
    sBlue /= MAX(sColorsInSet, 1.0);
    sAlpha /= MAX(sColorsInSet, 1.0);
	}
  
	// When finished, release the context
	CGContextRelease(cgctx);
	// Free image data memory for the context
	if (data) { free(data); }
  
  primaryColor = [UIColor colorWithRed:pRed green:pGreen blue:pBlue alpha:pAlpha];
  secondaryColor = [UIColor colorWithRed:sRed green:sGreen blue:sBlue alpha:sAlpha];
  averageColor = [UIColor colorWithRed:tRed green:tGreen blue:tBlue alpha:tAlpha];
  brightness = 0.299*pRed + 0.587*pGreen + 0.114*pBlue;
  textGray = (brightness < 0.6) ? 1.0 : 0.0;
  textShadowGray = (brightness < 0.6) ? 0.0 : 1.0;
  textColor = [UIColor colorWithWhite:textGray alpha:1.0];
  textShadowColor = [UIColor colorWithWhite:textShadowGray alpha:1.0];
  
  RACTuple *t = [RACTuple tupleWithObjects:primaryColor, secondaryColor, averageColor, textColor, textShadowColor, nil];
  
	return t;
}

+ (CGContextRef)createARGBBitmapContextFromImage:(CGImageRef)inImage{
  
	CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	void *          bitmapData;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
  
	// Get image width, height. We'll use the entire image.
	size_t pixelsWide = CGImageGetWidth(inImage);
	size_t pixelsHigh = CGImageGetHeight(inImage);
  
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow   = (pixelsWide * 4);
	bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
  
	// Use the generic RGB color space.
	colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL)
	{
		fprintf(stderr, "Error allocating color space\n");
		return NULL;
	}
  
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL)
	{
		fprintf (stderr, "Memory not allocated!");
		CGColorSpaceRelease( colorSpace );
		return NULL;
	}
  
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	context = CGBitmapContextCreate (bitmapData,
                                   pixelsWide,
                                   pixelsHigh,
                                   8,      // bits per component
                                   bitmapBytesPerRow,
                                   colorSpace,
                                   kCGImageAlphaPremultipliedFirst);
	if (context == NULL)
	{
		free (bitmapData);
		fprintf (stderr, "Context not created!");
	}
  
	// Make sure and release colorspace before returning
	CGColorSpaceRelease( colorSpace );
  
	return context;
}

@end

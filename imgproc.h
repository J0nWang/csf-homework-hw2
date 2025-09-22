/*
 * .h file for transformations on image files, using C for Milestone 1.
 * CSF Assignment 2 MS1
 * Jonathan Wang
 * jwang612@jhu.edu
 */

// Header for image processing API functions (imgproc_complement, etc.)
// as well as any helper functions they rely on.

#ifndef IMGPROC_H
#define IMGPROC_H

#include "image.h" // for struct Image and related functions

//! Transform the color component values in each input pixel
//! by applying the bitwise complement operation. I.e., each bit
//! in the color component information should be inverted
//! (1 becomes 0, 0 becomes 1.) The alpha value of each pixel should
//! be left unchanged.
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_complement( struct Image *input_img, struct Image *output_img );

//! Transform the input image by swapping the row and column
//! of each source pixel when copying it to the output image.
//! E.g., a pixel at row i and column j of the input image
//! should be copied to row j and column i of the output image.
//! Note that this transformation can only be applied to square
//! images (where the width and height are identical.)
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
//!
//! @return 1 if the transformation succeeded, or 0 if the
//!         transformation can't be applied because the image
//!         width and height are not the same
int imgproc_transpose( struct Image *input_img, struct Image *output_img );

//! Transform the input image by copying only those pixels that are
//! within an ellipse centered within the bounds of the image.
//! Pixels not in the ellipse should be left unmodified, which will
//! make them opaque black.
//!
//! Let w represent the width of the image and h represent the
//! height of the image. Let a=floor(w/2) and b=floor(h/2).
//! Consider the pixel at row b and column a is being at the
//! center of the image. When considering whether a specific pixel
//! is in the ellipse, x is the horizontal distance to the center
//! of the image and y is the vertical distance to the center of
//! the image. The pixel at the coordinates described by x and y
//! is in the ellipse if the following inequality is true:
//!
//!   floor( (10000*x*x) / (a*a) ) + floor( (10000*y*y) / (b*b) ) <= 10000
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_ellipse( struct Image *input_img, struct Image *output_img );

//! Transform the input image using an "emboss" effect. The pixels
//! of the source image are transformed as follows.
//!
//! The top row and left column of pixels are transformed so that their
//! red, green, and blue color component values are all set to 128,
//! and their alpha values are not modified.
//!
//! For all other pixels, we consider the pixel's color component
//! values r, g, and b, and also the pixel's upper-left neighbor's
//! color component values nr, ng, and nb. In comparing the color
//! component values of the pixel and its upper-left neighbor,
//! we consider the differences (nr-r), (ng-g), and (nb-b).
//! Whichever of these differences has the largest absolute value
//! we refer to as diff. (Note that in the case that more than one
//! difference has the same absolute value, the red difference has
//! priority over green and blue, and the green difference has priority
//! over blue.)
//!
//! From the value diff, compute the value gray as 128 + diff.
//! However, gray should be clamped so that it is in the range
//! 0..255. I.e., if it's negative, it should become 0, and if
//! it is greater than 255, it should become 255.
//!
//! For all pixels not in the top or left row, the pixel's red, green,
//! and blue color component values should be set to gray, and the
//! alpha value should be left unmodified.
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_emboss( struct Image *input_img, struct Image *output_img );

// TODO: add prototypes for your helper functions

//! retreives the r value for a pixel
//!
//! @param pixel pixel to retreive value from
//! @return uint32_t value representing the pixel's r value
uint32_t get_r( uint32_t pixel );

//! retreives the g value for a pixel
//!
//! @param pixel pixel to retreive value from
//! @return uint32_t value representing the pixel's g value
uint32_t get_g( uint32_t pixel );

//! retreives the b value for a pixel
//!
//! @param pixel pixel to retreive value from
//! @return uint32_t value representing the pixel's b value
uint32_t get_b( uint32_t pixel );

//! retreives the alpha value for a pixel
//!
//! @param pixel pixel to retreive value from
//! @return uint32_t value representing the pixel's alpha value
uint32_t get_a( uint32_t pixel );

//! returns an uint32_t value that represents the r,g,b, and a values of a pixel
//!
//! @param r pixel's r value
//! @param g pixel's g value
//! @param b pixel's b value
//! @param a pixel's alpha value
//! @return uint32_t value representing a pixel's r,g,b, and a value
uint32_t make_pixel( uint32_t r, uint32_t g, uint32_t b, uint32_t a );

//! calculates the index number of a particular pixel in an Image's data field
//! based its row and column values
//!
//! @param img pointer to the input image 
//! @param row the row number of the image's pixel
//! @param col the column number of the image's pixel
//! @return int32_t value representing the pixel's position in the Image's data field 
int32_t compute_index( struct Image *img, int32_t row, int32_t col );

//! determines whether or not a particular pixel in an image is in an ellipse.
//!
//! @param img pointer to the input image 
//! @param row the row number of the image's pixel
//! @param col the column number of the image's pixel
//! @return int value representing whether or not the pixel was in the ellispe;
//!         1 if it is, 0 if it is not.
int is_in_ellipse( struct Image *img, int32_t row, int32_t col );

//! helper function to calculate RGB differences between two pixels. Values are
//! stored in diff_r, diff_g, and diff_b respectively.
//!
//! @param current_pixel uint32_t value representing the current pixel's RGBA values
//! @param neighbor_pixel uint32_t value representing the neighbors pixel's RGBA values
//! @param diff_r int32_t value to store the difference between R values
//! @param diff_g int32_t value to store the difference between G values
//! @param diff_b int32_t value to store the difference between B values
void calculate_rgb_diffs(uint32_t current_pixel, uint32_t neighbor_pixel, 
                        int32_t *diff_r, int32_t *diff_g, int32_t *diff_b);

//! helper function to return the absolute value of some value.
//!
//! @param value the uint32_t value to take an absolute value of
//! @return int32_t value result after taking absolute value of the input value
int32_t abs_value(int32_t value);

//! helper function to find the RGB difference with largest absolute value.
//! note that red has priority over green and blue, green has priority over blue.
//!
//! @param diff_r int32_t representing the difference between two R values
//! @param diff_g int32_t representing the difference between two G values
//! @param diff_b int32_t representing the difference between two B values
//! @return the diff's with the largest absolute value (with respect to color priorities)
int32_t get_max_diff(int32_t diff_r, int32_t diff_g, int32_t diff_b);

//! helper function to clamp the gray value to a value between 0 and 255.
//!
//! @param int32_t value representing the gray value
//! @return the clamped value (if needed)
int32_t clamp_gray_value(int32_t value);

//! helper function to apply emboss effect to interior pixels.
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
//! @param row the row number of the image's pixel
//! @param col the column number of the image's pixel
//! @param index index where a pixel is stored in the Image struct's data array
//! @param current_pixel uint32_t value representing the current pixel's RGBA values
//! @param alpha uint32_t value repesenting the current pixel's alpha value
void process_interior_pixel(struct Image *input_img, struct Image *output_img, 
                          int32_t row, int32_t col, int32_t index, uint32_t current_pixel,
                          uint32_t alpha);

#endif // IMGPROC_H

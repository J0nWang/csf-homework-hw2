/*
 * Transformations on image files, using C for Milestone 1.
 * CSF Assignment 2 MS1
 * Jonathan Wang
 * jwang612@jhu.edu
 */

// C implementations of image processing functions

#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include "imgproc.h"

// TODO: define your helper functions here

uint32_t get_r( uint32_t pixel ){
  return (pixel >> 24) & 0xFF;
}

uint32_t get_g( uint32_t pixel ){
  return (pixel >> 16) & 0xFF;
}

uint32_t get_b( uint32_t pixel ){
  return (pixel >> 8) & 0xFF;
}

uint32_t get_a( uint32_t pixel ){
  return pixel & 0xFF;
}

uint32_t make_pixel( uint32_t r, uint32_t g, uint32_t b, uint32_t a ){
  return (r << 24) | (g << 16) | (b << 8) | a;
}

int32_t compute_index( struct Image *img, int32_t row, int32_t col ){
  return row * img->width + col;
  // does this need error checking for row/col out of bounds?
}

int is_in_ellipse( struct Image *img, int32_t row, int32_t col ){
  // does this need error checking for row/col out of bounds?
  // center of the ellipse
  int32_t centerRow = img->height / 2; // b
  int32_t centerCol = img->width / 2; // a
  
  int32_t yDistFromCenter = row - centerRow; // y
  int32_t xDistFromCenter = col - centerCol; // x

  // check ellispe equation: ⌊(10,000*x^2)/a^2⌋ + ⌊(10,000*y^2)/b^2⌋ ≤ 10,000
  // where the center pixel has row b and col a, and x is horizontal distance
  // from the center pixel and y is vertical distance from center pixel
  int32_t term1 = (10000 * xDistFromCenter * xDistFromCenter) / (centerCol * centerCol);
  int32_t term2 = (10000 * yDistFromCenter * yDistFromCenter) / (centerRow * centerRow);

  return (term1 + term2) <= 10000;
}

void calculate_rgb_diffs(uint32_t current_pixel, uint32_t neighbor_pixel, 
                        int32_t *diff_r, int32_t *diff_g, int32_t *diff_b) {
  int32_t r = get_r(current_pixel);
  int32_t g = get_g(current_pixel);
  int32_t b = get_b(current_pixel);
  
  int32_t nr = get_r(neighbor_pixel);
  int32_t ng = get_g(neighbor_pixel);
  int32_t nb = get_b(neighbor_pixel);
  
  *diff_r = nr - r;
  *diff_g = ng - g;
  *diff_b = nb - b;
}

// helper function to get absolute value
int32_t abs_value(int32_t value) {
  return abs(value);
}

int32_t get_max_diff(int32_t diff_r, int32_t diff_g, int32_t diff_b) {
  int32_t abs_r = abs_value(diff_r);
  int32_t abs_g = abs_value(diff_g);
  int32_t abs_b = abs_value(diff_b);
  
  // control flow statement to handle color priorities
  if (abs_r >= abs_g && abs_r >= abs_b) {
      return diff_r;
  } else if (abs_g >= abs_b) {
      return diff_g;
  } else {
      return diff_b;
  }
}

int32_t clamp_gray_value(int32_t value){
  if (value < 0) return 0;
  if (value > 255) return 255;
  return value;
}

void process_interior_pixel(struct Image *input_img, struct Image *output_img, 
                          int32_t row, int32_t col, int32_t index, uint32_t current_pixel,
                          uint32_t alpha) {
  // get upper-left neighbor pixel
  int32_t neighbor_index = compute_index(input_img, row - 1, col - 1);
  uint32_t neighbor_pixel = input_img->data[neighbor_index];
  
  // calculate RGB differences between current and neighbor pixel
  int32_t diff_r, diff_g, diff_b;
  calculate_rgb_diffs(current_pixel, neighbor_pixel, &diff_r, &diff_g, &diff_b);
  
  // find difference with largest absolute value
  int32_t diff = get_max_diff(diff_r, diff_g, diff_b);
  
  // compute gray value with clamping (value must be between 0 and 255)
  int32_t gray = clamp_gray_value(128 + diff);
  
  // set RGB to gray, keep alpha and store pixel in output
  output_img->data[index] = make_pixel(gray, gray, gray, alpha);
}

// ---------- BEGIN IMAGE PROCESSING FUNCTIONS HERE ---------- //

//! Transform the color component values in each input pixel
//! by applying the bitwise complement operation. I.e., each bit
//! in the color component information should be inverted
//! (1 becomes 0, 0 becomes 1.) The alpha value of each pixel should
//! be left unchanged.
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_complement( struct Image *input_img, struct Image *output_img ) {
  int32_t width = input_img->width;
  int32_t height = input_img->height;

  for (int32_t row = 0; row < height; row++){
    for (int32_t col = 0; col < width; col++){
      int32_t dataIdx = compute_index(input_img, row, col);
      uint32_t pixel = input_img->data[dataIdx];
      
      // extract RGBA components
      uint32_t r = get_r(pixel);
      uint32_t g = get_g(pixel);
      uint32_t b = get_b(pixel);
      uint32_t a = get_a(pixel);
      
      // apply complement to RGB, keep A untouched
      r = ~r & 0xFF;
      g = ~g & 0xFF;
      b = ~b & 0xFF;

      // create new pixel with the complements and store it in output image
      output_img->data[dataIdx] = make_pixel(r,g,b,a);
    }
  }
}

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
int imgproc_transpose( struct Image *input_img, struct Image *output_img ) {
  int32_t width = input_img->width;
  int32_t height = input_img->height;

  // check if image is square
  if (width != height) return 0;

  for (int32_t row = 0; row < height; row++){
    for (int32_t col = 0; col < width; col++){
      // get pixel at (row, col) from input image
      int32_t input_index = compute_index(input_img, row, col);
      int32_t transposed_index = compute_index(input_img, col, row);
      
      // and store it at (col, row) in output image
      uint32_t pixel = input_img->data[input_index];
      output_img->data[transposed_index] = pixel;
    }
  }

  return 1;
}

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
void imgproc_ellipse( struct Image *input_img, struct Image *output_img ) {
  int32_t width = input_img->width;
  int32_t height = input_img->height;

  for (int32_t row = 0; row < height; row++){
    for (int32_t col = 0; col < width; col++){
      int32_t index = compute_index(input_img, row, col);
      
      if (is_in_ellipse(input_img, row, col)){
        // copy the pixel over if it's in the ellipse
        output_img->data[index] = input_img->data[index];
      }
      // otherwise, leave it as opaque black, which is the default (0x000000FF)
    }
  }
}

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
void imgproc_emboss( struct Image *input_img, struct Image *output_img ) {
  int32_t width = input_img->width;
  int32_t height = input_img->height;

  for (int32_t row = 0; row < height; row++){
    for (int32_t col = 0; col < width; col++){
      int32_t index = compute_index(input_img, row, col);
      uint32_t pixel = input_img->data[index];
      int32_t a = get_a(pixel);

      if (row == 0 || col == 0){
        // if pixel is in the top row or leftmost column, set RGB to 128, keep alpha
        output_img->data[index] = make_pixel(128,128,128,a);
      } else {
        process_interior_pixel(input_img, output_img, row, col, index, pixel, a);
      }
    }
  }
}
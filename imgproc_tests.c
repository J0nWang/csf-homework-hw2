/*
 * Unit test file for transformations on image files, using C for Milestone 1.
 * CSF Assignment 2 MS1
 * Jonathan Wang
 * jwang612@jhu.edu
 */

#include <assert.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tctest.h"
#include "imgproc.h"

// An expected color identified by a (non-zero) character code.
// Used in the "struct Picture" data type.
struct ExpectedColor {
  char c;
  uint32_t color;
};

// Type representing a "picture" of an expected image.
// Useful for creating a very simple Image to be accessed
// by test functions.
struct Picture {
  struct ExpectedColor colors[40];
  int width, height;
  const char *data;
};

// Some "basic" colors to use in test struct Pictures.
// Note that the ranges '1'-'5', 'A'-'E', and 'P'-'T'
// are (respectively) colors 'r','g','b','c', and 'm'
// with just the red, green, and blue color component values
#define TEST_COLORS \
    { \
      { ' ', 0xFFFFFFFF }, \
      { '_', 0x000000FF }, \
      { 'r', 0xFF0000FF }, \
      { 'g', 0x00FF00FF }, \
      { 'b', 0x0000FFFF }, \
      { 'c', 0x00FFFFFF }, \
      { 'm', 0xFF00FFFF }, \
      { '1', 0xFF0000FF }, \
      { '2', 0x000000FF }, \
      { '3', 0x000000FF }, \
      { '4', 0x000000FF }, \
      { '5', 0xFF0000FF }, \
      { 'A', 0x000000FF }, \
      { 'B', 0x00FF00FF }, \
      { 'C', 0x000000FF }, \
      { 'D', 0x00FF00FF }, \
      { 'E', 0x000000FF }, \
      { 'P', 0x000000FF }, \
      { 'Q', 0x000000FF }, \
      { 'R', 0x0000FFFF }, \
      { 'S', 0x0000FFFF }, \
      { 'T', 0x0000FFFF }, \
    }

// Data type for the test fixture object.
// This contains data (including Image objects) that
// can be accessed by test functions. This is useful
// because multiple test functions can access the same
// data (so you don't need to create/initialize that
// data multiple times in different test functions.)
typedef struct {
  // smiley-face picture
  struct Picture smiley_pic;

  // original smiley-face Image object
  struct Image *smiley;

  // empty Image object to use for output of
  // transformation on smiley-face image
  struct Image *smiley_out;

  // a square image (same width/height) to use as a test
  // for the transpose transformation
  struct Picture sq_test_pic;

  // original square Image object
  struct Image *sq_test;

  // empty image for output of transpose transformation
  struct Image *sq_test_out;
} TestObjs;

// Functions to create and clean up a test fixture object
TestObjs *setup( void );
void cleanup( TestObjs *objs );

// Helper functions used by the test code
struct Image *picture_to_img( const struct Picture *pic );
uint32_t lookup_color(char c, const struct ExpectedColor *colors);
bool images_equal( struct Image *a, struct Image *b );
void destroy_img( struct Image *img );

// Test functions
void test_complement_basic( TestObjs *objs );
void test_transpose_basic( TestObjs *objs );
void test_ellipse_basic( TestObjs *objs );
void test_emboss_basic( TestObjs *objs );
// TODO: add prototypes for additional test functions
// void test_get_r( TestObjs *objs );
// void test_get_g( TestObjs *objs );
// void test_get_b( TestObjs *objs );
// void test_get_a( TestObjs *objs );
// void test_make_pixel( TestObjs *objs );
// void test_compute_index( TestObjs *objs );
void test_is_in_ellipse( TestObjs *objs );
// void test_calculate_rgb_diffs( TestObjs *objs );
// void test_abs_value( TestObjs *objs );
// void test_get_max_diff( TestObjs *objs );
// void test_clamp_gray_value( TestObjs *objs );
// void test_process_interior_pixel( TestObjs *objs );

int main( int argc, char **argv ) {
  // allow the specific test to execute to be specified as the
  // first command line argument
  if ( argc > 1 )
    tctest_testname_to_execute = argv[1];

  TEST_INIT();

  // Run tests.
  // Make sure you add additional TEST() macro invocations
  // for any additional test functions you add.
  TEST( test_complement_basic );
  TEST( test_transpose_basic );
  TEST( test_ellipse_basic );
  TEST( test_emboss_basic );

  // TEST( test_get_r );
  // TEST( test_get_g );
  // TEST( test_get_b );
  // TEST( test_get_a );
  // TEST( test_make_pixel );
  // TEST( test_compute_index );
  TEST( test_is_in_ellipse );
  // TEST( test_calculate_rgb_diffs );
  // TEST( test_abs_value );
  // TEST( test_get_max_diff );
  // TEST( test_clamp_gray_value );
  // TEST( test_process_interior_pixel );

  TEST_FINI();
}

////////////////////////////////////////////////////////////////////////
// Test fixture setup/cleanup functions
////////////////////////////////////////////////////////////////////////

TestObjs *setup( void ) {
  TestObjs *objs = (TestObjs *) malloc( sizeof(TestObjs) );

  struct Picture smiley_pic = {
    TEST_COLORS,
    16, // width
    10, // height
    "    mrrrggbc    "
    "   c        b   "
    "  r   r  b   c  "
    " b            b "
    " b            r "
    " g   b    c   r "
    "  c   ggrb   b  "
    "   m        c   "
    "    gggrrbmc    "
    "                "
  };
  objs->smiley_pic = smiley_pic;
  objs->smiley = picture_to_img( &smiley_pic );

  objs->smiley_out = (struct Image *) malloc( sizeof( struct Image ) );
  img_init( objs->smiley_out, objs->smiley->width, objs->smiley->height );

  struct Picture sq_test_pic = {
    TEST_COLORS,
    12, // width
    12, // height
    "rrrrrr      "
    " ggggg      "
    "  bbbb      "
    "   mmm      "
    "    cc      "
    "     r      "
    "            "
    "            "
    "            "
    "            "
    "            "
    "            "
  };
  objs->sq_test_pic = sq_test_pic;
  objs->sq_test = picture_to_img( &sq_test_pic );
  objs->sq_test_out = (struct Image *) malloc( sizeof( struct Image ) );
  img_init( objs->sq_test_out, objs->sq_test->width, objs->sq_test->height );

  return objs;
}

void cleanup( TestObjs *objs ) {
  destroy_img( objs->smiley );
  destroy_img( objs->smiley_out );
  destroy_img( objs->sq_test );
  destroy_img( objs->sq_test_out );

  free( objs );
}

////////////////////////////////////////////////////////////////////////
// Test code helper functions
////////////////////////////////////////////////////////////////////////

struct Image *picture_to_img( const struct Picture *pic ) {
  struct Image *img;

  img = (struct Image *) malloc( sizeof(struct Image) );
  img_init( img, pic->width, pic->height );

  for ( int i = 0; i < pic->height; ++i ) {
    for ( int j = 0; j < pic->width; ++j ) {
      int index = i * img->width + j;
      uint32_t color = lookup_color( pic->data[index], pic->colors );
      img->data[index] = color;
    }
  }

  return img;
}

uint32_t lookup_color(char c, const struct ExpectedColor *colors) {
  for (int i = 0; ; i++) {
    assert(colors[i].c != 0);
    if (colors[i].c == c) {
      return colors[i].color;
    }
  }
}

// Returns true IFF both Image objects are identical
bool images_equal( struct Image *a, struct Image *b ) {
  if ( a->width != b->width || a->height != b->height )
    return false;

  for ( int i = 0; i < a->height; ++i )
    for ( int j = 0; j < a->width; ++j ) {
      int index = i*a->width + j;
      if ( a->data[index] != b->data[index] )
        return false;
    }

  return true;
}

void destroy_img( struct Image *img ) {
  if ( img != NULL )
    img_cleanup( img );
  free( img );
}

////////////////////////////////////////////////////////////////////////
// Test functions
////////////////////////////////////////////////////////////////////////

void test_complement_basic( TestObjs *objs ) {
  {
    imgproc_complement( objs->smiley, objs->smiley_out );

    int height = objs->sq_test->height;
    int width = objs->sq_test->width;

    for ( int i = 0; i < height; ++i ) {
      for ( int j = 0; j < width; ++j ) {
        int index = i*width + j;
        uint32_t pixel = objs->smiley_out->data[ index ];
        uint32_t expected_color = ~( objs->smiley->data[ index ] ) & 0xFFFFFF00;
        uint32_t expected_alpha = objs->smiley->data[ index ] & 0xFF;
        ASSERT( pixel == (expected_color | expected_alpha ) );
      }
    }
  }

  {
    imgproc_complement( objs->sq_test, objs->sq_test_out );

    int height = objs->sq_test->height;
    int width = objs->sq_test->width;

    for ( int i = 0; i < height; ++i ) {
      for ( int j = 0; j < width; ++j ) {
        int index = i*width + j;
        uint32_t pixel = objs->sq_test_out->data[ index ];
        uint32_t expected_color = ~( objs->sq_test->data[ index ] ) & 0xFFFFFF00;
        uint32_t expected_alpha = objs->sq_test->data[ index ] & 0xFF;
        ASSERT( pixel == (expected_color | expected_alpha ) );
      }
    }
  }
}

void test_transpose_basic( TestObjs *objs ) {
  struct Picture sq_test_transpose_expected_pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0xff0000ff },
      { 'b', 0xffffffff },
      { 'c', 0x00ff00ff },
      { 'd', 0x0000ffff },
      { 'e', 0xff00ffff },
      { 'f', 0x00ffffff },
    },
    12, // width
    12, // height
    "abbbbbbbbbbb"
    "acbbbbbbbbbb"
    "acdbbbbbbbbb"
    "acdebbbbbbbb"
    "acdefbbbbbbb"
    "acdefabbbbbb"
    "bbbbbbbbbbbb"
    "bbbbbbbbbbbb"
    "bbbbbbbbbbbb"
    "bbbbbbbbbbbb"
    "bbbbbbbbbbbb"
    "bbbbbbbbbbbb"
  };

  struct Image *sq_test_transpose_expected =
    picture_to_img( &sq_test_transpose_expected_pic );

  imgproc_transpose( objs->sq_test, objs->sq_test_out );

  ASSERT( images_equal( objs->sq_test_out, sq_test_transpose_expected ) );

  destroy_img( sq_test_transpose_expected );
}

void test_ellipse_basic( TestObjs *objs ) {
  struct Picture smiley_ellipse_expected_pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0x00ff00ff },
      { 'b', 0xffffffff },
      { 'c', 0x0000ffff },
      { 'd', 0xff0000ff },
      { 'e', 0x00ffffff },
      { 'f', 0xff00ffff },
    },
    16, // width
    10, // height
    "        a       "
    "    bbbbbbbbc   "
    "  dbbbdbbcbbbeb "
    " cbbbbbbbbbbbbcb"
    " cbbbbbbbbbbbbdb"
    "babbbcbbbbebbbdb"
    " bebbbaadcbbbcbb"
    " bbfbbbbbbbbebbb"
    "  bbaaaddcfebbb "
    "    bbbbbbbbb   "
  };

  struct Image *smiley_ellipse_expected =
    picture_to_img( &smiley_ellipse_expected_pic );

  imgproc_ellipse( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( objs->smiley_out, smiley_ellipse_expected ) );

  destroy_img( smiley_ellipse_expected );
}

void test_emboss_basic( TestObjs *objs ) {
  struct Picture smiley_emboss_expected_pic = {
    {
      { ' ', 0x000000ff },
      { 'a', 0x808080ff },
      { 'b', 0xffffffff },
    },
    16, // width
    10, // height
    "aaaaaaaaaaaaaaaa"
    "aaaba       baaa"
    "aaba abaabaaa aa"
    "aba aaa aa aaaba"
    "ab aaaaaaaaaaab "
    "ab aabaaaabaaab "
    "aa aaa bbba aba "
    "aaa aaa    aba a"
    "aaaabbbbbbbba aa"
    "aaaaa        aaa"
  };

  struct Image *smiley_emboss_expected =
    picture_to_img( &smiley_emboss_expected_pic );

  imgproc_emboss( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( objs->smiley_out, smiley_emboss_expected ) );

  destroy_img( smiley_emboss_expected );
}

// Unit tests for helper functions
// void test_get_r( TestObjs *objs ) {
//     uint32_t pixel1 = 0xFF123456; // R=0xFF, G=0x12, B=0x34, A=0x56
//     ASSERT( get_r(pixel1) == 0xFF );
    
//     uint32_t pixel2 = 0x00FFFFFF; // R=0x00, others have max value
//     ASSERT( get_r(pixel2) == 0x00 );
    
//     uint32_t pixel3 = 0xAB000000; // R=0xAB, others are zero
//     ASSERT( get_r(pixel3) == 0xAB );
    
//     uint32_t smiley_pixel = objs->smiley->data[0];
//     uint32_t expected_r = (smiley_pixel >> 24) & 0xFF;
//     ASSERT( get_r(smiley_pixel) == expected_r );
// }

// void test_get_g( TestObjs *objs ) {
//     uint32_t pixel1 = 0xFF123456; // R=0xFF, G=0x12, B=0x34, A=0x56
//     ASSERT( get_g(pixel1) == 0x12 );
    
//     uint32_t pixel2 = 0x00FF0000; // G=0xFF, others zero
//     ASSERT( get_g(pixel2) == 0xFF );
    
//     uint32_t pixel3 = 0x0000FFFF; // G=0x00, B and A are max
//     ASSERT( get_g(pixel3) == 0x00 );
    
//     uint32_t smiley_pixel = objs->smiley->data[5];
//     uint32_t expected_g = (smiley_pixel >> 16) & 0xFF;
//     ASSERT( get_g(smiley_pixel) == expected_g );
// }

// void test_get_b( TestObjs *objs ) {
//     uint32_t pixel1 = 0xFF123456; // R=0xFF, G=0x12, B=0x34, A=0x56
//     ASSERT( get_b(pixel1) == 0x34 );
    
//     uint32_t pixel2 = 0x0000FF00; // B=0xFF, others zero
//     ASSERT( get_b(pixel2) == 0xFF );
    
//     uint32_t pixel3 = 0xFFFF00FF; // B=0x00, others have max value
//     ASSERT( get_b(pixel3) == 0x00 );
    
//     uint32_t smiley_pixel = objs->smiley->data[10];
//     uint32_t expected_b = (smiley_pixel >> 8) & 0xFF;
//     ASSERT( get_b(smiley_pixel) == expected_b );
// }

// void test_get_a( TestObjs *objs ) {
//     uint32_t pixel1 = 0xFF123456; // R=0xFF, G=0x12, B=0x34, A=0x56
//     ASSERT( get_a(pixel1) == 0x56 );
    
//     uint32_t pixel2 = 0x000000FF; // A=0xFF, others zero
//     ASSERT( get_a(pixel2) == 0xFF );
    
//     uint32_t pixel3 = 0xFFFFFF00; // A=0x00, others max
//     ASSERT( get_a(pixel3) == 0x00 );
    
//     uint32_t smiley_pixel = objs->smiley->data[15];
//     uint32_t expected_a = smiley_pixel & 0xFF;
//     ASSERT( get_a(smiley_pixel) == expected_a );
// }

// void test_make_pixel( TestObjs *objs ) {
//     uint32_t pixel1 = make_pixel(0xFF, 0x12, 0x34, 0x56);
//     ASSERT( pixel1 == 0xFF123456 );
    
//     uint32_t pixel2 = make_pixel(0x00, 0x00, 0x00, 0xFF);
//     ASSERT( pixel2 == 0x000000FF );
    
//     uint32_t pixel3 = make_pixel(0xFF, 0xFF, 0xFF, 0x00);
//     ASSERT( pixel3 == 0xFFFFFF00 );
    
//     uint32_t r = 0xAB, g = 0xCD, b = 0xEF, a = 0x12;
//     uint32_t pixel4 = make_pixel(r, g, b, a);
//     ASSERT( get_r(pixel4) == r );
//     ASSERT( get_g(pixel4) == g );
//     ASSERT( get_b(pixel4) == b );
//     ASSERT( get_a(pixel4) == a );
// }

// void test_compute_index( TestObjs *objs ) {
//     struct Image *img = objs->smiley; // 16x10 image
    
//     // testing corner cases
//     ASSERT( compute_index(img, 0, 0) == 0 );  // top left corner
//     ASSERT( compute_index(img, 0, 15) == 15 ); // top right corner
//     ASSERT( compute_index(img, 9, 0) == 144 ); // bottom left corner
//     ASSERT( compute_index(img, 9, 15) == 159 ); // bottom right corner
    
//     // testing interior positions
//     ASSERT( compute_index(img, 1, 1) == 17 ); 
//     ASSERT( compute_index(img, 5, 8) == 88 );
    
//     // test with a square image
//     struct Image *sq = objs->sq_test; // 12x12 image
//     ASSERT( compute_index(sq, 0, 0) == 0 );
//     ASSERT( compute_index(sq, 11, 11) == 143 );
//     ASSERT( compute_index(sq, 6, 6) == 78 );
// }

void test_is_in_ellipse( TestObjs *objs ) {
    struct Image *img = objs->smiley; // 16x10 image
    
    // center should be at (5, 8)
    // center point should be in ellipse
    ASSERT( is_in_ellipse(img, 5, 8) == 1 );
    
    // points close to center should also be in ellipse
    ASSERT( is_in_ellipse(img, 5, 7) == 1 );
    ASSERT( is_in_ellipse(img, 5, 1) == 1 );
    ASSERT( is_in_ellipse(img, 4, 8) == 1 );
    ASSERT( is_in_ellipse(img, 1, 8) == 1 );
    
    // corner points should be outside ellipse
    ASSERT( is_in_ellipse(img, 0, 0) == 0 );
    ASSERT( is_in_ellipse(img, 0, 15) == 0 );
    ASSERT( is_in_ellipse(img, 9, 0) == 0 );
    ASSERT( is_in_ellipse(img, 9, 15) == 0 );
    
    struct Image *sq = objs->sq_test; // 12x12 image, center should be at (6, 6)
    ASSERT( is_in_ellipse(sq, 6, 6) == 1 );
    ASSERT( is_in_ellipse(sq, 0, 0) == 0 );
    ASSERT( is_in_ellipse(sq, 11, 11) == 0 );
}

// void test_calculate_rgb_diffs( TestObjs *objs ) {
//     uint32_t current = make_pixel(100, 150, 200, 255); 
//     uint32_t neighbor = make_pixel(120, 130, 180, 255);
    
//     int32_t diff_r, diff_g, diff_b;
//     calculate_rgb_diffs(current, neighbor, &diff_r, &diff_g, &diff_b);
    
//     ASSERT( diff_r == 20 );  // 120 - 100 = 20
//     ASSERT( diff_g == -20 ); // 130 - 150 = -20
//     ASSERT( diff_b == -20 ); // 180 - 200 = -20
    
//     calculate_rgb_diffs(current, current, &diff_r, &diff_g, &diff_b);
//     ASSERT( diff_r == 0 );
//     ASSERT( diff_g == 0 );
//     ASSERT( diff_b == 0 );
    
//     uint32_t black = make_pixel(0, 0, 0, 255);
//     uint32_t white = make_pixel(255, 255, 255, 255);
//     calculate_rgb_diffs(black, white, &diff_r, &diff_g, &diff_b);
//     ASSERT( diff_r == 255 );
//     ASSERT( diff_g == 255 );
//     ASSERT( diff_b == 255 );
// }

// void test_abs_value( TestObjs *objs ) {
//     ASSERT( abs_value(10) == 10 );
//     ASSERT( abs_value(255) == 255 );
//     ASSERT( abs_value(1) == 1 );
    
//     ASSERT( abs_value(-10) == 10 );
//     ASSERT( abs_value(-255) == 255 );
//     ASSERT( abs_value(-1) == 1 );
    
//     ASSERT( abs_value(0) == 0 );
    
//     ASSERT( abs_value(-128) == 128 );
//     ASSERT( abs_value(127) == 127 );
// }

// void test_get_max_diff( TestObjs *objs ) {
//     // test red priority (red >= green >= blue)
//     ASSERT( get_max_diff(10, 10, 10) == 10 );
//     ASSERT( get_max_diff(10, 10, 5) == 10 );
//     ASSERT( get_max_diff(15, 10, 5) == 15 );
    
//     // test green priority over blue
//     ASSERT( get_max_diff(5, 10, 10) == 10 ); 
//     ASSERT( get_max_diff(5, 15, 10) == 15 );
    
//     // test blue selection
//     ASSERT( get_max_diff(5, 8, 20) == 20 );
    
//     ASSERT( get_max_diff(-15, 10, 5) == -15 ); // |-15| = 15
//     ASSERT( get_max_diff(5, -20, 10) == -20 ); // |-20| = 20
//     ASSERT( get_max_diff(5, 8, -25) == -25 );  // |-25| = 25
    
//     // mix positive/negative with color priorities
//     ASSERT( get_max_diff(-10, -10, 5) == -10 );
//     ASSERT( get_max_diff(8, -10, -10) == -10 );
// }

// void test_clamp_gray_value( TestObjs *objs ) {
//     ASSERT( clamp_gray_value(0) == 0 );
//     ASSERT( clamp_gray_value(128) == 128 );
//     ASSERT( clamp_gray_value(255) == 255 );
//     ASSERT( clamp_gray_value(100) == 100 );
    
//     ASSERT( clamp_gray_value(-1) == 0 );
//     ASSERT( clamp_gray_value(-100) == 0 );
//     ASSERT( clamp_gray_value(-255) == 0 );
    
//     ASSERT( clamp_gray_value(256) == 255 );
//     ASSERT( clamp_gray_value(300) == 255 );
//     ASSERT( clamp_gray_value(1000) == 255 );
    
//     // mimic typical emboss calculations (128 + diff)
//     ASSERT( clamp_gray_value(128 + 127) == 255 );
//     ASSERT( clamp_gray_value(128 - 128) == 0 ); 
//     ASSERT( clamp_gray_value(128 + 0) == 128 );
// }

// void test_process_interior_pixel( TestObjs *objs ) {
//     int32_t test_row = 2, test_col = 3;  // some random interior pixel in smiley image
//     int32_t index = compute_index(objs->smiley, test_row, test_col);
//     int32_t neighbor_index = compute_index(objs->smiley, test_row - 1, test_col - 1);
    
//     uint32_t current_pixel = objs->smiley->data[index];
//     uint32_t neighbor_pixel = objs->smiley->data[neighbor_index];
//     uint32_t alpha = get_a(current_pixel);
    
//     img_init(objs->smiley_out, objs->smiley->width, objs->smiley->height);

//     process_interior_pixel(objs->smiley, objs->smiley_out, test_row, test_col, index, current_pixel, alpha);
//     uint32_t result = objs->smiley_out->data[index]; // our embossed pixel
    
//     // now to double check, need to manually calculate what we expect
//     int32_t diff_r, diff_g, diff_b;
//     calculate_rgb_diffs(current_pixel, neighbor_pixel, &diff_r, &diff_g, &diff_b);
//     int32_t expected_diff = get_max_diff(diff_r, diff_g, diff_b);
//     int32_t expected_gray = clamp_gray_value(128 + expected_diff);
    
//     ASSERT( get_r(result) == expected_gray );
//     ASSERT( get_g(result) == expected_gray );
//     ASSERT( get_b(result) == expected_gray );
//     ASSERT( get_a(result) == alpha );
    
//     // testing another interior pixel
//     test_row = 3; test_col = 5; // white pixel
//     index = compute_index(objs->smiley, test_row, test_col);
//     current_pixel = objs->smiley->data[index];
//     alpha = get_a(current_pixel);
    
//     process_interior_pixel(objs->smiley, objs->smiley_out, test_row, test_col, index, current_pixel, alpha);
//     result = objs->smiley_out->data[index];
    
//     // result should be grayscale since it's upper left neighbor is also white (gray = 128 + 0 = 128)
//     ASSERT( get_a(result) == alpha );
//     ASSERT( get_r(result) == get_g(result) ); // r = g = b
//     ASSERT( get_g(result) == get_b(result) );  
// }
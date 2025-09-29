/*
 * x86-64 assembly language implementations of functions
 * CSF Assignment 2 MS2
 * Jonathan Wang
 * jwang612@jhu.edu
 */

	.section .text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/*
 * TODO: define your helper functions here.
 * Don't forget to use the .globl directive to make
 * them visible to the test code.
 */

/*
 * Retreives the r value for a pixel 
 * 
 * Parameter: 
 * 	%edi - pixel to retreive value from
 * 
 * @return	%eax - uint32_t value representing the pixel's r value 
 */
 .globl get_r
 get_r:
	movl %edi, %eax 	/* we copy the pixel value to eax%	*/
	shrl $24, %eax 		/* then shift eax% right by 24 bits to get red in bits 0-7 */
	ret								/* lastly, return with the result in eax% */

/*
 * Retreives the g value for a pixel 
 * 
 * Parameter: 
 * 	%edi - pixel to retreive value from
 *  
 * @return	%eax - uint32_t value representing the pixel's g value 
 */
 .globl get_g
 get_g:
	movl %edi, %eax 	/* we copy the pixel value to eax%	*/
	shrl $16, %eax 		/* shift eax% right by 16 bits */
	andl $0xFF, %eax 	/* use logical and on eax% to only keep the lowest 8 bits (green component) */
	ret								/* lastly, return with the result in eax% */

/*
 * Retreives the b value for a pixel 
 * 
 * Parameter: 
 * 	%edi - pixel to retreive value from
 * 
 * @return	%eax - uint32_t value representing the pixel's b value 
 */
 .globl get_b
 get_b:
	movl %edi, %eax 	/* we copy the pixel value to eax%	*/
	shrl $8, %eax 		/* shift eax% right by 8 bits */
	andl $0xFF, %eax 	/* use logical and on eax% to only keep the lowest 8 bits (blue component) */
	ret								/* lastly, return with the result in eax% */

/*
 * Retreives the a value for a pixel 
 * 
 * Parameter: 
 * 	%edi - pixel to retreive value from
 * 
 * @return	%eax - uint32_t value representing the pixel's a value 
 */
 .globl get_a
 get_a:
	movl %edi, %eax 	/* we copy the pixel value to eax%	*/
	andl $0xFF, %eax 	/* use logical and on eax% to only keep the lowest 8 bits (alpha component) */
	ret								/* lastly, return with the result in eax% */

/*
 * Returns an uint32_t value that represents the r,g,b, and a values of a pixel
 *
 * Parameters:
 *	%edi - pixel's r value
 * 	%esi - pixel's g value
 *  %edx - pixel's b value
 *	%ecx - pixel's alpha value
 * 
 * @return uint32_t value representing a pixel's r,g,b, and a value
*/
.global make_pixel
make_pixel:
	movl %edi, %eax		/* copy the red component to eax%	*/
	shll $8, %eax			/* shift eax% left by 8 bits to make room for green component	*/
	orl %esi, %eax		/* use logical or to fill in the green component	*/
	shll $8, %eax			/* shift eax% left by 8 bits to make room for blue component	*/
	orl %edx, %eax		/* use logical or to fill in the blue component	*/
	shll $8, %eax			/* shift eax% left by 8 bits to make room for alpha component	*/
	orl %ecx, %eax		/* use logical or to fill in the alpha component	*/
	ret								/* pixel should now be complete, return eax% */

/*
 * Calculates the index number of a particular pixel in an Image's data field
 * based its row and column values
 *
 * Parameters:
 * 	%rdi - pointer to the input image 
 * 	%esi - the row number of the image's pixel
 * 	%edx - the column number of the image's pixel
 * 
 * @return int32_t value representing the pixel's position in the Image's data field 
*/
.globl compute_index
compute_index:
	movl IMAGE_WIDTH_OFFSET(%rdi), %eax		/* load input image width into %eax */
	imull %esi, %eax											/* multiply width by row number */
	addl %edx, %eax												/* add column number to get final index */
	ret																		/* return with result in %eax */

/*
 * Definitions of image transformation functions
 */

/*
 *  Transform the color component values in each input pixel
 *  by applying the bitwise complement operation. I.e., each bit
 *  in the color component information should be inverted
 *  (1 becomes 0, 0 becomes 1.) The alpha value of each pixel should
 *  be left unchanged.
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *         transformed pixels should be stored)
 * 	Register use:
 *   %r12d - image width
 *   %r13d - total number of pixels (width * height)
 *   %r14  - pointer to the current input pixel
 *   %rbx  - pointer to the current output pixel
 *   %eax  - holds the pixel being processed
 *   %edx  - holds a copy of the original pixel for alpha mask
 */
	.globl imgproc_complement
imgproc_complement:
	/* prologue to create ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp

	/* pushing callee-saved registers */
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14

	movl IMAGE_WIDTH_OFFSET(%rdi), %r12d			/* load input image width into %r12d */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r13d			/* load input image height into %r13d */
	movq IMAGE_DATA_OFFSET(%rdi), %r14				/* set %r14 to address of input image data */
	movq IMAGE_DATA_OFFSET(%rsi), %rbx				/* set %rbx to address of output image data */

	imull %r12d, %r13d 												/* %r13d = width * height = total pixels */
	movl $0, %ecx															/* let %ecx be our counter variable, initialized to 0 */

	.Lcomplement_loop:
		cmpl %r13d, %ecx													/* are we done processing all pixels (counter >= total pixels)? */
		jge .Lcomplement_done										/* if yes, exit loop */

		movl (%r14), %eax												/* retrieve the current pixel from input data array */
		movl %eax, %edx													/* make a copy of the pixel and store in %edx for scratchwork */
		notl %eax																/* complement all bits of the pixel */
		andl $0xFFFFFF00, %eax									/* but only keep the RGB components (bits 8-31) */
		andl $0x000000FF, %edx									/* for %edx's copy, only keep the alpha component */
		orl %edx, %eax													/* merge the two copies using logical or to get the final pixel */
		movl %eax, (%rbx)												/* store resulting pixel in output data array */

		addq $4, %r14														/* advance to the next pixel in the input data */
		addq $4, %rbx														/* advance to the next pixel in the output data */
		incl %ecx																/* increment counter */
		jmp .Lcomplement_loop										/* continue the loop */

	.Lcomplement_done:
		/* restore callee-saved registers in reverse order of saving */
		popq %r14
		popq %r13
		popq %r12
		popq %rbx

		/* epilogue to restore ABI-compliant stack frame */
		popq %rbp
		
		ret

/*
 *  Transform the input image by swapping the row and column
 *  of each source pixel when copying it to the output image.
 *  E.g., a pixel at row i and column j of the input image
 *  should be copied to row j and column i of the output image.
 *  Note that this transformation can only be applied to square
 *  images (where the width and height are identical.)
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 * 
 *  @return 1 if the transformation succeeded, or 0 if the
 *          transformation can't be applied because the image
 *          width and height are not the same

 * Register use:
 *   %r12d - image width and height (since it must be square)
 *   %r13d - outer loop counter (row index)
 *   %r14d - inner loop counter (column index)
 *   %r15  - pointer to input image data array
 *   %rbx  - pointer to output image data array
 *   %rax  - used for calculating memory offsets
 *   %edx  - temporary storage place for the pixel being transposed
 */
	.globl imgproc_transpose
imgproc_transpose:
	/* prologue to create ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp

	/* pushing callee-saved registers */
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	subq $8, %rsp          /* with 6 pushq's (an even number), the stack is currently unaligned, so this realigns it */

	movl IMAGE_WIDTH_OFFSET(%rdi), %r12d			/* load input image width into %r12d */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %eax			/* load input image height into %eax for scratchwork */
	cmpl %r12d, %eax 													/* is width = height? */
	jne .Ltranspose_fail											/* if not, the image is not square and fails */

	movq IMAGE_DATA_OFFSET(%rdi), %r15				/* set %r14 to address of input image data */
	movq IMAGE_DATA_OFFSET(%rsi), %rbx				/* set %rbx to address of output image data */
	movl $0, %r13d														/* let %r13d be our row counter, initialized to 0 */

	.Ltranspose_row_loop:
		cmpl %r12d, %r13d 											/* have we processed all rows (row counter >= height)? */
		jge .Ltranspose_success									/* if so, we are done */
		movl $0, %r14d													/* otherwise, reset column counter to 0 and enter the column loop */

	.Ltranspose_col_loop:
		cmpl %r12d, %r14d												/* have we processed all columns (col counter >= width)? */
		jge .Ltranspose_next_row 								/* if so, then move onto next row */

		/* calculate index of pixel in input data array, using the formula index=row*width+col */
		movl %r13d, %eax												/* %eax = row number */
		imull %r12d, %eax												/* %eax = row*width */
		addl %r14d, %eax												/* %eax = row*width+col */

		/* use the calculated index to retreive the pixel from the input array */
		movl (%r15, %rax, 4), %edx							/* note, need to use %rax here to match with %r15, a 64 bit register */

		/* calculate corresponding tranposed index of the output array, using index=col*width*+row */
		movl %r14d, %eax												/* %eax = col number */						
		imull %r12d, %eax												/* %eax = col*width */
		addl %r13d, %eax												/* %eax = col*width+row */

		movl %edx, (%rbx, %rax, 4)							/* store the pixel at the transposed index */

		incl %r14d															/* increment column counter */
		jmp .Ltranspose_col_loop								/* continue the column loop */

	.Ltranspose_next_row:
		incl %r13d															/* increment row counter */
		jmp .Ltranspose_row_loop								/* countinue row loop */

	.Ltranspose_success:
		movl $1, %eax														/* set the return value to 1 (success) */
		jmp .Ltranspose_done										/* and jump to the cleanup sequence */

	.Ltranspose_fail:
		movl $0, %eax														/* set the return value to 0 (failure) */

	.Ltranspose_done:
		addq $8, %rsp														/* deallocate the 8 bytes used for stack alignment */

		/* restore callee-saved registers in reverse order of saving */
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		popq %rbx

		/* epilogue to restore ABI-compliant stack frame */
		popq %rbp

		ret																			/* return success/failure value stored in %eax */

/*
 *  Transform the input image by copying only those pixels that are
 *  within an ellipse centered within the bounds of the image.
 *  Pixels not in the ellipse should be left unmodified, which will
 *  make them opaque black.
 * 
 *  Let w represent the width of the image and h represent the
 *  height of the image. Let a=floor(w/2) and b=floor(h/2).
 *  Consider the pixel at row b and column a is being at the
 *  center of the image. When considering whether a specific pixel
 *  is in the ellipse, x is the horizontal distance to the center
 *  of the image and y is the vertical distance to the center of
 *  the image. The pixel at the coordinates described by x and y
 *  is in the ellipse if the following inequality is true:
 * 
 *    floor( (10000*x*x) / (a*a) ) + floor( (10000*y*y) / (b*b) ) <= 10000
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 */
	.globl imgproc_ellipse
imgproc_ellipse:
	/* TODO: implement */
	ret

/*
 *  Transform the input image using an "emboss" effect. The pixels
 *  of the source image are transformed as follows.
 * 
 *  The top row and left column of pixels are transformed so that their
 *  red, green, and blue color component values are all set to 128,
 *  and their alpha values are not modified.
 * 
 *  For all other pixels, we consider the pixel's color component
 *  values r, g, and b, and also the pixel's upper-left neighbor's
 *  color component values nr, ng, and nb. In comparing the color
 *  component values of the pixel and its upper-left neighbor,
 *  we consider the differences (nr-r), (ng-g), and (nb-b).
 *  Whichever of these differences has the largest absolute value
 *  we refer to as diff. (Note that in the case that more than one
 *  difference has the same absolute value, the red difference has
 *  priority over green and blue, and the green difference has priority
 *  over blue.)
 * 
 *  From the value diff, compute the value gray as 128 + diff.
 *  However, gray should be clamped so that it is in the range
 *  0..255. I.e., if it's negative, it should become 0, and if
 *  it is greater than 255, it should become 255.
 * 
 *  For all pixels not in the top or left row, the pixel's red, green,
 *  and blue color component values should be set to gray, and the
 *  alpha value should be left unmodified.
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 */
	.globl imgproc_emboss
imgproc_emboss:
	/* TODO: implement */
	ret

/*
vim:ft=gas:
*/

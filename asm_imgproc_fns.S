/*
 * x86-64 assembly language implementations of functions
 * CSF Assignment 2 MS3
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
 * Calculates the index number of a particular pixel in an Image's data field
 * based its row and column values
 *
 * Parameters:
 * 	%rdi - pointer to the input image 
 * 	%esi - the row number of the image's pixel
 * 	%edx - the column number of the image's pixel
 * 
 * @return int value representing whether or not the pixel was in the ellispe
 * 				 1 if it is, 0 if it is not.
 *
 * Register use:
 *	%r8d - image width/2 = equivalent to centerRow in C code. This is our b
 *	%r9d - image height/2 = equivalent to centerCol in C code. This is our a
 *	%esi - row-centerRow = equivalent to yDistFromCenter. This is our y
 *	%edx - col-centerCol = equivalent to xDistFromCenter. This is our x
 *	%r10 - used to calculate first term, and eventually holds the left hand sum
 *	%r11 - used to calculate the second term
 *	%r12 - used to calculate the intermediary value x*x
 *	%rax - first used to calculate intermediary value y*y, then used to return success/failure
 *	%rbx - used to calculate limit term
*/
.globl is_in_ellipse
is_in_ellipse:
	/* Push callee saved variables */
	pushq %rbx
	pushq %r12
	subq $8, %rsp        		/* realigns stack */

	movl IMAGE_WIDTH_OFFSET(%rdi), %r8d /* make copy of image width and store in %r8d scratch variable */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r9d /* make copy of image height and store in %r9d scratch variable */
	
	shrl $1, %r8d /* width/2 to get center column = a */
	shrl $1, %r9d /* height/2 to get center row = b */

	subl %r8d, %edx /* x distance from center = current column - center column = x */
	subl %r9d, %esi /* y distance from center = current row - center row = y */

	/* Originially we were using the formula ⌊(10,000*x^2)/a^2⌋ + ⌊(10,000*y^2)/b^2⌋ ≤ 10,000.
		This is fine, but can be optimized as division operations are very slow in assembly.
		We can instead rearrange the formula as:
			10,000*x^2*b^2 + 10,000*y^2*a^2 <= 10,000*a^2+b^2 (multiply both sides by a^2*b^2)
		= x^2*b^2 + y^2*a^2 <= a^2*b^2	(divide both sides by 10,000)
		= x*x*b*b + y*y*a*a <= a*a*b*b
		Now we can use only add and mult operations, which is much faster than div
	*/
	/* convert 32 bit integers to 64 bit signed integers to prepare for multiplication (in case overflow happens) */
	movslq %r8d, %r10	/* r10 = a */
	movslq %r9d, %r11 /* r11 = b */
	movslq %edx, %r12 /* r12 = x */
	movslq %esi, %rax /* rax = y */

	imulq %r10, %r10	/* r10 = a*a */
	imulq %r11, %r11	/* r11 = b*b */
	imulq %r12, %r12	/* r12 = x*x */
	imulq %rax, %rax	/* rax = y*y */

	movq %r10, %rbx		/* move a*a to rbx */
	imulq %r11, %rbx	/* rbx = a*a*b*b (the limit term) */

	imulq %rax, %r10	/* r10 = a*a*y*y */
	imulq %r12, %r11	/* r11 = b*b*x*x */

	addq %r11, %r10 	/* r10 = a*a*y*y + b*b*x*x */

	cmpq %rbx, %r10 	/* compare sum with limit */
	jg .Lnot_in_ellipse /* jump if sum > limit */

	movl $1, %eax 		/* if didn't jump, then inequality must've been satisfied, return 1 */
	jmp .Ldone_ellispe	/* jump to cleanup */

	.Lnot_in_ellipse:
		movl $0, %eax		/* return 0 (not in ellispe) */

	.Ldone_ellispe:
		addq $8, %rsp        		/* reverse the 8 bits allocated to align stack */
		/* restore callee-saved registers in reverse order of saving */
		popq %r12
		popq %rbx

		ret

/*
 * Finds the RGB difference with largest absolute value.
 * Note that red has priority over green and blue, green has priority over blue.
 *
 * Parameters:
 * 	%rdi - int32_t representing the difference between two R values
 * 	%rsi - int32_t representing the difference between two G values
 * 	%rdx - int32_t representing the difference between two B values
 * 
 * @return the diff's with the largest absolute value (with respect to color priorities)
 *
 * 	Register use:
 *   %r12d - holds diff_r (taken from the first parameter)
 *   %r13d - holds diff_g (taken from the second parameter)
 *   %r14  - holds diff_b (taken from the third parameter)
 *   %rbx  - holds the absolute value of diff_r, used for comparisons
*/
.globl get_max_diff
get_max_diff:
	/* prologue to create ABI-compliant stack frame */	
	pushq %rbp
	movq %rsp, %rbp

	/* Push callee saved variables */
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %rbx

	movl %edi, %r12d	// save diff_r in r12d
	movl %esi, %r13d	// save diff_g in r13d
	movl %edx, %r14d	// save diff_b in r14d

	call abs_value		// get abs_value(diff_r)
	movl %eax, %ebx		// save the result in %ebx

	movl %r13d, %edi	// move diff_g into parameter
	call abs_value		// get abs_value(diff_g)
	movl %eax, %r8d		// save the result in %r8d

	movl %r14d, %edi	// move diff_b into parameter
	call abs_value		// get abs_value(diff_b)
	movl %eax, %r9d		// save the result in %r9d

	/* compare abs value of differences based on color priority  */
	cmpl %r8d, %ebx				// compare abs_r and abs_g
	jl .Lcheck_green_blue // if abs_r < abs_g, check green vs blue next */
	cmpl %r9d, %ebx				// compare abs_r and abs_b
	jl .Lreturn_blue			// if abs_b > abs_r, then just return blue
	movl %r12d, %eax			// at this point, abs_r is >= abs_g and abs_b so return diff_r */
	jmp .Ldone_get_max_diff	// jump to cleanup

	.Lcheck_green_blue:
		cmpl %r9d, %r8d		// compare abs_g and abs_b 
		jl .Lreturn_blue	// if abs_b > abs_g, then just return blue
		movl %r13d, %eax	// otherwise, return diff_b
		jmp .Ldone_get_max_diff	// jump to cleanup

	.Lreturn_blue:
		movl %r14d, %eax	// return diff_b

	.Ldone_get_max_diff:
		/* restore callee-saved registers in reverse order of saving */
		popq %rbx
		popq %r14
		popq %r13
		popq %r12

		/* epilogue to restore ABI-compliant stack frame */
		popq %rbp
		ret

/*
 * Returns the absolute value of some value.
 *
 * Parameters:
 * 	%rdi - the uint32_t value to take an absolute value of
 * 
 * @return int32_t value result after taking absolute value of the input value
*/
.globl abs_value
abs_value:
	/*
	first version using conditional jump: 
	movl %edi, %eax					// store input value into eax 
	cmpl $0, %eax						// is the value negative?
	.jge .Ldone_abs_value		// if not, you're done 
	negl %eax								// if it is, negate it

	.Ldone_abs_value:
		ret										// return the final value
	*/
	/* interesting way without using jump */
	movl %edi, %eax					// store input value into eax
	movl %edi, %edx					// make another copy into edx
	sarl $31, %edx					// in edx's copy, LOGICAL shift right (sign extend) to get a mask
	xorl %edx, %eax					// then xor, which flips all same value bits
	subl %edx, %eax					// lastly, add the mask to get final value
	ret		// return result
	
/*
 * Clamps the gray value to a value between 0 and 255.
 *
 * Parameters:
 * 	%rdi - int32_t value representing the gray value
 * 
 * @return the clamped value (if needed)
*/
.globl clamp_gray_value
clamp_gray_value:
	movl %edi, %eax 	// copy value to eax
	testl %eax, %eax 	// want to see if value is negative
	jns .Lcheck_max 	// if the value is positive, check if it's > 255
	movl $0, %eax 		// if value is negative, clamp value to 0
	ret								// return result
	.Lcheck_max:
		cmpl $255, %eax // check if value is > 255
		jle .Lclamp_done // if it is, then no clamping is needed
		movl $255, %eax // otherwise, clamp value to 255
	.Lclamp_done:
		ret							// return result
	
/*
 * Calculates RGB differences between two pixels. Values are
 * stored in diff_r, diff_g, and diff_b respectively.
 * Parameters: 
 *	%edi - current pixel
 *	%esi - neighbor pixel
 * 	%rdx - ptr to diff_r
 *	%rcx - ptr to diff_g
 *	%r8 - ptr to diff_b
 *
 * Register usage:
 *	%r8d	- pixel index
 *	%r9d -  used to temporarily store current pixel's red, green, 
 *					and blue components for calculations
 *  %r12d - stores current pixel
 *  %r13d - stores neighbor pixel
 */
	.globl calculate_rgb_diffs
calculate_rgb_diffs:
	/* pushing callee-saved registers */
	pushq %rbx
	pushq %r12
	pushq %r13
	
	movl %edi, %r12d        // save current pixel into r12d
	movl %esi, %r13d        // save neighbor pixel into r13d
	movq %rdx, %rbx         // save diff_r pointer into rbx
	
	// get current pixel's red component
	movl %r12d, %edi        // set current pixel as arg 1
	call get_r              // get red component
	movl %eax, %r9d         // save red component into r9d
	
	// get neighbor pixel's red component
	movl %r13d, %edi        // set neighbor pixel as arg 1
	call get_r              // get red component
	subl %r9d, %eax         // calculate diff_r = neighbor_r - current_r
	movl %eax, (%rbx)       // store result into memory address of diff_r
	
	// get current pixel's green component
	movl %r12d, %edi        // set current pixel as arg 1
	call get_g              // get green component
	movl %eax, %r9d         // save current green into r9d
	
	// get neighbor pixel green
	movl %r13d, %edi        // set neighbor pixel as arg 1
	call get_g              // get green component
	subl %r9d, %eax         // calculate diff_g = neighbor_g - current_g
	movl %eax, (%rcx)       // store result into memory address of diff_g
	
	// get current pixel blue
	movl %r12d, %edi        // set current pixel as arg 1
	call get_b              // get blue component
	movl %eax, %r9d         // save current blue into r9d
	
	// get neighbor pixel blue
	movl %r13d, %edi        // set neighbor pixel as arg 1
	call get_b             	// get blue component
	subl %r9d, %eax         // calculate diff_b = neighbor_b - current_b
	movl %eax, (%r8)        // store result into memory address of diff_b
	
	/* restore callee-saved registers in reverse order of saving */
	popq %r13
	popq %r12
	popq %rbx
	ret                     // return

/*
 * Processes interior pixel for emboss image processing function
 *
 * Parameters: 
 *	%rdi - input img pointer
 * 	%rsi - output img pointer
 *	%edx - row index
 *	%ecx - col index
 *	%r8d - pixel index
 *
 * Register usage:
 *	%r8d	- pixel index
 *  %r12d - row index
 *  %r13d - col index
 *  %r14 - input image pointer
 *  %r15 - output image pointer
 */
	.globl process_interior_pixel
process_interior_pixel:
	/* prologue to create ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp

	/* pushing callee-saved registers */
	subq $32, %rsp          // allocate stack space for local variables
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	subq $8, %rsp						/* realigns stack */
	
	movq %rdi, %r14         // save input image pointer into r14
	movq %rsi, %r15         // save output image pointer into r15
	movl %edx, %r12d        // save row into r12d
	movl %ecx, %r13d        // save col into r13d
	movl %r8d, %ebx         // save current index into ebx
	
	// get current pixel and its alpha
	movq IMAGE_DATA_OFFSET(%r14), %rax    // load input data pointer into rax
	movl (%rax, %rbx, 4), %edi            // load current pixel into arg 1
	movl %edi, -4(%rbp)                   // save current pixel on stack
	call get_a                            // get alpha
	movl %eax, -8(%rbp)                   // save alpha on stack on stack
	
	// calculate neighbor index
	movq %r14, %rdi         // set image pointer as arg 1
	movl %r12d, %esi        // set row as arg 2
	decl %esi               // row - 1
	movl %r13d, %edx        // set column as arg 3
	decl %edx               // column - 1
	call compute_index      // get neighbor index
	
	// get neighbor pixel
	movq IMAGE_DATA_OFFSET(%r14), %rdx    // load input data pointer
	movl (%rdx, %rax, 4), %esi            // load neighbor pixel and set it to arg 2
	
	// calculate RGB differences
	movl -4(%rbp), %edi     		// retrieve current pixel from stack and set it to arg 1
															// esi already has neighbor pixel
	leaq -12(%rbp), %rdx    		// set address for diff_r and pass as arg 3
	leaq -16(%rbp), %rcx    		// set address for diff_g and pass as arg 4
	leaq -20(%rbp), %r8     		// set address for diff_b and pass as arg 5
	call calculate_rgb_diffs 		// calculate differences
	
	// get maximum difference
	movl -12(%rbp), %edi    		// retrieve updated diff_r and pass as arg 1
	movl -16(%rbp), %esi    		// retrieve updated diff_g and pass as arg 2
	movl -20(%rbp), %edx    		// retrieve updated diff_b and pass as arg 3
	call get_max_diff       		// get diff with largest absolute value
	
	// calculate gray = 128 + diff
	addl $128, %eax         		// gray = 128 + diff
	movl %eax, %edi         		// move gray to arg 1
	call clamp_gray_value   		// clamp to [0, 255] (if needed)
	
	// create and store pixel
	movl %eax, %edi         		// set red = gray
	movl %eax, %esi         		// set green = gray
	movl %eax, %edx         		// set blue = gray
	movl -8(%rbp), %ecx     		// alpha = original alpha
	call make_pixel         		// create pixel
	
	movq IMAGE_DATA_OFFSET(%r15), %rdx    // load output data pointer
	movl %eax, (%rdx, %rbx, 4)            // and store pixel at the current index
	
	addq $8, %rsp						/* deallocate the 8 bytes used for stack alignment */

	/* restore callee-saved registers in reverse order of saving */
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbx
	addq $32, %rsp          // deallocate stack space for local variables

	/* epilogue to restore ABI-compliant stack frame */
	popq %rbp
	ret

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
 *
 * Register use:
 *   %r12d - image height
 *   %r13d - image width
 *   %r14  - pointer to input image
 *   %r15  - pointer to output image
 *   %ebx  - outer loop counter (row index)
 *	 %ecx  - inner loop counter (col index)
 *   %rax  - index for storing/loading a pixel from a pixel data array
 *	 %edx  - temporary storage place for the pixel being transposed
 */
	.globl imgproc_ellipse
imgproc_ellipse:
	/* prologue to create ABI-compliant stack frame */
	pushq %rbp
	movq %rsp, %rbp

	/* pushing callee-saved registers */
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	subq $8, %rsp        		/* realigns stack */

	movl IMAGE_HEIGHT_OFFSET(%rdi), %r12d		/* store image height in %r12d */
	movl IMAGE_WIDTH_OFFSET(%rdi), %r13d 		/* store image width in %r13d */
	movq %rdi, %r14         /* save input image pointer in %r14 */
	movq %rsi, %r15         /* save output image pointer in %r15 */
	

	movl $0, %ebx						/* initialize row counter to 0 */

	.Lrow_loop:
		cmpl %r12d, %ebx 			/* are we done iterating through all rows? */
		jge .Lellipse_done 		/* if so, jump to cleanup	*/
		movl $0, %ecx 				/* initialize col counter to 0 */

	.Lcol_loop:
		cmpl %r13d, %ecx  		/* are we done iterating through all columns of the row? */
		jge .Lnext_row 				/* if so, jump to next row */

		pushq %rbx						/* save row count on stack */
		pushq %rcx						/* save col count on stack */

		movq %r14, %rdi				/* image pointer in %rdi (arg 1) */
		movl %ebx, %esi				/* row in %esi (arg 2)	*/
		movl %ecx, %edx 			/* col in %edx (arg 3) */
		call is_in_ellipse		/* call helper function passing in those args */

		popq %rcx							/* restore col count from stack */
		popq %rbx							/* restore row count from stack */
		cmpl $0, %eax 				/* see if eax returned 1 or 0 (success or fail) */
		je .Lskip_pixel 			/* if fail, jump to Lskip_pixel	*/

		/* calculate index: row * width + col */
		movl %ebx, %eax       /* copy row to %eax */
		imull %r13d, %eax     /* multiply by width */
		addl %ecx, %eax       /* lastly, add column */

		movq IMAGE_DATA_OFFSET(%r14), %rdx    /* load input data pointer */
		movl (%rdx, %rax, 4), %edx            /* load pixel from input[index] */
		movq IMAGE_DATA_OFFSET(%r15), %rsi    /* load output data pointer */
		movl %edx, (%rsi, %rax, 4)            /* store pixel to output[index] */
	
	.Lskip_pixel:
		incl %ecx							/* increment column counter */
		jmp .Lcol_loop 				/* go to next column */

	.Lnext_row:
		incl %ebx 						/* increment row counter */
		jmp .Lrow_loop 				/* go to the next row */

	.Lellipse_done:
		addq $8, %rsp					/* deallocate the 8 bytes used for stack alignment */

		/* restore callee-saved registers in reverse order of saving */
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		popq %rbx

		/* epilogue to restore ABI-compliant stack frame */
		popq %rbp

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
 * 
 * Register usage:
 *  %rbx - row counter
 *	%rcx - column counter
 *	%r8d	- pixel index
 *  %r12d - image height
 *  %r13d - image width
 *  %r14 - input image pointer
 *  %r15 - output image pointer
 */
	.globl imgproc_emboss
imgproc_emboss:
	/* prologue to create ABI-compliant stack frame */
	push %rbp
	movq %rsp, %rbp

	/* pushing callee-saved registers */
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	subq $8, %rsp        		/* realigns stack */

	movq %rdi, %r14					// save input image pointer into r14
	movq %rsi, %r15 				// save output image pointer into r15
	movl IMAGE_HEIGHT_OFFSET(%r14), %r12d // save image height into r12d
	movl IMAGE_WIDTH_OFFSET(%r14), %r13d // save image width into r13d

	movl $0, %ebx 					// initialize row counter to 0
	
	.Lemboss_row_loop:
		cmpl %r12d, %ebx 			// have we iterated through all rows?
		jge .Lemboss_done 		// if so, jump to cleanup

		movl $0, %ecx 				// initilize column counter to 0
	
	.Lemboss_col_loop:
		cmpl %r13d, %ecx 			// have we iterated through all columns of the row? 
		jge .Lemboss_next_row // if yes, jump to next row

		// compute current index in data array = current row * image width + current column
		movl %ebx, %eax				// copy current row count to eax
		imull %r13d, %eax 		// multipily by width
		addl %ecx, %eax 			// add current column count
		movl %eax, %r8d 			// save index in r8d

		testl %ebx, %ebx 			// is row counter = 0 (a border pixel)?
		jz .Lemboss_border_pixel // if it is, jump
		testl %ecx, %ecx			// is column counter = 0 (a border pixel)?
		jz .Lemboss_border_pixel // if so, jump

		// otherwise, must be interior pixel
		pushq %rcx						// save column counter
		pushq %rbx						// save row counter
		
		movq %r14, %rdi				// pass input image pointer into arg 1
		movq %r15, %rsi				// pass output image pointer into arg 2
		movl %ebx, %edx 			// pass row counter into arg 3
													// column counter is already in %ecx
													// pixel index is already in %r8d
		call process_interior_pixel   // process interior pixel with the passed in arguments
		
		popq %rbx							// restore row counter
		popq %rcx							// restore column counter
		jmp .Lemboss_next_pixel  // and continue to next pixel

	.Lemboss_border_pixel:
		pushq %rcx						// save column counter
		pushq %rbx						// save row counter

		movq IMAGE_DATA_OFFSET(%r14), %rax	// load input data pointer into rax
		movl (%rax, %r8, 4), %edi	// load pixel from input
		call get_a						// get alpha component
		movl %eax, %ecx				// move alpha component to ecx

		movl $128, %edi				// pass 128 in for red
		movl $128, %esi				// pass 128 in for green
		movl $128, %edx				// pass 128 in for blue
		call make_pixel				// and call make_pixel to create pixel

		movq IMAGE_DATA_OFFSET(%r15), %rdx	// load output data pointer
		movl %eax, (%rdx, %r8, 4)	// and store pixel to output

		popq %rbx							// restore row counter
		popq %rcx							// restore column counter

	.Lemboss_next_pixel:
		incl %ecx							// increment column counter 
		jmp .Lemboss_col_loop	// and continue the column loop

	.Lemboss_next_row:
		incl %ebx 						// increment row counter
		jmp .Lemboss_row_loop // and start another row loop
	
	.Lemboss_done:
		addq $8, %rsp		/* deallocate the 8 bytes used for stack alignment */
		
		/* restore callee-saved registers in reverse order of saving */
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		popq %rbx

		/* epilogue to restore ABI-compliant stack frame */
		popq %rbp
		ret
	
/*
vim:ft=gas:
*/

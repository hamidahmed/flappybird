# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# All the Helper Function:
# | Init | CoordinateToAddress | DrawPixel | DrawBird | DrawSky | UpdateBirdArrayPos | Print  | ClearRegisters
.data
	#Screen 
	screenWidth: 	.word 32
	screenHeight: 	.word 32
	displayAddress:	.word	0x10008000
	newline: .asciiz "\n"
	
	# Debug prompts
	promptBirdPos: .asciiz "Bird position: "
	promptDisplayAdd: .asciiz "Display address: "
	promptInit: .asciiz "Init\n"
	promptDrawSky: .asciiz "Drawing Sky\n"
	promptDrawBird: .asciiz "Drawing Bird\n"
	promptEndLoop: .asciiz "End Of Loop\n"
	
	# Colors
	Blue: 	   .word	0x9AFCF6	 # blue
	Green:     .word	0x2DA617	 # Green
	Yellow:    .word	0xFFE945	 # Yellow
	Black:     .word        0x000000	 # black
	
	# Bird variables
	#shape of the bird#
	#     ##	  #
	#    #####	  #
	#    #####	  #
	#     ##	  #
	###################
	birdPixelCount: .word 14
	birdBytesCount: .word 0
	# (x, y): {(1, 0), (2, 0),..., (1, 3), (2,3)}
	birdPos: .word 1,13 , 2,13 , 0,14 , 1,14 , 2,14 , 3,14 , 4,14 , 0,15 , 1,15 , 2,15 , 3,15 , 4,15 , 1,16 , 2,16	
	BirdColor: .word 0xFFE945		# The color of the bird
	
.text
main:
	jal Init
	la $a0, promptDrawSky
	li $a1, 4
	jal Print
	jal DrawSky
	la $a0, promptDrawBird
	li $a1, 4
	jal Print
	jal DrawBird
	
	
	j Exit

#-----------------------------------------------------------------
##################################################################
# Init Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
Init:
	lw $t0, Yellow			# store Yellow color in $t0
	sw $t0, BirdColor		# set the birds color to $t0
	lw $t0, birdPixelCount		# Store number of sets the bird is made of
	mul $t0, $t0, 2			# multiply to account for x and y
	mul $t0, $t0, 4			# multiply to account for number of bytes each pixel is
	#subi $t0, $t0, 4		# moves one index back since count starts at 0
	sw $t0, birdBytesCount		# setting number of bytes the bird is to word
	jr $ra			# return $v0

##################################################################
# CoordinatesToAddress Function
# $a0 -> x coordinate
# $a1 -> y coordinate
##################################################################
# returns $v0 -> the address of the coordinates for bitmap display
##################################################################
CoordinateToAddress:
	lw	$v0, screenWidth 	#Store screen width into $v0
	mul 	$v0, $v0, $a1		#multiply by y position
	add 	$v0, $v0, $a0		#add the x position
	mul 	$v0, $v0, 4		#multiply by 4
	add 	$v0, $v0, $gp		#add global pointerfrom bitmap display
	jr $ra				# return $v0

##################################################################
# DrawPixel Function
# $a0 -> Pixel to draw
# $a1 -> Color of the pixel
##################################################################
# returns $v0 -> NULL
##################################################################
DrawPixel:
	add	$a0, $a0, $zero
	sw	$a1, 0($a0)
	jr $ra

##################################################################
# DrawBird Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawBird:
	la $s5, ($ra)
	lw $s2, birdBytesCount
	la $a0, ($s2)
	li $a1, 1
	jal Print
	loopInitDrawBird:
		li 	$s0, 0
	drawBird:
		sub 	$s1, $s0, $s2
		beq 	$s1, 0, endDrawBird
		
		# main body of code ------
		lw 	$a0, birdPos($s0) 	# loads the x-coordinate into $a0
		addi 	$s0, $s0, 4 		# iterate over to the next element in the array
		lw 	$a1, birdPos($s0) 	# loads the y-coordinate into $a1
		
		jal 	CoordinateToAddress 	# call to get the display address from the coordinates
		move 	$a0, $v0 		# move the address into $a0
		
		lw 	$a1, BirdColor 		# loads the color yellow in $a1
		
		jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
		# ------------------------
		addi 	$s0, $s0, 4		# iterate over the counter by sizeof(int)
		j 	drawBird 		# loop back to drawBird
	endDrawBird:
		la $a0, promptEndLoop
		li $a1, 4
		jal Print
		la $ra, ($s5)
		jr $ra

##################################################################
# DrawSky Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawSky:
	la $s5, ($ra)
	loopInitDrawSkyX:
		li 	$s0, 0
	drawSkyX:
		subi 	$s1, $s0, 32
		beq 	$s1, 0, endDrawSkyX
		
		# main body of code ------		
			loopInitDrawSkyY:
				li 	$s2, 0
			drawSkyY:
				subi 	$s3, $s2, 32
				beq 	$s3, 0, endDrawSkyY
				
				# main body of code ------
				la	$a0, 0($s0)	# loads the x-coordinate into $a0
				la	$a1, 0($s2)	# loads the y-coordinate into $a1
		
				jal 	CoordinateToAddress 	# call to get the display address from the coordinates
				move 	$a0, $v0 		# move the address into $a0
		
				lw 	$a1, Blue 		# loads the color yellow in $a1
		
				jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
				# ------------------------
				addi 	$s2, $s2, 1		# iterate over the counter by sizeof(int)
				j 	drawSkyY 		# loop back to drawSkyY
			endDrawSkyY:
				
		# ------------------------
		addi 	$s0, $s0, 1		# iterate over the counter by sizeof(int)
		j 	drawSkyX 		# loop back to drawSkyX
	endDrawSkyX:
		la $a0, promptEndLoop
		li $a1, 4
		jal Print
		la $ra, ($s5)
		jr $ra
		
##################################################################
# UpdateBirdArrayPos Function
# $a0 -> Array index
# $a1 -> Value
##################################################################
# returns $v0 -> NULL
##################################################################
UpdateBirdArrayPos:
	sw $a1, birdPos($a0)	# stores the value of $a1 at the index of $a0 in birdPos
	jr $ra			# return 
	
##################################################################
# Print Function
# $a0 -> Value to print
# $a1 -> Type to print
##################################################################
# returns $v0 -> NULL
##################################################################
Print:
	move $v0, $a1 	# sets print type
	syscall		# system call
	jr $ra		# return

##################################################################
# ClearRegisters Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
ClearRegisters:

	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0
	jr $ra

Exit:
	li $v0, 10 # terminate the program gracefully
	syscall

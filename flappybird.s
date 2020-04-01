# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# All the Helper Function:
# | Init | CoordinateToAddress | DrawPixel | DrawBird | DrawSky | UpdateBirdArrayPos | Print  | ClearRegisters | DrawGround | DrawBottomLine |
# | DrawTopLine | UpdateFall | Pause | GetKeyPress
.data
	#Screen 
	screenWidth: 	.word 32
	screenHeight: 	.word 64
	displayAddress:	.word	0x10008000
	newline: .asciiz "\n"
	
	# Debug prompts
	promptBirdPos: 		.asciiz "Bird position: "
	promptDisplayAdd: 	.asciiz "Display address: "
	promptInit: 		.asciiz "Init\n"
	promptDrawSky: 		.asciiz "Drawing Sky\n"
	promptDrawBird: 	.asciiz "Drawing Bird\n"
	promptEndLoop: 		.asciiz "End Of Loop\n"
	promptFall:		.asciiz "Birds falling.\n"
	promptFlap:		.asciiz "Birds flapping.\n"	
	
	# Colors
	Blue: 	   .word	0x9AFCF6	 # blue
	Green:     .word	0x2DA617	 # Green
	Yellow:    .word	0xFFE945	 # Yellow
	Black:     .word        0x000000	 # black
	Orange:    .word	0xff9933	 # orange
	
	# Gameplay
	difficulty: .word 0
	framesPerSecond: .word 4
	
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
	birdPos: .word 3,13 , 4,13 , 2,14 , 3,14 , 4,14 , 5,14 , 6,14 , 2,15 , 3,15 , 4,15 , 5,15 , 6,15 , 3,16 , 4,16	
	BirdColor: .word 0xFFE945		# The color of the bird
	birdAlive: .word 1
	birdScore: .word 0
	fallDistance: .word 1
	
.text
main:
	jal Init
	#set the framerate for the game
	lw $a0, framesPerSecond
	li $a1, 1000
	div $a1, $a0
	mflo $t0
	# main gameplay loop--------------------------------------
	loopInitMain:
		li 	$t1, 0
	whileMain:
		la $a0, ($t0)
		jal Pause
		lw 	$t2, birdAlive
		beq 	$t2, 0, deadMain
		
		# main body of code ------
		jal GetKeyPress		# get key press or 0 on no input
		move 	$a0, $v0
		li 	$a1, 0x66   		# store kyboard input f in $t0
 		beq  	$a0, $a1, updateFlap
 		beq  	$a0, 0, noInput
 			noInput:
 				la $a0, promptFall
 				la $a1, 4
 				jal Print
 				jal UpdateFall
 				j continue
 			updateFlap:
 				la $a0, promptFlap
 				la $a1, 4
 				jal Print
 				jal Flap
 				j continue
 		continue:
		jal DrawSky
		jal DrawBird
		#jal DrawGround
		#-------------------------
		j whileMain
	deadMain:
		# Show death screen
	#---------------------------------------------------------
	
	
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
	la $t0, ($ra)
	lw $t1, Yellow			# store Yellow color in $t0
	sw $t1, BirdColor		# set the birds color to $t0
	lw $t1, birdPixelCount		# Store number of sets the bird is made of
	mul $t1, $t1, 2			# multiply to account for x and y
	mul $t1, $t1, 4			# multiply to account for number of bytes each pixel is
	sw $t1, birdBytesCount		# setting number of bytes the bird is to word
	# draw initial pixels
	la $a0, promptDrawSky
	li $a1, 4
	jal Print
	jal DrawSky
	la $a0, promptDrawBird
	li $a1, 4
	jal Print
	jal DrawBird
	jal DrawGround
	la $ra, ($t0)
	jr $ra				# return $v0

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
	la $s3, ($ra) 				# load the register address to which we need to leave and return to the main function
	lw $s2, birdBytesCount			# load the number of bytes we need to loop over
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
		la 	$ra, ($s3)
		jr 	$ra

##################################################################
# DrawSky Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawSky:
	lw $s4, screenWidth			# load the number of pixels we need to loop over
	la $s5, ($ra)				# load the register address to which we need to leave and return to the main function
	lw $s6, screenHeight			# load the number of pixels we need to loop over
	loopInitDrawSkyX:
		li 	$s0, 0
	drawSkyX:
		sub 	$s1, $s0, $s4
		beq 	$s1, 0, endDrawSkyX
		
		# main body of code ------		
			loopInitDrawSkyY:
				li 	$s2, 0
			drawSkyY:
				sub 	$s3, $s2, $s6		# checks if the counter is less == to 32 i < 0
				beq 	$s3, 0, endDrawSkyY
				
				# main body of code ------
				la	$a0, 0($s0)		# loads the x-coordinate into $a0
				la	$a1, 0($s2)		# loads the y-coordinate into $a1
		
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
		la 	$ra, ($s5)
		jr 	$ra
		
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

##################################################################
# DrawGround Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawGround:
	lw 	$s2, screenWidth		# load the number of pixels we need to loop over the width
	lw 	$s3, screenHeight		# load the number of bytes we need to loop over the height
	la 	$s4, ($ra) 			# load the register address to which we need to leave and return to the main function
	loopInitDrawBorder:
		li 	$s0, 0
	forDrawBorder:
		sub 	$s1, $s0, $s3
		bgtz 	$s1, endDrawBorder
		
		# main body of code ------
		la 	$a0, 0
		la 	$a1, ($s0)
		jal 	CoordinateToAddress 	# call to get the display address from the coordinates
		move 	$a0, $v0 		# move the address into $a0
		lw 	$a1, Orange 		# loads the color yellow in $a1
		jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
		subi 	$a0, $s3, 1
		la 	$a1, ($s0)
		jal 	CoordinateToAddress 	# call to get the display address from the coordinates
		move 	$a0, $v0 		# move the address into $a0
		lw 	$a1, Orange 		# loads the color yellow in $a1
		jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
		# ------------------------
		addi 	$s0, $s0, 1		# iterate over the counter 
		j 	forDrawBorder 		# loop back to drawBird
	endDrawBorder:
		jal DrawTopLine
		jal DrawBottomLine
		la 	$ra, ($s4)
		jr 	$ra
			
##################################################################
# DrawBottomLine Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawBottomLine:
	lw 	$s2, screenWidth		# load the number of pixels we need to loop over the width
	lw 	$s3, screenHeight		# load the number of bytes we need to loop over the height
	la	$a3, ($ra)
	loopInitDrawBottomLine:
		li 	$s5, 0
	forDrawBottomLine:
		sub $a0, $s5, $s2
		beq $a0, 0, endBottomLine
		
		# main body of code ------
		subi	$a0, $s3, 1
		la 	$a1, ($s5)
		jal 	CoordinateToAddress 	# call to get the display address from the coordinates
		move 	$a0, $v0 		# move the address into $a0
		lw 	$a1, Orange 		# loads the color yellow in $a1
		jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
		# ------------------------
		addi $s5, $s5, 1
		j forDrawBottomLine
	endBottomLine:
		la	$ra, ($a3)
		jr 	$ra

##################################################################
# drawTopLine Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawTopLine:
	lw 	$s2, screenWidth		# load the number of pixels we need to loop over the width
	lw 	$s3, screenHeight		# load the number of bytes we need to loop over the height
	la	$a3, ($ra)
	loopInitDrawTopLine:
		li 	$s5, 0
	forDrawTopLine:
		sub $a0, $s5, $s2
		beq $a0, 0, endTopLine
		
		# main body of code ------
		li	$a0, 0
		la 	$a1, ($s5)
		jal 	CoordinateToAddress 	# call to get the display address from the coordinates
		move 	$a0, $v0 		# move the address into $a0
		lw 	$a1, Orange 		# loads the color yellow in $a1
		jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
		# ------------------------
		addi $s5, $s5, 1
		j forDrawTopLine
	endTopLine:
		la	$ra, ($a3)
		jr 	$ra

##################################################################
# UpdateFall Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
UpdateFall:
	la 	$s3, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s2, birdBytesCount		# load the number of bytes we need to loop over
	loopInitUpdateFall:
		li 	$s0, 4
	forUpdatFall:
		sub 	$s1, $s0, $s2
		bgtz 	$s1, endUpdateFall
		
		# main body of code ------
		lw 	$a0, birdPos($s0) 	# loads the y-coordinate into $a0
		# subtract distance to fall for each pixel
		lw	$a1, fallDistance	# load the distance the bird shouldd fall into $a1
		add	$a0, $a0, $a1		# add to the y-coordinate to move each pixel down 
		
		sw	$a0, birdPos($s0)	# update the coords at index $s0
		# ------------------------
		addi 	$s0, $s0, 8		# iterate over the counter by 8 to move ddirectly to the y-coordinate
		j 	forUpdatFall 		# loop back to drawBird
	endUpdateFall:
		la $ra, ($s3)
		jr $ra

##################################################################
# Flap Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
Flap:
	la 	$s3, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s2, birdBytesCount		# load the number of bytes we need to loop over
	loopInitFlap:
		li 	$s0, 4
	forFlap:
		sub 	$s1, $s0, $s2
		bgtz 	$s1, endFlap
		
		# main body of code ------
		lw 	$a0, birdPos($s0) 	# loads the y-coordinate into $a0
		# subtract distance to fall for each pixel
		lw	$a1, fallDistance	# load the distance the bird shouldd fall into $a1
		subi	$a0, $a0, 1		# add to the y-coordinate to move each pixel up 
		
		sw	$a0, birdPos($s0)	# update the coords at index $s0
		# ------------------------
		addi 	$s0, $s0, 8		# iterate over the counter by 8 to move ddirectly to the y-coordinate
		j 	forFlap 		# loop back to drawBird
	endFlap:
		la $ra, ($s3)
		jr $ra

##################################################################
# CheckBorderCollision Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
CheckBorderCollision:
	la 	$s3, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s2, birdBytesCount		# load the number of bytes we need to loop over
	loopInitBorderCollision:
		li 	$s0, 0
	forBorderCollision:
		sub 	$s1, $s0, $s2
		bgtz 	$s1, endBorderCollision
		
		# main body of code ------
		lw 	$a0, birdPos($s0) 	# loads the x-coordinate into $a0
		# check if the y-coord collides with any other y-coord
		
		sw	$a0, birdPos($s0)	# update the coords at index $s0
		# ------------------------
		addi 	$s0, $s0, 4		# iterate over the counter by 8 to move ddirectly to the y-coordinate
		j 	forBorderCollision 	# loop back to drawBird
	endBorderCollision:
		la $ra, ($s3)
		jr $ra

##################################################################
# Pause Function
# $a0 - amount to pause
##################################################################
# no return values
##################################################################
Pause:
	li $v0, 32 #syscall value for sleep
	syscall
	jr $ra

##################################################################
# GetKeyPress Function
# $a0 - NULL
##################################################################
# returns $v0 -> returns 0 on fail and the key on success
##################################################################
GetKeyPress:
    	la    	$s1, 0xffff0000            	# status register
    	li    	$v0, 0                		# default to no key pressed
    	lw    	$s0, 0($s1)            		# load the status
    	beq   	$s0, $zero, keypress_return   	# no key pressed, return
    	lw    	$v0, 4($s1)            		# read the key pressed
	jr    	$ra
    keypress_return:
	jr 	$ra
    
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall

# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# All the Helper Function:
# | Init | CoordinateToAddress | DrawPixel | DrawBird | DrawSky | UpdateBirdArrayPos | Print  | ClearRegisters | DrawGround |
# | UpdateFall | Pause | GetKeyPress | InitGround | CheckCollisionWithGround | KillBird | DrawBirdPrevPos | InitPipes | DrawPipe |
# | DrawPrevPipePos | UpdatePipesLeft | LoadAddress | CheckCollisionWithPipes | GenNextPipe | LoopSky | shiftDifficulty
.data
	#Screen 
	screenWidth: 	.word 64
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
	Orange:    .word	0x331a00	 # orange
	Red:	   .word	0xff5050	 # red
	
	# Gameplay
	difficulty: .word 0
	framesPerSecond: .word 2
	timer: .word 0
	skyCounter: .word 0
	skyLoopCall: .word 40
	pipeCounter: .word 0
	pipeMoveCall: .word 2
	difficultyCounter: .word 0
	difficultyShiftCall: .word 100
	backGroundColor: .word 0x9AFCF6
	skyColorArray: .word 0x9AFCF6, 0xBCD2E8, 0x91BAD6, 0x73A5C6, 0x528AAE, 0x2E5984, 0x1E3F66, 0x06385D, 0x042442, 0x042442, 0x06385D, 0x1E3F66, 0x2E5984, 0x528AAE, 0x73A5C6,0x91BAD6, 0x9AFCF6
	
	# Bird variables
	#shape of the bird#
	#     ##	  #
	#    #####	  #
	#    #####	  #
	#     ##	  #
	###################
	birdPixelCount: .word 12
	birdBytesCount: .word 0
	# (x, y): {(1, 0), (2, 0),..., (1, 3), (2,3)}
	#9,13 , 10,13 , 8,14 , 9,14 , 10,14 , 11,14 , 12,14 , 8,15 , 9,15 , 10,15 , 11,15 , 12,15	
	birdPos: .word 8,13 , 9,13 , 7,14 , 8,14 , 9,14 , 10,14 , 11,14 , 7,15 , 8,15 , 9,15 , 10,15 , 11,15
	birdPos2: .word 3,23 , 4,23 , 2,24 , 3,24 , 4,24 , 5,24 , 6,24 , 2,25 , 3,25 , 4,25 , 5,25 , 6,25
	BirdColor: .word 0xFFE945		# The color of the bird	
	BirdColor2: .word 0xFFE945		# The color of the bird
	birdAlive: .word 1
	birdScore: .word 0
	fallDistance: .word 1
	flapDistance: .word 6
	
	# Ground variables
	# (x, y): {(0, 0), (0, 0), (0, 0), (0,0)}
	groundArray:	.word 0,0 , 0,0 , 0,0 , 0,0
	groundHeight: 	.word 5
	
	# Pipes Values
	# (x, y): {(0, 0), (0, 0), (0, 0), (0,0)}
	pipeArray1:		.word 0,0 , 0,0 , 0,0 , 0,0
	pipeArray2:		.word 0,0 , 0,0 , 0,0 , 0,0
	pipeArray3:		.word 0,0 , 0,0 , 0,0 , 0,0
	pipeArray4:		.word 0,0 , 0,0 , 0,0 , 0,0
	pipesDistance:		.word 20
	minTopPipeHeight:	.word 5
	shiftDistance:		.word 1
	pipeThickness:		.word 10
	
.text
main:
	jal LoadAddress
	jal Init
	#set the framerate for the game
	lw $a0, framesPerSecond
	li $a1, 120
	div $a1, $a0
	mflo $t0
	# main gameplay loop--------------------------------------
	loopInitMain:
		li 	$t1, 0
	whileMain:
		jal CheckCollisionWithGround
		jal CheckCollisionWithGround2
 		jal CheckCollisionWithPipes
 		jal CheckCollisionWithPipes2
		la $a0, ($t0)
		jal Pause
		lw 	$a0, birdAlive
		beq 	$a0, 0, deadMain
		lw $a0, skyCounter
		addi $a0, $a0, 1
		sw $a0, skyCounter
		lw $a1, skyLoopCall
		div $a0, $a1
		mfhi $a0
		beq $a0, 0, loopSky
		j dontloop
		loopSky:
			li $a0, 0
			sw $a0, skyCounter
			jal LoopSky
			jal DrawSky
		dontloop:
		lw $a0, pipeCounter
		addi $a0, $a0, 1
		sw $a0, pipeCounter
		lw $a1, pipeMoveCall
		div $a0, $a1
		mfhi $a0
		beq $a0, 0, movePipe
		j dontMovePipe
		movePipe:
			li $a0, 0
			sw $a0, pipeCounter
			jal DrawPrevPipePos
 			jal UpdatePipesLeft
 			jal DrawPipe
		dontMovePipe:
		lw $a0, difficultyCounter
		addi $a0, $a0, 1
		sw $a0, difficultyCounter
		lw $a1, difficultyShiftCall
		div $a0, $a1
		mfhi $a0
		beq $a0, 0, shiftDifficulty
		j dontShiftDifficulty
		shiftDifficulty:
			jal ShiftDifficulty
			li $a0, 0
			sw $a0, difficultyCounter
		dontShiftDifficulty:
		# main body of code ------
		jal GetKeyPress		# get key press or 0 on no input
		move 	$a0, $v0
		li 	$a1, 0x66   		# store kyboard input f in $t0
 		beq  	$a0, $a1, updateFlap
 		li 	$a1, 0x6a
 		beq  	$a0, $a1, updateFlap2
 		beq  	$a0, 0, noInput
 			noInput:
				jal DrawBirdPrevPos
				jal DrawBirdPrevPos2
 				jal UpdateFall
 				jal UpdateFall2
				jal DrawBird
				jal DrawBird2
 				jal DrawPipe
 				j continue
 			updateFlap:
				jal DrawBirdPrevPos
 				jal Flap
				jal DrawBird
 				j continue
 			updateFlap2:
				jal DrawBirdPrevPos2
 				jal Flap2
				jal DrawBird2
 				j continue
 		continue:
 		lw	$a1, 0($t6)
 		blt 	$a1, 0, genPipe
		#-------------------------
		j whileMain
		genPipe:
			jal GenNextPipe
			jal DrawSky
			jal DrawBird
			jal DrawBird2
			j whileMain
	deadMain:
		jal DrawBye
 		jal DrawPipe
 		jal DrawGround
		jal DrawBird
		jal DrawBird2
		# Show death screen
		jal DrawBye
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
	lw $t1, Red			# store Yellow color in $t0
	sw $t1, BirdColor2		# set the birds color to $t0
	lw $t1, Blue
	sw $t1, backGroundColor
	lw $t1, birdPixelCount		# Store number of sets the bird is made of
	mul $t1, $t1, 2			# multiply to account for x and y
	mul $t1, $t1, 4			# multiply to account for number of bytes each pixel is
	sw $t1, birdBytesCount		# setting number of bytes the bird is to word
	# draw initial pixels
	jal DrawSky
	jal DrawBird
	jal DrawBird2
	jal InitGround
	jal DrawGround
	jal InitPipes
	la $ra, ($t0)
	jr $ra				# return $v0

##################################################################
# GenNextPipe Function
# $a0 -> x coordinate
# $a1 -> y coordinate
##################################################################
# returns $v0 -> NULL
##################################################################
GenNextPipe:
	la	$s7, ($ra)
	jal 	InitPipes
	la	$ra, ($s7)
	jr	$ra
	
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
	sll 	$v0, $v0, 2		#multiply by 4
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
# DrawBird Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawBird2:
    la $s3, ($ra)                 # load the register address to which we need to leave and return to the main function
    lw $s2, birdBytesCount            # load the number of bytes we need to loop over
    loopInitDrawBird2:
        li     $s0, 0
    drawBird2:
        sub     $s1, $s0, $s2
        beq     $s1, 0, endDrawBird2

        # main body of code ------
        lw     $a0, birdPos2($s0)     # loads the x-coordinate into $a0
        addi     $s0, $s0, 4         # iterate over to the next element in the array
        lw     $a1, birdPos2($s0)     # loads the y-coordinate into $a1

        jal     CoordinateToAddress     # call to get the display address from the coordinates
        move     $a0, $v0         # move the address into $a0

        lw     $a1, BirdColor2         # loads the color yellow in $a1

        jal     DrawPixel        # call to draw the bird on the given $a0 position and $a1 color
        # ------------------------
        addi     $s0, $s0, 4        # iterate over the counter by sizeof(int)
        j     drawBird2         # loop back to drawBird
    endDrawBird2:
        la     $ra, ($s3)
        jr     $ra

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
	lw $a0, groundHeight
	sub $s6, $s6, $a0
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
		
				lw 	$a1, backGroundColor 	# loads the color yellow in $a1
		
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
# DrawGround Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawGround:
	la	$s6, groundArray
	lw	$s0, 0($s6)		# width 1
	lw	$s1, 8($s6)		# width 2
	lw	$s3, 20($s6)		# height 2
	la 	$s4, ($ra) 		# load the register address to which we need to leave and return to the main function
	whileDrawGroundX:
		sub $a0, $s0, $s1
		beq $a0, 0, endDrawGroundX
		
		# main body of code ------
		lw	$s2, 4($s6)		# height 1
			whileDrawGroundY:
				sub $a0, $s2, $s3
				beq $a0, 0, endDrawGroundY
				
				# main body of code ------
				la	$a0, ($s0)		# loads the x-coordinate into $a0
				la	$a1, ($s2)		# loads the y-coordinate into $a1
				jal 	CoordinateToAddress 	# call to get the display address from the coordinates
				move 	$a0, $v0 		# move the address into $a0
				lw 	$a1, Orange 		# loads the color orange in $a1
				jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
				#-------------------------
				addi $s2, $s2, 1
				j whileDrawGroundY
				
			endDrawGroundY:
				
		#-------------------------
		addi $s0, $s0, 1	# iterate to the next x coord
		j whileDrawGroundX	# loop back to top
		
	endDrawGroundX:
		la 	$ra, ($s4)
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
# UpdateFall Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
UpdateFall2:
	la 	$s3, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s2, birdBytesCount		# load the number of bytes we need to loop over
	loopInitUpdateFall2:
		li 	$s0, 4
	forUpdatFall2:
		sub 	$s1, $s0, $s2
		bgtz 	$s1, endUpdateFall2
		
		# main body of code ------
		lw 	$a0, birdPos2($s0) 	# loads the y-coordinate into $a0
		# subtract distance to fall for each pixel
		lw	$a1, fallDistance	# load the distance the bird shouldd fall into $a1
		add	$a0, $a0, $a1		# add to the y-coordinate to move each pixel down 
		
		sw	$a0, birdPos2($s0)	# update the coords at index $s0
		# ------------------------
		addi 	$s0, $s0, 8		# iterate over the counter by 8 to move ddirectly to the y-coordinate
		j 	forUpdatFall2 		# loop back to drawBird
	endUpdateFall2:
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
		lw	$a1, flapDistance	# load the distance the bird shouldd fall into $a1
		sub	$a0, $a0, $a1		# add to the y-coordinate to move each pixel up 
		
		sw	$a0, birdPos($s0)	# update the coords at index $s0
		# ------------------------
		addi 	$s0, $s0, 8		# iterate over the counter by 8 to move ddirectly to the y-coordinate
		j 	forFlap 		# loop back to drawBird
	endFlap:
		la $ra, ($s3)
		jr $ra

##################################################################
# Flap Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
Flap2:
	la 	$s3, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s2, birdBytesCount		# load the number of bytes we need to loop over
	loopInitFlap2:
		li 	$s0, 4
	forFlap2:
		sub 	$s1, $s0, $s2
		bgtz 	$s1, endFlap2
		
		# main body of code ------
		lw 	$a0, birdPos2($s0) 	# loads the y-coordinate into $a0
		# subtract distance to fall for each pixel
		lw	$a1, flapDistance	# load the distance the bird shouldd fall into $a1
		sub	$a0, $a0, $a1		# add to the y-coordinate to move each pixel up 
		
		sw	$a0, birdPos2($s0)	# update the coords at index $s0
		# ------------------------
		addi 	$s0, $s0, 8		# iterate over the counter by 8 to move ddirectly to the y-coordinate
		j 	forFlap2 		# loop back to drawBird
	endFlap2:
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
  
##################################################################
# InitGround Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
InitGround:
	la	$s6, groundArray
	lw 	$s0, screenWidth		# load the number of bytes we need to loop over from screen width
	lw 	$s1, screenHeight		# load the number of bytes we need to loop over from screen height
	lw	$s2, groundHeight
	# Point one (0, h-gh)
	li	$a0, 0
	sw	$a0, 0($s6)
	sub	$a0, $s1, $s2
	sw	$a0, 4($s6)
	# Point one (w-1, h-gh)
	subi	$a0, $s0, 0
	sw	$a0, 8($s6)
	sub	$a0, $s1, $s2
	sw	$a0, 12($s6)
	# Point one (0, h-1)
	li	$a0, 0
	sw	$a0, 16($s6)
	subi	$a0, $s1, 0
	sw	$a0, 20($s6)
	# Point one (w-1, h-1)
	subi	$a0, $s0, 0
	sw	$a0, 24($s6)
	subi	$a0, $s1, 0
	sw	$a0, 28($s6)
	jr	$ra

##################################################################
# CheckCollisionWithGround Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
CheckCollisionWithGround:
	lw	$s0, 0($t8)		# width 1
	lw	$s1, 8($t8)		# width 2
	lw	$s2, 4($t8)		# height 1
	lw	$s3, 20($t8)		# height 2
	la 	$s4, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s5, birdBytesCount		# load the number of bytes we need to loop over
	loopInitCollisionWithGround:
		li 	$s6, 0
	forCollisionWithGround:
		sub 	$a0, $s6, $s5
		beq 	$a0, 0, endCollisionWithGround
		
		# main body of code ------
		lw 	$a0, birdPos($s6) 	# loads the x-coordinate into $a0
		addi	$s6, $s6, 4		# moving to the y-coord
		lw 	$a1, birdPos($s6) 	# loads the y-coordinate into $a1
		# check if in ground
		bgt	$a0, $s0, greaterThanX					# check if the x-coord is greater than the farthest left ground point
		j	continueCollisionWithGround				# if not then move to the next coordinate
		greaterThanX:							# if it is then 
			blt	$a0, $s1, lessThanX				# check if the x-coord is less than the farthest right ground point
			j	continueCollisionWithGround			# if not then move to the next coordinate
			lessThanX:						# if it is then
				bgt	$a1, $s2, greaterThanY			# check if the y-coord is greater than the heighest ground point
				j continueCollisionWithGround			# if not then move to the next coordinate
				greaterThanY:					# if it is then
					blt	$a1, $s3, lessThanY		# check if the y-coord is less than the lowest ground point
					j	continueCollisionWithGround	# if not then move to the next coordinate
					lessThanY:				# if it is then
						jal	KillBird		# kill bird
						j	deadMain		# move to death screen from main
		continueCollisionWithGround:		
		# ------------------------
		addi 	$s6, $s6, 4		# iterate over the counter by 4 to move the next coordinate
		j 	forCollisionWithGround 	# loop back to drawBird
	endCollisionWithGround:
		la $ra, ($s4)
		jr $ra
	
##################################################################
# CheckCollisionWithGround Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
CheckCollisionWithGround2:
	lw	$s0, 0($t8)		# width 1
	lw	$s1, 8($t8)		# width 2
	lw	$s2, 4($t8)		# height 1
	lw	$s3, 20($t8)		# height 2
	la 	$s4, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s5, birdBytesCount		# load the number of bytes we need to loop over
	loopInitCollisionWithGround2:
		li 	$s6, 0
	forCollisionWithGround2:
		sub 	$a0, $s6, $s5
		beq 	$a0, 0, endCollisionWithGround2
		
		# main body of code ------
		lw 	$a0, birdPos2($s6) 	# loads the x-coordinate into $a0
		addi	$s6, $s6, 4		# moving to the y-coord
		lw 	$a1, birdPos2($s6) 	# loads the y-coordinate into $a1
		# check if in ground
		bgt	$a0, $s0, greaterThanX2					# check if the x-coord is greater than the farthest left ground point
		j	continueCollisionWithGround2				# if not then move to the next coordinate
		greaterThanX2:							# if it is then 
			blt	$a0, $s1, lessThanX2				# check if the x-coord is less than the farthest right ground point
			j	continueCollisionWithGround2			# if not then move to the next coordinate
			lessThanX2:						# if it is then
				bgt	$a1, $s2, greaterThanY2			# check if the y-coord is greater than the heighest ground point
				j continueCollisionWithGround2			# if not then move to the next coordinate
				greaterThanY2:					# if it is then
					blt	$a1, $s3, lessThanY2		# check if the y-coord is less than the lowest ground point
					j	continueCollisionWithGround2	# if not then move to the next coordinate
					lessThanY2:				# if it is then
						jal	KillBird		# kill bird
						j	deadMain		# move to death screen from main
		continueCollisionWithGround2:		
		# ------------------------
		addi 	$s6, $s6, 4		# iterate over the counter by 4 to move the next coordinate
		j 	forCollisionWithGround2 	# loop back to drawBird
	endCollisionWithGround2:
		la $ra, ($s4)
		jr $ra
	
##################################################################
# KillBird Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
KillBird:
	lw $a0, Yellow
	sw $a0, BirdColor
	li $a0, 0
	sw $a0, birdAlive
	jr $ra

##################################################################
# GenRandom Function
# $a1 -> Max
# $a2 -> Min
##################################################################
# returns $v0 -> random number between min and max
##################################################################
GenRandom:
	li $v0, 42
	syscall
    	add $a0, $a0, $a2	#Here you add the lowest bound
    	move $v0, $a0
	jr $ra
	
##################################################################
# DrawBirdPrevPos Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawBirdPrevPos:
	la $s3, ($ra) 				# load the register address to which we need to leave and return to the main function
	lw $s2, birdBytesCount			# load the number of bytes we need to loop over
	loopInitDrawBirdPrevPos:
		li 	$s0, 0
	drawBirdPrevPos:
		sub 	$s1, $s0, $s2
		beq 	$s1, 0, endDrawBirdPrevPos
		
		# main body of code ------
		lw 	$a0, birdPos($s0) 	# loads the x-coordinate into $a0
		addi 	$s0, $s0, 4 		# iterate over to the next element in the array
		lw 	$a1, birdPos($s0) 	# loads the y-coordinate into $a1
		
		jal 	CoordinateToAddress 	# call to get the display address from the coordinates
		move 	$a0, $v0 		# move the address into $a0
		
		lw 	$a1, backGroundColor	# loads the color yellow in $a1
		
		jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
		# ------------------------
		addi 	$s0, $s0, 4		# iterate over the counter by sizeof(int)
		j 	drawBirdPrevPos 		# loop back to drawBird
	endDrawBirdPrevPos:
		la 	$ra, ($s3)
		jr 	$ra

##################################################################
# DrawBirdPrevPos Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawBirdPrevPos2:
	la $s3, ($ra) 				# load the register address to which we need to leave and return to the main function
	lw $s2, birdBytesCount			# load the number of bytes we need to loop over
	loopInitDrawBirdPrevPos2:
		li 	$s0, 0
	drawBirdPrevPos2:
		sub 	$s1, $s0, $s2
		beq 	$s1, 0, endDrawBirdPrevPos2
		
		# main body of code ------
		lw 	$a0, birdPos2($s0) 	# loads the x-coordinate into $a0
		addi 	$s0, $s0, 4 		# iterate over to the next element in the array
		lw 	$a1, birdPos2($s0) 	# loads the y-coordinate into $a1
		
		jal 	CoordinateToAddress 	# call to get the display address from the coordinates
		move 	$a0, $v0 		# move the address into $a0
		
		lw 	$a1, backGroundColor	# loads the color yellow in $a1
		
		jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
		# ------------------------
		addi 	$s0, $s0, 4		# iterate over the counter by sizeof(int)
		j 	drawBirdPrevPos2 		# loop back to drawBird
	endDrawBirdPrevPos2:
		la 	$ra, ($s3)
		jr 	$ra

##################################################################
# InitPipes Function
# $a0 -> NULL
# $a1 -> NULL
# $a3 -> bottom pipe array
# $s6 -> top pipe array
##################################################################
# returns $v0 -> NULL
##################################################################
InitPipes:
	la	$s6, ($ra)
	lw	$s1, minTopPipeHeight
	lw	$s2, pipesDistance
	# bottom pipe generate the 4 coords
	# generate height of pipe-----------------------
	add	$a2, $s1, $s2
	sub	$a1, $t3, $t4
	sub	$a1, $a1, $s1
	sub	$a1, $a1, $a2
	jal 	GenRandom
	move	$s3, $v0		# store the height for the bottom pipe in $s3
	la	$s4, ($s3)
	# top-left coord
	lw	$a2, pipeThickness
	sub	$a2, $t2, $a2
	sw	$a2, 0($t6)
	sw	$s3, 4($t6)
	# top-right coord
	sw	$t2, 8($t6)
	sw	$s3, 12($t6)
	# bottom-left coord
	lw	$a2, pipeThickness
	sub	$a2, $t2, $a2
	sw	$a2, 16($t6)
	sub	$s3, $t3, $t4
	sw	$s3, 20($t6)
	# bottom-right coord
	sw	$t2, 24($t6)
	sub	$s3, $t3, $t4
	sw	$s3, 28($t6)
	# calculate distance from bottom pipe------------
	sub	$a1, $s4, $s2
	li	$s3, 0
	# top pipe generate the 4 coords
	# top-left coord
	lw	$a2, pipeThickness
	sub	$a2, $t2, $a2
	sw	$a2, 0($t7)
	sw	$s3, 4($t7)
	# top-right coord
	sw	$t2, 8($t7)
	sw	$s3, 12($t7)
	# bottom-left coord
	lw	$a2, pipeThickness
	sub	$a2, $t2, $a2
	sw	$a2, 16($t7)
	sw	$a1, 20($t7)
	# bottom-right coord
	sw	$t2, 24($t7)
	sw	$a1, 28($t7)
	la	$ra, ($s6)
	jr 	$ra

##################################################################
# DrawPipe Function
# $a0 -> NULL
# $a1 -> NULL
##################################################################
# returns $v0 -> NULL
##################################################################
DrawPipe:
	la	$a3, 0($ra)
	lw	$s0, 0($t6)
	lw	$s1, 8($t6)
	lw	$s5, 20($t6)
	lw	$s6, 20($t7)
	whileDrawPipe1X:
		sub	$a0, $s0, $s1
		beq	$a0, 0, endDrawPipe1X
		
		#-------------------------
		lw	$s4, 4($t6)
		whileDrawPipe1Y:
			sub	$a0, $s5, $s4
			beq	$a0, 0, endDrawPipe1Y
			
			#-------------------------
			la	$a0, ($s0)		# loads the x-coordinate into $a0
			la	$a1, ($s4)		# loads the y-coordinate into $a1
			jal 	CoordinateToAddress 	# call to get the display address from the coordinates
			move 	$a0, $v0 		# move the address into $a0
			lw 	$a1, Green		# loads the color orange in $a1
			jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
			#-------------------------
			
			addi	$s4, $s4, 1
			j	whileDrawPipe1Y
		endDrawPipe1Y:
		lw	$s7, 4($t7)
		whileDrawPipe2Y:
			sub	$a0, $s6, $s7
			beq	$a0, 0, endDrawPipe2Y
			
			#-------------------------
			la	$a0, ($s0)		# loads the x-coordinate into $a0
			la	$a1, ($s7)		# loads the y-coordinate into $a1
			jal 	CoordinateToAddress 	# call to get the display address from the coordinates
			move 	$a0, $v0 		# move the address into $a0
			lw 	$a1, Green		# loads the color orange in $a1
			jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
			#-------------------------
			
			addi	$s7, $s7, 1
			j	whileDrawPipe2Y
		endDrawPipe2Y:
		#-------------------------
		
		addi	$s0, $s0, 1
		j	whileDrawPipe1X
	endDrawPipe1X:
		la	$ra, ($a3)
		jr	$ra

##################################################################
# DrawPipe Function
# $a0 -> NULL
# $a1 -> NULL
# $a3 -> bottom pipe
# $s6 -> top pipe
##################################################################
# returns $v0 -> NULL
##################################################################
DrawPrevPipePos:
	la	$a3, 0($ra)
	lw	$s0, 0($t6)
	lw	$s1, 8($t6)
	lw	$s5, 20($t6)
	lw	$s6, 20($t7)
	whileDrawPrevPipePos1X:
		sub	$a0, $s0, $s1
		beq	$a0, 0, endDrawPrevPipePos1X
		
		#-------------------------
		lw	$s4, 4($t6)
		whileDrawPrevPipePos1Y:
			sub	$a0, $s5, $s4
			beq	$a0, 0, endDrawPrevPipePos1Y
			
			#-------------------------
			la	$a0, ($s0)		# loads the x-coordinate into $a0
			la	$a1, ($s4)		# loads the y-coordinate into $a1
			jal 	CoordinateToAddress 	# call to get the display address from the coordinates
			move 	$a0, $v0 		# move the address into $a0
			lw 	$a1, backGroundColor	# loads the color orange in $a1
			jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
			#-------------------------
			
			addi	$s4, $s4, 1
			j	whileDrawPrevPipePos1Y
		endDrawPrevPipePos1Y:
		lw	$s7, 4($t7)
		whileDrawPrevPipePos2Y:
			sub	$a0, $s6, $s7
			beq	$a0, 0, endDrawPrevPipePos2Y
			
			#-------------------------
			la	$a0, ($s0)		# loads the x-coordinate into $a0
			la	$a1, ($s7)		# loads the y-coordinate into $a1
			jal 	CoordinateToAddress 	# call to get the display address from the coordinates
			move 	$a0, $v0 		# move the address into $a0
			lw 	$a1, backGroundColor	# loads the color orange in $a1
			jal 	DrawPixel		# call to draw the bird on the given $a0 position and $a1 color
			#-------------------------
			
			addi	$s7, $s7, 1
			j	whileDrawPrevPipePos2Y
		endDrawPrevPipePos2Y:
		#-------------------------
		
		addi	$s0, $s0, 1
		j	whileDrawPrevPipePos1X
	endDrawPrevPipePos1X:
		la	$ra, ($a3)
		jr	$ra

##################################################################
# DrawBye Function
##################################################################
# returns $v0 -> NULL
##################################################################
DrawBye:
				lw 	$a1, Red 		# loads the color red in $a1
				lw $t0, displayAddress	# $t0 stores the base address for display
				sw     $a1, 1040($t0)
				sw     $a1, 1296($t0)
				sw     $a1, 1552($t0)
				sw     $a1, 1808($t0)
				sw     $a1, 2064($t0)
				sw     $a1, 2320($t0)
				sw     $a1, 2576($t0)
				sw     $a1, 2832($t0)
				sw     $a1, 3088($t0)
				sw     $a1, 3344($t0)
				sw     $a1, 3600($t0)
				sw     $a1, 3856($t0)
				
				sw     $a1, 3860($t0)
				sw     $a1, 3864($t0)
				sw     $a1, 3868($t0)
				sw     $a1, 3872($t0)
				sw     $a1, 3876($t0)
				
				sw     $a1, 3876($t0)
				sw     $a1, 3620($t0)
				sw     $a1, 3364($t0)
				sw     $a1, 3108($t0)
				sw     $a1, 2852($t0)
				
				sw     $a1, 2848($t0)
				sw     $a1, 2844($t0)
				sw     $a1, 2840($t0)
				sw     $a1, 2836($t0)
				# Y #
				sw     $a1, 2608($t0)
				sw     $a1, 2864($t0)
				sw     $a1, 3120($t0)
				sw     $a1, 3376($t0)
				sw     $a1, 3632($t0)
				sw     $a1, 3888($t0)
				
				sw     $a1, 2348($t0)
				sw     $a1, 2088($t0)
				sw     $a1, 1828($t0)
				sw     $a1, 1568($t0)
				
				
				sw     $a1, 2356($t0)
				sw     $a1, 2104($t0)
				sw     $a1, 1852($t0)
				sw     $a1, 1600($t0)
				
				#   E   #
				sw     $a1, 1108($t0)
				sw     $a1, 1112($t0) 
				sw     $a1, 1116($t0) 
				sw     $a1, 1120($t0)
				sw     $a1, 1124($t0)
				###
				sw     $a1, 1364($t0)
				sw     $a1, 1620($t0)
				sw     $a1, 1876($t0)
				sw     $a1, 2132($t0)
				
				sw     $a1, 2388($t0) 
				sw     $a1, 2392($t0)
				sw     $a1, 2396($t0)
				sw     $a1, 2400($t0)
				sw     $a1, 2404($t0)
				###
				sw     $a1, 2644($t0)
				sw     $a1, 2900($t0)
				sw     $a1, 3156($t0)
				sw     $a1, 3412($t0)
				sw     $a1, 3668($t0)
				sw     $a1, 3924($t0) 
				sw     $a1, 3928($t0)
				sw     $a1, 3932($t0)
				sw     $a1, 3936($t0)
				sw     $a1, 3940($t0)
				jr	   $ra

##################################################################
# UpdatePipesLeft Function
# $a0 -> NULL
# $a1 -> NULL
# $a3 -> bottom pipe
# $s6 -> top pipe 
##################################################################
# returns $v0 -> NULL
##################################################################		
UpdatePipesLeft:
	lw	$a0, shiftDistance
	lw	$a1, 0($t6)		# width 1
	sub	$a1, $a1, $a0
	sw	$a1, 0($t6)
	lw	$a1, 8($t6)		# width 2
	sub	$a1, $a1, $a0
	sw	$a1, 8($t6)
	lw	$a1, 16($t6)		# width 3
	sub	$a1, $a1, $a0
	sw	$a1, 16($t6)
	lw	$a1, 24($t6)		# width 4
	sub	$a1, $a1, $a0
	sw	$a1, 24($t6)
	lw	$a1, 0($t7)		# width 1
	sub	$a1, $a1, $a0
	sw	$a1, 0($t7)
	lw	$a1, 8($t7)		# width 2
	sub	$a1, $a1, $a0
	sw	$a1, 8($t7)
	lw	$a1, 16($t7)		# width 3
	sub	$a1, $a1, $a0
	sw	$a1, 16($t7)
	lw	$a1, 24($t7)		# width 4
	sub	$a1, $a1, $a0
	sw	$a1, 24($t7)
	jr 	$ra

##################################################################
# UpdatePipesLeft Function
# $a0 -> NULL
# $a1 -> NULL
# $a3 -> bottom pipe
# $s6 -> top pipe 
##################################################################
# returns $v0 -> NULL
##################################################################
CheckCollisionWithPipes:
	li	$s6, 1
	lw	$s0, 0($t6)		# 1 width 1
	lw	$s1, 8($t6)		# 1 width 2
	lw	$s2, 4($t6)		# 1 height 1
	lw	$s3, 20($t6)		# 1 height 2
	la 	$a3, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s4, birdBytesCount		# load the number of bytes we need to loop over
	loopInitCollisionWithPipe1:
		li 	$s5, 0
	forCollisionWithPipe1:
		sub 	$a0, $s5, $s4
		beq 	$a0, 0, endCollisionWithPipe1
		
		# main body of code ------
		lw 	$a0, birdPos($s5) 	# loads the x-coordinate into $a0
		addi	$s5, $s5, 4		# moving to the y-coord
		lw 	$a1, birdPos($s5) 	# loads the y-coordinate into $a1
		# check if in ground
		bgt	$a0, $s0, greaterPipeThanX					# check if the x-coord is greater than the farthest left ground point
		j	continueCollisionWithPipe1				# if not then move to the next coordinate
		greaterPipeThanX:							# if it is then 
			blt	$a0, $s1, lessPipeThanX				# check if the x-coord is less than the farthest right ground point
			j	continueCollisionWithPipe1			# if not then move to the next coordinate
			lessPipeThanX:						# if it is then
				bgt	$a1, $s2, greaterPipeThanY			# check if the y-coord is greater than the heighest ground point
				j continueCollisionWithPipe1			# if not then move to the next coordinate
				greaterPipeThanY:					# if it is then
					blt	$a1, $s3, lessPipeThanY		# check if the y-coord is less than the lowest ground point
					j	continueCollisionWithPipe1	# if not then move to the next coordinate
					lessPipeThanY:				# if it is then
						jal	KillBird		# kill bird
						j	deadMain		# move to death screen from main
		continueCollisionWithPipe1:
		# ------------------------
		addi 	$s5, $s5, 4		# iterate over the counter by 4 to move the next coordinate
		j 	forCollisionWithPipe1 	# loop back to drawBird
	endCollisionWithPipe1:
		beq	$s6, 0,	trueEnd
		li	$s5, 0
		li	$s6, 0
		lw	$s0, 0($t7)		# 1 width 1
		lw	$s1, 8($t7)		# 1 width 2
		lw	$s2, 4($t7)		# 1 height 1
		lw	$s3, 20($t7)		# 1 height 2
		j	forCollisionWithPipe1
		trueEnd:
			la $ra, ($a3)
			jr $ra

##################################################################
# UpdatePipesLeft Function
# $a0 -> NULL
# $a1 -> NULL
# $a3 -> bottom pipe
# $s6 -> top pipe 
##################################################################
# returns $v0 -> NULL
##################################################################
CheckCollisionWithPipes2:
	li	$s6, 1
	lw	$s0, 0($t6)		# 1 width 1
	lw	$s1, 8($t6)		# 1 width 2
	lw	$s2, 4($t6)		# 1 height 1
	lw	$s3, 20($t6)		# 1 height 2
	la 	$a3, ($ra) 			# load the register address to which we need to leave and return to the main function
	lw 	$s4, birdBytesCount		# load the number of bytes we need to loop over
	loopInitCollisionWithPipe12:
		li 	$s5, 0
	forCollisionWithPipe12:
		sub 	$a0, $s5, $s4
		beq 	$a0, 0, endCollisionWithPipe12
		
		# main body of code ------
		lw 	$a0, birdPos2($s5) 	# loads the x-coordinate into $a0
		addi	$s5, $s5, 4		# moving to the y-coord
		lw 	$a1, birdPos2($s5) 	# loads the y-coordinate into $a1
		# check if in ground
		bgt	$a0, $s0, greaterPipeThanX2					# check if the x-coord is greater than the farthest left ground point
		j	continueCollisionWithPipe12				# if not then move to the next coordinate
		greaterPipeThanX2:							# if it is then 
			blt	$a0, $s1, lessPipeThanX2				# check if the x-coord is less than the farthest right ground point
			j	continueCollisionWithPipe12			# if not then move to the next coordinate
			lessPipeThanX2:						# if it is then
				bgt	$a1, $s2, greaterPipeThanY2			# check if the y-coord is greater than the heighest ground point
				j continueCollisionWithPipe12			# if not then move to the next coordinate
				greaterPipeThanY2:					# if it is then
					blt	$a1, $s3, lessPipeThanY2		# check if the y-coord is less than the lowest ground point
					j	continueCollisionWithPipe12	# if not then move to the next coordinate
					lessPipeThanY2:				# if it is then
						jal	KillBird		# kill bird
						j	deadMain		# move to death screen from main
		continueCollisionWithPipe12:
		# ------------------------
		addi 	$s5, $s5, 4		# iterate over the counter by 4 to move the next coordinate
		j 	forCollisionWithPipe12 	# loop back to drawBird
	endCollisionWithPipe12:
		beq	$s6, 0,	trueEnd2
		li	$s5, 0
		li	$s6, 0
		lw	$s0, 0($t7)		# 1 width 1
		lw	$s1, 8($t7)		# 1 width 2
		lw	$s2, 4($t7)		# 1 height 1
		lw	$s3, 20($t7)		# 1 height 2
		j	forCollisionWithPipe12
		trueEnd2:
			la $ra, ($a3)
			jr $ra
##################################################################
# LoopSky Function
##################################################################
# returns $v0 -> NULL
##################################################################
LoopSky:
	la	$a3, ($ra)
	lw	$s7, timer
	la	$a0, ($s7)
	bgt	$s7, 64, reset
	continueAfterReset:
	addi	$s7, $s7, 1
	li	$s2, 4
	div	$s7, $s2
	mfhi	$a0
	beq	$a0, 0, changeSky
	continueAfter: 
		sw	$s7, timer
		la	$ra, ($a3)
		jr	$ra
	changeSky:
		lw	$a1, skyColorArray($s7)
		sw	$a1, backGroundColor
		j 	continueAfter
	reset:
		li	$s7, 0
		j 	continueAfterReset

ShiftDifficulty:
	lw	$s7, difficulty
	la	$a0, ($s7)
	bgt	$s7, 32, Max
	addi	$s7, $s7, 1
	li	$s2, 4
	div	$s7, $s2
	mfhi	$a0
	beq	$a0, 0, shift
	continueAfterShift: 
		sw	$s7, difficulty
		jr	$ra
	shift:
		lw	$a1, shiftDistance
		addi	$a1, $a1, 1
		sw	$a1, shiftDistance
		lw $a0, shiftDistance
		li $v0, 1
		syscall
		j 	continueAfterShift
	Max:
	jr	$ra
LoadAddress:
	lw	$t2, screenWidth
	lw	$t3, screenHeight
	lw	$t4, groundHeight
	la	$t5, birdPos
	la	$t6, pipeArray1
	la	$t7, pipeArray2
	la	$t8, groundArray
	jr	$ra
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
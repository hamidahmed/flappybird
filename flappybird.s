# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
	displayAddress:	.word	0x10008000
	newline: .asciiz "\n"
	birdPos: .word 2048, 1920, 2176
	
.text
	lw $t0, displayAddress	# $t0 stores the base address for display
	li $t1, 0xFFE945	# $t1 stores the yellow colour code
	li $t2, 0x2DA617	# $t2 stores the green colour code
	li $t3, 0x9AFCF6	# $t3 stores the blue colour code
	li $t4, 1		# $t4 stores if the bird is still alive
	
	#sw $t1, 0($t0)	 # paint the first (top-left) unit red. 
	#sw $t2, 4($t0)	 # paint the second unit on the first row green. Why $t0+4?
	#sw $t3, 8($t0)	 # paint the second unit on the first row green. Why $t0+4?
	#sw $t2, 4092($t0) # paint the first unit on the second row blue. Why +128?
	
	LOOPINIT:
		li $s0, 0
	WHILE:
		subi $s1, $s0, 4092
		bgtz $s1, DONE
		
		# prints 01234...(N-1), Hence loops N times
		#li $v0, 1
		#move $a0, $s0
		#syscall
		
		#main body------------------------------------
		sw $t3, 0($gp)
		#---------------------------------------------
		
		addi $s0, $s0, 4
		addi $gp, $gp, 4
		
		j WHILE
	DONE:	
		j Exit
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall

# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#j = $s0
.data
	displayAddress:	.word	0x10008000
.text
	lw $t0, displayAddress	# $t0 stores the base address for display
	li $t1, 0xff0000	# $t1 stores the red colour code
	li $t2, 0xffff00	# $t2 stores the yellow colour code
	li $t3, 0x0000ff	# $t3 stores the blue colour code
	li $t4, 0x86c5da         #stores the light blue color
	
	
	li $s0,0
	loop:
	bgt $s0,1023,Exit
	addi $s0,$s0,1
	sw $t4, ($t0)    #paint the Display
	addiu $t0,$t0,4
	j loop
	
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
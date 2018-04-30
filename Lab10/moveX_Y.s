# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# memory-mapped I/O
VELOCITY                = 0xffff0010
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

TIMER                   = 0xffff001c

PRINT_INT_ADDR          = 0xffff0080
PRINT_FLOAT_ADDR        = 0xffff0084
PRINT_HEX_ADDR          = 0xffff0088

ASTEROID_MAP            = 0xffff0050
COLLECT_ASTEROID        = 0xffff00c8

GET_CARGO               = 0xffff00c4

# interrupt constants
BONK_INT_MASK           = 0x1000
BONK_ACK                = 0xffff0060

TIMER_INT_MASK          = 0x8000
TIMER_ACK               = 0xffff006c


.data
three:	.float	3.0
five:	.float	5.0
PI:	.float	3.141592
F180:	.float  180.0

.align 2
asteroid_map: .space 1024

.text
main:
    	li	$t4, BONK_INT_MASK
	or	$t4, $t4, 1
	mtc0	$t4, $12

	la	$t0, asteroid_map
	sw	$t0, ASTEROID_MAP

	sub	$sp, $sp, 32
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)			#s1 = x_bot
	sw	$s2, 12($sp)			#s2 = y_bot
	sw	$s3, 16($sp)				#s3 = x_asteroid
	sw	$s4, 20($sp)			#s4 = y_asteroid
	sw	$s5, 24($sp)			#s5 = ratio = (y_ast- y_bot)/(x_ast-x_bot)
	sw	$s6, 28($sp)			#s6 = angle
	sw	$s7, 32($sp)			#s7 = current Vg

	li	$s0, 0				#s0 = i = 0
for_asteroid_length:
	bgt	$s0, 50, complete_100		#seatch through each asteroid	
	lw	$t1, GET_CARGO			#t1 = points in cargo
#	bge	$t1, 100, complete_100		#keep going until 100 points
	li	$s5, 0	
while_not_there:
	lw	$t4, ANGLE
	lw	$t5, VELOCITY
	lw	$s1, BOT_X($0)			#s1 = x_bot
	lw	$s2, BOT_Y($0)			#s2 = y_bot
	la	$t0, asteroid_map
	mul	$t2, $s0, 8
	add	$s3, $t0, 4
	lw	$t7, 0($s3)
	add	$t7, $t2, $s3
	lw	$s3, 0($t7)
	move	$s4, $s3
	srl	$s3, $s3, 16		#s3 = ((asteroidMap.asteroids)[i]).x
	sll	$s4, $s4, 16
	srl	$s4, $s4, 16		#s4 = ((asteroidMap.asteroids)[i]).y
	sub	$t2, $s1, $s3			
	sub	$t1, $s2, $s4
	or	$t2, $t2, $t1
	beq	$t2, $0, on_target	#stop moving when on the asteroid location
	lw	$s5, 4($t7)		#load asteroid points
	li	$t1, 10
	ble	$s5, 10, next		#if points<10 try another
	#sub	$s7, $s1, 40
	div	$s7, $s1, -60
	add	$s7, $s7, 5		#s7 = vg = -5 + (x)/60
	li	$t1, 1

	beq	$s2, $s4 move_xdir
	#beq	$s5, $t1, move_ydir

	sub	$t8, $s4, $s2		#t8 = Y_distance = Y_ast - Y_bot
	blt	$t8, $0, y_up		# if t8 is neg, bot moves up
	li	$s5, 2
	j	got_y
y_up:	move	$a0, $s7
	li	$s5, -2
got_y:	
	move	$a0, $s7
	move	$a1, $s5
	jal 	euclidean_dist
	sw	$s7, VELOCITY		#velocity = sqrt(vg^2 + 5^2)
	move	$a0, $s7
	move	$a1, $s5
	jal	sb_arctan
	move	$s6, $v0
	sw	$v0, ANGLE
	li	$t1, 1
	sw	$t1, ANGLE_CONTROL	#absolute angle
	j	while_not_there

move_xdir:
	sub	$t8, $s3, $s1		#t8 = x_distance = x_ast - x_bot
	bgt	$t8, $0, x_right	# if t8 is neg, bot moves left
	li	$s6, 180
	sw	$s6, ANGLE
	sw	$t1, 0xffff0018($0)	#absolute angle = 180
	li	$t2, 2
	sw	$t2, VELOCITY		#velocity = Vg + 2
	j	while_not_there
x_right: sw	$0, ANGLE
	li	$t1, 1
	sw	$t1, 0xffff0018($0)	#absolute angle = 0
	add	$t2, $s7, 3
	sw	$t2, VELOCITY		#velocity = 3
	j	while_not_there	

on_target:
	sw	$v0, VELOCITY		#velocity = 2
	sw	$0, ANGLE
	sw	$t1, ANGLE_CONTROL	#absolute angle = 0

	sw	$t1, COLLECT_ASTEROID

#update asteroid_maps
	sw	$0, 0($t7)		#asteroid points = 0
	sw	$0, 4($t7)		#asteroid x_pos/y_pos = 0

next:
	add	$s0, $s0, 1
	j	for_asteroid_length
	jal	box_step
complete_100:
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	lw	$s7, 32($sp)	
	add	$sp, $sp, 32

	# note that we infinite loop to avoid stopping the simulation early
        j       main


sb_arctan:
	li	$v0, 0		# angle = 0;

	abs	$t0, $a0	# get absolute values
	abs	$t1, $a1
	ble	$t1, $t0, no_TURN_90	  

	## if (abs(y) > abs(x)) { rotate 90 degrees }
	move	$t0, $a1	# int temp = y;
	neg	$a1, $a0	# y = -x;      
	move	$a0, $t0	# x = temp;    
	li	$v0, 90		# angle = 90;  

no_TURN_90:
	bgez	$a0, pos_x 	# skip if (x >= 0)

	## if (x < 0) 
	add	$v0, $v0, 180	# angle += 180;

pos_x:
	mtc1	$a0, $f0
	mtc1	$a1, $f1
	cvt.s.w $f0, $f0	# convert from ints to floats
	cvt.s.w $f1, $f1
	
	div.s	$f0, $f1, $f0	# float v = (float) y / (float) x;

	mul.s	$f1, $f0, $f0	# v^^2
	mul.s	$f2, $f1, $f0	# v^^3
	l.s	$f3, three	# load 3.0
	div.s 	$f3, $f2, $f3	# v^^3/3
	sub.s	$f6, $f0, $f3	# v - v^^3/3

	mul.s	$f4, $f1, $f2	# v^^5
	l.s	$f5, five	# load 5.0
	div.s 	$f5, $f4, $f5	# v^^5/5
	add.s	$f6, $f6, $f5	# value = v - v^^3/3 + v^^5/5

	l.s	$f8, PI		# load PI
	div.s	$f6, $f6, $f8	# value / PI
	l.s	$f7, F180	# load 180.0
	mul.s	$f6, $f6, $f7	# 180.0 * value / PI

	cvt.w.s $f6, $f6	# convert "delta" back to integer
	mfc1	$t0, $f6
	add	$v0, $v0, $t0	# angle += delta

	jr 	$ra

euclidean_dist:
	mul	$a0, $a0, $a0	# x^2
	mul	$a1, $a1, $a1	# y^2
	add	$v0, $a0, $a1	# x^2 + y^2
	mtc1	$v0, $f0
	cvt.s.w	$f0, $f0	# float(x^2 + y^2)
	sqrt.s	$f0, $f0	# sqrt(x^2 + y^2)
	cvt.w.s	$f0, $f0	# int(sqrt(...))
	mfc1	$v0, $f0
	jr	$ra

box_step:
	li	$a0, 10
	jal	set_speed

	li	$a0, 0			# face EAST
	jal	set_orientation
	jal	wait

	li	$a0, 90			# face SOUTH
	jal	set_orientation
	jal	wait

	li	$a0, 180		# face WEST
	jal	set_orientation
	jal	wait

	li	$a0, 270		# face NORTH
	jal	set_orientation
	jal	wait

	jr	$ra

set_orientation:
	sw	$a0, 0xffff0014($zero) 
	li	$t0, 1
	sw	$t0, 0xffff0018($zero)		# say it is an absolute angle
	jr	$ra

wait:
	li	$a0, 10000		# select a wait amount

wait_loop:	
	sub	$a0, $a0, 1
	bgt	$a0, $zero, wait_loop

	jr	$ra

set_speed: 
 	sw	$a0, 0xffff0010($zero)		# set velocity
	jr	$ra

################################################################################

#interrupts
.kdata
chunkIH:	.space 8

unhandled_str:	.asciiz  "Unhandle interrupt"

.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at
.set at
	sw	$k0, chunkIH
	sw	$a0, 0($k0)
interrupt_dispatch:
	mfc0	$k0, $13
	beq	$a0, $0, done
	and	$a0, $k0, BONK_INT_MASK
	bne	$a0, 0, bonk_interrupt
bonk_interrupt:
	lw	$t6, ANGLE($0)
	add	$t6, $t6 180
	sw	$t6, ANGLE($0)
	j	interrupt_dispatch
done:
	lw	$k0, chunkIH
	lw	$a0, 0($k0)
	.set noat
	move	$at, $k1
	.set at
	eret


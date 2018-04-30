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


.align 2
asteroid_map: .space 1024

.text
main:
        li	$t4, BONK_INT_MASK
	or	$t4, $t4, 1
	mtc0	$t4, $12

	la	$t0, asteroid_map
	sw	$t0, ASTEROID_MAP

	sub	$sp, $sp, 28
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)		#s1 = x_bot
	sw	$s2, 12($sp)		#s2 = y_bot
	sw	$s3, 16($sp)		#s3 = x_asteroid
	sw	$s4, 20($sp)		#s4 = y_asteroid
	sw	$s5, 24($sp)		#s5 = ratio = (y_ast- y_bot)/(x_ast-x_bot)
	sw	$s6, 28($sp)		#s6 = angle

	li	$s0, 0				#s0 = i = 0
for_asteroid_length:
	#lw	$t0, ASTEROID_MAP($0)		#t0 = asteroid_map.length
	bgt	$s0, 50, for_end		#seatch through each asteroid	

	lw	$t0, GET_CARGO			#t0 = points in cargo
	bge	$t0, 100, complete_100		#keep going until 100 points
	
while_not_there:
	lw	$s1, BOT_X($0)			#s1 = x_bot
	lw	$s2, BOT_Y($0)			#s2 = y_bot
	mul	$t0, $s0, 8
	la	$t1, ASTEROID_MAP
	add	$s3, $t1, 4
	add	$t0, $t0, $s3
	add	$t7, $t0, 4
	#lh	$s3, 0($t0)			#s3 = ((asteroidMap.asteroids)[i]).x
	#lh	$s4, 2($t0)			#s4 = ((asteroidMap.asteroids)[i]).y
	lw	$s3, 0($t0)
	move	$s4, $s3
	sll	$s3, $s3, 16
	srl	$s4, $s4, 16
	sll	$s4, $s4, 16
	sub	$t0, $s1, $s3			
	sub	$t1, $s2, $s4
	or	$t0, $t0, $t1
	beq	$t0, $0, there			#stop moving when on the asteroid location
	j	get_angle

got_angle:
	sw	$s6, ANGLE_CONTROL($0)
	li	$t1, 1
	sw	$t1, 0xffff0018($0)
	j	set_velocity
got_velocity:
	sw	$t1, VELOCITY($0)
there:
	sw	$0, ANGLE_CONTROL($0)		#stop motion by rotating to right
	li	$t1, 1
	sw	$t1, 0xffff0018($0)
	sub	$t1, $s1, 40
	div	$t1, $t1, 60
	sub	$t1, $t1, 5
	sw	$t1, VELOCITY($0)		#set velocity in x-dir to overcome 
	sw	$t0, COLLECT_ASTEROID($0)	#collect asteroid
	sw	$0, 0($t7)

	add	$s0, $s0, 1
	j	for_asteroid_length
for_end:

complete_100:
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	add	$sp, $sp, 28

	# note that we infinite loop to avoid stopping the simulation early
        j       main

#other functions
set_velocity:
	# for constant velocity anywhere v = sqrt(25 + vg^2 + vg*25/(1+ratio^2)) however the square root does not exist	
	sub	$t1, $s1, 40
	div	$t1, $t1, 60
	sub	$t1, $t1, 5			# t1 = velocity from supernova
	ble	$t8, $0, x_left		# find if x-direction is left
	sub	$t2, $0, $t1
	add	$t1, $t2, 6
	j	got_velocity
x_left:	
	li	$t1, 2
	j	got_velocity

get_angle:
	sub	$t8, $s3, $s1			#t10 = x-direction movement
	sub 	$t9, $s4, $s2			#t11 = y-direction movement
	div	$s5, $t8, $t9			#s5 = ratio = (y_ast- y_bot)/(x_ast-x_bot)
	li	$t3, 0
	li	$t4, 0
	li	$s6, 0				#s6 = angle = 0
	bge	$s2, $0, y_posi	
	li	$t3, 180			#t3 = a = 180 if y_bot is neg
y_posi:	bge	$s5, $0, x_posi			#t4 = b = 90 if x_bot is neg
	li	$t4, 90
x_posi:	abs	$t0, $s5			#t0 = |ratio|
	li.s	$f5, 0.2885
	mfc1	$t5, $f5
	bge	$t0, $t5, not_0
	add	$s6, $s6, $t3
	add	$s6, $s6, $t4			#s6 = angle = 0 + a + b
	j	got_angle
not_0:  li.s	$f5, 0.788675
	mfc1	$t5, $f5
	bge	$t0, $t5, not_30
	li	$s6, 30
	add	$s6, $s6, $t3
	add	$s6, $s6, $t4			#s6 = angle = 30 + a + b
	j	got_angle
not_30: li.s	$f5, 1.3666
	mfc1	$t5, $f5
	bge	$t0, $t5, not_60
	li	$s6, 60
	add	$s6, $s6, $t3
	add	$s6, $s6, $t4			#s6 = angle = 60 + a + b
	j	got_angle
not_60: li	$s6, 90
	add	$s6, $s6, $t3
	add	$s6, $s6, $t4			#s6 = angle = 90 + a + b
	j	got_angle

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
	lw	$t6, ANGLE_CONTROL($0)
	add	$t6, $t6 180
	sw	$t6, ANGLE_CONTROL($0)
	j	interrupt_dispatch
done:
	lw	$k0, chunkIH
	lw	$a0, 0($ko)
	.set noat
	move	$at, $k1
	.set at
	eret

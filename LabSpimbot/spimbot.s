# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# debug constants
PRINT_INT_ADDR              = 0xffff0080
PRINT_FLOAT_ADDR            = 0xffff0084
PRINT_HEX_ADDR              = 0xffff0088

# spimbot memory-mapped I/O
VELOCITY                    = 0xffff0010
ANGLE                       = 0xffff0014
ANGLE_CONTROL               = 0xffff0018
BOT_X                       = 0xffff0020
BOT_Y                       = 0xffff0024
OTHER_BOT_X                 = 0xffff00a0
OTHER_BOT_Y                 = 0xffff00a4
TIMER                       = 0xffff001c
SCORES_REQUEST              = 0xffff1018

ASTEROID_MAP                = 0xffff0050
COLLECT_ASTEROID            = 0xffff00c8

STATION_LOC                 = 0xffff0054
DROPOFF_ASTEROID            = 0xffff005c

GET_ENERGY                  = 0xffff00c0
GET_CARGO                   = 0xffff00c4

REQUEST_PUZZLE              = 0xffff00d0
SUBMIT_SOLUTION             = 0xffff00d4

THROW_PUZZLE                = 0xffff00e0
UNFREEZE_BOT                = 0xffff00e8
CHECK_OTHER_FROZEN          = 0xffff101c

# interrupt constants
BONK_INT_MASK               = 0x1000
BONK_ACK                    = 0xffff0060

TIMER_INT_MASK              = 0x8000
TIMER_ACK                   = 0xffff006c

REQUEST_PUZZLE_INT_MASK     = 0x800
REQUEST_PUZZLE_ACK          = 0xffff00d8

STATION_ENTER_INT_MASK      = 0x400
STATION_ENTER_ACK           = 0xffff0058

STATION_EXIT_INT_MASK       = 0x2000
STATION_EXIT_ACK            = 0xffff0064

BOT_FREEZE_INT_MASK         = 0x4000
BOT_FREEZE_ACK              = 0xffff00e4


.data
three:	.float	3.0
five:	.float	5.0
PI:	.float	3.141592
F180:	.float  180.0

lines:          .word   2       start_pos       end_pos
start_pos:      .word   2       100
end_pos:        .word   2       100

canvas: 	.word   0       0       0       canv
canv:   	.space  2000

solution:       .word   2       counts
counts:         .space  16

puzzle:  	.word	canvas	lines	data
data:		.space	1024

.align 2
asteroid_map: .space 1024
collect_asteroid: .space 8
dropoff_asteroids: .space 8
puzzle_ready:	.space 4
frozen:		.space 4

.text


main:
        sub	$sp, $sp, 4                    # allocate 20 byte stack frame
        sw	$ra, 0($sp)

        la      $t0, asteroid_map
        sw      $t0, ASTEROID_MAP

        # enable interrupts
	li	$t4, TIMER_INT_MASK	        # timer interrupt enable bit
	or	$t4, $t4, BONK_INT_MASK	# bonk interrupt bit
        or      $t4, $t4, STATION_ENTER_INT_MASK
        or      $t4, $t4, STATION_EXIT_INT_MASK
        or      $t4, $t4, REQUEST_PUZZLE_INT_MASK
        or      $t4, $t4, BOT_FREEZE_INT_MASK
	or	$t4, $t4, 1		# global interrupt enable
	mtc0	$t4, $12		# set interrupt mask (Status register)

	la	$t4, frozen
	lw	$t3, 0($t4)
	bne	$t3, 1, not_frozen
	sw	$0, 0($t4)
        la      $t0, puzzle
        lw      $a0, 0($t0)
	jal	solve_unfreeze

not_frozen:
        lw      $t0, GET_ENERGY
        li      $t1, 500
        bge     $t0, $t1, not_puzzle

        la      $t0, puzzle
        sw      $t0, REQUEST_PUZZLE

	la	$t4, puzzle_ready
	lw	$t3, 0($t4)
	bne	$t3, 1, not_puzzle
        sw	$t3, 0($t4)
	move	$a0, $t0 				#a0 = puzzle, a2 = solution
	la	$a2, solution
	jal	count_disjoint_regions
	lw	$t1, 4($a2)					#submitting
	lw	$t2, CHECK_OTHER_FROZEN		#t2 = 1 if other bot frozen
	beq	$t2, 1, no_throwing

	lw	$t2, SCORES_REQUEST
	srl	$t3, $t2, 30				#t3 = our score
	sll     $t2, $t2, 30				#t2 = other's score
	srl     $t2, $t2, 30
	bge	$t3, $t2, no_throwing
	sw	$a1, THROW_PUZZLE

no_throwing:
	sw	$t1, SUBMIT_SOLUTION
	sw	$0, 0($a2)				#zero solution struct
	sw	$0, 4($a2)

not_puzzle:
        li	$a0, 10
	sw	$a0, VELOCITY		# drive
        lw      $t0, BOT_X
        li      $t1, 60
        bge     $t0, $t1, cargo_gt
        li	$t0, 0			# ???
	sw	$t0, ANGLE		# ???
        li      $t2, 1
	sw	$t2, ANGLE_CONTROL	# ???
        j       mainl

cargo_gt:
        lw      $t5, GET_CARGO
        li      $t7, 100
        ble     $t5, $t7, rev_skip

        lw      $t0, BOT_X
        li      $t1, 150
        ble     $t0, $t1, no_follow

        lw      $t0, BOT_X
        lw      $t1, BOT_Y
        lw      $t3, STATION_LOC
        sll     $t4, $t3, 16
        srl     $t4, $t4, 16
        srl     $t3, $t3, 16
        sub     $a0, $t3, $t0
        sub     $a1, $t4, $t1
        jal     sb_arctan
        sw	$v0, ANGLE		# ???
        li      $t2, 1
	sw	$t2, ANGLE_CONTROL
        j       dropoff

no_follow:
        li	$t0, 0			# ???
        sw	$t0, ANGLE		# ???
        li      $t2, 1
        sw	$t2, ANGLE_CONTROL

dropoff:
        la      $t0, dropoff_asteroids
        sw      $t6, DROPOFF_ASTEROID

        j       mainl

rev_skip:
        lw      $t0, BOT_X
        li      $t1, 100
        lw      $t5, ANGLE
        beq     $t5, $0, skip_a_s
        move    $t6, $t5

skip_a_s:
        lw      $t0, BOT_X
        lw      $t1, BOT_Y
        lw      $t3, 0xffff0054($zero)
        sll     $t4, $t3, 16
        srl     $t4, $t4, 16
        srl     $t3, $t3, 16
        sub     $a0, $t3, $t0
        sub     $a1, $t4, $t1
        jal     sb_arctan
        sw	$v0, ANGLE		# ???
        li      $t2, 1
        sw	$t2, ANGLE_CONTROL

mainl:
        la      $t0, collect_asteroid
        sw      $t0, COLLECT_ASTEROID

        add	$sp, $sp, 4                    # allocate 20 byte stack frame
        lw	$ra, 0($sp)

        j       main

################################################################################

solve_unfreeze:
        sub	$sp, $sp, 12                                  # allocate 28 byte stack frame
        sw	$ra, 0($sp)
        sw      $a0, 4($sp)
        sw      $a1, 8($sp)

        move	$a0, $a1 			#a0 = puzzle, a2 = solution
        la	$a2, solution
        jal     count_disjoint_regions
        lw	$t0, 4($a2)				#submitting
        sw	$t0, UNFREEZE_BOT
        sw	$0, 0($a2)				#zero solution struct
        sw	$0, 4($a2)

        lw	$ra, 0($sp)
        lw      $a0, 4($sp)
        lw      $a1, 8($sp)
        add	$sp, $sp, 12
        jr      $ra
################################################################################

count_disjoint_regions:
        sub     $sp, $sp, 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)
        move    $s0, $a0        # s0 = lines
        move    $s1, $a1        # s1 = canvas
        move    $s2, $a2        # s2 = solution

        lw      $s4, 0($s0)     # s4 = lines->num_lines
        li      $s5, 0          # s5 = i
        lw      $s6, 4($s0)     # s6 = lines->coords[0]
        lw      $s7, 8($s0)     # s7 = lines->coords[1]
forcdr_loop:
        bgeu    $s5, $s4, endcdr_for
        mul     $t2, $s5, 4     # t2 = i*4
        add     $t3, $s6, $t2   # t3 = &lines->coords[0][i]
        lw      $a0, 0($t3)     # a0 = start_pos = lines->coords[0][i]
        add     $t4, $s7, $t2   # t4 = &lines->coords[1][i]
        lw      $a1, 0($t4)     # a1 = end_pos = lines->coords[1][i]
        move    $a2, $s1
        jal     draw_line

        li      $t9, 2
        div     $s5, $t9
        mfhi    $t6             # t6 = i % 2
        addi    $a0, $t6, 65    # a0 = 'A' + (i % 2)
        move    $a1, $s1        # count_disjoint_regions_step('A' + (i % 2), canvas)
        jal     count_disjoint_regions_step                # v0 = count
        lw      $t6, 4($s2)     # t6 = solution->counts
        mul     $t7, $s5, 4
        add     $t7, $t7, $t6   # t7 = &solution->counts[i]
        sw      $v0, 0($t7)     # solution->counts[i] = count
        addi    $s5, $s5, 1     # i++
        j       forcdr_loop

endcdr_for:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        lw      $s6, 28($sp)
        lw      $s7, 32($sp)
        add     $sp, $sp, 36
        jr      $ra

################################################################################

draw_line:
        lw      $t0, 4($a2)     # t0 = width = canvas->width
        li      $t1, 1          # t1 = step_size = 1
        sub     $t2, $a1, $a0   # t2 = end_pos - start_pos
        blt     $t2, $t0, cont
        move    $t1, $t0        # step_size = width;
cont:
        move    $t3, $a0        # t3 = pos = start_pos
        add     $t4, $a1, $t1   # t4 = end_pos + step_size
        lw      $t5, 12($a2)    # t5 = &canvas->canvas
        lbu     $t6, 8($a2)     # t6 = canvas->pattern
for_loop:
        beq     $t3, $t4, end_for
        div     $t3, $t0        #
        mfhi    $t7             # t7 = pos % width
        mflo    $t8             # t8 = pos / width
        mul     $t9, $t8, 4		# t9 = pos/width*4
        add     $t9, $t9, $t5   # t9 = &canvas->canvas[pos / width]
        lw      $t9, 0($t9)     # t9 = canvas->canvas[pos / width]
        add     $t9, $t9, $t7
        sb      $t6, 0($t9)     # canvas->canvas[pos / width][pos % width] = canvas->pattern
        add     $t3, $t3, $t1   # pos += step_size
        j       for_loop

end_for:
        jr      $ra

################################################################################

count_disjoint_regions_step:
        sub     $sp, $sp, 36
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)
        sw      $s6, 28($sp)
        sw      $s7, 32($sp)

        move    $s0, $a0
        move    $s1, $a1

        li      $s2, 0                  # $s2 = region_count
        li      $s3, 0                  # $s3 = row
        lw      $s4, 0($s1)             # $s4 = canvas->height
        lw      $s6, 4($s1)             # $s6 = canvas->width
        lw      $s7, 8($s1)             # canvas->pattern

cdrs_outer_for_loop:
        bge     $s3, $s4, cdrs_outer_end
        li      $s5, 0                  # $s5 = col

cdrs_inner_for_loop:
        bge     $s5, $s6, cdrs_inner_end
        lw      $t0, 12($s1)            # canvas->canvas
        mul     $t5, $s3, 4             # row * 4
        add     $t5, $t0, $t5           # &canvas->canvas[row]
        lw      $t0, 0($t5)             # canvas->canvas[row]
        add     $t0, $t0, $s5           # &canvas->canvas[row][col]
        lbu     $t0, 0($t0)             # $t0 = canvas->canvas[row][col]
        beq     $t0, $s7, cdrs_skip_if  # curr_char != canvas->pattern
        beq     $t0, $s0, cdrs_skip_if  # curr_char != canvas->marker
        add     $s2, $s2, 1             # region_count++
        move    $a0, $s3
        move    $a1, $s5
        move    $a2, $s0
        move    $a3, $s1
        jal     flood_fill

cdrs_skip_if:
        add     $s5, $s5, 1             # col++
        j       cdrs_inner_for_loop

cdrs_inner_end:
        add     $s3, $s3, 1             # row++
        j       cdrs_outer_for_loop

cdrs_outer_end:
        move    $v0, $s2
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        lw      $s6, 28($sp)
        lw      $s7, 32($sp)
        add     $sp, $sp, 36
        jr      $ra

################################################################################

flood_fill:
        sub     $sp, $sp, 20
        sw      $ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        move    $s0, $a0                # $s0 = row
        move    $s1, $a1                # $s1 = col
        move    $s2, $a2                # $s2 = marker
        move    $s3, $a3                # $s3 = canvas
        blt     $s0, $0, ff_return      # row < 0
        blt     $s1, $0, ff_return      # col < 0
        lw      $t0, 0($s3)             # $t0 = canvas->height
        bge     $s0, $t0, ff_return     # row >= canvas->height
        lw      $t0, 4($s3)             # $t0 = canvas->width
        bge     $s1, $t0, ff_return     # col >= canvas->width

        lw      $t0, 12($s3)            # canvas->canvas
        mul     $t1, $s0, 4
        add     $t0, $t1, $t0           # $t0 = &canvas->canvas[row]
        lw      $t0, 0($t0)             # canvas->canvas[row]
        add     $t1, $s1, $t0           # $t1 = &canvas->canvas[row][col]
        lbu     $t0, 0($t1)             # $t0 = curr = canvas->canvas[row][col]
        lbu     $t2, 8($s3)             # $t2 = canvas->pattern
        beq     $t0, $t2, ff_return     # curr == canvas->pattern
        beq     $t0, $s2, ff_return     # curr == marker

        sb      $s2, 0($t1)             # canvas->canvas[row][col] = marker
        sub     $a0, $s0, 1             # $a0 = row - 1
        jal     flood_fill              # flood_fill(row - 1, col, marker, canvas);
        move    $a0, $s0
        add     $a1, $s1, 1
        move    $a2, $s2
        move    $a3, $s3
        jal     flood_fill              # flood_fill(row, col + 1, marker, canvas);
        add     $a0, $s0, 1
        move    $a1, $s1
        move    $a2, $s2
        move    $a3, $s3
        jal     flood_fill              # flood_fill(row + 1, col, marker, canvas);
        move    $a0, $s0
        sub     $a1, $s1, 1
        move    $a2, $s2
        move    $a3, $s3
        jal     flood_fill              # flood_fill(row, col - 1, marker, canvas);

ff_return:
        lw      $ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        add     $sp, $sp, 20
        jr      $ra

################################################################################

        # -----------------------------------------------------------------------
        # sb_arctan - computes the arctangent of y / x
        # $a0 - x
        # $a1 - y
        # returns the arctangent
        # -----------------------------------------------------------------------

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


# -----------------------------------------------------------------------
# euclidean_dist - computes sqrt(x^2 + y^2)
# $a0 - x
# $a1 - y
# returns the distance
# -----------------------------------------------------------------------

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



.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 32	# space for two registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at		# Save $at
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers
	sw	$a1, 4($k0)		# by storing them to a global variable
        sw      $t0, 8($k0)
        sw      $v0, 12($k0)
        sw      $a2, 16($k0)
        sw      $t1, 20($k0)
        sw      $t2, 24($k0)
        sw      $t3, 28($k0)

	mfc0	$k0, $13		# Get Cause register
	srl	$a0, $k0, 2
	and	$a0, $a0, 0xf		# ExcCode field
	bne	$a0, 0, non_intrpt

interrupt_dispatch:			# Interrupt:
	mfc0	$k0, $13		# Get Cause register, again
	beq	$k0, 0, done		# handled all outstanding interrupts

	and	$a0, $k0, BONK_INT_MASK	# is there a bonk interrupt?
	bne	$a0, 0, bonk_interrupt

	and	$a0, $k0, TIMER_INT_MASK	# is there a timer interrupt?
	bne	$a0, 0, timer_interrupt

    and     $a0, $k0, STATION_ENTER_INT_MASK
    bne     $a0, 0, station_enter_interrupt

    and     $a0, $k0, STATION_EXIT_INT_MASK
    bne     $a0, 0, station_exit_interrupt

    and		$a0, $k0, REQUEST_PUZZLE_INT_MASK
	bne     $a0, 0 solve_puzzle

	and     $a0, $k0, BOT_FREEZE_INT_MASK
    bne     $a0, 0, unfreeze_bot

	# add dispatch for other interrupt types here.

	li	$v0, PRINT_STRING	# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall
	j	done

bonk_interrupt:
        sw        $a1, 0xffff0060($zero)   # acknowledge interrupt

        li	$t0, 180			# ???
        sw	$t0, ANGLE		# ???
        sw	$zero, ANGLE_CONTROL	# ???

        j         interrupt_dispatch       # see if other interrupts are waiting

timer_interrupt:
	sw	$a1, TIMER_ACK		# acknowledge interrupt

	j	interrupt_dispatch	# see if other interrupts are waiting

station_enter_interrupt:
	sw	$a1, 0xffff0058($zero)		# acknowledge interrupt

	j	interrupt_dispatch	# see if other interrupts are waiting

station_exit_interrupt:
	sw	$a1, 0xffff0064($zero)		# acknowledge interrupt

	j	interrupt_dispatch	# see if other interrupts are waiting

unfreeze_bot:
	la	$a1, puzzle
	sw	$a1, BOT_FREEZE_ACK
	la	$t0, puzzle_ready
	li	$t1, 1
	sw	$t1, 0($t0)
	j	interrupt_dispatch

solve_puzzle:
	sw	$a1, REQUEST_PUZZLE_ACK
	la	$t0, puzzle_ready
	li	$t1, 1
	sw	$t1, 0($t0)
        j   interrupt_dispatch

non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done

done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)
        lw      $t0, 8($k0)
        lw      $v0, 12($k0)
        lw      $a2, 16($k0)
        lw      $t1, 20($k0)
        lw      $t2, 24($k0)
        lw      $t3, 28($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at
eret

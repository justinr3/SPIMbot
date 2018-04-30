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
REQUEST_PUZZLE			= 0xffff00d0
REQUEST_PUZZLE_ACK			= 0xffff00d8
PUZZLE_MASK					= 0x800
SUBMIT_SOLUTION				= 0xffff00d4
BOT_FREEZE_ACK				= 0xffff00e4
BOT_FREEZE_MASK				= 0x4000
UNFREEZE_BOT				= 0xffff00e8
THROW_PUZZLE				= 0xffff00e0
CHECK_OTHER_FROZEN			= 0xffff101c
SCORES_REQUEST				= 0xffff1018

.data
lines:          .word   2       start_pos       end_pos
start_pos:      .word   2       10
end_pos:        .word   22      14

canvas: 		.word   0       0       0       canv
canv:   		.space  1024

solution:       .word   2       counts
counts:         .space  8

puzzle:  		.word	canvas	lines	data
data:			.space	300

.align 2
asteroid_map: .space 1024

.text
main:

	la	$t0, asteroid_map
	sw	$t0, ASTEROID_MAP

	lw	$t1, BOT_X($0)			#s1 = x_bot
	sw	$0, ANGLE
	li	$t3, 1
	sw	$t3, ANGLE_CONTROL		#absolute angle = 0
	div	$t7, $t1, -60
	add	$t7, $t7, 5				#s7 = -vg = 5 - (x)/60
	sw	$t7, VELOCITY

	la $t0, puzzle
	sw $t0, REQUEST_PUZZLE

j	main
################################################################################

solve_unfreeze:
    sub	$sp, $sp, 12                                  # allocate 28 byte stack frame
    sw	$ra, 0($sp)
    sw      $a0, 4($sp)
    sw      $a1, 8($sp)

	sw	$a0, 16($a1) 			#a0 = lines, a1 =  canvas, a2 = solution
	sw	$a1, 0($a1)
	la	$a2, solution
	jal count_disjoint_regions
	lw	$t0, 4($a2)				#submitting
	sw	$t0, UNFREEZE_BOT
	sw	$0,	0($a2)				#zero solution struct
	sw	$0, 4($a2)

	lw	$ra, 0($sp)
    lw      $a0, 4($sp)
    lw      $a1, 8($sp)
	add	$sp, $sp, 12
    jr      $ra
################################################################################

count_disjoint_regions:
        sub	$sp, $sp, 28                                    # allocate 28 byte stack frame
        sw	$ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)

        move    $s0, $a0                                        # save lines
        move    $s1, $a1                                        # save canvas
        lw      $s2, 4($a2)                                     # save solution->count

        li      $s3, 0                                          # unsigned int i = 0

cdr_for:
        lw      $t0, 0($s0)                                     # load lines->num_lines
        bge     $s3, $t0, cdr_end                               # branch if !(i < lines->num_lines)

        lw      $t1, 4($s0)                                     # load lines->coords[0]
        li      $t2, 4
        mult    $s3, $t2
        mflo    $t2
        add     $t2, $t1, $t2                                   # & lines->coords[0][i]
        lb      $t4, 8($s1)                                     # load canvas->pattern
        lw      $s4, 0($t2)                                     # load lines->coords[0][i]

        lw      $t1, 8($s0)                                     # load lines->coords[1]
        li      $t2, 4
        mult    $s3, $t2
        mflo    $t2
        add     $t2, $t1, $t2                                   # & lines->coords[1][i]
        lw      $s5, 0($t2)                                     # load lines->coords[1][i]

        move    $a0, $s4
        move    $a1, $s5
        move    $a2, $s1
        jal     draw_line                                       # draw_line(start_pos, end_pos, canvas);

        li      $t0, 2
        div     $s3, $t0
        mfhi    $t0                                             # i % 2

        add     $a0, $t0, 65
        move    $a1, $s1
        jal     count_disjoint_regions_step                     # count = count_disjoint_regions_step('A' + (i % 2), canvas);

        li      $t0, 4
        mult    $t0, $s3
        mflo    $t0
        add     $t0, $t0, $s2
        sw      $v0, 0($t0)                                     # solution->counts[i] = count;

        add     $s3, 1                                          # i++
        j       cdr_for

cdr_end:
        lw	$ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        add	$sp, $sp, 28
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
        mul     $t9, $t8, 4		  # t9 = pos/width*4
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
        sub	$sp, $sp, 28                    # allocate 28 byte stack frame
        sw	$ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)
        sw      $s4, 20($sp)
        sw      $s5, 24($sp)

        move    $s0, $a0                        # save marker
        move    $s1, $a1                        # save canvas

        li      $s3, 0                          # unsigned int region_count = 0;

        li      $s4, 0                          # int row = 0

cdrs_for_outer:
        li      $s5, 0                          # int col = 0
        lw      $t0, 4($s1)                     # load canvas->width
        bge     $s4, $t0, cdrs_end_outer        # branch if !(col < canvas->width)

cdrs_for_inner:
        lw      $t0, 0($s1)                     # load canvas->height
        bge     $s5, $t0, cdrs_end_inner        # branch if !(row < canvas->height)
        lw      $t2, 12($s1)                    # canvas->canvas
        li      $t3, 4
        mult    $s4, $t3
        mflo    $t3
        add     $t2, $t2, $t3                   # &canvas->canvas[row]
        lw      $t2, 0($t2)                     # load canvas->canvas[row]
        add     $t2, $t2, $s5                   # &canvas->canvas[row][col]
        lb      $s2, 0($t2)                     # curr = canvas->canvas[row][col]

        lb      $t4, 8($s1)                     # load pattern
        beq     $s2, $t4, cdrs_exit_if          # branch if (curr == canvas->pattern)
        beq     $s2, $s0, cdrs_exit_if          # branch if (curr == marker)

        add     $s3, $s3, 1                     # region_count ++;

        move    $a0, $s4
        move    $a1, $s5
        move    $a2, $s0
        move    $a3, $s1
        jal     flood_fill                      # flood_fill(row, col, marker, canvas);

cdrs_exit_if:
        add     $s5, $s5, 1                     # col++
        j       cdrs_for_inner

cdrs_end_inner:
        add     $s4, $s4, 1                     # row++
        j       cdrs_for_outer

cdrs_end_outer:
        move    $v0, $s3                        # return value region_count

        lw	$ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)
        add	$sp, $sp, 28
        jr      $ra

################################################################################

flood_fill:
        sub	$sp, $sp, 20                    # allocate 20 byte stack frame
        sw	$ra, 0($sp)
        sw      $s0, 4($sp)
        sw      $s1, 8($sp)
        sw      $s2, 12($sp)
        sw      $s3, 16($sp)

        blt     $a0, $0, ff_ret_skip            # branch if (row < 0)
        blt     $a1, $0, ff_ret_skip            # branch if (col < 0)
        lw      $t0, 0($a3)
        lw      $t1, 4($a3)

        bge     $a0, $t0, ff_ret_skip           # branch if (row >= canvas->height)
        bge     $a1, $t1, ff_ret_skip           # branch if (col >= canvas->width)

        move    $s0, $a0                        # save row
        move    $s1, $a1                        # save column
        move    $s2, $a2                        # save marker
        move    $s3, $a3                        # save canvas

        lw      $t2, 12($s3)                    # canvas->canvas
        li      $t3, 4
        mult    $s0, $t3
        mflo    $t3
        add     $t2, $t2, $t3                   # &canvas->canvas[row]
        lw      $t2, 0($t2)                     # load canvas->canvas[row]
        add     $t2, $t2, $s1                   # &canvas->canvas[row][col]
        lb      $t3, 0($t2)                     # curr = canvas->canvas[row][col]

        lb      $t4, 8($s3)                     # load pattern
        beq     $t3, $t4, ff_ret                # branch if (curr == canvas->pattern)
        beq     $t3, $s2, ff_ret                # branch if (curr == marker)

        sb      $s2, 0($t2)                     # canvas->canvas[row][col] = marker

        sub     $a0, $s0, 1
        move    $a1, $s1
        move    $a2, $s2
        move    $a3, $s3
        jal     flood_fill                      # flood_fill(row - 1, col, marker, canvas)

        move    $a0, $s0
        add     $a1, $s1, 1
        move    $a2, $s2
        move    $a3, $s3
        jal     flood_fill                      # flood_fill(row, col + 1, marker, canvas)

        add     $a0, $s0, 1
        move    $a1, $s1
        move    $a2, $s2
        move    $a3, $s3
        jal     flood_fill                      # flood_fill(row + 1, col, marker, canvas)

        move    $a0, $s0
        sub     $a1, $s1, 1
        move    $a2, $s2
        move    $a3, $s3
        jal     flood_fill                      # flood_fill(row, col - 1, marker, canvas)

ff_ret:
        lw	$ra, 0($sp)
        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)

ff_ret_skip:
        add     $sp, $sp, 20
        jr      $ra

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
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers
	sw	$a1, 4($k0)		# by storing them to a global variable

	mfc0	$k0, $13		# Get Cause register
	srl	$a0, $k0, 2
	and	$a0, $a0, 0xf		# ExcCode field
	bne	$a0, 0, done

interrupt_dispatch:

	and	$a0, $k0, PUZZLE_MASK
	bne $a0, 0 solve_puzzle

	and $a0, $k0, BOT_FREEZE_MASK
	bne	$a0, 0, unfreeze_bot

unfreeze_bot:
	la	$a1, puzzle
	sw	$a1, BOT_FREEZE_ACK
	#jal	solve_unfreeze
	j	interrupt_dispatch

solve_puzzle:
	sw	$a0, 16($t0) 			#a0 = lines, a1 =  canvas, a2 = solution
	sw	$a1, 0($t0)
	la	$a2, solution
	jal count_disjoint_regions
	lw	$t1, 4($a2)				#submitting
	lw	$t2, CHECK_OTHER_FROZEN	#t2 = 1 if other bot frozen
	beq	$t2, 1, no_throwing
	lw	$t2, SCORES_REQUEST
	srl	$t3, $t2, 30		#t3 = our score
	sll $t2, $t2, 30		#t2 = other's score
	srl $t2, $t2, 30
	bge	$t3, $t2, no_throwing
		sw	$a1, THROW_PUZZLE
no_throwing:
	sw	$t1, SUBMIT_SOLUTION
	sw	$0,	0($a2)				#zero solution struct
	sw	$0, 4($a2)
	sw	$a1, REQUEST_PUZZLE_ACK
	j interrupt_dispatch

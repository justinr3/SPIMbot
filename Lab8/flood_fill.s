.text

## struct Canvas {
##     // Height and width of the canvas.
##     unsigned int height;
##     unsigned int width;
##     // The pattern to draw on the canvas.
##     unsigned char pattern;
##     // Each char* is null-terminated and has same length.
##     char** canvas;
## };
##
## // Mark an empty region as visited on the canvas using flood fill algorithm.
## void flood_fill(int row, int col, unsigned char marker, Canvas* canvas) {
##     // Check the current position is valid.
##     if (row < 0 || col < 0 ||
##         row >= canvas->height || col >= canvas->width) {
##         return;
##     }
##     unsigned char curr = canvas->canvas[row][col];
##     if (curr != canvas->pattern && curr != marker) {
##         // Mark the current pos as visited.
##         canvas->canvas[row][col] = marker;
##         // Flood fill four neighbors.
##         flood_fill(row - 1, col, marker, canvas);
##         flood_fill(row, col + 1, marker, canvas);
##         flood_fill(row + 1, col, marker, canvas);
##         flood_fill(row, col - 1, marker, canvas);
##     }
## }

.globl flood_fill
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
        jr      $ra                             # return

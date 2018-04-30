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

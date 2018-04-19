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
## // Count the number of disjoint empty area in a given canvas.
## unsigned int count_disjoint_regions_step(unsigned char marker,
##                                          Canvas* canvas) {
##     unsigned int region_count = 0;
##     for (unsigned int row = 0; row < canvas->height; row++) {
##         for (unsigned int col = 0; col < canvas->width; col++) {
##             unsigned char curr_char = canvas->canvas[row][col];
##             if (curr_char != canvas->pattern && curr_char != marker) {
##                 region_count ++;
##                 flood_fill(row, col, marker, canvas);
##             }
##         }
##     }
##     return region_count;
## }

.globl count_disjoint_regions_step
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
        jr      $ra                             # return

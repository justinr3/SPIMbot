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

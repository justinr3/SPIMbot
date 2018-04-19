.text

## struct Lines {
##     unsigned int num_lines;
##     // An int* array of size 2, where first element is an array of start pos
##     // and second element is an array of end pos for each line.
##     // start pos always has a smaller value than end pos.
##     unsigned int* coords[2];
## };
##
## struct Solution {
##     unsigned int length;
##     int* counts;
## };
##
## // Count the number of disjoint empty area after adding each line.
## // Store the count values into the Solution struct.
## void count_disjoint_regions(const Lines* lines, Canvas* canvas,
##                             Solution* solution) {
##     // Iterate through each step.
##     for (unsigned int i = 0; i < lines->num_lines; i++) {
##         unsigned int start_pos = lines->coords[0][i];
##         unsigned int end_pos = lines->coords[1][i];
##         // Draw line on canvas.
##         draw_line(start_pos, end_pos, canvas);
##         // Run flood fill algorithm on the updated canvas.
##         // In each even iteration, fill with marker 'A', otherwise use 'B'.
##         unsigned int count =
##                 count_disjoint_regions_step('A' + (i % 2), canvas);
##         // Update the solution struct. Memory for counts is preallocated.
##         solution->counts[i] = count;
##     }
## }

.globl count_disjoint_regions
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
        jr      $ra                                             # return

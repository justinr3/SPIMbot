.text

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
##         unsigned int count = count_disjoint_regions_step('A' + (i % 2),
##                                                          canvas);
##         // Update the solution struct. Memory for counts is preallocated.
##         solution->counts[i] = count;
##     }
## }

.globl count_disjoint_regions
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
for_loop:
        bgeu    $s5, $s4, end_for
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
        j       for_loop

end_for:
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

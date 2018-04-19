.text

## struct Canvas {
##     // Height and width of the canvas.
##     unsigned int height; (4B)
##     unsigned int width; (4B)
##     // The pattern to draw on the canvas.
##     unsigned char pattern; (1B)
##     // Each char* is null-terminated and has same length.
##     char** canvas; (4B)
## };
##
##
## // Draw a line on canvas from start_pos to end_pos.
## // start_pos will always be smaller than end_pos.
## void draw_line(unsigned int start_pos, unsigned int end_pos,
##                Canvas* canvas) {
##     unsigned int width = canvas->width;
##     unsigned int step_size = 1;
##     // Check if the line is vertical.
##     if (end_pos - start_pos >= width) {
##         step_size = width;
##     }
##     // Update the canvas with the new line.
##     for (int pos = start_pos; pos != end_pos + step_size;
##              pos += step_size) {
##         canvas->canvas[pos / width][pos % width] = canvas->pattern;
##     }
## }


.globl draw_line
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

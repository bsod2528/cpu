-- i mean i can add comments _insert mnm shrug_

start:
    addi r0, 3;
    subi r0, 1;
    cjmp r0, jne, 1;
    addi r1, 3;
    subi r1, 1;
    cjmp r1, jeq, 4;
    addi r2, 3;
    subi r2, 1;
    cjmp r2, jgt, 7;
    subi r3, 1;
    cjmp r3, jlt, 9;
    halt;
end:

-- line 6: loop back to addr 1
-- line 9: loop back to addr 4
-- line 12: loop back to addr 7
-- line 13: r3 = 0xFFFF = -1 signed
-- line 14: infinite loop — r3 always negative

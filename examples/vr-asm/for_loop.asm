-- sum 1+2+3+4+5
start:
    addi r0, 5;
    addi r1, 0;
    add  r1, r1, r0;
    subi r0, 1;
    cjmp r0, jne, 2;
    halt
end:

-- r0 = 5
-- r1 = 0
-- r1 += r0
-- r0 --
-- if r0 != 0 go back to 2
-- r1 = 15
-- halt

start:
    addi r0, 48;
    addi r1, 18;
    sub r2, r0, r1;
    cjmp r2, jeq, 9;
    cjmp r2, jlt, 7;
    or r0, r2, r2;
    jmp 2;
    or r0, r1, r1;
    or r1, r2, r2;
    jmp 2;
    halt;
end:
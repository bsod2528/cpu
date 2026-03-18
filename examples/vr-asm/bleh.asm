start:
    addi r0, 1;
    cjmp r0, jeq, 6;
    cjmp r0, jlt, 6;
    cjmp r0, jgt, 5;
    jmp 6;
    addi r1, 1;
    halt;
end:
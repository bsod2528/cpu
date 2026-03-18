-- if r0 > 0: r1 = 1 else: r1 = 0

start:
    addi r0, 9;
    cjmp r0, jgt, 4;
    addi r1, 0;
    jmp 5;
    addi r1, 1;
    halt;
end:

-- if r0 > 0, jump to true branch
-- false branch r1 = 0
-- skip true branch
-- true branch r1 = 1

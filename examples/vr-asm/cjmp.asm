-- jeq tester

-- start:
--     addi r0, 10;
--     cjmp r0, jeq, 4;
--     addi r3, 0;
--     addi r3, 1;
--     halt;
-- end:

-- jne countdown

-- start:
--     addi r0, 5;
--     subi r0, 1;
--     cjmp r0, jne, 1;
--     halt;
-- end:

-- jlt tester check for negative value
-- start:
--     addi r0, 0;
--     subi r0, 5;
--     cjmp r0, jlt, 3;
--     addi r1, 1;
--     jmp 6;
--     addi r1, 0;
--     halt;
-- end:

-- sum only the positive numbers: r0 counts 3 down to -1, add to r1 if > 0

-- start:
--     addi r0, 3;
--     cjmp r0, jlt, 6;
--     cjmp r0, jeq, 5;
--     add r1, r1, r0;
--     subi r0, 1;
--     jmp 1;
--     subi r0, 1;
--     jmp 1;
--     halt;
-- end:
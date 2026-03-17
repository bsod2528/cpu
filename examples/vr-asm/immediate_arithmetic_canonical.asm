-- Canonical immediate arithmetic example for VR16.
-- Demonstrates ADDI/SUBI/MULI/DIVI using accumulator-style semantics.
--
-- Initial register state (before `start:`):
-- r0 = 8
-- r1 = 10
-- r2 = 6
-- r3 = 18
--
-- Expected register state after execution:
-- r0 = 13   (8  + 5)
-- r1 = 7    (10 - 3)
-- r2 = 24   (6  * 4)
-- r3 = 3    (18 / 6)

start:
    addi r0, 5;
    subi r1, 3;
    muli r2, 4;
    divi r3, 6;
    halt;
end:

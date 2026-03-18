-- ; multiply r0 by 2 until it's >= 100
start:
addi r0, 1;
muli r0, 2;
subi r2, 100;y

-- ; better written as:
addi r0, 1;
muli r0, 2;
addi r2, 100;
sub  r3, r0, r2;
cjmp r3, jlt, 1;
halt;
end:

-- ; r0 = 1
-- ; r0 *= 2
-- ; r2 = r0 - 100  (use r2 as scratch: load r0 first)

-- ; r0 = 1
-- ; r0 *= 2
-- ; r2 = 100
-- ; r3 = r0 - 100
-- ; if r3 < 0 (r0 < 100), loop back
-- ; r0 is first power-of-2 >= 100  → r0=128

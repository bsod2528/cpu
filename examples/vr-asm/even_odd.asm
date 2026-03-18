-- is r0 even or odd?
-- shift right by 1, then shift left by 1
-- if result == original, it was even
start:
    addi r0, 10;
    or r1, r0, r0;
    shift r0, right, 1;
    shift r0, left, 1;  
    sub  r2, r0, r1;
    cjmp r2, jeq, 6; 
    halt;           
    halt;   
end:

-- r1 = r0 (save original)
-- r0 = r0 >> 1
-- r0 = r0 << 1
-- r2 = modified - original
-- if r2 == 0, number was even
-- odd path
-- even path

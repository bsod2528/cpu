# VR16-ISA alpha

> [!IMPORTANT]
> The entire architecture is subject to change.

Please don't mind my poor markdown skills.

1. `ADD`:
```md
0000 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

2. `ADDI`:
  ```md
0001 | 00 | 0000000000
opcode | store_at | 10-bit immediate value
```

3. `SUB`:
```md
0010 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

4. `SUBI`:
```md
0011 | 00 | 0000000000
opcode | store_at | 10-bit immediate value
```

5. `MUL`:
```md
0100 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

6. `MULI`:
```md
0101 | 00 | 0000000000
opcode | store_at | 10-bit immediate value
```

7. `DIV`:
```md
0110 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

8. `DIVI`:
```md
0111 | 00 | 0000000000
opcode | store_at | 10-bit immediate value
```

9. DONT KNOW WHAT TO DO HERE

10. `JUMP`:
```md
1001 | 000000000000 |
opcode | jump_to_12_bit_address for now
```

11. `DELETE`:
```md
1010 | 00 | xxxxxxxxxx
opcode | destination_register | dont-care values
```

12. `AND`:
```md
1011 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

13. `OR`:
```md
1100 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

14. `NOT`:
```md
1101 | 00 | 00 | xxxxxxxx
opcode | store_at | operand_one | dont-care values
```

15. `XOR`:
```md
1110 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

16. `HALT`:
```md
1111 | xxxxxxxxxxxx
opcode | dont-care values
```

Kept only basic LOGIC operations as others can be done from these.

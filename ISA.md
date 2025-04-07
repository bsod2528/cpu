# VR16-ISA v0.1

THIS IS SUBJECT TO CHANGE, I'M EXPERIMENTING ENTIRELY.

# Working for this
So instead of having a definite IS Format: `0000 00 00 00 00 0000`, this would keep changing based on the opcode mentioned.

For this the entire ISA has to be designed.

1. `ADD`:
    - 0000 | 00 | 00 | 00 | 00 | xxxx
    - opcode | store_at | operand_one | operand_two | dont-care values
2. `ADDI`:
    - 0001 | 00 | 0000000000
    - opcode | store_at | 10-bit immediate value
3. `SUB`:
    - 0010 | 00 | 00 | 00 | 00 | xxxx
    - opcode | store_at | operand_one | operand_two | dont-care values
4. `SUBI`:
    - 0011 | 00 | 0000000000
    - opcode | store_at | 10-bit immediate value
5. `MUL`:
    - 0100 | 00 | 00 | 00 | 00 | xxxx
    - opcode | store_at | operand_one | operand_two | dont-care values
6. `MULI`:
    - 0101 | 00 | 0000000000
    - opcode | store_at | 10-bit immediate value
7. `DIV`:
    - 0110 | 00 | 00 | 00 | 00 | xxxx
    - opcode | store_at | operand_one | operand_two | dont-care values
8. `DIVI`:
    - 0111 | 00 | 0000000000
    - opcode | store_at | 10-bit immediate value
9. `STOREI`:
    - 1000 | 00 | 00000000
    - opcode | destination_register | 10-bit immediate value
10. `JUMP`:
    - 1001 | 000000000000 |
    - opcode | jump_to_12_bit_address for now
11. `DELETE`:
    - 1010 | 00 | xxxxxxxxxx
    - opcode | destination_register | dont-care values
12. `AND`:
    - 1011 | 00 | 00 | 00 | xxxxxx
    - opcode | store_at | operand_one | operand_two | dont-care values
12. `OR`:
    - 1100 | 00 | 00 | 00 | xxxxxx
    - opcode | store_at | operand_one | operand_two | dont-care values
13. `NOT`:
    - 1101 | 00 | 00 | xxxxxxxx
    - opcode | store_at | operand_one | dont-care values
14. `XOR`:
    - 1110 | 00 | 00 | 00 | xxxxxx
    - opcode | store_at | operand_one | operand_two | dont-care values
15. `HALT`:
    - 1111 | xxxxxxxxxxxx
    - opcode | dont-care values

Kept only basic LOGIC operations as others can be done from these.

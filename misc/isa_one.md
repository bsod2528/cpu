# VR16-ISA v0.1

- `0000`: ADD -> operand_one + operand_two
- `0001`: ADDI -> operand_one + imm_val
- `0010`: SUB -> operand_one - operand_two
- `0011`: SUBI -> operand_one - imm_val
- `0100`: MUL -> operand_one * operand_two
- `0101`: MULI -> operand_one * imm_val
- `0110`: DIV -> operand_one / operand_two
- `0111`: DIVI -> operand_one / imm_val
- `1000`: LOAD -> source
- `1001`: JUMP -> destination
- `1010`: STORE -> value or source, destination
- `1011`: AND
- `1100`: OR
- `1101`: NOT
- `1110`: XOR
- `1111`: HALT

Kept only basic LOGIC operations as others can be done from these.

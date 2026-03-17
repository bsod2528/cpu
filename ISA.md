# VR16-ISA

## Instruction Summary

### Raw Opcode Instructions
| Mnemonic | Opcode (4-bit) | Operand Format | Immediate Value Width (if any) |
| --- | --- | --- | --- |
| `add` | `0000` | `store_at`, `operand_one`, `operand_two` | None | 
| `addi` | `0001` | `store_at`, `imm10` | 10-bit | 
| `sub` | `0010` | `store_at`, `operand_one`, `operand_two` | None | 
| `subi` | `0011` | `store_at`, `imm10` | 10-bit |
| `mul` | `0100` | `store_at`,` `operand_one, `operand_two` | None |
| `muli` | `0101` | `store_at`, `imm10` | 10-bit |
| `div` | `0110` | `store_at`, `operand_one`, `operand_two` | None |
| `divi` | `0111` | `store_at`, `imm10` | 10-bit |
| `shift` | `1000` | `shift_at`, `direction` | 9-bit |
| `jmp` | `1001` | `jump_address` | 12-bit |
| `cjmp` | `1010` | `reg_to_check`, `condition`, `jump_address` | 8-bit |
| `and` | `1011` | `store_at`, `operand_one`, `operand_two` | None |
| `or` | `1100` | `store_at`, `operand_one`,`operand_two` | None |
| `not` | `1101` | `store_at`, `operand_one` | None |
| `xor` | `1110` | `store_at`, `operand_one`, `operand_two` | None |
| `halt` | `1111` | no operands | None |

<!-- 

TODO:
### Pseudo Instructions
| Mnemonic | Operand Format | 
| --- | --- |
| `mov` | `store_at` | 
| `del` | `store_at` |
-->

- - - 

## Arithmetic instructions

1. `add`:
```md
0000 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

2. `addi`:
```md
0001 | 00 | 0000000000
opcode | store_at | 10-bit immediate value
```

3. `sub`:
```md
0010 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

4. `subi`:
```md
0011 | 00 | 0000000000
opcode | store_at | 10-bit immediate value
```

5. `mul`:
```md
0100 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

6. `muli`:
```md
0101 | 00 | 0000000000
opcode | store_at | 10-bit immediate value
```

7. `div`:
```md
0110 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

8. `divi`:
```md
0111 | 00 | 0000000000
opcode | store_at | 10-bit immediate value
```

### Exact immediate arithmetic semantics (`ADDI`, `SUBI`, `MULI`, `DIVI`)

For all immediate arithmetic opcodes (`0001`, `0011`, `0101`, `0111`), the encoding and execution model are intentionally accumulator-style:

- Bits `[11:10]` (`store_at`) are both:
  - the **destination register**, and
  - the **source register** (`operand_one`).
- Bits `[9:0]` are a **10-bit unsigned immediate**.
- Assembly literals for `imm10` are accepted in **base-10 only** (e.g., `0`, `17`, `1023`).
- Valid `imm10` range is **`0..1023`**, interpreted as an **unsigned** value.
- Immediate is **zero-extended** to 16 bits before ALU use.
- Execution formulas:
  - `ADDI rd, imm10`: `R[rd] <- R[rd] + zero_extend(imm10)`
  - `SUBI rd, imm10`: `R[rd] <- R[rd] - zero_extend(imm10)`
  - `MULI rd, imm10`: `R[rd] <- R[rd] * zero_extend(imm10)`
  - `DIVI rd, imm10`: `R[rd] <- R[rd] / zero_extend(imm10)`

> [!NOTE]
> **Assembler validation rule (immediate arithmetic family):** non-base-10 literals or values outside `0..1023` raise `Invalid immediate ... Expected a base-10 integer in range 0 to 1023.`

#### Worked examples
<!-- `)` used don't work -->
1. `addi r1, 5`

- Before: `R1 = 12`
- Encoded fields:
  - opcode=`0001`
  - `store_at` (`r1`) = `01`
  - imm10 (`5`) = `0000000101`
- 16-bit instruction: `0001 01 0000000101`
- ALU inputs:
  - `operand_one = R1 = 12`
  - `operand_two = zero_extend(5) = 5`
- After: `R1 = 17`

2. `subi r2, 3`

- Before: `R2 = 20`
- 16-bit instruction: `0011 10 0000000011`
- After: `R2 = 17`

3. `muli r0, 4`

- Before: `R0 = 7`
- 16-bit instruction: `0101 00 0000000100`
- After: `R0 = 28`

4. `divi r3, 6`

- Before: `R3 = 30`
- 16-bit instruction: `0111 11 0000000110`
- After: `R3 = 5`

9. `shift`:
```md
1000 | 00 | 0 | 00000000
opcode | shift_at | direction | 9-bit shift amount
```

10. `jmp`:
```md
1001 | 000000000000 |
opcode | jump_to_12_bit_address for now
```

- Assembly literals for `jump_address` are accepted in **base-10 only**.
- Valid `jump_address` range is **`0..4095`**, interpreted as an **unsigned** address.

> [!NOTE]
> **Assembler validation rule (jump family):** non-base-10 literals or values outside `0..4095` raise `Invalid jump address ... Expected a base-10 integer in range 0 to 4095.`

### Rule for future immediate/address-bearing instructions

Any future instruction that carries an immediate/address field should follow the same assembler-facing contract:

- literal input is **base-10 only**,
- the accepted range is the instruction field width interpreted as **unsigned**,
- out-of-range or non-decimal input should raise an `Invalid ... Expected a base-10 integer in range ...` error matching the extractor style.

13. `cjmp`:
```md
1010 | 00 | 00 | 00000000
opcode | reg_to_check | condition | 8-bit jump address
```

> `jeq` - 00 - jump equal - if `x == y`
> `jne` - 01 - jump not equal to - if `x != y`
> `jgt` - 10 - jump greater than - if `x > y`
> `jlt` - 11 - jump less than - if `x < y`

12. `and`:
```md
1011 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

13. `or`:
```md
1100 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

14. `not`:
```md
1101 | 00 | 00 | xxxxxxxx
opcode | store_at | operand_one | dont-care values
```

15. `xor`:
```md
1110 | 00 | 00 | 00 | xxxxxx
opcode | store_at | operand_one | operand_two | dont-care values
```

16. `halt`:
```md
1111 | xxxxxxxxxxxx
opcode | dont-care values
```

Kept only basic LOGIC operations as others can be done from these.

<!-- ## Pseudo Instructions
These instructions aren't built into the CPU, running other instructions gives the same output, thus they're called pseudo instructions.

17. `mov`:
```md
mov 
``` -->

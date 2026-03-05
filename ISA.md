# VR16-ISA alpha

> [!IMPORTANT]
> The entire architecture is subject to change.

Please don't mind my poor markdown skills.

## Instruction summary

| Mnemonic | Opcode (4-bit) | Operand format | Immediate width (if any) | Implementation status (implemented/decoder-only/planned) |
| --- | --- | --- | --- | --- |
| `ADD` | `0000` | `store_at, operand_one, operand_two` | None | implemented |
| `ADDI` | `0001` | `store_at, imm10` | 10-bit | implemented |
| `SUB` | `0010` | `store_at, operand_one, operand_two` | None | implemented |
| `SUBI` | `0011` | `store_at, imm10` | 10-bit | implemented |
| `MUL` | `0100` | `store_at, operand_one, operand_two` | None | implemented |
| `MULI` | `0101` | `store_at, imm10` | 10-bit | implemented |
| `DIV` | `0110` | `store_at, operand_one, operand_two` | None | implemented |
| `DIVI` | `0111` | `store_at, imm10` | 10-bit | implemented |
| `STOREI` | `1000` | `reg_to_store_in, imm8` | 8-bit | decoder-only |
| `JUMP` | `1001` | `jump_address` | 12-bit | implemented |
| `DELETE` | `1010` | `destination_register` | None | planned |
| `AND` | `1011` | `store_at, operand_one, operand_two` | None | implemented |
| `OR` | `1100` | `store_at, operand_one, operand_two` | None | implemented |
| `NOT` | `1101` | `store_at, operand_one` | None | implemented |
| `XOR` | `1110` | `store_at, operand_one, operand_two` | None | implemented |
| `HALT` | `1111` | no operands | None | implemented |

## Arithmetic instructions

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

1) `ADDI r1, 5`

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

2) `SUBI r2, 3`

- Before: `R2 = 20`
- 16-bit instruction: `0011 10 0000000011`
- After: `R2 = 17`

3) `MULI r0, 4`

- Before: `R0 = 7`
- 16-bit instruction: `0101 00 0000000100`
- After: `R0 = 28`

4) `DIVI r3, 6`

- Before: `R3 = 30`
- 16-bit instruction: `0111 11 0000000110`
- After: `R3 = 5`

9. `STOREI`:

```md
1000 | xx | 00 | 00000000
opcode | dont-care | reg_to_store_in | 8-bit immediate value
```

> [!NOTE]
> `STOREI` is decoded by the instruction decoder (opcode `1000`) but is **not yet implemented** in the control unit or assembler. It stores an 8-bit immediate directly into a register. Since `ADDI` covers the same use-case with a 10-bit immediate in accumulator style, `STOREI` may be removed or repurposed in a future ISA revision.

10. `JUMP`:

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

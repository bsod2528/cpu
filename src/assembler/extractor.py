# VR16: A basic 16-bit RISC processor
# Copyright (C) 2025 Vishal Srivatsava AV
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https:#www.gnu.org/licenses/>.

"""Extractor functions for the VR16 assembler.

Each public function in this module accepts a :class:`ParsedInstruction` and
returns a 16-bit binary string (``"0"``/``"1"`` characters) ready to be
written as one line of a ``.mem`` file.

Module-level constants:
    ARITHMETIC_OPCODES  - Mapping of arithmetic mnemonic → 4-bit binary string.
    LOGICAL_OPCODES     - Mapping of logical mnemonic → 4-bit binary string.
    REGISTER_VALUES     - Mapping of register name (r0–r3) → 2-bit binary string.
"""

from dataclasses import dataclass

from baseclass import RegisterNotPresent

ARITHMETIC_OPCODES: dict[str, str] = {
    "add": "0000",
    "addi": "0001",
    "sub": "0010",
    "subi": "0011",
    "mul": "0100",
    "muli": "0101",
    "div": "0110",
    "divi": "0111",
}

LOGICAL_OPCODES: dict[str, str] = {
    "and": "1011",
    "or": "1100",
    "not": "1101",
    "xor": "1110",
}

REGISTER_VALUES: dict[str, str] = {"r0": "00", "r1": "01", "r2": "10", "r3": "11"}


@dataclass
class ParsedInstruction:
    """Structured representation of a single decoded VR-ASM instruction line.

    Attributes:
    -----------
    opcode: str
        The mnemonic (e.g. ``"add"``, ``"jump"``, ``"halt"``).
    operands: list[str]
        The operand tokens (registers and/or immediate values) in source order.
    line_number: int
        1-based line number in the source file; used in error messages.
    """

    opcode: str
    operands: list[str]
    line_number: int


def _validate_operand_count(
    instruction: ParsedInstruction, expected_operands: int
) -> list[str]:
    """Validate that the instruction has the expected number of operands.

    Arguments:
    ----------
    instruction: ParsedInstruction
        The instruction whose operand list will be checked.
    expected_operands: int
        The number of operands the opcode requires.

    Returns:
    --------
    list[str]:
        The operand list unchanged if the count matches.

    Raises:
    -------
    ValueError:
        When the actual operand count does not match ``expected_operands``.
    """
    # Step 1: Compare actual vs expected count and raise a descriptive error.
    if len(instruction.operands) != expected_operands:
        raise ValueError(
            f"Syntax error at line {instruction.line_number}: opcode '{instruction.opcode}' "
            f"expects {expected_operands} operand(s), got {len(instruction.operands)}."
        )
    return instruction.operands


def decode_register(register: str, line: int) -> str:
    """
    Converts register names into 2-bit string binary.

    Arguments:
    ----------
    register: str
        The value, either r0, r1, r2, or r3 from the input `.asm`.
    line: int
        Line number from the source file in which this current instruction is present.

    Returns:
    --------
    str:
        Version of the register which can be stored in `.mem`.
    """
    if register not in REGISTER_VALUES:
        raise RegisterNotPresent(register, line)
    else:
        return REGISTER_VALUES[register]


def get_arithmetic_opcode(opcode: str) -> str:
    """
    Dynamically (laughs) converts the `str-opcode` into `str-binary`.

    Arguments:
    ----------
    opcode: str
        Mentions what instruction must be conducted in pure English, which is later converted to `str-binary`.

    Returns:
    --------
    str:
        4-bit binary string which corresponds to which instruction must be executed.
    """
    return ARITHMETIC_OPCODES[opcode]


# I could've just added this stuff and changed the above `get_arithmetic_opcode()`,
# but uhm, it's easy on the eye to see and get it done.
def get_logic_opcode(opcode: str) -> str:
    """
    Converts logical instruction names into corresponding 4-bit binary represenation.

    Arguments:
    ----------
    opcode: str
        Given is a LOGICAL instruction, i.e., (and, or, xnor, xor, etc.)

    Returns:
    --------
    str:
        4-bit binary string which corresponds to the opcode.
    """
    return LOGICAL_OPCODES[opcode]


def extract_arithmetic(instruction: ParsedInstruction) -> str:
    """Convert a register-register arithmetic instruction into 16-bit binary.

    Converts given instruction into 16-bit binary for *non-immediate value* arithmetic operations.

    Arguments:
    ----------
    instruction: list[str]
        Current arithmetic instruction in the `VR16-ASM` format.
    line: int
        Line number from the source file in which this current instruction is present.

    Returns:
    --------
    str:
        16-bit binary string representation of the given arithmetic instruction.

    Format::

        [opcode 4b][store_at 2b][operand_one 2b][operand_two 2b][dont_care 6b]
    """
    # Step 1: Look up the 4-bit binary opcode string.
    opcode: str = get_arithmetic_opcode(instruction.opcode)
    # Step 2: Validate and unpack the three register operands.
    operands: list[str] = _validate_operand_count(instruction, 3)

    # Step 3: Encode each register name to its 2-bit binary equivalent.
    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)
    operand_two: str = decode_register(operands[2], instruction.line_number)

    # Step 4: Assemble the full 16-bit string; lower 6 bits are don't-care (0).
    return f"{opcode}{store_at}{operand_one}{operand_two}000000"


def extract_immediate_arithmetic(instruction: ParsedInstruction) -> str:
    """Convert an immediate arithmetic instruction into 16-bit binary.

    Converts given instruction into 16-bit binary for *immediate value* arithmetic operations.

    Arguments:
    ----------
    instruction: list[str]
        Current arithmetic instruction in the `VR16-ASM` format.
    line: int
        Line number from the source file in which this current instruction is present.

    Returns:
    --------
    str:
        16-bit binary string representation of the given arithmetic instruction.

    Format::

        [opcode 4b][store_at 2b][imm10 10b]
    """
    # Step 1: Look up the 4-bit binary opcode string.
    opcode: str = get_arithmetic_opcode(instruction.opcode)
    # Step 2: Validate and unpack the register + immediate operands.
    operands: list[str] = _validate_operand_count(instruction, 2)

    # Step 3: Encode the destination register.
    store_at: str = decode_register(operands[0], instruction.line_number)
    # Step 4: Parse and validate the immediate integer value.
    try:
        immediate: int = int(operands[1])
    except ValueError as exc:
        raise ValueError(
            f"Invalid immediate at line {instruction.line_number}: {operands[1]!r}. "
            "Expected a base-10 integer in range 0 to 1023."
        ) from exc

    # Step 5: Validate that the immediate fits within the 10-bit field (0–1023).
    if immediate < 0 or immediate > 1023:
        raise ValueError(
            f"Invalid immediate at line {instruction.line_number}: {immediate}. "
            "Expected a base-10 integer in range 0 to 1023."
        )

    # Step 6: Format the immediate as a zero-padded 10-bit binary string.
    immediate_value: str = format(immediate, "010b")

    # Step 7: Assemble the full 16-bit string.
    return f"{opcode}{store_at}{immediate_value}"


def extract_logic_main(instruction: ParsedInstruction) -> str:
    """Convert a two-operand logical instruction into 16-bit binary.

    Converts given instruction into 16-bit binary for *2-operand* logical operations.

    Arguments:
    ----------
    instruction: list[str]
        Current logical instruction in the `VR16-ASM` format.
    line: int
        Line number from the source file in which this current instruction is present.

    Returns:
    --------
    str:
        16-bit binary string representation of the given logical instruction.

    Format::

        [opcode 4b][store_at 2b][operand_one 2b][operand_two 2b][dont_care 6b]
    """
    # Step 1: Look up the 4-bit binary logical opcode string.
    opcode: str = get_logic_opcode(instruction.opcode)
    # Step 2: Validate and unpack the three register operands.
    operands: list[str] = _validate_operand_count(instruction, 3)

    # Step 3: Encode each register.
    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)
    operand_two: str = decode_register(operands[2], instruction.line_number)

    # Step 4: Assemble the full 16-bit string; lower 6 bits are don't-care.
    return f"{opcode}{store_at}{operand_one}{operand_two}000000"


# Could've kept a better name, will change once my mind strikes with one.
# Saint: `extract_logic_unary` or `extract_not` would both be clear options!
def extract_logic_side(instruction: ParsedInstruction) -> str:
    """Convert a single-operand logical instruction (NOT) into 16-bit binary.

    Converts given instruction into 16-bit binary for *1-operand* logical operations.

    Arguments:
    ----------
    instruction: list[str]
        Current logical instruction in the `VR16-ASM` format.
    line: int
        Line number from the source file in which this current instruction is present.

    Returns:
    --------
    str:
        16-bit binary string representation of the given logical instruction.

    Format::

        [opcode 4b][store_at 2b][operand_one 2b][dont_care 8b]
    """
    # Step 1: Look up the NOT opcode binary string.
    opcode: str = get_logic_opcode(instruction.opcode)
    # Step 2: Validate and unpack the two register operands (dest + source).
    operands: list[str] = _validate_operand_count(instruction, 2)

    # Step 3: Encode the destination and source registers.
    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)

    # Step 4: Assemble the 16-bit string; lower 8 bits are don't-care (0).
    return f"{opcode}{store_at}{operand_one}00000000"


def extract_jump(instruction: ParsedInstruction) -> str:
    """Convert a jump instruction into 16-bit binary.

    Converts given instruction into 16-bit binary for jump operations.

    Arguments:
    ----------
    instruction: ParsedInstruction
        Current instruction in the `VR16-ASM` format.

    Returns:
    --------
    str:
        16-bit binary string representation of the given jump instruction.

    Format::

        [opcode 4b = 1001][jump_address 12b]
    """
    operands: list[str] = _validate_operand_count(instruction, 1)

    # Step 1: Parse and validate the jump target address from the operand string.
    try:
        jump_address: int = int(operands[0])
    except ValueError as exc:
        raise ValueError(
            f"Invalid jump address at line {instruction.line_number}: {operands[0]!r}. "
            "Expected a base-10 integer in range 0 to 4095."
        ) from exc

    # Step 2: Validate the address fits within the 12-bit jump address field.
    if jump_address < 0 or jump_address > 4095:
        raise ValueError(
            f"Invalid jump address at line {instruction.line_number}: {jump_address}. "
            "Expected a base-10 integer in range 0 to 4095."
        )

    # Step 3: Format the address as a zero-padded 12-bit binary string.
    jump_address_bits: str = format(jump_address, "012b")
    # Step 4: Prepend the fixed JUMP opcode (1001).
    return f"1001{jump_address_bits}"


def extract_delete(instruction: ParsedInstruction) -> str:
    """Convert a delete instruction into 16-bit binary.

    Converts given instruction into 16-bit binary for deletion of data from a register..

    Arguments:
    ----------
    instruction: list[str]
        Current instruction in the `VR16-ASM` format.
    line: int
        Line number from the source file in which this current instruction is present.

    Returns:
    --------
    str:
        16-bit binary string representation of the given delete instruction.

    Format::

        [opcode 4b = 1010][dest_reg 2b][dont_care 10b]
    """
    operands: list[str] = _validate_operand_count(instruction, 1)
    # Step 1: Encode the target register to its 2-bit binary representation.
    destination_register: str = decode_register(operands[0], instruction.line_number)

    # Step 2: Assemble the 16-bit string; lower 10 bits are don't-care.
    return f"1010{destination_register}0000000000"


def extract_halt(instruction: ParsedInstruction) -> str:
    """Convert a halt instruction into 16-bit binary.

    Converts given instruction into 16-bit binary for halt operations.

    Arguments:
    ----------
    instruction: list[str]
        Current instruction in the `VR16-ASM` format.

    Returns:
    --------
    str:
        16-bit binary string representation of the given halt instruction.

    Format::

        [opcode 4b = 1111][dont_care 12b = 000000000000]
    """
    # Step 1: Validate there are no operands (HALT takes none).
    _validate_operand_count(instruction, 0)
    # Step 2: Return the fixed HALT encoding; all lower bits are don't-care.
    return "1111000000000000"

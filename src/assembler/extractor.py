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

"""
Extractor functions for the VR16 assembler.

Each public function in this module accepts a :class:`ParsedInstruction` and
returns a 16-bit binary string (``"0"``/``"1"`` characters) ready to be
written as one line of a ``.mem`` file.

Module-level constants:
    ARITHMETIC_OPCODES      - Mapping of arithmetic mnemonic → 4-bit binary string.
    MEMORY_OPCODES          - ...
    LOGICAL_OPCODES         - Mapping of logical mnemonic → 4-bit binary string.
    REGISTER_VALUES         - Mapping of register name (r0–r3) → 2-bit binary string.
    SHIFT_DIRECTION         - ...
    CONDITIONAL_JUMP_CHECKS - ...
"""

from dataclasses import dataclass

from colorama import Back, Fore, Style

from assembler.baseclass import RegisterNotPresent

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

MEMORY_OPCODES: dict[str, str] = {"shift": "1000", "jmp": "1001", "cjmp": "1010"}

LOGICAL_OPCODES: dict[str, str] = {
    "and": "1011",
    "or": "1100",
    "not": "1101",
    "xor": "1110",
}

REGISTER_VALUES: dict[str, str] = {"r0": "00", "r1": "01", "r2": "10", "r3": "11"}

SHIFT_DIRECTION: dict[str, int] = {"left": 0, "right": 1}

CONDITIONAL_JUMP_CHECKS: dict[str, str] = {
    "jeq": "00",
    "jne": "01",
    "jgt": "10",
    "jlt": "11",
}


@dataclass
class ParsedInstruction:
    """
    Structured representation of a single decoded VR-ASM instruction line.

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
    """
    Validate that the instruction has the expected number of operands.

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


# bsod2528: I could've just added this stuff and changed the above `get_arithmetic_opcode()`,
# bsod2528: but uhm, it's easy on the eye to see and get it done.
def get_logic_opcode(opcode: str) -> str:
    """
    Converts logical instruction names into corresponding 4-bit binary representation.

    Arguments:
    ----------
    opcode: str
        Given is a LOGICAL instruction, i.e., (and, or, xnor, xor)

    Returns:
    --------
    str:
        4-bit binary string which corresponds to the opcode.
    """
    return LOGICAL_OPCODES[opcode]


def get_cjmp_condition(condition: str) -> str:
    """
    Converts conditonal jump condition into corresponding 2-bit binary representation.

    Arguments:
    ----------
    condition: str
        Given is a conditional jump check which corresponds to the 4 types of checks implemented.

    Returns:
    --------
    str:
        2-bit binary string which corresponds to the check implemented.
    """
    return CONDITIONAL_JUMP_CHECKS[condition]


def get_data_opcode(opcode: str) -> str:
    """
    Converts data instruction names into corresponding 4-bit binary representation.

    Arguments:
    ----------
    opcode: str
        Given is a DATA instruction, i.e., (shift, jmmp, cjmp)

    Returns:
    --------
    str:
        4-bit binary string which corresponds to the opcode.
    """
    return MEMORY_OPCODES[opcode]


def extract_arithmetic(instruction: ParsedInstruction) -> str:
    """
    Converts given instruction into 16-bit binary for register-register arithmetic operations.

    Arguments:
    ----------
    instruction: ParsedInstruction
        Current arithmetic instruction in the `VR16-ASM` format.

    Returns:
    --------
    str:
        16-bit binary string representation of the given arithmetic instruction.

    Format::
        [opcode 4b][store_at 2b][operand_one 2b][operand_two 2b][dont_care 6b]
    """
    opcode: str = get_arithmetic_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 3)

    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)
    operand_two: str = decode_register(operands[2], instruction.line_number)

    return f"{opcode}{store_at}{operand_one}{operand_two}000000"


def extract_immediate_arithmetic(instruction: ParsedInstruction) -> str:
    """
    Converts given instruction into 16-bit binary for register-immediate arithmetic operations.

    Arguments:
    ----------
    instruction: ParsedInstruction
        Current arithmetic instruction in the `VR16-ASM` format.

    Returns:
    --------
    str:
        16-bit binary string representation of the given arithmetic instruction.

    Format::
        [opcode 4b][store_at 2b][imm10 10b]
    """
    opcode: str = get_arithmetic_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 2)
    store_at: str = decode_register(operands[0], instruction.line_number)

    try:
        immediate: int = int(operands[1])
    except ValueError as exc:
        raise ValueError(
            f"Invalid immediate at line {instruction.line_number}: {operands[1]!r}. "
            "Expected a base-10 integer in range 0 to 1023."
        ) from exc

    if immediate < 0 or immediate > 1023:
        raise ValueError(
            f"Invalid immediate at line {instruction.line_number}: {immediate}. "
            "Expected a base-10 integer in range 0 to 1023."
        )

    immediate_value: str = format(immediate, "010b")
    return f"{opcode}{store_at}{immediate_value}"


def extract_logic_main(instruction: ParsedInstruction) -> str:
    """
    Converts given two-operand instruction into 16-bit binary for logical operations.

    Arguments:
    ----------
    instruction: ParsedInstruction
        Current logical instruction in the `VR16-ASM` format.

    Returns:
    --------
    str:
        16-bit binary string representation of the given logical instruction.

    Format::
        [opcode 4b][store_at 2b][operand_one 2b][operand_two 2b][dont_care 6b]
    """
    opcode: str = get_logic_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 3)

    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)
    operand_two: str = decode_register(operands[2], instruction.line_number)

    return f"{opcode}{store_at}{operand_one}{operand_two}000000"


# bsod2528: Could've kept a better name, will change once my mind strikes with one.
# Saint: `extract_logic_unary` or `extract_not` would both be clear options!
# bsod2528: `extract_not` it is, man it's so simple yet it doesn't strike this pea brain :sob:! Thank you!
def extract_not(instruction: ParsedInstruction) -> str:
    """
    Converts given instruction into 16-bit binary for not operation.

    Arguments:
    ----------
    instruction: list[str]
        Current logical instruction in the `VR16-ASM` format.
    line: int
        Line number from the source file in which this current instruction is present.

    Returns:
    --------
    str:
        16-bit binary string representation of the not instruction.

    Format::
        [opcode 4b][store_at 2b][operand_one 2b][dont_care 8b]
    """
    opcode: str = get_logic_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 2)

    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)

    return f"{opcode}{store_at}{operand_one}00000000"


def extract_shift(instruction: ParsedInstruction) -> str:
    """
    Converts given instruction into 16-bit binary for shifting of data in a register.

    Arguments:
    ---------
    instruction: ParsedInstruction
        Current shift instruction in the `VR16-ASM` format.

    Returns:
    --------
    str:
        16-bit binary string representation of the given shift instruction.

    Format::
        [opcode 4b][shift_at 2b][direction 1b][shift_ammount 9b]
    """
    opcode: str = get_data_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 3)
    store_at: str = decode_register(operands[0], instruction.line_number)
    direction: str = operands[1]

    if direction not in SHIFT_DIRECTION:
        raise ValueError(
            f"Invalid direction given at line {instruction.line_number}: {direction}. Expected either "
            f"{Fore.BLACK + Back.WHITE + Style.BRIGHT}left{Style.RESET_ALL}"
            f" or {Fore.BLACK + Back.WHITE + Style.BRIGHT}right{Style.RESET_ALL}"
        )
    else:
        if direction == "left":
            direction = SHIFT_DIRECTION["left"]
        else:
            direction = SHIFT_DIRECTION["right"]

        try:
            immediate: int = int(operands[2])
        except ValueError as exception:
            raise ValueError(
                f"Invalid immediate at line {instruction.line_number}: {operands[1]!r}. "
                "Expected a base-10 integer in range 0 to 511."
            ) from exception

        if immediate < 0 or immediate > 511:
            raise ValueError(
                f"Invalid immediate at line {instruction.line_number}: {immediate}. "
                "Expected a base-10 integer in range 0 to 511."
            )

    immediate_value: str = format(immediate, "09b")
    return f"{opcode}{store_at}{direction}{immediate_value}"


def extract_jump(instruction: ParsedInstruction) -> str:
    """
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
        [opcode 4b][jump_address 12b]
    """
    operands: list[str] = _validate_operand_count(instruction, 1)

    try:
        jump_address: int = int(operands[0])
    except ValueError as exc:
        raise ValueError(
            f"Invalid jump address at line {instruction.line_number}: {operands[0]!r}. "
            "Expected a base-10 integer in range 0 to 4095."
        ) from exc

    if jump_address < 0 or jump_address > 4095:
        raise ValueError(
            f"Invalid jump address at line {instruction.line_number}: {jump_address}. "
            "Expected a base-10 integer in range 0 to 4095."
        )

    jump_address_bits: str = format(jump_address, "012b")
    return f"1001{jump_address_bits}"


def extract_conditional_jump(instruction: ParsedInstruction) -> str:
    """
    Converts the given conditional jumping instruction into 16-bit binary.

    Arguments:
    ----------
    instruction: ParsedInstruction
        Current conditional jump instruction in the `VR16-ASM` format.

    Returns:
    --------
    str:
        16-bit binary string representation of the conditional jump instruction.

    Format::
        [opcode 4b][reg_to_check 2b][condition 2b][jump_address 8b]
    """
    operands: list[str] = _validate_operand_count(instruction, 3)
    reg_to_check: str = decode_register(operands[0], instruction.line_number)
    condition_to_run: str = operands[1]
    condition_to_run: str = get_cjmp_condition(condition_to_run)

    try:
        jump_address: int = int(operands[2])
    except ValueError as exception:
        raise ValueError(
            f"Invalid jump address at line {instruction.line_number}: {operands[0]!r}. "
            "Expected a base-10 integer in range 0 to 255."
        ) from exception

    if jump_address < 0 or jump_address > 255:
        raise ValueError(
            f"Invalid jump address at line {instruction.line_number}: {jump_address}. "
            "Expected a base-10 integer in range 0 to 255."
        )

    # bsod2528: I was adding support for cjmp and uh I was constantly getting a `OpcodeNotPresent` error
    # bsod2528: despite updating it everywhere!
    # bsod2528: All I had to do was genuinely just add a temporary `return "1010000000000000" and it worked.
    # bsod2528: _insert shrek donkey stare meme_
    jump_address_bits: str = format(jump_address, "08b")
    return f"1010{reg_to_check}{condition_to_run}{jump_address_bits}"


def return_halt(instruction: ParsedInstruction) -> str:
    """
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
        [opcode 4b][dont_care 12b]
    """
    _validate_operand_count(instruction, 0)
    return "1111000000000000"

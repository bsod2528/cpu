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
    opcode: str
    operands: list[str]
    line_number: int


def _validate_operand_count(
    instruction: ParsedInstruction, expected_operands: int
) -> list[str]:
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
    """
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
    """
    opcode: str = get_arithmetic_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 3)

    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)
    operand_two: str = decode_register(operands[2], instruction.line_number)

    return f"{opcode}{store_at}{operand_one}{operand_two}000000"


def extract_immediate_arithmetic(instruction: ParsedInstruction) -> str:
    """
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
    """
    opcode: str = get_arithmetic_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 2)

    store_at: str = decode_register(operands[0], instruction.line_number)
    immediate: int = int(operands[1])
    if immediate < 0 or immediate > 1023:
        raise ValueError(
            f"Immediate value out of range at line {instruction.line_number}: {immediate}. Expected 0 to 1023."
        )

    immediate_value: str = format(immediate, "010b")

    return f"{opcode}{store_at}{immediate_value}"


def extract_logic_main(instruction: ParsedInstruction) -> str:
    """
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
    """
    opcode: str = get_logic_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 3)

    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)
    operand_two: str = decode_register(operands[2], instruction.line_number)

    return f"{opcode}{store_at}{operand_one}{operand_two}000000"


# Could've kept a better name, will change once my mind strikes with one.
def extract_logic_side(instruction: ParsedInstruction) -> str:
    """
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
    """
    opcode: str = get_logic_opcode(instruction.opcode)
    operands: list[str] = _validate_operand_count(instruction, 2)

    store_at: str = decode_register(operands[0], instruction.line_number)
    operand_one: str = decode_register(operands[1], instruction.line_number)

    return f"{opcode}{store_at}{operand_one}00000000"


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
    """
    operands: list[str] = _validate_operand_count(instruction, 1)

    jump_address: int = int(operands[0])
    if jump_address < 0 or jump_address > 4095:
        raise ValueError(
            f"Jump address out of range at line {instruction.line_number}: {jump_address}. Expected 0 to 4095."
        )

    jump_address_bits: str = format(jump_address, "012b")
    return f"1001{jump_address_bits}"


def extract_delete(instruction: ParsedInstruction) -> str:
    """
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
    """
    operands: list[str] = _validate_operand_count(instruction, 1)
    destination_register: str = decode_register(operands[0], instruction.line_number)

    return f"1010{destination_register}0000000000"


def extract_halt(instruction: ParsedInstruction) -> str:
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
    """
    _validate_operand_count(instruction, 0)
    return f"1111000000000000"

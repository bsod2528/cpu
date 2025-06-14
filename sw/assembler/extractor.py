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


def extract_arithmetic(instruction: list[str], line: str) -> str:
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
    try:
        opcode: str = get_arithmetic_opcode(instruction[4])
        store_at: str = decode_register(instruction[5].strip(","), line)
        operand_one: str = decode_register(instruction[6].strip(","), line)
        operand_two: str = decode_register(instruction[7], line)

        return f"{opcode}{store_at}{operand_one}{operand_two}xxxxxx"
    except Exception as error:
        print(error)


# TODO: Raise error when the immediate value provided is more than 1023
# (in decimal)
def extract_immediate_arithmetic(instruction: list[str], line: int) -> str:
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
    try:
        opcode: str = get_arithmetic_opcode(instruction[4])
        store_at: str = decode_register(instruction[5].strip(","), line)
        temp: int = int(instruction[6])
        temp: str = f"{temp:b}"
        immediate_value: str = f"{temp.zfill(16 - 4 - 2)}"

        return f"{opcode}{store_at}{immediate_value}"
    except Exception as error:
        print(error)


def extract_logic_main(instruction: list[str], line: int) -> str:
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
    try:
        opcode: str = get_logic_opcode(instruction[4])
        store_at: str = decode_register(instruction[5].strip(","), line)
        operand_one: str = decode_register(instruction[6].strip(","), line)
        operand_two: str = decode_register(instruction[7], line)

        return f"{opcode}{store_at}{operand_one}{operand_two}xxxxxx"
    except Exception as error:
        print(error)


# Could've kept a better name, will change once my mind strikes with one.
def extract_logic_side(instruction: list[str], line: int) -> str:
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
    try:
        opcode: str = get_logic_opcode(instruction[4])
        store_at: str = decode_register(instruction[5].strip(","), line)
        operand_one: str = decode_register(instruction[6].strip(","), line)

        return f"{opcode}{store_at}{operand_one}xxxxxxxx"
    except Exception as error:
        print(error)


def extract_jump(instruction: list[str]) -> None:
    """
    This hasn't been done, as there is a logical dilemma going in my head regarding the working of this.
    """
    return None


def extract_delete(instruction: list[str], line: int) -> str:
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
    try:
        destination_register: str = decode_register(instruction[5], line)

        return f"1010{destination_register}xxxxxxxxxx"
    except Exception as error:
        print(error)


def extract_halt(instruction: list[str]) -> str:
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
    try:
        return f"1111xxxxxxxxxxxx"
    except Exception as error:
        print(error)

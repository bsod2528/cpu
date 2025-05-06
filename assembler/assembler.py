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

import typer
from colorama import Fore, Back, Style

from baseclass import OpcodeNotPresent

from extractor import (
    extract_arithmetic,
    extract_immediate_arithmetic,
    extract_logic_main,
    extract_logic_side,
    extract_jump,
    extract_delete,
    extract_halt,
)


with open("../asm source files/not_gate.asm") as source:
    lines: list[str] = []

    for line in source:
        lines.append(line.strip("\n"))

# This is to "clear" the file so that everything gets appended later on.
# This file hasn't been git-ignored as you can see the "latest" mem file
# based on given input asm.
with open("../memory files/write_imem.mem", "w") as imem_to_clear:
    imem_to_clear.write("")


total_lines: int = len(lines)
start_present: bool = False
list_index: int = 0
result: str = ""

# As of date 23-04-25, it struck my mind that I have "duplicate" instructions.
# `storei`: adds immediate value into a register, for some bizzare reason I've kept it as 8-bit.
# The same thing is done by `addi`.
# I'll change the ISA later on but uhh yeah :moyai:


def choose_extractor(opcode: str, instruction: list[str], line: int) -> str | None:
    """
    Based on opcode, extraction is done.

    Arguments:
    ----------
    opcode: str
        To decide which extractor must be used.
    instruction: list[str]
        Current instruction in the `VR16-ASM` format which has to be passed on to the
        extractor.
    line: int
        Line number from the source file in which this current instruction is present.

    Returns:
    --------
    str:
        Output of the extractor function chosen which is essentially a string representation
        of the binary machine code.
    """
    if opcode in ["add", "sub", "mul", "div"]:
        return extract_arithmetic(instruction, line)
    if opcode in ["addi", "subi", "muli", "divi"]:
        return extract_immediate_arithmetic(instruction, line)
    if opcode == "jump":
        return extract_jump(instruction, line)
    if opcode == "delete":
        return extract_delete(instruction, line)
    if opcode in ["and", "or", "xor"]:
        return extract_logic_main(instruction, line)
    if opcode == "not":
        return extract_logic_side(instruction, line)
    if opcode == "halt":
        return extract_halt(instruction)

    return None


while list_index != total_lines:
    current_instruction = lines[list_index].strip(";").split(" ")

    print(
        Fore.BLUE
        + Style.BRIGHT
        + "INFO"
        + Style.RESET_ALL
        + ": "
        + f"{list_index} -> {current_instruction}"
        + Style.RESET_ALL
    )

    if current_instruction[0].startswith("--") or (current_instruction[0] == " "):
        list_index = list_index + 1
        continue

    if current_instruction[0] == "start:":
        list_index = list_index + 1
        start_present = True
        continue

    if current_instruction[0] == "end:":
        break

    if start_present:
        try:
            opcode = current_instruction[4]
            result = choose_extractor(opcode, current_instruction, list_index + 1)

            if result is None:
                raise OpcodeNotPresent(opcode, list_index + 1)

            with open("../memory files/write_imem.mem", "a") as imem:
                imem.write(f"{result}\n")
        except OpcodeNotPresent as error:
            print(error)
            break

    list_index = list_index + 1

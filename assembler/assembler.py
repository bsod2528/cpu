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


from extractor import (
    extract_arithmetic,
    extract_immediate_arithmetic,
    extract_logic_main,
    extract_logic_side,
    extract_jump,
    extract_delete,
    extract_halt,
)


with open("../asm source files/add.asm") as source:
    lines: list[str] = []

    for line in source:
        lines.append(line.strip("\n"))

# This is to "clear" the file so that everything gets appended later on.
# This file hasn't been git-ignored as you can see the "latest" mem file based on given input asm.
with open("../memory files/write_imem.mem", "w") as imem_to_clear:
    imem_to_clear.write("")


total_lines: int = len(lines)
list_index: int = 0


# As of date 23-04-25, it struck my mind that I have "duplicate" instructions.
# `storei`: adds immediate value into a register, for some bizzare reason I've kept it as 8-bit.
# The same thing is done by `addi`.
# I'll change the ISA later on but uhh yeah :moyai:


def choose_extractor(opcode: str, instruction: list[str]) -> str | None:
    """
    Based on opcode, extraction is done.

    Arguments:
    ----------
    opcode: str
        To decide which extractor must be used.
    instruction: list[str]
        Current instruction in the `VR16-ASM` format which has to be passed on to the
        extractor.
    """
    if opcode in ["add", "sub", "mul", "div"]:
        return extract_arithmetic(instruction)
    if opcode in ["addi", "subi", "muli", "divi"]:
        return extract_immediate_arithmetic(instruction)
    if opcode == "jump":
        return extract_jump(instruction)
    if opcode == "delete":
        return extract_delete(instruction)
    if opcode in ["and", "or", "xor"]:
        return extract_logic_main(instruction)
    if opcode == "not":
        return extract_logic_side(instruction)
    if opcode == "halt":
        return extract_halt(instruction)


# TODO: Make the assembler bit better and change syntax of asm to:
# ```asm
# start;
#   addi r0, 1;
#   addi r2, 10;
#   and r0, r0, r2;
#   halt
# end;
# ```
# Like a proper compiler / interpreter or however that works.


while list_index != total_lines:
    current_instruction = lines[list_index].strip(";").split(" ")

    print(current_instruction)

    result = choose_extractor(current_instruction[0], current_instruction)
    print(f"--> {result}")

    with open("../memory files/write_imem.mem", "a") as imem:
        imem.write(f"{result}\n")

    list_index = list_index + 1

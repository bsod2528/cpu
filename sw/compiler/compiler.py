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
    extract_register_variables,
    extract_for,
    current_for_iteration_value,
)

# This won't be running this code for now.
# I don't even know if this can be considered as a compiler.
# Games the game.

with open("./add.vrs") as source:
    lines: list[str] = []

    for line in source:
        lines.append(line.strip("\n"))

with open("../asm source files/compiled.asm", "w") as output_asm:
    output_asm.write("start:\n")

total_lines: int = len(lines)
list_index: int = 0


def parser(line: str, line_number: int) -> str:
    """"""

    if line.startswith(("r0", "r1", "r2", "r3")):
        return extract_register_variables(line)

    if line.startswith(("add", "sub", "mul", "div")):
        return extract_arithmetic(line)

    # TODO: SO BAD, SO BAD SO BAD GOD HELP.
    # I'm supposed to be doing the control-unit not this.

    # if line.startswith("for"):
    #     return extract_for(line, line_number)


def for_loop_append():
    """"""
    temp: int = 0

    while temp != current_for_iteration_value:
        with open("../asm source files/compiled.asm", "w") as output_asm:
            output_asm.write(f"\n{result}\n")
        temp = temp + 1
        break


while list_index != total_lines:
    code = lines[list_index]

    # comments integration
    if code[0:2] == "``":
        list_index = list_index + 1
        continue

    result = parser(code, list_index + 1)

    if result is None:
        list_index = list_index + 1
        continue

    if code[0:3] == "for":
        for_loop_append()

    with open("../asm source files/compiled.asm", "a") as output_asm:
        if result is not None:
            output_asm.write(f"\t{result}\n")

    list_index = list_index + 1

with open("../asm source files/compiled.asm", "a") as output_asm:
    output_asm.write("end:\n")

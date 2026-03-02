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

global current_for_iteration_value

current_for_iteration_value: str = "10"


def extract_arithmetic(line: str) -> str:
    """"""
    opcode: str = line[0:3]
    store_at: str = line[4:6]
    operand_one: str = line[8:10]
    operand_two: str = line[12:14]

    return f"{opcode} {store_at}, {operand_one}, {operand_two};"


def extract_register_variables(line: str) -> str:
    """"""
    if line[1] == "0":
        return f"addi r0, {line[5:]};"
    if line[1] == "1":
        return f"addi r1, {line[5:]};"
    if line[1] == "2":
        return f"addi r2, {line[5:]};"
    if line[1] == "3":
        return f"addi r3, {line[5:]};"


def extract_for(line: str, line_number: int) -> str:
    """"""
    for_var: str = line[4]  # to find out the "variable" thats used in the iteration
    for_var_line: int = 0  # to find out the line it's happening at
    for_var_value: str = ""  # the variables = ___, that value lol
    current_for_iteration_value = line[9:12]  # number of times to iterate

    register_to_interate_on: str = ""
    register_operation: str = ""
    register_operand: str = ""

    # Stupid move, but hey it works.
    with open("./add.vrs") as _source:
        _lines: list[str] = []

        for _line in _source:
            _lines.append(_line.strip("\n"))

        meta = 1
        for code in _lines:
            if line in code:
                for_var_line = meta

            meta = meta + 1

        for key, value in enumerate(_lines, 1):
            if key == 7:
                for_var_value = value[4:]

            if key == for_var_line + 1:
                # print(value.strip(" "))
                temp = value.strip(" ")

                register_to_interate_on = temp[0:2]
                register_operation = temp[3:5]
                register_operand = temp[6:]

    temp: int = 0
    while temp != current_for_iteration_value:
        if register_operation == "++":
            return f"addi {register_to_interate_on}, {register_operand}"
        if register_operation == "--":
            return f"subi {register_to_interate_on}, {register_operand}"
        if register_operation == "**":
            return f"muli {register_to_interate_on}, {register_operand}"
        if register_operation == "//":
            return f"divi {register_to_interate_on}, {register_operand}"
        temp = temp + 1

    # print(f"{register_to_interate_on}\n{register_operation}\n{register_operand}")
    # print(f"for variable: {for_var}\niteration line at: {for_var_line}\n{for_var} = {for_var_value}\niterate times: {current_for_iteration_value}")

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

import argparse
from pathlib import Path

from colorama import Fore, Style

from baseclass import OpcodeNotPresent

from extractor import (
    ParsedInstruction,
    extract_arithmetic,
    extract_immediate_arithmetic,
    extract_logic_main,
    extract_logic_side,
    extract_jump,
    extract_delete,
    extract_halt,
)

# As of date 23-04-25, it struck my mind that I have "duplicate" instructions.
# `storei`: adds immediate value into a register, for some bizzare reason I've kept it as 8-bit.
# The same thing is done by `addi`.
# I'll change the ISA later on but uhh yeah :moyai:


def parse_instruction_line(raw_line: str, line_number: int) -> ParsedInstruction | None:
    trimmed_line: str = raw_line.strip()
    if not trimmed_line:
        return None

    tokens: list[str] = trimmed_line.strip(";").split()
    if not tokens or tokens[0].startswith("--"):
        return None

    if tokens[0] in ["start:", "end:"]:
        return ParsedInstruction(opcode=tokens[0], operands=[], line_number=line_number)

    cleaned_tokens: list[str] = [token.strip(",") for token in tokens]
    opcode: str = cleaned_tokens[0]
    operands: list[str] = cleaned_tokens[1:]

    expected_operands_by_opcode: dict[str, int] = {
        "add": 3,
        "sub": 3,
        "mul": 3,
        "div": 3,
        "addi": 2,
        "subi": 2,
        "muli": 2,
        "divi": 2,
        "and": 3,
        "or": 3,
        "xor": 3,
        "not": 2,
        "delete": 1,
        "halt": 0,
        "jump": 1,
    }

    if opcode in expected_operands_by_opcode:
        expected_operands: int = expected_operands_by_opcode[opcode]
        if len(operands) != expected_operands:
            raise ValueError(
                f"Syntax error at line {line_number}: opcode '{opcode}' expects "
                f"{expected_operands} operand(s), got {len(operands)}. "
                f"Line content: '{raw_line.strip()}'"
            )

    return ParsedInstruction(opcode=opcode, operands=operands, line_number=line_number)


def choose_extractor(instruction: ParsedInstruction) -> str | None:
    """
    Based on opcode, extraction is done.

    Arguments:
    ----------
    instruction: ParsedInstruction
        Structured instruction with opcode, operands and source line number.

    Returns:
    --------
    str:
        Output of the extractor function chosen which is essentially a string representation
        of the binary machine code.
    """
    opcode: str = instruction.opcode

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

    return None


def assemble(source_path: str, output_path: str) -> None:
    source = Path(source_path)
    output = Path(output_path)

    with source.open() as source_file:
        lines: list[str] = [line.strip("\n") for line in source_file]

    # This is to "clear" the file so that everything gets appended later on.
    # This file hasn't been git-ignored as you can see the "latest" mem file
    # based on given input asm.
    output.write_text("")

    total_lines: int = len(lines)
    start_present: bool = False
    list_index: int = 0

    while list_index != total_lines:
        line_number: int = list_index + 1
        try:
            parsed_instruction: ParsedInstruction | None = parse_instruction_line(
                lines[list_index], line_number
            )
        except ValueError as error:
            print(error)
            break

        print(
            Fore.BLUE
            + Style.BRIGHT
            + "INFO"
            + Style.RESET_ALL
            + ": "
            + f"{list_index} -> {parsed_instruction}"
            + Style.RESET_ALL
        )

        if parsed_instruction is None:
            list_index = list_index + 1
            continue

        if parsed_instruction.opcode == "start:":
            list_index = list_index + 1
            start_present = True
            continue

        if parsed_instruction.opcode == "end:":
            break

        if start_present:
            try:
                result = choose_extractor(parsed_instruction)

                if result is None:
                    raise OpcodeNotPresent(parsed_instruction.opcode, line_number)

                with output.open("a") as imem:
                    imem.write(f"{result}\n")
            except (OpcodeNotPresent, ValueError) as error:
                print(error)
                break

        list_index = list_index + 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Assemble VR16 assembly into machine code.")
    parser.add_argument(
        "source_path",
        nargs="?",
        default="../../examples/vr-asm/add.asm",
        help="Path to the source assembly file.",
    )
    parser.add_argument(
        "output_path",
        nargs="?",
        default="../../mem/imem.mem",
        help="Path to write assembled machine code.",
    )
    args = parser.parse_args()
    assemble(args.source_path, args.output_path)

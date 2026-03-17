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
VR16 assembler: converts VR-ASM source files into binary `.mem` files.

The assembler performs a single-pass translation of a VR-ASM text file into
binary machine code understood by the VR16 instruction memory.

Workflow:
    1. Read all lines from the source ``.asm`` file.
    2. Parse/encode every instruction into an in-memory list first.
    3. Iterate line by line, skipping blanks and comments (``--`` prefix).
    4. Honour ``start:`` / ``end:`` delimiters — only encode instructions
       that appear between them.
    5. Only after successful parsing/encoding of the full source, write the
       complete result to the output file in one go.

Usage (CLI)::

    python3 -m assembler [source_path] [output_path]

    Defaults:
        source_path  = examples/vr-asm/add.asm
        output_path  = mem/imem.mem
"""

import argparse
import sys
from pathlib import Path

from colorama import Fore, Style

from assembler.baseclass import OpcodeNotPresent, RegisterNotPresent, SourceNotFound
from assembler.extractor import (
    ParsedInstruction,
    extract_arithmetic,
    extract_conditional_jump,
    extract_immediate_arithmetic,
    extract_jump,
    extract_logic_main,
    extract_not,
    extract_shift,
    return_halt,
)

# bsod2528: As of date 23-04-25, it struck my mind that I have "duplicate" instructions.
# bsod2528: `storei`: adds immediate value into a register, for some bizzare reason I've kept it as 8-bit.
# bsod2528: The same thing is done by `addi`.
# bsod2528: I'll change the ISA later on but uhh yeah :moyai:
# Saint: Noted — STOREI vs ADDI duplication is tracked. When STOREI gets its
# Saint: own semantics (e.g. absolute store, not accumulate) it will justify its slot.
# bsod2528: ISA has been changed as of 13-03-2026.


def parse_instruction_line(raw_line: str, line_number: int) -> ParsedInstruction | None:
    """
    Parse a single source line into a :class:`ParsedInstruction` or ``None``.

    Strips inline comments (everything after ``--``), trims whitespace, and
    tokenises the remainder.  Validates that the operand count matches the
    expected count for the detected opcode and raises :class:`ValueError` on
    a mismatch.

    Arguments:
    ----------
    raw_line: str
        The raw, unprocessed line from the source ``.asm`` file including any
        trailing newline characters.
    line_number: int
        1-based line number used in error messages.

    Returns:
    --------
    ParsedInstruction | None:
        A structured instruction if the line contains a valid opcode, or
        ``None`` if the line is blank or comment-only.

    Raises:
    -------
    ValueError:
        When the operand count does not match the expected count for the opcode.
    """
    line_without_comment: str = raw_line.split("--", 1)[0]
    trimmed_line: str = line_without_comment.strip()
    if not trimmed_line:
        return None

    tokens: list[str] = trimmed_line.strip(";").split()
    if not tokens:
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
        "shift": 3,
        "jmp": 1,
        "cjmp": 3,
        "and": 3,
        "or": 3,
        "xor": 3,
        "not": 2,
        "halt": 0,
    }

    if opcode in expected_operands_by_opcode:
        expected_operands: int = expected_operands_by_opcode[opcode]
        if len(operands) != expected_operands:
            raise ValueError(
                f"Syntax error at line {line_number}: opcode '{opcode}' expects "
                f"{expected_operands} operand(s), got {len(operands)}. "
                f"Line content: '{raw_line.strip()}'"
            )

    # Step 9: Return the structured instruction for further processing.
    return ParsedInstruction(opcode=opcode, operands=operands, line_number=line_number)


def choose_extractor(instruction: ParsedInstruction) -> str | None:
    """
    Select and invoke the correct extractor function for the given opcode.

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
    None:
        When the opcode has no registered extractor (unknown / unimplemented).
    """
    opcode: str = instruction.opcode

    if opcode in ["add", "sub", "mul", "div"]:
        return extract_arithmetic(instruction)
    if opcode in ["addi", "subi", "muli", "divi"]:
        return extract_immediate_arithmetic(instruction)
    if opcode == "shift":
        return extract_shift(instruction)
    if opcode == "jmp":
        return extract_jump(instruction)
    if opcode == "cjmp":
        return extract_conditional_jump(instruction)
    if opcode in ["and", "or", "xor"]:
        return extract_logic_main(instruction)
    if opcode == "not":
        return extract_not(instruction)
    if opcode == "halt":
        return return_halt(instruction)

    return None


class AssemblerError(Exception):
    """Structured assembler failure with line context."""

    def __init__(self, line_number: int, message: str) -> None:
        super().__init__(message)
        self.line_number = line_number
        self.message = message

    def __str__(self) -> str:
        return self.message


def assemble(source_path: str, output_path: str) -> None:
    """
    Assemble a VR-ASM source file into a binary `.mem` output file.

    Reads the source file line by line, parses each instruction, and collects
    resulting 16-bit binary strings in memory. Only instructions between
    ``start:`` and ``end:`` delimiters are emitted.

    File-write behavior on failures:
    - If parsing/encoding fails at any point, this function raises
      :class:`AssemblerError` and **does not modify** ``output_path``.
    - ``output_path`` is only overwritten after full successful assembly.

    Arguments:
    ----------
    source_path: str
        Path to the input VR-ASM ``.asm`` file.
    output_path: str
        Path to the output binary ``.mem`` file. The file is overwritten only
        when full assembly succeeds.
    """
    source = Path(source_path)
    output = Path(output_path)

    try:
        with source.open() as source_file:
            lines: list[str] = [line.strip("\n") for line in source_file]
    except FileNotFoundError:
        raise SourceNotFound(source) from None

    # Saint2706: Collect encoded machine-code lines in memory first.
    # This guarantees we never leave partially-written output on errors.
    encoded_lines: list[str] = []

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
            raise AssemblerError(line_number, str(error)) from error

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

                encoded_lines.append(result)
            except (
                OpcodeNotPresent,
                ValueError,
                RegisterNotPresent,
                SourceNotFound,
            ) as error:
                raise AssemblerError(line_number, str(error)) from error

        list_index = list_index + 1

    final_text: str = "\n".join(encoded_lines)
    if encoded_lines:
        final_text = f"{final_text}\n"
    output.write_text(final_text)


def main() -> None:
    """Entry point: parse CLI args and run the assembler."""
    parser = argparse.ArgumentParser(
        description="Assemble VR16 assembly into machine code."
    )
    parser.add_argument(
        "source_path",
        nargs="?",
        default="examples/vr-asm/add.asm",
        help="Path to the source assembly file.",
    )
    parser.add_argument(
        "output_path",
        nargs="?",
        default="mem/imem.mem",
        help="Path to write assembled machine code.",
    )
    args = parser.parse_args()
    try:
        assemble(args.source_path, args.output_path)
    except AssemblerError as error:
        print(error)
        sys.exit(1)

    sys.exit(0)


if __name__ == "__main__":
    main()

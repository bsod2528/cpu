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

"""VR16 assembler: converts VR-ASM source files into binary `.mem` files.

The assembler performs a single-pass translation of a VR-ASM text file into
binary machine code understood by the VR16 instruction memory.

Workflow:
    1. Read all lines from the source ``.asm`` file.
    2. Clear the output ``.mem`` file so previous results are not preserved.
    3. Iterate line by line, skipping blanks and comments (``--`` prefix).
    4. Honour ``start:`` / ``end:`` delimiters — only encode instructions
       that appear between them.
    5. For each valid instruction, delegate to the appropriate extractor
       function and append the resulting 16-bit binary string.

Usage (CLI)::

    python3 assembler.py [source_path] [output_path]

    Defaults:
        source_path  = ../../examples/vr-asm/add.asm
        output_path  = ../../mem/imem.mem
"""

import argparse
import sys
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
# Saint: Noted — STOREI vs ADDI duplication is tracked. When STOREI gets its
# Saint: own semantics (e.g. absolute store, not accumulate) it will justify its slot.


def parse_instruction_line(raw_line: str, line_number: int) -> ParsedInstruction | None:
    """Parse a single source line into a :class:`ParsedInstruction` or ``None``.

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
    # Step 1: Strip everything after the comment delimiter `--`.
    line_without_comment: str = raw_line.split("--", 1)[0]
    # Step 2: Remove leading / trailing whitespace from the remaining text.
    trimmed_line: str = line_without_comment.strip()
    # Step 3: Skip blank lines (comment-only lines become blank after step 1).
    if not trimmed_line:
        return None

    # Step 4: Remove trailing semicolons and split into tokens.
    tokens: list[str] = trimmed_line.strip(";").split()
    if not tokens:
        return None

    # Step 5: Handle special delimiter tokens (`start:` / `end:`) directly.
    if tokens[0] in ["start:", "end:"]:
        return ParsedInstruction(opcode=tokens[0], operands=[], line_number=line_number)

    # Step 6: Strip commas from each token so `add r0, r1, r2` and
    #         `add r0 r1 r2` are handled identically.
    cleaned_tokens: list[str] = [token.strip(",") for token in tokens]
    opcode: str = cleaned_tokens[0]
    operands: list[str] = cleaned_tokens[1:]

    # Step 7: Look up the expected operand count for the opcode.
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

    # Step 8: Validate the operand count and raise a descriptive error on mismatch.
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
    """Select and invoke the correct extractor function for the given opcode.

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

    # Step 1: Route arithmetic register-register operations.
    if opcode in ["add", "sub", "mul", "div"]:
        return extract_arithmetic(instruction)
    # Step 2: Route arithmetic immediate operations.
    if opcode in ["addi", "subi", "muli", "divi"]:
        return extract_immediate_arithmetic(instruction)
    # Step 3: Route control-flow — jump instruction.
    if opcode == "jump":
        return extract_jump(instruction)
    # Step 4: Route register-clear operation.
    if opcode == "delete":
        return extract_delete(instruction)
    # Step 5: Route two-operand logical operations.
    if opcode in ["and", "or", "xor"]:
        return extract_logic_main(instruction)
    # Step 6: Route single-operand logical operation (NOT).
    if opcode == "not":
        return extract_logic_side(instruction)
    # Step 7: Route halt.
    if opcode == "halt":
        return extract_halt(instruction)

    # Step 8: Return None for unrecognised opcodes; the caller raises an error.
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
    """Assemble a VR-ASM source file into a binary `.mem` output file.

    Reads the source file line by line, parses each instruction, and appends
    the resulting 16-bit binary string to the output file.  Only instructions
    between ``start:`` and ``end:`` delimiters are emitted.

    Arguments:
    ----------
    source_path: str
        Path to the input VR-ASM ``.asm`` file.
    output_path: str
        Path to the output binary ``.mem`` file.  The file is truncated to
        empty before writing to avoid stale data from a previous run.
    """
    source = Path(source_path)
    output = Path(output_path)

    # Step 1: Read all lines from the source file, stripping trailing newlines.
    with source.open() as source_file:
        lines: list[str] = [line.strip("\n") for line in source_file]

    # This is to "clear" the file so that everything gets appended later on.
    # This file hasn't been git-ignored as you can see the "latest" mem file
    # based on given input asm.
    # Saint: Good practice — truncating first prevents leftover instructions
    # Saint: from a longer previous program from silently remaining in the file.
    # Step 2: Truncate the output file so only the current assembly is written.
    output.write_text("")

    total_lines: int = len(lines)
    start_present: bool = False  # Tracks whether `start:` has been seen.
    list_index: int = 0

    # Step 3: Iterate through every source line.
    while list_index != total_lines:
        line_number: int = list_index + 1
        try:
            # Step 4: Parse the current line into a structured instruction (or None).
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

        # Step 5: Skip blank / comment-only lines.
        if parsed_instruction is None:
            list_index = list_index + 1
            continue

        # Step 6: When `start:` is encountered, set the active encoding flag.
        if parsed_instruction.opcode == "start:":
            list_index = list_index + 1
            start_present = True
            continue

        # Step 7: When `end:` is encountered, stop processing immediately.
        if parsed_instruction.opcode == "end:":
            break

        # Step 8: Only encode instructions that appear inside start:/end: block.
        if start_present:
            try:
                # Step 9: Delegate to the correct extractor and get binary string.
                result = choose_extractor(parsed_instruction)

                if result is None:
                    raise OpcodeNotPresent(parsed_instruction.opcode, line_number)

                # Step 10: Append the binary string (one instruction per line).
                with output.open("a") as imem:
                    imem.write(f"{result}\n")
            except (OpcodeNotPresent, ValueError) as error:
                raise AssemblerError(line_number, str(error)) from error

        list_index = list_index + 1


if __name__ == "__main__":
    # Step 11: Build the CLI argument parser with sensible defaults so the
    #          assembler can be run without arguments during development.
    parser = argparse.ArgumentParser(
        description="Assemble VR16 assembly into machine code."
    )
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
    # Step 12: Run the assembler with the provided (or default) paths.
    try:
        assemble(args.source_path, args.output_path)
    except AssemblerError as error:
        print(error)
        sys.exit(1)

    sys.exit(0)

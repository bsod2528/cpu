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

"""Extractor and parser utilities for the VRScript compiler.

This module provides the low-level parsing and translation functions used
by the VRScript compiler to convert individual language constructs into
VR-ASM instruction strings.

Module-level constants:
    ARITHMETIC_OPCODES - Tuple of supported arithmetic instruction prefixes.
    REGISTER_PREFIXES  - Tuple of valid register name prefixes (r0–r3).
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class ForLoopSpec:
    """Representation of a parsed vrscript for-loop header and body.

    Attributes:
    -----------
    loop_var: str
        The loop variable name (e.g. ``"i"``); informational only in VRScript.
    iterations: int
        Number of times the loop body is unrolled.
    register: str
        The register operated on inside the loop body (e.g. ``"r3"``).
    operation: str
        The loop body operator: ``"++"`` , ``"--"``, ``"**"``, or ``"//"``.
    operand: int
        The integer operand applied on each iteration.
    """

    loop_var: str
    iterations: int
    register: str
    operation: str
    operand: int


ARITHMETIC_OPCODES: tuple[str, ...] = ("add", "sub", "mul", "div")
REGISTER_PREFIXES: tuple[str, ...] = ("r0", "r1", "r2", "r3")


def extract_arithmetic(line: str) -> str:
    """Convert an arithmetic VRScript call into a VR-ASM instruction string.

    Parses a function-call style arithmetic expression and reformats it as
    a VR-ASM statement.

    Arguments:
    ----------
    line: str
        A VRScript arithmetic call, e.g. ``"add(r0, r1, r2)"``.

    Returns:
    --------
    str:
        VR-ASM instruction, e.g. ``"add r0, r1, r2;"``.

    Raises:
    -------
    ValueError:
        When the argument count is not exactly 3.
    """
    # Step 1: Strip whitespace and split on the opening parenthesis to isolate
    #         the opcode and argument blob.
    cleaned_line = line.strip()
    opcode, args_blob = cleaned_line.split("(", maxsplit=1)
    # Step 2: Strip the closing parenthesis and split on commas.
    args = [token.strip() for token in args_blob.rstrip(")").split(",")]

    # Step 3: Validate exactly three arguments (store_at, op1, op2).
    if len(args) != 3:
        raise ValueError(f"invalid arithmetic call: {line}")

    store_at, operand_one, operand_two = args
    # Step 4: Reassemble as a VR-ASM instruction line.
    return f"{opcode} {store_at}, {operand_one}, {operand_two};"


def extract_register_variables(line: str) -> str:
    """Convert a register assignment to an immediate add (addi) instruction.

    Parses an assignment of the form ``r<n> = <int>`` and emits the
    corresponding ``addi`` instruction.

    Arguments:
    ----------
    line: str
        A VRScript register assignment, e.g. ``"r0 = 5"``.

    Returns:
    --------
    str:
        VR-ASM instruction, e.g. ``"addi r0, 5;"``.
    """
    # Step 1: Split on the first `=` to separate the register name from value.
    lhs, rhs = [token.strip() for token in line.split("=", maxsplit=1)]
    # Step 2: Emit as an `addi` immediate-add instruction.
    return f"addi {lhs}, {rhs};"


def parse_for_header(line: str) -> tuple[str, int]:
    """Parse a ``for x in 10 {`` style loop header.

    Arguments:
    ----------
    line: str
        A VRScript for-loop header line, e.g. ``"for i in 10 {"``

    Returns:
    --------
    tuple[str, int]:
        ``(loop_var, iterations)`` — the loop variable name and iteration count.

    Raises:
    -------
    ValueError:
        When the line does not match the expected ``for <var> in <n> {`` format.
    """
    # Step 1: Normalise by replacing `{` with a space then splitting on whitespace.
    normalized = line.replace("{", " ").strip()
    tokens = normalized.split()

    # Step 2: Validate the token structure: `for <var> in <n>`.
    if len(tokens) != 4 or tokens[0] != "for" or tokens[2] != "in":
        raise ValueError(f"invalid for-loop header: {line}")

    # Step 3: Return the loop variable and the integer iteration count.
    return tokens[1], int(tokens[3])


def parse_loop_body_instruction(line: str) -> tuple[str, str, int]:
    """Parse a loop body instruction like ``r3 ++ 2``.

    Arguments:
    ----------
    line: str
        A single VRScript loop body line, e.g. ``"r3 ++ 2"``.

    Returns:
    --------
    tuple[str, str, int]:
        ``(register, operation, operand)`` extracted from the line.

    Raises:
    -------
    ValueError:
        When the line does not contain exactly three whitespace-separated tokens.
    """
    # Step 1: Split into tokens; expect exactly register + operator + operand.
    tokens = line.split()

    if len(tokens) != 3:
        raise ValueError(f"invalid loop body instruction: {line}")

    register, operation, operand = tokens
    # Step 2: Convert the operand string to an integer and return.
    return register, operation, int(operand)


def extract_for(
    lines: list[str], loop_header_index: int, loop_end_index: int | None = None
) -> ForLoopSpec:
    """Build a :class:`ForLoopSpec` from source lines.

    Build a loop spec from source lines without relying on fixed indexes.

    Arguments:
    ----------
    lines: list[str]
        All source lines of the VRScript file.
    loop_header_index: int
        The 0-based index of the ``for …`` header line within ``lines``.

    loop_end_index: int | None
        Optional 0-based index of the loop terminator line containing ``}``.
        When provided, the loop body is validated to fit within
        ``(loop_header_index, loop_end_index)`` and contain exactly one
        instruction.

    Returns:
    --------
    ForLoopSpec:
        Fully populated loop specification ready for :func:`compile_loop_instruction`.

    Raises:
    -------
    ValueError:
        When the loop body cannot be found after the header or when body lines
        before ``}`` are malformed.
    """
    # Step 1: Parse the loop variable and iteration count from the header line.
    loop_var, iterations = parse_for_header(lines[loop_header_index])

    # Step 2: Advance past any blank lines to find the first body line.
    body_start = loop_header_index + 1
    while body_start < len(lines) and not lines[body_start].strip():
        body_start += 1

    if body_start >= len(lines):
        raise ValueError("for-loop body not found")

    if loop_end_index is not None and body_start >= loop_end_index:
        raise ValueError("for-loop body not found before closing brace")

    if loop_end_index is not None:
        body_lines = [
            lines[index].strip()
            for index in range(body_start, loop_end_index)
            if lines[index].strip() and not lines[index].strip().startswith("``")
        ]
        if len(body_lines) != 1:
            raise ValueError(
                "for-loop body must contain exactly one instruction before closing brace"
            )
        body_instruction = body_lines[0]
    else:
        body_instruction = lines[body_start].strip()

    # Step 3: Parse the single body instruction.
    register, operation, operand = parse_loop_body_instruction(body_instruction)
    # Step 4: Assemble and return the spec.
    return ForLoopSpec(
        loop_var=loop_var,
        iterations=iterations,
        register=register,
        operation=operation,
        operand=operand,
    )


def compile_loop_instruction(spec: ForLoopSpec) -> str:
    """Translate a parsed loop body instruction into a VR-ASM immediate op.

    Translate a parsed loop body instruction into vr-asm immediate ops.

    Arguments:
    ----------
    spec: ForLoopSpec
        A fully populated loop specification produced by :func:`extract_for`.

    Returns:
    --------
    str:
        A single VR-ASM instruction string to be repeated ``spec.iterations``
        times by the caller.

    Raises:
    -------
    ValueError:
        When ``spec.operation`` is not one of the four supported operators.
    """
    # Step 1: Map each loop operator to its corresponding VR-ASM immediate opcode.
    if spec.operation == "++":
        return f"addi {spec.register}, {spec.operand};"
    if spec.operation == "--":
        return f"subi {spec.register}, {spec.operand};"
    if spec.operation == "**":
        return f"muli {spec.register}, {spec.operand};"
    if spec.operation == "//":
        return f"divi {spec.register}, {spec.operand};"

    # Step 2: Raise a clear error for any unrecognised operator.
    raise ValueError(f"unsupported loop operation: {spec.operation}")

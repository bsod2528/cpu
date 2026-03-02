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


@dataclass(frozen=True)
class ForLoopSpec:
    """Representation of a parsed vrscript for-loop header and body."""

    loop_var: str
    iterations: int
    register: str
    operation: str
    operand: int


ARITHMETIC_OPCODES: tuple[str, ...] = ("add", "sub", "mul", "div")
REGISTER_PREFIXES: tuple[str, ...] = ("r0", "r1", "r2", "r3")


def extract_arithmetic(line: str) -> str:
    """Convert an arithmetic vrscript call into vr-asm."""
    cleaned_line = line.strip()
    opcode, args_blob = cleaned_line.split("(", maxsplit=1)
    args = [token.strip() for token in args_blob.rstrip(")").split(",")]

    if len(args) != 3:
        raise ValueError(f"invalid arithmetic call: {line}")

    store_at, operand_one, operand_two = args
    return f"{opcode} {store_at}, {operand_one}, {operand_two};"


def extract_register_variables(line: str) -> str:
    """Convert a register assignment to immediate add syntax."""
    lhs, rhs = [token.strip() for token in line.split("=", maxsplit=1)]
    return f"addi {lhs}, {rhs};"


def parse_for_header(line: str) -> tuple[str, int]:
    """Parse a `for x in 10 {` style loop header."""
    normalized = line.replace("{", " ").strip()
    tokens = normalized.split()

    if len(tokens) != 4 or tokens[0] != "for" or tokens[2] != "in":
        raise ValueError(f"invalid for-loop header: {line}")

    return tokens[1], int(tokens[3])


def parse_loop_body_instruction(line: str) -> tuple[str, str, int]:
    """Parse a loop body instruction like `r3 ++ 2`."""
    tokens = line.split()

    if len(tokens) != 3:
        raise ValueError(f"invalid loop body instruction: {line}")

    register, operation, operand = tokens
    return register, operation, int(operand)


def extract_for(lines: list[str], loop_header_index: int) -> ForLoopSpec:
    """Build a loop spec from source lines without relying on fixed indexes."""
    loop_var, iterations = parse_for_header(lines[loop_header_index])

    body_start = loop_header_index + 1
    while body_start < len(lines) and not lines[body_start].strip():
        body_start += 1

    if body_start >= len(lines):
        raise ValueError("for-loop body not found")

    register, operation, operand = parse_loop_body_instruction(
        lines[body_start].strip()
    )
    return ForLoopSpec(
        loop_var=loop_var,
        iterations=iterations,
        register=register,
        operation=operation,
        operand=operand,
    )


def compile_loop_instruction(spec: ForLoopSpec) -> str:
    """Translate a parsed loop body instruction into vr-asm immediate ops."""
    if spec.operation == "++":
        return f"addi {spec.register}, {spec.operand};"
    if spec.operation == "--":
        return f"subi {spec.register}, {spec.operand};"
    if spec.operation == "**":
        return f"muli {spec.register}, {spec.operand};"
    if spec.operation == "//":
        return f"divi {spec.register}, {spec.operand};"

    raise ValueError(f"unsupported loop operation: {spec.operation}")

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

"""VR16 compiler: translates VRScript source files into VR-ASM assembly.

VRScript is a simple high-level language that compiles down to VR-ASM which
can then be assembled into binary machine code using the VR16 assembler.

Supported VRScript constructs:
    - Register assignment: ``r0 = 5``  →  ``addi r0, 5;``
    - Arithmetic calls:    ``add(r0, r1, r2)``  →  ``add r0, r1, r2;``
    - For loops:           ``for i in 4 { r3 ++ 2 }``  →  four ``addi r3, 2;``
    - Comments:            lines starting with ` `` ` are ignored.

Usage (CLI)::

    python3 compiler.py <source_path> <output_path>
"""

import argparse
from pathlib import Path

from extractor import (
    ARITHMETIC_OPCODES,
    REGISTER_PREFIXES,
    compile_loop_instruction,
    extract_arithmetic,
    extract_for,
    extract_register_variables,
    parse_for_header,
)


class CompilationError(ValueError):
    """Raised when VRScript source cannot be compiled."""


def build_cli() -> argparse.ArgumentParser:
    """Build and return the CLI argument parser for the compiler.

    Returns:
    --------
    argparse.ArgumentParser:
        Parser configured with ``source_path`` and ``output_path`` positional
        arguments.
    """
    parser = argparse.ArgumentParser(description="Compile vrscript source to vr-asm.")
    parser.add_argument("source_path", type=Path, help="Path to vrscript source file")
    parser.add_argument("output_path", type=Path, help="Path to output vr-asm file")
    return parser


def parse_instruction(line_index: int, line: str) -> str | None:
    """Attempt to compile a single VRScript line into a VR-ASM instruction.

    Arguments:
    ----------
    line_index: int
        The 0-based source line index.
    line: str
        A single line of VRScript source text (may include leading whitespace).

    Returns:
    --------
    str | None:
        The compiled VR-ASM instruction string, or ``None`` if the line is
        blank or a comment.

    Raises:
    -------
    CompilationError:
        If the source line is non-empty, non-comment, and does not match any
        supported syntax.
    """
    stripped = line.strip()
    source_line = line_index + 1

    # Step 1: Skip blank lines and comment lines (start with double backtick).
    if not stripped or stripped.startswith("``"):
        return None

    # Step 2: Register assignment — e.g. `r0 = 5` → `addi r0, 5;`
    if stripped.startswith(REGISTER_PREFIXES):
        return extract_register_variables(stripped)

    # Step 3: Arithmetic call — e.g. `add(r0, r1, r2)` → `add r0, r1, r2;`
    if stripped.startswith(ARITHMETIC_OPCODES):
        return extract_arithmetic(stripped)

    raise CompilationError(
        f"Line {source_line}: unsupported syntax: {stripped!r}. "
        "Expected register assignment, arithmetic call, or for-loop."
    )


def compile_source(source_path: Path, output_path: Path) -> None:
    """Compile a VRScript source file into a VR-ASM output file.

    Reads the source file line by line and emits VR-ASM instructions wrapped
    in ``start:`` / ``end:`` delimiters.  For-loop constructs are fully
    unrolled at compile time.

    Arguments:
    ----------
    source_path: Path
        Path to the VRScript ``.vrs`` source file.
    output_path: Path
        Path to the output VR-ASM ``.asm`` file.  Parent directories are
        created automatically if they do not exist.
    """
    # Step 1: Read all source lines.
    lines = source_path.read_text(encoding="utf-8").splitlines()
    # Step 2: Start the output with the mandatory `start:` delimiter.
    compiled_lines: list[str] = ["start:"]

    list_index = 0
    while list_index < len(lines):
        code = lines[list_index].strip()

        # Step 3: Skip blank lines and VRScript comment lines.
        if not code or code.startswith("``"):
            list_index += 1
            continue

        # Step 4: Handle for-loop construct — parse the header, extract the
        #         body instruction, and unroll the loop `iterations` times.
        if code.startswith("for "):
            try:
                parse_for_header(code)
            except ValueError as error:
                raise CompilationError(f"Line {list_index + 1}: {error}") from error

            loop_end = list_index + 1
            while loop_end < len(lines) and "}" not in lines[loop_end]:
                loop_end += 1

            if loop_end >= len(lines):
                raise CompilationError(
                    f"Line {list_index + 1}: unterminated for-loop starting here; missing closing '}}'"
                )

            loop_spec = extract_for(lines, list_index, loop_end)
            loop_instruction = compile_loop_instruction(loop_spec)
            # Step 4a: Emit one copy of the body instruction per iteration.
            for _ in range(loop_spec.iterations):
                compiled_lines.append(f"	{loop_instruction}")

            # Step 4b: Skip past the closing `}` of the loop body.
            list_index = loop_end + 1
            continue

        # Step 5: Attempt to compile the line as a simple instruction.
        result = parse_instruction(list_index, code)
        if result is not None:
            compiled_lines.append(f"\t{result}")

        list_index += 1

    # Step 6: Close the output with the mandatory `end:` delimiter.
    compiled_lines.append("end:")

    # Step 7: Write the compiled VR-ASM to the output file, creating parent
    #         directories if they do not exist.
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(compiled_lines) + "\n", encoding="utf-8")


def main() -> None:
    """Entry point: parse CLI arguments and run the compiler."""
    args = build_cli().parse_args()
    try:
        compile_source(args.source_path, args.output_path)
    except (CompilationError, ValueError) as error:
        print(f"Compilation error: {error}")
        raise SystemExit(1) from error


if __name__ == "__main__":
    main()

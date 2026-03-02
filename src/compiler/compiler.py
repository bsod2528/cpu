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

from extractor import (
    ARITHMETIC_OPCODES,
    REGISTER_PREFIXES,
    compile_loop_instruction,
    extract_arithmetic,
    extract_for,
    extract_register_variables,
)


def build_cli() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Compile vrscript source to vr-asm.")
    parser.add_argument("source_path", type=Path, help="Path to vrscript source file")
    parser.add_argument("output_path", type=Path, help="Path to output vr-asm file")
    return parser


def parse_instruction(line: str) -> str | None:
    stripped = line.strip()

    if not stripped or stripped.startswith("``"):
        return None

    if stripped.startswith(REGISTER_PREFIXES):
        return extract_register_variables(stripped)

    if stripped.startswith(ARITHMETIC_OPCODES):
        return extract_arithmetic(stripped)

    return None


def compile_source(source_path: Path, output_path: Path) -> None:
    lines = source_path.read_text(encoding="utf-8").splitlines()
    compiled_lines: list[str] = ["start:"]

    list_index = 0
    while list_index < len(lines):
        code = lines[list_index].strip()

        if not code or code.startswith("``"):
            list_index += 1
            continue

        if code.startswith("for"):
            loop_spec = extract_for(lines, list_index)
            loop_instruction = compile_loop_instruction(loop_spec)
            for _ in range(loop_spec.iterations):
                compiled_lines.append(f"\t{loop_instruction}")

            loop_end = list_index + 1
            while loop_end < len(lines) and "}" not in lines[loop_end]:
                loop_end += 1
            list_index = loop_end + 1
            continue

        result = parse_instruction(code)
        if result is not None:
            compiled_lines.append(f"\t{result}")

        list_index += 1

    compiled_lines.append("end:")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(compiled_lines) + "\n", encoding="utf-8")


def main() -> None:
    args = build_cli().parse_args()
    compile_source(args.source_path, args.output_path)


if __name__ == "__main__":
    main()

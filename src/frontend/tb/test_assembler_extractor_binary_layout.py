from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[3]
SRC_DIR = ROOT_DIR / "src"
INSTRUCTION_MEMORY_RTL = ROOT_DIR / "src" / "frontend" / "rtl" / "instruction_memory.v"

from assembler.extractor import (
    ParsedInstruction,
    extract_arithmetic,
    extract_delete,
    extract_halt,
    extract_immediate_arithmetic,
    extract_jump,
    extract_logic_main,
    extract_logic_side,
)

BINARY_16_RE = re.compile(r"^[01]{16}$")


def test_extractor_outputs_exact_expected_16bit_binary_strings() -> None:
    fixtures: list[tuple[ParsedInstruction, str]] = [
        (ParsedInstruction("add", ["r0", "r1", "r2"], 1), "0000000110000000"),
        (ParsedInstruction("addi", ["r2", "13"], 2), "0001100000001101"),
        (ParsedInstruction("and", ["r3", "r1", "r0"], 3), "1011110100000000"),
        (ParsedInstruction("not", ["r1", "r2"], 4), "1101011000000000"),
        (ParsedInstruction("jump", ["42"], 5), "1001000000101010"),
        (ParsedInstruction("delete", ["r3"], 6), "1010110000000000"),
        (ParsedInstruction("halt", [], 7), "1111000000000000"),
    ]

    extractors = {
        "add": extract_arithmetic,
        "addi": extract_immediate_arithmetic,
        "and": extract_logic_main,
        "not": extract_logic_side,
        "jump": extract_jump,
        "delete": extract_delete,
        "halt": extract_halt,
    }

    for instruction, expected in fixtures:
        result = extractors[instruction.opcode](instruction)
        assert result == expected
        assert len(result) == 16
        assert BINARY_16_RE.match(result), f"Non-binary/unknown output: {result}"


def test_generated_mem_loads_without_unknowns_in_instruction_memory() -> None:
    asm_source = """start:
add r0, r1, r2
and r3, r2, r1
not r0, r3
delete r1
halt
end:
"""

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        asm_path = tmpdir_path / "program.asm"
        mem_path = tmpdir_path / "program.mem"
        asm_path.write_text(asm_source)

        assemble = subprocess.run(
            ["python3", "-m", "assembler", str(asm_path), str(mem_path)],
            cwd=ROOT_DIR,
            env={**os.environ, "PYTHONPATH": str(SRC_DIR)},
            capture_output=True,
            text=True,
            check=False,
        )
        assert assemble.returncode == 0, assemble.stderr

        mem_lines = [
            line.strip() for line in mem_path.read_text().splitlines() if line.strip()
        ]
        assert mem_lines, "Expected non-empty generated memory file"
        assert all(BINARY_16_RE.match(line) for line in mem_lines)

        tb_path = tmpdir_path / "tb_mem_no_unknown.v"
        tb_path.write_text(f"""`timescale 1ns / 1ps
module tb_mem_no_unknown;
    reg clk = 1'b0;
    reg reset = 1'b0;
    reg enable = 1'b1;
    reg [15:0] address = 16'd0;
    wire [15:0] instruction;

    instruction_memory #(
        .MEM_FILE(\"{mem_path.as_posix()}\")
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .address(address),
        .instruction(instruction)
    );

    always #5 clk = ~clk;

    integer i;
    initial begin
        for (i = 0; i < {len(mem_lines)}; i = i + 1) begin
            address = i[15:0];
            @(posedge clk);
            #1;
            if (^instruction === 1'bx) begin
                $display("[FAIL] Unknown bits at address %0d: %b", i, instruction);
                $fatal(1);
            end
        end
        $display("[PASS] tb_mem_no_unknown");
        $finish;
    end
endmodule
""")

        if shutil.which("iverilog") is None or shutil.which("vvp") is None:
            return

        compile_result = subprocess.run(
            [
                "iverilog",
                "-g2005-sv",
                "-o",
                str(tmpdir_path / "tb_mem_no_unknown.out"),
                str(INSTRUCTION_MEMORY_RTL),
                str(tb_path),
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        assert compile_result.returncode == 0, compile_result.stderr

        run_result = subprocess.run(
            ["vvp", str(tmpdir_path / "tb_mem_no_unknown.out")],
            capture_output=True,
            text=True,
            check=False,
        )
        assert run_result.returncode == 0, run_result.stderr + run_result.stdout
        assert "[PASS] tb_mem_no_unknown" in run_result.stdout


def test_assembler_cli_returns_non_zero_on_unknown_opcode() -> None:
    asm_source = """start:
foo r0, r1
end:
"""

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        asm_path = tmpdir_path / "invalid_opcode.asm"
        mem_path = tmpdir_path / "invalid_opcode.mem"
        asm_path.write_text(asm_source)

        assemble = subprocess.run(
            ["python3", "-m", "assembler", str(asm_path), str(mem_path)],
            cwd=ROOT_DIR,
            env={**os.environ, "PYTHONPATH": str(SRC_DIR)},
            capture_output=True,
            text=True,
            check=False,
        )

        assert assemble.returncode != 0
        assert "There is no such opcode" in assemble.stdout
        if mem_path.exists():
            assert mem_path.read_text().strip() == ""


if __name__ == "__main__":
    test_extractor_outputs_exact_expected_16bit_binary_strings()
    test_generated_mem_loads_without_unknowns_in_instruction_memory()
    test_assembler_cli_returns_non_zero_on_unknown_opcode()
    print("[PASS] test_assembler_extractor_binary_layout")

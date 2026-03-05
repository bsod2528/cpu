from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[3]
ASSEMBLER_DIR = ROOT_DIR / "src" / "assembler"
ASSEMBLER_SCRIPT = ASSEMBLER_DIR / "assembler.py"


def run_assembler(source_text: str) -> tuple[int, str, str, str]:
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        source_path = tmpdir_path / "immediate.asm"
        output_path = tmpdir_path / "immediate.mem"
        source_path.write_text(source_text)

        result = subprocess.run(
            ["python3", str(ASSEMBLER_SCRIPT), str(source_path), str(output_path)],
            cwd=ASSEMBLER_DIR,
            capture_output=True,
            text=True,
            check=False,
        )

        output = output_path.read_text() if output_path.exists() else ""
        return result.returncode, result.stdout, result.stderr, output


def test_addi_rejects_non_integer_immediate() -> None:
    code = """start:\naddi r0, foo\nend:\n"""
    rc, stdout, stderr, mem = run_assembler(code)

    assert rc != 0, "assembler should return non-zero for invalid addi immediate"
    assert "Invalid immediate at line 2" in stdout
    assert "Expected a base-10 integer in range 0 to 1023" in stdout
    assert mem.strip() == ""


def test_addi_rejects_out_of_range_immediate() -> None:
    code = """start:\naddi r0, 1024\nend:\n"""
    rc, stdout, stderr, mem = run_assembler(code)

    assert rc != 0, "assembler should return non-zero for out-of-range addi immediate"
    assert "Invalid immediate at line 2" in stdout
    assert "Expected a base-10 integer in range 0 to 1023" in stdout
    assert mem.strip() == ""


if __name__ == "__main__":
    test_addi_rejects_non_integer_immediate()
    test_addi_rejects_out_of_range_immediate()
    print("[PASS] test_assembler_immediate")

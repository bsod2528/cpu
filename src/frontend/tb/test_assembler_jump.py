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
        source_path = tmpdir_path / "jump.asm"
        output_path = tmpdir_path / "jump.mem"
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


def test_jump_encodes_12bit_immediate() -> None:
    code = """start:\njump 10\njump 4095\nend:\n"""
    rc, stdout, stderr, mem = run_assembler(code)

    assert rc == 0, f"assembler failed: stdout={stdout}\nstderr={stderr}"
    lines = [line for line in mem.splitlines() if line]
    assert lines == ["1001000000001010", "1001111111111111"]


def test_jump_rejects_out_of_range_immediate() -> None:
    code = """start:\njump 4096\nend:\n"""
    rc, stdout, stderr, mem = run_assembler(code)

    assert (
        rc == 0
    ), f"assembler invocation failed unexpectedly: stdout={stdout}\nstderr={stderr}"
    assert "Jump address out of range" in stdout
    assert mem.strip() == ""


if __name__ == "__main__":
    test_jump_encodes_12bit_immediate()
    test_jump_rejects_out_of_range_immediate()
    print("[PASS] test_assembler_jump")

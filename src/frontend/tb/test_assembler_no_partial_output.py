from __future__ import annotations

import os
import subprocess
import tempfile
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[3]
SRC_DIR = ROOT_DIR / "src"


def test_assembler_leaves_existing_output_untouched_on_mid_stream_error() -> None:
    asm_source = """start:
add r0, r1, r2
invalid_opcode r0, r1
end:
"""

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        output_path = tmpdir_path / "partial_output_regression.mem"
        asm_path = tmpdir_path / "partial_output_regression.asm"

        original_output = "1010101010101010\n0101010101010101\n"
        output_path.write_text(original_output)
        asm_path.write_text(asm_source)

        assemble = subprocess.run(
            ["python3", "-m", "assembler", str(asm_path), str(output_path)],
            cwd=ROOT_DIR,
            env={**os.environ, "PYTHONPATH": str(SRC_DIR)},
            capture_output=True,
            text=True,
            check=False,
        )

        assert assemble.returncode != 0
        assert "There is no such opcode" in assemble.stdout
        assert output_path.read_text() == original_output


if __name__ == "__main__":
    test_assembler_leaves_existing_output_untouched_on_mid_stream_error()
    print("[PASS] test_assembler_no_partial_output")

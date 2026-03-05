from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[3]
COMPILER_DIR = ROOT_DIR / "src" / "compiler"
COMPILER_SCRIPT = COMPILER_DIR / "compiler.py"


def run_compiler(source_text: str) -> subprocess.CompletedProcess[str]:
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        source_path = tmpdir_path / "bad_input.vrs"
        output_path = tmpdir_path / "bad_output.asm"

        source_path.write_text(source_text, encoding="utf-8")

        return subprocess.run(
            ["python3", str(COMPILER_SCRIPT), str(source_path), str(output_path)],
            cwd=COMPILER_DIR,
            capture_output=True,
            text=True,
            check=False,
        )


def test_compiler_reports_line_number_for_unrecognized_statement() -> None:
    compile_result = run_compiler("r0 = 5\nthis is not valid\n")

    assert compile_result.returncode != 0
    assert "Compilation error:" in compile_result.stdout
    assert "Line 2" in compile_result.stdout
    assert "unsupported syntax" in compile_result.stdout


def test_compiler_ignores_blank_and_comment_lines_before_reporting_error() -> None:
    compile_result = run_compiler("\n`` comment\n\ninvalid\n")

    assert compile_result.returncode != 0
    assert "Line 4" in compile_result.stdout


def test_compiler_does_not_treat_for_prefixed_words_as_loop_headers() -> None:
    for bad_header in ("format", "force", "forx"):
        compile_result = run_compiler(f"{bad_header}\n")

        assert compile_result.returncode != 0
        assert "Compilation error:" in compile_result.stdout
        assert "Line 1" in compile_result.stdout
        assert "unsupported syntax" in compile_result.stdout


if __name__ == "__main__":
    test_compiler_reports_line_number_for_unrecognized_statement()
    test_compiler_ignores_blank_and_comment_lines_before_reporting_error()
    test_compiler_does_not_treat_for_prefixed_words_as_loop_headers()
    print("[PASS] test_compiler_malformed_input")

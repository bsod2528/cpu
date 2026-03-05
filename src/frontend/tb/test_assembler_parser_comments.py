from __future__ import annotations

from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[3]
from assembler.assembler import parse_instruction_line


def test_parse_instruction_ignores_full_line_comment() -> None:
    assert parse_instruction_line("-- this line is ignored", 1) is None
    assert parse_instruction_line("   -- indented comment", 2) is None


def test_parse_instruction_ignores_inline_comment_after_instruction() -> None:
    parsed = parse_instruction_line("add r0, r1, r2 -- add two registers", 3)

    assert parsed is not None
    assert parsed.opcode == "add"
    assert parsed.operands == ["r0", "r1", "r2"]


def test_parse_start_and_end_with_trailing_comments() -> None:
    parsed_start = parse_instruction_line("start: -- entry point", 4)
    parsed_end = parse_instruction_line("end: -- exit point", 5)

    assert parsed_start is not None
    assert parsed_start.opcode == "start:"
    assert parsed_start.operands == []

    assert parsed_end is not None
    assert parsed_end.opcode == "end:"
    assert parsed_end.operands == []


def test_operand_count_validation_unchanged_after_comment_strip() -> None:
    try:
        parse_instruction_line("add r0, r1 -- missing third operand", 6)
    except ValueError as error:
        assert "expects 3 operand(s), got 2" in str(error)
    else:
        raise AssertionError("Expected ValueError for invalid operand count")


if __name__ == "__main__":
    test_parse_instruction_ignores_full_line_comment()
    test_parse_instruction_ignores_inline_comment_after_instruction()
    test_parse_start_and_end_with_trailing_comments()
    test_operand_count_validation_unchanged_after_comment_strip()
    print("[PASS] test_assembler_parser_comments")

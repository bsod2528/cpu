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

"""Base exception classes for the VR16 assembler.

Provides colourised, human-readable error messages for two categories of
assembler errors:

- :class:`RegisterNotPresent`: raised when an operand names a register that
  does not exist in the VR16 ISA (only r0–r3 are valid).
- :class:`OpcodeNotPresent`: raised when an instruction uses an opcode that
  is not defined in the VR16 ISA, with fuzzy-match suggestions to help the
  programmer correct the typo.
"""

from colorama import Fore, Back, Style


class RegisterNotPresent(Exception):
    """Raised when an assembly instruction references an undefined register.

    The VR16 ISA only has four general-purpose registers: r0, r1, r2, r3.
    Any other register name triggers this exception.

    Attributes:
    -----------
    register: str
        The invalid register name that was encountered.
    line: int
        1-based source line number where the bad register appeared.
    """

    def __init__(self, register: str, line: int):
        """Initialise with the bad register name and source line number."""
        super().__init__(register)
        self.register = register
        self.line = line

    def __str__(self) -> str:
        """Return a colourised, human-readable error message."""
        return (
            Fore.YELLOW
            + "WARNING"
            + Style.RESET_ALL
            + ": There is no register "
            + Fore.BLACK
            + Back.WHITE
            + Style.BRIGHT
            + self.register
            + Style.RESET_ALL
            + " at line: "
            + Fore.BLACK
            + Style.BRIGHT
            + Back.RED
            + f"{self.line}"
            + Style.RESET_ALL
            + "!"
        )


class OpcodeNotPresent(Exception):
    """Raised when an assembly instruction uses an unrecognised opcode.

    In addition to reporting the bad opcode, :meth:`predict_opcode` attempts
    to suggest valid opcodes that start with the same letter, giving the
    programmer a hint about what they might have intended.

    Attributes:
    -----------
    opcode: str
        The unrecognised opcode string that was encountered.
    line: int
        1-based source line number where the bad opcode appeared.
    """

    def __init__(self, opcode: str, line: int):
        """Initialise with the bad opcode string and source line number."""
        super().__init__(opcode)
        self.opcode = opcode
        self.line = line

    def predict_opcode(self, opcode: str) -> list[str]:
        """Return a list of valid opcodes that share the same starting letter.

        Arguments:
        ----------
        opcode: str
            The unrecognised opcode to match against.

        Returns:
        --------
        list[str]:
            A list of candidate opcodes, or an empty list if no match found.
        """
        # Step 1: Match on the first character to produce a short candidate list.
        if opcode.startswith("a"):
            return ["add", "addi", "and"]
        if opcode.startswith("s"):
            return ["sub", "subi"]
        if opcode.startswith("m"):
            return ["mul", "muli"]
        if opcode.startswith("d"):
            return ["div", "divi", "delete"]
        if opcode.startswith("j"):
            return ["jump"]
        if opcode.startswith("h"):
            return ["halt"]
        if opcode.startswith("o"):
            return ["or", "xor"]
        if opcode.startswith("n"):
            return ["not"]

    def __str__(self) -> str:
        """Return a colourised error message with fuzzy-match suggestions."""
        # Step 2: Generate opcode suggestions for the error message.
        opcode_suggestions: list[str] = self.predict_opcode(self.opcode)

        suggestion_text = ""
        if opcode_suggestions:
            # Step 3: Format each suggestion with green colour for visibility.
            suggestion_text = (
                "Did you mean: "
                + ", ".join(
                    [
                        Fore.GREEN + Style.BRIGHT + suggestion + Style.RESET_ALL
                        for suggestion in opcode_suggestions
                    ]
                )
                + "?"
            )

        return (
            Fore.YELLOW
            + "WARNING"
            + Style.RESET_ALL
            + ": There is no such opcode "
            + Fore.BLACK
            + Back.WHITE
            + Style.BRIGHT
            + self.opcode
            + Style.RESET_ALL
            + " at line: "
            + Fore.BLACK
            + Style.BRIGHT
            + Back.RED
            + f"{self.line}"
            + Style.RESET_ALL
            + "!\n"
            + suggestion_text
        )

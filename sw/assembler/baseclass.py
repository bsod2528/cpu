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

from colorama import Fore, Back, Style


class RegisterNotPresent(Exception):
    def __init__(self, register: str, line: int):
        super().__init__(register)
        self.register = register
        self.line = line

    def __str__(self) -> str:
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
    def __init__(self, opcode: str, line: int):
        super().__init__(opcode)
        self.opcode = opcode
        self.line = line

    def predict_opcode(self, opcode: str) -> list[str]:
        """ """
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
        opcode_suggestions: list[str] = self.predict_opcode(self.opcode)

        suggestion_text = ""
        if opcode_suggestions:
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

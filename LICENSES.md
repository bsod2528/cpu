# Licenses

This project is licensed under two different licenses, depending on the part of the repository.

## Frontend & Toolchain - GPLv3

- **Frontend**: synthesizable Verilog RTL and testbenches (`src/frontend/`)
- **Toolchain**: assembler and compiler (`src/assembler/`, `src/compiler/`)

These are licensed under the **GNU General Public License v3.0 (GPLv3)**.

Full text: [`LICENSE`](./LICENSE)

## Backend - CERN-OHL-S v2

- **Backend**: physical design output, specifically the GDSII layout (`src/backend/`).

This is licensed under the **CERN Open Hardware Licence Version 2 - Strongly Reciprocal (CERN-OHL-S v2)**.

Full text: [`LICENSES/CERN-OHL-S-2.0.txt`](./LICENSES/CERN-OHL-S-2.0.txt)

## Summary

| Part | Path | License |
|---|---|---|
| Frontend | `src/frontend/` | GPLv3 |
| Toolchain | `src/assembler/`, `src/compiler/` | GPLv3 |
| Backend | `src/backend/` | CERN-OHL-S v2 |

If a file isn't covered by either license above, assume no license is granted for reuse or redistribution unless stated otherwise.
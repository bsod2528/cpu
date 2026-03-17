"""Module entrypoint for ``python -m assembler``."""

import sys
from assembler.assembler import main, AssemblerError
from assembler.baseclass import SourceNotFound

if __name__ == "__main__":
    try:
        main()
    except SourceNotFound as error:
        print(error)
        sys.exit(1)
    except AssemblerError as error:
        print(error)
        sys.exit(1)

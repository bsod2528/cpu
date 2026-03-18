#!/bin/bash

clear

# bsod2528: thank you gtkwave docs lmaoo, genuine godsend for the dark mode implementation, otherwise debugging at 4am is a pain
# bsod2528: here is the link btw - https://gtkwave.github.io/gtkwave/man/gtkwave.1.html and do `ctrl+f` + `dark`.
vvp output.out
gtkwave dump.vcd -6 dark
